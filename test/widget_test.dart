import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/journal_app.dart';

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
