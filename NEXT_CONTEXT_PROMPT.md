# Health Journal — next continuation

Read AGENTS.md, README.md, specifications 01–05, the latest checkpoint in
IMPLEMENTATION_STATUS.md and all ADRs before editing. Preserve uncommitted work.
The 2026-11-18 checkpoint and ADR 0005 supersede earlier handoffs that describe
an isolated review package, pending inline administration validation, a v1-only
store, or text-only symptom history.

Android production and fictional review share `com.repasscloud.healthjournal`.
The review entry point requires its compiled Android flavor, skips native
storage plugins and starts a volatile fictional fixture on each process launch.
Web always starts a fresh volatile fictional repository on each full page load.
Native production personal record entry remains gated. Keep builds and mobile
runtime evidence distinct. Restrict installs/probes to explicitly verified
disposable virtual targets for this checkpoint. Leave physical installations,
signing, provisioning, deployments, commits and pushes untouched.

The isolated NativeStore adapter upgrades encrypted v1 or v2 to v3 and saves
a verified encrypted local snapshot before migrating. Host tests kill a
separate process before commit in WAL and rollback-journal modes, inspect
the original and snapshot, and retry. v3 adds the remaining foundation
tables and a tested explicit singleton profile bootstrap. See ADRs 0005 and
0006 and the latest implementation status for build/runtime evidence.

Timeline symptom detail is read-only and uses each saved marker's embedded
asset version, view and normalised coordinates. Widget tests cover both versions
and views at two widths with 200% text scaling and semantic marker labels.

Production Start Fresh and personal records remain gated. Physical Android
acceptance requires an isolated installation and owner-assisted credential
checks. iOS testing was excluded from the latest checkpoint and remains open
for eventual mobile release acceptance.
