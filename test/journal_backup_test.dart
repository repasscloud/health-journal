import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/repositories/native_journal_repository.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/platform/backup/journal_backup.dart';
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
    final file = await backup.create(source, password);
    await source.close();
    var target = await NativeStore.openJournalAt(targetDir, targetKeys);
    addTearDown(() => target.close());
    final preview = await backup.inspect(file, password);
    expect(preview.counts['profile'], 1);
    expect(preview.counts['pain_markers'], 1);
    expect(preview.counts['audit_events'], 1);

    await backup.restoreInto(target, preview);
    expect(targetKeys.value, isNot(sourceKeys.value));
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
}
