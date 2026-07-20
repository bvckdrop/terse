#!/bin/bash
# Terse — shared hook lib. State is key=value (tolerant: missing keys default).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/state"

state_get() { # $1 key, $2 default
  local v=""
  [ -f "$STATE" ] && v=$(sed -n "s/^$1=//p" "$STATE" | tr -d '\r' | head -1)
  printf '%s' "${v:-$2}"
}

state_set() { # $1 key, $2 value — update or append, atomic
  local tmp="$STATE.tmp"
  { grep -v "^$1=" "$STATE" 2>/dev/null || true; echo "$1=$2"; } > "$tmp" && mv "$tmp" "$STATE"
}

family_for_model() { # $1 model id → inject family
  case "$1" in
    *haiku*) echo small ;;
    *)       echo default ;;
  esac
}

json_context() { # $1 event, $2 text — minimal JSON escaping (\ " newline)
  local t=${2//\\/\\\\}; t=${t//\"/\\\"}; t=${t//$'\n'/\\n}
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$1" "$t"
}
