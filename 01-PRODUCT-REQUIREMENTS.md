# 01 — Product Requirements and User Experience

## 1. Target experience

The app belongs to **one person only**, locally on their phone. It provides fast, reassuring data entry without making clinical conclusions. Users can prepare accurate summaries for a medical professional. No onboarding account or identity verification.

### First-run native flow

Welcome → `Start Fresh` OR `Restore Existing Backup`.

**Start Fresh**: privacy and limitations explanation; optional profile name and date of birth (not required); local encryption initialisation; optional app PIN and biometrics; optional reminder permission when first needed; encourage first encrypted backup after meaningful entries. No empty or second profile.

**Restore**: select portable file → enter password → decrypt and validate → preview backup metadata/date/counts → restore into empty local store; establish this as the sole profile; configure local unlock credentials on this device; reschedule eligible reminders with permission.

**Populated app restore**: explicit warning that existing local contents will be **replaced**, with backup-before-replace option, typed/destructive confirmation, transactional/staged restore, rollback on failure. No merging or creating new profiles.

### Navigation

Bottom navigation for phone: `Today`, `Medications`, `Symptoms`, `Timeline`. Tablet responsive/navigation rail optional. The top-right cog opens Settings for units, appearance, and device features. Record measurements from Today and review them in Timeline. Reports, Trends, and Backup/Restore are accessible contextually as those features become available. Use Material 3, consistent spacing/typography, meaningful empty/loading/error states, touch targets, dynamic type and screen-reader semantics.

## 2. Today dashboard

Show date, next scheduled medications, due/overdue/recorded statuses, quick actions `Record medication`, `Log symptom`, `Record measurement`, brief today timeline, optional reminder/backup status. **Never label a scheduled dose 'taken' without explicit event confirmation.** Overdue is not necessarily missed; unknown remains unknown until user records a state (optional rule to offer 'mark missed'). Privacy-aware notification previews.

## 3. Medication catalogue

Fields: ID, display name, optional generic/brand, form (tablet/liquid/inhaler/etc), strength + unit, instructions/directions (including with-food), reason (optional), prescribed-by (optional free text), started/stopped/paused dates, active status, notes, created/updated timestamps. Store dose **amount + unit** separately from product strength. Support variable schedules: one/multiple daily times; selected weekdays; date-bounded courses; **PRN/as needed** (no invented due times); explicit timezone policy; reminders toggled per schedule. Allow editing and archival, never destructively rewrite history.

Medication administration event: intended/scheduled occurrence reference (nullable for PRN), actual recorded intake time, entered time, amount/unit, status (`taken`, `skipped`, `missed`, `unknown`/unconfirmed), optional reason/notes; delay and corrections as user-entered facts. Preserve historical medication/schedule snapshots or effective-dated revisions so old reports stay accurate. Prevent accidental duplicates through clear UI and optional duplicate warning; do not silently discard user data. No dosage recommendations.

### Medication reminders

Local notifications only, opt-in. `Taken`, `Snooze`, `Skip`, and `Open app` actions where platform supports; every action must persist a confirmed event, not assume delivery. Reschedule on medication changes, timezone changes, DST, reboot and permission changes as practical. Bound queued notifications; iOS has a limited pending queue. Display reminders as **best effort**, never guaranteed or a substitute for clinical systems. Optional redact medication names in lock-screen alerts.

## 4. Symptoms and pain journal

General symptom fields: ID, category/type (user-defined supported), title, severity 0–10 (optional for symptoms where not applicable), start/end, continuous/intermittent, triggers, relief measures, perceived effect, notes, event timestamp distinct from recorded/updated timestamps, tags. Edits carry audit metadata. Optional attachments/photos only after safe encrypted file storage is implemented; not a hard blocker for first release.

**Pain entry:** one symptom can contain **multiple pain observations**. Each observation stores body view (`front`,`back`; left/right optional later), normalised `x`/`y` in `[0,1]`, optional normalised radius, canonical anatomical region code, laterality, pain type (`aching`, `sharp`, `burning`, `throbbing`, `tingling`, `other`), severity 0–10, and **body-map asset version**. A pain location can represent a point or an area. Optional radiation linkage/arrow and surface/deep description can be later iterations.

### Body map interaction

