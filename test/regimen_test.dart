import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/regimen.dart';

void main() {
  final start = DateTime.utc(2026, 11, 17);
  Regimen prn(String id, {DateTime? end}) => Regimen(
    id: id,
    medicationId: '00000000-0000-4000-8000-000000000001',
    amount: 1,
    unit: 'tablet',
    kind: ScheduleKind.prn,
    effectiveFrom: start,
    effectiveTo: end,
  );

  test('PRN cannot invent due times and courses require an end', () {
    expect(prn('r').rules, isEmpty);
    expect(
      () => Regimen(
        id: 'r',
        medicationId: 'm',
        amount: 1,
        unit: 'tablet',
        kind: ScheduleKind.prn,
        effectiveFrom: start,
        rules: [
          ScheduleRule(hour: 8, minute: 0, weekdays: {1}),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => Regimen(
        id: 'r',
        medicationId: 'm',
        amount: 1,
        unit: 'tablet',
        kind: ScheduleKind.course,
        effectiveFrom: start,
        rules: [
          ScheduleRule(hour: 8, minute: 0, weekdays: {1}),
        ],
      ),
      throwsArgumentError,
    );
  });
  test('multiple daily rules reject overlapping occurrences', () {
    expect(
      () => Regimen(
        id: 'r',
        medicationId: 'm',
        amount: 1,
        unit: 'tablet',
        kind: ScheduleKind.fixed,
        effectiveFrom: start,
        rules: [
          ScheduleRule(hour: 8, minute: 0, weekdays: {1, 2}),
          ScheduleRule(hour: 8, minute: 0, weekdays: {2, 3}),
        ],
      ),
      throwsArgumentError,
    );
    final regimen = Regimen(
      id: 'r',
      medicationId: 'm',
      amount: 1,
      unit: 'tablet',
      kind: ScheduleKind.fixed,
      effectiveFrom: start,
      rules: [
        ScheduleRule(hour: 8, minute: 0, weekdays: {1, 2}),
        ScheduleRule(hour: 18, minute: 0, weekdays: {1, 2}),
      ],
    );
    expect(regimen.rules.length, 2);
  });
  test('effective ranges are exclusive and reject overlapping revisions', () {
    final repository = DemoRepository();
    repository.addRegimen(prn('r', end: start.add(const Duration(days: 2))));
    expect(() => repository.addRegimen(prn('r2')), throwsStateError);
    expect(
      prn(
        'r',
        end: start.add(const Duration(days: 1)),
      ).contains(start.add(const Duration(days: 1))),
      isFalse,
    );
  });
  test('revision closes the old range atomically and preserves past event snapshots', () {
    final repository = DemoRepository();
    repository.addRegimen(prn('old'));
    final old = repository.regimens.single;
    final event = old.record(
      eventId: 'event',
      medication: repository.medications.single,
      status: AdministrationStatus.taken,
      recordedAt: start,
      takenAt: start,
    );
    repository.recordAdministration(event);
    final next = Regimen(
      id: 'next',
      medicationId: old.medicationId,
      amount: 2,
      unit: 'tablet',
      kind: ScheduleKind.prn,
      effectiveFrom: start.add(const Duration(days: 1)),
    );
    repository.reviseRegimen('old', next);
    expect(repository.regimens.first.effectiveTo, next.effectiveFrom);
    expect(repository.regimens.first.contains(next.effectiveFrom), isFalse);
    expect(event.amount, 1);
    expect(event.regimenSnapshot?.kind, ScheduleKind.prn);
    expect(event.regimenSnapshot?.amount, 1);
    expect(event.regimenSnapshot?.unit, 'tablet');
    expect(() => repository.reviseRegimen('next', next), throwsStateError);
    expect(repository.regimens.length, 2);
  });
  test('explicit event retains historical name, amount and instructions', () {
    final repository = DemoRepository();
    final regimen = prn('r');
    repository.addRegimen(regimen);
    expect(repository.administrations, isEmpty);
    final medication = repository.medications.single;
    final event = regimen.record(
      eventId: 'e',
      medication: medication,
      status: AdministrationStatus.skipped,
      recordedAt: start,
    );
    repository.recordAdministration(event);
    repository.saveMedication(
      Medication(
        id: medication.id,
        name: 'Changed fictional name',
        strength: '',
        createdAt: medication.createdAt,
        updatedAt: start,
      ),
    );
    expect(event.medicationNameSnapshot, medication.name);
    expect(event.regimenSnapshot?.kind, ScheduleKind.prn);
    expect(event.regimenSnapshot?.amount, 1);
    expect(event.regimenSnapshot?.unit, 'tablet');
    expect(event.takenAt, isNull);
    expect(() => repository.recordAdministration(event), throwsStateError);
  });
}
