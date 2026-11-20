# Implementation status

Updated 2026-11-19. Product baseline: README, AGENTS and specifications 01–05 read.
See the encrypted medication history and Android release migration checkpoints
at the end of this file for current results.

## Milestone 0 — In progress

- Generated Flutter stable iOS/Android/web targets and locked dependencies.
- Applied the grayscale Hj monogram to iOS and iPadOS app icons, Android legacy and adaptive
  launchers (including themed icons), and web demo favicon and PWA icons.
- The in-app header loads its grayscale Hj from a dedicated Flutter branding asset.
- Added shared repository contract, immutable medication/administration models and validation.
- Added injected environment and a volatile fictional demo with five-tab shell, persistent
  demo notice, medication creation with validation and explicit unavailable device features.
- Web startup always creates a new repository. No journal browser storage APIs are used.
- The browser demo centres all screens in a 480 logical pixel column on wider
  displays and fills narrower viewports.
- Timeline filters keep one active choice and leave space between wrapped rows.
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

- Launcher icons: validated PNG dimensions and PWA mask safe areas. iOS asset catalog
  compilation, Android release resource merges for both flavors, and web release build passed.
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
filters/pagination, encrypted native repository/schema.
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

## Android fictional review implementation — 2026-11-18

This session fixes all three handoff findings: strict calendar validation permits
completed historical courses with exclusive end after start (revisions require end
after captured revision time); mixed per-rule weekdays are explicitly refused by
the shared-weekday revision UI without changing rules; repository writes/corrections
reject event times outside the referenced regimen's effective range before mutation.
Regression tests cover invalid/normalised dates, inverted ranges, completed-course
form retry, mixed weekday refusal and unchanged lists after invalid direct writes.

Added isolated `review` Android flavor/entry point, package
`com.example.healthjournal.health_journal.fictionalreview`, launcher
`HJ FICTIONAL REVIEW`. Fresh deterministic fictional memory fixture includes
fixed/course/PRN regimens, completed course, skipped/taken history and append-only
correction, a catalogue revision, three front/back pain observations, and six
measurement kinds. Main production entry point remains nativePending; review
requires Android plus its compiled review flavor. Web remains unconditional demo.
Review skips Android native plugin registration and the protected-directory channel.
No keys, record database, reminders, app lock, reports or backup are opened/enabled.
Edits last only for the process; backgrounding does not guarantee reset.

Catalogue history viewer added; regimen/status selection shows effective ranges and
rule weekdays; schedule timeline names retain catalogue-at-regimen-creation names.
Nested forms use the review reset notice. See ADR 0003 and README build/install steps.
Administration optional snapshots/object-identity preservation remain volatile-only;
a stable versioned value snapshot/serialization contract is still required before
native wiring. Full per-time weekday editing, administration-form retry without
losing inputs, original timezone, native persistence/migrations, notifications,
lock, reports and portable backup/restore remain incomplete. No milestone completed.

New checks this session: formatting and analysis passed; 38 unit/widget tests passed;
Android review release APK and production release APK built; web release built;
Chrome's two acceptance tests passed (reload/tab isolation/storage and measurement
entry/search/reset). iOS was not rebuilt or re-probed this session. Xcode signing
and all iOS files are unchanged; no dependencies, commits or pushes were added.
Previous simulator/emulator encryption evidence above is prior evidence, not a new
security claim. Physical-iPhone release/security verification remains blocked by
the prior provisioning limit and continues to gate personal native records.

No physical Android device was present through adb. An API 35 arm64 emulator was
started as supplemental evidence; the previously absent review package installed
without replacement, package/launcher/activity were checked with aapt/dumpsys, and
the fictional review UI launched successfully. No existing personal-data app was
cleared, uninstalled or overwritten. Emulator observations do not establish any
physical-device or production encryption/security acceptance.

Final emulator smoke on the rebuilt review APK: added a fictional 73 kg measurement,
confirmed it alongside the six seeds, force-stopped process 4044 and relaunched in
process 4331, then confirmed canonical 72 kg seed remains and added 73 kg is absent.
No data clear/uninstall was used. Only the review package created in this session was
updated with the final APK. Review notices were checked in the measurement screen;
UI XML/screenshots are under ignored `build/review-evidence/`. Emulator clock was
2026-11-12; host/session date is 2026-11-18. Fixture dates were moved earlier to keep
edits valid on that emulator clock; one old test now preserves the fixture's actual
creation timestamp rather than hardcoding it. Tabs have independent list state so
scrolling Today cannot hide the beginning of More. Final formatting/analysis and all
38 tests passed after these changes; final web release and both Chrome tests passed.

Final review artifact: `build/app/outputs/flutter-apk/app-review-release.apk`
(61.2 MB, local development signing). SHA-256:
`f9e3437fb8cea7b495fd31aee92273e704cc28011f469ce17ea63d5bf3835622`.
APK metadata confirms the separate package/name/activity and minSdk 24, targetSdk 36.
Production APK was built earlier in this session after flavor/channel changes;
subsequent UI/fixture changes are validated by the final review/web builds and tests.

