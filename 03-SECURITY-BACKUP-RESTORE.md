# 03 — Security, Encryption, Backup and Restore

## 1. Threat model

Protect against casual device access, stolen backup files, accidental data loss and inadvertent sharing. A mobile OS compromise/rooted device is outside full protection scope; document limitations. Medical information remains local unless user **explicitly** exports/shares it. No developer-managed server, tracking, remote backup or account.

## 2. Database at rest

Production native local database MUST use authenticated/proven encrypted SQLite (e.g., correctly configured SQLite3MultipleCiphers or compatible maintained SQLCipher solution) with a **random per-installation database key**. Keep that key protected by iOS Keychain / Android Keystore-backed key-wrapping/storage. Set appropriate file protection; guard temporary/sidecar/WAL/export files. Verify raw database cannot be opened without key; verify changing device unlock does not corrupt access. Keychain/Keystore key is for **local installation only**, never a dependency of cross-device recovery. Avoid claiming encryption if only app PIN gate implemented.

## 3. PIN and biometrics

App PIN is optional configurable UI lock, distinct from backup password. Never store PIN in plaintext; use slow salted verification and throttling/backoff, avoid permanent irreversible lockout without documented recovery route. Biometrics only if device supports them and has enrollment; require successful device auth before showing records, allow supported fallback path, recheck after biometric enrollment changes. Native `local_auth` is **not a web biometric solution**. Lock on app background and configurable inactivity interval. Avoid leaking sensitive screen content in OS task switcher previews where possible. On new-device restore, configure PIN/biometrics anew.

## 4. Portable encrypted backup — v1

Container `*.healthbak` with:

```text
Magic + header length
Unencrypted header:
  format_version = 1
  kdf = argon2id
  random_salt = 16-32 bytes (new each backup)
  kdf_parameters = tested memory/time/parallelism
  cipher = AES-256-GCM
  unique_nonce = 12 bytes
  encrypted_payload_length
Authenticated encrypted payload:
  manifest (schema/app version, created UTC, counts, body asset revisions)
  consistent database snapshot / domain export
  attachments if supported
  integrity/consistency metadata
GCM authentication tag (e.g. appended to ciphertext)
```

All unencrypted header bytes necessary to interpret the ciphertext must be **authenticated as AES-GCM associated data (AAD)** so attackers cannot tamper with metadata undetected. Header salt and nonce are intentionally not secret. Use CSPRNG for salt and nonce. Derive a **separate backup key from the user password and header salt via Argon2id**; never use or embed a globally shared app secret. The **same password, salt and KDF parameters** reconstruct the key on a different device. Each backup uses a new salt and nonce. Test tampering, wrong password, truncated files, unsupported versions, malicious oversized archives, zip/path traversal if archive container uses ZIP, low-memory KDF behaviour and format upgrades. Use a tested crypto implementation; zero sensitive buffers where practical.

KDF benchmark: tune Argon2id parameters for supported mobile devices (memory use, response time, resistance to offline attack); store actual parameter values in each file. Do not hardcode 'secure' tuning without profiling.

## 5. Password changes

Changing the stored **default password for future backups** only changes future generated files. **Existing backups remain under their original password.** If user wants older copies changed, choose files and perform decrypt → re-encrypt with new random salt/nonce → verify → save new encrypted file; never overwrite the only backup until new copy verified. Make distinction explicit in UX. No silent claim that past backups were updated. Optional recovery key only in future design; if no recovery feature, forgotten backup password means that file cannot be restored.

## 6. Backup export

1. User starts backup and provides/sets backup password, with confirmation on first setup and meaningful strength guidance.
2. Snapshot consistent transactional DB and protected attachments in an isolated temporary workspace; no plaintext outside protected sandbox.
3. Produce encrypted container, authenticated header + payload, validate by decrypting to ephemeral staging/at minimum authenticated verification and manifest checks.
4. Share/save through OS file picker/document provider: iCloud Drive on iOS, user-chosen Documents/Google Drive/other compatible provider on Android. The app **does not manage an iCloud account** or require provider API credentials.
5. Report explicit success **only after destination handoff succeeds**; where document APIs cannot guarantee durable cloud upload, word status as 'exported to selected location' rather than 'uploaded'.
6. Prompt periodic user-initiated backup reminders; never claim guaranteed automatic uploads. Optionally retain app-private versioned backups if documented. Do not include PIN, biometrics, Keychain/Keystore secrets or live device credentials in portable file.

## 7. Restore workflow

```text
Select *.healthbak
  → parse bounded header / validate format
  → password → Argon2id → AES-GCM authenticated decrypt
  → verify manifest, schema, file structure, semantic integrity, FK constraints
  → stage into new encrypted local DB with new device-local DB key
  → show date/version/counts and request explicit replace confirmation if populated
  → close current connections, coordinate WAL/files, safely commit staged DB
  → verify committed DB, then release original snapshot only after recovery point
  → refresh repository/state, configure PIN/biometrics anew, reschedule reminders
```

**Atomicity:** file rename alone is not enough if DB has WAL/SHM files or multiple files. Design transaction/snapshot/safe commit sequence with crash-consistent rollback; test simulated crashes before/during/after swap. Never clear existing data before staging passes verification. On failure existing profile and credentials remain untouched. After restore, there is still exactly **one profile**. **No merge** in v1. Backup preview and confirmation must precede destruction.

## 8. Data lifecycle / deletion

Explicit `Delete all local data`: require reauthentication/destructive confirmation; wipe DB, attachments, local key, app-created temporaries and queued reminders as best possible. Explain exported PDFs/CSV and external backups remain under user's control and are not automatically removed. Device OS backups: document policies and consider excluding live encrypted DB from platform auto-backups if restoration would be unrecoverable without original keystore key; test Android Auto Backup and iOS file backup behaviour. Handle uninstalled app files per OS and user-provided backup location.

## 9. Privacy assurances

No PHI in crash logs/analytics, clipboard by default, URLs, notification previews unless opted in, network requests, or demo fixtures. Ensure exception messages avoid user medical contents. Production core works offline. Use platform permissions just in time and explain denial gracefully. PDF/CSV share warning because exported files can be readable by recipients/providers. Publish accurate privacy policy/app-store privacy disclosures and review Australian Privacy Act implications even without servers.
