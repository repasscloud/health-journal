import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/data/schema/journal_database.dart';

void main() {
  test('initial migration enforces singleton and relationships', () async {
    final db = JournalDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement('INSERT INTO profile (singleton) VALUES (1)');
    await expectLater(
      db.customStatement('INSERT INTO profile (singleton) VALUES (2)'),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement(
        "INSERT INTO medication_regimens VALUES ('r','missing',1,'tablet','prn',1,NULL,'')",
      ),
      throwsA(anything),
    );
    final check = await db.customSelect('PRAGMA foreign_key_check').get();
    expect(check, isEmpty);
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 1);
  });
  test(
    'coordinates and severity cannot bypass the database contract',
    () async {
      final db = JournalDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.customStatement(
        "INSERT INTO symptom_entries VALUES ('s','Fictional pain',1,NULL,1,1,5,'')",
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO pain_markers VALUES ('p','s','front',1.1,0.5,NULL,'v1','arm','left',5,'aching')",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO pain_markers VALUES ('p','s','front',0.5,0.5,NULL,'v1','arm','left',11,'aching')",
        ),
        throwsA(anything),
      );
    },
  );
}
