# ADR 0010 — Portable backup container v1

A portable backup opens with its file and password alone. The container core
uses Argon2id for derivation and AES-256-GCM for authenticated encryption.
Every written archive has a random 16-byte salt and 12-byte nonce. The
entire 52-byte header is associated data. Multi-byte values are big endian.

| Bytes | Meaning |
|---|---|
| 0–7 | Magic `48 4a 42 41 4b 0d 0a 1a` |
| 8–9 | Header length, 52 |
| 10 | Container version, 1 |
| 11 | KDF ID, 1 for Argon2id v19 |
| 12 | Cipher ID, 1 for AES-256-GCM |
| 13 | Argon2id parallelism |
| 14–15 | Argon2id iterations |
| 16–19 | Argon2id memory in KiB |
| 20–35 | Salt |
| 36–47 | GCM nonce |
| 48–51 | Ciphertext length, excluding tag |
| 52 onward | Ciphertext followed by the 16-byte GCM tag |

The decoder rejects oversized and inconsistent lengths before deriving a key.
Version 1 accepts 32–64 MiB, 3–5 iterations and 1–2 lanes with the required
Argon2 memory alignment. The current encoder uses 32 MiB, 3 iterations and
one lane. The release probe measured this setting on a Galaxy A14 5G.
Broader benchmarks remain open. The 32 MiB payload limit bounds in-memory decoding. The local export
and import layers must enforce the same limit before reading files.

The container treats cleartext as an opaque byte sequence. The journal
payload is UTF-8 JSON with schema 4, a UTC creation time and an allowlist of
tables. Rows contain the corresponding schema columns in declaration order.
Inspect applies the rows to an isolated in-memory database with constraints,
foreign keys and domain decoding. An opt-in replacement writes all rows
within one SQLite transaction. Other payload versions require a versioned
compatibility reader. Key derivation and AEAD run off the UI isolate.
The codec does not read or write files or include an installation secret.
An independent Python Argon2id/AES-GCM vector tests interoperability. The Android probe validates the backend. OS document picker, production
preview/confirmation controls and cross-platform transfer remain open.
