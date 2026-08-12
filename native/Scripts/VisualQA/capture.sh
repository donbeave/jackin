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
# Re-activate before resolving; activation can replace the target window.
open "$APP"
sleep 1

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
  sleep 1
fi

screencapture -x -o -l "$WID" "$OUT"
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
