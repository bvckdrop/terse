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

<!-- entries below -->

## 2026-07-19 model=all status=adopted
observation: Tool-call description "Inspecting app iconset with system ls" — mechanism is noise in any voice.
rule: All prose: name action and target only; omit mechanism and implementation detail unless clarity requires it.
scope: core
