#!/bin/sh
# Atomic kill-launch-reactivate-resolve-capture loop for jackin❯ desktop.
set -eu

APP=${1:?app bundle path required}
OWNER=${2:?owner name required}
OUT=${3:?output path required}
WINDOW_NAME=${4:-}
shift 4
HERE=$(cd "$(dirname "$0")" && pwd -P)
REPO=$(cd "$HERE/../../.." && pwd -P)

fixture_id=live
appearance=system
window_size=default
argument_key=
for argument in "$@"; do
  case "$argument_key" in
    fixture) fixture_id=$argument; argument_key=; continue ;;
    appearance) appearance=$argument; argument_key=; continue ;;
    window-size) window_size=$argument; argument_key=; continue ;;
  esac
  case "$argument" in
    --fixture) argument_key=fixture ;;
    --appearance) argument_key=appearance ;;
    --window-size) argument_key=window-size ;;
  esac
done

app_dir=$(cd "$(dirname "$APP")" 2>/dev/null && pwd -P) || {
  echo "app directory not found" >&2
  exit 2
}
APP="$app_dir/$(basename "$APP")"
case "$APP" in
  /tmp/* | /private/tmp/* | /var/folders/* | /private/var/folders/*)
    echo "refusing to launch app from temporary directory" >&2
    exit 2
    ;;
esac
if [ -n "${TMPDIR:-}" ]; then
  tmp_dir=$(cd "$TMPDIR" 2>/dev/null && pwd -P) || tmp_dir=$TMPDIR
  case "$APP" in
    "$tmp_dir" | "$tmp_dir"/*)
      echo "refusing to launch app from TMPDIR" >&2
      exit 2
      ;;
  esac
fi

mkdir -p "$(dirname "$OUT")"
TOOL=${WINDOW_ID_TOOL:-"${TMPDIR:-/tmp}/tailrocks-window-id"}
if [ ! -x "$TOOL" ]; then
  command -v swiftc >/dev/null 2>&1 || {
    echo "swiftc missing; set WINDOW_ID_TOOL" >&2
    exit 2
  }
  swiftc -O "$HERE/window-id.swift" -o "$TOOL"
fi
DRIVE_TOOL=${NOTIFICATION_DRIVE_TOOL:-"${TMPDIR:-/tmp}/tailrocks-notification-drive"}
if [ ! -x "$DRIVE_TOOL" ]; then
  command -v swiftc >/dev/null 2>&1 || {
    echo "swiftc missing; set NOTIFICATION_DRIVE_TOOL" >&2
    exit 2
  }
  swiftc -O "$HERE/notification-drive.swift" -o "$DRIVE_TOOL"
fi

EXEC="$APP/Contents/MacOS/"
matched=$(pgrep -f "$EXEC" 2>/dev/null | wc -l | tr -d ' ')
echo "kill matched $matched processes"
if [ "$matched" -gt 0 ]; then
  pgrep -f "$EXEC" | xargs kill -TERM
  i=0
  while pgrep -f "$EXEC" >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
    sleep 0.5
    i=$((i + 1))
  done
  pgrep -f "$EXEC" >/dev/null 2>&1 && pgrep -f "$EXEC" | xargs kill -KILL
  i=0
  while pgrep -f "$EXEC" >/dev/null 2>&1 && [ "$i" -lt 10 ]; do
    sleep 0.5
    i=$((i + 1))
  done
  pgrep -f "$EXEC" >/dev/null 2>&1 && {
    echo "app process survived kill" >&2
    exit 1
  }
fi

open -n "$APP" --args "$@"
sleep 3
executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")
if [ -n "${CAPTURE_STATUS_ITEM_INDEX:-}" ]; then
  if [ "${CAPTURE_STATUS_ITEM_BUTTON:-left}" = right ]; then
    STATUS_TOOL=${STATUS_ITEM_TOOL:-"${TMPDIR:-/tmp}/tailrocks-status-item-drive"}
    if [ ! -x "$STATUS_TOOL" ]; then
      swiftc -O "$HERE/status-item-drive.swift" -o "$STATUS_TOOL"
    fi
    pid=$(pgrep -f "$EXEC" | head -1)
    "$STATUS_TOOL" "$pid" "$CAPTURE_STATUS_ITEM_INDEX" right
  else
    osascript -e \
      "tell application \"System Events\" to tell application process \"$executable\" to click menu bar item $CAPTURE_STATUS_ITEM_INDEX of menu bar 2"
  fi
  sleep 1
else
  # The product owns activation. Reopening here can replace a transient popover.
  sleep 1
fi

requested_activation=active
if [ -n "${CAPTURE_INACTIVE_APP:-}" ]; then
  requested_activation=inactive
fi

drive_activation() {
  if [ -n "$WINDOW_NAME" ]; then
    window_onscreen=$("$TOOL" "$OWNER" "$WINDOW_NAME" --json 2>/dev/null \
      | plutil -extract onScreen raw - 2>/dev/null || echo false)
    if [ "$window_onscreen" != true ]; then
      "$DRIVE_TOOL" "com.jackin-project.desktop.visual-qa.show-usage"
    fi
  else
    popover_onscreen=$(WINDOW_LAYER_MODE=all "$TOOL" "$OWNER" --json 2>/dev/null \
      | plutil -extract onScreen raw - 2>/dev/null || echo false)
    if [ "$popover_onscreen" != true ]; then
      "$DRIVE_TOOL" "com.jackin-project.desktop.visual-qa.show-popover"
    fi
  fi
  if [ "$requested_activation" = inactive ]; then
    open -a "$CAPTURE_INACTIVE_APP" >/dev/null 2>&1 || true
    osascript -e \
      "tell application \"System Events\" to set frontmost of application process \"$CAPTURE_INACTIVE_APP\" to true" \
      >/dev/null 2>&1 || true
  else
    osascript -e \
      "tell application \"System Events\" to set frontmost of application process \"$executable\" to true" \
      >/dev/null 2>&1 || true
  fi
}

activation_ok=0
i=0
while [ "$i" -lt 60 ]; do
  drive_activation
  sleep 0.5
  is_frontmost=$(osascript -e \
    "tell application \"System Events\" to get frontmost of application process \"$executable\"" \
    2>/dev/null || echo unavailable)
  if { [ "$requested_activation" = active ] && [ "$is_frontmost" = true ]; } \
    || { [ "$requested_activation" = inactive ] && [ "$is_frontmost" = false ]; }; then
    activation_ok=1
    break
  fi
  i=$((i + 1))
done
[ "$activation_ok" -eq 1 ] || {
  echo "application did not reach requested $requested_activation state" >&2
  exit 1
}

if [ -n "${CAPTURE_TOOLBAR_BUTTON_DESCRIPTION:-}" ]; then
  [ -n "$WINDOW_NAME" ] || {
    echo "toolbar driving requires a window title" >&2
    exit 2
  }
  toolbar_ok=0
  i=0
  while [ "$i" -lt 40 ]; do
    drive_activation
    window_onscreen=$("$TOOL" "$OWNER" "$WINDOW_NAME" --json 2>/dev/null \
      | plutil -extract onScreen raw - 2>/dev/null || echo false)
    if [ "$window_onscreen" = true ] && osascript -e \
      "tell application \"System Events\" to tell application process \"$executable\" to tell front window to click first button of toolbar 1 whose description is \"$CAPTURE_TOOLBAR_BUTTON_DESCRIPTION\""; then
      toolbar_ok=1
      break
    fi
    sleep 0.5
    i=$((i + 1))
  done
  [ "$toolbar_ok" -eq 1 ] || {
    echo "toolbar button did not become available: $CAPTURE_TOOLBAR_BUTTON_DESCRIPTION" >&2
    exit 1
  }
  sleep 1
fi

capture_ok=0
success_count=0
best_size=0
best_metadata="$OUT.capture-metadata.json"
attempt=0
while [ "$attempt" -lt 20 ]; do
  drive_activation
  sleep 0.5
  candidate="$OUT.capture-$attempt.png"
  candidate_metadata="$OUT.capture-$attempt.json"
  candidate_post_metadata="$OUT.capture-$attempt-post.json"
  if [ -n "$WINDOW_NAME" ]; then
    "$TOOL" "$OWNER" "$WINDOW_NAME" --json > "$candidate_metadata" 2>/dev/null || {
      rm -f "$candidate_metadata"
      attempt=$((attempt + 1))
      continue
    }
  else
    "$TOOL" "$OWNER" --json > "$candidate_metadata" 2>/dev/null || {
      rm -f "$candidate_metadata"
      attempt=$((attempt + 1))
      continue
    }
  fi
  actual_activation=$(plutil -extract applicationActivationState raw "$candidate_metadata")
  actual_key=$(plutil -extract keyStatus raw "$candidate_metadata")
  actual_onscreen=$(plutil -extract onScreen raw "$candidate_metadata")
  expected_key=key
  [ "$requested_activation" = inactive ] && expected_key=non-key
  [ -z "$WINDOW_NAME" ] && expected_key=not-applicable-transient
  if [ "$actual_activation" != "$requested_activation" ] \
    || [ "$actual_key" != "$expected_key" ] || [ "$actual_onscreen" != true ]; then
    rm -f "$candidate_metadata"
    attempt=$((attempt + 1))
    continue
  fi
  WID=$(plutil -extract windowID raw "$candidate_metadata")
  if screencapture -x -o -l "$WID" "$candidate"; then
    if [ -n "$WINDOW_NAME" ]; then
      "$TOOL" "$OWNER" "$WINDOW_NAME" --json > "$candidate_post_metadata" 2>/dev/null || true
    else
      "$TOOL" "$OWNER" --json > "$candidate_post_metadata" 2>/dev/null || true
    fi
    post_id=$(plutil -extract windowID raw "$candidate_post_metadata" 2>/dev/null || echo unavailable)
    post_activation=$(plutil -extract applicationActivationState raw "$candidate_post_metadata" 2>/dev/null || echo unavailable)
    post_key=$(plutil -extract keyStatus raw "$candidate_post_metadata" 2>/dev/null || echo unavailable)
    post_onscreen=$(plutil -extract onScreen raw "$candidate_post_metadata" 2>/dev/null || echo unavailable)
    if [ "$post_id" != "$WID" ] || [ "$post_activation" != "$requested_activation" ] \
      || [ "$post_key" != "$expected_key" ] || [ "$post_onscreen" != true ]; then
      rm -f "$candidate" "$candidate_metadata" "$candidate_post_metadata"
      attempt=$((attempt + 1))
      continue
    fi
    rm -f "$candidate_post_metadata"
    capture_ok=1
    success_count=$((success_count + 1))
    candidate_size=$(wc -c < "$candidate")
    if [ "$candidate_size" -gt "$best_size" ]; then
      mv -f "$candidate" "$OUT"
      mv -f "$candidate_metadata" "$best_metadata"
      best_size=$candidate_size
    else
      rm -f "$candidate" "$candidate_metadata"
    fi
    attempt=$((attempt + 1))
    [ "$success_count" -ge 2 ] && break
    continue
  fi
  rm -f "$candidate" "$candidate_metadata" "$candidate_post_metadata"
  attempt=$((attempt + 1))
done
[ "$capture_ok" -eq 1 ] || {
  echo "window capture did not stabilize" >&2
  exit 1
}
[ -f "$OUT" ] && [ "$(wc -c < "$OUT")" -ge 8192 ] || {
  echo "capture empty — check Screen Recording permission for this terminal" >&2
  exit 1
}
dims=$(sips -g pixelWidth -g pixelHeight "$OUT" 2>/dev/null)
if ! echo "$dims" | grep -Eq 'pixelWidth: [1-9][0-9]*' \
  || ! echo "$dims" | grep -Eq 'pixelHeight: [1-9][0-9]*'; then
    echo "capture has zero dimensions" >&2
    exit 1
fi
pixel_width=$(echo "$dims" | awk '/pixelWidth:/ { print $2 }')
pixel_height=$(echo "$dims" | awk '/pixelHeight:/ { print $2 }')
SIDECAR="$OUT.json"
mv -f "$best_metadata" "$SIDECAR"
plutil -replace pixelDimensions -json "{\"width\":$pixel_width,\"height\":$pixel_height}" "$SIDECAR"
frame_width=$(plutil -extract frameSize.width raw "$SIDECAR")
scale=$(awk -v pixels="$pixel_width" -v points="$frame_width" \
  'BEGIN { if (points > 0) printf "%.3f", pixels / points; else print "0" }')
plutil -replace backingScale -float "$scale" "$SIDECAR"
plutil -replace captureTimestampUTC -string "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$SIDECAR"
plutil -replace sourceCommit -string "$(git -C "$REPO" rev-parse HEAD)" "$SIDECAR"
plutil -replace appBundlePath -string "$APP" "$SIDECAR"
plutil -replace appExecutableSHA256 -string "$(shasum -a 256 "$APP/Contents/MacOS/$executable" | awk '{ print $1 }')" "$SIDECAR"
plutil -replace imageSHA256 -string "$(shasum -a 256 "$OUT" | awk '{ print $1 }')" "$SIDECAR"
plutil -replace fixtureID -string "$fixture_id" "$SIDECAR"
plutil -replace requestedAppearance -string "$appearance" "$SIDECAR"
plutil -replace requestedActivationState -string "$requested_activation" "$SIDECAR"
plutil -replace requestedWindowSize -string "$window_size" "$SIDECAR"
plutil -replace macOSVersion -string "$(sw_vers -productVersion)" "$SIDECAR"
plutil -replace macOSBuild -string "$(sw_vers -buildVersion)" "$SIDECAR"
plutil -replace xcodeVersion -string "$(xcodebuild -version | head -1)" "$SIDECAR"
plutil -replace xcodeBuild -string "$(xcodebuild -version | awk '/Build version/ { print $3 }')" "$SIDECAR"
plutil -replace macOSSDK -string "$(xcrun --sdk macosx --show-sdk-version)" "$SIDECAR"
plutil -insert accessibilitySettings -json '{}' "$SIDECAR"
for setting in increaseContrast reduceTransparency reduceMotion differentiateWithoutColor; do
  setting_value=$(defaults read com.apple.universalaccess "$setting" 2>/dev/null || echo ABSENT)
  plutil -replace "accessibilitySettings.$setting" -string "$setting_value" "$SIDECAR"
done
echo "$OUT"
