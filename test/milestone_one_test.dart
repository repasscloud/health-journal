import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/journal_app.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/data/repositories/native_journal_repository.dart';
import 'package:health_journal/data/repositories/native_medication_history.dart';
import 'package:health_journal/data/repositories/native_records.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/measurement_units.dart';
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
    reminderEnabled: true,
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
    double x = .5,
    double y = .3,
  }) => SymptomEntry(
    id: id,
    title: title,
    onsetAt: at,
    recordedAt: at,
    updatedAt: updatedAt,
    endAt: at.add(const Duration(hours: 4)),
    category: 'Fictional category',
    triggers: 'Fictional activity',
    relief: 'Fictional rest',
    effect: 'Fictional effect',
    pattern: 'intermittent',
    pain: [
      PainObservation(
        id: markerId,
        view: 'back',
        x: x,
        y: y,
        severity: 4,
        radius: radius,
      ),
      PainObservation(
        id: '$markerId-secondary',
        view: 'front',
        assetVersion: 'v2',
        x: .57,
        y: .32,
        severity: 8,
        painType: 'sharp',
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
    expect(demo.symptoms.single.pain.first.radius, .07);
    expect(demo.symptomHistory('s').single.pain.first.radius, isNull);
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
    const preferences = JournalPreferences(
      units: MeasurementUnits(weight: DisplayUnit.pounds),
      appearance: JournalAppearance.dark,
    );
    await repository.savePreferences(preferences);
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
    final duplicate = regimen.record(
      eventId: 'duplicate',
      medication: original,
      status: AdministrationStatus.unknown,
      recordedAt: event.recordedAt,
      occurrenceKey: event.occurrenceKey,
      intendedAt: event.intendedAt,
    );
    await expectLater(
      repository.recordAdministration(duplicate),
      throwsStateError,
    );
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
    final correction = Administration(
      id: 'correction',
      medicationId: original.id,
      medicationNameSnapshot: original.name,
      medicationSnapshot: event.medicationSnapshot,
      regimenId: event.regimenId,
      regimenSnapshot: event.regimenSnapshot,
      status: AdministrationStatus.taken,
      recordedAt: later.add(const Duration(hours: 3)),
      occurredAt: event.occurredAt,
      takenAt: event.occurredAt,
      amount: 1,
      unit: 'tablet',
      correctsId: event.id,
      correctionReason: 'Fictional record correction',
      occurrenceKey: event.occurrenceKey,
      intendedAt: event.intendedAt,
      originalZoneLabel: event.originalZoneLabel,
      originalOffsetMinutes: event.originalOffsetMinutes,
    );
    await repository.recordAdministration(correction);
    await repository.addSymptom(symptom('Fictional symptom before edit'));
    await repository.reviseSymptom(
      symptom(
        'Fictional symptom after edit',
        x: .55,
        y: .35,
        radius: .06,
        updatedAt: later,
      ),
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
    expect(repository.preferences.units.weight, DisplayUnit.pounds);
    expect(repository.preferences.appearance, JournalAppearance.dark);
    expect(repository.timeline(search: 'fictional symptom').single.id, 's');
    expect(
      repository.administrations.map((entry) => entry.occurrenceKey),
      everyElement(event.occurrenceKey),
    );
    expect(repository.administrations, hasLength(2));
    final reopenedCorrection = repository.administrations.singleWhere(
      (entry) => entry.id == 'correction',
    );
    expect(reopenedCorrection.correctsId, event.id);
    expect(reopenedCorrection.status, AdministrationStatus.taken);
    expect(reopenedCorrection.takenAt, event.occurredAt);
    expect(reopenedCorrection.intendedAt, event.intendedAt);
    expect(reopenedCorrection.originalZoneLabel, 'ACDT');
    expect(reopenedCorrection.originalOffsetMinutes, 630);
    expect(reopenedCorrection.regimenSnapshot?.kind, ScheduleKind.fixed);
    expect(reopenedCorrection.regimenSnapshot?.effectiveTo, isNull);
    expect(occurrenceOutcomes([reopenedCorrection, event]), {
      event.occurrenceKey!: AdministrationStatus.taken,
    });
    expect(next.rules, isEmpty);
    expect(occurrencesForDate(next, DateTime(2026, 1, 6)), isEmpty);
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
    expect((await records.regimen('r'))?.reminderEnabled, isTrue);
    final persisted = (await NativeMedicationHistory(db).read('e'))!;
    expect(persisted.catalogue?.name, original.name);
    expect(persisted.row.originalOffsetMinutes, 630);
    expect(persisted.row.originalZoneLabel, 'ACDT');
    expect(persisted.row.occurrenceKey, event.occurrenceKey);
    expect(persisted.regimen?.effectiveTo, isNull);
    final saved = (await records.symptom('s'))!;
    expect(saved.title, 'Fictional symptom after edit');
    expect(saved.pain.first.assetVersion, 'v1');
    expect(saved.endAt, at.add(const Duration(hours: 4)));
    expect(saved.category, 'Fictional category');
    expect(saved.pattern, 'intermittent');
    expect(saved.triggers, 'Fictional activity');
    expect(saved.relief, 'Fictional rest');
    expect(saved.effect, 'Fictional effect');
    final markers = {for (final point in saved.pain) point.id: point};
    final moved = markers['p']!;
    expect((moved.x, moved.y, moved.radius), (.55, .35, .06));
    expect((moved.view, moved.assetVersion, moved.severity), ('back', 'v1', 4));
    final untouched = markers['p-secondary']!;
    expect(
      (
        untouched.view,
        untouched.assetVersion,
        untouched.severity,
        untouched.painType,
      ),
      ('front', 'v2', 8, 'sharp'),
    );
    expect((untouched.x, untouched.y, untouched.radius), (.57, .32, null));
    final before = (await records.symptomHistory('s')).single.pain
        .singleWhere((p) => p.id == 'p');
    expect((before.x, before.y, before.radius), (.5, .3, null));
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
      expect(demo.symptoms.single.pain.first.region, 'head');
      expect(demo.symptoms.single.pain.first.assetVersion, 'v1');
      expect(demo.symptoms.single.pain.first.id, 'p');
      expect(demo.symptomHistory('s').single.pain.first.region, 'torso');
      expect(find.text('Edit history'), findsOneWidget);
    },
  );

  testWidgets('Timeline pages entries and filters by inclusive local dates', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    for (var index = 0; index < 160; index++) {
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
      find.text('Fictional entry 120'),
      280,
      scrollable: scroll,
    );
    expect(find.text('Fictional entry 119'), findsNothing);
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
    expect(find.textContaining('1 symptom entry'), findsOneWidget);
    expect(find.text('Weekly symptom entries'), findsOneWidget);
    expect(find.text('Fictional entry 1'), findsNothing);
    expect(more, findsNothing);
  });

  testWidgets(
    'historical marker alignment survives orientation and editor zoom',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 780);
      addTearDown(tester.view.reset);
      final original = symptom('Fictional alignment', x: .55, y: .34);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: SymptomDetail(entry: original, onRevise: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      final map = find.byKey(const ValueKey('saved-map-v1-back'));
      final marker = find.byKey(const ValueKey('saved-marker-p'));
      final description = find.bySemanticsLabel(
        'Marker 1, Back view, Torso, Aching, severity 4 out of 10',
      );
      void checkAlignment(Finder artwork, Finder point) {
        final bounds = tester.getRect(artwork);
        final center = tester.getCenter(point);
        expect((center.dx - bounds.left) / bounds.width, closeTo(.55, .001));
        expect((center.dy - bounds.top) / bounds.height, closeTo(.34, .001));
      }

      final detailScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(marker, 250, scrollable: detailScroll);
      await tester.pumpAndSettle();
      checkAlignment(map, marker);
      await tester.scrollUntilVisible(
        description,
        180,
        scrollable: detailScroll,
      );
      tester.view.physicalSize = const Size(780, 360);
      final scroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(map, 210, scrollable: scroll);
      await tester.pumpAndSettle();
      checkAlignment(map, marker);
      tester.view.physicalSize = const Size(360, 780);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Edit symptom'),
        -260,
        scrollable: detailScroll,
      );
      await tester.tap(find.text('Edit symptom'));
      await tester.pumpAndSettle();
      final editorScroll = find
          .descendant(
            of: find.byType(SymptomForm),
            matching: find.byType(Scrollable),
          )
          .first;
      final historicalPoint = find.text('Back · Torso · 4/10 · Aching');
      await tester.scrollUntilVisible(
        historicalPoint,
        320,
        scrollable: editorScroll,
      );
      await tester.tap(historicalPoint);
      await tester.pumpAndSettle();
      final work = find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(SvgPicture),
      );
      final dot = find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(CircleAvatar),
      );
      await tester.scrollUntilVisible(work, -260, scrollable: editorScroll);
      await tester.ensureVisible(work);
      await tester.pumpAndSettle();
      checkAlignment(work, dot);
      final center = tester.getCenter(work);
      final first = await tester.startGesture(center - const Offset(32, 0));
      final second = await tester.startGesture(center + const Offset(32, 0));
      await first.moveBy(const Offset(-25, 0));
      await second.moveBy(const Offset(25, 0));
      await tester.pump();
      await first.moveBy(const Offset(-13, 0));
      await second.moveBy(const Offset(13, 0));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(work).width, greaterThan(220));
      checkAlignment(work, dot);
      semantics.dispose();
    },
  );

  testWidgets('Timeline search isolates record types with a shared ID', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    final repo = environment.repository!;
    repo.addSymptom(
      SymptomEntry(
        id: 'shared',
        title: 'Fictional isolated search',
        onsetAt: at,
        recordedAt: at,
      ),
    );
    repo.addMeasurement(
      Measurement(
        id: 'shared',
        kind: MeasurementKind.weight,
        value: 72,
        unit: 'kg',
        measuredAt: at,
        recordedAt: at,
      ),
    );
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    final search = find.widgetWithText(TextFormField, 'Search timeline');
    await tester.enterText(search, 'weight');
    await tester.pumpAndSettle();
    expect(find.textContaining('Weight'), findsWidgets);
    expect(find.text('Fictional isolated search'), findsNothing);
    await tester.enterText(search, 'isolated search');
    await tester.pumpAndSettle();
    expect(find.text('Fictional isolated search'), findsOneWidget);
    expect(find.textContaining('72 kg'), findsNothing);
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
