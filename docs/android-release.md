# Android build and release verification

The default production and review APK builds use local development signing.
The CI build checks their application identity, the review-only activity alias,
production backup exclusion and the absence of the Internet permission.

For a production distribution build, set these variables in the local secure
environment or a protected CI job:

- `HEALTH_JOURNAL_KEYSTORE` is the path to the Android upload keystore.
- `HEALTH_JOURNAL_STORE_PASSWORD` is its store password.
- `HEALTH_JOURNAL_KEY_ALIAS` selects the upload key.
- `HEALTH_JOURNAL_KEY_PASSWORD` is the key password.

```sh
ORG_GRADLE_PROJECT_healthJournalDistribution=true \
  flutter build appbundle --release --flavor production
```

The same signing inputs apply to `flutter build apk --release --flavor production`.
The build rejects missing inputs and prevents using distribution signing with
the isolated device-test package. Review always uses development signing.
Keep credentials and keystores outside the repository.

Verify the production APK with `apksigner verify --print-certs`, check its
package ID with `apkanalyzer manifest application-id`, and compare its
signer digest with the authorized key. Record the source commit and the
artifact SHA-256 alongside the acceptance matrix. See the Flutter
[Android signing and release instructions](https://docs.flutter.dev/deployment/android).

The signing hookup was verified with a disposable local certificate on
19 November 2026. Publisher identity, the real upload key, store listing
and publication approval remain release prerequisites.

## Fictional Android backup benchmark

```sh
ORG_GRADLE_PROJECT_healthJournalDeviceTest=true \
ORG_GRADLE_PROJECT_healthJournalBackupProbe=true \
flutter build apk --release --flavor production -t tool/android_backup_probe.dart
```

Verify the application ID is `com.repasscloud.healthjournal.backupprobe`
before installing. Launch the probe and look for
`HEALTH_JOURNAL_BACKUP_PROOF:PASS` in Flutter's device log. No real journal
records are needed. The probe times the Argon2id implementation separately
from export and restore. See [implementation status](../IMPLEMENTATION_STATUS.md)
for the device, artifact, parameters and elapsed times.
