# Technical privacy and storage evidence

## Android production

The app stores one profile in encrypted SQLite under the app's private
`no_backup/protected_journal` directory. A randomly generated installation
key is protected by Android Keystore-backed secure storage. Journal sidecars
and migration snapshots stay in the protected directory. The journal and
backup validation databases configure SQLite temporary storage in memory.
The backup validator stages authenticated contents in a separate in-memory
database before writing through a transaction to the active encrypted journal.

The production manifest opts out of Android backup, disables legacy full
backup and declares separate exclusions for cloud backup and Android
device-to-device transfer. Android always excludes the no-backup and cache
directories. The APK includes the exclusions for private, device-protected
and external app-owned files. The local backup transport on API 35
returned `Backup is not allowed` for the isolated release migration
package. OEM transfer behavior still needs a physical
transfer test with a second Android device. Android cross-platform transfer
has no app configuration. [Android Auto Backup rules](https://developer.android.com/identity/data/autobackup)

The Android document picker creates or opens only documents the person
chooses. The app requests no broad storage access. Backup export hands the
picker a password-encrypted archive. PDF and CSV exports are readable by
the chosen provider or recipient. A PDF sent through the share sheet uses
a private cache file and a read-only URI grant. The app revokes the grant
and removes the file when it replaces the share or its ten-minute timer
runs. The next app launch removes interrupted shares. On the isolated API
35 release, opening the PDF share chooser produced a mode-0600 cache file.
The file was absent after dismissing the chooser, force-stopping and
cold-launching the app. No recipient was selected. A recipient can
retain its own copy even after the grant expires. Android package reset
removes app-owned data and keys. Copies already exported to an external
location stay under the recipient's or provider's control.

The production APK has no Internet permission, exact-alarm request, or
broad storage permission. It prompts for notification permission from
the reminder controls on Android versions that require it. Production
also requests normal boot and biometric permissions for the corresponding
features. The encrypted reminder cache holds only bounded wake-up instants
and the plan zone, under a separate Android Keystore key. AndroidX's
signature-level receiver permission is internal to the app package.
The production dependency tree was inspected with
`flutter pub deps --no-dev --style=compact`. It contains SQLite, routing,
UI, secure storage, file paths, cryptography, SVG and local report
generation dependencies. It includes an HTTP library through SVG tooling.
The journal source has no HTTP client use or backend API. A process-level syscall trace bounded to 23 seconds (API 35 arm64 emulator, release package) during
offline measurement entry observed no IPv4 or IPv6 socket calls. The
inspected
dependency tree includes no advertising, analytics, payment or crash
reporting SDK. App-store declarations and OEM transfer remain subject to
publisher and physical-device verification.

## Fictional browser demo

Desktop automation verified single-load, in-memory edits on four browser
channels and found no journal persistence in local/session storage,
IndexedDB, OPFS or Cache Storage. The web build booted from a local static
server. A Chrome 157.0.8103.79 Playwright request capture for initial load,
fictional medication save and reload observed static GETs only. The build
fetched Flutter CanvasKit from `www.gstatic.com` and Roboto from
`fonts.gstatic.com`. The observed requests contained no journal values
and had no request bodies. Browser infrastructure and those static
asset hosts can see normal network metadata such as IP addresses. Deployed
hosting, mobile browser traffic and store disclosures were outside that
capture.

See the [acceptance matrix](release-acceptance.md) and
[implementation status](../IMPLEMENTATION_STATUS.md) for build identifiers
and narrower test claims.
