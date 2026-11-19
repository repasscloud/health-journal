import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../data/repositories/native_journal_repository.dart';
import '../../data/schema/journal_database.dart';
import 'portable_backup_cipher.dart';

/// Authenticated, validated content held in RAM until the user decides
/// whether to restore. No device secrets are part of the payload.
final class JournalBackupPreview {
  JournalBackupPreview._(this.createdAt, this._tables)
    : counts = Map.unmodifiable(
        _tables.map((name, rows) => MapEntry(name, rows.length)),
      );

  final DateTime createdAt;
  final Map<String, int> counts;
  final Map<String, List<List<Object?>>> _tables;
}

final class JournalBackup {
  const JournalBackup();

  static const _cipher = PortableBackupCipher();
  static const _payloadSchema = 4;
  // Parent rows precede dependent rows. The exact allowlist deliberately
  // contains journal data only; credentials live in platform secure storage.
  static List<TableInfo> _tables(JournalDatabase db) => [
    db.profile,
    db.medications,
    db.medicationRegimens,
    db.medicationScheduleRules,
    db.medicationEvents,
    db.symptomEntries,
    db.painMarkers,
    db.symptomTags,
    db.measurements,
    db.journalNotes,
    db.auditEvents,
    db.journalSettings,
  ];

  Future<Uint8List> create(JournalDatabase db, String password) async {
    _requireSchema(db);
    final payload = await db.transaction(() async {
      if (await db.select(db.profile).getSingleOrNull() == null) {
        throw StateError('Start the journal before creating a backup.');
      }
      return utf8.encode(
        jsonEncode({
          'schema': _payloadSchema,
          'created_utc': DateTime.now().toUtc().toIso8601String(),
          'tables': {
            for (final table in _tables(db))
              table.actualTableName: [
                for (final row
                    in await db
                        .customSelect(
                          'SELECT * FROM "${table.actualTableName}"',
                        )
                        .get())
                  [for (final column in table.$columns) row.data[column.name]],
              ],
          },
        }),
      );
    });
    try {
      final archive = await _cipher.seal(payload, password);
      final verified = await _cipher.open(archive, password);
      verified.fillRange(0, verified.length, 0);
      return archive;
    } finally {
      payload.fillRange(0, payload.length, 0);
    }
  }

  Future<JournalBackupPreview> inspect(Uint8List file, String password) async {
    if (JournalDatabase.currentSchemaVersion != _payloadSchema) {
      throw StateError('The backup reader requires a schema update.');
    }
    final payload = await _cipher.open(file, password);
    final staging = _StagingJournal();
    try {
      final content = jsonDecode(utf8.decode(payload));
      if (content is! Map<String, dynamic> ||
          content['schema'] != _payloadSchema ||
          content['created_utc'] is! String ||
          content['tables'] is! Map<String, dynamic>) {
        throw const FormatException('Unsupported journal backup payload.');
      }
      final createdAt = DateTime.tryParse(content['created_utc'] as String);
      final source = content['tables'] as Map<String, dynamic>;
      final tables = _tables(staging);
      if (createdAt == null ||
          !createdAt.isUtc ||
          source.length != tables.length) {
        throw const FormatException('Invalid journal backup manifest.');
      }
      final parsed = <String, List<List<Object?>>>{};
      for (final table in tables) {
        final rows = source[table.actualTableName];
        if (rows is! List) {
          throw const FormatException('Missing journal table.');
        }
        parsed[table.actualTableName] = [
          for (final row in rows) _parseRow(row, table.$columns),
        ];
      }
      final preview = JournalBackupPreview._(createdAt, parsed);
      if (preview.counts['profile'] != 1) {
        throw const FormatException('A backup must contain one profile.');
      }
      await staging.transaction(() => _insert(staging, preview));
      await NativeJournalRepository.load(staging);
      return preview;
    } finally {
      payload.fillRange(0, payload.length, 0);
      await staging.close();
    }
  }

  /// Called only on the live encrypted connection. The outer SQLite
  /// transaction makes replacement atomic through process termination.
  Future<void> restoreInto(
    JournalDatabase db,
    JournalBackupPreview preview, {
    bool replaceConfirmed = false,
  }) => db.transaction(() async {
    _requireSchema(db);
    final tables = _tables(db);
    if (!replaceConfirmed) {
      for (final table in tables) {
        final existing = await db
            .customSelect('SELECT 1 FROM "${table.actualTableName}" LIMIT 1')
            .getSingleOrNull();
        if (existing != null) {
          throw StateError(
            'Replacing an existing journal requires confirmation.',
          );
        }
      }
    }
    await db.customStatement('PRAGMA defer_foreign_keys = ON');
    for (final table in tables.reversed) {
      await db.customStatement('DELETE FROM "${table.actualTableName}"');
    }
    await _insert(db, preview);
  });

  static void _requireSchema(JournalDatabase db) {
    if (db.schemaVersion != _payloadSchema) {
      throw StateError('The backup writer requires a schema update.');
    }
  }

  static Future<void> _insert(
    JournalDatabase db,
    JournalBackupPreview preview,
  ) async {
    await db.customStatement('PRAGMA defer_foreign_keys = ON');
    for (final table in _tables(db)) {
      final columns = table.$columns
          .map((column) => '"${column.name}"')
          .join(',');
      final placeholders = List.filled(table.$columns.length, '?').join(',');
      final statement =
          'INSERT INTO "${table.actualTableName}" ($columns) VALUES ($placeholders)';
      for (final row in preview._tables[table.actualTableName]!) {
        await db.customStatement(statement, row);
      }
    }
    if ((await db.customSelect('PRAGMA foreign_key_check').get()).isNotEmpty) {
      throw const FormatException('Journal backup relationships are invalid.');
    }
  }

  static List<Object?> _parseRow(Object? row, List<GeneratedColumn> columns) {
    if (row is! List || row.length != columns.length) {
      throw const FormatException('Invalid journal backup row.');
    }
    for (final (index, column) in columns.indexed) {
      final value = row[index];
      final valid = value == null
          ? column.$nullable
          : switch (column.type) {
              DriftSqlType.int => value is int,
              DriftSqlType.double => value is num && value.isFinite,
              DriftSqlType.string => value is String,
              _ => false,
            };
      if (!valid) throw const FormatException('Invalid journal backup value.');
    }
    return List<Object?>.unmodifiable(row);
  }
}

// Staging has its own executor and never uses the active database connection.
final class _StagingJournal extends JournalDatabase {
  _StagingJournal()
    : super(
        NativeDatabase.memory(
          setup: (db) {
            db.execute('PRAGMA temp_store = MEMORY');
          },
        ),
      );
}
