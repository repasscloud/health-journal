# Android journal and backup compatibility

The live journal schema and portable archive versions are independent. The
current journal is SQLite schema 4. The released portable format is V1 with
authenticated JSON payload schema 4. Earlier *SQLite* schemas were never
portable payload formats.

| Input | Current reader | Evidence |
|---|---|---|
| Fresh Android installation | Create encrypted schema 4 and one profile when started. | Host bootstrap tests and isolated Android production startup. |
| Encrypted journal v1 | Migrate to v4 with independently encrypted recovery snapshot. Keep legacy events and links. | Exported v1 fixture, host failure/retry and keyed reopen. Physical Android release migration recorded in implementation status. |
| Encrypted journal v2 | Migrate to v4 and retain a keyed v2 snapshot. | Host fixtures with DELETE and WAL, process kill before commit, independent WAL snapshot, interrupted staging and failed snapshot write. Disk-full run also passed. |
| Encrypted journal v3 | Migrate to v4 before accepting current measurement writes. | Host exported v3 fixture in `migration_lifecycle_test.dart`. |
| Encrypted journal v4 | Reopen under the same installation key. | Host restart and Android production release restart. |
| Unrecognized live journal version | Refuse upgrade and preserve bytes. | Host unsupported-version fixture. |
| V1 container, v4 JSON | Validate authenticated logical contents and restore into v4. | Independent cipher vector, host cross-key and two-password tests, physical Android round trip. |
| V1 container with payload schema 1, 2, 3 or 5 | Reject even with valid authentication. | Host authenticated mutation cases. |
| V1 container with an unexpected credentials table | Reject before replacement. | Host authenticated allowlist case. |
| Damaged container or incorrect password | Reject malformed bounds/authentication and preserve active journal. | Host framing, password, tamper and rollback tests. |
| Another container version | Reject unknown header version before the KDF. | Host byte mutation case. |

The focused host migration/backup run enabled
`HJ_TEST_DISK_EXHAUSTION=1` on macOS 27.2.1 / Flutter 3.47.9 and passed
29 tests against `424c426`. The subsequent compatibility tests include
unsupported authenticated payload schemas and two separately created
archives. Android OEM transfer, physical iOS and Android↔iOS portable
archive interoperability remain unverified in this run.