## 2026-11-18 — UI redesign

Redesigned the implemented Flutter screens using the references in
`docs/design/example-pack-20261118`. A shared light/dark Material 3 theme
covers the journal, record forms and the gated native setup screen. Today
prioritises recorded activity and gives direct access to dose, symptom and
measurement entry. The medication catalogue is searchable, with separate
detail pages for regimens, catalogue history and dose corrections. The timeline
has event-type filters, date groups and contextual times. Symptom entry uses
segmented front/back controls and retains accessible region selection.

Dose status is still explicitly chosen. The confirmation form uses the current
time for a new record and the original time for a correction, both editable.
Inline validation keeps values intact when a correction reason, dose or time
needs adjustment. An as-needed regimen supports recording without scheduled
times. Samples now populate the web demo as well as the isolated Android review.
The web demo still seeds a fresh volatile repository on each page load.

The design pack also includes future workflows. Catalogue import, symptom
follow-ups and trends, drawn body areas, reports, reminders, app lock and
portable recovery remain outside this UI pass. The app continues to show
device-feature availability and gate native personal record entry.

Validation: `flutter analyze` and all 38 unit/widget tests passed. Web release
and Android fictional-review release APK built successfully. Both Chrome
acceptance tests passed twice, covering tab isolation, browser storage and
reload reset. Visually checked desktop, 390 px mobile, dark mode and symptom
entry in Chrome. The Android APK is available for device review. This UI pass
did not run an iOS build or repeat the native encryption probes.

### Monochrome appearance and build labels

Adopted WanderConnect's Standard light/dark palette and added a session-only
System, Light and Dark control under More > Appearance. The web demo still
shows the sample-data and reload notice. The Android review launcher is
Health Journal Review and the review notice explains process-reset behaviour.
Shared screens use regular journal labels. The review app keeps its isolated
package ID, and the production storage gate remains in effect.

Flutter analysis, all 39 unit/widget tests and both Chrome acceptance tests
passed. Chrome visual checks covered monochrome light, dark and the body map.

### Medication and pain-map form refinements

Pain type and body-region controls display capitalised labels while retaining
their stored identifiers. The severity slider and numbered body-map markers
use green for 0–5, orange for 6–8 and red for 9–10, with light/dark variants.
Medication form and strength unit use the brief's dropdown options. New
product strengths accept positive decimals and preserve the entered precision.
Existing free-text values remain available when editing earlier records.
These changes keep the current schema and do not add dose calculations.

Static analysis and all 39 unit/widget tests passed, including severity band
boundaries, numeric validation, and the medication field round-trip.
The web release built and both Chrome acceptance tests passed. The Android
review release installed and cold-launched successfully on the USB-connected
Samsung SM-A146P.

### Calendar controls and strength unit labels

Medication start, stop and pause dates and regimen start and end dates use
calendar-only controls. Optional medication dates can be cleared. Recorded
dose dates also use calendar-only mode. Regimen end dates remain exclusive and
must follow the effective start. Strength unit options show the symbol and
full name and continue to save the symbol.
Static analysis, 39 Flutter tests and both Chrome acceptance tests passed.
The updated Android review build installed and launched on the Samsung phone.

### Regimen form spacing

Added 12 logical pixels between fields in Add and Revise regimen, plus gaps
between weekday choices. The form remains scrollable for longer schedules.
Static analysis, 39 Flutter tests and both Chrome acceptance tests passed.
The updated Android review build installed and launched on the Samsung phone.

### Readability and dose correction flow

Reviewed the implemented screens and shared controls. Dose status and
regimen labels are human-readable throughout the relevant flows. Medication
details now separate regimen, dose history and catalogue history. Each dose
shows its status, amount and event time first. Expandable entry details
retain the original medication snapshot, entry time and correction reason.
Timeline cards use separate lines, readable body-region names and severity
colours alongside numeric values. Shared controls have clearer borders,
larger action targets and more generous body text.

Flutter analysis, 39 Flutter tests and both Chrome acceptance tests passed.
The Flutter suite includes 200% text at phone width and the correction
dialog. The updated Android review build installed and launched on the
Samsung phone. Chrome visual checks covered phone and desktop widths.

### Ad-hoc medication intake

Today > Record medication and the medication detail page open an intake
form without requiring a regimen. The event date and time default to when
the form opens and remain editable. The dose is recorded as taken only
after Save dose. The recording form reuses a current regimen's amount and
unit, or uses an unambiguous countable product form for the unit and asks
for the amount. Product strength remains separate. Dose units can be
changed and are requested when no usable default exists. Corrections
still preserve the original event snapshots.

This slice uses the existing nullable regimen reference in the shared
domain and the in-memory review and web repositories. The gated native
database still requires a regimen reference and must be migrated and
validated before supporting this flow with personal records.
Static analysis, 40 Flutter tests, both Chrome acceptance tests and a
phone-width Chrome ad-hoc intake smoke test passed. The updated Android
review build installed and launched on the Samsung phone.

### Android launcher identity

