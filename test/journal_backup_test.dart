import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/repositories/native_journal_repository.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/platform/backup/journal_backup.dart';
import 'package:health_journal/platform/backup/portable_backup_cipher.dart';
import 'package:health_journal/platform/security/journal_pin.dart';
import 'package:health_journal/platform/security/native_store.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

void main() {
  test('validated backup restores on a different key and replacement rolls back on failure', () async {
    final directory = Directory.systemTemp.createTempSync('fictional_backup_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final sourceDir = Directory('${directory.path}/source')..createSync();
    final targetDir = Directory('${directory.path}/target')..createSync();
    final sourceKeys = MemoryKeyStore();
    final targetKeys = MemoryKeyStore();
    final source = await NativeStore.openJournalAt(sourceDir, sourceKeys);
    addTearDown(source.close);

    final time = DateTime.utc(2026, 11, 19);
    SymptomEntry symptom(String id, String title, {DateTime? updatedAt}) =>
        SymptomEntry(
          id: id,
          title: title,
          onsetAt: time,
          recordedAt: time,
          updatedAt: updatedAt,
          pain: [
            PainObservation(
              id: 'pain-$id',
              view: 'front',
              x: .5,
              y: .3,
              severity: 3,
            ),
          ],
        );

    await NativeStore.initializeProfile(source);
    final repository = await NativeJournalRepository.load(source);
    await repository.addSymptom(symptom('original', 'Fictional original'));
    await repository.reviseSymptom(
      symptom(
        'original',
        'Fictional revised',
        updatedAt: time.add(const Duration(minutes: 1)),
      ),
    );

    const backup = JournalBackup();
    const password = 'Fictional backup interoperability password';
    final sourcePin = JournalPin(MemoryKeyStore());
    final targetPin = JournalPin(MemoryKeyStore());
    expect(await sourcePin.configure(current: '', next: '123456'), isTrue);
    final file = await backup.create(source, password);
    const newPassword = 'A different fictional backup password';
    final newerFile = await backup.create(source, newPassword);
    await source.close();
    var target = await NativeStore.openJournalAt(targetDir, targetKeys);
    addTearDown(() => target.close());
    final preview = await backup.inspect(file, password);
    await expectLater(backup.inspect(file, newPassword), throwsException);
    await expectLater(backup.inspect(newerFile, password), throwsException);
    expect(
      (await backup.inspect(newerFile, newPassword)).counts,
      preview.counts,
    );
    expect(
      preview.counts.keys,
      unorderedEquals([
        'profile',
        'medications',
        'medication_regimens',
        'medication_schedule_rules',
        'medication_events',
        'symptom_entries',
        'pain_markers',
        'symptom_tags',
        'measurements',
        'journal_notes',
        'audit_events',
        'journal_settings',
      ]),
    );
    expect(preview.counts['profile'], 1);
    expect(preview.counts['pain_markers'], 1);
    expect(preview.counts['audit_events'], 1);

    await backup.restoreInto(target, preview);
    expect(targetKeys.value, isNot(sourceKeys.value));
    expect(await sourcePin.isEnabled(), isTrue);
    expect(await targetPin.isEnabled(), isFalse);
    final restored = await NativeJournalRepository.load(target);
    expect(restored.symptoms.single.title, 'Fictional revised');
    expect(
      restored.symptomHistory('original').single.title,
      'Fictional original',
    );
    expect(restored.symptoms.single.pain.single.assetVersion, 'v1');

    await restored.addSymptom(symptom('local', 'Fictional local record'));
    await expectLater(backup.restoreInto(target, preview), throwsStateError);
    await target.customStatement("""
      CREATE TRIGGER fail_restore BEFORE INSERT ON symptom_entries
      BEGIN SELECT RAISE(ABORT, 'fixture failure'); END
    """);
    await expectLater(
      backup.restoreInto(target, preview, replaceConfirmed: true),
      throwsException,
    );
    expect((await NativeJournalRepository.load(target)).symptoms, hasLength(2));

    await target.customStatement('DROP TRIGGER fail_restore');
    await backup.restoreInto(target, preview, replaceConfirmed: true);
    await target.close();
    target = await NativeStore.openJournalAt(targetDir, targetKeys);
    final reopened = await NativeJournalRepository.load(target);
    expect(reopened.symptoms.single.id, 'original');
    expect((await target.select(target.profile).get()).length, 1);
  });

  test(
    'rejects authenticated unsupported schemas and credential tables',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'fictional_backup_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final db = await NativeStore.openJournalAt(directory, MemoryKeyStore());
      addTearDown(db.close);
      await NativeStore.initializeProfile(db);
      const backup = JournalBackup();
      const cipher = PortableBackupCipher();
      const password = 'Fictional schema compatibility password';
      final file = await backup.create(db, password);
      final clear = await cipher.open(file, password);
      final payload = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      clear.fillRange(0, clear.length, 0);

      for (final schema in [1, 2, 3, 5]) {
        final unsupported = await cipher.seal(
          utf8.encode(jsonEncode({...payload, 'schema': schema})),
          password,
        );
        await expectLater(
          backup.inspect(unsupported, password),
          throwsFormatException,
        );
      }
      final tables = payload['tables'] as Map<String, dynamic>;
      tables['device_credentials'] = [];
      final extraTable = await cipher.seal(
        utf8.encode(jsonEncode(payload)),
        password,
      );
      await expectLater(
        backup.inspect(extraTable, password),
        throwsFormatException,
      );
      expect(await db.select(db.profile).get(), hasLength(1));
    },
  );

  test(
    'process death inside replacement preserves the old encrypted journal',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'fictional_restore_interrupt_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final sourceDir = Directory('${directory.path}/source')..createSync();
      final targetDir = Directory('${directory.path}/target')..createSync();
      final keys = MemoryKeyStore();
      final source = await NativeStore.openJournalAt(
        sourceDir,
        MemoryKeyStore(),
      );
      const backup = JournalBackup();
      const password = 'Fictional interruption test password';
      late final File archive;
      try {
        await NativeStore.initializeProfile(source);
        await source.customStatement(
          "UPDATE profile SET name = 'Fictional replacement'",
        );
        archive = await File('${directory.path}/fictional.healthbak')
            .writeAsBytes(await backup.create(source, password));
      } finally {
        await source.close();
      }
      final target = await NativeStore.openJournalAt(targetDir, keys);
      try {
        await target.customSelect('PRAGMA journal_mode = WAL').getSingle();
        await NativeStore.initializeProfile(target);
        await target.customStatement(
          "UPDATE profile SET name = 'Fictional original'",
        );
      } finally {
        await target.close();
      }

      final ready = File('${directory.path}/ready');
      final child = await Process.start(
        'flutter',
        [
          'test',
          '--no-pub',
          '--reporter',
          'expanded',
          'test/fixtures/restore_process.dart',
        ],
        environment: {
          'HJ_TEST_RESTORE_KEY': keys.value!,
          'HJ_TEST_RESTORE_TARGET': targetDir.path,
          'HJ_TEST_RESTORE_ARCHIVE': archive.path,
          'HJ_TEST_RESTORE_READY': ready.path,
        },
      );
      final errors = child.stderr.transform(utf8.decoder).join();
      final output = child.stdout.transform(utf8.decoder).join();
      int? exitCode;
      unawaited(child.exitCode.then((code) => exitCode = code));
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      try {
        while (!ready.existsSync() &&
            exitCode == null &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        expect(
          ready.existsSync(),
          isTrue,
          reason: exitCode == null ? null : '${await errors}\n${await output}',
        );
        final enginePid = int.parse(ready.readAsStringSync());
        expect(enginePid, isNot(pid));
        expect(Process.killPid(enginePid, ProcessSignal.sigkill), isTrue);
        expect(
          await child.exitCode.timeout(const Duration(seconds: 5)),
          isNot(0),
        );
      } finally {
        child.kill();
      }
      final reopened = await NativeStore.openJournalAt(targetDir, keys);
      try {
        expect(
          (await reopened.select(reopened.profile).getSingle()).name,
          'Fictional original',
        );
        final preview = await backup.inspect(
          await archive.readAsBytes(),
          password,
        );
        await backup.restoreInto(reopened, preview, replaceConfirmed: true);
        expect(
          (await reopened.select(reopened.profile).getSingle()).name,
          'Fictional replacement',
        );
      } finally {
        await reopened.close();
      }
    },
  );
}
