import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/platform/security/encrypted_database.dart';
import 'package:health_journal/platform/security/migration_snapshot.dart';
import 'package:health_journal/platform/security/native_store.dart';
import 'package:sqlite3/sqlite3.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

const sentinel = 'FICTIONAL_MIGRATION_RECOVERY_180b';

void main() {
  late Directory directory;
  late MemoryKeyStore keys;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('journal_recovery_test_');
    keys = MemoryKeyStore();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  Future<void> seed(int version, {String journalMode = 'DELETE'}) async {
    final db = await NativeStore.openAt(directory, keys);
    try {
      db.execute('PRAGMA journal_mode = $journalMode');
      final fixture = jsonDecode(
        File('test/fixtures/schema_v$version.json').readAsStringSync(),
      );
      for (final item in fixture['fixed_sql'] as List) {
        db.execute((item['sql'] as List).single['sql'] as String);
      }
      db.execute('INSERT INTO profile VALUES (1, ?, NULL)', [sentinel]);
      db.execute(
        "INSERT INTO symptom_entries (id, title, onset_at, end_at, recorded_at, updated_at, severity, notes) VALUES ('s', ?, 1, NULL, 1, 1, 4, '')",
        [sentinel],
      );
      db.execute('''
        INSERT INTO pain_markers VALUES
        ('p','s','back',0.5,0.3,NULL,'v1','torso','midline',4,'aching')
      ''');
      if (version == 2) {
        db.execute("INSERT INTO medications VALUES ('m', ?, '1', 0, 1, 1)", [
          sentinel,
        ]);
        db.execute(
          "INSERT INTO medication_regimens VALUES ('r','m',1,'tablet','prn',1,NULL,'')",
        );
        db.execute(
          """
          INSERT INTO medication_events (
            id, medication_id, regimen_id, status, recorded_at,
            amount, unit, legacy_medication_snapshot
          ) VALUES ('e','m','r','skipped',2,1,'tablet',?)
        """,
          [sentinel],
        );
      }
      db.userVersion = version;
    } finally {
      db.close();
    }
  }

  void scan() {
    for (final file in directory.listSync().whereType<File>()) {
      final bytes = latin1.decode(file.readAsBytesSync());
      expect(bytes, isNot(contains(sentinel)));
      expect(bytes, isNot(startsWith('SQLite format 3')));
    }
  }

  Future<void> inspectSnapshot(int version) async {
    final file = File('${directory.path}/pre-upgrade-v$version.db');
    final unkeyed = sqlite3.open(file.path, mode: OpenMode.readOnly);
    try {
      expect(() => unkeyed.select('SELECT * FROM profile'), throwsException);
    } finally {
      unkeyed.close();
    }
    final key = base64Decode((await keys.read())!);
    final snapshot = openEncryptedDatabase(file, key);
    try {
      expect(snapshot.userVersion, version);
      expect(
        snapshot.select('SELECT name FROM profile').single.values.single,
        sentinel,
      );
      expect(
        snapshot
            .select('SELECT body_asset_version FROM pain_markers')
            .single
            .values
            .single,
        'v1',
      );
    } finally {
      snapshot.close();
      key.fillRange(0, key.length, 0);
    }
  }

  for (final mode in ['DELETE', 'WAL']) {
    test('SIGKILL before commit preserves v2 in $mode mode', () async {
      await seed(2, journalMode: mode);
      final process = await Process.start(
        'dart',
        ['run', 'test/fixtures/migration_process.dart', directory.path],
        environment: {'HJ_TEST_MIGRATION_KEY': (await keys.read())!},
      );
      final errors = process.stderr.transform(utf8.decoder).join();
      final ready = Completer<int>();
      final output = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.contains('MIGRATION_TRANSACTION_READY') &&
                !ready.isCompleted) {
              ready.complete(int.parse(line.split(' ').last));
            }
          });
      try {
        final reached = await Future.any([
          ready.future.then((_) => true),
          process.exitCode.then((_) => false),
        ]).timeout(const Duration(seconds: 60));
        expect(reached, isTrue, reason: reached ? null : await errors);
        expect(await ready.future, process.pid);
        final sidecar = mode == 'WAL' ? 'wal' : 'journal';
        expect(
          File('${directory.path}/journal.db-$sidecar').existsSync(),
          isTrue,
        );
        scan();
      } finally {
        process.kill(ProcessSignal.sigkill);
        await output.cancel();
      }
      expect(await process.exitCode, -9);
      final raw = await NativeStore.openAt(directory, keys);
      try {
        expect(raw.userVersion, 2);
        expect(
          raw.select(
            "SELECT name FROM sqlite_master WHERE name = 'measurements'",
          ),
          isEmpty,
        );
        expect(
          raw.select('SELECT name FROM profile').single.values.single,
          sentinel,
        );
        expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
      } finally {
        raw.close();
      }
      await inspectSnapshot(2);
      final journal = await NativeStore.openJournalAt(directory, keys);
      try {
        expect(
          (await journal.customSelect('PRAGMA user_version').getSingle())
              .data
              .values
              .single,
          4,
        );
        expect(
          (await journal.select(journal.painMarkers).getSingle())
              .bodyAssetVersion,
          'v1',
        );
        expect(await journal.select(journal.measurements).get(), isEmpty);
        final event = await journal
            .select(journal.medicationEvents)
            .getSingle();
        expect(event.legacyMedicationSnapshot, sentinel);
        expect(event.occurredAt, isNull);
        expect(
          (await journal.select(journal.medications).getSingle()).genericName,
          isNull,
        );
        expect(
          (await journal.select(journal.symptomEntries).getSingle()).category,
          isNull,
        );
      } finally {
        await journal.close();
      }
      await inspectSnapshot(2);
      scan();
    }, timeout: const Timeout(Duration(seconds: 90)));
  }

  test(
    'exported v3 upgrades before the first valid measurement write',
    () async {
      await seed(3);
      final journal = await NativeStore.openJournalAt(directory, keys);
      try {
        expect(
          (await journal.select(journal.symptomEntries).getSingle()).title,
          sentinel,
        );
        await journal.customStatement("""
        INSERT INTO measurements (id, kind, value, measured_at, recorded_at)
        VALUES ('sample','weight',72,1,2)
      """);
        expect(
          (await journal.select(journal.measurements).getSingle()).value,
          72,
        );
        await expectLater(
          journal.customStatement("""
        INSERT INTO measurements (id, kind, value, measured_at, recorded_at)
        VALUES ('invalid','weight',1e999,1,2)
      """),
          throwsException,
        );
      } finally {
        await journal.close();
      }
      await inspectSnapshot(3);
    },
  );

  test('snapshot captures committed WAL rows independently', () async {
    await seed(2, journalMode: 'WAL');
    final journal = await NativeStore.openAt(directory, keys);
    final key = base64Decode((await keys.read())!);
    try {
      journal.execute('PRAGMA wal_autocheckpoint = 0');
      journal.execute("UPDATE profile SET name = 'Superseded fictional name'");
      journal.execute('UPDATE profile SET name = ?', [sentinel]);
      final wal = File('${directory.path}/journal.db-wal');
      expect(wal.lengthSync(), greaterThan(32));
      await saveMigrationSnapshot(directory, journal, key, 2);
      journal.execute("UPDATE profile SET name = 'Later fictional name'");
      await inspectSnapshot(2);
      scan();
    } finally {
      journal.close();
      key.fillRange(0, key.length, 0);
    }
    expect(File('${directory.path}/journal.db-wal').existsSync(), isFalse);
    expect(File('${directory.path}/journal.db-shm').existsSync(), isFalse);
    expect(
      File('${directory.path}/migration-staging.db').existsSync(),
      isFalse,
    );
    await inspectSnapshot(2);
  });

  test('bootstrap is explicit and retries preserve the only profile', () async {
    var journal = await NativeStore.openJournalAt(directory, keys);
    expect(await journal.select(journal.profile).get(), isEmpty);
    await NativeStore.initializeProfile(journal);
    await journal.customStatement('UPDATE profile SET name = ?', [sentinel]);
    await journal.close();
    journal = await NativeStore.openJournalAt(directory, keys);
    try {
      expect((await NativeStore.initializeProfile(journal)).name, sentinel);
      expect(await journal.select(journal.profile).get(), hasLength(1));
      expect(
        (await journal.customSelect('PRAGMA temp_store').getSingle())
            .data
            .values
            .single,
        2,
      );
      await journal.customStatement('CREATE TEMP TABLE scratch (value TEXT)');
      await journal.customStatement('INSERT INTO scratch VALUES (?)', [
        sentinel,
      ]);
      final temp = await journal.customSelect('PRAGMA database_list').get();
      expect(
        temp
            .singleWhere((row) => row.read<String>('name') == 'temp')
            .read<String>('file'),
        isEmpty,
      );
      scan();
    } finally {
      await journal.close();
    }
    scan();
  });

  test(
    'still-keyed snapshot alone prevents silent creation of a new journal',
    () async {
      await seed(2);
      final journal = await NativeStore.openJournalAt(directory, keys);
      await journal.close();
      File('${directory.path}/journal.db')
          .renameSync('${directory.path}/withheld.db');
      await expectLater(
        NativeStore.openJournalAt(directory, keys),
        throwsStateError,
      );
      expect(File('${directory.path}/journal.db').existsSync(), isFalse);
      await inspectSnapshot(2);
    },
  );
}
