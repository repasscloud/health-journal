# Personal Medication & Symptom Journal — Build Specification

**Status:** Approved product baseline / implementation handoff  
**Date:** 2026-11-17  
**Working name:** Health Journal (confirm branding and identifiers before release)
**Owner decision:** Free forever, no ads, no subscriptions, no account, no backend, **one profile only**.

## Read order for Claude / Codex

1. `01-PRODUCT-REQUIREMENTS.md` — functional scope and UX
2. `02-ARCHITECTURE-AND-DATA.md` — Flutter structure, database, domain invariants
3. `03-SECURITY-BACKUP-RESTORE.md` — encryption, credentials, backups, portability
4. `04-PLATFORM-AND-DEMO.md` — iOS, Android, demo-only web/PWA, optional desktop
5. `05-IMPLEMENTATION-PLAN-AND-TESTS.md` — work packages and acceptance criteria
6. `AGENTS.md` — instructions for coding agents

## Product statement

A private, offline-first **single-person** medication and symptom journal, with scheduled and as-needed medications, administration records, pain location mapping, symptoms and measurements, reminders, trends, doctor-ready PDF/CSV exports, and user-controlled portable encrypted backups. Public Flutter Web is **a fictional, reset-on-reload demo only**, never a production medical record system.

## Non-negotiable constraints

- **iOS and Android:** full local-first production apps; core operation does not require internet.
- **Web:** interactive public PWA **demo exclusively**; fictional dataset, no real data, reset to seed data on every full load/reload; no browser-persistent user health record.
- **macOS/Windows/Linux:** optional, not a release blocker; only ship if fully supported and tested. Do not use their existence to expand MVP.
- **Exactly one profile** per app installation. No accounts, login, registration, profile switching, family mode, or backend.
- **Completely free:** no paywall, ads, subscriptions, purchase SDKs, tracking SDKs or monetisation tiers.
- **No AI diagnosis, medication recommendations, automated dosing advice or causal claims.** The app records and presents self-reported data.
- **Private by design:** local encrypted database; no transmission of medical data to developer-operated infrastructure.
- **Portable recovery:** password-encrypted backup can be restored on a replacement phone without access to the original phone, app secret or old device key.
- **Loss-aware restore:** fresh installation loads a backup as its only profile; populated installation requires explicit replace confirmation, no merges in v1.
- **Shared business logic:** platform capability adapters, no parallel feature implementations for demo vs native.

## Out of scope for v1

Cloud sync, multi-device live synchronisation, multiple profiles, clinician portal, real medical advice, prescription fulfillment, medication interaction checker, social/community features, automatic AI analysis, scanning/OCR, in-app purchases, advertising, account recovery service, automated off-device upload, and direct syncing of Apple Health Medications.

## Unresolved release-time inputs (do not block implementation)

Final product name, bundle IDs/package IDs, brand assets, privacy-policy URL, support contact, supported OS minimum versions, app-store listing copy, publisher legal details. Use clearly named placeholders and keep configuration centralised.

## Official starting points

- Flutter web: https://docs.flutter.dev/platform-integration/web/faq
- Flutter web deployment: https://docs.flutter.dev/deployment/web
- Drift encryption: https://drift.simonbinder.eu/platforms/encryption/
- Drift: https://drift.simonbinder.eu/
- Flutter local auth: https://pub.dev/packages/local_auth
- Flutter local notifications: https://pub.dev/packages/flutter_local_notifications
- Health integration: https://pub.dev/packages/health
- TGA exclusions: https://www.tga.gov.au/products/medical-devices/software-and-artificial-intelligence-ai/overview/software-based-medical-device-exclusions

**Note:** Package versions and platform policies evolve. Verify current official docs at implementation time. Never claim unverified plugin support.

## Development (implementation in progress)

