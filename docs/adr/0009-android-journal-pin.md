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
A forgotten PIN cannot be recovered. The locked screen offers an app reset
after explicit confirmation. See [ADR 0012](0012-android-forgotten-pin-reset.md).

See [ADR 0016](0016-android-biometric-unlock.md) for biometric enrollment
and the current Android production secure-window policy. The web demo and
fictional Android review have no journal PIN implementation.

References include the [Android screenshot API](https://developer.android.com/reference/android/app/Activity#setRecentsScreenshotEnabled(boolean))
and the [OWASP Argon2id baseline](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html).
