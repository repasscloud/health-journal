# ADR 0015 — Replay bounded Android reminders after reboot

Android discards alarms at shutdown. Production listens for
`BOOT_COMPLETED` after the Android user unlocks the device. It can replay
unexpired future wake-ups in the same time zone without opening the journal
or asking for the journal PIN. It checks the current notification permission
and channel state before scheduling and again before posting.

The journal computes a seven-day window with at most 64 unique instants.
Simultaneous entries share a generic notification. Android stores only the
bounded instants and the time zone ID in its app-private no-backup directory.
An independent Android Keystore AES-GCM key encrypts and authenticates that
cache. The boot receiver discards an absent, invalid, expired or wrong-zone
plan. The cache contains no names, amounts, dose outcomes or portable
backup data. Android package-data erasure removes the cache and key.

Clock and time-zone broadcasts clear pending alarms and notices before the
attached Flutter engine recomputes from the loaded journal. If the engine
has no journal available, the next journal open or unlock recomputes.
The civil planner calculates actual instants on each day, including DST
gaps and folds. Permission revocation prevents delivery and clears the
queue on the next permission check, refresh or attempted delivery.

Alarms are inexact and can be delayed or suppressed by Android. Force-stop
and some battery settings can suppress boot handling. A reboot never
creates new days beyond the cached horizon. An abrupt process exit
between a journal write and the alarm refresh can leave a bounded old
queue until the next open. A notification opens the journal. A separate
explicit dose confirmation is required to create any outcome.

[Android alarm scheduling](https://developer.android.com/develop/background-work/services/alarms)
