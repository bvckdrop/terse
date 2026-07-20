# Terse

Efficient communication for AI coding agents: maximum brevity by default, automatic
expansion exactly where compression would risk confusion or errors.

Answer first. Zero filler. Nothing lost that matters.

## The Charter

Four tiers, precedence highest first. Nothing overrides a higher tier — not voices,
not customizations, not future extensions.

1. **Accuracy** — code, commands, errors, paths, identifiers, numbers: byte-exact.
   No invented abbreviations (they save no tokens and cost clarity).
2. **Clarity-on-risk** — the Expansion Ladder always fires: destructive actions,
   security, failures, ambiguity, user confusion, explicit asks, first-mention concepts.
3. **Brevity** — answer-first; budgets (status ≤1 line, success ≤2, diagnosis = cause→fix);
   no preamble, narration, recaps, or unsolicited next-steps.
4. **Voice & customization** — word-choice layers only.

## Voices

| Voice | Character |
|---|---|
| **crisp** (default) | Pure economy. No persona. |
| **buddy** | Subtle camaraderie — warm address, occasional "we". |
| **witty** | Subtle cleverness riding existing analysis. Never manufactures content to be clever. |

One voice active; single intensity; ±10% of crisp's length; never colors warnings,
errors, or destructive confirmations. Toggle: `/terse crisp|buddy|witty`, `/terse off|on`.

## Estimated output-token reduction

Vs. typical unstyled assistant responses (response-shape estimate; measure with `evals/`):

| Voice | Est. reduction |
|---|---|
| crisp | ~55–70% |
| buddy | ~55–65% |
| witty | ~55–65% |

**Measured impact**: run the 10 prompts in `evals/prompts.json` with terse off/on,
record output tokens, fill this table. Prompt 10 verifies safety text is never compressed.

## Customization

Add prose preferences to `custom.md` (see `custom.example.md`): one rule per line,
≤15 words, max 10 rules, word-choice/punctuation/formatting scope only. Rules that
would increase verbosity, weaken accuracy or safety, or override budgets are ignored
by Charter precedence. Oversize files truncate at ~300 tokens with a warning.

## Install

```
./install.sh                    # auto-detect platforms
./install.sh --platform claude  # Claude Code: symlinks + hooks (full dynamic system)
./install.sh --platform codex   # ChatGPT/Codex CLI: managed block in ~/.codex/AGENTS.md
./install.sh --platform cursor [project]  # Cursor: project rule, or paste-ready global block
```

Claude Code marketplace alternative: `/plugin marketplace add bvckdrop/terse`,
then `/plugin install terse@bvckdrop`.

Claude Code gets the full system: compiled ruleset injection at session start
(~400 tokens, precompiled to `dist/` — hooks only `cat`), a cadence-gated anchor
(every 4th prompt, `anchor_every` in `state`), SessionStart re-firing after
compaction (source=compact) so the contract survives it, subagent digest propagation
(PreToolUse rewrite with a pure-bash fast path), and the `/terse` toggle. Codex and
Cursor are static-rule platforms: managed marker blocks, idempotent, clean removal.

Source of truth: `skills/terse/SKILL.md` (+ `models.d/` overlays + adopted
`LEARNINGS.md` entries). After editing any of them, `./build.sh` recompiles `dist/`.

## Model adaptivity & learning

- `models.d/default.md` (frontier models — lean) and `models.d/small.md` (Haiku-class —
  firmer imperatives) compile into per-family rulesets; `model=` in `state` selects.
- `LEARNINGS.md` is the rule-evolution journal: the assistant appends *candidates*
  when style corrections recur; only human-promoted `status=adopted` entries compile
  in, scoped per model family, and `build.sh` auto-rejects anything that would weaken
  Charter tiers 1–3. New model generation? Add an overlay file — nothing else changes.

## Uninstall

```
./install.sh --uninstall                   # all platforms
./install.sh --uninstall claude            # one: claude|codex|cursor
./install.sh --uninstall cursor [project]  # remove a project rule
```

- Marketplace install: `/plugin uninstall terse@bvckdrop`.
- Cursor global User Rules block must be removed by hand (not scriptable).
