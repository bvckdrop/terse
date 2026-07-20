#!/bin/bash
# Terse — Cursor install.
#   ./install.sh /path/to/project   → installs .cursor/rules/terse.mdc there
#   ./install.sh                    → prints the paste-ready global User Rules block
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RULE="$ROOT/platforms/cursor/terse.mdc"

if [ "${1:-}" = "--uninstall" ]; then
  if [ -n "${2:-}" ]; then
    rm -f "$2/.cursor/rules/terse.mdc"
    echo "Removed $2/.cursor/rules/terse.mdc."
  else
    echo "Project rule: rm <project>/.cursor/rules/terse.mdc"
    echo "Global: delete the terse block from Cursor → Settings → Rules → User Rules."
  fi
  exit 0
fi

[ -f "$RULE" ] || { echo "Run build.sh first."; exit 1; }

if [ -n "${1:-}" ]; then
  dest="$1/.cursor/rules"
  mkdir -p "$dest"
  cp "$RULE" "$dest/terse.mdc"
  echo "Installed $dest/terse.mdc (project rule, always applied)."
else
  echo "Cursor has no scriptable global-rules file. Paste this into"
  echo "Cursor → Settings → Rules → User Rules:"
  echo "-----------------------------------------------------------"
  awk 'c>=2{print} /^---$/{c++}' "$RULE"
fi
