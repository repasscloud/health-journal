# Autonomous development checkpoint

19 November 2026, Australia/Adelaide.

- Latest validated code is the commit carrying this checkpoint. Run
  `git log -1 --oneline` for the exact revision.
- Android foundation and the shared native record composition are active.
  Issue #2 is closed. Issue #1 has physical Android review and production evidence, with iOS deferred. Issues #3, #5 and #16–#18
  retain open acceptance criteria.
- Flutter 3.47.9, 78 Flutter tests, analyzer, web release and two Chrome
  Playwright cases passed. See [implementation status](IMPLEMENTATION_STATUS.md)
  for physical storage and production-path evidence. No iOS tests were run.
- The physical Galaxy A14 5G is `R9WW30CSG1K`. The shared app ID exists.
  Any further device verification should use `com.repasscloud.healthjournal.devicetest`
  after checking its identity. Build and logs are kept under ignored `build/`.
- Android #7 PIN enrollment, background lock, incorrect PIN and cold unlock
  passed on hardware, along with blank Overview and five-minute idle lock.
  Biometrics and older Android fallback remain open.
- Android #6 permission denial/grant, secret test notification and bounded
  system alarm scheduling passed on hardware. Automatic background regeneration,
  timed delivery verification and iOS remain open.
- Android #8 CSV save through Downloads passed with fictional data. PDF and
  iOS export remain open.
- Next active issues are #9/#10 production backup and restore controls, using
  the verified backend and Android document-provider integration. The backend
  passed host validation and a fictional Android file round trip. Production
  handoff, preview/confirmation controls and crash-device tests are pending.
  #11 deletion and #12–#15 hardening remain open. iOS runtime, signing and
  hardware acceptance remain deferred.

```sh
flutter analyze
flutter test
flutter build apk --release --flavor production
flutter build apk --release --flavor review -t lib/main_review.dart
flutter build web --release
npx --prefix tool/browser playwright test --config tool/browser/playwright.config.cjs
ORG_GRADLE_PROJECT_healthJournalDeviceTest=true flutter build apk --release --flavor production
adb -s R9WW30CSG1K shell pm path com.repasscloud.healthjournal.devicetest
ORG_GRADLE_PROJECT_healthJournalDeviceTest=true flutter build apk --release --flavor production -t tool/android_backup_probe.dart
```
