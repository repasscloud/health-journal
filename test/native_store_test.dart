import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/platform/security/native_store.dart';

import 'installation_key_test.dart' show MemoryKeyStore;

void main() {
  late Directory directory;
  setUp(
    () => directory = Directory.systemTemp.createTempSync('fictional_store_'),
  );
  tearDown(() => directory.deleteSync(recursive: true));

  test('protected opener reuses key and preserves encrypted records', () async {
    final keys = MemoryKeyStore();
    var db = await NativeStore.openAt(directory, keys);
    db.execute('CREATE TABLE proof (value TEXT)');
    db.execute("INSERT INTO proof VALUES ('fictional')");
    db.close();
    db = await NativeStore.openAt(directory, keys);
    expect(db.select('SELECT value FROM proof').single['value'], 'fictional');
    db.close();
    expect(keys.writes, 1);
  });

  test(
    'unknown schema is retained without migration or version rewrite',
    () async {
      final keys = MemoryKeyStore();
      final db = await NativeStore.openAt(directory, keys);
      db.execute('PRAGMA user_version=99');
      db.close();
      final before = File('${directory.path}/journal.db').readAsBytesSync();
      await expectLater(NativeStore.openAt(directory, keys), throwsStateError);
      expect(File('${directory.path}/journal.db').readAsBytesSync(), before);
    },
  );

  test('orphaned sidecars prevent silent key regeneration', () async {
    File('${directory.path}/journal.db-wal').writeAsStringSync('fictional');
    final keys = MemoryKeyStore();
    await expectLater(NativeStore.openAt(directory, keys), throwsStateError);
    expect(keys.writes, 0);
    expect(File('${directory.path}/journal.db').existsSync(), isFalse);
  });
}
