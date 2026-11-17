# AGENTS.md — Instructions for Claude / Codex

Build the Flutter application described by this specification. Read README and docs `01` through `05` before coding.

## Highest-priority product invariants

1. iOS + Android: local-only single-profile production; web: fictional demo-only and reset on **each page load**.
2. No multiple profiles, cloud backend, sync, login, paid features, advertising or trackers.
3. Production records encrypted at rest; mobile backup encrypted and portable using password alone, with salt and crypto parameters in authenticated header.
4. Restore never merges; fresh install initializes the only profile; populated install requires explicit replacement confirmation and crash-safe rollback.
5. Medication scheduled != taken; never infer adherence, diagnose or recommend medication changes.
6. Pain map uses bundled versioned assets + normalised X/Y coordinates; PDF renders markers from data.
7. Native biometric/PIN protection is distinct from backup password. Do not replicate old device credentials through backup.
8. Demo must not persist visitor records; never promote demo into production web by hidden config.

## Coding approach

- Follow current Flutter stable, Dart linting and small testable layers.
- Implement full vertical slices, include meaningful validation and error feedback.
- Prefer Riverpod, go_router, Drift, Material 3; maintain stable IDs/migrations.
- Verify package compatibility with each required platform before committing to a dependency, especially SQLite at-rest encryption and notifications.
- Never use custom cryptographic primitives, hardcoded common app secrets or claim that obsolete `sqlcipher_flutter_libs` provides encryption.
- Maintain architecture decision records for material changes.
- No fake security behaviours in production; use explicitly labelled simulations in public demo.
- Keep shared UI/domain logic, inject platform adapters at startup.
- Add tests for each milestone and keep `IMPLEMENTATION_STATUS.md` current.

## Initial execution plan

A. Scaffold Flutter apps and shared domain.  
B. Create demo fixture, in-memory repository and a web reset test.  
C. Prove encrypted native DB in release-mode iOS/Android test before real records.  
D. Build medication/symptom/map UI and native persistence.  
E. Implement security/reminders, then reports and portable backup/restore.  
F. Harden accessibility, migrations, privacy and releases.

Never substitute browser persistent storage for the reset-on-reload demo requirement.
