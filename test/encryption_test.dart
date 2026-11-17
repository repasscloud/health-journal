import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:health_journal/platform/security/encrypted_database.dart';

void main() {
  test('ciphertext, WAL and reopen require the installation key', () {
    final directory = Directory.systemTemp.createTempSync('journal_cipher_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/proof.db');
    final random = Random.secure();
    final key = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final db = openEncryptedDatabase(file, key);
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('CREATE TABLE proof (value TEXT NOT NULL)');
    const sentinel = 'FICTIONAL_ENCRYPTION_PROBE_4bc682f1';
    db.execute('INSERT INTO proof VALUES (?)', [sentinel]);
    for (final entry in directory.listSync().whereType<File>()) {
      final bytes = entry.readAsBytesSync();
      expect(latin1.decode(bytes).contains(sentinel), isFalse);
      expect(latin1.decode(bytes).startsWith('SQLite format 3'), isFalse);
    }
    db.close();
    final raw = sqlite3.open(file.path);
    expect(() => raw.select('SELECT * FROM proof'), throwsA(anything));
    raw.close();
    expect(() => openEncryptedDatabase(file, Uint8List(32)), throwsA(anything));
    final reopened = openEncryptedDatabase(file, key);
    expect(
      reopened.select('SELECT value FROM proof').single['value'],
      sentinel,
    );
    reopened.close();
  });
}
