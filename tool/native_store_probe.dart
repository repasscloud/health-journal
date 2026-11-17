// Dedicated fictional test installation only. Leaves a fictional encrypted store
// to verify keychain/keystore and DB reopen on the next process launch.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_journal/platform/security/native_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var result = 'FAIL';
  try {
    var db = await NativeStore.open();
    final file = File(
      db.select('PRAGMA database_list').first['file'] as String,
    );
    db.execute('PRAGMA journal_mode=WAL');
    db.execute(
      'CREATE TABLE IF NOT EXISTS fictional_probe (value TEXT NOT NULL)',
    );
    const marker = 'FICTIONAL_KEY_STORE_RESTART_PROBE_b7412';
    if (db.select('SELECT * FROM fictional_probe').isEmpty) {
      db.execute('INSERT INTO fictional_probe VALUES (?)', [marker]);
    }
    for (final entry in file.parent.listSync().whereType<File>()) {
      final bytes = latin1.decode(entry.readAsBytesSync());
      if (bytes.contains(marker) || bytes.startsWith('SQLite format 3')) {
        throw StateError('Plaintext file detected.');
      }
    }
    db.close();
    db = await NativeStore.open();
    if (db.select('SELECT value FROM fictional_probe').single['value'] !=
        marker) {
      throw StateError('Reopen failed.');
    }
    db.close();
    result = 'PASS';
  } catch (_) {
    // Do not log database paths, keys, exception contents or records.
  }
  debugPrint('HEALTH_JOURNAL_NATIVE_STORE_PROOF:$result');
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text('Native store proof: $result'))),
    ),
  );
}
