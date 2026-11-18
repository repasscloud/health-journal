import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/calendar_date_field.dart';
import 'package:health_journal/app/journal_app.dart';
import 'package:health_journal/features/records/record_forms.dart';
import 'package:health_journal/domain/regimen.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/measurement_units.dart';
import 'package:health_journal/app/demo_notice.dart';

void main() {
  testWidgets('demo can edit and a new boot restores the seed', (tester) async {
    await tester.pumpWidget(
      JournalApp(environment: AppEnvironment.demo(richFixture: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text(demoNotice), findsOneWidget);
    await tester.tap(find.text('Medications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add medication'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Medication name'),
      'Fictional new item',
    );
    await tester.ensureVisible(find.text('Add'));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fictional new item'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      JournalApp(environment: AppEnvironment.demo(richFixture: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fictional new item'), findsNothing);
  });
  testWidgets(
    'medication directions prefill a regimen and saved prescribers can be selected',
    (tester) async {
      final environment = AppEnvironment.demo(richFixture: false);
      final repository = environment.repository!;
      repository.saveMedication(
        Medication(
          id: 'prior-med',
          name: 'Prior medication',
          strength: '',
          form: 'Chewable tablet',
          instructions: 'Example directions across multiple lines.',
          prescribedBy: 'Dr Sample',
          createdAt: DateTime.utc(2020),
        ),
      );
      await tester.pumpWidget(JournalApp(environment: environment));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add medication'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Medication name'),
        'New sample medication',
      );
      final prescriber = find.widgetWithText(TextFormField, 'Prescribed by');
      await tester.ensureVisible(prescriber);
      await tester.pumpAndSettle();
      await tester.enterText(prescriber, 'sample');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr Sample'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(prescriber).controller!.text,
        'Dr Sample',
      );
      await tester.enterText(prescriber, 'Dr New');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(repository.medications.last.prescribedBy, 'Dr New');

      final prior = find.text('Prior medication');
      await tester.ensureVisible(prior);
      await tester.pumpAndSettle();
      await tester.tap(prior);
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Example directions across multiple lines.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Add regimen'));
      await tester.pumpAndSettle();
      final directions = find.widgetWithText(TextFormField, 'Directions');
      final field = tester.widget<TextFormField>(directions);
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: directions, matching: find.byType(TextField)),
            )
            .minLines,
        3,
      );
      expect(
        field.controller!.text,
        'Example directions across multiple lines.',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Dose amount (not strength)'),
        '3',
      );
      await tester.pumpAndSettle();
      expect(find.text('tablets'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repository.regimens.single.unit, 'tablet');
      expect(repository.regimens.single.amount, 3);
      expect(
        repository.regimens.single.instructions,
        'Example directions across multiple lines.',
      );
    },
  );

  testWidgets('ad-hoc intake saves the current time without a regimen', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    final repo = environment.repository!;
    repo.saveMedication(
      Medication(
        id: 'tablet-test',
        name: 'Sample tablet product',
        form: 'Tablet',
        strength: '500',
        strengthUnit: 'mg',
        createdAt: DateTime.utc(2020),
      ),
    );
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record medication'));
    await tester.pumpAndSettle();
    final before = DateTime.now().toUtc();
    await tester.tap(find.text('Sample tablet product'));
    await tester.pumpAndSettle();
    expect(find.text('When taken'), findsOneWidget);
    expect(find.text('Dose unit: tablet'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Recorded dose unit'),
      findsNothing,
    );
    final time = TimeOfDay.fromDateTime(before.toLocal());
    expect(
      find.text(time.format(tester.element(find.byType(AlertDialog)))),
      findsOneWidget,
    );

    final amount = find.widgetWithText(TextFormField, 'Recorded dose amount');
    expect(tester.widget<TextFormField>(amount).controller!.text, isEmpty);
    await tester.enterText(amount, '2');
    await tester.tap(find.text('Save dose'));
    await tester.pumpAndSettle();

    expect(repo.regimens, isEmpty);
    final intake = repo.administrations.single;
    expect(intake.regimenId, isNull);
    expect(intake.amount, 2);
    expect(intake.unit, 'tablet');
    expect(intake.takenAt, intake.occurredAt);
    expect(intake.occurredAt.isBefore(before), isFalse);
    expect(intake.occurredAt.isAfter(intake.recordedAt), isFalse);
    expect(intake.medicationSnapshot?.strength, '500');
    await tester.ensureVisible(find.text('Correct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SimpleDialogOption, 'Taken'), findsOneWidget);
  });

  testWidgets('explicit PRN status and accessible multi-point symptom flow', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medications'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sample medication'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sample medication'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add regimen'));
    await tester.pumpAndSettle();
    final doseAmountField = find.widgetWithText(
      TextFormField,
      'Dose amount (not strength)',
    );
    final doseUnitField = find.widgetWithText(InputDecorator, 'Dose unit');
    expect(find.widgetWithText(TextFormField, 'Dose unit'), findsNothing);
    expect(
      tester.getTopLeft(doseUnitField).dy -
          tester.getBottomLeft(doseAmountField).dy,
      greaterThanOrEqualTo(12),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dose amount (not strength)'),
      '1',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: doseUnitField, matching: find.text('tablet')),
      findsOneWidget,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(environment.repository!.administrations, isEmpty);
    await tester.tap(find.text('Record dose status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skipped'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm entry'));
    await tester.pumpAndSettle();
    expect(environment.repository!.administrations.single.takenAt, isNull);
    await tester.ensureVisible(find.text('Correct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct'));
    await tester.pumpAndSettle();
    for (final status in ['Taken', 'Skipped', 'Missed', 'Unconfirmed']) {
      expect(find.widgetWithText(SimpleDialogOption, status), findsOneWidget);
    }
    await tester.tap(find.text('Taken'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Recorded dose amount'),
      '2',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correction reason (required)'),
      'Fictional correction',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm entry'));
    await tester.pumpAndSettle();
    expect(environment.repository!.administrations.length, 2);
    expect(environment.repository!.administrations.first.takenAt, isNull);
    expect(environment.repository!.administrations.last.amount, 2);
    expect(
      environment.repository!.administrations.last.correctsId,
      environment.repository!.administrations.first.id,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Symptoms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log symptom'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Symptom title'),
      'Fictional ache',
    );
    expect(find.text('Aching'), findsOneWidget);
    final slider = find.byType(Slider);
    final symptomScroll = find
        .descendant(
          of: find.byType(SymptomForm),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(slider, 140, scrollable: symptomScroll);
    await tester.pumpAndSettle();
    final colors = <Color?>[];
    for (final value in [0.0, 5.0, 6.0, 8.0, 9.0, 10.0]) {
      tester.widget<Slider>(slider).onChanged!(value);
      await tester.pumpAndSettle();
      colors.add(tester.widget<Slider>(slider).activeColor);
    }
    expect(colors[0], colors[1]);
    expect(colors[2], colors[3]);
    expect(colors[4], colors[5]);
    expect(colors.toSet(), hasLength(3));
    await tester.scrollUntilVisible(
      find.text('Torso'),
      200,
      scrollable: symptomScroll,
    );
    await tester.tap(find.text('Torso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Head'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save symptom'),
      200,
      scrollable: symptomScroll,
    );
    await tester.tap(find.text('Save symptom'));
    await tester.pumpAndSettle();
    expect(environment.repository!.symptoms.single.pain.length, 2);
    expect(environment.repository!.symptoms.single.pain.first.severity, 10);
    expect(
      environment.repository!.symptoms.single.pain.first.painType,
      'aching',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'narrow screen and large text retain reachable navigation and forms',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(JournalApp(environment: AppEnvironment.demo()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final tab in ['Symptoms', 'Timeline', 'Medications']) {
        await tester.tap(find.widgetWithText(NavigationDestination, tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      final course = find.text('Sample course medication', skipOffstage: false);
      await tester.scrollUntilVisible(
        course,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(course);
      await tester.pumpAndSettle();
      await tester.tap(course);
      await tester.pumpAndSettle();
      final correct = find.widgetWithText(OutlinedButton, 'Correct');
      await tester.scrollUntilVisible(correct, 220);
      await tester.ensureVisible(correct);
      await tester.pumpAndSettle();
      await tester.tap(correct);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(SimpleDialogOption, 'Unconfirmed'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(SimpleDialogOption, 'Cancel'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Record measurement'), findsNothing);
      expect(find.text(demoNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('catalogue edit archives without replacing ID or history', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    final original = environment.repository!.medications.single;
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medications'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sample medication'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sample medication'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit medication'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Medication name'),
      'Edited catalogue',
    );
    final formChoice = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Form',
    );
    await tester.ensureVisible(formChoice);
    await tester.pumpAndSettle();
    await tester.tap(formChoice);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tablet').last);
    await tester.pumpAndSettle();

    final strength = find.widgetWithText(TextFormField, 'Product strength');
    await tester.enterText(strength, 'two');
    final strengthUnit = find.widgetWithText(
      DropdownButtonFormField<String>,
      'Strength unit',
    );
    await tester.ensureVisible(strengthUnit);
    await tester.pumpAndSettle();
    await tester.tap(strengthUnit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('mg — Milligram').last);
    await tester.pumpAndSettle();

    final save = find.text('Save medication');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a positive number, for example 2.5.'),
      findsOneWidget,
    );
    expect(environment.repository!.medications.single, same(original));
    await tester.ensureVisible(strength);
    await tester.pumpAndSettle();
    await tester.enterText(strength, '2.50');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final started = find.widgetWithText(CalendarDateField, 'Started date');
    await tester.ensureVisible(started);
    await tester.pumpAndSettle();
    await tester.tap(started);
    await tester.pumpAndSettle();
    final picker = find.byType(DatePickerDialog);
    final pickedDay = tester.widget<DatePickerDialog>(picker).initialDate!;
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear started date'), findsOneWidget);
    await tester.ensureVisible(find.text('Archived'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.ensureVisible(find.text('Save medication'));
    await tester.tap(find.text('Save medication'));
    await tester.pumpAndSettle();
    expect(environment.repository!.medications.single.id, original.id);
    expect(environment.repository!.medications.single.archived, isTrue);
    expect(environment.repository!.medications.single.form, 'Tablet');
    expect(environment.repository!.medications.single.strength, '2.50');
    expect(environment.repository!.medications.single.strengthUnit, 'mg');
    expect(
      environment.repository!.medications.single.startedAt,
      pickedDay.toUtc(),
    );
    expect(environment.repository!.medicationHistory.single, same(original));
    expect(find.text('Add regimen'), findsNothing);
  });
  testWidgets('multiple schedule times create rules without administrations', (
    tester,
  ) async {
    final environment = AppEnvironment.demo(richFixture: false);
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medications'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sample medication'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sample medication'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add regimen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ScheduleKind>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scheduled').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dose amount (not strength)'),
      '1',
    );
    await tester.ensureVisible(find.text('Add time'));
    await tester.tap(find.text('Add time'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(environment.repository!.regimens.single.rules.length, 2);
    expect(environment.repository!.administrations, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'completed historical course saves and mixed weekdays cannot expand',
    (tester) async {
      final environment = AppEnvironment.demo(richFixture: false);
      await tester.pumpWidget(JournalApp(environment: environment));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medications'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sample medication'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample medication'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add regimen'));
      await tester.pumpAndSettle();
      Future<void> selectDate(String label, DateTime date) async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final field = find.widgetWithText(CalendarDateField, label);
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        final picker = find.byType(DatePickerDialog);
        final dialog = tester.widget<DatePickerDialog>(picker);
        expect(dialog.initialEntryMode, DatePickerEntryMode.calendarOnly);
        Navigator.of(tester.element(picker)).pop(date);
        await tester.pumpAndSettle();
      }

      await selectDate('Effective start date', DateTime(2020, 1, 1));
      await tester.tap(find.byType(DropdownButtonFormField<ScheduleKind>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Course').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Dose amount (not strength)'),
        '1',
      );
      await selectDate('Exclusive end date', DateTime(2020, 1, 1));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(environment.repository!.regimens, isEmpty);
      expect(
        find.text('Choose an end date after the effective start.'),
        findsOneWidget,
      );
      await selectDate('Exclusive end date', DateTime(2020, 1, 5));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        environment.repository!.regimens.single.effectiveTo!.toLocal(),
        DateTime(2020, 1, 5),
      );
      final mixed = Regimen(
        id: 'mixed',
        medicationId: environment.repository!.medications.single.id,
        amount: 1,
        unit: 'tablet',
        kind: ScheduleKind.fixed,
        effectiveFrom: DateTime.utc(2021),
        rules: [
          ScheduleRule(hour: 8, minute: 0, weekdays: {1}),
          ScheduleRule(hour: 18, minute: 0, weekdays: {5}),
        ],
      );
      environment.repository!.addRegimen(mixed);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sample medication'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample medication'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Revise regimen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revise regimen'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('different weekdays per time'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(environment.repository!.regimens.last, same(mixed));
      expect(mixed.rules.first.weekdays, {1});
      expect(mixed.rules.last.weekdays, {5});
    },
  );

  testWidgets(
    'review narrow screen retains notice on nested forms and settings',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final environment = AppEnvironment.fictionalReview();
      await tester.pumpWidget(JournalApp(environment: environment));
      await tester.pumpAndSettle();
      expect(find.text(reviewNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Medications'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sample medication'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Sample medication'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sample medication'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Edit medication').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit medication').first);
      await tester.pumpAndSettle();
      expect(find.text(reviewNotice), findsOneWidget);
      expect(find.text(demoNotice), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Record measurement'), findsNothing);
      expect(find.text(reviewNotice), findsOneWidget);
      expect(find.text(demoNotice), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('appearance follows the system or an explicit override', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final dispatcher = tester.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      JournalApp(environment: AppEnvironment.fictionalReview()),
    );
    await tester.pumpAndSettle();

    final themeControl = find.byType(DropdownButtonFormField<ThemeMode>);
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Scaffold))).brightness;
    expect(brightness(), Brightness.dark);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Units')).dy,
      lessThan(tester.getTopLeft(find.text('Appearance')).dy),
    );
    await tester.ensureVisible(themeControl);
    await tester.pumpAndSettle();

    for (final (label, expected) in [
      ('Light', Brightness.light),
      ('Dark', Brightness.dark),
      ('System', Brightness.dark),
    ]) {
      await tester.tap(themeControl);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(brightness(), expected);
    }
    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
    expect(find.text(reviewNotice), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'demo|fictional', caseSensitive: false)),
      findsNothing,
    );
  });

  for (final (brightness, background, ink) in [
    (Brightness.light, const Color(0xfffafafa), const Color(0xff0a0a0a)),
    (Brightness.dark, const Color(0xff0a0a0a), const Color(0xfff5f5f5)),
  ]) {
    testWidgets(
      'startup draws then fades the logo in ${brightness.name} mode',
      (tester) async {
        final dispatcher = tester.platformDispatcher;
        dispatcher.platformBrightnessTestValue = brightness;
        addTearDown(dispatcher.clearPlatformBrightnessTestValue);
        await tester.pumpWidget(JournalApp(environment: AppEnvironment.demo()));
        final logo = find.byKey(const ValueKey('startup-logo'));
        expect(
          Theme.of(tester.element(logo)).scaffoldBackgroundColor,
          background,
        );
        expect(logo, paintsNothing);

        await tester.pump(const Duration(milliseconds: 1100));
        expect(logo, paintsExactlyCountTimes(#drawPath, 1));

        await tester.pump(const Duration(milliseconds: 1900));
        expect(logo, paintsExactlyCountTimes(#drawPath, 3));
        expect(logo, paints..path(color: ink));

        await tester.pump(const Duration(milliseconds: 900));
        expect(
          logo,
          paints
            ..something((method, arguments) {
              if (method != #saveLayer) return false;
              final alpha = (arguments[1] as Paint).color.a;
              return alpha > 0 && alpha < 1;
            })
            ..path(color: ink)
            ..path(color: ink)
            ..path(color: ink),
        );

        await tester.pump(const Duration(milliseconds: 600));
        expect(logo, paintsNothing);
        expect(find.text('Today'), findsNothing);
        await tester.pump(const Duration(milliseconds: 199));
        expect(find.text('Today'), findsNothing);
        await tester.pump(const Duration(milliseconds: 17));
        expect(logo, findsNothing);
        expect(find.text('Today'), findsWidgets);
      },
    );
  }

  testWidgets('logo plays once and reduced motion skips it', (tester) async {
    final app = JournalApp(environment: AppEnvironment.demo());
    await tester.pumpWidget(app);
    expect(find.byKey(const ValueKey('startup-logo')), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsWidgets);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('startup-logo')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    final dispatcher = tester.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(app);
    expect(find.byKey(const ValueKey('startup-logo')), findsNothing);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets(
    'configured unlock takes precedence and gates access until success',
    (tester) async {
      final result = Completer<bool>();
      var attempts = 0;
      await tester.pumpWidget(
        JournalApp(
          environment: const AppEnvironment.nativePending(),
          unlockOnStartup: () async => ++attempts == 1 ? false : result.future,
        ),
      );
      expect(find.byKey(const ValueKey('startup-logo')), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Could not unlock. Try again.'), findsOneWidget);
      expect(find.text('Setup unavailable'), findsNothing);
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      expect(find.text('Unlocking…'), findsOneWidget);
      expect(find.text('Setup unavailable'), findsNothing);
      result.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Setup unavailable'), findsOneWidget);
    },
  );

  testWidgets(
    'unit preferences apply to forms and timeline without changing stored units',
    (tester) async {
      final environment = AppEnvironment.demo(richFixture: false);
      await tester.pumpWidget(JournalApp(environment: environment));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('No measurements recorded'), findsNothing);
      final weight = find.widgetWithText(
        DropdownButtonFormField<DisplayUnit>,
        'Weight',
      );
      await tester.ensureVisible(weight);
      await tester.tap(weight);
      await tester.pumpAndSettle();
      await tester.tap(find.text('lb').last);
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(NavigationDestination, 'More'), findsNothing);
      final action = find.text('Record measurement');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Value (lb)'),
        '150',
      );
      final save = find.text('Save measurement');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final measurement = environment.repository!.measurements.single;
      expect(measurement.unit, 'kg');
      expect(measurement.value, closeTo(68.0388555, 1e-8));

      await tester.tap(find.widgetWithText(NavigationDestination, 'Timeline'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Search timeline'),
        '150 lb',
      );
      await tester.pumpAndSettle();
      expect(find.text('Weight · 150 lb'), findsOneWidget);
    },
  );

  testWidgets('native cannot accept records before encryption proof', (
    tester,
  ) async {
    await tester.pumpWidget(
      const JournalApp(environment: AppEnvironment.nativePending()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(find.textContaining('No records have been stored'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('No measurements recorded'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
