#!/bin/bash
# Terse — compiler. SKILL.md (+ models.d overlays + adopted LEARNINGS) →
#   dist/inject.<family>.txt   compact session ruleset (~330 tokens vs ~900 raw)
#   dist/digest.txt            subagent digest line
#   platforms/codex, cursor    static artifacts
# Deterministic: same inputs → identical outputs. Runtime hooks only cat dist/.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p dist

ver="1.3.18"

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
VOICES: crisp = none. auto = pick per response from prompt tone: celebratory/casual = buddy, playful = witty, neutral/technical or ambiguous = crisp. buddy = casual supportive interjections on wins ("Cool", "Sweet", "Right on") and friendly word choice; no "we"/"our". witty = clever only where it fits and lightens the moment, zero decoding cost, never imagery that could misread; when in doubt drop the wit (good: "All 42 passed — no slouch."). Both layer lightly — balanced between crisp and the voice, never overdone, and always the shorter phrasing when one exists. Within 10% of crisp length; never colors warnings, errors, or code.
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
  } > "dist/claude-code-inject.$fam.txt"
done

printf 'Terse report: answer first, no filler; code/errors exact.\n' > dist/claude-code-subagent-digest.txt

cat > dist/claude-code-help.txt <<EOF
Terse v$ver — efficient communication: terse by default, expands on risk.
  /terse on|off              enable / disable (the Charter is not toggleable)
  /terse crisp|buddy|witty|auto  set voice; auto adapts to prompt tone per response
  /terse help                this reference
  /terse upgrade             rebuild and adopt the latest ruleset mid-session
  /terse learn <feedback>    record a candidate rule; auto-vets, flags conflicts
  /terse learn               list candidates awaiting adopt/reject
    adopt                    promote a candidate into the injected ruleset
    reject <rule>            delete a candidate (no rejection history kept)
  /terse prune               sweep entries hand-marked status=rejected
  /terse consolidate         graduate long-lived adopted rules into core
Voices by example (auto picks per response from prompt tone):
  crisp  Deployed. Icon shows on device.        All 42 passed.
  buddy  Sweet — deployed, icon shows.          Cool, all 42 passed.
  witty  Deployed — icon made the home screen.  All 42 passed — no slouch.
  Warnings, errors, and destructive confirms: identical in every voice.
State: ~/.claude/terse/state — mode=on|off, voice=crisp|buddy|witty|auto,
anchor_every=<n>, model=auto|default|small (auto detects; haiku → small).
Journal: LEARNINGS.md. Rules: SKILL.md.
EOF

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

# Claude Desktop skill: SKILL.md folder zipped for upload via
# Settings → Capabilities → Skills. No hooks/state on Desktop — voice and
# on/off live in the conversation, so those sections are replaced.
mkdir -p platforms/claude-desktop/terse
{
  echo "---"
  echo "name: terse"
  echo "description: \"Efficient-communication mode: terse by default, automatic expansion where compression risks confusion or errors. Voices: crisp (default), buddy, witty, auto. Use when the user asks for brevity, invokes terse mode, changes voice, or complains about verbosity.\""
  echo "---"
  printf '%s\n' "$static" | awk '/^## Persistence/{exit} {print}'
  cat <<'DESK'
## Toggles (conversation-scoped — Desktop has no state file)

Mode and voice are set in chat: "terse: buddy voice", "terse: auto voice",
"terse off". Default voice: crisp. Settings hold for the conversation and
re-assert after context compaction. The Charter is not toggleable.

## Persistence

Active every response once invoked. No drift toward verbosity in long
conversations. Off only when the user says so.
DESK
} > platforms/claude-desktop/terse/SKILL.md
rm -f dist/terse-claude-desktop-skill.zip
(cd platforms/claude-desktop && zip -qr ../../dist/terse-claude-desktop-skill.zip terse)

# Claude Desktop / Cowork plugin: manifest + the desktop skill, zipped as a
# .plugin file — drop it into a Cowork chat to install. Skills-only: the
# hook/state machinery is Claude Code-side.
PDIR=platforms/claude-desktop/plugin
rm -rf "$PDIR"
mkdir -p "$PDIR/.claude-plugin" "$PDIR/skills/terse"
cat > "$PDIR/.claude-plugin/plugin.json" <<EOF
{
  "name": "terse",
  "version": "$ver",
  "description": "Efficient-communication mode: terse by default, automatic expansion where compression risks confusion or errors. Voices: crisp, buddy, witty, auto.",
  "author": { "name": "bvckdrop" },
  "license": "MIT"
}
EOF
cp platforms/claude-desktop/terse/SKILL.md "$PDIR/skills/terse/SKILL.md"
cat > "$PDIR/README.md" <<'EOF'
# Terse

Efficient-communication mode for Claude: answer-first, minimal by default,
with an expansion ladder that fires automatically wherever compression would
risk confusion or errors (destructive actions, security, failures, ambiguity).
Voices: crisp (default), buddy, witty, auto. Toggle in conversation:
"terse: buddy voice", "terse off". Compiled from the Terse repo by build.sh.
EOF
rm -f dist/terse-claude-desktop.plugin
(cd "$PDIR" && zip -qr ../../../dist/terse-claude-desktop.plugin . -x "*.DS_Store")

# Claude Desktop paste-ready layers: always-on preferences baseline, a custom
# Style, and full project instructions. Preferences guarantee the floor,
# the Style shapes every reply, the skill carries the full ladder.
cat > dist/claude-desktop-preferences.txt <<'EOF'
Communicate with maximum economy: answer first — verdict or result in the
first sentence; detail only if it changes my next action. Status updates 1
line; success reports 2 lines; diagnosis = cause, then fix. Cut preamble,
pleasantries, hedging, filler, recaps, unsolicited next steps, and decorative
structure on short content. Short sentences, common words, grammar intact.
Keep code, commands, error strings, paths, and numbers byte-exact. Always
expand fully for: destructive or irreversible actions (warn and confirm),
security implications, failures (cause, evidence, fix), genuine ambiguity,
my confusion, or explicit requests to explain. Brevity never overrides
accuracy or risk clarity.
EOF

cat > dist/claude-desktop-style.txt <<'EOF'
Answer-first: verdict in the first sentence. Budgets: status 1 line max,
success 2 lines max, diagnosis is cause then fix. No preamble, filler,
hedging, restated context, or unsolicited next steps; no headers, tables, or
emoji on short answers. Short sentences, common words, complete grammar.
State each fact once. Quote code, commands, errors, paths, and numbers
exactly. Expand only where compression risks harm: destructive actions get a
full-sentence warning and a confirmation ask; security gets a complete
explanation; failures get cause, decisive evidence, and fix; ambiguity gets
written out; an explicit "explain" or "why" gets a teaching register. Default
voice is neutral. If the user asks for "buddy", add light supportive
interjections on wins ("Cool", "Sweet", "Right on"). If "witty", allow clever
phrasing only when it fits the moment, costs zero decoding effort, and never
uses imagery that could misread. Voices never color warnings, errors, or code.
EOF

{
  printf '%s\n' "$static" | awk '/^## Persistence/{exit} {print}'
} > dist/claude-desktop-project-instructions.txt

echo "Built dist/ (claude-code-inject.default.txt $(wc -c < dist/claude-code-inject.default.txt)B, claude-code-inject.small.txt $(wc -c < dist/claude-code-inject.small.txt)B) + platform artifacts + terse-claude-desktop-skill.zip"
