#!/bin/bash
# Terse — PreToolUse hook for agent-spawning tools (Task|Agent).
# Appends the terse digest to the subagent prompt via updatedInput.
# Idempotent (sentinel check). Workflow scripts are left untouched —
# the SKILL.md behavioral rule covers those.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/state"

[ -f "$STATE" ] && [ "$(sed -n 1p "$STATE")" = "off" ] && exit 0

input=$(cat)
python3 - "$input" <<'PY'
import json, sys
DIGEST = ("\n\nReport tersely: answer first, no filler, expand only for "
          "risk/ambiguity; code/errors byte-exact.")
try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)
ti = data.get("tool_input") or {}
prompt = ti.get("prompt")
if not isinstance(prompt, str) or "Report tersely:" in prompt:
    sys.exit(0)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {**ti, "prompt": prompt + DIGEST}}}))
PY
