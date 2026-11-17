import 'package:drift/drift.dart';
part 'journal_database.g.dart';

/// Initial, incomplete schema foundation. Not yet connected to production UI.
@DriftDatabase(include: {'journal.drift'})
class JournalDatabase extends _$JournalDatabase {
  JournalDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      throw StateError(
        'No supported upgrade path. Original database retained.',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.versionBefore != null &&
          details.versionBefore! > schemaVersion) {
        throw StateError('Database was created by a newer app version.');
      }
    },
  );
}
