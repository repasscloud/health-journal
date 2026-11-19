import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/installation_key.dart';
import '../../data/schema/journal_database.dart';
import 'encrypted_database.dart';
import 'migration_snapshot.dart';
import 'secure_installation_key_store.dart';

/// Native-only composition for the protected database.
final class NativeStore {
  static const _channel = MethodChannel('health_journal/private_store');

  static Future<JournalDatabase> openJournalAt(
    Directory directory,
    InstallationKeyStore keys,
  ) async {
    final journal = JournalDatabase(
      NativeDatabase.opened(await _openAt(directory, keys, snapshot: true)),
    );
    try {
      await journal.customSelect('PRAGMA user_version').getSingle();
      return journal;
    } catch (_) {
      await journal.close();
      rethrow;
    }
  }

  static Future<JournalDatabase> openJournal() async => openJournalAt(
    await _protectedDirectory(),
    const SecureInstallationKeyStore(),
  );

  static Future<Database> open() async =>
      openAt(await _protectedDirectory(), const SecureInstallationKeyStore());

  static Future<Directory> _protectedDirectory() async {
    final path = await _channel.invokeMethod<String>('prepare');
    if (path == null) throw StateError('Protected storage is unavailable.');
    return Directory(path);
  }

  /// Explicit Start Fresh operation for the native composition.
  /// A retry returns the existing profile without replacing it.
  static Future<ProfileData> initializeProfile(JournalDatabase journal) =>
      journal.transaction(() async {
        await journal.customStatement(
          'INSERT INTO profile (singleton) VALUES (1) ON CONFLICT DO NOTHING',
        );
        return journal.select(journal.profile).getSingle();
      });

  /// Directory must already be private, protected and excluded from OS backup.
  /// A single composition owner must serialize open/close operations.
  static Future<Database> openAt(
    Directory directory,
    InstallationKeyStore keys,
  ) => _openAt(directory, keys);

  static Future<Database> _openAt(
    Directory directory,
    InstallationKeyStore keys, {
    bool snapshot = false,
  }) async {
    final file = File('${directory.path}/journal.db');
    // Orphaned sidecars also count as existing data: never mint a replacement key.
    final exists =
        [
          file.path,
          '${file.path}-wal',
          '${file.path}-shm',
          '${file.path}-journal',
        ].any((path) => File(path).existsSync()) ||
        directory.listSync().whereType<File>().any(
          (file) => file.uri.pathSegments.last.startsWith('pre-upgrade-v'),
        );
    if (exists && !file.existsSync()) {
      throw StateError('Journal is missing. Existing recovery data retained.');
    }
    final key = await InstallationKeyService(keys).load(databaseExists: exists);
    try {
      final db = openEncryptedDatabase(file, key);
      try {
        final version = db.userVersion;
        if (version != 0 &&
            version != 1 &&
            version != 2 &&
            version != 3 &&
            version != JournalDatabase.currentSchemaVersion) {
          throw StateError('Unsupported schema. Existing records retained.');
        }
        if (db.select('PRAGMA quick_check').single.values.single != 'ok' ||
            db.select('PRAGMA foreign_key_check').isNotEmpty) {
          throw StateError(
            'Database validation failed. Existing records retained.',
          );
        }
        if (snapshot &&
            version > 0 &&
            version < JournalDatabase.currentSchemaVersion) {
          await saveMigrationSnapshot(directory, db, key, version);
        }
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
