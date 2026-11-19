import 'package:drift/drift.dart';

import '../../domain/administration_snapshots.dart';
import '../../domain/medication.dart';
import '../../domain/regimen.dart';
import '../schema/journal_database.dart'
    show JournalDatabase, MedicationEvent, MedicationEventsCompanion;

/// Raw v1 facts remain available through [row]. Legacy snapshot text has no
/// published structure and is never interpreted as a current catalogue value.
final class StoredAdministration {
  StoredAdministration(this.row)
    : catalogue = row.catalogueSnapshot == null
          ? null
          : AdministrationSnapshots.readCatalogue(row.catalogueSnapshot!),
      regimen = row.regimenSnapshot == null
          ? null
          : AdministrationSnapshots.readSchedule(row.regimenSnapshot!);

  final MedicationEvent row;
  final Medication? catalogue;
  final Regimen? regimen;
  AdministrationStatus get status =>
      AdministrationStatus.values.byName(row.status);
}

/// Isolated append/read adapter. The production composition does not call it.
final class NativeMedicationHistory {
  NativeMedicationHistory(this._db);
  final JournalDatabase _db;

  Future<StoredAdministration?> read(String id) async {
    final row = await (_db.select(
      _db.medicationEvents,
    )..where((event) => event.id.equals(id))).getSingleOrNull();
    return row == null ? null : StoredAdministration(row);
  }

  Future<void> append(Administration event) => _db.transaction(() async {
    final medication = event.medicationSnapshot;
    final regimen = event.regimenSnapshot;
    if (medication == null ||
        medication.id != event.medicationId ||
        medication.name != event.medicationNameSnapshot ||
        regimen?.id != event.regimenId ||
        (regimen != null && regimen.medicationId != medication.id)) {
      throw ArgumentError('Event snapshots do not match the record.');
    }
    final catalogueValue = AdministrationSnapshots.catalogue(medication);
    final regimenValue = regimen == null
        ? null
        : AdministrationSnapshots.schedule(regimen);
    final recorded = event.recordedAt.microsecondsSinceEpoch;
    final target = event.correctsId;
    if (event.regimenId case final regimenId?) {
      final current = await (_db.select(
        _db.medicationRegimens,
      )..where((r) => r.id.equals(regimenId))).getSingleOrNull();
      if (current?.medicationId != medication.id) {
        throw StateError('Regimen does not belong to the medication.');
      }
    }
    if (target != null) {
      final previous = (await read(target))?.row;
      if (previous == null ||
          previous.medicationId != event.medicationId ||
          previous.regimenId != event.regimenId ||
          previous.catalogueSnapshot != catalogueValue ||
          previous.regimenSnapshot != regimenValue ||
          previous.recordedAt > recorded) {
        throw StateError('Corrections must preserve the original snapshots.');
      }
    } else if (regimen != null && !regimen.contains(event.occurredAt)) {
      throw ArgumentError('Regimen is not effective at this time.');
    }
    await _db
        .into(_db.medicationEvents)
        .insert(
          MedicationEventsCompanion.insert(
            id: event.id,
            medicationId: event.medicationId,
            regimenId: Value(event.regimenId),
            status: event.status.name,
            takenAt: Value(event.takenAt?.microsecondsSinceEpoch),
            recordedAt: recorded,
            occurredAt: Value(event.occurredAt.microsecondsSinceEpoch),
            amount: event.amount,
            unit: event.unit,
            catalogueSnapshot: Value(catalogueValue),
            regimenSnapshot: Value(regimenValue),
            notes: Value(event.notes),
            correctsId: Value(target),
            correctionReason: Value(
              target == null ? null : event.correctionReason,
            ),
          ),
        );
  });
}
