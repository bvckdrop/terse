#!/bin/bash
# Terse — PreToolUse (Task|Agent). Appends the digest to subagent prompts
# via updatedInput. Fast path: pure-bash sentinel check skips the python
# spawn when the digest is already present. Silent when off.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(state_get mode on)" = "off" ] && exit 0

input=$(cat)
case "$input" in *"Terse report:"*) exit 0;; esac

DIGEST="$(cat "$ROOT/dist/claude-code-subagent-digest.txt" 2>/dev/null || printf 'Terse report: answer first, no filler; code/errors exact.')"
export TERSE_DIGEST="$DIGEST"
python3 - "$input" <<'PY'
import json, os, sys
digest = "\n\n" + os.environ["TERSE_DIGEST"].strip()
try:
    data = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)
ti = data.get("tool_input") or {}
prompt = ti.get("prompt")
if not isinstance(prompt, str):
    sys.exit(0)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": {**ti, "prompt": prompt + digest}}}))
PY
