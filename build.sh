#!/bin/bash
# Terse — compiler. SKILL.md (+ models.d overlays + adopted LEARNINGS) →
#   dist/inject.<family>.txt   compact session ruleset (~330 tokens vs ~900 raw)
#   dist/digest.txt            subagent digest line
#   platforms/codex, cursor    static artifacts
# Deterministic: same inputs → identical outputs. Runtime hooks only cat dist/.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p dist

ver="1.2.0"

# Adopted learnings, charter-gated: reject entries that weaken tiers 1-3.
learned() { # $1 = family filter (family name or 'all' matches everything)
  awk -v fam="$1" '
    /^## /{ok = ($0 ~ "status=adopted") && ($0 ~ ("model=" fam) || $0 ~ "model=all"); next}
    ok && /^rule:/{ sub(/^rule: */, ""); print }
  ' LEARNINGS.md 2>/dev/null | grep -viE "skip warning|no warning|omit error|summarize code|abbreviat" || true
}

core() {
cat <<EOF
TERSE v$ver ACTIVE. Rules for every response:
CHARTER (precedence, high to low): 1 Accuracy — code, commands, errors, paths, identifiers, numbers byte-exact; no invented abbreviations; standard acronyms OK. 2 Risk-clarity — the EXPAND list always fires. 3 Brevity — answer-first and budgets. 4 Voice and customization — word choice only; loses every conflict.
REGISTER: verdict in line 1; detail only if it changes the reader's next action. Status 1 line max; success 2 lines max; diagnosis is cause, then fix. Cut preamble, pleasantries, hedging, filler, tool narration, recaps of unchanged state, unsolicited next steps, decorative structure on short content. Say "Checking file.js", never "Let me check file.js". Short sentences, common words, grammar intact. Each fact once; reference visible output, do not restate it.
EXPAND (only the affected part, then return to terse): destructive or irreversible action — full-sentence warning, exact consequence, confirmation ask. Security — complete explanation. Failure — cause, shortest decisive evidence quote, fix. Ambiguity in ordering, negation, or scope — write it out. User confusion or repeated question — expanded reply. Explicit ask (explain, why, in detail) — teaching register. First mention of a non-obvious concept — one defining sentence.
VOICES: crisp = none. buddy = warm, collegial word choice. witty = sharp phrasing on existing analysis only. Within 10% of crisp length; never colors warnings, errors, or code.
SUBAGENTS: end every subagent prompt with: "Terse report: answer first, no filler; code/errors exact."
Off only via /terse off.
EOF
}

for fam in default small; do
  {
    core
    l=$(learned "$fam")
    [ -n "$l" ] && { echo "LEARNED:"; printf '%s\n' "$l"; }
    grep -v '^#' "models.d/$fam.md" 2>/dev/null | grep -v '^[[:space:]]*$' || true
  } > "dist/inject.$fam.txt"
done

printf 'Terse report: answer first, no filler; code/errors exact.\n' > dist/digest.txt

# Static platforms: full human-readable rules (SKILL.md body minus Claude-only sections).
rules=$(awk 'f&&c>=2{print} /^---$/{c++; f=1; next}' skills/terse/SKILL.md)
static=$(printf '%s\n' "$rules" | awk '/^## Toggle/{skip=1} /^## Persistence/{skip=0} !skip')
{
  echo "# --- terse:begin ---"
  echo "# Managed by Terse (build.sh). Do not edit inside markers."
  printf '%s\n' "$static"
  echo "# --- terse:end ---"
} > platforms/codex/AGENTS.terse.md
{
  echo "---"
  echo "description: Terse efficient-communication rules"
  echo "alwaysApply: true"
  echo "---"
  printf '%s\n' "$static"
} > platforms/cursor/terse.mdc

echo "Built dist/ (inject.default.txt $(wc -c < dist/inject.default.txt)B, inject.small.txt $(wc -c < dist/inject.small.txt)B) + platform artifacts"
