
#!/usr/bin/env bash
set -euo pipefail

REPO="repasscloud/health-journal"

titles=(
  "0 — Foundation and encrypted storage"
  "1 — Records, body maps and Timeline"
  "2 — Reminders and local access protection"
  "3 — Reports and portable backup/restore"
  "4 — Release hardening"
)

descriptions=(
  "Initialize and safely reopen one encrypted native mobile profile. Verify migration, recovery, encryption and file protection."
  "Complete offline record entry, editing, history, body maps and Timeline. Resolve symptom form UI defects and verify persistence."
  "Implement opt-in notifications, PIN and biometric protection, privacy controls and lifecycle locking."
  "Deliver PDF/CSV exports, password-encrypted portable backups and reliable cross-device restoration."
  "Complete accessibility, platform compatibility, security validation, signing, store preparation and acceptance testing."
)

milestone_number=""

for i in "${!titles[@]}"; do
  title="${titles[$i]}"

  number=$(
    gh api --paginate "repos/$REPO/milestones?state=all&per_page=100" \
      --jq ".[] | select(.title == \"$title\") | .number" |
      head -n 1
  )

  if [[ -z "$number" ]]; then
    number=$(
      gh api --method POST "repos/$REPO/milestones" \
        -f title="$title" \
        -f description="${descriptions[$i]}" \
        --jq '.number'
    )
    echo "Created milestone: $title"
  else
    echo "Existing milestone: $title"
  fi

  if [[ "$i" -eq 1 ]]; then
    milestone_number="$number"
  fi
done

for issue in 1 2; do
  gh api --method PATCH "repos/$REPO/issues/$issue" \
    -F milestone="$milestone_number" \
    --silent
  echo "Assigned issue #$issue to milestone 1"
done
