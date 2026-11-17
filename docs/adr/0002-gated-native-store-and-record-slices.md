# ADR 0002 — Protected native opener and fictional record slices

Date: 2026-11-17. Status: accepted; native personal-record entry remains blocked.

## Security dependency

The original release cipher probe passes on the Android API 35 arm64 emulator.
An iPhone was detected this session, but deployment failed because Apple reported
that the signing team reached its registered-iPhone limit and no provisioning
profile matched the application. This is a signing blocker, not encryption proof.
No credentials or provisioning settings were changed to bypass it.

`NativeStore` composes the installation-key lifecycle with encrypted SQLite. The
production app does **not** call it yet: `nativePending` remains unconditional on
native platforms. Only the dedicated fictional probe invokes native storage.
The opener refuses missing keys when DB or SQLite sidecars exist, wipes the loaded
key buffer after SQLite setup, checks integrity/FKs, and rejects unsupported schema
versions without speculative DDL. It never deletes/recreates a failed database.

Android supplies an owner-only directory under `noBackupFilesDir`; Auto Backup is
also disabled. iOS prepares an app-support directory with complete Data Protection,
backup exclusion and reapplies attributes to existing sidecars. New files inherit
the protected directory policy; physical-device lock/unlock and sidecar attribute
checks are still required. Complete protection may make storage unavailable while
locked; future reminder actions must handle this without falsely confirming intake.
The dedicated store probe passed on the Android emulator, including a second process
launch with the same secure-storage key. iOS file protection/Keychain runtime and
physical Android Keystore behaviour remain unverified.

The v1 Drift schema is exported to `test/fixtures/schema_v1.json`. There are no
supported upgrades yet. Unsupported version opening is tested against an encrypted
file and leaves the sentinel, version and file bytes intact. This is a refusal
safeguard, not completed migration recovery. Before introducing a supported upgrade,
add a transactional migration, encrypted recovery snapshot and crash-injection tests.

## Independent milestone 1 work

The web/demo repository remains process-local memory. Immutable regimen revisions
use exclusive effective end dates and reject overlaps. Revision closes the previous
range atomically in memory. Explicit administrations snapshot the name, dose and
regimen context; schedule creation never creates intake. Schedules declare device-
local wall time and weekdays. DST occurrence generation/notifications are not yet
implemented. The current form exposes one daily time; the domain accepts multiple.

Versioned original schematic SVG polygons use a 100 × 200 viewBox. The same polygon
geometry performs silhouette hit testing; a test checks every bundled polygon
against the geometry. A fixed-aspect image/marker canvas sits inside InteractiveViewer,
so zoom/pan transforms the image and markers together. Text region buttons provide
an alternative to precision touch. Front/back interpretation preserves anatomical
laterality. Only v1 is accepted; future versions must retain its assets/geometry.
Markers store data, not screenshots. These are schematic body maps, not clinical
anatomical illustrations. PDF rendering remains milestone 3.

Manual measurement forms use explicit canonical units and manual provenance. No
conversion/import feature or clinical range interpretation is claimed. Timeline
search combines regimen changes, explicit administrations, symptoms and measurements.
These slices are demo-only pending native repository/schema integration. Correction
history, full catalogue fields, symptom timing/metadata, marker edit/move/radius,
filtering/pagination and native persistence are still incomplete.

## Dependency verification

`flutter_svg` 2.4.0 was selected after reviewing the official package platform list
(Android, iOS, web), then resolving against the locked Flutter/Dart SDK. It loads
bundled assets only. Its transitive HTTP dependency does not introduce network calls
in this app. No new storage or cryptography dependency was added.

Official sources reviewed 2026-11-17:
- https://pub.dev/packages/flutter_svg
- https://developer.apple.com/documentation/foundation/fileprotectiontype
- https://developer.apple.com/documentation/foundation/using-the-file-system-effectively
- https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup
- https://drift.simonbinder.eu/migrations/step_by_step/
- https://drift.simonbinder.eu/migrations/api/
