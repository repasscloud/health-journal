import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/platform/backup/portable_backup_cipher.dart';

const password = 'Independent fictional password — café';
const payload = 'Fictional journal interoperability vector';
// Independently generated using Python argon2-cffi and cryptography.
// Salt is bytes 0–15 and nonce is bytes 16–27 for this fixture only.
final fixture = base64Decode(
  'SEpCQUsNChoANAEBAQEAAwAAgAAAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobAAAA'
  'KeT3zPTrBprjJRkSAVJUhZ5v3MtWxv+LeWINgUBdS60rlgJOEzv59FTO2Tf1BESuBS0QY7i6RjEylA==',
);

void main() {
  const cipher = PortableBackupCipher();

  test('opens an independent header and ciphertext with only the file and password', () async {
    expect(utf8.decode(await cipher.open(fixture, password)), payload);
  });

  test('every new archive has independent salt and nonce', () async {
    final first = await cipher.seal(utf8.encode(payload), password);
    final second = await cipher.seal(utf8.encode(payload), password);
    expect(first.sublist(20, 36), isNot(second.sublist(20, 36)));
    expect(first.sublist(36, 48), isNot(second.sublist(36, 48)));
    expect(utf8.decode(await cipher.open(first, password)), payload);
    expect(utf8.decode(await cipher.open(second, password)), payload);
  });

  test('rejects wrong password, modified header, ciphertext and tag', () async {
    final authenticationError = throwsA(isA<SecretBoxAuthenticationError>());
    await expectLater(
      cipher.open(fixture, 'incorrect password'),
      authenticationError,
    );
    for (final index in [20, 36, 52, fixture.length - 1]) {
      final modified = Uint8List.fromList(fixture)..[index] ^= 1;
      await expectLater(cipher.open(modified, password), authenticationError);
    }
  });

  test('rejects malformed and excessive input before key derivation', () async {
    for (final malformed in [
      fixture.sublist(0, 51),
      fixture.sublist(0, fixture.length - 1),
      Uint8List.fromList([...fixture, 0]),
      Uint8List.fromList(fixture)..[10] = 2,
      Uint8List.fromList(fixture)..[16] = 255,
      Uint8List.fromList(fixture)..[13] = 3,
      Uint8List(PortableBackupCipher.maxFileBytes + 1),
    ]) {
      await expectLater(
        cipher.open(malformed, password),
        throwsFormatException,
      );
    }
  });
}
