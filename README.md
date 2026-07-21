# Terse

Efficient communication for AI coding agents: answer-first, minimal by default,
automatic expansion where compression would risk confusion or errors.

## Charter

Four tiers; higher always wins.

1. **Accuracy** — code, commands, errors, paths, identifiers, numbers: byte-exact.
   No invented abbreviations.
2. **Clarity-on-risk** — the Expansion Ladder always fires: destructive actions,
   security, failures, ambiguity, user confusion, explicit asks, first-mention concepts.
3. **Brevity** — answer-first; budgets (status ≤1 line, success ≤2, diagnosis = cause→fix);
   no preamble, narration, recaps, or unsolicited next-steps.
4. **Voice & customization** — word choice only.

## Voices

| Voice | Character |
|---|---|
| **crisp** (default) | Pure economy, no persona |
| **buddy** | Light supportive interjections on wins; no "we" |
| **witty** | Clever only where it fits; zero decoding cost |
| **auto** | Picks per response from prompt tone; risk moments always crisp |

±10% of crisp's length; never colors warnings, errors, or code.

Commands: `/terse on|off|crisp|buddy|witty|auto`, `/terse help`,
`/terse upgrade` (reload ruleset in-session), `/terse learn` (distill feedback
into a rule candidate), `/terse prune`, `/terse compress <file>` (shrink a
memory file's input-token cost — see `skills/compress/`; Claude Code only).

## Output-token reduction

~55–70% vs unstyled responses (estimate). Measure: run `evals/prompts.json`
with terse off/on; prompt 10 verifies safety text is never compressed.

## Compress (input-token reduction)

`/terse compress <file>` shrinks a memory file (`CLAUDE.md`, todos,
preferences) so it costs fewer tokens every time it loads — the input-side
complement to the output-side reduction above. Same Charter (accuracy and
clarity outrank brevity) — grammar and articles stay intact, never stripped
for extra compression. Original is never lost: an out-of-tree backup is
kept, editable, and never clobbered on rerun. Code, URLs, paths, commands,
and structure are preserved exactly — only prose is rewritten. Claude Code
only (needs Bash + Python 3; Codex, Cursor, and Desktop can't run the
validator scripts). See `skills/compress/SKILL.md`.

Measure: `pip install -r skills/compress/scripts/requirements.txt`
(optional — accurate token counts via tiktoken; falls back to word count
without it), then `python3 skills/compress/scripts/benchmark.py` from the
repo root, against `evals/compress-samples/`.

## Customization

`custom.md` (see `custom.example.md`): ≤10 rules, ≤15 words each,
word-choice/punctuation/formatting scope only. Charter precedence ignores
anything that would increase verbosity or weaken accuracy, safety, or budgets.

## Install

```
./install.sh                    # auto-detect platforms
./install.sh --platform claude  # Claude Code: symlinks + hooks (full dynamic system)
./install.sh --platform codex   # ChatGPT/Codex CLI: managed block in ~/.codex/AGENTS.md
./install.sh --platform cursor [project]  # Cursor: project rule, or paste-ready global block
```

Claude Code marketplace: `/plugin marketplace add bvckdrop/terse`, then
`/plugin install terse@bvckdrop`.

Claude Desktop / Cowork: `./build.sh`, then upload
`dist/terse-claude-desktop-skill.zip` (Settings → Capabilities → Skills) or drop
`dist/terse-claude-desktop.plugin` into a Cowork chat. Skills-only — no hooks or state.

Claude Code runs the full dynamic system: compiled ruleset injection at session
start (~400 tokens), cadence-gated anchor, re-injection after compaction,
subagent digest propagation, `/terse` toggle. Codex, Cursor, and Desktop are
static-rule platforms: managed blocks, idempotent, clean removal.

Source of truth: `skills/terse/SKILL.md` + `models.d/` overlays + adopted
`LEARNINGS.md` entries. After editing any of them, `./build.sh` recompiles `dist/`.

## Model adaptivity & learning

- `models.d/default.md` (frontier models) and `models.d/small.md` (Haiku-class)
  compile into per-family rulesets; family auto-detected per session, `model=`
  in `state` forces.
- `LEARNINGS.md` is the rule-evolution journal: the assistant appends candidates
  when style corrections recur; only human-promoted `status=adopted` entries
  compile in. `build.sh` rejects anything that would weaken tiers 1–3.
  New model generation: add an overlay file.

## Uninstall

```
./install.sh --uninstall                   # all platforms
./install.sh --uninstall claude            # one: claude|codex|cursor
./install.sh --uninstall cursor [project]  # remove a project rule
```

- Marketplace install: `/plugin uninstall terse@bvckdrop`.
- Cursor global User Rules block must be removed by hand (not scriptable).
