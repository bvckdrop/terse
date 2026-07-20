#!/bin/bash
# Terse — ChatGPT / OpenAI Codex CLI install.
# Writes a managed marker block into ~/.codex/AGENTS.md (idempotent).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
BLOCK="$ROOT/platforms/codex/AGENTS.terse.md"

if [ "${1:-}" = "--uninstall" ]; then
  if ! grep -q '# --- terse:begin ---' "$TARGET" 2>/dev/null; then
    echo "Codex: not installed — nothing to remove."
    exit 0
  fi
  if grep -q '# --- terse:end ---' "$TARGET"; then
    echo "Codex: managed block found in $TARGET — removing."
  else
    echo "Codex: partial block (begin marker without end) in $TARGET — removing from begin marker to end of file."
  fi
  tmp=$(mktemp)
  awk '/# --- terse:begin ---/{skip=1} !skip{print} /# --- terse:end ---/{skip=0}' "$TARGET" > "$tmp"
  mv "$tmp" "$TARGET"
  if grep -q 'terse:' "$TARGET"; then
    echo "Codex: uninstall INCOMPLETE — terse markers still present in $TARGET" >&2
    exit 1
  fi
  echo "Codex: full uninstall succeeded — verified clean."
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
