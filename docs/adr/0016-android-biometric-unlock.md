# ADR 0016 — Android biometric journal unlock

A configured journal PIN is required before opting in or out of biometric
unlock. Android 11 and later can use a Class 3 biometric that Android
reports as enrolled and available. The app verifies the journal PIN
through the same throttled verifier used for ordinary unlock. Enabling
biometrics also requires a successful Android biometric prompt. Earlier
versions and devices without a matching biometric keep the PIN path.

The Android Keystore holds a separate per-use HMAC authentication key.
Only a successful operation using the prompt's authenticated
`CryptoObject` authorizes unlock. Android can invalidate the key after a
biometric enrollment change or removal of the device credential. An
invalidated key requires PIN fallback and a new opt-in. Cancelled,
unavailable or locked-out system authentication leaves the journal
locked and the journal PIN available. The Android screen-lock credential
does not substitute for the journal PIN. Removing the journal PIN disables
biometric unlock.

The authentication key and opt-in preference are device-local. They
never enter a portable backup or authorize decryption of a backup.
The same lock epoch and background/inactivity flow gate biometric and PIN
unlock. Android cancels an outstanding prompt when the activity stops.

Production uses a secure Android window at every supported API level.
An API 35 emulator exposed the live Overview surface with the recents-only
screenshot opt-out. The secure window blocks screenshots, screen
recording and app-switcher capture for production journal views. Reports
can still be saved or shared from Android. The demo and fictional review
have no journal biometric flow.

[Android biometric CryptoObject](https://developer.android.com/reference/android/hardware/biometrics/BiometricPrompt.CryptoObject)
[Android Keystore enrollment invalidation](https://developer.android.com/reference/android/security/keystore/KeyGenParameterSpec.Builder#setInvalidatedByBiometricEnrollment(boolean))
