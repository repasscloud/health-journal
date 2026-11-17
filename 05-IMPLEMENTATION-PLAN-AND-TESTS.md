# 05 — Delivery Plan, Acceptance Criteria and Test Matrix

## 1. Implementation approach

Deliver vertical slices with functioning builds and tests, not a giant unreviewable code dump. **Prioritise iOS/Android production correctness and web demo UI parity.** A feature is complete only when implemented, tested on the claimed platforms, accessible, and wired to correct repository adapter.

### Milestone 0 — Foundation

- Bootstrap current stable Flutter, iOS/Android/Web targets, static lint/format/test CI.
- App environment/feature capability injection; Riverpod, go_router, Material 3 light/dark/system.
- Domain models/validation, SQLite migrations, in-memory demo fixtures, generic error states.
- Decision record (ADR) documenting selected verified encrypted SQLite and portable cryptography libraries, with proof-of-concept iOS/Android tests **before** feature data is stored.
- No production web persistence.

**Exit:** `flutter analyze` and tests pass, iOS/Android builds, demo boots and reloads to fixture.

### Milestone 1 — Records and body mapping

- Medication catalogue, effective-dated regimens/schedules, PRN, actual intake/missed/skipped statuses.
- Symptoms, multiple pain markers, versioned front/back SVG, visible and accessible region picker.
- Timeline, search and basic measurements; safe migrations and edit history.
- Screens adapt to mobile phone widths, system theme and text scale.

**Exit:** Data persists through native app restart and remains encrypted; demo edits revert on reload; pain coordinates remain aligned after orientation/layout changes.

### Milestone 2 — Reminders and local access security

- Native opt-in local notifications, rolling schedule window and action confirmation.
- Optional passcode, biometrics/fallback, background auto-lock and notification privacy.
- Test permission denials, timezone/DST and app/background transitions.

**Exit:** Notifications never auto-record doses as taken; security gates behave reliably; reminder limitations documented.

### Milestone 3 — Exports and portable backups

- PDF report builder with body maps/legend/timeline, CSV exports, OS save/share.
- Argon2id + AES-GCM portable backup with authenticated header and versioned payload.
- Fresh-install restore, existing-profile replace confirmation, staged/rollback-safe restore, cross-iOS/Android interoperability.
- Change future backup password semantics; optional manual re-encryption of earlier backup files; backup reminders.

**Exit:** Can create encrypted backup on iOS, restore it on a clean Android phone with password alone, and vice versa, without original device key or server; corrupted/wrong-password archive preserves existing data.

### Milestone 4 — Release hardening

- Accessibility review, report legibility, export data protection, runtime error handling, migrations, backup schema compatibility and store disclosure/legal review.
- Demo install/offline shell (if required) with explicitly managed service worker, CSP and tracking-free static deployment.
- End-to-end physical-device test scripts and release documentation.

**Exit:** Complete acceptance checklist below and documented known limitations.

### Later (not blockers)

- Optional HealthKit/Health Connect imports of supported measurements only.
- Extra anatomical views/radiation arrows, photo attachments with encryption, appointment notes enhancement.
- Optional desktop distributions after independent platform security testing.
- No account/sync/multi-profile/monetisation roadmap without explicit new product decision.

## 2. Required acceptance tests

| ID | Test | Pass condition |
|---|---|---|
| DEMO-01 | Add medication in web, reload | Original fixed demo fixture restored; edited medication absent |
| DEMO-02 | Open second tab | Independent fixture; no shared user changes |
| DEMO-03 | Inspect browser storage | No user journal entries in localStorage/IndexedDB/OPFS |
| DEMO-04 | Run web demo offline after cache | App shell loads if offline support enabled; fixture still resets |
| DEMO-05 | Attempt demo backup/biometrics | Explicitly unavailable/simulated; no misleading security claims |
| CORE-01 | Add/modify medication and restart native app | Encrypted DB persists accurate current and historical records |
| CORE-02 | Change regimen | Old administration events retain original schedule/amount context |
| CORE-03 | PRN medication | No invented scheduled dose or missed notification |
| CORE-04 | Reminder delivered/denied | Never silently record dose as taken |
| CORE-05 | DST and time zone switch | Scheduling policy deterministic, no duplicate/unintended event status |
| MAP-01 | Front/back marker coordinate round-trip | X/Y stable across aspect ratios, orientation, zoom and PDF |
| MAP-02 | Tap outside body silhouette | Rejected; accessible region alternative works |
| MAP-03 | Multiple markers, same entry | Independently saved/rendered with severity/type/radius |
| MAP-04 | Asset update | Old saved markers render correctly with old asset version |
| SECURITY-01 | Read raw native database without key | Fails; no plaintext patient data in file/sidecars/temp |
| SECURITY-02 | Lock app and background | No visible sensitive records until successful unlock |
| SECURITY-03 | Invalid PIN/biometric denial | Proper fallback and throttling; no bypass |
| BACKUP-01 | Restore iOS backup on Android | Complete round-trip with only backup file + correct password |
| BACKUP-02 | Restore Android backup on iOS | Same as above |
| BACKUP-03 | Wrong password/truncated/tampered archive | Safe error; no active DB change |
| BACKUP-04 | Existing populated installation | Clear replace confirmation; cancel leaves data unchanged |
| BACKUP-05 | Inject process crash during restore | Original or fully restored DB recoverable, never partial/mixed |
| BACKUP-06 | Change backup password | Old backups still require old password; new backups new password |
| BACKUP-07 | Restored security | App PIN/biometric enrollments not carried to new phone |
| EXPORT-01 | PDF 30-day report | Correct dates/meds/pain map/legend/provenance/pagination |
| EXPORT-02 | Export CSV | Valid escaping, units, column names, timezone metadata |
| ACCESS-01 | Screen reader and larger text | All key tasks achievable including pain location selection |
| PRIVACY-01 | Offline native app | No backend call needed for all core workflows |
| PRIVACY-02 | Inspect dependencies and network | No ads, IAP, telemetry, PHI upload, trackers or embedded app secret |

## 3. Test types

- Unit: schedule evaluation, canonical units, validation, status transitions, normalisation, migration, KDF/header parsing.
- Widget: accessibility, forms, medication status, map controls, settings states, demo banners.
- Integration: encrypted SQLite storage, migration, backup/restore/export, OS file providers, notifications and native auth.
- Golden: UI layouts and PDF map positions with fixed sample coordinates across portrait/landscape.
- Property/fuzz: malformed archives, corrupt SQLite snapshot, missing required schema fields, random coordinates, bad dates, oversized manifest.
- Manual: iPhone and Android real hardware, app restart, airplane mode, iCloud Drive transfer, Android document provider, biometric enrollment changed, reboot and DST/time-zone simulation.

## 4. Definition of done

- Every requirement tagged implemented, deferred or blocked with documented rationale.
- No placeholder security or fake encryption.
- No TODOs left for restore atomicity or manual backup verification.
- Builds, tests and lint pass for supported targets.
- Privacy claims and app-store disclosures match actual behaviour.
- README explains local-only model, backup responsibility, missing-password limitation, reminder limitations, medical disclaimer, release setup.
- Demo fixture verified fictional and reset on every full page load.

## 5. Implementation-agent interaction protocol

Create a short `IMPLEMENTATION_STATUS.md` in the repository tracking milestone, current state, decisions, known gaps and test results. Implement independent testable slices. On any technical contradiction, use official package/platform documentation and record an ADR; preserve non-negotiable product constraints rather than silently weakening them. No requests for product clarification needed for the baseline; use reasonable defaults for labels/visuals, leave final brand values as configurable placeholders.
