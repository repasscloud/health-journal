import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

/// Never opens a production database using an unencrypted SQLite library.
/// Caller owns the random installation key and its protected storage lifecycle.
Database openEncryptedDatabase(File file, Uint8List key) {
  if (key.length != 32) throw ArgumentError('Expected a 256-bit key.');
  final database = sqlite3.open(file.path);
  try {
    if (database.select('PRAGMA cipher').isEmpty) {
      throw StateError('Encrypted SQLite is unavailable.');
    }
    final hex = key.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    database.execute("PRAGMA key = '$hex'");
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('PRAGMA temp_store = MEMORY');
    database.select('SELECT count(*) FROM sqlite_master');
    return database;
  } catch (_) {
    database.close();
    rethrow;
  }
}
