import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/features/backup/backup_page.dart';
import 'package:health_journal/platform/backup/journal_backup.dart';
import 'package:health_journal/platform/security/native_store.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

void main() {
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
