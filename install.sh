#!/bin/bash
# Terse — install dispatcher.
#   ./install.sh                      → auto-detect installed platforms
#   ./install.sh --platform claude|codex|cursor|all
set -euo pipefail
cd "$(dirname "$0")"
./build.sh >/dev/null

want="${2:-detect}"
[ "${1:-}" = "--platform" ] || want="detect"

run() { echo "== $1 =="; "platforms/$1/install.sh" "${@:2}"; }

case "$want" in
  claude) run claude ;;
  codex)  run codex ;;
  cursor) run cursor "${3:-}" ;;
  all)    run claude; run codex; run cursor ;;
  detect)
    [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] && run claude
    [ -d "${CODEX_HOME:-$HOME/.codex}" ] && run codex
    command -v cursor >/dev/null 2>&1 && run cursor || true
    ;;
  *) echo "Unknown platform: $want"; exit 1 ;;
esac