The Android launcher name is **Health Journal** and the application ID and
Kotlin namespace are `com.repasscloud.healthjournal`. The review APK was
installed and cold-launched on the Samsung. The legacy review package was
disabled for Android user 0, leaving its installation intact. Review and
production now share an application ID. The deploy script checks the
review-only activity alias before replacing an installed build. Static
analysis and all 40 Flutter tests passed.
Both Android release flavors built. APK inspection confirmed the requested
label and ID on both, with the review activity alias absent from production.

### Regimen units, directions and prescribers

New regimens derive the read-only dose unit from the medication's form and
display the appropriate singular or plural for countable forms. New regimens
require a recognised form. Revisions keep the saved unit to preserve the
meaning of their existing quantities. New regimen directions start with the
medication's saved directions. Medication details show the current
directions and prescriber. Both editors have multiline Directions fields.
Prescribed by suggests names from saved current and historical medications
and accepts new names. Suggestions use the current repository's data.
Flutter analysis, all 41 Flutter tests and both Chrome acceptance tests
passed. The updated Android review build installed and launched on the
Samsung phone.

## Settings and startup (2026-11-18)

- The top-right cog opens Settings. Independent weight, temperature and glucose
  units appear above system/light/dark appearance and device capability information.
  Measurement entry is on Today and readings appear in Timeline. The selected
  units apply to new entries and existing readings using canonical storage.
- Preferences are session-scoped in the current builds. A new demo page load
  restores the defaults and creates a fresh fictional repository.
- Cold startup traces the Hj launcher monogram, holds it, and fades the
  white mark and black tile together into the theme background before showing
  the journal. The 4.7-second sequence follows system appearance on first launch.
  Reduced motion skips the animation.
  If the native composition supplies an unlock check, the unlock screen replaces
  the animation and gates the journal until authentication succeeds. Native PIN
  and biometric enrolment and verification are still pending.
- Verified with Flutter analysis and 47 Flutter tests, including Settings,
  canonical weight conversion, logo colours, the lowercase j dot, and fading in both themes,
  reduced-motion startup, and the unlock gate.
- The web release build, both Chrome acceptance tests, the Android review
  release APK, and the unsigned iOS release build passed. Native physical-device
  runtime verification remains pending.

## Body-map artwork v2

Symptom entry uses the v2 front and back SVGs and saves new observations as
v2. Version-aware validation uses the matching silhouette, and region buttons
place markers inside the revised artwork. Both versions are bundled. Existing
v1 observations retain their original coordinates and region labels. Timeline
history displays locations as text. Future graphical history and report
renderers must select the asset by the saved version.

Verification passed for Flutter analysis, all 50 Flutter tests, and both
Chrome demo acceptance tests. Web, Android production and review, and unsigned
iOS release builds completed. All four body-map SVGs in each release bundle
matched their source files byte for byte.

## 2026-11-18 — Encrypted medication history and Timeline symptom detail

This checkpoint supersedes earlier v1-only, text-only symptom history and
Android review package notes. Production personal record entry remains gated.
Android review and production share `com.repasscloud.healthjournal`. Review
starts with fictional process-local data. A full web page load constructs a
fresh volatile fictional repository.

- Drift v2 upgrades the event table through the keyed NativeStore connection.
  The isolated history adapter appends explicit events, supports ad-hoc intake
  and append-only corrections, and decodes versioned catalogue and regimen
  snapshots independently of edits to the parent rows. Duplicate corrections
  are rejected. Parent catalogue and regimen writes for native UI remain open.
- The exported v1 fixture is the migration source of truth. The upgrade
  retains original status, amount/unit, linkage, occurrence information,
  timestamp integers and opaque legacy snapshot text. It derives medication
  id from the existing relationship and copies confirmed taken time into event
  time. Other legacy event times, structured historical snapshot values, notes
  and correction metadata were unavailable. Legacy events can be read. Legacy
  correction support and new original-offset/occurrence capture remain open.
  See [ADR 0005](docs/adr/0005-encrypted-medication-event-upgrade.md).
- Timeline opens a read-only symptom detail with numbered pain locations.
  Each marker uses its saved front/back asset and version. Visible and spoken
  labels give anatomical location, pain type and severity. Widget tests
  exercise all four asset/view combinations at 215 and 520 logical pixels
  with 200% text scaling and verify marker centres against the image bounds.

### Current verification

| Check | Target and outcome |
|---|---|
| Formatting and analysis | Flutter 3.47.9 / Dart 3.13.7. Format check passed across 46 Dart files. `flutter analyze` passed. |
| Complete Flutter suite | 55 passed on arm64 macOS, including real SQLite3MultipleCiphers through `NativeStore.openJournalAt` with an injected in-memory key store and an isolated directory. |
| Web release | `flutter build web --release` passed. |
| Browser demo | 2 Playwright tests passed in local headless Chrome against the web release, covering reload reset, tab isolation, no journal in browser storage, and measurement entry/search/reset. |
| Android production release | `flutter build apk --release --flavor production` passed. Local development signing. |
| Android review release | `flutter build apk --release --flavor review -t lib/main_review.dart` passed. APK inspection found the review-only activity alias only in review, the shared ID on both, and minSdk 24 / targetSdk 36. |
| Unsigned iOS release | `flutter build ios --release --no-codesign` passed against the device SDK with Xcode 27.2. Bundle id `com.example.healthjournal.healthJournal`. |

