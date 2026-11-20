import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/features/security_pin_form.dart';

void main() {
  testWidgets('cancel and partial confirmation preserve the locked journal', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: JournalPinForm(
          enabled: true,
          unlock: true,
          onSubmit: (_, _) async => false,
          onErase: () async {
            requests++;
            return false;
          },
        ),
      ),
    );
    final forgot = find.text('Forgot PIN?');
    await tester.tap(forgot);
    await tester.pumpAndSettle();
    final erase = find.widgetWithText(FilledButton, 'Erase app data');
    final confirmation = find.widgetWithText(TextField, 'Type ERASE');
    expect(tester.widget<FilledButton>(erase).onPressed, isNull);
    await tester.enterText(confirmation, 'erase');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(erase).onPressed, isNull);
    await tester.enterText(confirmation, 'ERASE');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(erase).onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.text('Unlock journal'), findsOneWidget);

    await tester.tap(forgot);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(erase).onPressed, isNull);
    await tester.enterText(confirmation, 'ERASE');
    await tester.pumpAndSettle();
    await tester.tap(erase);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Could not erase app data. Try again.'), findsOneWidget);
    expect(find.text('Unlock journal'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Forgot PIN?'))
          .onPressed,
      isNotNull,
    );
  });
  testWidgets(
    'settings erase requires the current PIN and typed confirmation',
    (tester) async {
      final attempts = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: JournalPinForm(
            enabled: true,
            onSubmit: (_, _) async => false,
            onEraseWithPin: (pin) async {
              attempts.add(pin);
              return false;
            },
          ),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final delete = find.text('Delete all local data');
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter your current PIN to erase app data.'),
        findsOneWidget,
      );
      expect(attempts, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current PIN'),
        '123456',
      );
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Exported PDFs, CSV files and backups'),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Type ERASE'),
        'ERASE',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Erase app data'));
      await tester.pumpAndSettle();
      expect(attempts, ['123456']);
      expect(find.textContaining('Check your PIN'), findsOneWidget);
    },
  );
  testWidgets(
    'failed biometrics leave PIN reachable at large text in landscape',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 420));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var biometricAttempts = 0;
      final pins = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: JournalPinForm(
            enabled: true,
            unlock: true,
            onSubmit: (pin, _) async {
              pins.add(pin);
              return true;
            },
            onBiometricUnlock: () async {
              biometricAttempts++;
              return false;
            },
          ),
        ),
      );

      final biometric = find.widgetWithText(
        OutlinedButton,
        'Unlock with biometrics',
      );
      await tester.ensureVisible(biometric);
      await tester.tap(biometric);
      await tester.pumpAndSettle();
      expect(biometricAttempts, 1);
      expect(pins, isEmpty);
      expect(find.textContaining('Use your journal PIN'), findsOneWidget);

      final pin = find.widgetWithText(TextFormField, 'Journal PIN');
      await tester.ensureVisible(pin);
      await tester.enterText(pin, '123456');
      tester.view.viewInsets = const FakeViewPadding(bottom: 110);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final unlock = find.widgetWithText(FilledButton, 'Unlock');
      await tester.ensureVisible(unlock);
      await tester.pumpAndSettle();
      await tester.tap(unlock);
      await tester.pumpAndSettle();
      expect(pins, ['123456']);
      expect(tester.takeException(), isNull);
    },
  );
}
