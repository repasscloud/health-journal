import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/schema/journal_database.dart';
import 'package:health_journal/platform/security/encrypted_database.dart';

void main() {
  test(
    'unsupported schema upgrade/downgrade leaves original encrypted DB intact',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'fictional_migration_',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/journal.db');
      final key = Uint8List.fromList(
        List.generate(32, (i) => i + 1),
      ); // test only
      final raw = openEncryptedDatabase(file, key);
      raw.execute('CREATE TABLE recovery_sentinel (value TEXT)');
      raw.execute(
        "INSERT INTO recovery_sentinel VALUES ('fictional preserved record')",
      );
      raw.execute('PRAGMA user_version = 99');
      raw.close();
      final before = file.readAsBytesSync();
      final db = JournalDatabase(
        NativeDatabase.opened(openEncryptedDatabase(file, key)),
      );
      await expectLater(
        db.customSelect('SELECT * FROM profile').get(),
        throwsStateError,
      );
      await db.close();
      expect(file.readAsBytesSync(), before);
      final reopened = openEncryptedDatabase(file, key);
      expect(reopened.select('PRAGMA user_version').single.values.single, 99);
      expect(
        reopened.select('SELECT value FROM recovery_sentinel').single['value'],
        'fictional preserved record',
      );
      reopened.close();
    },
  );
}
