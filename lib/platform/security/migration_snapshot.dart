import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'encrypted_database.dart';

/// A local recovery point encrypted with the installation key. The caller
/// serializes database opens and holds the only application connection.
Future<void> saveMigrationSnapshot(
  Directory directory,
  Database source,
  Uint8List key,
  int version,
) async {
  final staging = File('${directory.path}/migration-staging.db');
  final destination = File('${directory.path}/pre-upgrade-v$version.db');

  void cleanStaging() {
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('${staging.path}$suffix');
      if (file.existsSync()) file.deleteSync();
    }
  }

  cleanStaging();
  try {
    final copy = openEncryptedDatabase(staging, key);
    try {
      copy.execute('PRAGMA journal_mode = DELETE');
      copy.execute('PRAGMA synchronous = FULL');
      await source.backup(copy).drain<void>();
    } finally {
      copy.close();
    }
    final verified = openEncryptedDatabase(staging, key);
    try {
      if (verified.userVersion != version ||
          verified.select('PRAGMA integrity_check').single.values.single !=
              'ok' ||
          verified.select('PRAGMA foreign_key_check').isNotEmpty) {
        throw StateError('Migration recovery snapshot could not be verified.');
      }
    } finally {
      verified.close();
    }
    // Same-filesystem rename publishes a complete, closed snapshot. Never
    // open the recovery point for writes or automatically replace the journal.
    staging.renameSync(destination.path);
  } finally {
    cleanStaging();
  }
}
