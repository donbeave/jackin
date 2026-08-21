#!/bin/sh

set -u

verdict() {
  printf '%s\n' "TAILROCKS GOAL: $1"
  case "$1" in
    PASS\ *) exit 0 ;;
    *) exit 1 ;;
  esac
}

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) ||
  verdict "BLOCKED malformed=script-path"
slug=${1:-$(basename -- "$script_dir")}
package="plans/$slug"
hub="$package/README.md"
goal="$package/GOAL.md"

[ -f "$hub" ] || verdict "BLOCKED malformed=missing-readme"
[ -f "$goal" ] || verdict "BLOCKED malformed=missing-goal"

[ -z "$(git status --porcelain 2>/dev/null)" ] ||
  verdict "BLOCKED dirty-tree"

expected_fingerprint=$(sed -n \
  's/^Frozen package fingerprint: `\([^`]*\)`.*/\1/p' "$hub" | sed -n '1p')
case "$expected_fingerprint" in
  ''|*[!0-9a-f]*) verdict "BLOCKED malformed=fingerprint" ;;
esac

frozen_files=$(find "$package" -type f ! -path "$hub" -print 2>/dev/null |
  LC_ALL=C sort)
[ -n "$frozen_files" ] || verdict "BLOCKED malformed=frozen-files"
actual_fingerprint=$(
  printf '%s\n' "$frozen_files" |
    while IFS= read -r file; do
      printf '%s %s\n' "$(git hash-object -- "$file")" "$file"
    done |
    git hash-object --stdin
) || verdict "BLOCKED malformed=fingerprint"
[ "$actual_fingerprint" = "$expected_fingerprint" ] ||
  verdict "BLOCKED plan-drift"

status_counts=$(awk -F '|' '
  /^\|/ {
    status = $(NF - 1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", status)
    if (status == "DONE") done++
    else if (status == "REJECTED" || status ~ /^REJECTED \(/) rejected++
    else if (status == "TODO" || status == "STALE" ||
             status == "IN PROGRESS" || status == "BLOCKED" ||
             status ~ /^BLOCKED \(/) nonterminal++
  }
  END { print done + 0, rejected + 0, nonterminal + 0 }
' "$hub")
set -- $status_counts
done_count=$1
terminal_count=$((done_count + $2))
nonterminal_count=$3
[ "$nonterminal_count" -eq 0 ] ||
  verdict "BLOCKED nonterminal-rows=$nonterminal_count"
[ "$done_count" -gt 0 ] || verdict "BLOCKED malformed=status-table"
[ "$terminal_count" -gt 0 ] || verdict "BLOCKED malformed=status-table"

gates=$(awk '
  /^```sh gates[[:space:]]*$/ { inside = 1; found = 1; next }
  inside && /^```[[:space:]]*$/ { inside = 0; closed = 1; exit }
  inside { print }
  END { if (!found || !closed) exit 1 }
' "$goal") || verdict "BLOCKED malformed=gates-block"
[ -n "$gates" ] || verdict "BLOCKED malformed=gates-block"

printf '%s\n' "$gates" | while IFS= read -r command; do
  [ -n "$command" ] || continue
  sh -c "$command" || {
    printf '%s\n' "TAILROCKS GOAL: BLOCKED gate-failed=$command"
    exit 1
  }
done
gate_status=$?
[ "$gate_status" -eq 0 ] || exit "$gate_status"

head_sha=$(git rev-parse --short HEAD 2>/dev/null) ||
  verdict "BLOCKED malformed=head-sha"
verdict "PASS $head_sha"
