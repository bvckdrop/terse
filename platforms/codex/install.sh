#!/bin/bash
# Terse — ChatGPT / OpenAI Codex CLI install.
# Writes a managed marker block into ~/.codex/AGENTS.md (idempotent).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
BLOCK="$ROOT/platforms/codex/AGENTS.terse.md"

if [ "${1:-}" = "--uninstall" ]; then
  [ -f "$TARGET" ] || { echo "Nothing to remove."; exit 0; }
  tmp=$(mktemp)
  awk '/# --- terse:begin ---/{skip=1} !skip{print} /# --- terse:end ---/{skip=0}' "$TARGET" > "$tmp"
  mv "$tmp" "$TARGET"
  echo "Removed terse block from $TARGET."
  exit 0
fi

[ -f "$BLOCK" ] || { echo "Run build.sh first."; exit 1; }
mkdir -p "$(dirname "$TARGET")"
touch "$TARGET"

# Remove any existing managed block, then append the current one.
tmp=$(mktemp)
awk '/# --- terse:begin ---/{skip=1} !skip{print} /# --- terse:end ---/{skip=0}' "$TARGET" > "$tmp"
cat "$tmp" "$BLOCK" > "$TARGET"
rm "$tmp"
echo "Installed into $TARGET (managed block; rerun to update, delete markers to remove)."
