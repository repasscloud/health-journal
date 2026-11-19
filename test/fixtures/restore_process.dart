// Explicitly launched test fixture. It is excluded from normal test discovery.
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/schema/journal_database.dart';
import 'package:health_journal/platform/backup/journal_backup.dart';
import 'package:health_journal/platform/security/encrypted_database.dart';

void main() {
  test('wait inside a fictional restore transaction', () async {
    final target = Platform.environment['HJ_TEST_RESTORE_TARGET']!;
    final archive = Platform.environment['HJ_TEST_RESTORE_ARCHIVE']!;
    final ready = File(Platform.environment['HJ_TEST_RESTORE_READY']!);
    final key = base64Decode(Platform.environment['HJ_TEST_RESTORE_KEY']!);
    final raw = openEncryptedDatabase(File('$target/journal.db'), key);
    key.fillRange(0, key.length, 0);
    raw.execute('PRAGMA cache_size = 1');
    raw.execute('PRAGMA wal_autocheckpoint = 0');
    final journal = _InterruptedJournal(NativeDatabase.opened(raw), ready);
    const service = JournalBackup();
    final preview = await service.inspect(
      await File(archive).readAsBytes(),
      'Fictional interruption test password',
    );
    await service.restoreInto(journal, preview, replaceConfirmed: true);
    await journal.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}

final class _InterruptedJournal extends JournalDatabase {
  _InterruptedJournal(super.executor, this._ready);

  final File _ready;

  @override
  Future<void> customStatement(String statement, [List<dynamic>? args]) async {
    await super.customStatement(statement, args);
    if (statement.startsWith('INSERT INTO "profile"')) {
      _ready.writeAsStringSync('$pid', flush: true);
      await Future<void>.delayed(const Duration(minutes: 1));
    }
  }
}
