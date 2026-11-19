# ADR 0005 — Encrypted medication event upgrade

Accepted on 2026-11-18 for the gated native store.

## Event values

New administration events capture two independent immutable values. Catalogue
snapshot v1 captures all catalogue fields, including id, product strength and
unit, dates, archive state, and free-text fields. Regimen snapshot v1 captures
id, medication id, the prescribed amount and unit, kind, effective range,
directions, time policy and local weekday/time rules. Each JSON object carries
its own version and uses named fields, enum tokens and ISO 8601 UTC timestamps.
The codec writes weekdays in sorted order. Ad-hoc events have no regimen id or
snapshot. The actual amount and unit, explicit status, event time in UTC
microseconds, separate entry time, notes and correction metadata are event
fields. A taken timestamp requires explicit taken status.

The isolated native history adapter appends and reads events. Its correction
transaction checks that the target belongs to the same medication and regimen
and uses the same snapshot values. The self-referencing foreign key and unique
target constraint permit a single replacement per event and allow a chain
through subsequent corrections. The target row is retained. Event reads
decode the snapshots independently of current parent details. Catalogue and
regimen writes for native UI are outside this adapter. Demo corrections also
compare snapshot values.

## Drift schema v1 to v2

The migration rebuilds only the event table and its index. It derives medication
id through the existing regimen foreign key and copies the original event id,
regimen id, status, actual amount/unit, occurrence key, intended time, taken
time, entry time and opaque medication snapshot text. It copies the confirmed
taken time into event time where present. Other legacy event times stay null.
An intended time describes a plan and an entry time describes logging.

The exported v1 fixture defines no contract for units of its integer
timestamps or for the structure of snapshot text. Legacy timestamp integers
and text are retained as-is and identified by the legacy snapshot column.
Readers must account for that distinction before sorting mixed-version history.
V1 cannot supply historical catalogue/regimen values, schedule rules,
event notes, correction targets/reasons, timezone, or original offset. Current
parent values cannot establish what was recorded at the time. Legacy events
are readable through the adapter, with legacy corrections deferred pending a
contract that preserves opaque history. New event original timezone/offset and
occurrence linkage also remain pending.

Rename, copy, old-table removal, index creation, FK validation and the version
stamp share a single SQLite transaction on the already-keyed connection. The
version stamp is inside the transaction because Drift writes its automatic stamp
after the opening callback. The protected opener checks the version and DB/FK
integrity before handing over the connection. Unsupported upgrades are rejected
before migration. This extends the gated opener in ADR 0002. Its requirements
for production recovery evidence still apply.

## Exercised recovery

The arm64 macOS Flutter test suite creates an isolated temporary store through
the real NativeStore key lifecycle and SQLite3MultipleCiphers connection, using
an injected in-memory key store. It seeds from the exported v1 SQL, upgrades,
checks foreign keys, appends fictional events including an ad-hoc intake and a
correction, and closes and reopens with the same key. It scans the DB and
present sidecars for fictional plaintext with WAL active and again after close.

An additional valid FK reference deliberately prevents dropping the renamed
v1 table after event copy. Reopening confirms the rollback preserved the old
table, records, FK, and version; removing the test dependency permits retry.
A separate version-99 test verifies rejection, unchanged file bytes and
keyed reinspection of the original records and version. These are exception
rollback and unsupported-version tests. Process termination during migration,
an independent encrypted recovery snapshot, mobile protection/secure-storage
behaviour and portable restore are pending. Production personal entry stays gated.

## Android runtime follow-up — 2026-11-19

The dedicated release probe seeded the exported v1 schema on a fresh Android
API 35 arm64 emulator, upgraded it through the Android protected directory
and secure installation key adapter, then wrote and reread an ad-hoc event
and linked correction. The probe checked foreign keys and scanned the DB and
present sidecars for sentinel plaintext during WAL writes and after close.
Force-stop and cold launch reopened and verified the same records in a new
process using the stored key. Exception rollback and unsupported version
preservation were exercised by the host suite. Termination during migration,
iOS migration runtime and physical-device security acceptance remain open.
