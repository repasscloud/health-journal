import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/journal_app.dart';
import 'package:health_journal/features/records/record_forms.dart';

void main() {
  testWidgets('demo can edit and a new boot restores the seed', (tester) async {
    await tester.pumpWidget(JournalApp(environment: AppEnvironment.demo()));
    await tester.pumpAndSettle();
    expect(find.text(demoNotice), findsOneWidget);
    await tester.tap(find.text('Add fictional medication'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Fictional new item');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fictional new item'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(JournalApp(environment: AppEnvironment.demo()));
    await tester.pumpAndSettle();
    expect(find.text('Fictional new item'), findsNothing);
  });
  testWidgets('explicit PRN status and accessible multi-point symptom flow', (
    tester,
  ) async {
    final environment = AppEnvironment.demo();
    await tester.pumpWidget(JournalApp(environment: environment));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add regimen'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dose amount (not strength)'),
      '1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dose unit'),
      'tablet',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(environment.repository!.administrations, isEmpty);
    await tester.tap(find.text('Record status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('skipped'));
    await tester.pumpAndSettle();
    expect(environment.repository!.administrations.single.takenAt, isNull);
    await tester.tap(find.text('Symptoms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log fictional symptom'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Symptom title'),
      'Fictional ache',
    );
    await tester.scrollUntilVisible(
      find.text('torso'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SymptomForm),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('torso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('head'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save fictional symptom'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SymptomForm),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save fictional symptom'));
    await tester.pumpAndSettle();
    expect(environment.repository!.symptoms.single.pain.length, 2);
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
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Record fictional measurement'));
      await tester.pumpAndSettle();
      expect(find.text(demoNotice), findsOneWidget);
      expect(tester.takeException(), isNull);
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
  });
}
