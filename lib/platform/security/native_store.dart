import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/installation_key.dart';
import 'encrypted_database.dart';
import 'secure_installation_key_store.dart';

/// Native-only composition for the protected database. Not exposed to record UI
/// until the release and device security acceptance checks have passed.
final class NativeStore {
  static const _channel = MethodChannel('health_journal/private_store');

  static Future<Database> open() async {
    final path = await _channel.invokeMethod<String>('prepare');
    if (path == null) throw StateError('Protected storage is unavailable.');
    return openAt(Directory(path), const SecureInstallationKeyStore());
  }

  /// Directory must already be private, protected and excluded from OS backup.
  /// A single composition owner must serialize open/close operations.
  static Future<Database> openAt(
    Directory directory,
    InstallationKeyStore keys,
  ) async {
    final file = File('${directory.path}/journal.db');
    // Orphaned sidecars also count as existing data: never mint a replacement key.
    final exists = [
      file.path,
      '${file.path}-wal',
      '${file.path}-shm',
      '${file.path}-journal',
    ].any((path) => File(path).existsSync());
    final key = await InstallationKeyService(keys).load(databaseExists: exists);
    try {
      final db = openEncryptedDatabase(file, key);
      try {
        final version = db.select('PRAGMA user_version').single.values.single;
        if (version != 0 && version != 1) {
          throw StateError('Unsupported schema. Existing records retained.');
        }
        if (db.select('PRAGMA quick_check').single.values.single != 'ok' ||
            db.select('PRAGMA foreign_key_check').isNotEmpty) {
          throw StateError(
            'Database validation failed. Existing records retained.',
          );
        }
        // No upgrade path exists yet. Never run speculative DDL or recovery
        // through deletion; SQLite transactional migrations must be tested first.
        return db;
      } catch (_) {
        db.close();
        rethrow;
      }
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }
}
