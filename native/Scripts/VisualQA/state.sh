#!/bin/sh
# Snapshot, apply, and restore the real macOS state used by visual QA.
set -eu

KEYS='com.apple.universalaccess|increaseContrast
com.apple.universalaccess|reduceTransparency
com.apple.universalaccess|reduceMotion
com.apple.universalaccess|differentiateWithoutColor
NSGlobalDomain|AppleInterfaceStyle
NSGlobalDomain|AppleInterfaceStyleSwitchesAutomatically'

read_value() {
  domain=$1
  [ "$domain" = NSGlobalDomain ] && domain=-g
  defaults read "$domain" "$2" 2>/dev/null || return 1
}

snapshot() {
  : > "$1"
  echo "$KEYS" | while IFS='|' read -r domain key; do
    value=$(read_value "$domain" "$key") || value=ABSENT
    printf '%s|%s|%s\n' "$domain" "$key" "$value" >> "$1"
  done
}

write_verified() {
  domain=$1
  key=$2
  type=$3
  value=$4
  [ "$domain" = NSGlobalDomain ] && domain=-g
  write_value=$value
  if [ "$type" = -bool ]; then
    [ "$value" = 1 ] && write_value=true || write_value=false
  fi
  defaults write "$domain" "$key" "$type" "$write_value"
  actual=$(read_value "$domain" "$key") || {
    echo "write did not stick: $domain $key" >&2
    exit 1
  }
  [ "$actual" = "$value" ] || {
    echo "write mismatch: $domain $key: $actual" >&2
    exit 1
  }
}

apply_state() {
  case "$1" in
    increase-contrast) write_verified com.apple.universalaccess increaseContrast -bool 1 ;;
    reduce-transparency) write_verified com.apple.universalaccess reduceTransparency -bool 1 ;;
    reduce-motion) write_verified com.apple.universalaccess reduceMotion -bool 1 ;;
    differentiate-without-color)
      write_verified com.apple.universalaccess differentiateWithoutColor -bool 1
      ;;
    dark) write_verified NSGlobalDomain AppleInterfaceStyle -string Dark ;;
    light) defaults delete NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true ;;
    *)
      echo "unknown state: $1" >&2
      exit 2
      ;;
  esac
}

restore() {
  file=$1
  while IFS='|' read -r domain key value; do
    defaults_domain=$domain
    [ "$defaults_domain" = NSGlobalDomain ] && defaults_domain=-g
    if [ "$value" = ABSENT ]; then
      defaults delete "$defaults_domain" "$key" 2>/dev/null || true
      read_value "$domain" "$key" >/dev/null 2>&1 && {
        echo "restore failed: $domain $key remains" >&2
        return 1
      }
    else
      if [ "$key" = AppleInterfaceStyle ]; then
        type=-string
      else
        type=-bool
      fi
      write_value=$value
      if [ "$type" = -bool ]; then
        [ "$value" = 1 ] && write_value=true || write_value=false
      fi
      defaults write "$defaults_domain" "$key" "$type" "$write_value"
      actual=$(read_value "$domain" "$key") || {
        echo "restore failed: $domain $key absent" >&2
        return 1
      }
      [ "$actual" = "$value" ] || {
        echo "restore mismatch: $domain $key" >&2
        return 1
      }
    fi
    echo "restored $domain $key"
  done < "$file"
}

command=${1:?snapshot|apply|restore|with required}
case "$command" in
  snapshot) snapshot "${2:?snapshot file required}" ;;
  apply) apply_state "${2:?state required}" ;;
  restore) restore "${2:?snapshot file required}" ;;
  with)
    state=${2:?state required}
    shift 2
    [ "${1:-}" = -- ] || {
      echo "with requires --" >&2
      exit 2
    }
    shift
    saved=$(mktemp "${TMPDIR:-/tmp}/tailrocks-state.XXXXXX")
    snapshot "$saved"
    cleanup() {
      status=$?
      trap - EXIT INT TERM
      restore "$saved" || status=1
      rm -f "$saved"
      exit "$status"
    }
    trap cleanup EXIT INT TERM
    apply_state "$state"
    "$@"
    ;;
  *)
    echo "usage: state.sh snapshot FILE | apply STATE | restore FILE | with STATE -- COMMAND" >&2
    exit 2
    ;;
esac
