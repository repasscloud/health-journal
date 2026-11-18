#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

# Android Studio's Device Manager lists these same virtual device names.
sdk_root=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-"$HOME/Library/Android/sdk"}}
emulator="$sdk_root/emulator/emulator"
if [[ ! -x "$emulator" ]]; then
  emulator=$(command -v emulator) || {
    printf 'Android Emulator not found. Install it in Android Studio or set ANDROID_HOME.\n' >&2
    exit 1
  }
fi
models=$("$emulator" -list-avds)

usage() {
  printf 'Usage: %s <AVD name>\n' "$0"
  printf 'Start or reuse the selected emulator, then rebuild and open the Health Journal review app.\n\n'
  printf 'Available models (Android Virtual Devices):\n'
  if [[ -n "$models" ]]; then
    printf '%s\n' "$models"
  else
    printf '  None. Create a virtual device in Android Studio Device Manager.\n'
  fi
}

case "${1:-}" in
  ''|-h|--help) usage; exit 0 ;;
esac
if [[ $# != 1 ]] || ! grep -Fxq -- "$1" <<< "$models"; then
  printf 'Expected one of the listed AVD names.\n' >&2
  usage >&2
  exit 2
fi
model=$1

for tool in adb flutter; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required tool missing from PATH: %s\n' "$tool" >&2
    exit 1
  fi
done

# Match the AVD name reported by its emulator console, never a physical phone
# or whichever emulator happened to connect first.
find_emulator() {
  local devices serial reported_model
  devices=$(adb devices) || return 1
  while read -r serial _; do
    [[ "$serial" =~ ^emulator-[0-9]+$ ]] || continue
    reported_model=$(adb -s "$serial" emu avd name 2>/dev/null | tr -d '\r') || continue
    if [[ "${reported_model%%$'\n'*}" == "$model" ]]; then
      printf '%s\n' "$serial"
      return 0
    fi
  done <<< "$devices"
  return 1
}

if ! serial=$(find_emulator); then
  emulator_log=$(mktemp "${TMPDIR:-/tmp}/health-journal-emulator.XXXXXX")
  printf 'Starting %s. Emulator log: %s\n' "$model" "$emulator_log"
  nohup "$emulator" -avd "$model" </dev/null >"$emulator_log" 2>&1 &
  emulator_pid=$!
fi

# ADB can see an emulator before Android is ready to install packages.
deadline=$((SECONDS + 180))
while (( SECONDS < deadline )); do
  if [[ -n "${emulator_pid:-}" ]] && ! kill -0 "$emulator_pid" 2>/dev/null; then
    printf 'The emulator exited. See %s\n' "$emulator_log" >&2
    exit 1
  fi
  if serial=$(find_emulator) &&
     booted=$(adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') &&
     [[ "$booted" == 1 ]]; then
    # Reuse the USB script's review-only upgrade check for this ADB target.
    exec ./scripts/deploy-android-review.sh --emulator "$serial"
  fi
  sleep 2
done

printf 'Timed out waiting for %s to boot.\n' "$model" >&2
if [[ -n "${emulator_log:-}" ]]; then
  printf 'Emulator log: %s\n' "$emulator_log" >&2
fi
exit 1
