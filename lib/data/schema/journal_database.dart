import 'package:drift/drift.dart';

part 'journal_database.g.dart';

/// Isolated schema. Production record entry does not open this database yet.
@DriftDatabase(include: {'journal.drift'})
class JournalDatabase extends _$JournalDatabase {
  JournalDatabase(super.executor);

  static const currentSchemaVersion = 3;

  @override
  int get schemaVersion => currentSchemaVersion;

  Future<void> _verifyAndStamp() async {
    if ((await customSelect('PRAGMA foreign_key_check').get()).isNotEmpty) {
      throw StateError('Database relations could not be verified.');
    }
    // Drift also writes this after opening. Include it in the transaction so
    // a process exit between the DDL commit and Drift's write is recoverable.
    await customStatement('PRAGMA user_version = $currentSchemaVersion');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => transaction(() async {
      await m.createAll();
      await _verifyAndStamp();
    }),
    onUpgrade: (m, from, to) async {
      if ((from != 1 && from != 2) || to != currentSchemaVersion) {
        throw StateError('Unsupported schema. Existing records retained.');
      }
      await transaction(() async {
        if (from == 1) {
          await customStatement(
            'ALTER TABLE medication_events RENAME TO medication_events_v1',
          );
          await m.createTable(medicationEvents);
          await customStatement('''
          INSERT INTO medication_events (
            id, medication_id, regimen_id, occurrence_key, status, intended_at,
            taken_at, recorded_at, occurred_at, amount, unit,
            legacy_medication_snapshot
          )
          SELECT e.id, r.medication_id, e.regimen_id, e.occurrence_key, e.status,
            e.intended_at, e.taken_at, e.recorded_at, e.taken_at, e.amount,
            e.unit, e.medication_snapshot
          FROM medication_events_v1 e
          LEFT JOIN medication_regimens r ON r.id = e.regimen_id
        ''');
          await customStatement('DROP TABLE medication_events_v1');
          await m.createIndex(medicationEventsTime);
        }
        for (final column in [
          medications.genericName,
          medications.brand,
          medications.form,
          medications.strengthUnit,
          medications.instructions,
          medications.reason,
          medications.prescribedBy,
          medications.notes,
          medications.startedAt,
          medications.stoppedAt,
          medications.pausedAt,
        ]) {
          await m.addColumn(medications, column);
        }
        await m.addColumn(medicationRegimens, medicationRegimens.zonePolicy);
        await m.addColumn(
          medicationRegimens,
          medicationRegimens.reminderEnabled,
        );
        for (final column in [
          symptomEntries.category,
          symptomEntries.pattern,
          symptomEntries.triggers,
          symptomEntries.reliefMeasures,
          symptomEntries.perceivedEffect,
        ]) {
          await m.addColumn(symptomEntries, column);
        }
        await m.createTable(symptomTags);
        await m.createTable(medicationScheduleRules);
        await m.createTable(measurements);
        await m.createIndex(measurementsTime);
        await m.createTable(journalNotes);
        await m.createIndex(journalNotesTime);
        await m.createTable(auditEvents);
        await m.createIndex(auditEventsRecord);
        await m.createTable(journalSettings);
        await _verifyAndStamp();
      });
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
