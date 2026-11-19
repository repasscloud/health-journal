// Build only for a verified disposable installation with no existing app data.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:health_journal/data/repositories/native_medication_history.dart';
import 'package:health_journal/domain/medication.dart';
import 'package:health_journal/platform/security/native_store.dart';
import 'package:sqlite3/sqlite3.dart';

const sentinel = 'FICTIONAL_ANDROID_MIGRATION_e427';
const fixture = String.fromEnvironment('FICTIONAL_V1_SQL_BASE64');

void verify(bool condition) {
  if (!condition) throw StateError('Probe verification failed.');
}

void seedV1(Database db) {
  verify(fixture.isNotEmpty);
  final statements = jsonDecode(utf8.decode(base64Decode(fixture))) as List;
  db.execute('BEGIN');
  try {
    for (final sql in statements.cast<String>()) {
      db.execute(sql);
    }
    db.execute(
      "INSERT INTO medications VALUES ('probe-med', ?, '1', 0, 1, 1)",
      [sentinel],
    );
    db.execute('''
      INSERT INTO medication_regimens VALUES
      ('probe-regimen','probe-med',1,'tablet','prn',1,NULL,'')
    ''');
    db.execute(
      '''
      INSERT INTO medication_events VALUES
      ('probe-v1','probe-regimen',NULL,'skipped',NULL,NULL,4,1,'tablet',?)
    ''',
      [sentinel],
    );
    db.userVersion = 1;
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}

void scan(Directory directory, {bool activeWal = false}) {
  final files = directory.listSync().whereType<File>().toList();
  verify(files.any((file) => file.path.endsWith('/journal.db')));
  if (activeWal) {
    verify(files.any((file) => file.path.endsWith('/journal.db-wal')));
  }
  for (final file in files) {
    final content = latin1.decode(file.readAsBytesSync());
    verify(
      !content.contains(sentinel) && !content.startsWith('SQLite format 3'),
    );
  }
}

Future<String> probe() async {
  final raw = await NativeStore.open();
  late final Directory directory;
  late final bool restart;
  try {
    directory = File(raw.select('PRAGMA database_list').first['file'] as String)
        .parent;
    restart = raw.userVersion == 2;
    if (!restart) {
      verify(raw.userVersion == 0);
      seedV1(raw);
    }
  } finally {
    raw.close();
  }

  final db = await NativeStore.openJournal();
  try {
    verify(
      (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ) ==
          2,
    );
    verify(
      (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
            'foreign_keys',
          ) ==
          1,
    );
    verify((await db.customSelect('PRAGMA foreign_key_check').get()).isEmpty);
    final history = NativeMedicationHistory(db);
    final legacy = (await history.read('probe-v1'))!;
    verify(
      legacy.status == AdministrationStatus.skipped &&
          legacy.row.legacyMedicationSnapshot == sentinel &&
          legacy.row.occurredAt == null &&
          legacy.row.recordedAt == 4,
    );
    final time = DateTime.utc(2026, 11, 18);
    if (!restart) {
      await db.customSelect('PRAGMA journal_mode = WAL').getSingle();
      final catalogue = Medication(
        id: 'probe-med',
        name: sentinel,
        strength: '1',
        createdAt: time,
      );
      Administration event(String id, {String? corrects}) => Administration(
        id: id,
        medicationId: catalogue.id,
        medicationNameSnapshot: catalogue.name,
        medicationSnapshot: catalogue,
        status: AdministrationStatus.taken,
        takenAt: time,
        occurredAt: time,
        recordedAt: time.add(Duration(seconds: corrects == null ? 1 : 2)),
        amount: corrects == null ? 1 : 2,
        unit: 'tablet',
        correctsId: corrects,
        correctionReason: corrects == null ? '' : sentinel,
      );
      await history.append(event('probe-new'));
      await history.append(event('probe-correction', corrects: 'probe-new'));
      scan(directory, activeWal: true);
    }
    final original = (await history.read('probe-new'))!;
    final correction = (await history.read('probe-correction'))!;
    verify(
      original.row.amount == 1 &&
          original.row.regimenId == null &&
          original.catalogue?.name == sentinel &&
          correction.row.correctsId == original.row.id &&
          correction.row.amount == 2 &&
          correction.row.correctionReason == sentinel &&
          correction.row.occurredAt == time.microsecondsSinceEpoch &&
          correction.row.recordedAt ==
              time.add(const Duration(seconds: 2)).microsecondsSinceEpoch,
    );
  } finally {
    await db.close();
  }
  scan(directory);
  return restart ? 'PASS_RESTART' : 'PASS_UPGRADE';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var result = 'FAIL';
  try {
    result = await probe();
  } catch (_) {
    // Paths, keys, SQL error contents and records stay out of the logs.
  }
  debugPrint('HEALTH_JOURNAL_MIGRATION_PROOF:$result');
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text(result))),
    ),
  );
}
