#!/bin/bash
# Terse — UserPromptSubmit hook. ~25-token anchor keeps the register stable
# across long sessions and context compaction. Silent when off.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STATE="$ROOT/state"

[ -f "$STATE" ] || exit 0
mode=$(sed -n 1p "$STATE"); voice=$(sed -n 2p "$STATE")
[ "$mode" = "off" ] && exit 0
[ -n "$voice" ] || voice=crisp

printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Terse mode (voice: %s): answer-first, minimal output, expand only for risk/confusion/explicit asks; code and errors byte-exact."}}\n' "$voice"
