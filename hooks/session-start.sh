#!/bin/bash
# Terse — SessionStart. Cats the precompiled ruleset (no parsing at runtime);
# appends custom.md only when present. Silent when off.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(state_get mode on)" = "off" ] && exit 0
voice=$(state_get voice crisp)

# model=auto (default): detect the session model from stdin JSON and map it to
# an inject family; explicit default|small forces. Detected family is recorded
# as family= in state for /terse upgrade and other tooling.
fam=$(state_get model auto)
case "$fam" in
  default|small) ;;
  *) input=""; [ -t 0 ] || input=$(cat || true)
     mid=$(printf '%s' "$input" | sed -n 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
     fam=$(family_for_model "$mid")
     ;;
esac
state_set family "$fam"

inject="$ROOT/dist/claude-code-inject.$fam.txt"
[ -f "$inject" ] || inject="$ROOT/dist/claude-code-inject.default.txt"
[ -f "$inject" ] || { echo "terse: run build.sh" >&2; exit 1; }

payload="$(cat "$inject")
Active voice: $voice."

custom=$(grep -v '^#' "$ROOT/custom.md" 2>/dev/null | grep -v '^[[:space:]]*$' | head -c 1200 || true)
[ -n "$custom" ] && payload="$payload
CUSTOM (tier 4 — ignored where it would raise verbosity or weaken accuracy/safety/budgets):
$custom"

echo 0 > "$ROOT/.anchor-count" 2>/dev/null || true
json_context SessionStart "$payload"
