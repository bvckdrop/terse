---
name: compress
description: >
  Compress natural language memory files (CLAUDE.md, todos, preferences) to cut
  the input tokens they cost on every session start. Preserves all technical
  substance, code, URLs, and structure exactly; only prose is rewritten.
  Compressed version overwrites the original file; a human-readable backup is
  kept out-of-tree. Trigger: /terse compress FILEPATH or "compress this memory
  file" / "shrink my CLAUDE.md".
---

# Compress

Shrink a memory file's *input*-token cost the way `terse` shrinks a
response's *output*-token cost. Same Charter, same precedence, applied to a
static file instead of a live reply:

1. **Accuracy** — code, commands, error strings, paths, identifiers, numbers,
   URLs, structure: byte-exact, always.
2. **Clarity** — when compression would risk confusion, ambiguity, or a
   lower-quality memory, keep the fuller phrasing. Token savings never
   outrank the file still being an accurate, unambiguous instruction set.
3. **Brevity** — cut filler, hedging, pleasantries, redundant phrasing.

Dropping articles and conjunctions for a few more percent of compression
trades accuracy for brevity — the wrong tier to sacrifice. Fragments are
fine where a fragment reads unambiguously on its own; keep full clauses
(articles included) wherever dropping them would blur ordering, negation,
or scope.

## Trigger

`/terse compress <filepath>`, or when the user asks to compress/shrink a
memory file, todo list, or preferences doc.

## Process

The helper scripts live in `scripts/`, adjacent to this SKILL.md — no LLM
calls happen inside them; they only do the deterministic parts (classify,
guard, backup, validate). You do the actual compression yourself, inline,
via your normal Read/Edit tools. From the directory containing this
SKILL.md:

1. **Detect.** Run `python3 -m scripts detect <filepath>`.
   - Exit 0 → proceed.
   - Exit 2 → not natural language (code/config); tell the user and stop.
   - Exit 3 → path looks like it holds credentials/secrets; refuse and tell
     the user why. Do not read the file's contents first.
   - Exit 1 → not found, too large (>500KB), or empty; report and stop.

2. **Backup.** Run `python3 -m scripts backup <filepath>`. This writes an
   out-of-tree copy of the file's current contents (or, if one already
   exists from a prior run, leaves it untouched — see Notes) and prints the
   backup path. Report that path to the user; it's their editable original
   going forward.

3. **Compress.** Read the file. Note the exact YAML frontmatter block if
   present (the `---`…`---` at the top) — never rewrite it, only the body
   below it. Rewrite the body's prose per the Compression Rules below, then
   Edit/Write the file with the compressed result.

4. **Validate.** Run `python3 -m scripts validate <backup_path> <filepath>`
   (backup path from step 2, current file from step 3).
   - Exit 0 → done. Report the result (see Report format).
   - Exit 1 → errors printed. Fix only the specific lines/sections named in
     the errors by editing the compressed file directly — do not
     recompress the whole thing. Re-run validate. Retry up to 2 times.
   - Still failing after 2 retries → restore the original from the backup
     path, leave the source file exactly as it was, and report the failure
     with the validation errors. Never leave a file half-compressed.

## Compression Rules

### Preserve exactly (never touch)
- YAML frontmatter (the `---`…`---` block)
- Code blocks (fenced ``` /~~~ and indented)
- Inline code (`` `backtick content` ``)
- URLs and links (full URLs, markdown links)
- File paths (`/src/components/...`, `./config.yaml`)
- Commands (`npm install`, `git commit`, `docker build`)
- Technical terms (library names, API names, protocols, algorithms)
- Proper nouns (project names, people, companies)
- Dates, version numbers, numeric values
- Environment variables (`$HOME`, `NODE_ENV`)
- Markdown structure: headings (exact text), bullet/numbered nesting, tables
  (compress cell text, keep structure)

### Cut (never changes grammar or meaning)
- Filler: just, really, basically, actually, simply, essentially, generally
- Pleasantries: "sure", "certainly", "of course", "happy to", "I'd recommend"
- Hedging: "it might be worth", "you could consider", "it would be good to"
- Redundant phrasing: "in order to" → "to", "make sure to" → "ensure", "the
  reason is because" → "because"
- Connective fluff: "however", "furthermore", "additionally", "in addition"
- "you should", "make sure to", "remember to" — just state the action

### Compress (word choice and redundancy only — keep grammar intact)
- Short synonyms: "big" not "extensive", "fix" not "implement a solution
  for", "use" not "utilize"
- Fragments OK where unambiguous: "Run tests before commit" — but keep full
  clauses (articles included) wherever a fragment would blur ordering,
  negation, or scope
- Merge bullets that say the same thing differently
- Keep one example where multiple examples show the same pattern

If unsure whether something is code or prose, leave it unchanged. If unsure
whether compressing a sentence would create ambiguity, don't compress it.

## Pattern

Original:
> You should always make sure to run the test suite before pushing any
> changes to the main branch. This is important because it helps catch bugs
> early and prevents broken builds from being deployed to production.

Compressed:
> Run the test suite before pushing to main — catches bugs early, prevents
> broken builds in production.

Original:
> The application uses a microservices architecture with the following
> components. The API gateway handles all incoming requests and routes them
> to the appropriate service. The authentication service is responsible for
> managing user sessions and JWT tokens.

Compressed:
> Microservices architecture. The API gateway routes all incoming requests to
> the appropriate service. The auth service manages user sessions and JWT
> tokens.

(Dropping "the" and "to" entirely — "API gateway route all requests to
services" — would compress further but reads as broken and risks
misparsing which service handles what.)

## Boundaries

- ONLY compress natural language files (`.md`, `.txt`, `.rst`, `.typ`,
  `.typst`, `.tex`, extensionless prose)
- NEVER modify: `.py`, `.js`, `.ts`, `.json`, `.yaml`, `.yml`, `.toml`,
  `.env`, `.lock`, `.css`, `.html`, `.xml`, `.sql`, `.sh`
- Mixed content (prose + code): compress only the prose sections; code
  blocks are read-only regions — don't merge sections around them
- Never compress a `*.original.md` backup file
- Refuse anything `scripts/cli.py detect` flags as sensitive (credentials,
  keys, secrets, SSH/AWS/GPG paths) — report the refusal, don't read the
  file first

## Notes

- Backups live out-of-tree (`$XDG_DATA_HOME/terse/compress-backups/...`, or
  the Windows equivalent) so other tools' auto-loaders don't re-ingest a
  sibling `.original.md` as a live memory file.
- Re-running compress after the user has hand-edited the backup works as
  expected: an existing backup is left alone (never clobbered), and the
  current source file is still compressed fresh each time.
- No second LLM call happens anywhere in this flow — you are already the
  model doing the compression, running inside the trusted Claude Code
  harness. There is no API key, no subprocess to a `claude` CLI, and no
  third-party network boundary being crossed; the only risk surface is the
  local file path you were given, which the sensitive-path guard covers.

## Report format

Keep it to the terse Register: one line on success (backup path + rough
token/byte delta if easy to state), cause+fix on failure. Full sentences
only for the failure/refusal cases (Charter tier 2 — this is exactly the
kind of moment the Expansion Ladder exists for).
