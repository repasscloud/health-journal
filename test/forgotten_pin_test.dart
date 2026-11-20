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
}
