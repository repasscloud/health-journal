# ADR 0001 — Platform composition and encryption proof gate

Date: 2026-11-17. Status: accepted architecture; native security candidate pending device proof.

## Dependencies and order

Foundation → volatile demo → native encryption release proof → persisted record UI →
reminders/access protection → reports/portable backup → restore crash recovery → hardening.
Native records remain unavailable until the encryption proof succeeds on both mobile
platforms. Milestone 0 cannot be marked complete based on a desktop unit test.

## Composition

Flutter stable 3.47.9 / Dart 3.13.7 installed. Platform selection occurs in main only.
Web always constructs a new DemoRepository. There is no production web configuration.
Repository contracts and immutable domain models are shared. Material 3 supports system
light/dark; go_router 18.1.4 and flutter_riverpod 3.5.0 resolve on this SDK.
Riverpod is installed for subsequent reactive application state; the small current
shell uses local state, not a second repository implementation.

## Encrypted SQLite candidate

Drift 2.35.4 / sqlite3 3.9.1 with `source: sqlite3mc` build hook. No obsolete
sqlcipher_flutter_libs. Runtime cipher checks throw in release mode (not assertions).
The probe uses only fictional data and an ephemeral CSPRNG key. It tests ciphertext,
WAL, no-key rejection, wrong-key rejection and correct-key reopen. This is not yet a
production repository or key lifecycle implementation. An isolated initial Drift schema is tested with synthetic in-memory data; production
migration recovery safeguards and repository wiring await successful native proof.

flutter_secure_storage 11.2.0 supports Android (minimum API 23) and iOS Keychain.
A native adapter and testable installation-key lifecycle are composed in the gated
`NativeStore` opener (see ADR 0002); personal-record bootstrap remains disabled.
Missing/corrupt keys refuse database replacement. Android Auto Backup is disabled,
and the native directory is under noBackupFilesDir. iOS complete Data Protection and
backup exclusion are now configured through a native channel but remain runtime-unverified.
Android emulator key reuse/restart passed; physical-device key/lock tests remain required.
Native security files are not imported by the web application composition graph.

## Portable crypto candidate

cryptography 2.9.0 provides Argon2id and AES-GCM across Dart platforms. It is resolved
for evaluation only; no backup implementation or benchmark is claimed. Parameters must
be benchmarked on supported phones before production use. Header bytes including magic,
length, salt, parameters, nonce and payload length must be authenticated as AAD.
Device keys/PINs must never enter portable archives.

## Verification sources

Reviewed official documentation on 2026-11-17:
- https://drift.simonbinder.eu/platforms/encryption/
- https://pub.dev/packages/sqlite3
- https://pub.dev/packages/go_router
- https://pub.dev/packages/flutter_riverpod
- https://pub.dev/packages/flutter_secure_storage
- https://pub.dev/packages/cryptography

Package platform declarations establish candidates, not release verification.
Notifications, local_auth, SVG/PDF/file providers are deliberately not selected yet.
Their platform restrictions must be checked before each milestone adds them.
