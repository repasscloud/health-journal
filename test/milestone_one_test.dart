import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/journal_app.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/data/repositories/native_journal_repository.dart';
import 'package:health_journal/data/repositories/native_medication_history.dart';
import 'package:health_journal/data/repositories/native_records.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/domain/regimen.dart';
import 'package:health_journal/domain/schedule_occurrences.dart';
import 'package:health_journal/features/records/record_forms.dart';
import 'package:health_journal/features/records/symptom_detail.dart';
import 'package:health_journal/platform/security/native_store.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

void main() {
  final at = DateTime.utc(2026, 1, 5);
  final later = at.add(const Duration(days: 1));
  Medication medication(String name, {DateTime? updatedAt}) => Medication(
    id: 'm',
    name: name,
    strength: '1',
    createdAt: at,
    updatedAt: updatedAt,
  );
  final regimen = Regimen(
    id: 'r',
    medicationId: 'm',
    amount: 1,
    unit: 'tablet',
    kind: ScheduleKind.fixed,
    effectiveFrom: at,
    rules: [
      ScheduleRule(hour: 2, minute: 30, weekdays: {1, 7}),
    ],
  );
  SymptomEntry symptom(
    String title, {
    double? radius,
    DateTime? updatedAt,
    String markerId = 'p',
    String id = 's',
  }) => SymptomEntry(
    id: id,
    title: title,
    onsetAt: at,
    recordedAt: at,
    updatedAt: updatedAt,
    triggers: 'Fictional activity',
    pain: [
      PainObservation(
        id: markerId,
        view: 'back',
        x: .5,
        y: .3,
        severity: 4,
        radius: radius,
      ),
    ],
  );

  test('occurrences skip gaps, choose earlier fold and retain wall slot key across zones', () {
    final spring = DateTime.utc(2026, 3, 8, 7);
    final fall = DateTime.utc(2026, 11, 1, 7);
    Duration offset(DateTime date) => Duration(
      hours: date.isBefore(spring) || !date.isBefore(fall) ? -5 : -4,
    );
    List<ScheduleOccurrence> slots(DateTime day) => occurrencesForDate(
      regimen,
      day,
      offsetAt: offset,
      localize: (date) => date.add(offset(date)),
    );
    expect(slots(spring), isEmpty);
    expect(slots(fall).single.at, DateTime.utc(2026, 11, 1, 6, 30));
    final shifted = occurrencesForDate(
      regimen,
      fall,
      offsetAt: (_) => const Duration(hours: 3),
      localize: (date) => date.add(const Duration(hours: 3)),
    );
    expect(shifted.single.key, slots(fall).single.key);
    expect(shifted.single.at, DateTime.utc(2026, 10, 31, 23, 30));
  });

  test('symptom revisions keep the previous timestamp and marker', () {
    final demo = DemoRepository();
    demo.addSymptom(symptom('Fictional first'));
    demo.reviseSymptom(
      symptom('Fictional second', radius: .07, updatedAt: later),
    );
    expect(demo.symptoms.single.pain.single.radius, .07);
    expect(demo.symptomHistory('s').single.pain.single.radius, isNull);
    expect(() => demo.reviseSymptom(symptom('Stale')), throwsStateError);
    expect(demo.symptomHistory('s'), hasLength(1));
  });

  test('encrypted UI repository reopens records and rolls back a failed marker replacement', () async {
    final directory = Directory.systemTemp.createTempSync(
      'fictional_native_records_',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final keys = MemoryKeyStore();
    var db = await NativeStore.openJournalAt(directory, keys);
    addTearDown(() => db.close());
    await NativeStore.initializeProfile(db);
    var repository = await NativeJournalRepository.load(db);
    expect(repository.medications, isEmpty);
    final original = medication('Fictional catalogue record');
    await repository.saveMedication(original);
    await repository.addRegimen(regimen);
    final event = regimen.record(
      eventId: 'e',
      medication: original,
      status: AdministrationStatus.skipped,
      recordedAt: at.add(const Duration(hours: 4)),
      occurrenceKey: 'r:2026-01-05:02:30',
      intendedAt: at.add(const Duration(hours: 2, minutes: 30)),
      originalZoneLabel: 'ACDT',
      originalOffsetMinutes: 630,
    );
    await repository.recordAdministration(event);
    await repository.saveMedication(
      medication('Fictional revised catalogue', updatedAt: later),
    );
    final next = Regimen(
      id: 'new-regimen',
      medicationId: 'm',
      amount: 2,
      unit: 'tablet',
      kind: ScheduleKind.prn,
      effectiveFrom: later,
    );
    await repository.reviseRegimen('r', next);
    await repository.addSymptom(symptom('Fictional symptom before edit'));
    await repository.reviseSymptom(
      symptom('Fictional symptom after edit', radius: .06, updatedAt: later),
    );
    await repository.addSymptom(
      symptom('Unrelated', markerId: 'unrelated', id: 'other'),
    );
    await expectLater(
      repository.reviseSymptom(
        symptom(
          'Invalid duplicate marker',
          markerId: 'unrelated',
          updatedAt: later.add(const Duration(days: 1)),
        ),
      ),
      throwsException,
    );
    await Future.wait([
      repository.addSymptom(
        symptom(
          'Concurrent record',
          id: 'concurrent',
          markerId: 'concurrent-marker',
        ),
      ),
      repository.addMeasurement(
        Measurement(
          id: 'bp',
          kind: MeasurementKind.bloodPressure,
          value: 120,
          secondary: 80,
          unit: 'mmHg',
          measuredAt: at,
          recordedAt: at,
        ),
      ),
    ]);
    expect(
      repository.symptoms.any((entry) => entry.id == 'concurrent'),
      isTrue,
    );

    await db.close();
    final bytes = latin1.decode(
      File('${directory.path}/journal.db').readAsBytesSync(),
    );
    expect(bytes, isNot(contains('Fictional symptom after edit')));
    db = await NativeStore.openJournalAt(directory, keys);
    final records = NativeRecords(db);
    repository = await NativeJournalRepository.load(db);
    expect(repository.timeline(search: 'fictional symptom').single.id, 's');
    expect(
      repository.administrations.single.occurrenceKey,
      event.occurrenceKey,
    );
    expect(
      repository.symptomHistory('s').single.title,
      'Fictional symptom before edit',
    );
    expect(repository.measurements.single.secondary, 80);
    expect(
      (await records.medication('m'))?.name,
      'Fictional revised catalogue',
    );
    expect((await records.medicationHistory('m')).single.name, original.name);
    expect((await records.regimen('r'))?.effectiveTo, later);
    expect((await records.regimen('r'))?.rules.single.weekdays, {1, 7});
    final persisted = (await NativeMedicationHistory(db).read('e'))!;
    expect(persisted.catalogue?.name, original.name);
    expect(persisted.row.originalOffsetMinutes, 630);
    expect(persisted.row.originalZoneLabel, 'ACDT');
    expect(persisted.row.occurrenceKey, event.occurrenceKey);
    expect(persisted.regimen?.effectiveTo, isNull);
    final saved = (await records.symptom('s'))!;
    expect(saved.title, 'Fictional symptom after edit');
    expect(saved.pain.single.assetVersion, 'v1');
    expect(saved.pain.single.radius, .06);
    expect(
      (await records.symptomHistory('s')).single.pain.single.radius,
      isNull,
    );
    expect((await records.measurement('bp'))?.secondary, 80);
  });

  test('an explicit occurrence cannot be recorded twice', () {
    final demo = DemoRepository();
    final drug = demo.medications.single;
    final scheduled = Regimen(
      id: regimen.id,
      medicationId: drug.id,
      amount: regimen.amount,
      unit: regimen.unit,
      kind: regimen.kind,
      effectiveFrom: regimen.effectiveFrom,
      rules: regimen.rules,
    );
    demo.addRegimen(scheduled);
    final slot = occurrencesForDate(scheduled, DateTime(2026, 1, 12)).single;
    Administration record(String id) => scheduled.record(
      eventId: id,
      medication: drug,
      status: AdministrationStatus.unknown,
      occurredAt: slot.at,
      recordedAt: slot.at,
      occurrenceKey: slot.key,
      intendedAt: slot.at,
    );
    demo.recordAdministration(record('first'));
    expect(
      () => demo.recordAdministration(record('duplicate')),
      throwsStateError,
    );
    expect(demo.administrations.single.status, AdministrationStatus.unknown);
  });

  testWidgets(
    'move an existing marker on its historical asset and inspect prior version',
    (tester) async {
      final demo = DemoRepository();
      final initial = symptom('Fictional symptom');
      demo.addSymptom(initial);
      final savedMap = find.byKey(const ValueKey('saved-map-v1-back'));
      await tester.pumpWidget(
        MaterialApp(
          home: SymptomDetail(
            entry: initial,
            onRevise: demo.reviseSymptom,
            history: () => demo.symptomHistory(initial.id),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(savedMap, findsOneWidget);
      await tester.tap(find.text('Edit symptom'));
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byType(SymptomForm),
            matching: find.byType(Scrollable),
          )
          .first;
      final marker = find.text('Back · Torso · 4/10 · Aching');
      await tester.scrollUntilVisible(marker, 250, scrollable: scroll);
      await tester.pumpAndSettle();
      await tester.tap(marker);
      await tester.pumpAndSettle();
      final head = find.widgetWithText(OutlinedButton, 'Head');
      await tester.scrollUntilVisible(head, 220, scrollable: scroll);
      await tester.pumpAndSettle();
      await tester.tap(head);
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save symptom');
      await tester.scrollUntilVisible(save, 220, scrollable: scroll);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(demo.symptoms.single.pain.single.region, 'head');
      expect(demo.symptoms.single.pain.single.assetVersion, 'v1');
      expect(demo.symptoms.single.pain.single.id, 'p');
      expect(demo.symptomHistory('s').single.pain.single.region, 'torso');
      expect(find.text('Edit history'), findsOneWidget);
    },
  );

  testWidgets('Timeline pages entries and filters by inclusive local dates', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    for (var index = 0; index < 24; index++) {
      final date = at.add(Duration(days: index, hours: 12));
      environment.repository!.addSymptom(
        SymptomEntry(
          id: 'timeline-$index',
          title: 'Fictional entry $index',
          onsetAt: date,
          recordedAt: date,
          severity: index % 10,
        ),
      );
    }
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey(3));
    final scroll = find
        .descendant(of: list, matching: find.byType(Scrollable))
        .first;
    final more = find.text('Show more events');
    await tester.scrollUntilVisible(
      more,
      450,
      maxScrolls: 45,
      scrollable: scroll,
    );
    await tester.pumpAndSettle();
    expect(find.text('Fictional entry 0'), findsNothing);
    await tester.tap(more);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Fictional entry 0'),
      280,
      scrollable: scroll,
    );
    await tester.scrollUntilVisible(
      find.text('Filter by date'),
      -500,
      maxScrolls: 45,
      scrollable: scroll,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter by date'));
    await tester.pumpAndSettle();
    final picker = find.byType(DateRangePickerDialog);
    expect(picker, findsOneWidget);
    final day = DateUtils.dateOnly(at.add(const Duration(hours: 12)).toLocal());
    Navigator.of(tester.element(picker))
        .pop(DateTimeRange(start: day, end: day));
    await tester.pumpAndSettle();
    final symptoms = find.widgetWithText(ChoiceChip, 'Symptoms');
    await tester.ensureVisible(symptoms);
    await tester.tap(symptoms);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 symptom entries'), findsOneWidget);
    expect(find.text('Weekly symptom entries'), findsOneWidget);
    expect(find.text('Fictional entry 1'), findsNothing);
    expect(more, findsNothing);
  });

  testWidgets(
    'symptom save clears navigation inset and regions have aligned spacing',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(392, 750);
      tester.view.padding = const FakeViewPadding(bottom: 32);
      tester.view.viewPadding = const FakeViewPadding(bottom: 32);
      addTearDown(tester.view.reset);
      SymptomEntry? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SymptomForm(onSave: (entry) => saved = entry),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Fictional pain',
      );
      final scroll = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Head'),
        250,
        scrollable: scroll,
      );
      await tester.pumpAndSettle();
      final first = tester.getRect(find.widgetWithText(OutlinedButton, 'Head'));
      final second = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Torso'),
      );
      final next = tester.getRect(
        find.widgetWithText(OutlinedButton, 'Left Arm'),
      );
      expect(first.width, second.width);
      expect(next.top - first.bottom, greaterThanOrEqualTo(12));
      const regions = {
        'Head': 'head',
        'Torso': 'torso',
        'Right Arm': 'right_arm',
        'Left Arm': 'left_arm',
        'Right Leg': 'right_leg',
        'Left Leg': 'left_leg',
      };
      for (final label in regions.keys) {
        final button = find.widgetWithText(OutlinedButton, label);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        await tester.tap(button);
        await tester.pumpAndSettle();
      }
      tester.view.physicalSize = const Size(750, 392);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 110);
      tester.view.padding = const FakeViewPadding();
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save symptom');
      await tester.scrollUntilVisible(save, 220, scrollable: scroll);
      final position = tester.state<ScrollableState>(scroll).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(282));
      tester.view.resetViewInsets();
      tester.view.padding = const FakeViewPadding(bottom: 32);
      await tester.pumpAndSettle();
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(360));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved?.pain.map((point) => point.region), regions.values);
      expect(tester.takeException(), isNull);
    },
  );
}
