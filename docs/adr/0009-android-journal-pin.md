# ADR 0009 — Android journal PIN

Android users can opt into a journal PIN with 6–12 digits. It gates the UI at
cold startup, when the activity goes into the background, and after five
minutes without pointer or hardware-key input. Locking drops the current
navigation and unsaved form state. It retains the open encrypted store while
the process stays alive. On a cold launch the UI authenticates before opening
the database.

The secure-storage adapter uses a separate entry for a salted Argon2id
verifier and retry state. A worker isolate derives the verifier. Entry after
three consecutive failures is subject to a persisted, increasing delay. The
current PIN is required to replace or remove it. PIN access control is
separate from the random database key and the planned portable backup password.
There is no forgotten-PIN recovery path.

Android 13 and newer disable recents screenshots through the activity API.
Older Android versions use the secure-window flag, which also prevents user
screenshots. This applies to production only. The web demo and fictional
Android review have no PIN implementation. Biometric enrollment and fallback
are deferred.

References include the [Android screenshot API](https://developer.android.com/reference/android/app/Activity#setRecentsScreenshotEnabled(boolean))
and the [OWASP Argon2id baseline](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
