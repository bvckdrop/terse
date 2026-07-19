#!/bin/bash
# Terse — Claude Code install: symlinks + settings.json hook merge + state seed.
# Idempotent; run again after moving the repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE/skills"
ln -sfn "$ROOT" "$CLAUDE/terse"
ln -sfn "$ROOT/skills/terse" "$CLAUDE/skills/terse"
[ -f "$ROOT/state" ] || printf 'on\ncrisp\n' > "$ROOT/state"

python3 - "$CLAUDE/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f: s = json.load(f)
except FileNotFoundError:
    s = {}
hooks = s.setdefault("hooks", {})
def entry(cmd, matcher=None):
    e = {"hooks": [{"type": "command",
                    "command": f'bash "$HOME/.claude/terse/hooks/{cmd}"',
                    "timeout": 5}]}
    if matcher: e["matcher"] = matcher
    return e
def ensure(event, e):
    arr = hooks.setdefault(event, [])
    if not any("terse" in h.get("command", "") for g in arr for h in g.get("hooks", [])):
        arr.append(e)
ensure("SessionStart", entry("session-start.sh"))
ensure("UserPromptSubmit", entry("anchor.sh"))
ensure("PreToolUse", entry("subagent.sh", "Task|Agent"))
with open(path, "w") as f: json.dump(s, f, indent=2)
print("settings.json: terse hooks registered")
PY
echo "Claude Code install complete. Takes effect in new sessions."
