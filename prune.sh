#!/bin/bash
# Terse — journal hygiene. Deletes all rejected entries from LEARNINGS.md.
# Adopted, candidate, and graduated entries are never touched;
# nothing above the <!-- entries below --> marker is ever modified.
set -euo pipefail
cd "$(dirname "$0")"

tmp=$(mktemp)

awk '
  !inentries { print; if (/<!-- entries below -->/) inentries=1; next }
  /^## /     { skip = ($0 ~ /status=rejected/); if (skip) n++ }
  !skip      { print }
  END        { print n+0 > "/dev/stderr" }
' LEARNINGS.md > "$tmp" 2>/tmp/terse-prune-count

count=$(cat /tmp/terse-prune-count)
if [ "$count" -gt 0 ]; then
  mv "$tmp" LEARNINGS.md
else
  rm -f "$tmp"
fi
echo "Pruned $count rejected entr$( [ "$count" = 1 ] && echo y || echo ies)"
