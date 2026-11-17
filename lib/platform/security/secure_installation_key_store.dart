import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/installation_key.dart';

/// Native-only adapter. Never instantiate in web composition.
final class SecureInstallationKeyStore implements InstallationKeyStore {
  const SecureInstallationKeyStore();
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
    aOptions: AndroidOptions(),
  );
  static const _key = 'health_journal.installation_database_key.v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String encodedKey) =>
      _storage.write(key: _key, value: encodedKey);
}
