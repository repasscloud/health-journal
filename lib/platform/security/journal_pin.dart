import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/installation_key.dart';

/// The app PIN gates the local UI. Its verifier and retry state are protected by
/// the platform key store and are independent of the journal encryption key.
final class JournalPin {
  JournalPin(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final InstallationKeyStore _store;
  final DateTime Function() _clock;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static final _digits = RegExp(r'^[0-9]{6,12}$');
  static bool isValid(String pin) => _digits.hasMatch(pin);

  Future<bool> isEnabled() => _serialize(() async => (await _read()) != null);

  Future<bool> configure({required String current, required String next}) =>
      _serialize(() async {
        if (next.isNotEmpty && !isValid(next)) {
          throw ArgumentError('Use 6 to 12 digits.');
        }
        if (await _read() != null && !await _verify(current)) return false;
        if (next.isEmpty) {
          await _store.write('disabled-v1');
        } else {
          final random = Random.secure();
          final salt = Uint8List.fromList(
            List.generate(16, (_) => random.nextInt(256)),
          );
          final digest = await _derive(next, salt);
          await _write(_PinState(salt, digest, 0, 0));
        }
        return true;
      });

  Future<bool> verify(String pin) => _serialize(() => _verify(pin));

  Future<bool> _verify(String pin) async {
    final state = await _read();
    if (state == null) return false;
    if (_clock().millisecondsSinceEpoch < state.retryAt) return false;
    final matches =
        isValid(pin) &&
        Mac(await _derive(pin, state.salt)) == Mac(state.digest);
    final failures = matches ? 0 : min(state.failures + 1, 10);
    final delay = failures < 3 ? 0 : min(300, 1 << (failures - 2));
    // Persist retry state before releasing the UI, including across restarts.
    await _write(
      _PinState(
        state.salt,
        state.digest,
        failures,
        delay == 0 ? 0 : _clock().millisecondsSinceEpoch + delay * 1000,
      ),
    );
    return matches;
  }

  static Future<List<int>> _derive(String pin, List<int> salt) =>
      Isolate.run(() async {
        final key = await Argon2id(
          parallelism: 1,
          memory: 19456,
          iterations: 2,
          hashLength: 32,
        ).deriveKeyFromPassword(password: pin, nonce: salt);
        try {
          return List<int>.of(await key.extractBytes());
        } finally {
          key.destroy();
        }
      });

  Future<_PinState?> _read() async {
    final value = await _store.read();
    if (value == null || value == 'disabled-v1') return null;
    if (jsonDecode(value) case [
      1,
      String salt,
      String digest,
      int failures,
      int retryAt,
    ]) {
      return _validate(
        _PinState(base64Decode(salt), base64Decode(digest), failures, retryAt),
      );
    }
    throw const FormatException('Invalid PIN settings.');
  }

  _PinState _validate(_PinState state) {
    if (state.salt.length != 16 ||
        state.digest.length != 32 ||
        state.failures < 0 ||
        state.failures > 10 ||
        state.retryAt < 0) {
      throw const FormatException('Invalid PIN settings.');
    }
    return state;
  }

  Future<void> _write(_PinState state) => _store.write(
    jsonEncode([
      1,
      base64Encode(state.salt),
      base64Encode(state.digest),
      state.failures,
      state.retryAt,
    ]),
  );
}

final class _PinState {
  const _PinState(this.salt, this.digest, this.failures, this.retryAt);
  final List<int> salt, digest;
  final int failures, retryAt;
}
