#!/bin/bash
# Run native UI tests and reject missing, corrupt, zero-test, or partial results.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/../.." && pwd -P)
stamp=$(date -u '+%Y%m%dT%H%M%SZ')
result="$repo/native/DerivedData/UITests-$stamp-$$.xcresult"
expected=$(rg --no-filename '^[[:space:]]+func test' "$repo/native/UITests"/*.swift | wc -l | tr -d ' ')
lock="$repo/native/.build/ui-test.lock"
runner="$repo/native/DerivedData/Build/Products/Debug/JackinDesktopUITests-Runner.app/Contents/MacOS/JackinDesktopUITests-Runner"
app_pattern="^$repo/native/(dist|DerivedData)/.*JackinDesktop.app/Contents/MacOS/JackinDesktop( |$)"
child_pid=""

terminate_repo_apps() {
  while IFS= read -r app_pid; do
    kill -TERM "$app_pid" 2>/dev/null || true
  done < <(pgrep -f "$app_pattern" || true)
  i=0
  while pgrep -f "$app_pattern" >/dev/null 2>&1 && [[ "$i" -lt 20 ]]; do
    sleep 0.25
    i=$((i + 1))
  done
  while IFS= read -r app_pid; do
    kill -KILL "$app_pid" 2>/dev/null || true
  done < <(pgrep -f "$app_pattern" || true)
  ! pgrep -f "$app_pattern" >/dev/null 2>&1
}

mkdir -p "$(dirname "$lock")"
if ! mkdir "$lock"; then
  echo "Another jackin❯ desktop UI test run owns $lock" >&2
  exit 1
fi

cleanup() {
  status=$?
  trap - EXIT INT TERM HUP
  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  while IFS= read -r runner_pid; do
    kill -TERM "$runner_pid" 2>/dev/null || true
  done < <(pgrep -f "^${runner}$" || true)
  terminate_repo_apps || status=1
  rmdir "$lock" 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT INT TERM HUP

test "$expected" -gt 0
terminate_repo_apps
xcodebuild test \
  -quiet \
  -project "$repo/native/JackinDesktop.xcodeproj" \
  -scheme JackinDesktop \
  -destination 'platform=macOS' \
  -parallel-testing-enabled NO \
  -only-testing:JackinDesktopUITests \
  -derivedDataPath "$repo/native/DerivedData" \
  -resultBundlePath "$result" &
child_pid=$!
wait "$child_pid"
child_pid=""

test -f "$result/Info.plist" || {
  echo "UI test result bundle is missing or corrupt: $result" >&2
  exit 1
}

summary=$(xcrun xcresulttool get test-results summary --path "$result")
total=$(printf '%s' "$summary" | plutil -extract totalTestCount raw -)
failed=$(printf '%s' "$summary" | plutil -extract failedTests raw -)
passed=$(printf '%s' "$summary" | plutil -extract passedTests raw -)

test "$total" -eq "$expected" || {
  echo "UI test count mismatch: expected $expected, executed $total" >&2
  exit 1
}
test "$failed" -eq 0 || {
  echo "UI test failures: $failed" >&2
  exit 1
}
test "$passed" -eq "$expected" || {
  echo "UI tests did not all pass: expected $expected, passed $passed" >&2
  exit 1
}

echo "UI tests: $passed/$expected passed"
echo "Result: $result"
