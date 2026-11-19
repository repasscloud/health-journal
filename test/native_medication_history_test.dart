import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/repositories/native_medication_history.dart';
import 'package:health_journal/domain/administration_snapshots.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/domain/regimen.dart';
import 'package:health_journal/platform/security/encrypted_database.dart';
import 'package:health_journal/platform/security/native_store.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

const sentinel = 'FICTIONAL_HISTORY_SENTINEL_ad87';
const legacy = 'FICTIONAL_LEGACY_OPAQUE_49d2';

void main() {
  late Directory directory;
  late MemoryKeyStore keys;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('fictional_history_');
    keys = MemoryKeyStore();
  });
  tearDown(() => directory.deleteSync(recursive: true));

  void checkCiphertext({bool expectWal = false}) {
    final files = directory.listSync().whereType<File>().toList();
    expect(files.any((file) => file.path.endsWith('/journal.db')), isTrue);
    if (expectWal) {
      expect(
        files.any((file) => file.path.endsWith('/journal.db-wal')),
        isTrue,
      );
    }
    for (final file in files) {
      final bytes = latin1.decode(file.readAsBytesSync());
      expect(bytes, isNot(contains(sentinel)));
      expect(bytes, isNot(contains(legacy)));
      expect(bytes, isNot(startsWith('SQLite format 3')));
    }
  }

  Future<void> seedV1({bool blockDrop = false}) async {
    final raw = await NativeStore.openAt(directory, keys);
    try {
      final fixture = jsonDecode(
        File('test/fixtures/schema_v1.json').readAsStringSync(),
      );
      for (final entity in fixture['fixed_sql'] as List) {
        raw.execute((entity['sql'] as List).single['sql'] as String);
      }
      raw.execute('INSERT INTO profile VALUES (1, ?, NULL)', [sentinel]);
      raw.execute("INSERT INTO medications VALUES ('m', ?, '10', 0, 1, 2)", [
        sentinel,
      ]);
      raw.execute('''
        INSERT INTO medication_regimens
        VALUES ('r','m',1,'tablet','fixed',1,NULL,'Current directions')
      ''');
      raw.execute(
        '''
        INSERT INTO medication_events VALUES
        ('old-skip','r','occ-1','skipped',3,NULL,4,1,'tablet',?),
        ('old-dose','r',NULL,'taken',NULL,5,6,2,'tablet',?)
      ''',
        [legacy, legacy],
      );
      if (blockDrop) {
        // A valid FK dependency makes DROP fail after rename and copy.
        raw.execute('''
          CREATE TABLE migration_blocker (
            event_id TEXT NOT NULL REFERENCES medication_events(id)
          )
        ''');
        raw.execute("INSERT INTO migration_blocker VALUES ('old-dose')");
      }
      raw.execute('PRAGMA user_version = 1');
    } finally {
      raw.close();
    }
  }

  test(
    'v1 upgrade and explicit history survive encrypted reopen and edits',
    () async {
      await seedV1();
      checkCiphertext();
      var db = await NativeStore.openJournalAt(directory, keys);
      addTearDown(() => db.close());
      var history = NativeMedicationHistory(db);
      await db.customSelect('PRAGMA journal_mode = WAL').getSingle();
      final skipped = (await history.read('old-skip'))!;
      expect(skipped.status, AdministrationStatus.skipped);
      expect(skipped.row.medicationId, 'm');
      expect(skipped.row.regimenId, 'r');
      expect(skipped.row.legacyMedicationSnapshot, legacy);
      expect(skipped.row.occurrenceKey, 'occ-1');
      expect(skipped.row.intendedAt, 3);
      expect(skipped.row.recordedAt, 4);
      expect(skipped.row.occurredAt, isNull);
      expect(skipped.row.takenAt, isNull);
      expect(skipped.row.correctsId, isNull);
      expect(skipped.row.correctionReason, isNull);
      expect(skipped.row.notes, isNull);
      expect(skipped.catalogue, isNull);
      expect(skipped.regimen, isNull);
      expect((await history.read('old-dose'))!.row.occurredAt, 5);
      expect((await db.select(db.profile).getSingle()).name, sentinel);

      final time = DateTime.utc(2026, 11, 15, 8, 15, 0, 0, 1);
      final medication = Medication(
        id: 'm',
        name: sentinel,
        strength: '10',
        strengthUnit: 'mg',
        createdAt: time,
        notes: sentinel,
      );
      final regimen = Regimen(
        id: 'r',
        medicationId: 'm',
        amount: 1,
        unit: 'tablet',
        kind: ScheduleKind.fixed,
        effectiveFrom: time,
        instructions: sentinel,
        rules: [
          ScheduleRule(hour: 8, minute: 15, weekdays: {7, 2}),
        ],
      );
      final original = regimen.record(
        eventId: 'new',
        medication: medication,
        status: AdministrationStatus.missed,
        occurredAt: time,
        recordedAt: time.add(const Duration(microseconds: 1)),
      );
      await history.append(original);
      await db.customStatement("UPDATE medications SET name = 'Changed'");
      await db.customStatement("UPDATE medication_regimens SET amount = 9");

      final saved = (await history.read('new'))!;
      expect(saved.status, AdministrationStatus.missed);
      expect(saved.catalogue!.name, sentinel);
      expect(saved.regimen!.amount, 1);
      expect(saved.regimen!.rules.single.weekdays, {2, 7});
      expect(saved.row.occurredAt, time.microsecondsSinceEpoch);
      expect(saved.row.recordedAt, time.microsecondsSinceEpoch + 1);
      expect(saved.row.takenAt, isNull);
      expect(
        AdministrationSnapshots.catalogue(saved.catalogue!),
        AdministrationSnapshots.catalogue(medication),
      );
      expect(
        AdministrationSnapshots.schedule(saved.regimen!),
        AdministrationSnapshots.schedule(regimen),
      );

      Administration verifyEvent(
        String id, {
        String? target,
        String medicationId = 'm',
      }) => Administration(
        id: id,
        medicationId: medicationId,
        medicationNameSnapshot: sentinel,
        medicationSnapshot: medicationId == 'm'
            ? saved.catalogue
            : Medication(
                id: medicationId,
                name: sentinel,
                strength: '10',
                createdAt: time,
              ),
        regimenId: target == null ? null : 'r',
        regimenSnapshot: target == null ? null : saved.regimen,
        status: AdministrationStatus.taken,
        occurredAt: time,
        takenAt: time,
        recordedAt: time.add(const Duration(minutes: 1)),
        amount: 1.5,
        unit: 'tablet',
        notes: sentinel,
        correctsId: target,
        correctionReason: target == null ? '' : sentinel,
      );
      await history.append(verifyEvent('ad-hoc'));
      await history.append(verifyEvent('correction', target: 'new'));
      await expectLater(
        history.append(verifyEvent('duplicate', target: 'new')),
        throwsException,
      );
      await expectLater(
        history.append(verifyEvent('orphan', medicationId: 'missing')),
        throwsException,
      );
      expect(await history.read('duplicate'), isNull);
      expect(await history.read('orphan'), isNull);
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle())
            .data
            .values
            .single,
        1,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      checkCiphertext(expectWal: true);

      await db.close();
      checkCiphertext();
      db = await NativeStore.openJournalAt(directory, keys);
      history = NativeMedicationHistory(db);
      final corrected = (await history.read('correction'))!;
      expect(corrected.status, AdministrationStatus.taken);
      expect(corrected.row.takenAt, time.microsecondsSinceEpoch);
      expect(corrected.row.correctsId, 'new');
      expect(corrected.row.correctionReason, sentinel);
      expect(corrected.row.notes, sentinel);
      expect(corrected.catalogue!.strengthUnit, 'mg');
      expect(corrected.regimen!.instructions, sentinel);
      expect((await history.read('new'))!.status, AdministrationStatus.missed);
      expect((await history.read('ad-hoc'))!.row.regimenId, isNull);
      expect(
        (await history.read('old-skip'))!.row.legacyMedicationSnapshot,
        legacy,
      );
      expect(keys.writes, 1);
    },
  );

  test('failed v1 migration rolls DDL, data and version back; retry succeeds', () async {
    await seedV1(blockDrop: true);
    await expectLater(
      NativeStore.openJournalAt(directory, keys),
      throwsA(
        predicate(
          (Object e) => e.toString().contains('FOREIGN KEY constraint failed'),
        ),
      ),
    );
    checkCiphertext();
    final raw = await NativeStore.openAt(directory, keys);
    try {
      expect(raw.userVersion, 1);
      expect(
        raw.select(
          "SELECT name FROM sqlite_master WHERE name = 'medication_events_v1'",
        ),
        isEmpty,
      );
      expect(
        raw
            .select('SELECT medication_snapshot FROM medication_events')
            .map((r) => r.values.single),
        [legacy, legacy],
      );
      expect(
        raw
            .select('SELECT event_id FROM migration_blocker')
            .single
            .values
            .single,
        'old-dose',
      );
      expect(raw.select('PRAGMA foreign_key_check'), isEmpty);
      raw.execute('DROP TABLE migration_blocker');
    } finally {
      raw.close();
    }
    final upgraded = await NativeStore.openJournalAt(directory, keys);
    addTearDown(upgraded.close);
    expect(
      (await upgraded.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      2,
    );
    expect(
      (await NativeMedicationHistory(upgraded).read('old-dose'))!
          .row
          .legacyMedicationSnapshot,
      legacy,
    );
  });

  test('unsupported encrypted version retains original bytes and records', () async {
    await seedV1();
    final raw = await NativeStore.openAt(directory, keys);
    raw.userVersion = 99;
    raw.close();
    final file = File('${directory.path}/journal.db');
    final before = file.readAsBytesSync();
    await expectLater(
      NativeStore.openJournalAt(directory, keys),
      throwsStateError,
    );
    expect(file.readAsBytesSync(), before);
    checkCiphertext();
    final key = Uint8List.fromList(base64Decode((await keys.read())!));
    final preserved = openEncryptedDatabase(file, key);
    try {
      expect(preserved.userVersion, 99);
      expect(
        preserved
            .select(
              'SELECT medication_snapshot FROM medication_events WHERE id = ?',
              ['old-dose'],
            )
            .single
            .values
            .single,
        legacy,
      );
    } finally {
      preserved.close();
      key.fillRange(0, key.length, 0);
    }
    expect(keys.writes, 1);
  });
}
