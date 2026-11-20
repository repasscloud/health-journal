import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'package:flutter/material.dart';
import 'package:health_journal/core/installation_key.dart';
import 'package:health_journal/data/repositories/native_journal_repository.dart';
import 'package:health_journal/data/repositories/native_records.dart';
import 'package:health_journal/domain/records.dart';
import 'package:health_journal/platform/backup/journal_backup.dart';
import 'package:health_journal/platform/security/native_store.dart';
import 'package:path_provider/path_provider.dart';

final class _ProbeKeys implements InstallationKeyStore {
  String? _key;

  @override
  Future<String?> read() async => _key;

  @override
  Future<void> write(String encodedKey) async => _key = encodedKey;
}

Future<String> _probe(void Function(String) stage) async {
  stage('prepare');
  final cache = await getTemporaryDirectory();
  if (!Platform.isAndroid ||
      !cache.path
          .split(Platform.pathSeparator)
          .contains('com.repasscloud.healthjournal.backupprobe')) {
    return 'WRONG_INSTALLATION';
  }
  final work = await cache.createTemp('fictional_backup_');
  try {
    final sourceDir = await Directory('${work.path}/source').create();
    final targetDir = await Directory('${work.path}/target').create();
    final sourceKeys = _ProbeKeys();
    final targetKeys = _ProbeKeys();
    final source = await NativeStore.openJournalAt(sourceDir, sourceKeys);
    const backup = JournalBackup();
    const password = 'Fictional Android round-trip probe password';
    final stopwatch = Stopwatch();
    final archive = File('${work.path}/fictional.healthbak');
    try {
      await NativeStore.initializeProfile(source);
      final records = NativeRecords(source);
      final day = DateTime.utc(2026, 10, 1);
      await source.transaction(() async {
        for (var i = 0; i < 365; i++) {
          final at = day.add(Duration(days: i));
          await records.addMeasurement(
            Measurement(
              id: 'probe-$i',
              kind: MeasurementKind.weight,
              value: 70 + i / 100,
              unit: 'kg',
              measuredAt: at,
              recordedAt: at,
            ),
          );
        }
      });
      stage('create');
      stopwatch.start();
      await archive.writeAsBytes(
        await backup.create(source, password),
        flush: true,
      );
      stopwatch.stop();
    } finally {
      await source.close();
    }
    final createMs = stopwatch.elapsedMilliseconds;
    stopwatch
      ..reset()
      ..start();
    stage('inspect');
    final preview = await backup.inspect(await archive.readAsBytes(), password);
    final target = await NativeStore.openJournalAt(targetDir, targetKeys);
    try {
      stage('restore');
      await backup.restoreInto(target, preview);
    } finally {
      await target.close();
    }
    final reopened = await NativeStore.openJournalAt(targetDir, targetKeys);
    try {
      stage('reopen');
      final repository = await NativeJournalRepository.load(reopened);
      if (sourceKeys._key == targetKeys._key ||
          repository.measurements.length != 365 ||
          !repository.measurements.any(
            (m) => m.id == 'probe-364' && m.value == 73.64,
          )) {
        throw StateError('Round-trip verification failed.');
      }
    } finally {
      await reopened.close();
    }
    stopwatch.stop();
    // Read the actual writer parameters from the V1 archive. Time the same
    // cryptography implementation off the UI isolate, excluding isolate startup.
    final bytes = await archive.readAsBytes();
    final header = ByteData.sublistView(bytes);
    final lanes = header.getUint8(13);
    final iterations = header.getUint16(14);
    final memory = header.getUint32(16);
    final salt = bytes.sublist(20, 36);
    stage('benchmark');
    final samples = <int>[];
    for (var sample = 0; sample < 5; sample++) {
      samples.add(await _timeKdf(password, salt, lanes, iterations, memory));
    }
    return 'PASS argon2id_kib=$memory iterations=$iterations lanes=$lanes '
        'key_bytes=32 kdf_ms=${samples.join(",")} create_ms=$createMs inspect_restore_reopen_ms=${stopwatch.elapsedMilliseconds} archive_bytes=${await archive.length()}';
  } finally {
    await work.delete(recursive: true);
  }
}

Future<int> _timeKdf(
  String password,
  List<int> salt,
  int lanes,
  int iterations,
  int memory,
) => Isolate.run(() async {
  final timer = Stopwatch()..start();
  final key = await Argon2id(
    parallelism: lanes,
    iterations: iterations,
    memory: memory,
    hashLength: 32,
  ).deriveKeyFromPassword(password: password, nonce: salt);
  timer.stop();
  key.destroy();
  return timer.elapsedMilliseconds;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  var stage = 'startup';
  try {
    result = await _probe((value) => stage = value);
  } catch (_) {
    // Only a sentinel and aggregate timings are emitted.
    result = 'FAIL stage=$stage';
  }
  debugPrint('HEALTH_JOURNAL_BACKUP_PROOF:$result');
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text(result))),
    ),
  );
}
