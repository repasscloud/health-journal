// Release-mode proof target; fictional data only. Never used by production boot.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:health_journal/platform/security/encrypted_database.dart';

void require(bool condition) {
  if (!condition) throw StateError('Encryption proof failed.');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = Directory.systemTemp.createTempSync('journal_proof_');
  var result = 'FAIL';
  try {
    final file = File('${directory.path}/probe.db');
    final random = Random.secure();
    final key = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    final db = openEncryptedDatabase(file, key);
    db.execute('PRAGMA journal_mode=WAL');
    db.execute('CREATE TABLE proof (value TEXT NOT NULL)');
    const marker = 'FICTIONAL_NATIVE_CIPHERTEXT_PROBE_481eb77d';
    db.execute('INSERT INTO proof VALUES (?)', [marker]);
    for (final file in directory.listSync().whereType<File>()) {
      final text = latin1.decode(file.readAsBytesSync());
      require(!text.contains(marker) && !text.startsWith('SQLite format 3'));
    }
    db.close();
    final raw = sqlite3.open(file.path);
    var rejected = false;
    try {
      raw.select('SELECT * FROM proof');
    } catch (_) {
      rejected = true;
    }
    raw.close();
    require(rejected);
    rejected = false;
    try {
      final wrong = openEncryptedDatabase(file, Uint8List(32));
      wrong.close();
    } catch (_) {
      rejected = true;
    }
    require(rejected);
    final reopened = openEncryptedDatabase(file, key);
    require(
      reopened.select('SELECT value FROM proof').single['value'] == marker,
    );
    reopened.close();
    result = 'PASS';
  } catch (_) {
    result = 'FAIL';
  } finally {
    directory.deleteSync(recursive: true);
  }
  // Non-sensitive marker allows adb/device-log automation to verify release proof.
  debugPrint('HEALTH_JOURNAL_ENCRYPTION_PROOF:$result');
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text('Encryption proof: $result'))),
    ),
  );
}
