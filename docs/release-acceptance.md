# Release acceptance checkpoint

Updated 20 November 2026. Physical Android checks used the USB Samsung Galaxy A14
5G (SM-A146P, Android 15/API 35) and app ID
`com.repasscloud.healthjournal.devicetest`. The physical probe and release
UI data were fictional. Standard production and review APKs were built
separately. iOS runtime and changes were outside this Android, web and host run. Methods and outcomes are in
[IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md).

| Test | Evidence | Remaining |
|---|---|---|
| DEMO-01 | Chrome, Edge, Playwright Firefox and WebKit release automation restored the fixture after medication and measurement edits. | Installed Safari and physical mobile browsers. Isolated Chrome for Android 124.0.6367.219 rendered a blank page and logged a WebGL framebuffer error with the stock emulator GPU path. |
| DEMO-02 | All four browser automation channels opened an independent second tab. | Physical mobile browsers. |
| DEMO-03 | All four browser automation channels found empty local/session storage, IndexedDB, OPFS and Cache Storage after the edit. | Physical mobile browsers. |
| DEMO-04 | The current build has no offline app-shell service worker. | Optional offline demonstration. |
| DEMO-05 | All four browser automation channels displayed that PIN/biometrics, encrypted backup and notifications were unavailable. | Physical mobile browsers. |
| CORE-01 | Android release created a catalogue and regimen. Host tests reopen catalogue revisions and historical snapshots. | Full hardware edit, correction and restart matrix. |
| CORE-02 | Host tests preserve historical regimen and dose facts after revision and restart. Android saved a revised regimen. | Complete physical dosing/correction workflow. |
| CORE-03 | Domain and widget tests cover PRN as unscheduled. Android reminder planner excludes PRN. | Physical PRN round trip. |
| CORE-04 | Prior physical Android permission denial/grant and a secret test notification passed. API 35 emulator revoked/regranted permission, removed alarms on opt-out, and left no dose outcome. | Physical OEM battery/idle delivery, notification-tap walkthrough and iOS. |
| CORE-05 | Host DST gap/fold tests passed. The API 35 emulator rebuilt wake-ups on Adelaide-to-Auckland travel, replayed the same seven after reboot in Adelaide, and scheduled 08:00 wall time across a 25-hour DST fold. | Physical Android OEM reboot/clock handling and iOS. |
| MAP-01 | Android marker survived restart. Host widgets verify saved positions across viewport sizes. | Hardware rotation/zoom and PDF rendering. |
| MAP-02 | Domain/widget tests reject out-of-silhouette markers. All six region controls were exercised. | Screen-reader runs. |
| MAP-03 | Host round-trip tests and physical symptom entry cover markers, severity, type and preserved coordinates. | Full physical multiple-marker edits and area round trip. |
| MAP-04 | Host widgets render both saved asset versions. The physical app saved a v2 marker. | Full historical map check on hardware. |
| SECURITY-01 | Earlier physical Android release probe proved keyed reopen, unreadable raw files and encrypted sidecars and snapshot. The API 35 release migration probe repeated those checks for v1→v4 and restart. | Physical iOS and earlier Android versions. |
| SECURITY-02 | Earlier physical Android PIN passed background, relaunch and idle. API 35 emulator rechecked background/relaunch, re-locked after five idle minutes and showed a blank Overview card after secure-window hardening. | Earlier Android runtime and physical iOS. |
| SECURITY-03 | Host PIN throttling passed. API 35 emulator enrolled a virtual fingerprint, denied unlock on cancellation and after clearing the device credential, and used the journal PIN to recover. | OS biometric lockout, adding a second fingerprint, physical Android biometrics and physical iOS. |
| BACKUP-01 | Android restored a password-only file into a distinct key in the release probe. | iOS to Android physical transfer. |
| BACKUP-02 | Local Android archives open with file and password. | Android to iOS physical transfer. |
| BACKUP-03 | Host authenticated tamper, wrong password, malformed and oversized headers, and every truncated prefix pass. Android release rejected a wrong password. Physical Android KDF results and artifact hash are in implementation status. | Low-memory Android and physical iOS coverage. |
| BACKUP-04 | Typed confirmation and failed-write rollback are host tested. Earlier physical Android release replaced two fictional measurements with the selected one-measurement backup. | Additional Android providers and physical iOS cancellation and replace flow. |
| BACKUP-05 | Host Flutter child was killed after deleting and inserting inside a restore transaction. The original reopened and retry passed. | Physical process interruption and replacement-device matrix. |
| BACKUP-06 | Host journal-level test creates two archives and verifies each original password and both rejected cross-pairings. | Two-password physical document-picker round trip. |
| BACKUP-07 | Host v4 payload allowlist and authenticated injected-credential rejection passed. The physical Android backup probe restored into a different installation key. | Physical transfer with biometric and PIN enrollment on the source and fresh opt-in on destination. |
| EXPORT-01 | Local 30-day PDF shipped in #25. Host tests cover pagination, content and versioned pain markers. The isolated release exercised Android PDF document/share UI in the original checkpoint. | Physical multi-page output and provider handoff across supported platforms. |
| EXPORT-02 | Android Downloads export parsed correctly. Host tests cover escaping, time zones, revision links and canonical units. | iOS document handoff and additional locales. |
| ACCESS-01 | Host widgets cover body-region alternatives, narrow/landscape, 200% text, keyboard insets and PIN fallback. Earlier physical Android symptom save passed both navigation modes. | Complete physical TalkBack, VoiceOver and supported-OS matrix. |
| PRIVACY-01 | The APK has no Internet permission. API 35 emulator saved a fictional measurement with airplane mode, Wi-Fi and mobile data off, landscape and 200% font scaling. Cold reopen retained the measurement. | Complete physical airplane-mode, process death and lifecycle matrix. |
| PRIVACY-02 | Inspected the APK permission and backup configuration, the dependency tree and the Chrome release request trace. See [technical privacy](technical-privacy.md). | OEM transfer on second device, broader runtime capture and publisher store disclosures. |


See the [Android compatibility matrix](android-compatibility.md) for the
supported live journal and archive versions. The desktop browser evidence
comes from a local static server. Physical mobile browser and deployed
HTTPS/PWA installation remain open. Distribution signing and publication
still require the publisher configuration documented in
[Android build and release verification](android-release.md).
