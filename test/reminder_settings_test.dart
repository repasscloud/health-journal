import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/features/reminder_settings.dart';

void main() {
  testWidgets('permission is contextual and denial has a recovery path', (
    tester,
  ) async {
    final calls = <String>[];
    var allow = false;
    var refreshes = 0;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(journalRemindersChannel, (call) async {
      calls.add(call.method);
      return allow;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(journalRemindersChannel, null),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReminderSettings(onPermissionChanged: () => refreshes++),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, ['enabled']);
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();
    expect(
      find.text('Allow Health Journal notifications in Android settings.'),
      findsOneWidget,
    );
    allow = true;
    await tester.tap(find.text('Allow notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send test reminder'));
    await tester.pumpAndSettle();
    expect(calls, ['enabled', 'request', 'request', 'test']);
    expect(refreshes, 2);
    expect(find.text('Test reminder sent.'), findsOneWidget);
  });
}
