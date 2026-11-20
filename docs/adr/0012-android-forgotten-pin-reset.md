# ADR 0012 — Android forgotten PIN reset

Use Android's [app data reset API](https://developer.android.com/reference/android/app/ActivityManager#clearApplicationUserData()) after the user types `ERASE` and confirms on the locked journal screen. This offers the same destructive recovery available in Android Settings to someone who cannot authenticate with the journal PIN. The action grants no access to encrypted records.

Android owns removal of app-private data, including the database and migration snapshots, the installation key and PIN storage, app settings, and reminders. The system closes the app. Reopening runs normal first-launch setup, where the user can start fresh or restore an exported backup with its backup password. Exported documents live in their selected destination outside app-private storage.

The reset channel is available only on the Android production build. If the platform rejects the request, the app keeps the journal locked and displays an error.

## Settings erasure

Settings → Privacy & security also offers erasure. The existing verifier
reauthenticates the configured PIN using the same persisted throttling as
ordinary unlock. The confirmation explains what happens to the local
journal, settings, reminders and exported files. Both paths delegate
the package-level reset to Android. Files held by external document
providers or recipients stay under their control.
