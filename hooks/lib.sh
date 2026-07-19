#!/bin/bash
# Terse — shared hook lib. State is key=value (tolerant: missing keys default).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/state"

state_get() { # $1 key, $2 default
  local v=""
  [ -f "$STATE" ] && v=$(sed -n "s/^$1=//p" "$STATE" | tr -d '\r' | head -1)
  printf '%s' "${v:-$2}"
}

json_context() { # $1 event, $2 text — minimal JSON escaping (\ " newline)
  local t=${2//\\/\\\\}; t=${t//\"/\\\"}; t=${t//$'\n'/\\n}
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$1" "$t"
}
