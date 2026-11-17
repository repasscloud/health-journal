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
- Demo catalogue creation/editing covers generic/brand, form, strength/unit, directions,
  reason, prescriber, notes, start/stop/pause dates and archival, with created/updated UTC
  timestamps and retained prior catalogue objects in memory. IDs/creation dates survive edits.
- Regimen forms support multiple distinct daily times with shared selected weekdays, local
  start dates for historical entry, courses and PRN. Revisions prefill prior dose/times and
  take effect now. Schedule occurrence/DST generation and per-time weekday editing remain.
- Explicit administration forms select historical local date/time, status, actual amount/unit
  and notes. Event time is separate from entered time, including non-taken statuses.
  Corrections append a linked event with required reason; original and superseded events
  remain visible. Immutable catalogue and regimen snapshots survive edits and corrections.
  Confirmation asks users to check existing entries for duplicates; no candidate detection
  or automatic deduplication is implemented.
  Original timezone/offset capture and intended occurrence linkage remain unfinished.
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
- `flutter test`: 31 tests passed (domain, widgets, installation keys, encryption, schema retention, body geometry and record flows).
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
- iOS 27.0 iPhone 18 Pro SIMULATOR DEBUG installation-key/protected-store probe:
  PASS in Runner process 52855, then terminate/relaunch and PASS in process 53135
  (2026-11-17 simulator logs). No uninstall or data clear between launches. The probe
  uses NativeStore, retains a fictional sentinel, scans DB/sidecars for plaintext and
  reopens with the stored installation key. This verifies simulator key/store reuse,
  not release mode, hardware Keychain guarantees, effective file-protection attributes,
  locked-device access denial, device passcode/biometric changes or portable recovery.
- iOS release runtime retry: iPhone detected, but signing failed because Apple reported
  the team reached its registered-iPhone limit and no matching provisioning profile existed.
  No physical-iPhone release runtime encryption success is claimed. Physical-device proof on both OSes,
  iOS file protection, lock changes and expanded WAL/temp lifecycle remain required.

## Remaining milestone work

0: iOS native release encryption proof, physical-device checks, protected opener production
bootstrap after proof, complete Drift schema and migration recovery safeguards, complete
fictional fixture and broader CI/platform verification. CI is authored but not run remotely.
1: Catalogue history viewer and broader record editing/audit metadata, original timezone
capture, intended schedule occurrences/DST, marker editing/movement/radius, richer symptom metadata, timeline
filters/pagination, measurements display conversions, encrypted native repository/schema.
Existing independent demo slices are described above; native restart acceptance is blocked.
2: Real notifications, permission/timezone/DST handling, PIN/biometric lock and privacy.
3: PDF/CSV, OS document providers, benchmarked Argon2id/AES-GCM backup, authenticated
bounded parser, portable restore staging, replacement confirmation and crash recovery.
4: Accessibility/device QA, migration/backup compatibility, release disclosures and branding.

Optional health imports, attachments and desktop are deferred as permitted by the specs.
Offline PWA caching is not enabled; no service worker or offline-install claim is made.
No native production release readiness or complete application is claimed.

## Continuation verification scope

This continuation leaves native entry gated and makes no signing/project changes. iOS
simulator protected-store restart evidence is new; physical-iPhone release proof is still
blocked by the previously observed Personal Team provisioning limit. Android release and
unsigned iOS release builds also passed again in this continuation. Catalogue and
administration additions are volatile demo slices; no schema migration or native record
repository change was made. Prior catalogue versions are retained by the repository but
have no dedicated history browser yet. Full accessibility and physical-device QA remain.

## Review and Android handoff — 2026-11-18

Analysis and all 31 tests passed again. No new platform build or device probe was run
in this review-only continuation; the build/browser/probe results above are prior evidence.
Review found three follow-ups: completed historical courses are blocked by the future-only
end validator; editing domain rules with differing weekdays unions those weekdays across
all times; direct repository administration writes do not enforce regimen effective dates.
These remain unfixed in this snapshot and are prioritised with regression-test guidance in
`NEXT_CONTEXT_PROMPT.md`. The normal Android target still opens the native security gate,
so a separate, visibly fictional review installation is the recommended next slice.
Xcode signing settings were not modified.
