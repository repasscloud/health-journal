# 04 — Platform Matrix and Demo Deployment

## 1. Capability matrix

| Capability | iOS production | Android production | Web PWA demo | Desktop optional |
|---|---|---|---|---|
| One personal local profile | Yes | Yes | One fictional seed | If implemented |
| Persistent encrypted DB | Yes | Yes | **No: in-memory only** | Must verify |
| Medications/symptoms/pain map | Yes | Yes | Fictional interactive | If implemented |
| Local medication notifications | Best effort | Best effort | Simulated only | Verify |
| PIN and biometrics | Yes, where available | Yes, where available | Disabled/simulated | Verify |
| Password-encrypted backup/restore | Yes | Yes | Disabled | If implemented |
| Export doctor-ready PDF | Yes | Yes | Fictional PDF demo | If implemented |
| OS file share/save | Yes | Yes | Optional demo-only download | Verify |
| Apple HealthKit | Future opt-in reads | N/A | Not available | N/A |
| Health Connect | N/A | Future opt-in reads | Not available | N/A |
| Internet required for daily use | No | No | First load + optional offline cache | No |

## 2. Demo-specific architecture

Build target `web` should be **impossible to configure into production persistence accidentally**. Compile-time config selects `DemoEnvironment`, never imports/enables native record DB, device secret store or production export/backup endpoints. All edits mutate only injected in-memory repositories. Re-seed on each main() start. A browser refresh, hard reload or opening another tab produces independent canonical fixture. No LocalStorage, IndexedDB, OPFS or browser storage for journal contents. Cache app *code/assets* only via PWA service worker when enabled; do not cache sensitive demo inputs or runtime state. Do not add real personal medical data to test fixture.

Demo UI: obvious banner on every screen with reset explanation; settings display nonfunctional platform-only features as **demonstration** rather than permitting fake settings to appear secure. Offer sample PDF download with `SAMPLE / FICTIONAL DATA` watermark. Disable backup/restore and Health integration. No login.

## 3. PWA hosting and caching

Build Flutter web in CI (`flutter build web --release`). Current Flutter versions no longer generate/register an offline caching service worker by default. **Implement and maintain a custom service worker** (or Workbox-based build) when offline demo caching is desired; use precache manifest/current official docs and explicit cache versioning. Serve HTTPS, valid PWA manifest, icons, start_url/scope, responsive viewport and SPA history fallback. Deploy immutable hashed assets with sensible caching; ensure updated web builds invalidate old app shell. Disable indexing if desired via robots but do not rely on it for privacy. No back-end required except static hosting. Apply suitable CSP, security headers and no third-party tracker scripts. PWA loads seed in memory on every boot even when assets are cached.

Smoke tests in Chrome, Safari iOS, Android Chrome, desktop browsers; verify **reload resets data**, tab isolation, offline cached shell if implemented, PWA installation flow, mobile layout and no persistent user records. Distinguish `web build` from `native release` by explicit CI targets and test assertions.

## 4. iOS

Use private app storage and Data Protection where appropriate. Keychain for local key security. Biometric permission description/capabilities as required. Schedule local notifications respecting iOS permission and pending notification cap; rolling scheduling window and rescheduling on app launch. iCloud Drive is a **user-chosen destination** in OS Files picker, not an app-operated synchronisation database. Test share/import from iCloud Drive on replacement physical iPhone. If later supporting HealthKit, add entitlement and just-in-time permissions for approved measurement types, no medication integration assumptions. Verify minimum iOS target supported by chosen packages.

## 5. Android

Use encrypted DB in app-private files; Android Keystore-backed secret management. Use Storage Access Framework for documents (including user-chosen cloud providers), not blanket external storage access. Request notification permission on supported versions. Exact alarms are restricted on current Android; select inexact vs exact intentionally, explain reliability and seek only legitimately needed permissions. Verify reboot rescheduling, OEM battery restriction behaviour, permission revocation and Android Auto Backup exclusion/restore of encrypted DB key material. Health Connect later as opt-in read-only measurements. Test supported API/minSdk combination.

## 6. Optional desktop

Do not mark desktop as release-supported merely because `flutter create` generates folders. Native SQLite encryption, secure key storage, files, passcode/biometrics fallback, notifications and PDF sharing require platform validation. It is acceptable to retain scaffolds unshipped. Do not block iOS/Android delivery for Windows/macOS/Linux.

## 7. Deployment and CI

Suggested GitHub Actions jobs: formatting/static analysis, unit/widget tests, demo reset tests, cryptography vectors/format tests, Android debug/release build, iOS build on macOS runner where signing is provided, web build and browser smoke. Separate demo static deployment workflow. Don't commit signing secrets, recovery passwords or actual patient data. No analytics SDK or server API.
