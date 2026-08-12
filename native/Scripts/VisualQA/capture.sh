#!/bin/sh
# Atomic kill-launch-reactivate-resolve-capture loop for jackin❯ desktop.
set -eu

APP=${1:?app bundle path required}
OWNER=${2:?owner name required}
OUT=${3:?output path required}
WINDOW_NAME=${4:-}
shift 4
HERE=$(cd "$(dirname "$0")" && pwd -P)

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
  # Re-activate before resolving; activation can replace the target window.
  open "$APP"
  sleep 1
fi

if [ -n "${CAPTURE_TOOLBAR_BUTTON_DESCRIPTION:-}" ]; then
  [ -n "$WINDOW_NAME" ] || {
    echo "toolbar driving requires a window title" >&2
    exit 2
  }
  osascript -e \
    "tell application \"System Events\" to tell application process \"$executable\" to tell front window to click first button of toolbar 1 whose description is \"$CAPTURE_TOOLBAR_BUTTON_DESCRIPTION\""
  sleep 1
fi

WID=""
i=0
while [ "$i" -lt 10 ]; do
  if [ -n "$WINDOW_NAME" ]; then
    WID=$("$TOOL" "$OWNER" "$WINDOW_NAME" || true)
  else
    WID=$("$TOOL" "$OWNER" || true)
  fi
  [ -n "$WID" ] && break
  sleep 1
  i=$((i + 1))
done
case "$WID" in
  '' | *[!0-9]*)
    echo "no numeric window id resolved for $OWNER" >&2
    "$TOOL" "$OWNER" --list >&2 || true
    exit 1
    ;;
esac

if [ -n "${CAPTURE_INACTIVE_APP:-}" ]; then
  open -a "$CAPTURE_INACTIVE_APP"
  osascript -e "tell application \"$CAPTURE_INACTIVE_APP\" to activate"
  sleep 1
fi

capture_ok=0
best_size=0
attempt=0
while [ "$attempt" -lt 3 ]; do
  sleep 1
  candidate="$OUT.capture-$attempt.png"
  if screencapture -x -o -l "$WID" "$candidate"; then
    capture_ok=1
    candidate_size=$(wc -c < "$candidate")
    if [ "$candidate_size" -gt "$best_size" ]; then
      mv -f "$candidate" "$OUT"
      best_size=$candidate_size
    else
      rm -f "$candidate"
    fi
    attempt=$((attempt + 1))
    continue
  fi
  rm -f "$candidate"
  if [ -n "$WINDOW_NAME" ]; then
    WID=$("$TOOL" "$OWNER" "$WINDOW_NAME" || true)
  else
    WID=$("$TOOL" "$OWNER" || true)
  fi
  case "$WID" in
    '' | *[!0-9]*) WID="" ;;
  esac
  [ -n "$WID" ] || break
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
echo "$dims" | grep -Eq 'pixelWidth: [1-9][0-9]*' \
  && echo "$dims" | grep -Eq 'pixelHeight: [1-9][0-9]*' || {
    echo "capture has zero dimensions" >&2
    exit 1
  }
pixel_width=$(echo "$dims" | awk '/pixelWidth:/ { print $2 }')
pixel_height=$(echo "$dims" | awk '/pixelHeight:/ { print $2 }')
SIDECAR="$OUT.json"
if [ -n "$WINDOW_NAME" ]; then
  "$TOOL" "$OWNER" "$WINDOW_NAME" --json > "$SIDECAR"
else
  "$TOOL" "$OWNER" --json > "$SIDECAR"
fi
plutil -replace pixelDimensions -json "{\"width\":$pixel_width,\"height\":$pixel_height}" "$SIDECAR"
frame_width=$(plutil -extract frameSize.width raw "$SIDECAR")
scale=$(awk -v pixels="$pixel_width" -v points="$frame_width" \
  'BEGIN { if (points > 0) printf "%.3f", pixels / points; else print "0" }')
plutil -replace backingScale -float "$scale" "$SIDECAR"
echo "$OUT"
