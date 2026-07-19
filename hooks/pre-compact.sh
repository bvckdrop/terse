#!/bin/bash
# Terse — PreCompact. Marks the full ruleset as critical context so it
# survives compaction; the compacted session resumes terse without cost.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(state_get mode on)" = "off" ] && exit 0
fam=$(state_get model default)
inject="$ROOT/dist/inject.$fam.txt"
[ -f "$inject" ] || inject="$ROOT/dist/inject.default.txt"
[ -f "$inject" ] || exit 0

json_context PreCompact "PRESERVE VERBATIM through compaction — active communication contract:
$(cat "$inject")
Active voice: $(state_get voice crisp)."
