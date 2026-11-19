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

The isolated NativeStore adapter now upgrades encrypted Drift v1 to v2 and
reads/appends medication events with independently versioned catalogue and
regimen values. Legacy v1 event text and timestamp integers remain intact.
See ADR 0005 for unavailable fields, correction limits and the exact recovery
tests. The arm64 macOS Flutter tests exercise the encrypted SQLite path with
injected keys. The Android API 35 arm64 disposable emulator passed the release
migration probe and a separate-process restart through the platform secure key
store. iOS migration runtime, interruption during migration, independent
encrypted recovery snapshots and hardware security acceptance remain open.
See the latest status for actual build and browser results.

Timeline symptom detail is read-only and uses each saved marker's embedded
asset version, view and normalised coordinates. Widget tests cover both versions
and views at two widths with 200% text scaling and semantic marker labels.

No phone action is needed for the completed checkpoint. Keep the gate in place
while validating iOS migration runtime, interrupted migration, recovery
snapshots and device protection. Physical iPhone release acceptance previously
hit the registered-device limit and requires a suitable signing/provisioning
environment in a separately authorised session.
