#!/bin/bash
# Terse — Claude Code install: build + symlinks + settings.json hook merge +
# state seed. Idempotent (also migrates the old positional state format).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

"$ROOT/build.sh" >/dev/null
mkdir -p "$CLAUDE/skills"
ln -sfn "$ROOT" "$CLAUDE/terse"
ln -sfn "$ROOT/skills/terse" "$CLAUDE/skills/terse"

if [ ! -f "$ROOT/state" ] || ! grep -q '^mode=' "$ROOT/state"; then
  old_voice=$( { sed -n 2p "$ROOT/state" | tr -d '\r'; } 2>/dev/null || true)
  case "$old_voice" in (crisp|buddy|witty) ;; (*) old_voice=crisp;; esac
  printf 'mode=on\nvoice=%s\nanchor_every=4\nmodel=default\n' "$old_voice" > "$ROOT/state"
fi

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
ensure("PreCompact", entry("pre-compact.sh"))
ensure("PreToolUse", entry("subagent.sh", "Task|Agent"))
with open(path, "w") as f: json.dump(s, f, indent=2)
print("settings.json: terse hooks registered (SessionStart, UserPromptSubmit, PreCompact, PreToolUse)")
PY
echo "Claude Code install complete. Takes effect in new sessions."
