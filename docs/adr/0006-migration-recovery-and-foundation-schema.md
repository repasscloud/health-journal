# ADR 0006 — Encrypted migration recovery and foundation schema

Accepted 2026-11-19 for the gated native store. ADR 0005 describes the
historical v1 to v2 medication event contract.

## Before upgrading

The protected opener checks the source version, integrity and foreign keys.
For supported upgrades it copies the open database through SQLite's backup
API into a separately keyed staging database in the same app-private,
backup-excluded directory. This obtains a database snapshot through SQLite,
including committed changes visible in WAL. The destination uses the
installation key, rollback journaling and full synchronous writes. The opener
closes and reopens the staging copy, checks its version, integrity and foreign
keys, then publishes it by same-directory rename as `pre-upgrade-vN.db`.
An interrupted or failed staging operation leaves the journal and any
previous published snapshot alone. A retry removes staging files and
validates a fresh snapshot before running the migration.

Migration DDL and the version stamp commit together. The published copy is a
local recovery point. It stays on the same device and depends on its
installation key. No automatic replacement of a live journal occurs.
If the journal is missing but a recovery snapshot or sidecar exists, the
opener refuses to start a new journal. Snapshot retention and deployment of a
user-facing recovery workflow remain open. This design covers process
termination with SQLite journaling. Power-loss durability of the filesystem
rename and physical locked-device behaviour have separate acceptance needs.

## Schema v3 and profile bootstrap

Fresh creation and supported encrypted v1/v2 upgrades reach v3. Upgrading v1
uses the historical medication event transformation inside the same
transaction as the remaining schema additions. v3 adds storage for schedule
rules, manual measurements, freeform notes, symptom tags, audit events and
singleton settings. It expands catalogue, regimen and symptom metadata.
Newly available fields remain null for legacy rows where the old schema
supplied no value. Optional appointments and imports are deferred.

The gated store exposes an explicit Start Fresh bootstrap operation.
It inserts singleton profile 1 transactionally and returns the existing
profile on retry. The production UI does not call it while native release
security acceptance is open.

## Scope of evidence

The host suite starts a separate Dart process and pauses it after the
migration DDL and version stamp, before the outer transaction commits.
The test sends SIGKILL in rollback-journal and WAL configurations, scans the
database files and present sidecars, checks the published snapshot with and
without the key, confirms the original rows and schema version survived,
and retries the upgrade. A separate test checks the temp schema has no
backing file with `temp_store=MEMORY` and that encrypted profile initialization
survives close and reopen without replacing an existing profile.
