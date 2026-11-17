import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

abstract interface class InstallationKeyStore {
  Future<String?> read();
  Future<void> write(String encodedKey);
}

/// Missing or corrupt installation keys never trigger silent data replacement.
/// Bootstrap must serialize calls to this service.
final class InstallationKeyService {
  InstallationKeyService(this.store);
  final InstallationKeyStore store;

  Future<Uint8List> load({required bool databaseExists}) async {
    final encoded = await store.read();
    if (encoded != null) {
      try {
        final bytes = base64Decode(encoded);
        if (bytes.length != 32) throw const FormatException();
        return bytes;
      } on FormatException {
        throw StateError(
          'Device key is unavailable. Use a portable backup to recover.',
        );
      }
    }
    if (databaseExists) {
      throw StateError(
        'Device key is unavailable. Existing records were not changed.',
      );
    }
    final random = Random.secure();
    final key = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final value = base64Encode(key);
    await store.write(value);
    if (await store.read() != value) {
      throw StateError(
        'Device key could not be verified. No database was created.',
      );
    }
    return key;
  }
}
