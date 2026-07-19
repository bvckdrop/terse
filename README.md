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

Claude Code gets the full system: session ruleset injection, a ~25-token per-prompt
anchor (survives context compaction), subagent digest propagation (PreToolUse rewrite),
and the `/terse` toggle. Codex and Cursor are static-rule platforms: always-on Charter +
register + ladder inside managed markers (idempotent installs, clean removal).

Source of truth: `skills/terse/SKILL.md`. After editing it, `./build.sh` regenerates
platform artifacts; Claude Code picks it up live through symlinks.

## Uninstall

- Claude Code: remove the three `terse` hook entries from `~/.claude/settings.json`;
  delete symlinks `~/.claude/terse` and `~/.claude/skills/terse`.
- Codex: delete the `# --- terse:begin/end ---` block from `~/.codex/AGENTS.md`.
- Cursor: delete `.cursor/rules/terse.mdc` / remove the User Rules block.
