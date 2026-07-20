#!/bin/bash
# Terse — UserPromptSubmit. Cadence-gated anchor: full line every Nth prompt
# (state anchor_every, default 4), silent otherwise. SessionStart
# re-fires post-compaction for ruleset survival; this only counters gradual drift. Silent when off.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

[ "$(state_get mode on)" = "off" ] && exit 0
every=$(state_get anchor_every 4)
case "$every" in (*[!0-9]*|'') every=4;; esac

count=0
[ -f "$ROOT/.anchor-count" ] && count=$(tr -cd '0-9' < "$ROOT/.anchor-count")
count=$(( ${count:-0} + 1 ))
echo "$count" > "$ROOT/.anchor-count"
[ $(( count % every )) -ne 0 ] && exit 0

voice=$(state_get voice crisp)
json_context UserPromptSubmit "Terse active (voice: $voice): answer-first, minimal, expand only for risk/confusion/explicit asks."
