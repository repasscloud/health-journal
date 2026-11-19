import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// V1 authenticated container. This layer protects opaque payload bytes.
/// Callers must validate the decrypted journal schema before using the result.
final class PortableBackupCipher {
  const PortableBackupCipher();

  static const _magic = [0x48, 0x4a, 0x42, 0x41, 0x4b, 0x0d, 0x0a, 0x1a];
  static const _headerBytes = 52;
  static const _tagBytes = 16;
  static const _saltOffset = 20;
  static const _nonceOffset = 36;
  static const _lengthOffset = 48;
  static const _memoryKib = 32768;
  static const _iterations = 3;
  static const _lanes = 1;

  static const maxPayloadBytes = 32 * 1024 * 1024;
  static const maxFileBytes = _headerBytes + maxPayloadBytes + _tagBytes;

  Future<Uint8List> seal(Uint8List payload, String password) async {
    _checkPassword(password);
    if (payload.isEmpty || payload.length > maxPayloadBytes) {
      throw const FormatException('Backup payload size is out of bounds.');
    }
    final input = TransferableTypedData.fromList([payload]);
    return (await Isolate.run(() async {
      final clear = input.materialize().asUint8List();
      final header = Uint8List(_headerBytes)..setAll(0, _magic);
      final fields = ByteData.sublistView(header);
      fields
        ..setUint16(8, _headerBytes)
        ..setUint8(10, 1) // format version
        ..setUint8(11, 1) // Argon2id v19
        ..setUint8(12, 1) // AES-256-GCM
        ..setUint8(13, _lanes)
        ..setUint16(14, _iterations)
        ..setUint32(16, _memoryKib)
        ..setUint32(_lengthOffset, clear.length);
      final random = Random.secure();
      for (var offset = _saltOffset; offset < _lengthOffset; offset++) {
        header[offset] = random.nextInt(256);
      }

      SecretKey? key;
      try {
        key = await _derive(fields, password);
        final box = await AesGcm.with256bits().encrypt(
          clear,
          secretKey: key,
          nonce: Uint8List.sublistView(header, _nonceOffset, _lengthOffset),
          aad: header,
        );
        return TransferableTypedData.fromList([
          header,
          Uint8List.fromList(box.cipherText),
          Uint8List.fromList(box.mac.bytes),
        ]);
      } finally {
        key?.destroy();
        clear.fillRange(0, clear.length, 0);
      }
    })).materialize().asUint8List();
  }

  Future<Uint8List> open(Uint8List file, String password) async {
    _checkPassword(password);
    _parse(file);
    final input = TransferableTypedData.fromList([file]);
    return (await Isolate.run(() async {
      final bytes = input.materialize().asUint8List();
      final fields = _parse(bytes);
      final cipherEnd = bytes.length - _tagBytes;
      final header = Uint8List.sublistView(bytes, 0, _headerBytes);
      final box = SecretBox(
        Uint8List.sublistView(bytes, _headerBytes, cipherEnd),
        nonce: Uint8List.sublistView(header, _nonceOffset, _lengthOffset),
        mac: Mac(Uint8List.sublistView(bytes, cipherEnd)),
      );
      final key = await _derive(fields, password);
      try {
        final clear = await AesGcm.with256bits().decrypt(
          box,
          secretKey: key,
          aad: header,
        );
        final buffer = Uint8List.fromList(clear);
        try {
          return TransferableTypedData.fromList([buffer]);
        } finally {
          buffer.fillRange(0, buffer.length, 0);
          clear.fillRange(0, clear.length, 0);
        }
      } finally {
        key.destroy();
      }
    })).materialize().asUint8List();
  }

  static ByteData _parse(Uint8List file) {
    if (file.length <= _headerBytes + _tagBytes || file.length > maxFileBytes) {
      throw const FormatException('Backup file size is out of bounds.');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (file[i] != _magic[i]) {
        throw const FormatException('Unknown backup file.');
      }
    }
    final fields = ByteData.sublistView(file, 0, _headerBytes);
    if (fields.getUint16(8) != _headerBytes ||
        fields.getUint8(10) != 1 ||
        fields.getUint8(11) != 1 ||
        fields.getUint8(12) != 1) {
      throw const FormatException('Unsupported backup format.');
    }
    final lanes = fields.getUint8(13);
    final iterations = fields.getUint16(14);
    final memory = fields.getUint32(16);
    if (lanes < 1 ||
        lanes > 2 ||
        iterations < 3 ||
        iterations > 5 ||
        memory < 32768 ||
        memory > 65536 ||
        memory % (4 * lanes) != 0 ||
        fields.getUint32(_lengthOffset) !=
            file.length - _headerBytes - _tagBytes) {
      throw const FormatException('Unsupported backup parameters.');
    }
    return fields;
  }

  static Future<SecretKey> _derive(ByteData header, String password) =>
      Argon2id(
        parallelism: header.getUint8(13),
        iterations: header.getUint16(14),
        memory: header.getUint32(16),
        hashLength: 32,
      ).deriveKeyFromPassword(
        password: password,
        nonce: Uint8List.sublistView(header, _saltOffset, _nonceOffset),
      );

  static void _checkPassword(String password) {
    if (password.isEmpty || password.length > 1024) {
      throw const FormatException('Backup password length is out of bounds.');
    }
  }
}
