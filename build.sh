#!/bin/bash
# Terse — regenerate platform artifacts from skills/terse/SKILL.md.
# Deterministic: same input → identical output.
set -euo pipefail
cd "$(dirname "$0")"

rules=$(awk 'f&&c>=2{print} /^---$/{c++; f=1; next}' skills/terse/SKILL.md)
# Static platforms get the always-on portions; the /terse toggle section is
# Claude-Code-specific and stripped.
static=$(printf '%s\n' "$rules" | awk '/^## Toggle/{skip=1} /^## Persistence/{skip=0} !skip')

# ChatGPT / OpenAI Codex CLI — managed AGENTS.md block
{
  echo "# --- terse:begin ---"
  echo "# Managed by Terse (build.sh). Do not edit inside markers."
  printf '%s\n' "$static"
  echo "# --- terse:end ---"
} > platforms/codex/AGENTS.terse.md

# Cursor — always-on project rule
{
  echo "---"
  echo "description: Terse efficient-communication rules"
  echo "alwaysApply: true"
  echo "---"
  printf '%s\n' "$static"
} > platforms/cursor/terse.mdc

echo "Built: platforms/codex/AGENTS.terse.md, platforms/cursor/terse.mdc"
