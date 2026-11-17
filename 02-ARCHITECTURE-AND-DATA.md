# 02 — Architecture, Data Contracts and Database

## 1. Supported targets

One Flutter/Dart repository targeting **iOS and Android production** plus **Flutter Web/PWA demo-only**. macOS/Windows/Linux build optional. Use current stable Flutter and Dart, lock exact resolved versions in `pubspec.lock`, use current supported APIs.

## 2. Suggested libraries (verify before pinning)

- Flutter Material 3; Riverpod for state, go_router for navigation.
- Drift for typed SQLite queries and migrations; **verified native encrypted SQLite integration**, not plain SQLite mislabeled as encrypted.
- `flutter_secure_storage` or audited native Keychain / Android Keystore adapter for protected local device key wrapping; never assume Android secure storage is automatically migratable to another phone.
- `local_auth` for native biometrics/device auth; custom app PIN verifier (scrypt/Argon2id + salt/parameters, rate limits); use native platform secure mechanisms for actual device key protection.
- `flutter_local_notifications` + timezone package (recheck exact alarm rules and current platform limits).
- `flutter_svg` for versioned body vectors, CustomPainter for markers and PDF drawing.
- `pdf` and `printing` for local report generation, OS file chooser/share integration.
- Cryptography: vetted implementation for Argon2id and authenticated AES-256-GCM. **Never implement cryptographic primitives yourself.** Test platform build and memory/performance.
- For exports: `csv` or manual standards-compliant encoding with correct escaping.

**Encryption note:** `sqlcipher_flutter_libs` is obsolete with newer sqlite3 stacks. Drift documents SQLite3MultipleCiphers and an encrypted executor approach. Select one actively maintained and auditable combination, prove ciphertext at rest and release builds on both targets. Explicitly document exact packages and compatibility in an ADR before implementing encryption. Do not silently fall back to plaintext.

## 3. Architecture layers

```text
lib/
  app/                  # bootstrap, routes, theme, dependency wiring
  core/                 # clock, ids, validation, errors, units, time, crypto interfaces
  domain/               # entities, value objects, policies, services
  data/
    schema/             # drift tables, migrations
    repositories/       # repository contracts + encrypted native adapters
    demo/               # immutable seed fixture + volatile in-memory repositories
  features/
    onboarding/ today/ medications/ symptoms/ body_map/
    timeline/ measurements/ reports/ settings/ backup/
  platform/
    notifications/ auth/ backups/ health/ files/ security/
assets/
  bodymaps/v1/front.svg
  bodymaps/v1/back.svg
  demo/fixture_v1.json
```

Define `RepositoryFactory` and `PlatformCapabilities` at composition root. Do not scatter `kIsWeb` checks throughout screens; select one demo environment **at application bootstrap** and inject capabilities.

```dart
abstract interface class JournalRepository {
  Future<List<Medication>> medications();
  Future<void> saveMedication(Medication medication);
  Future<List<SymptomEntry>> symptoms(DateTime from, DateTime to);
  // Additional typed methods, transactions and observables.
}

abstract interface class BackupService {
  Future<BackupResult> exportEncrypted(String password);
  Future<RestorePreview> validateAndPreview(
      Uint8List archive, String password);
  Future<void> restoreReplace(ValidatedBackup backup);
}
```

Adapter implementations: `EncryptedNativeJournalRepository` for production; `InMemoryDemoJournalRepository` for web. Backup interface production implementation only. Explicit unsupported capability UI in demo.

## 4. Schema requirements

Use UUIDs, FK constraints, unique relevant keys, indexed event timestamps and a schema version table. Suggested **logical** tables (names/columns may evolve with migrations):

| Table | Key fields |
|---|---|
| `profile` | constant singleton key, optional name/DOB; at most one record |
| `medications` | id, name/form/strength, instruction, archived, created/modified |
| `medication_regimens` | id, medication_id, amount/unit, effective_from/to, kind (fixed/PRN/course), original instructions |
| `medication_schedule_rules` | id, regimen_id, local clock time, selected weekdays, zone policy, reminder flag |
| `medication_events` | id, regimen_id, schedule_occurrence_key nullable, status, intended_at nullable, taken_at nullable, recorded_at, amount/unit, notes, correction metadata |
| `symptom_entries` | id, name/category, onset_at/end_at, recorded_at, severity nullable, triggers, relief, notes |
| `pain_markers` | id, symptom_id, body_view, x/y/radius, body_asset_version, region_code, laterality, severity/type |
| `measurements` | id, kind, canonical_value(s), canonical_unit, measured_at, recorded_at, provenance, source_ref |
| `journal_notes` | id, event_at, recorded_at, notes |
| `appointments` | id, starts_at, clinician optional, questions, notes (optional v1) |
| `audit_events` | id, object_type/id, event_at, action, non-sensitive metadata or protected snapshot |
| `settings` | single local settings row, excluding secret material |
| `schema_info` | schema_revision, created_with_app_version |

Use value objects and constraints to keep x/y in `[0,1]`, radius within sensible bounds, severity within `0..10`, nonempty medication names, correct date ordering, and unit consistency. Do not store bitmap for each pain marker. Store full absolute timestamps in UTC and original local offset/time zone where relevant; schedule rules represent **local wall time and zone semantics**. Rendering must not flip left and right. Keep medications and regimen history separate; editing a current schedule does not mutate past events.

## 5. Backup payload logical schema

Portable archive includes database snapshot (or versioned domain dump), any attachments and manifest; no machine-specific encryption keys, biometric enrollment, OS notification IDs, cached secrets, temp reports or platform paths. Record schema version, app version, data counts and body map asset versions in authenticated manifest. Restore migrates supported old archives to current schema in a staging environment. Rebuild reminders; request/validate permissions again; do **not** copy old biometric/PIN credentials onto a new phone. Optional profile metadata included because it is the one person's data.

## 6. PDF body-map renderer

Build platform-agnostic report representation from pain marker records. For PDFs use versioned SVG/rasterized vector asset and translate normalised positions into **actual painted image rectangle**. Match image aspect ratio and coordinate origin in Flutter and PDF. Marker ID + label legend, severity, region, pain type and timestamp. Store maps assets in repository, keep old asset revisions available.

## 7. Demo fixture conventions

JSON schema uses same domain models, fixed fictitious person, deterministic stable UUIDs and historical event times defined relative to demo's anchor date (or intentionally fixed sample dates). Fresh in-memory clone for each app bootstrap; never reuse mutated fixture objects. UI parity with native, but simulated device features clearly marked. Tests enforce no demo persistence API is invoked and no native storage/backups are called.

## 8. Performance and resilience

List pagination/virtualisation for timeline, indexed queries, debounced search, database transactions on multi-row writes, background isolate for expensive report/crypto tasks where supported, cancellation/error handling, minimal PHI in logs. Export with bounded memory where practical. Keep database in private app directory with durable flush/transaction semantics. Upgrade schema only after local recovery safeguard and migration tests. Separate encrypted attachment storage from DB if attachments are enabled.
