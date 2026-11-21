#!/usr/bin/env bash
set -Eeuo pipefail

# Run from any directory within the repository.
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

if [[ ! -f pubspec.yaml ]]; then
  echo 'ERROR: pubspec.yaml not found at repository root.' >&2
  exit 1
fi

for tool in flutter python3 git; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: $tool is not installed." >&2; exit 1; }
done

# Prevent accidental commits containing unrelated changes or build artifacts.
if [[ -n "$(git status --porcelain)" ]]; then
  echo 'ERROR: Git working tree must be clean before running this script.' >&2
  exit 1
fi

branch="$(git branch --show-current)"
if [[ "$branch" != main ]]; then
  echo "ERROR: Run this after merging into main (current branch: ${branch:-detached})." >&2
  exit 1
fi

echo '==> Installing dependencies'
flutter pub get

echo '==> Checking formatting'
dart format --output=none --set-exit-if-changed .

echo '==> Static analysis'
flutter analyze

echo '==> Unit and widget tests'
flutter test

echo '==> Android APK build'
flutter build apk --release

echo '==> Web build'
flutter build web --release

echo '==> Incrementing pubspec.yaml build number'
python3 - <<'PY'
from pathlib import Path
import re

path = Path('pubspec.yaml')
text = path.read_text(encoding='utf-8')
pattern = re.compile(r'^(version:\s*)(\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?)(\+)(\d+)(\s*(?:#.*)?)$', re.MULTILINE)
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise SystemExit('ERROR: Expected one version: x.y.z+build entry in pubspec.yaml')
match = matches[0]
old = int(match.group(4))
new = old + 1
updated = text[:match.start()] + f'{match.group(1)}{match.group(2)}+{new}{match.group(5)}' + text[match.end():]
path.write_text(updated, encoding='utf-8')
print(f'Version: {match.group(2)}+{old} -> {match.group(2)}+{new}')
PY

# Commit only pubspec.yaml. Never push without an explicit user action.
git add -- pubspec.yaml
git commit -m "chore: increment Flutter build number [skip ci]"
echo 'Done. Version bumped and committed locally. Push using: git push origin main'
