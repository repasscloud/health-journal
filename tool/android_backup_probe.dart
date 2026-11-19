import 'dart:io';

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

Future<String> _probe() async {
  final cache = await getTemporaryDirectory();
  if (!Platform.isAndroid ||
      !cache.path
          .split(Platform.pathSeparator)
          .contains('com.repasscloud.healthjournal.devicetest')) {
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
    final preview = await backup.inspect(await archive.readAsBytes(), password);
    final target = await NativeStore.openJournalAt(targetDir, targetKeys);
    try {
      await backup.restoreInto(target, preview);
    } finally {
      await target.close();
    }
    final reopened = await NativeStore.openJournalAt(targetDir, targetKeys);
    try {
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
    return 'PASS create_ms=$createMs inspect_restore_reopen_ms=${stopwatch.elapsedMilliseconds} archive_bytes=${await archive.length()}';
  } finally {
    await work.delete(recursive: true);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  try {
    result = await _probe();
  } catch (_) {
    // Only a sentinel and aggregate timings are emitted.
    result = 'FAIL';
  }
  debugPrint('HEALTH_JOURNAL_BACKUP_PROOF:$result');
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text(result))),
    ),
  );
}
