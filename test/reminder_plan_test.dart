import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/regimen.dart';
import 'package:health_journal/domain/reminder_plan.dart';
import 'package:health_journal/domain/schedule_occurrences.dart';

void main() {
  test(
    'reminder planning excludes opt-outs, archived, PRN and recorded slots',
    () {
      final now = DateTime(2026, 11, 19, 11);
      final effective = now.toUtc().subtract(const Duration(days: 1));
      Medication medication(String id, {bool archived = false}) => Medication(
        id: id,
        name: 'Fictional $id',
        strength: '',
        createdAt: effective,
        archived: archived,
      );
      final active = medication('one');
      final archived = medication('two', archived: true);
      Regimen regimen(String id, Medication parent, {bool prn = false}) =>
          Regimen(
            id: id,
            medicationId: parent.id,
            amount: 1,
            unit: 'tablet',
            kind: prn ? ScheduleKind.prn : ScheduleKind.fixed,
            effectiveFrom: effective,
            rules: prn
                ? []
                : [
                    ScheduleRule(
                      hour: 12,
                      minute: 0,
                      weekdays: {1, 2, 3, 4, 5, 6, 7},
                    ),
                  ],
          );
      final daily = regimen('daily', active);
      final first = occurrencesForDate(daily, now).single;
      final records = [
        daily.record(
          eventId: 'explicit-skip',
          medication: active,
          status: AdministrationStatus.skipped,
          recordedAt: now.toUtc(),
          occurrenceKey: first.key,
          intendedAt: first.at,
        ),
      ];
      final plans = planMedicationReminders(
        now: now,
        medications: [active, archived],
        regimens: [
          daily,
          daily,
          regimen('archived', archived),
          regimen('opt-out', active),
          regimen('prn', active, prn: true),
        ],
        enabledRegimenIds: {'daily', 'archived', 'prn'},
        administrations: records,
      );
      expect(plans, hasLength(6));
      expect(plans.every((slot) => slot.key.startsWith('daily:')), isTrue);
      expect(plans.map((slot) => slot.key), isNot(contains(first.key)));
      expect(records.single.status, AdministrationStatus.skipped);
    },
  );

  test('reminder queue bounds and tie ordering are deterministic', () {
    final now = DateTime(2026, 11, 19, 0);
    final medication = Medication(
      id: 'fictional',
      name: 'Fictional',
      strength: '',
      createdAt: now.toUtc(),
    );
    final regimen = Regimen(
      id: 'daily',
      medicationId: medication.id,
      amount: 1,
      unit: 'tablet',
      kind: ScheduleKind.fixed,
      effectiveFrom: now.toUtc(),
      rules: [
        for (var hour = 0; hour < 24; hour++)
          ScheduleRule(hour: hour, minute: 1, weekdays: {1, 2, 3, 4, 5, 6, 7}),
      ],
    );
    final plan = planMedicationReminders(
      now: now,
      medications: [medication],
      regimens: [regimen],
      enabledRegimenIds: {regimen.id},
      administrations: [],
    );
    expect(plan, hasLength(64));
    expect(plan.first.at.isAfter(now), isTrue);
    expect(plan.last.at.isAfter(now.add(const Duration(days: 7))), isFalse);
    expect(
      plan.map((slot) => slot.at),
      orderedEquals(plan.map((slot) => slot.at).toList()..sort()),
    );
  });
}
