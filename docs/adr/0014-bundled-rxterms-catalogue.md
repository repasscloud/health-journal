# ADR 0014 — Bundle a separate RxTerms catalogue

## Decision

Pack a pinned, publicly distributable SQLite asset with a contentless FTS5 index.
Use the app's existing SQLite library to open a read-only copy of the bundled
asset. Android builds verify its checksum and schema offline. The
release preparation tool imports validated SQL and can cross-check an
owner-built database against the same official release.

Use indexed token prefixes with exact and leading name matches ranked first.
Keep RxCUI as catalogue metadata. Selection copies editable fields into the
existing form. Only unambiguous single-ingredient strengths with supported
units populate the scalar strength fields. Display the source label so users
can distinguish strengths, preparations and pack sizes.

The catalogue is independent of journal storage, record identifiers,
administration snapshots and backup payloads. Upgrade or downgrade reads the
newly bundled catalogue on process restart. The public web demo uses manual
entry and continues to construct a fresh journal on every load.

## Consequences

Refresh and review the pinned asset before publishing. Keeping the derived
database in the repository allows offline builds and a standalone database
download under the ODbL. See [licensing and provenance](../../assets/rxterms/README.md).
