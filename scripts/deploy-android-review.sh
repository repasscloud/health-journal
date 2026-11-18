#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

for tool in adb flutter; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required tool missing from PATH: %s\n' "$tool" >&2
    exit 1
  fi
done

# Resolve the target once so a connection change cannot retarget deployment.
if [[ "${1:-}" == --emulator && $# == 2 && "$2" =~ ^emulator-[0-9]+$ ]]; then
  serial=$2
elif [[ $# == 0 ]]; then
  # ADB's USB selector excludes emulators and wireless devices.
  serial=$(adb -d get-serialno) || serial=
else
  printf 'Usage: %s [--emulator emulator-SERIAL]\n' "$0" >&2
  exit 2
fi

if [[ -z "$serial" || "$serial" == unknown ]] ||
   [[ "$(adb -s "$serial" get-state)" != device ]]; then
  printf 'Connect one authorised USB phone or select a running emulator.\n' >&2
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
