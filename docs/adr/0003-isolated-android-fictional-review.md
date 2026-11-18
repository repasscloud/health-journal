# ADR 0003 — Isolated Android fictional review

Date: 2026-11-18. Status: accepted; production security gate unchanged.

## Decision

Add Android `production` and `review` flavors. Production retains the original
application ID and always uses the native-pending gate from `lib/main.dart`.
Review has application ID `com.example.healthjournal.health_journal.fictionalreview`
and launcher name `HJ FICTIONAL REVIEW`. Build explicitly with:

```sh
flutter build apk --release --flavor review -t lib/main_review.dart
```

The review entry point checks Android plus Flutter's compiled `appFlavor == review`.
A mismatched native flavor fails closed; web remains a volatile demo even if this
entry point is selected. There is no production gate bypass/configuration flag.
Selecting main.dart in the review package still shows the gate, not real records.

Review composes the shared UI/domain with a fresh DemoRepository using deterministic
invented records dated November 2026. It never opens native records, installation
keys, backups, notifications or app lock. Android review skips native plugin
registration and the protected-store channel. Packaged native libraries are not
proof of persistence or encryption, and no security claim is made for this target.
Visible notices explain fictional data and reset on process restart (backgrounding
alone may retain the process). Native UI navigation into forms retains that notice.
The standard web fixture remains small for existing acceptance flows; the review
fixture adds fixed/course/PRN examples, explicit history/correction, front/back pain,
measurements and catalogue history. Both use the same models and memory adapter.

No app data clear/uninstall is needed or authorised. Install without `-r` so a
conflicting package is refused. A force-stop/relaunch resets review memory only.
No iOS project/signing changes, database migration or dependency changes are made.
Android production builds/probes now require `--flavor production`; iOS does not.
Debug signing remains the pre-existing local Android release signing configuration.
This is an installable review build, not a Play Store release.

## Related correctness decisions

Strict local calendar dates reject normalised dates. Completed courses are allowed
when exclusive end exceeds their effective start; revisions use their captured
current revision instant. Differing per-time weekday rules are explicitly rejected
by the shared-weekday revision UI before opening it; the original rules remain
unchanged. Full per-time weekday editing is deferred.

Repository administration writes (including corrections) must lie inside the
current effective range of their referenced regimen. Validation runs before any
mutation; correction snapshots remain the original snapshots, even when a revision
has since shortened the effective range. Schedule timeline names snapshot the
catalogue at regimen creation/revision, rather than resolving today's catalogue.
Catalogue history is available from each medication; record buttons show effective
ranges to distinguish historical regimens.

Administration constructors still permit optional snapshots and this memory adapter
uses object identity for catalogue correction preservation. These are not a native
serialization contract. Before native persistence is wired, require versioned stable
value snapshots and serialization round-trip/correction tests. Original timezone,
occurrence generation and native record migrations/recovery remain unfinished.

## Verification

Unit/widget coverage includes strict dates, completed-course form retry preserving
inputs, mixed-weekday revision rejection, atomic invalid direct/correction writes,
fresh immutable rich fixtures, retained schedule names, review notices on nested
forms at 200% text, the production gate and source/build composition checks.
Session-specific final build/browser/device results are recorded in
IMPLEMENTATION_STATUS.md; prior security probe evidence remains prior evidence.

## Android identity update

The review and production flavors now use the Android application ID
`com.repasscloud.healthjournal` and launcher label **Health Journal**.
This supersedes the original review suffix. The flavors cannot coexist on
one Android user profile. The review deployment script installs into a free
package ID or updates an installation whose review-only activity alias
Android can resolve. It refuses to replace a production installation.
The review startup and native plugin-registration guards still use the
compiled flavor.
