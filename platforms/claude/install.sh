#!/bin/bash
# Terse — Claude Code install: build + symlinks + settings.json hook merge +
# state seed. Idempotent (also migrates the old positional state format).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if [ "${1:-}" = "--uninstall" ]; then
  # Verify what's actually installed before touching anything.
  present=""; absent=""
  { [ -L "$CLAUDE/terse" ] || [ -e "$CLAUDE/terse" ]; } \
    && present="$present ~/.claude/terse" || absent="$absent ~/.claude/terse"
  { [ -L "$CLAUDE/skills/terse" ] || [ -e "$CLAUDE/skills/terse" ]; } \
    && present="$present ~/.claude/skills/terse" || absent="$absent ~/.claude/skills/terse"
  grep -q 'terse/hooks' "$CLAUDE/settings.json" 2>/dev/null \
    && present="$present settings.json-hooks" || absent="$absent settings.json-hooks"

  if [ -z "$present" ]; then
    echo "Claude Code: not installed — nothing to remove."
    exit 0
  elif [ -n "$absent" ]; then
    echo "Claude Code: partial installation (present:$present; missing:$absent) — removing what's present."
  else
    echo "Claude Code: full installation found — removing."
  fi

  rm -f "$CLAUDE/terse" "$CLAUDE/skills/terse"
  python3 - "$CLAUDE/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f: s = json.load(f)
except FileNotFoundError:
    sys.exit(0)
hooks = s.get("hooks", {})
for event in ("SessionStart", "UserPromptSubmit", "PreToolUse"):
    arr = hooks.get(event)
    if not arr: continue
    arr[:] = [g for g in arr
              if not any("terse" in h.get("command", "") for h in g.get("hooks", []))]
    if not arr: del hooks[event]
if not hooks: s.pop("hooks", None)
with open(path, "w") as f: json.dump(s, f, indent=2)
print("settings.json: terse hooks removed")
PY

  # Verify removal succeeded.
  left=""
  { [ -L "$CLAUDE/terse" ] || [ -e "$CLAUDE/terse" ]; } && left="$left ~/.claude/terse"
  { [ -L "$CLAUDE/skills/terse" ] || [ -e "$CLAUDE/skills/terse" ]; } && left="$left ~/.claude/skills/terse"
  grep -q 'terse/hooks' "$CLAUDE/settings.json" 2>/dev/null && left="$left settings.json-hooks"
  if [ -n "$left" ]; then
    echo "Claude Code: uninstall INCOMPLETE — still present:$left" >&2
    exit 1
  fi
  echo "Claude Code: full uninstall succeeded — verified clean. Takes effect in new sessions."
  exit 0
fi

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
ensure("PreToolUse", entry("subagent.sh", "Task|Agent"))
with open(path, "w") as f: json.dump(s, f, indent=2)
print("settings.json: terse hooks registered (SessionStart, UserPromptSubmit, PreToolUse)")
PY
echo "Claude Code install complete. Takes effect in new sessions."