See [ROADMAP.md](ROADMAP.md) for the remaining milestones,
[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for verification, and
[CHANGELOG.md](CHANGELOG.md) for changes. Android
production opens the encrypted journal after platform-specific security verification.
iOS personal record entry remains gated pending physical-device verification.
The web app is always a volatile fictional demo; no environment flag enables production
web records. Reloading or opening a new tab constructs a new fixture.

```sh
flutter pub get --enforce-lockfile
dart run build_runner build
flutter analyze
flutter test
flutter build web --release
flutter build apk --release --flavor production
flutter build ios --release --no-codesign
```

Browser acceptance: `npm ci --prefix tool/browser`, then
`npx --prefix tool/browser playwright test --config tool/browser/playwright.config.cjs`.
The test uses installed Chrome and serves the web release build locally.

Native encryption probe (fictional data only):
`flutter run --release -d DEVICE_ID -t tool/native_encryption_probe.dart --no-resident`.
Confirm `HEALTH_JOURNAL_ENCRYPTION_PROOF:PASS` in device logs. Test on both mobile OSes;
a build alone is insufficient. This target replaces the development app with a probe,
so use a dedicated test installation, never a personal-record installation.

Production design: local-only, one person, no accounts or backend. Portable recovery will
require the backup file and its password; a forgotten password cannot be recovered by a
server. Notifications will be best effort. PDF/CSV exports will be readable files and
must be shared carefully. The journal provides no medical advice. These later workflows
are not yet implemented. Publisher IDs, privacy policy and support details must be
set before release. No signing team or credentials are committed.

Additional fictional native store probe:
`flutter run --release -d DEVICE_ID -t tool/native_store_probe.dart --no-resident`.
Use a dedicated test installation: this target creates an encrypted **fictional**
store using the installation key and native protected directory. Confirm
`HEALTH_JOURNAL_NATIVE_STORE_PROOF:PASS` in device logs, force-stop and launch again,
then check for a new PASS from a new process. It intentionally retains fictional
state to test restart; do not run it over a personal-record installation. A PASS
is not physical-device file-protection, lock/unlock or portable-backup verification.

On iOS Simulator, use `--debug` for the store probe; simulator PASS/restart proves only
the simulator path. It cannot replace physical-iPhone release, file-protection or locked-
device acceptance. Native personal-record entry stays gated regardless of simulator PASS.

## Android encrypted migration probe

`tool/native_migration_probe.dart` is a separate release entry point for a
disposable emulator where `com.repasscloud.healthjournal` is absent. Its
`FICTIONAL_V1_SQL_BASE64` Dart define is the Base64-encoded UTF-8 JSON list of
SQLite statements from `test/fixtures/schema_v1.json` under `fixed_sql`. Build
it with the production flavor so the native protected directory and secure key
adapter are available. Keep its artifact separate from the normal production
APK and explicitly select the verified emulator serial for installation.
Look for `HEALTH_JOURNAL_MIGRATION_PROOF:PASS_UPGRADE` on cold launch, then
force-stop and relaunch without clearing data and check for `PASS_RESTART`.
The probe leaves fictional data in the disposable emulator.

## Android fictional device review

Build: `flutter build apk --release --flavor review -t lib/main_review.dart`.
APK: `build/app/outputs/flutter-apk/app-review-release.apk`.
Package: `com.repasscloud.healthjournal`.
Launcher: **Health Journal**. The review build holds sample edits in memory.
Force-stop and relaunch to restore the sample data. Do not enter real health
information.

With exactly one authorised Android phone connected by USB:

```sh
./scripts/deploy-android-review.sh
```

To list Android Studio virtual devices or refresh a selected emulator:

```sh
./scripts/refresh-android-emulator.sh
./scripts/refresh-android-emulator.sh swoovr-pixel
```

The script starts the named emulator if needed, waits for Android to boot,
then builds, installs, and opens the review app.

The review and production flavors share the package ID and cannot be installed
side by side. The deploy script updates an existing installation only when
Android identifies its review-only activity alias.

Review medications/catalogue history, completed courses, explicit status/corrections,
symptom front/back region entry, measurements and timeline search (`correction`,
`ache`, `weight`). Scheduled entries remain unconfirmed. Device storage/keys,
notifications, lock, reports, backup/restore and health import are unavailable.
iOS production remains gated pending physical-iPhone release/security verification.
For Android production builds and the dedicated fictional security probes, append
`--flavor production`; do not run probes over any personal-data installation.
See ADR 0003 for review composition boundaries and known snapshot-contract limitations.

To test the Android production flow with fictional records alongside an existing
installation, build with an isolated application ID:

```sh
ORG_GRADLE_PROJECT_healthJournalDeviceTest=true flutter build apk --release --flavor production
```

Inspect the APK manifest and confirm its application ID is
`com.repasscloud.healthjournal.devicetest` and is absent on the selected device
before installing. Copy it out of the standard build directory before building
the normal production APK. Android keeps this installation's database and
Keystore key separate from the standard package.
