#!/bin/bash
# Regenerate the branch-head A1 native evidence matrix from one validated app bundle.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd -P)
repo=$(cd "$here/../../.." && pwd -P)
app=${1:-"$repo/native/dist/JackinDesktop.app"}
output="$repo/plans/native-liquid-glass/evidence/final"
window_tool="$repo/native/.build/final-window-id"
notification_tool="$repo/native/.build/final-notification-drive"
focus_tool="$repo/native/.build/final-focus-drive"
capture="$here/capture.sh"
owner="jackin❯ desktop"
inactive_app=${CAPTURE_INACTIVE_APP:-$(osascript -e \
  'tell application "System Events" to get name of first application process whose frontmost is true')}
unset CAPTURE_INACTIVE_APP
test -n "$inactive_app" && test "$inactive_app" != JackinDesktop || {
  echo "front a non-jackin❯ application before capturing inactive states" >&2
  exit 2
}

source_paths=(
  Cargo.lock
  Cargo.toml
  crates/jackin-usage
  crates/jackin-usage-ffi
  crates/jackin-xtask
  mise.toml
  native/Generated
  native/Package.swift
  native/Scripts
  native/Sources
  native/Support
  native/Tests
  native/Tools
  native/UITests
  native/project.yml
  rust-toolchain.toml
)
require_clean_sources() {
  source_status=$(git -C "$repo" status --porcelain -- "${source_paths[@]}")
  test -z "$source_status" || {
    echo "refusing to label captures as branch-head evidence with dirty desktop sources:" >&2
    printf '%s\n' "$source_status" >&2
    exit 2
  }
}
require_clean_sources

canonical_app="$repo/native/dist/JackinDesktop.app"
test "$app" = "$canonical_app" || {
  echo "final evidence requires the canonical branch-head app: $canonical_app" >&2
  exit 2
}
mise -C "$repo" run desktop-build
mise -C "$repo" run desktop-verify
require_clean_sources
test -d "$app" || {
  echo "app bundle not found: $app" >&2
  exit 2
}
mkdir -p "$repo/native/.build" "$output"
swiftc -O "$here/window-id.swift" -o "$window_tool"
swiftc -O "$here/notification-drive.swift" -o "$notification_tool"
swiftc -O "$here/focus-drive.swift" -o "$focus_tool"

cleanup() {
  status=$?
  trap - EXIT INT TERM HUP
  while IFS= read -r app_pid; do
    kill -TERM "$app_pid" 2>/dev/null || true
  done < <(pgrep -f "^$app/Contents/MacOS/" || true)
  exit "$status"
}
trap cleanup EXIT INT TERM HUP

usage() {
  local file=$1 fixture=$2 appearance=$3 size=$4 state=${5:-active} collapsed=${6:-no}
  local -a environment=(
    "WINDOW_ID_TOOL=$window_tool"
    "NOTIFICATION_DRIVE_TOOL=$notification_tool"
    "FOCUS_DRIVE_TOOL=$focus_tool"
  )
  if [[ "$state" == inactive ]]; then
    environment+=("CAPTURE_INACTIVE_APP=$inactive_app")
  fi
  if [[ "$collapsed" == yes ]]; then
    environment+=("CAPTURE_TOOLBAR_BUTTON_DESCRIPTION=Hide Sidebar")
  fi
  env "${environment[@]}" "$capture" "$app" "$owner" "$output/$file" "jackin❯ desktop" \
    --fixture "$fixture" --open-usage --window-size "$size" --appearance "$appearance"
}

popover() {
  local file=$1 fixture=$2 appearance=$3
  env WINDOW_ID_TOOL="$window_tool" NOTIFICATION_DRIVE_TOOL="$notification_tool" \
    WINDOW_LAYER_MODE=all \
    "$capture" "$app" "$owner" "$output/$file" "" \
    --fixture "$fixture" --open-popover --appearance "$appearance"
}

usage usage-dark-active-F02.png F02-catalog-normal dark 920x620
usage usage-dark-inactive-F02.png F02-catalog-normal dark 920x620 inactive
usage usage-light-active-F02.png F02-catalog-normal light 920x620
usage usage-light-inactive-F02.png F02-catalog-normal light 920x620 inactive
usage usage-light-collapsed-F02.png F02-catalog-normal light 760x500 active yes
usage usage-light-empty-F00.png F00-no-providers light 760x500
usage usage-light-single-F01.png F01-single-normal light 920x620
usage usage-light-multiaccount-F03.png F03-multi-account light 920x620
usage usage-light-nearly-exhausted-F04.png F04-nearly-exhausted light 920x620
usage usage-light-exhausted-F05.png F05-exhausted light 920x620
usage usage-light-stale-F06.png F06-stale-last-good light 920x620
usage usage-light-refreshing-F07.png F07-refreshing-last-good light 920x620
usage usage-light-partial-F08.png F08-partial-timeout light 920x620
usage usage-light-permission-F09.png F09-permission-denied light 920x620
usage usage-light-offline-F10.png F10-offline-cached light 920x620
usage usage-light-long-F11.png F11-long-labels light 760x500
usage usage-light-min-F12.png F12-layout-envelope light 760x500
usage usage-light-expanded-F12.png F12-layout-envelope light 1200x760
usage usage-light-loading-F13.png F13-initial-loading light 760x500
usage usage-light-error-F14.png F14-global-bridge-error light 760x500

popover popover-dark-active-F02.png F02-catalog-normal dark
popover popover-light-active-F02.png F02-catalog-normal light
popover popover-light-empty-F00.png F00-no-providers light
popover popover-light-single-F01.png F01-single-normal light
popover popover-light-multiaccount-F03.png F03-multi-account light
popover popover-light-nearly-exhausted-F04.png F04-nearly-exhausted light
popover popover-light-exhausted-F05.png F05-exhausted light
popover popover-light-stale-F06.png F06-stale-last-good light
popover popover-light-refreshing-F07.png F07-refreshing-last-good light
popover popover-light-partial-F08.png F08-partial-timeout light
popover popover-light-permission-F09.png F09-permission-denied light
popover popover-light-offline-F10.png F10-offline-cached light
popover popover-light-long-F11.png F11-long-labels light
popover popover-light-maximum-F12.png F12-layout-envelope light
popover popover-light-loading-F13.png F13-initial-loading light
popover popover-light-error-F14.png F14-global-bridge-error light

echo "Final captures regenerated: $output"
