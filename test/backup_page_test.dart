import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/app/environment.dart';
import 'package:health_journal/app/journal_app.dart';
import 'package:health_journal/data/demo/demo_repository.dart';
import 'package:health_journal/features/backup/backup_page.dart';
import 'package:health_journal/platform/backup/journal_backup.dart';
import 'package:health_journal/platform/security/native_store.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

void main() {
  testWidgets('backup actions have a gap and system Back returns to Settings', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var busy = false;
    var closed = 0;
    await tester.pumpWidget(
      JournalApp(
        environment: AppEnvironment.production(DemoRepository()),
        backupSettings: (_) => StatefulBuilder(
          builder: (_, setState) => BackupPage(
            populated: true,
            hasArchive: false,
            busy: busy,
            message: null,
            onClose: () => closed++,
            onPick: () => setState(() => busy = true),
            onDiscard: () {},
            onCreate: (_) async {},
            onInspect: (_) async => throw UnimplementedError(),
            onRestore: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    final entry = find.text('Backup and restore');
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();

    final create = find.widgetWithText(FilledButton, 'Create encrypted backup');
    final restore = find.widgetWithText(
      OutlinedButton,
      'Choose backup to restore',
    );
    expect(
      tester.getTopLeft(restore).dy - tester.getBottomLeft(create).dy,
      greaterThanOrEqualTo(8),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(closed, 1);

    await tester.tap(entry);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pump();
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(find.text('Backup and restore'), findsOneWidget);
    expect(closed, 1);
  });

  testWidgets(
    'backup creation shows live length and match and masks each field',
    (tester) async {
      String? createdPassword;
      await tester.pumpWidget(
        MaterialApp(
          home: BackupPage(
            populated: true,
            hasArchive: false,
            busy: false,
            message: null,
            onClose: () {},
            onPick: () {},
            onDiscard: () {},
            onCreate: (password) async => createdPassword = password,
            onInspect: (_) async => throw UnimplementedError(),
            onRestore: (_, _) async {},
          ),
        ),
      );
      await tester.tap(find.text('Create encrypted backup'));
      await tester.pumpAndSettle();
      final password = find.byType(TextField).at(0);
      final confirmation = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      expect(tester.widget<TextField>(confirmation).obscureText, isTrue);

      await tester.enterText(password, 'too short');
      await tester.enterText(confirmation, 'different');
      await tester.pumpAndSettle();
      expect(find.text('Use at least 12 characters.'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);

      await tester.tap(find.byTooltip('Show backup password'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(tester.widget<TextField>(confirmation).obscureText, isTrue);
      await tester.tap(find.byTooltip('Hide backup password'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(password).obscureText, isTrue);

      const valid = 'example password';
      await tester.enterText(password, valid);
      await tester.enterText(confirmation, valid);
      await tester.pumpAndSettle();
      expect(find.text('Minimum length met'), findsOneWidget);
      expect(find.text('Passwords match'), findsOneWidget);

      await tester.tap(find.byTooltip('Show confirm backup password'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(confirmation).obscureText, isFalse);
      final save = find.text('Choose where to save backup');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(createdPassword, valid);

      await tester.tap(find.text('Create encrypted backup'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      expect(tester.widget<TextField>(confirmation).obscureText, isTrue);
    },
  );

  testWidgets(
    'replacement needs an explicit typed confirmation after preview',
    (tester) async {
      final preview = await tester.runAsync(() async {
        final dir = Directory.systemTemp.createTempSync('fictional_preview_');
        final db = await NativeStore.openJournalAt(dir, MemoryKeyStore());
        try {
          await NativeStore.initializeProfile(db);
          const service = JournalBackup();
          const password = 'Fictional preview test password';
          final bytes = await service.create(db, password);
          return await service.inspect(bytes, password);
        } finally {
          await db.close();
          dir.deleteSync(recursive: true);
        }
      });
      bool? approved;
      await tester.pumpWidget(
        MaterialApp(
          home: BackupPage(
            populated: true,
            hasArchive: true,
            busy: false,
            message: null,
            onClose: () {},
            onPick: () {},
            onDiscard: () {},
            onCreate: (_) async {},
            onInspect: (password) async {
              expect(password, 'Fictional preview test password');
              return preview!;
            },
            onRestore: (_, replaceConfirmed) async =>
                approved = replaceConfirmed,
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        'Fictional preview test password',
      );
      await tester.tap(find.text('Preview backup'));
      await tester.pumpAndSettle();
      final replace = find.widgetWithText(FilledButton, 'Replace journal');
      expect(tester.widget<FilledButton>(replace).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'replace');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(replace).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'REPLACE');
      await tester.pumpAndSettle();
      await tester.tap(replace);
      expect(approved, isTrue);
    },
  );
}
