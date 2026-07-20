#!/bin/bash
# Terse — install dispatcher.
#   ./install.sh                      → auto-detect installed platforms
#   ./install.sh --platform claude|codex|cursor|all [project]
#   ./install.sh --uninstall [claude|codex|cursor|all] [project]
set -euo pipefail
cd "$(dirname "$0")"

X=""
case "${1:-}" in
  --uninstall) X="--uninstall"; want="${2:-all}" ;;
  --platform)  want="${2:-detect}" ;;
  *)           want="detect" ;;
esac
[ -n "$X" ] || ./build.sh >/dev/null

run() { echo "== $1 =="; "platforms/$1/install.sh" "${@:2}"; }

case "$want" in
  claude) run claude $X ;;
  codex)  run codex $X ;;
  cursor) run cursor $X "${3:-}" ;;
  all)    run claude $X; run codex $X; run cursor $X ;;
  detect)
    [ -d "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ] && run claude $X
    [ -d "${CODEX_HOME:-$HOME/.codex}" ] && run codex $X
    command -v cursor >/dev/null 2>&1 && run cursor $X || true
    ;;
  *) echo "Unknown platform: $want"; exit 1 ;;
esac
