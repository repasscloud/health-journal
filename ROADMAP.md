# Health Journal completion roadmap

Updated 19 November 2026. This roadmap follows the five milestones in the
[implementation plan](05-IMPLEMENTATION-PLAN-AND-TESTS.md). See
[implementation status](IMPLEMENTATION_STATUS.md) for build and test evidence.

**Current position.** Foundation and record workflows are in progress. The
fictional Android review and web demo can be used today. The isolated encrypted
medication history has passed host tests and an Android emulator release
upgrade and restart. Native personal record entry remains gated.

## 0. Foundation and encrypted storage

- [x] Scaffold iOS, Android and web. Verify the fictional web demo resets on
  full reload, isolates tabs and leaves journal records out of browser storage.
- [x] Verify the encrypted medication event upgrade from Drift v1 to v2,
  including host rollback and unsupported-version preservation. Verify the
  Android emulator release upgrade and reopen through the platform key store.
- [ ] Exercise the migration on a disposable iOS simulator. Verify native
  release encryption, key reuse and file protection on supported physical
  iOS and Android devices, including locked-device and unlock-change cases.
  The last iPhone release attempt hit a registered-device provisioning limit.
- [ ] Test process death during migration and add an independent encrypted
  recovery snapshot. Verify the database, WAL and temporary-file lifecycle.
- [ ] Complete schema and migration coverage for the remaining record types.
  Enable the native single-profile bootstrap after the storage and recovery
  checks pass.

**Exit:** Native mobile can initialize and reopen one encrypted profile safely.
The web demo remains fictional and volatile.

## 1. Records, body maps and Timeline

- [x] Build fictional medication catalogue, regimen and explicit intake
  workflows, symptom entry with pain markers, manual measurements and Timeline.
- [x] Show read-only Timeline symptom detail using each marker’s saved
  front/back asset and coordinates. Verify v1 and v2 artwork and text labels.
- [ ] Wire catalogue, regimens, administrations, symptoms, pain markers and
  measurements to the encrypted native repository. Complete restart tests for
  each record type, including history after edits and corrections.
- [ ] Complete schedule rule editing, occurrence linkage, original event
  timezone/offset and daylight-saving behaviour. Keep schedules independent
  of explicitly confirmed administration status.
- [ ] Complete symptom editing and audit history, marker movement and areas,
  richer symptom metadata, and Timeline date filtering, pagination and
  descriptive trends.
- [ ] Fix and verify the Android **Save symptom** button overlap with system
  navigation. Cover three-button and gesture navigation alongside larger text.
  [Review screenshot](docs/test_results/20261119_104903-save-sympton-button-hidden-behind-android-overlay-buttons.png)

**Exit:** Users can enter, review and correct core records offline on mobile.
Records survive restart, and historical markers remain aligned.

## 2. Reminders and local access protection

- [ ] Add opt-in local notifications with bounded scheduling, explicit action
  confirmation, privacy controls and permission handling. Test rescheduling
  after reboot and timezone or daylight-saving changes.
- [ ] Implement optional PIN and biometric unlock, fallback and throttling,
  background and inactivity locking, and app-switcher privacy. Test denied or
  changed biometric enrollment and device credential changes.

**Exit:** Reminder delivery never records intake automatically, and configured
app locks protect access on both mobile platforms.

## 3. Reports and portable backup/restore

- [ ] Generate local PDF reports and CSV exports. Render versioned pain markers
  from saved coordinates, verify pagination and provenance, and integrate OS
  file picker and share workflows.
- [ ] Implement password-only portable encrypted backups with a versioned,
  authenticated header. Benchmark the password derivation on supported devices
  and test malformed files, tampering and wrong passwords.
- [ ] Implement preview and staged restore for a fresh install or an explicitly
  confirmed replacement. Verify crash recovery, cancellation, preservation of
  the existing journal on failure, and restoration in both iOS/Android
  directions using only the file and its password.
- [ ] Finish backup password change semantics and local data deletion.
  Keep device credentials separate from portable backups.

**Exit:** A user can export a readable report and restore an encrypted backup
to a replacement phone without the original device.

## 4. Release hardening

- [ ] Run physical-device accessibility, screen-reader, large-text, offline,
  lifecycle and supported-OS checks. Verify browser demo behaviour across the
  supported mobile and desktop browsers.
- [ ] Complete migration and backup compatibility testing and verify privacy,
  storage permissions, platform backup exclusions and release disclosures.
- [ ] Finalize publisher details, support and privacy URLs, iOS identity and
  signing, Android release signing, store assets and release CI.
- [ ] Pass the [acceptance matrix](05-IMPLEMENTATION-PLAN-AND-TESTS.md#2-required-acceptance-tests)
  for supported targets and record the evidence before release.

**Exit:** Signed mobile releases and the public fictional demo pass their
respective acceptance checks.

**Deferred from v1.** HealthKit and Health Connect imports, attachments,
desktop targets and optional offline PWA caching.
