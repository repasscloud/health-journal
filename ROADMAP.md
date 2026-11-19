# Health Journal completion roadmap

Updated 19 November 2026. This roadmap follows the five milestones in the
[implementation plan](05-IMPLEMENTATION-PLAN-AND-TESTS.md). See
[implementation status](IMPLEMENTATION_STATUS.md) for build and test evidence.

**Current position.** Foundation and record workflows are in progress. The
fictional Android review and web demo can be used today. Encrypted recovery
and Drift v4 have host acceptance coverage. Android emulator tests cover
the encrypted medication upgrade through v3 and the Milestone 1 symptom
form. Android production now opens the encrypted journal. iOS personal
record entry remains gated.

## 0. Foundation and encrypted storage

- [x] Scaffold iOS, Android and web. Verify the fictional web demo resets on
  full reload, isolates tabs and leaves journal records out of browser storage.
  *No dedicated issue.*
- [x] Verify the encrypted medication event upgrade from Drift v1 to v2,
  including host rollback and unsupported-version preservation. Verify the
  Android emulator release upgrade and reopen through the platform key store.
  *No dedicated issue.*
- [ ] Exercise the migration on a disposable iOS simulator. Verify native
  release encryption, key reuse and file protection on supported physical
  iOS and Android devices, including locked-device and unlock-change cases.
  The last iPhone release attempt hit a registered-device provisioning limit.
  [#3](https://github.com/repasscloud/health-journal/issues/3)
- [x] Test process death before migration commit in host WAL and rollback
  modes. Verify the independent encrypted recovery snapshot and scan the
  database and present sidecars. Verify SQLite temporary storage uses memory.
  [#4](https://github.com/repasscloud/health-journal/issues/4)
- [x] Add v3 foundation tables and test encrypted v1 and v2 upgrades.
  Verify explicit, idempotent single-profile bootstrap in the isolated store.
  [#5](https://github.com/repasscloud/health-journal/issues/5)
- [ ] Connect Start Fresh to production after mobile storage and recovery
  security acceptance. Physical Android acceptance includes hardware-backed
  key behaviour, locked-device behaviour and changes to the unlock credential.
  The Samsung release probe verified a hardware-backed key, protected storage,
  restart after upgrade, and reopen during screen lock and after unlock.
  The same records reopened after a device credential change and again after
  restoring the original credential.
  Android production Start Fresh and encrypted cold restart passed on the
  same handset under the isolated test ID. iOS remains deferred.
  [#5](https://github.com/repasscloud/health-journal/issues/5), [#3](https://github.com/repasscloud/health-journal/issues/3)


**Exit:** Native mobile can initialize and reopen one encrypted profile safely.
The web demo remains fictional and volatile.

## 1. Records, body maps and Timeline

- [x] Build fictional medication catalogue, regimen and explicit intake
  workflows, symptom entry with pain markers, manual measurements and Timeline.
  *No dedicated issue.*
- [x] Show read-only Timeline symptom detail using each marker’s saved
  front/back asset and coordinates. Verify v1 and v2 artwork and text labels.
  *No dedicated issue.*
- [ ] Wire catalogue, regimens, administrations, symptoms, pain markers and
  measurements to the encrypted native repository. Complete restart tests for
  each record type, including history after edits and corrections.
  The Android production UI uses the encrypted repository. Host tests
  exercise every supported record type. The physical restart matrix remains
  open beyond the smoke checks in the implementation status.
  [#16](https://github.com/repasscloud/health-journal/issues/16)
- [ ] Complete schedule rule editing, occurrence linkage, original event
  timezone/offset and daylight-saving behaviour. Keep schedules independent
  of explicitly confirmed administration status.
  The shared editor and device-local occurrence rules are available in
  Android production. Host restart tests cover occurrence and timezone
  metadata. Full physical schedule and travel acceptance remains open.
  [#17](https://github.com/repasscloud/health-journal/issues/17)
- [ ] Complete symptom editing and audit history, marker movement and areas,
  richer symptom metadata, and Timeline date filtering, pagination and
  descriptive trends.
  Fictional editing, marker movement and areas, history, filtering, pagination
  and weekly counts are implemented. Encrypted history is host-tested.
  Mobile production round-trip and accessibility acceptance remain open.
  [#18](https://github.com/repasscloud/health-journal/issues/18)
- [x] Fix and verify the Android **Save symptom** button overlap with system
  navigation. Cover three-button and gesture navigation alongside larger text.
  [Review screenshot](docs/test_results/20261119_104903-save-sympton-button-hidden-behind-android-overlay-buttons.png)
  Widget and Android 35 emulator checks passed in both navigation modes.
  The Samsung release review passed in both physical navigation modes.
  [#1](https://github.com/repasscloud/health-journal/issues/1)
- [x] Improve body-region button spacing and alignment on the symptom form.
  Verify the layout at narrow widths and larger text sizes.
  [#2](https://github.com/repasscloud/health-journal/issues/2)

**Exit:** Users can enter, review and correct core records offline on mobile.
Records survive restart, and historical markers remain aligned.

## 2. Reminders and local access protection

- [ ] Add opt-in local notifications with bounded scheduling, explicit action
  confirmation, privacy controls and permission handling. Test rescheduling
  after reboot and timezone or daylight-saving changes.
  [#6](https://github.com/repasscloud/health-journal/issues/6)
- [ ] Implement optional PIN and biometric unlock, fallback and throttling,
  background and inactivity locking, and app-switcher privacy. Test denied or
  changed biometric enrollment and device credential changes.
  [#7](https://github.com/repasscloud/health-journal/issues/7)

**Exit:** Reminder delivery never records intake automatically, and configured
app locks protect access on both mobile platforms.

## 3. Reports and portable backup/restore

- [ ] Generate local PDF reports and CSV exports. Render versioned pain markers
  from saved coordinates, verify pagination and provenance, and integrate OS
  file picker and share workflows.
  [#8](https://github.com/repasscloud/health-journal/issues/8)
- [ ] Implement password-only portable encrypted backups with a versioned,
  authenticated header. Benchmark the password derivation on supported devices
  and test malformed files, tampering and wrong passwords.
  [#9](https://github.com/repasscloud/health-journal/issues/9)
- [ ] Implement preview and staged restore for a fresh install or an explicitly
  confirmed replacement. Verify crash recovery, cancellation, preservation of
  the existing journal on failure, and restoration in both iOS/Android
  directions using only the file and its password.
  [#10](https://github.com/repasscloud/health-journal/issues/10)
- [ ] Finish backup password change semantics and local data deletion.
  Keep device credentials separate from portable backups.
  [#11](https://github.com/repasscloud/health-journal/issues/11)

**Exit:** A user can export a readable report and restore an encrypted backup
to a replacement phone without the original device.

## 4. Release hardening

- [ ] Run physical-device accessibility, screen-reader, large-text, offline,
  lifecycle and supported-OS checks. Verify browser demo behaviour across the
  supported mobile and desktop browsers.
  [#12](https://github.com/repasscloud/health-journal/issues/12)
- [ ] Complete migration and backup compatibility testing and verify privacy,
  storage permissions, platform backup exclusions and release disclosures.
  [#13](https://github.com/repasscloud/health-journal/issues/13)
- [ ] Finalize publisher details, support and privacy URLs, iOS identity and
  signing, Android release signing, store assets and release CI.
  [#14](https://github.com/repasscloud/health-journal/issues/14)
- [ ] Pass the [acceptance matrix](05-IMPLEMENTATION-PLAN-AND-TESTS.md#2-required-acceptance-tests)
  for supported targets and record the evidence before release.
  [#15](https://github.com/repasscloud/health-journal/issues/15)

**Exit:** Signed mobile releases and the public fictional demo pass their
respective acceptance checks.

**Deferred from v1.** HealthKit and Health Connect imports, attachments,
desktop targets and optional offline PWA caching.
