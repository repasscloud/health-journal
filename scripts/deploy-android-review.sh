#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

for tool in adb flutter; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required tool missing from PATH: %s\n' "$tool" >&2
    exit 1
  fi
done

# ADB's USB selector excludes emulators and network-connected devices.
# Resolve the serial up front so a device change during the build cannot retarget it.
if ! serial=$(adb -d get-serialno) ||
   [[ -z "$serial" || "$serial" == unknown ]] ||
   [[ "$(adb -s "$serial" get-state)" != device ]]; then
  printf 'Connect one Android phone by USB and approve USB debugging on the phone.\n' >&2
  adb devices -l >&2
  exit 1
fi

package=com.repasscloud.healthjournal
apk=build/app/outputs/flutter-apk/app-review-release.apk
printf 'Building Health Journal for %s\n' "$serial"
flutter build apk --release --flavor review -t lib/main_review.dart

# The flavors share an Android package ID. Never replace an installed build
# unless the package manager confirms its review-only component.
if adb -s "$serial" shell pm path "$package" >/dev/null; then
  if ! adb -s "$serial" shell cmd package resolve-activity --brief -n "$package/.ReviewEntry" |
       tr -d '\r' | grep -Fxq "$package/.ReviewEntry"; then
    printf 'Refusing to replace %s because the installed app is not a review build.\n' "$package" >&2
    exit 1
  fi
  adb -s "$serial" install -r "$apk"
else
  adb -s "$serial" install "$apk"
fi
adb -s "$serial" shell am start -S -W -n "$package/.ReviewEntry"
