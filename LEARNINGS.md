# Learnings — rule evolution journal

Append-only. Entries become active ONLY when status=adopted and `build.sh` runs
(adopted rules compile into dist/; candidates are never injected). Promotion or
rejection is a human decision. The Charter gate applies: any entry that would
weaken tiers 1–3 (accuracy, risk-clarity, brevity) is auto-rejected by build.sh.

Format (one block per entry):

    ## 2026-07-19 model=<family|all> status=candidate|adopted|rejected
    observation: <what happened / what the user corrected>
    rule: <one imperative line, ≤20 words>
    scope: core|models.d/<family>

## Graduation policy

Learned rules graduate to SKILL.md core during a consolidation pass — user-invoked
(`/terse consolidate`) or proposed by the assistant at ≥5 adopted entries.
A rule graduates only when ALL hold:
1. Survived ≥30 days (or ~20 sessions) adopted without amendment, contradiction,
   or repeat correction.
2. No conflicts surfaced with other rules or Charter tiers in practice.
3. scope=core — model-scoped rules never graduate; they live in models.d/.
4. The user approves the graduation batch.

Graduation: merge rule text into SKILL.md, set entry status=graduated (kept for
provenance, no longer compiled from the journal), run build.sh.

<!-- entries below -->

## 2026-07-19 model=all status=adopted
observation: Tool-call description "Inspecting app iconset with system ls" — mechanism is noise in any voice.
rule: All prose: name action and target only; omit mechanism and implementation detail unless clarity requires it.
scope: core
