// Child process for interruption tests. It accepts only fictional host data.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:health_journal/data/schema/journal_database.dart';
import 'package:health_journal/platform/security/encrypted_database.dart';
import 'package:health_journal/platform/security/migration_snapshot.dart';

Future<void> main(List<String> args) async {
  final directory = Directory(args.single);
  final key = base64Decode(Platform.environment['HJ_TEST_MIGRATION_KEY']!);
  final raw = openEncryptedDatabase(File('${directory.path}/journal.db'), key);
  await saveMigrationSnapshot(directory, raw, key, raw.userVersion);
  raw.execute('PRAGMA cache_size = 1');
  raw.execute('PRAGMA wal_autocheckpoint = 0');
  final journal = _InterruptedJournal(NativeDatabase.opened(raw));
  await journal.customSelect('PRAGMA user_version').getSingle();
}

class _InterruptedJournal extends JournalDatabase {
  _InterruptedJournal(super.executor);

  @override
  MigrationStrategy get migration {
    final normal = super.migration;
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) => transaction(() async {
        await normal.onUpgrade(migrator, from, to);
        stdout.writeln('MIGRATION_TRANSACTION_READY $pid');
        await stdout.flush();
        await Future<void>.delayed(const Duration(minutes: 2));
      }),
    );
  }
}
