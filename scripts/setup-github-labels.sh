
#!/usr/bin/env bash
set -euo pipefail

REPO="repasscloud/health-journal"

# Format: name|colour|description
LABELS=(
  "bug|D73A4A|Defects causing incorrect or unexpected behaviour"
  "enhancement|A2EEEF|Improvements to existing functionality"
  "ui/ux|7057FF|Layout, navigation and user experience"
  "accessibility|5319E7|Accessible interaction, readability and assistive technology"
  "platform/android|3DDC84|Android-specific functionality and compatibility"
  "platform/ios|007AFF|iOS-specific functionality and compatibility"
  "platform/web-demo|1D76DB|Fictional web/PWA demonstration"
  "feature/medications|F9D0C4|Medication catalogue, schedules and intake recording"
  "feature/symptoms|FBCA04|Symptom recording, severity and body mapping"
  "feature/data|C2E0C6|Persistence, backups, restoration and exports"
  "security/privacy|B60205|Encryption, data protection and privacy"
  "testing|BFDADC|Testing, validation and regression coverage"
  "priority/high|D93F0B|Significant functional impairment requiring prompt resolution"
  "priority/medium|FBCA04|Important but noncritical work"
  "priority/low|0E8A16|Minor improvements and low-impact defects"
)

# Check dependencies and authentication.
command -v gh >/dev/null || {
  echo "GitHub CLI (gh) is not installed."
  exit 1
}

command -v jq >/dev/null || {
  echo "jq is not installed."
  exit 1
}

gh auth status >/dev/null || exit 1

echo "Updating labels for $REPO..."
echo

# Create or update all approved labels.
for entry in "${LABELS[@]}"; do
  IFS='|' read -r name colour description <<< "$entry"

  gh label create "$name" \
    --repo "$REPO" \
    --color "$colour" \
    --description "$description" \
    --force

  echo "Updated: $name (#$colour)"
done

echo
echo "Checking for obsolete labels..."

# Fetch all labels, including pagination.
existing=$(
  gh api --paginate \
    "repos/$REPO/labels?per_page=100" \
    --jq '.[].name'
)

# Delete any label not in the approved list.
while IFS= read -r name; do
  [[ -z "$name" ]] && continue

  keep=false

  for entry in "${LABELS[@]}"; do
    IFS='|' read -r approved_name _ <<< "$entry"

    if [[ "$name" == "$approved_name" ]]; then
      keep=true
      break
    fi
  done

  if [[ "$keep" == false ]]; then
    echo "Deleting obsolete label: $name"

    # GitHub API safely encodes label names as path segments.
    encoded_name=$(
      jq -nr --arg value "$name" '$value | @uri'
    )

    gh api --method DELETE \
      "repos/$REPO/labels/$encoded_name" \
      --silent
  fi
done <<< "$existing"

echo
echo "Final repository labels:"
gh label list --repo "$REPO" --limit 100

echo
echo "Label cleanup completed."
