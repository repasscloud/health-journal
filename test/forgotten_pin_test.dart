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
}
