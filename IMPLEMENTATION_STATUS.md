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
- Installation-key lifecycle and secure-storage adapter are now composed in `NativeStore`.
  Personal-record bootstrap remains gated. Dedicated fictional probe verifies this opener.
  Lost/corrupt keys and orphaned sidecars fail closed without replacing records.
- iOS protected-directory channel applies complete Data Protection and backup exclusion;
  Android uses an owner-only directory under noBackupFilesDir. iOS runtime attributes,
  lock/unlock and physical-device checks are still required.
- Exported the v1 Drift schema baseline. Unsupported schema opening is tested against an
  encrypted file and retains original bytes, version and records. No supported upgrade
  or crash-tested migration recovery exists yet.
- Android Auto Backup disabled. Brand and application identifiers remain release placeholders.
- ADRs 0001/0002 document dependency order, candidates, protected opener, independent
  record slices, official sources and security gate.
- Corrected pre-existing setup-node action tag typo (`vv7` → verified `v7`) and included
  both native probes in CI formatting. Remote CI has not been run.

## Milestone 1 — Started; fictional demo slices only

- Immutable fixed/course/PRN regimens with explicit device-local weekday/time rules,
  exclusive effective ranges, overlap rejection and in-memory regimen revision.
- Explicit taken/skipped/missed/unknown entry snapshots medication name, amount/unit and
  regimen context. Schedule creation never records intake; PRN has no due times.
- Demo forms add/revise regimens and record current-time statuses. Domain supports multiple
  rules; UI currently exposes one daily time. Catalogue editing/full fields, historical
  entry/corrections and schedule occurrence generation remain unfinished.
- Symptom form supports multiple independently labelled pain observations; original bundled
  v1 front/back SVGs, normalized coordinates, silhouette rejection, anatomical laterality,
  zoom/pan, accessible text region selection and deletion. Asset/geometry equivalence tested.
- Manual measurement form supports weight, BP, heart rate, temperature, glucose and sleep
  with canonical units/manual provenance. Combined timeline has case-insensitive text search.
- Persistent fictional-data notice on record forms; validation/save errors; narrow-screen
  200% text test. Comprehensive screen-reader/device/golden QA remains outstanding.
- No native record repository is wired. These records exist only in demo memory and reset
  on every page load. Neither milestone 0 nor milestone 1 is complete.

## Verification

- `flutter analyze`: passed.
- `flutter test`: 26 tests passed (domain, widgets, installation keys, encryption, schema retention, body geometry and record flows).
- `flutter build web --release`: passed.
- `flutter build ios --release --no-codesign`: passed.
- `flutter build apk --release`: passed (development signing only; not a store-ready artifact).
- Android API 35 arm64 emulator RELEASE probe: `HEALTH_JOURNAL_ENCRYPTION_PROOF:PASS`.
  This verifies native SQLite encryption in release mode, not physical Android hardware.
- Chrome release demo acceptance: 2 tests passed covering edits/reload, independent tabs,
  no IndexedDB/OPFS records or edited journal text in local/session storage, and manual
  measurement entry/search/reload. Safari/mobile browser QA remains.
- Prior flutter doctor reported incomplete Android licenses and absent CocoaPods; this
  session did not re-audit doctor. The explicit native builds above passed.
- Android API 35 arm64 emulator RELEASE installation-key/store probe: PASS, then PASS
  from a second process after force-stop/relaunch. This tests stored-key reuse, encrypted
  DB/sidecars and reopen. No physical Android Keystore/lock-change proof is claimed.
- iOS 27.0 iPhone 18 Pro SIMULATOR DEBUG encryption probe: PASS, confirmed in
  simulator logs. This bypasses device provisioning and verifies the simulator cipher
  path only; it does not satisfy physical-iPhone release/security acceptance.
- iOS release runtime retry: iPhone detected, but signing failed because Apple reported
  the team reached its registered-iPhone limit and no matching provisioning profile existed.
  No iOS runtime encryption success is claimed. Physical-device proof on both OSes,
  iOS file protection, lock changes and expanded WAL/temp lifecycle remain required.

## Remaining milestone work

0: iOS native release encryption proof, physical-device checks, protected opener production
bootstrap after proof, complete Drift schema and migration recovery safeguards, complete
fictional fixture and broader CI/platform verification. CI is authored but not run remotely.
1: Complete catalogue/record editing and audit metadata, historical time entry, multiple-time
schedule UI/occurrences, marker editing/movement/radius, richer symptom metadata, timeline
filters/pagination, measurements display conversions, encrypted native repository/schema.
Existing independent demo slices are described above; native restart acceptance is blocked.
2: Real notifications, permission/timezone/DST handling, PIN/biometric lock and privacy.
3: PDF/CSV, OS document providers, benchmarked Argon2id/AES-GCM backup, authenticated
bounded parser, portable restore staging, replacement confirmation and crash recovery.
4: Accessibility/device QA, migration/backup compatibility, release disclosures and branding.

Optional health imports, attachments and desktop are deferred as permitted by the specs.
Offline PWA caching is not enabled; no service worker or offline-install claim is made.
No native production release readiness or complete application is claimed.
