# ADR 0011 — Android reminders and document output

Android production uses its existing OS APIs for these two features. The
fictional review and web builds do not register their platform services.

A reminder opt-in belongs to a regimen revision and stays in the encrypted
journal. Android notification permission is requested from Reminders settings
after an explicit action. The shared planner uses the same DST rules as Today,
excludes past, archived, PRN and recorded slots and limits the queue to seven
days or 64 entries. Multiple regimens due at the same instant use one generic
notification. Delivery exposes no medication name, uses secret lock-screen
visibility and opens the app without recording any outcome.

Android uses [inexact allow-while-idle alarms](https://developer.android.com/develop/background-work/services/alarms).
The OS may delay or drop delivery. A clock/timezone broadcast cancels stale
alarms. Launch, resume and record changes rebuild the current queue. The user
has to reopen the journal after a reboot or a clock change while the app is
closed. Automatic background regeneration and physical timezone/reboot
acceptance remain open.

The CSV includes canonical units, UTC timestamps, supplied original dose
timezone/offset, record types, revision links and versioned marker coordinates.
It escapes CSV delimiters and prefixes formula-like text with an apostrophe.
Export displays a plaintext warning and uses
[Android's Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files)
to create a user-selected document. The app streams data to that destination
without a plaintext temporary file. A configured journal PIN still locks
the app when the system document picker takes the foreground.
