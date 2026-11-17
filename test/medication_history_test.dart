import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/regimen.dart';

void main() {
  final at = DateTime.utc(2026, 11, 17);
  test(
    'catalogue edits and archive retain full prior version and creation time',
    () {
      final repo = DemoRepository();
      final old = repo.medications.single;
      repo.saveMedication(
        Medication(
          id: old.id,
          name: 'Fictional edited',
          strength: '5',
          strengthUnit: 'mg',
          form: 'tablet',
          genericName: 'Fictional generic',
          brand: 'Sample',
          instructions: 'Sample directions',
          reason: 'Sample reason',
          prescribedBy: 'Fictional clinician',
          notes: 'Sample notes',
          createdAt: old.createdAt,
          updatedAt: at.add(const Duration(days: 1)),
          archived: true,
        ),
      );
      expect(repo.medicationHistory.single, same(old));
      expect(repo.medications.single.archived, isTrue);
      expect(repo.medications.single.strengthUnit, 'mg');
      expect(() => repo.medicationHistory.clear(), throwsUnsupportedError);
      expect(DemoRepository().medicationHistory, isEmpty);
    },
  );
  test('historical statuses and corrections retain original snapshots and audit chain', () {
    final repo = DemoRepository();
    final medication = repo.medications.single;
    final regimen = Regimen(
      id: 'r',
      medicationId: medication.id,
      amount: 1,
      unit: 'tablet',
      kind: ScheduleKind.prn,
      effectiveFrom: at,
    );
    repo.addRegimen(regimen);
    final original = regimen.record(
      eventId: 'e',
      medication: medication,
      status: AdministrationStatus.skipped,
      occurredAt: at,
      recordedAt: at.add(const Duration(days: 2)),
      notes: 'Fictional note',
    );
    repo.recordAdministration(original);
    Administration correction(
      String id, {
      String? target,
      Medication? snapshot,
    }) => Administration(
      id: id,
      medicationId: medication.id,
      medicationNameSnapshot: original.medicationNameSnapshot,
      medicationSnapshot: snapshot ?? original.medicationSnapshot,
      regimenId: original.regimenId,
      regimenSnapshot: original.regimenSnapshot,
      status: AdministrationStatus.taken,
      occurredAt: at,
      takenAt: at,
      recordedAt: at.add(const Duration(days: 3)),
      amount: 2,
      unit: 'tablet',
      correctsId: target ?? original.id,
      correctionReason: 'Corrected fictional status and amount',
    );
    expect(
      () => repo.recordAdministration(correction('bad', target: 'absent')),
      throwsStateError,
    );
    expect(
      () => repo.recordAdministration(
        correction(
          'bad',
          snapshot: Medication(
            id: medication.id,
            name: 'Different',
            strength: '',
            createdAt: at,
          ),
        ),
      ),
      throwsStateError,
    );
    repo.recordAdministration(correction('c'));
    expect(repo.administrations.first, same(original));
    expect(original.status, AdministrationStatus.skipped);
    expect(original.takenAt, isNull);
    expect(repo.administrations.last.amount, 2);
    expect(repo.administrations.last.medicationSnapshot, same(medication));
    expect(
      () => repo.recordAdministration(correction('second')),
      throwsStateError,
    );
    expect(
      repo.timeline().where((i) => i.text.contains('superseded')).length,
      1,
    );
    expect(repo.timeline().first.at, at);
  });
  test('future events and invalid catalogue dates fail validation', () {
    expect(
      () => Administration(
        id: 'e',
        medicationId: 'm',
        medicationNameSnapshot: 'Fictional',
        status: AdministrationStatus.unknown,
        recordedAt: at,
        occurredAt: at.add(const Duration(minutes: 1)),
        amount: 1,
        unit: 'tablet',
      ),
      throwsArgumentError,
    );
    expect(
      () => Medication(
        id: 'm',
        name: 'Fictional',
        strength: '',
        createdAt: at,
        startedAt: at,
        stoppedAt: at.subtract(const Duration(days: 1)),
      ),
      throwsArgumentError,
    );
  });
}