The encrypted host integration test seeded v1 from its export, upgraded it,
appended/read an event, ad-hoc intake and linked correction, edited the parent
rows, checked FKs and scanned the raw DB and present sidecars with WAL active
and after close. It verified historical snapshots, both event and entry time,
and stored-key reuse on reopen. The deliberately blocked table drop proved
exception rollback after rename and copy, preserved v1 records/version/FKs,
and permitted a retry after removing the blocker. Version 99 was rejected
with byte-identical DB and a successful keyed inspection of the original
version and record. Process-interruption recovery and an independent encrypted
recovery snapshot remain untested and pending.

**Emulator/simulator runtime.** No mobile migration probe or APK installation
was run for this checkpoint. The Android emulator disappeared from adb during
the run. The booted iOS simulator was already present and its disposability
was unverified. Earlier cipher/store probe results above remain separate
historical evidence. The current release builds exercise the gated app
composition; the history adapter was exercised by the host integration test.

**Physical acceptance.** No physical installation, signing or provisioning
changes, deployment, commit or push. Hardware key behaviour, effective file
protection and locked-device behaviour remain pending. The previously observed
iPhone registered-device limit remains the last known provisioning blocker.

**First manual action.** Identify a verified disposable emulator or simulator
where the shared app package is absent, then run a target-specific version of
the fictional migration check through the protected directory and secure key
adapter. Keep production entry gated through recovery and hardware acceptance.
Symptom editing, reports, reminders, app lock and portable backup were outside
this checkpoint.

## 2026-11-19 — Android release migration runtime

The Android release probe entry point uses the platform protected-directory
channel and secure installation-key adapter. It was installed only on a
fresh, booted `HJ_Migration_Disposable_20261119` AVD
(`emulator-5562`, API 35, arm64), after checking emulator identity and that
`com.repasscloud.healthjournal` was absent. The probe seeded the exported
fictional Drift v1 SQL, upgraded to v2, verified legacy facts and foreign
keys, appended an explicit ad-hoc administration and correction, and scanned
the encrypted DB and present sidecars with WAL active and after close.
Cold launch reported `PASS_UPGRADE` in PID 4109. A force-stop and second cold
launch reported `PASS_RESTART` in PID 4205 with the original records and
stored installation key. This restart occurred after migration completed.

The host suite also passed all 55 tests, including the deliberately failed
migration rollback/retry and unsupported-version preservation. Formatting
and analysis passed on Flutter 3.47.9 / Dart 3.13.7. The Android production and
fictional review release builds also passed. The web release built and both
Chrome Playwright reset/storage tests passed against it. The unsigned iOS
device release built with Xcode 27.2. The migration APK is separate from the
regular production APK. Logs are in the ignored `build/mobile-checkpoint/` directory.

No installation or probe ran on the connected Samsung. iOS migration runtime,
process death during migration, an independent encrypted recovery snapshot
and physical security acceptance remain open. The production gate is still
in place. No phone action is needed to finish this checkpoint.

## 2026-11-19 — Foundation schema v3 and encrypted recovery

The isolated native opener now writes and validates an encrypted pre-upgrade
snapshot in the app's protected, backup-excluded directory before applying a
supported migration. It leaves the original journal in place if migration
fails and refuses to create a fresh journal over orphaned recovery data.
This is a same-installation recovery point. Portable recovery remains
milestone 3. [ADR 0006](docs/adr/0006-migration-recovery-and-foundation-schema.md)

Drift v3 supports both exported historical versions. It adds schedule rules,
manual measurements, journal notes, symptom tags, audit events, singleton
settings, and nullable catalogue, regimen and symptom metadata. It preserves
legacy facts and does not synthesize unavailable metadata. The isolated
Start Fresh API creates one profile transactionally and preserves it on
retry and reopen. Production does not call it while security acceptance is
open. Record UI integration remains milestone 1.

**Host recovery:** A separate process was killed after migration SQL and
version stamping and before outer commit, in both rollback-journal and WAL
modes. The original v2 schema and records reopened, the published encrypted
snapshot was readable only with the key, and the v2 to v3 retry passed. Tests
also cover v1 to v3, committed WAL snapshot content and independent lifetime,
active sidecar plaintext scans, WAL and SHM cleanup, and SQLite temporary
tables backed by memory. This exercised process termination, not power loss.

**Android runtime:** Release probe passed v1 to v3 on the fresh
`HJ_Foundation_V3_Disposable` Android API 35 arm64 emulator, with
`PASS_UPGRADE` in PID 4161 and `PASS_RESTART` in PID 4246. It exercised
snapshot creation, isolated profile bootstrap, the protected directory,
the platform key store, and reopening fictional data in a new process.
Physical Android acceptance remains open. The attached Samsung already
had the shared production/review package, so it was not replaced or tested
with the migration probe. Credential-change checks require owner participation.

