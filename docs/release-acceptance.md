# Release acceptance checkpoint

19 November 2026. Physical Android checks used the USB Samsung Galaxy A14
5G (SM-A146P, Android 15/API 35) and app ID
`com.repasscloud.healthjournal.devicetest`. The physical probe and release
UI data were fictional. Standard production and review APKs were built
separately. iOS platform results are deferred. Methods and outcomes are in
[IMPLEMENTATION_STATUS.md](../IMPLEMENTATION_STATUS.md).

| Test | Evidence | Remaining |
|---|---|---|
| DEMO-01 | Chrome, Edge, Playwright Firefox and WebKit release automation restored the fixture after medication and measurement edits. | Physical mobile browsers and installed Safari. |
| DEMO-02 | All four browser automation channels opened an independent second tab. | Physical mobile browsers. |
| DEMO-03 | All four browser automation channels found empty local/session storage, IndexedDB, OPFS and Cache Storage after the edit. | Physical mobile browsers. |
| DEMO-04 | The current build has no offline app-shell service worker. | Optional offline demonstration. |
| DEMO-05 | All four browser automation channels displayed that PIN/biometrics, encrypted backup and notifications were unavailable. | Physical mobile browsers. |
| CORE-01 | Android release created a catalogue and regimen. Host tests reopen catalogue revisions and historical snapshots. | Full hardware edit, correction and restart matrix. |
| CORE-02 | Host tests preserve historical regimen and dose facts after revision and restart. Android saved a revised regimen. | Complete physical dosing/correction workflow. |
| CORE-03 | Domain and widget tests cover PRN as unscheduled. Android reminder planner excludes PRN. | Physical PRN round trip. |
| CORE-04 | Android permission denial/grant and secret test notification passed. No administration was recorded. | Timed delivery and revocation under OS battery modes. |
| CORE-05 | Host tests cover DST gaps/folds and stable civil slots across zone offsets. | Physical travel, DST, reboot and clock changes. |
| MAP-01 | Android marker survived restart. Host widgets verify saved positions across viewport sizes. | Hardware rotation/zoom and PDF rendering. |
| MAP-02 | Domain/widget tests reject out-of-silhouette markers. All six region controls were exercised. | Screen-reader runs. |
| MAP-03 | Host round-trip tests and physical symptom entry cover markers, severity, type and preserved coordinates. | Full physical multiple-marker edits and area round trip. |
| MAP-04 | Host widgets render both saved asset versions. The physical app saved a v2 marker. | Full historical map check on hardware. |
| SECURITY-01 | Release probe on physical Android proved keyed reopen, unreadable raw files and encrypted sidecars and snapshot. | Additional Android hardware and physical iOS. |
| SECURITY-02 | Android PIN gated background return, cold start and five-minute idle. Overview screenshot was blank. | Earlier Android secure-window fallback and physical iOS. |
| SECURITY-03 | Android rejected a wrong PIN. Host tests cover persisted throttling and authenticated removal. | Biometric denial, fallback and enrollment change. |
| BACKUP-01 | Android restored a password-only file into a distinct key in the release probe. | iOS to Android physical transfer. |
| BACKUP-02 | Local Android archives open with file and password. | Android to iOS physical transfer. |
| BACKUP-03 | Host authenticated tamper, wrong password, malformed and oversized headers, and every truncated prefix pass. Android release rejected a wrong password. Physical Android KDF results and artifact hash are in implementation status. | Low-memory Android and physical iOS coverage. |
| BACKUP-04 | Typed confirmation is widget-tested. Host tests preserve the previous journal when confirmation or insert fails. | See the latest Android document-picker evidence in implementation status. |
| BACKUP-05 | Host Flutter child was killed after deleting and inserting inside a restore transaction. The original reopened and retry passed. | Physical process interruption and replacement-device matrix. |
| BACKUP-06 | Each export prompts for its own password and the document picker creates a new file. | Physical two-password round trip. |
| BACKUP-07 | Archive allowlist excludes the Android PIN verifier and device-local key. The isolated probe used a distinct key. | Replacement-device and biometric enrollment flows. |
| EXPORT-01 | Pending. | PDF with versioned pain maps, output pagination and physical verification. |
| EXPORT-02 | Android Downloads export parsed correctly. Host tests cover escaping, time zones, revision links and canonical units. | iOS document handoff and additional locales. |
| ACCESS-01 | Widget tests cover six body regions, narrow/landscape, 200% text and keyboard insets. The full save action passed both Android navigation modes. | Complete TalkBack, VoiceOver, rotation and OS matrix. |
| PRIVACY-01 | The production Android manifest requests no Internet permission. Core encrypted startup and restart passed physically. | Full hardware airplane-mode and lifecycle matrix. |
| PRIVACY-02 | CI inspects package identity, notification permission scope, backup exclusion and the production Internet permission. | Runtime traffic and release disclosure review. |
