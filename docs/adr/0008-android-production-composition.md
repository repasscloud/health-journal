# ADR 0008 — Android production composition

Android and iOS have independent storage acceptance gates. Android uses the
existing protected-directory and Keystore adapters after the physical release
probe verified the encrypted v1 to v4 upgrade, raw ciphertext, key reuse, and
screen lock and credential-change behaviour. Host process-kill and rollback
tests verify the migration recovery path. iOS remains gated until its own
required physical-device evidence is recorded.

The Android startup owns one connection. An absent profile offers explicit
Start Fresh, and an existing profile goes straight to the journal. Failures
leave records in place and offer retry. The shared form entry points await
native writes. Each write and the read snapshot it returns come from the same
serialized transaction. The app publishes the new snapshot after commit.

Older structured records keep their source facts. Legacy administration rows
whose snapshots lack a documented format appear as historical entries in the
Timeline. When their occurrence time is missing, the entry time is explicitly
identified. Legacy regimen rules are unavailable and cannot generate reminders.

The web build has no native composition import and always starts a new
fictional repository. An opt-in Android build property adds a separate test
application ID for production-path device tests using fictional records.
