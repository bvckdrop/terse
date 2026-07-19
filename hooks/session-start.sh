#!/bin/bash
# Terse — SessionStart hook. Injects the ruleset (+ user customizations)
# as hidden context. Silent when state is off.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/state"

[ -f "$STATE" ] || printf 'on\ncrisp\n' > "$STATE"
mode=$(sed -n 1p "$STATE"); voice=$(sed -n 2p "$STATE")
[ "$mode" = "off" ] && exit 0
[ -n "$voice" ] || voice=crisp

# Ruleset = SKILL.md body (frontmatter stripped) — single source of truth.
rules=$(awk 'f&&c>=2{print} /^---$/{c++; f=1; next}' "$ROOT/skills/terse/SKILL.md")

# User customizations: capped at ~300 tokens (~1200 chars) to protect budget.
custom=""
if [ -s "$ROOT/custom.md" ]; then
  custom=$(head -c 1200 "$ROOT/custom.md")
  [ "$(wc -c < "$ROOT/custom.md")" -gt 1200 ] && custom="$custom
[custom.md truncated at 1200 chars — trim it]"
  custom="

## User customizations (Charter tier 4 — ignored where they would increase verbosity, weaken accuracy or safety, or override budgets)
$custom"
fi

payload="TERSE MODE ACTIVE (voice: $voice). Follow these rules every response:
$rules$custom"

python3 - "$payload" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": sys.argv[1]}}))
PY
