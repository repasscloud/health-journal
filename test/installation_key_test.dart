import 'package:flutter_test/flutter_test.dart';
import 'package:health_journal/core/installation_key.dart';

class MemoryKeyStore implements InstallationKeyStore {
  String? value;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String encodedKey) async {
    value = encodedKey;
    writes++;
  }
}

void main() {
  test('key is random per install and stable across restart', () async {
    final store = MemoryKeyStore();
    final first = await InstallationKeyService(store)
        .load(databaseExists: false);
    expect(
      await InstallationKeyService(store).load(databaseExists: true),
      first,
    );
    expect(store.writes, 1);
    expect(
      await InstallationKeyService(MemoryKeyStore())
          .load(databaseExists: false),
      isNot(first),
    );
  });
  test('lost or malformed key cannot replace existing records', () async {
    final store = MemoryKeyStore();
    await expectLater(
      InstallationKeyService(store).load(databaseExists: true),
      throwsStateError,
    );
    expect(store.writes, 0);
    store.value = 'not a key';
    await expectLater(
      InstallationKeyService(store).load(databaseExists: false),
      throwsStateError,
    );
    expect(store.writes, 0);
  });
}