- Use **versioned bundled front and back vector assets**; images are not saved with each entry.
- Place markers by tapping; tap marker to edit, delete or move; optional long-press drag; pinch-zoom and pan for accuracy without changing stored normalised coordinates.
- Ensure rendered image bounds, mapping and `BoxFit` are consistent. Normalise relative to actual SVG image geometry, **not surrounding padding**; letterboxing and transforms must be accounted for.
- **Reject taps outside anatomical silhouette** using named vector paths or a reliable mask; do not place markers in the blank canvas.
- Display visual severity with colour **and** number/pattern/accessible label; do not rely solely on red/yellow.
- Show explicit front/back and left/right orientation labels (anatomical left/right, not viewer left/right).
- Provide accessible **text region picker** as alternative to precise touch mapping, including region and laterality; allow later refinement of location.
- Store independent marker records; when rendering historical entries use **same versioned body asset** or an explicit coordinate migration. Preserve legacy assets.
- PDF re-renders the relevant body asset plus markers, radius/labels and legend. For dense markers use numbered callouts and a corresponding table.

## 5. Measurements and optional health integration

Manual entries: weight, blood pressure (systolic/diastolic), heart rate, body temperature, blood glucose, and optionally sleep duration. Store canonical values and explicit units/source (`manual`, `apple_health`, `health_connect`) and source IDs if imported. Display metric/imperial conversion without rewriting canonical persisted values. Do not assume that every metric has a simple metric/imperial display pair; blood pressure is mmHg, glucose may use mmol/L or mg/dL as independent preference.

**Future/optional**: Apple HealthKit and Android Health Connect read-only import of approved measurements; explicit consent, provenance, duplication protection, opt-out. **Do not promise Apple Health Medications read/write access.** Medication records are owned by this app. Feature must be absent from demo or marked simulation.

## 6. Timeline and trends

One chronologically ordered view of medication administration, planned/changed schedules, symptom onset/changes, pain observations, measurements and freeform events. Search, filtering by date/type, severity trends, medication history, pain map per date or date range. Show time sequences only: **do not assert causality or clinical interpretations**. Support user corrections and indicate imported-vs-reported origins.

## 7. Doctor reports and exports

Report builder: 7/30/90 days, all-time, custom range; selectable sections: optional profile identifiers, active/previous medications with dose and directions, actual administration history and statuses, symptoms/severity, front/back body maps, health measurements, timeline, user notes/questions, date generated, time zone, provenance, data limitations. Include clear legend, accessible contrast and readable tables with pagination. Generate locally, preview and share/save via OS document/share sheet. PDF; CSV for structured selected datasets; optional JSON data export distinct from encrypted recovery backup. PDFs/CSV are **unencrypted by default** unless the user explicitly elects protection; show a privacy warning and avoid leaving unprotected temporary files.

## 8. Settings

- Units: independent choices for weight (kg/lb), temperature (°C/°F), and glucose (mmol/L or mg/dL). Blood pressure remains in mmHg.
- Appearance: system/light/dark.
- Clock/date: device locale, optional 12/24-hour.
- Medication reminders globally and per schedule; snooze preference; hide sensitive notification content.
- Security: change app PIN, enable/disable PIN (with reauthentication), biometrics where available (Face ID/Touch ID/Android biometric), lock on background, inactivity auto-lock, fallback behaviour.
- Backup: create encrypted backup, restore, change **future** backup password, confirm/re-encrypt selected old backups only if user explicitly chooses, backup-history view if files are accessible; optional local backup reminders.
- Export records, verify backup, privacy/help/about, erase device data with strong confirmation.
- Accessibility text size delegated to OS, large targets, semantics, reduced motion/high contrast where feasible.
- No ads, no purchase settings, no accounts, no profile management.

## 9. Demo-only PWA requirements

Prominent banner: `DEMO — All records are fictional. Changes reset when you reload. Do not enter real health information.` Fixed realistic fictional medications, administration events, symptoms, pain markers, measures and sample reports. Users can add/edit/remove data **in current in-memory runtime**. Every new page load, refresh, new browser tab and reload restores bundled seed dataset. No IndexedDB/localStorage/sessionStorage persistence for personal or demo health records. May use memory-based repositories, seeded at boot. No biometric/passcode authentication, production notifications, native health imports, encryption/restore access or disk persistence in demo; illustrate workflows with explanatory simulations where useful and **clearly label simulations**. Demo report may generate fictional-data-only PDF. **Do not build public production web mode.**

## 10. Product guardrails

User-entered content can be sensitive and may be incorrect. UI copy must not make diagnostic claims. Medication reminder failures and notifications limitations explained. Display general informational notice (not medical advice), plus urgent care language where appropriate without triage automation. App works without internet after installation. No registration, no analytics/telemetry SDK, no crash telemetry containing health data. No marketing pixels on the PWA demo.
