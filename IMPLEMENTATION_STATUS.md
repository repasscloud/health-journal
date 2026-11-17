# Implementation status

Updated 2026-11-17. Product baseline: README, AGENTS and specifications 01–05 read.

## Milestone 0 — In progress

- Generated Flutter stable iOS/Android/web targets and locked dependencies.
- Added shared repository contract, immutable medication/administration models and validation.
- Added injected environment and a volatile fictional demo with five-tab shell, persistent
  demo notice, medication creation with validation and explicit unavailable device features.
- Web startup always creates a new repository. No journal browser storage APIs are used.
- Native boot fails closed: personal data entry is unavailable pending encryption proof.
- Added SQLite3MultipleCiphers release-enforced cipher check and encryption probe tests.
- Initial isolated Drift schema/migration includes singleton profile, medications/regimens/events,
  symptoms and independent pain markers with FK/check constraints. Remaining tables/fields are pending.
- Added installation-key lifecycle service and native secure-storage adapter; not yet wired
  into production bootstrap. Lost/corrupt keys fail closed without replacing existing records.
- Android Auto Backup disabled. Brand and application identifiers remain release placeholders.
- ADR 0001 documents dependency order, candidates, official sources and security gate.

## Verification

- `flutter analyze`: passed.
- `flutter test`: 11 tests passed (domain, widgets, installation keys, encryption, initial schema).
- `flutter build web --release`: passed.
- `flutter build ios --release --no-codesign`: passed.
- `flutter build apk --release`: passed (development signing only; not a store-ready artifact).
- Android API 35 arm64 emulator RELEASE probe: `HEALTH_JOURNAL_ENCRYPTION_PROOF:PASS`.
  This verifies native SQLite encryption in release mode, not physical Android hardware.
- Chrome release demo acceptance: passed edits/reload, independent tabs, no IndexedDB/OPFS
  records or edited journal text in local/session storage. Safari/mobile browser QA remains.
- Android licenses incomplete; CocoaPods absent according to flutter doctor.
- iOS release runtime probe could not launch: the previously detected wireless iPhone
  became unavailable. No iOS runtime encryption success is claimed. Physical-device proof
  on both OSes, WAL/temp lifecycle and native key-store device tests remain required.

## Remaining milestones (not implemented)

0: iOS native release encryption proof, physical-device checks, production installation-key
wiring/file protection, complete Drift schema and migration recovery safeguards, complete
fictional fixture and broader CI/platform verification. CI is authored but not run remotely.
1: Effective-dated regimens, schedules, administration UI, symptoms, versioned anatomical
assets and silhouette hit testing, measurements, timeline, encrypted native repository.
2: Real notifications, permission/timezone/DST handling, PIN/biometric lock and privacy.
3: PDF/CSV, OS document providers, benchmarked Argon2id/AES-GCM backup, authenticated
bounded parser, portable restore staging, replacement confirmation and crash recovery.
4: Accessibility/device QA, migration/backup compatibility, release disclosures and branding.

Optional health imports, attachments and desktop are deferred as permitted by the specs.
Offline PWA caching is not enabled; no service worker or offline-install claim is made.
No native production release readiness or complete application is claimed.
