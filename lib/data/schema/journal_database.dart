import 'package:drift/drift.dart';

part 'journal_database.g.dart';

/// Versioned schema for the encrypted native journal.
@DriftDatabase(include: {'journal.drift'})
class JournalDatabase extends _$JournalDatabase {
  JournalDatabase(super.executor);

  static const currentSchemaVersion = 4;

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
      if ((from < 1 || from >= currentSchemaVersion) ||
          to != currentSchemaVersion) {
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
        if (from < 3) {
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
        } else {
          await m.addColumn(auditEvents, auditEvents.snapshot);
          // The v3 generated check rounded its finite bound down to zero.
          await customStatement(
            'ALTER TABLE measurements RENAME TO measurements_v3',
          );
          await m.createTable(measurements);
          await customStatement('''
            INSERT INTO measurements (id, kind, value, secondary, measured_at, recorded_at, source)
            SELECT id, kind, value, secondary, measured_at, recorded_at, source
            FROM measurements_v3
          ''');
          await customStatement('DROP TABLE measurements_v3');
          await m.createIndex(measurementsTime);
        }
        if (from >= 2) {
          await m.addColumn(
            medicationEvents,
            medicationEvents.originalZoneLabel,
          );
          await m.addColumn(
            medicationEvents,
            medicationEvents.originalOffsetMinutes,
          );
        }
        await _verifyAndStamp();
      });
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