**Release gate:** iOS testing was excluded by request. iOS runtime evidence
and hardware security acceptance remain open before enabling production
Start Fresh or marking milestone 0 complete.

**Checks:** Formatting across 50 Dart files, `flutter analyze`, all 60
Flutter tests, both Android release builds, the web release build and both
Chrome Playwright reload/storage tests passed. Logs are in the ignored
`build/foundation-v3/` directory.

## 2026-11-19 — Milestone 1 independent implementation

- **[#1](https://github.com/repasscloud/health-journal/issues/1) and [#2](https://github.com/repasscloud/health-journal/issues/2).**
  Shared forms respect the bottom system inset. The symptom region selector
  uses aligned, equal-width controls with row and column spacing, adapting
  its column count to available width and text size. A widget test verifies
  the save action is reachable above a simulated Android navigation inset
  and saves a record with a selected region.
- **[#16](https://github.com/repasscloud/health-journal/issues/16).** Isolated
  encrypted adapters now write and reopen medication catalogue revisions,
  effective-dated regimens and rules, explicit administrations, symptoms and
  markers, and measurements. The host test verifies versioned history survives
  reopen and a colliding marker replacement rolls back both current and audit
  writes. These adapters are outside production app composition.
- **[#17](https://github.com/repasscloud/health-journal/issues/17).** The
  fictional regimen editor preserves per-time weekdays. Device-local slots
  skip nonexistent clock times and use the earlier repeated minute. Stable
  civil slot keys support explicit occurrence links and duplicate prevention
  without inferring adherence. Today shows pending and explicitly recorded
  states separately. Event details preserve the original platform timezone
  identifier and UTC offset when available, with a device label fallback.
- **[#18](https://github.com/repasscloud/health-journal/issues/18).** Symptom
  details support audited edits, moving and resizing markers on their original
  asset, onset/end timestamps, severity and structured context. Timeline
  supports inclusive local date filters, 20-event pages and descriptive weekly
  symptom counts. Tests cover moving a v1 marker, historic inspection and
  pagination/date filtering.
- **Schema.** Drift v4 adds administration timezone metadata and encrypted
  audit snapshots. It repairs the generated v3 measurement check that rejected
  all positive values. The exported v3 database is verified through encrypted
  migration and a valid measurement write. [ADR 0007](docs/adr/0007-native-record-facts-and-audit-history.md)

**Checks:** Formatting and analysis passed. All 67 Flutter tests passed.
Web release and both Chrome Playwright storage/reset tests passed. Android
production and fictional review release builds and unsigned iOS device release
built. The iOS build is build evidence only. Logs are under the ignored
`build/milestone-1/final/` directory.

**Android runtime:** On the fresh `HJ_Milestone1_Disposable` API 35 arm64
emulator with the fictional review release, the complete Save symptom button
was above the system navigation area and saved an entry in both gesture and
three-button modes. The three-button layout also showed two aligned region
columns, 12-pixel gaps and 48-pixel button heights at the emulator's 1× density.
Only the disposable emulator was used for installations.

**Remaining acceptance:** Physical Android verification of the save action
is still due. Production end-to-end record integration and supported-device
restart and editing acceptance depend on Milestone 0 enabling Start Fresh
after encrypted storage and credential-protection evidence on Android and iOS.
Physical-device accessibility acceptance remains open. Android review remains
fictional and process-local. Web remains fictional and resets on full reload.

## 2026-11-19 — Physical Android acceptance

Tested a USB-connected Samsung Galaxy A14 5G (SM-A146P, Android API 35,
arm64) using release builds with local development signing. Scratch builds
used separate probe and fictional review app IDs. The existing shared-ID
installation was neither updated nor cleared.

- The encrypted probe upgraded fictional Drift v1 to v4 and reused the
  installation key after a force-stop and independent cold launch. It reopened
  catalogue, regimen, administration/correction, symptom and marker, and
  measurement records. Plain SQLite could not read the database. Active WAL,
  the database and recovery snapshot contained no fictional sentinel plaintext.
- Android reported file-based device encryption, enforcing SELinux, an
  app-owned mode-0700 backup-excluded directory in credential-encrypted
  storage, and one hardware-backed Keystore key for the probe. The wrapping
  key did not require per-use authentication. The probe reopened the database
  after Android reported the screen locked following first unlock. The probe
  also reopened the same records after the owner unlocked the handset again.
  An application access lock is a separate Milestone 2 feature.
- The isolated fictional review saved a symptom in three-button navigation.
  The entire save action ended at y=2183, above the navigation bar starting at
  y=2273. Region controls aligned with equal widths and separate rows. A cold
  restart restored the review fixture. The previous disposable-emulator
  check also passed both navigation modes. A follow-up physical gesture-mode
  run passed with the full button above the bar (y=2276 vs y=2366), successful
  save, and a clean fictional fixture after cold restart. The original
  three-button setting was restored. The temporary review installation was
  removed.

Logs and scratch APKs are under the ignored `build/android-device-acceptance/`
directory. Android credential-change acceptance passed. Android verified a
temporary PIN, and the release probe cold-started and reopened the encrypted
journal with the existing hardware-backed key. The original PIN was restored
and verified. A subsequent cold start reopened the same journal again.
Credential values are excluded from the recorded evidence. The temporary
probe installation was removed and the original Health Journal package and
three-button navigation setting were verified unchanged.
[Physical Android issue evidence](https://github.com/repasscloud/health-journal/issues/3#issuecomment-6998105752)

## 2026-11-19 — Android production composition

Android now runs the shared record UI against the encrypted store after
explicit Start Fresh or reopen of the existing single profile. The platform
gate uses the physical Android storage and credential evidence above plus
host crash-recovery tests. iOS remains gated, and no Apple verification was
run. See [ADR 0008](docs/adr/0008-android-production-composition.md).

The host record test now exercises the UI repository boundary across
encryption, concurrent-write serialization, reopen, history, and failed marker
replacement. Format, analysis and all 67 Flutter tests passed. Web release and
both Chrome demo acceptance checks passed.

On the USB Galaxy A14 5G (Android 15/API 35), a release build using the isolated
`com.repasscloud.healthjournal.devicetest` ID completed explicit Start Fresh,
saved a fictional symptom with a torso marker and displayed it after
force-stop and cold restart. The full Save symptom action ended at y=2183,
above the system navigation bar at y=2273. The same device saved a manual
weight, showed it in Timeline, and saved a symptom title revision with the
original v2 map and edit history still available. Standard production and
review release APKs built with local development signing. The original shared app ID was
excluded from installation and data commands. Physical coverage of each
record, large text, offline lifecycle, and full accessibility remains open.

## 2026-11-19 — Android journal PIN and build verification

Optional PIN enrollment, change and removal use a separately stored Argon2id
verifier and retry state. Android locks on background and after five minutes
without pointer or hardware-key input. Android 13+ disables app-switcher
screenshots and Android 7–12 use a secure window. The demo and review app are
unchanged. [ADR 0009](docs/adr/0009-android-journal-pin.md)

The isolated Galaxy A14 5G release enrolled a fictional PIN, showed the PIN
gate on returning from Home, rejected an incorrect PIN and showed the gate
again after force-stop. A correct PIN reopened the existing measurements and
symptoms. Host tests cover persisted backoff, re-enrollment with a fresh
salt, removal requiring authentication and invalid settings. On the same
handset, the isolated Overview card displayed a blank preview, and the
foreground app showed the PIN gate after five minutes without interaction.
The older Android fallback and biometrics still need device verification.

CI now builds both Android release flavors and checks package identity,
review-only alias, backup exclusion and that production requests no network
permission. Local APKs use development signing. Drift regeneration is
checked for drift from committed generated code.

## 2026-11-19 — Portable backup container core

Implemented and tested the v1 container with Argon2id and AES-256-GCM using
the full header as associated data. Independent Python-generated ciphertext
opens with its file and password alone. Automated cases verify randomized
salt/nonce, wrong-password rejection, header/ciphertext/tag tampering,
truncation, unsupported versions and bounded KDF inputs. The schema-v4
payload uses an allowlist of journal tables. Preview validates rows in an
in-memory database, and authorized replacement uses one transaction. The
host test restores to a distinct installation key, rejects unconfirmed
replacement and preserves both original entries after an injected insert
failure. Device PIN and Keystore contents are excluded.

The Galaxy A14 5G release probe used a disposable package, independent
random installation keys, app-private temporary databases and a fictional
365-measurement file. Creation and write took 919 ms. Inspecting, restoring
into the second database and reopening took 875 ms (28,348-byte archive).
These are end-to-end timings for one sample, including the KDF. The probe
cleaned its temporary files. Production UI, document-provider handoff,
actual Android-to-iOS transfer and restore process-kill tests remain open.
See [ADR 0010](docs/adr/0010-portable-backup-container.md).

## 2026-11-19 — Android reminders, CSV and preferences

- **Reminders.** Android production schedules up to seven days or 64 local
  alarms from opted-in regimens. On the physical Galaxy A14 5G, the contextual
  prompt supported denial and later approval. The test notification posted with
  secret visibility, and a fictional daily regimen scheduled seven alarms.
  They were present again after installing and starting a new release build.
  The app displayed no recorded dose from the notification. Actual timed
  delivery, background reboot/timezone regeneration and iOS remain open.
- **CSV.** The same isolated release saved a fictional file through Android
  Downloads. A standard CSV parser verified catalogue, canonical weight,
  symptom revision and versioned marker data. The app returned to its PIN
  gate from the picker and confirmed the save after unlock. The disposable
  document was removed from the phone. PDF reports and iOS exports remain open.
- **Preferences.** Theme and display units now reopen from the encrypted
  settings table. The host repository test confirms both persist. The web
  still creates a new volatile repository with each load.
- **Verification.** Analysis and all 78 Flutter tests passed. The browser
  acceptance suite passed three runs after the test began waiting for Flutter
  Web's text-editing client before typing. This addresses the earlier CI
  focus failure without changing the reset and isolation assertions.

See [ADR 0011](docs/adr/0011-android-reminders-and-document-output.md).

## Android backup and restore UI

Android can create a password-encrypted backup through the document picker,
authenticate and preview a selected file, and restore it. A populated journal
requires the user to type REPLACE. The backup carries no local PIN credentials.
On the Galaxy A14 5G, the isolated release saved an encrypted file, rejected
an incorrect password, and replaced a two-measurement test journal with the
one-measurement backup. An initial run exposed a read-only platform byte
buffer during cleanup. The app now discards the ciphertext reference, and
replacement passed on the rebuilt release.

The host killed a separate Flutter process after the restore transaction
began replacing rows. The previous encrypted journal reopened and retry
succeeded. The analyzer and all 80 Flutter tests passed. Fresh-install UI
verification on Android is pending handset unlock. See the
[release acceptance checkpoint](docs/release-acceptance.md).

New backups are authenticated by reopening the ciphertext before the app hands
it to the document picker. A regression test verifies that a new backup
password opens only the new file while the prior file still requires its
original password. All 81 Flutter tests passed.

## 20 November 2026 — Fresh restore and device installation

The cleared isolated Android release restored the fictional Downloads
archive from first-run setup and displayed the expected 72.5 kg measurement
and medication schedule. After verification, the legacy review, shared-ID
review and isolated test packages were removed. The standard production
release built from `be0c9fb` was installed and cold-launched to the initial
setup screen. Android listed a single Health Journal package. The APK uses
local development signing.

## Android backup screen follow-up — 2026-11-20

- The create and restore actions have 12 logical pixels of separation (#19).
- Backup and restore opens as a route. Android Back returns to Settings or to
  onboarding, depending on where the flow started. Active backup operations
  block route dismissal (#20).
- The backup creation form masks both password fields initially. Each field has
  its own visibility control, and live feedback shows the 12-character minimum
  and whether the confirmation matches (#21).
- Flutter analysis and all 83 tests passed. An isolated Android release build
  on an API 35 emulator verified the action gap and Android Back from both entry
  points. Widget tests verify password visibility, live validation, and typed
  replacement confirmation.

## Android forgotten PIN reset — 2026-11-20

- The Android unlock screen offers a destructive reset after the user types
  `ERASE` and confirms. Android clears the app's private data. Reopening offers
  Start fresh or Restore existing backup. See [ADR 0012](docs/adr/0012-android-forgotten-pin-reset.md).
- Flutter analysis and all 84 tests passed. A disposable API 35 emulator
  verified cancellation, the confirmed reset, both onboarding choices and
  creation of a fresh journal. Signed production APK built successfully.

## Encrypted migration recovery regression — 2026-11-20

Host analysis and 10 focused migration tests passed. Disposable encrypted
fixtures cover partial staging and stale sidecars, a corrupt published
snapshot, and a deterministic SQLite staging-file creation failure. The
failure preserves the original database and valid recovery snapshot
byte-for-byte. Removing the obstruction allows the migration to complete.
Existing SIGKILL coverage exercises both WAL and rollback-journal modes.

The app validates and atomically publishes an encrypted pre-upgrade copy and
never automatically promotes one over the journal. If startup fails, retain
the journal, sidecars, recovery copy and installation key together. Resolve
the storage problem and retry. A staging path obstruction exercises a real
write failure, but does not reproduce mid-write disk exhaustion or power loss.

## Android reports and exports — 2026-11-20

Android generates a local 30-day PDF with UTC dates, medication plans and
explicit outcomes, correction and symptom revision provenance, versioned
front/back pain maps, and a paginated timeline. Android saves via the
document picker or shares through a read-only grant for a private cache
file. See [ADR 0013](docs/adr/0013-local-pdf-and-android-sharing.md).

Analysis and three focused PDF/CSV tests passed. Poppler verified an
eight-page fictional report and raster marker positions and area size on
v1 front and v2 back artwork. On the isolated API 35 arm64 emulator release,
Android Downloads saved both formats. Poppler and a standard CSV parser
read the saved files, and the Android Print share target displayed the PDF
preview. After force-stop, a cold launch removed the interrupted share copy.
Coverage includes accented Latin text. Additional locales, document
providers, and iOS save/share acceptance remain open.

### Disk exhaustion verification

An opt-in macOS host test fills a newly created 16 MiB disk image so the
SQLite snapshot backup fails with SQLITE_FULL. The encrypted v2 journal
and valid recovery copy survive byte-for-byte, staging and sidecars are
cleaned up, and freeing space allows encrypted migration to v4. Run with
`HJ_TEST_DISK_EXHAUSTION=1 flutter test test/migration_lifecycle_test.dart`.
The full filesystem test passed. Physical power-cut durability was outside
the process-death and storage-failure tests.

## Encrypted record history and Timeline — 2026-11-20

Today resolves the current explicit dose outcome from the correction chain,
independent of database row order. Timeline search and cards use record
type and ID together, so an ID shared by two tables cannot mix their data.

The encrypted host repository reopened catalogue revisions, effective-dated
regimens, a linked administration and correction, symptom metadata and both
v1/v2 marker views, and a manual blood pressure reading. A duplicate
occurrence was rejected and a failed marker write rolled back without
changing the prior revision. DST gap/fold and travel tests verify stable
civil-slot keys and PRN has no schedule. Widget coverage verifies orientation
and pinch-zoom alignment on the historical map, marker accessibility
semantics, and inclusive date filtering and 20-result pagination on 160
fictional entries.

On the isolated Android 15/API 35 arm64 release, an in-place upgrade and
force-stop/relaunch preserved a fictional catalogue revision, a fixed
regimen, an explicit linked skip and taken correction, a symptom and v2
marker, and a 72.5 kg reading. After switching from Australia/Adelaide to
Asia/Tokyo the original entry still displayed Australia/Adelaide and
UTC+10:30. Today showed the linked Skip after travel, and showed Taken
after the explicit correction. Timeline displayed the superseded entry
and the correction separately.

Analysis and all 31 focused records tests passed. All 92 Flutter tests
passed with the optional full-filesystem case enabled, and both Playwright
web reload/isolation checks passed. Physical-device matrix and iOS restart
evidence remain open for records. Symptom/Timeline still needs supported-device
screen-reader acceptance.

Android Settings now opens with **Reports and exports** and explicitly lists
the 30-day PDF and CSV options. A widget regression verifies the entry and
PDF save action are reachable without scrolling at 320 × 640.

## Android portable archive benchmark — 2026-11-20

Source `2f3da1d`, Flutter 3.47.9 / Dart 3.13.7, production release
probe with a separate package ID. On a physical Galaxy A14 5G
(SM-A146P, Android 15/API 35, A146PXXULEZJ3, arm64), five Argon2id v19
derivations took 753, 729, 757, 731 and 726 ms (median 731 ms).
The V1 writer used 32,768 KiB, three iterations, one lane and a 32-byte
key. Timings exclude isolate startup and represent elapsed time.
Configured KDF memory is recorded here. Peak process memory was not measured.
The probe created and flushed a 28,348-byte backup in 1,596 ms and
inspected, restored under a different random key and reopened it in 845 ms.
It used 365 fictional measurements and removed its app-private scratch files.
Probe APK SHA-256 `1d46643f1d75beca4a15858ee123d284c1f945c9b25b9a26aeb6019433983cc9`.

Nine focused host tests passed. They include the independent V1 vector,
both directions of an incorrect password pairing, authentication tampering,
the oversized file cap, every truncated prefix, malformed headers, and a
process interruption during replacement. Existing archive parameters
and format are unchanged. iOS and older or low-memory Android hardware
benchmarks remain open.

## Fictional web browser matrix — 2026-11-20

The Flutter 3.47.9 release web build from `12dd587` ran locally over HTTP on
macOS 27.2.1. Playwright 1.65.1 ran three tests in each channel: Chrome
157.0.8103.79, Edge 157.0.4341.46, Playwright Firefox 159.0 (revision 1572),
and Playwright WebKit 27.2 (revision 2388). All 12 passed. The test changes
were exercised from the same test tree. Release `main.dart.js` SHA-256:
`21056f64a1e7d8546d9085aed7663ce29996f1510804b9ff3c902cbb51d52a20`.

Each channel verified medication and measurement reload reset, independent
tabs, empty local/session storage, no IndexedDB databases or OPFS files,
empty Cache Storage, and unavailable native PIN/biometrics, backup and
notifications. WebKit used a fresh persistent Playwright profile because its
ephemeral context rejected OPFS inspection. Flutter analysis and 29 focused
host tests passed. Installed Safari, physical mobile browsers, PWA
installation, and deployed HTTPS hosting remain outside this run.

## Android Settings erasure — 2026-11-20

Android Settings → Privacy & security offers **Delete all local data**.
With a configured journal PIN, the action uses the existing throttled PIN
verifier after typed confirmation. With the PIN disabled, typed confirmation
is sufficient. The forgotten-PIN recovery keeps its separate erase path.
Both use Android's app data reset and explain that backup, PDF and CSV files
at user-selected destinations remain there.

On the dedicated `HJ_P45_Fictional_20261120` API 35 arm64 emulator
(system build 12960925), the isolated production release accepted a
fictional PIN, rejected deletion with the wrong PIN after typing `ERASE`,
and accepted deletion after the correct PIN and typed confirmation.
Cold launch showed **Start fresh** and **Restore existing backup** without
the former PIN screen. Tested APK SHA-256
`402916d220f9911aae827af9ca250844a256e0b1025cbfaefcb8e5907aa48750`
was built from the code recorded as `122577c`.
Static analysis and four focused PIN/confirmation tests passed.
See [ADR 0012](docs/adr/0012-android-forgotten-pin-reset.md).
