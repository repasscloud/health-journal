# Health Journal — next continuation

Continue from the current working tree. Read AGENTS, README, specifications 01–05,
IMPLEMENTATION_STATUS and all three ADRs before coding. Preserve all changes and
Xcode signing settings; no commit/push or subagents without explicit authorisation.

Android fictional review is now a separate flavor and entry point:
`flutter build apk --release --flavor review -t lib/main_review.dart`.
Package `com.example.healthjournal.health_journal.fictionalreview`, launcher
`HJ FICTIONAL REVIEW`. It uses a fresh rich deterministic fictional memory fixture,
resets on process restart, and skips Android native plugins/protected-store channel.
Never treat it as personal-record production. Main.dart still gates native records;
web remains volatile demo-only. Android normal builds/probes now need
`--flavor production` (iOS does not). Do not install probes over a personal-data app.

The three previous review findings are fixed and regression-tested. Mixed per-time
weekday revisions are explicitly refused before opening the shared-weekday editor;
full per-time editing remains unfinished. Catalogue history viewer and regimen date
labels are present; schedule timeline names snapshot at regimen creation. Constructor
snapshots remain optional and volatile corrections still use catalogue object identity;
replace this with a stable versioned value contract before native serialization.

Next: install the review APK on an authorised physical Android phone if one appears;
check package conflict first, never uninstall/clear or blindly replace an existing app.
Build/emulator evidence is not physical-device evidence. Continue complete independent
slices: per-time weekdays, inline administration validation preserving inputs, symptom
map history viewer/editing, accessibility and timezone/occurrence semantics. Native
repository/schema/migration recovery, lock/reminders, reports and portable backup
remain unfinished. Do not weaken the physical-iPhone release/security gate or retry
unchanged Personal Team provisioning. Update status with this continuation's evidence.
