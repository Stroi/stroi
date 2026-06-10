---
name: analyze
description: Generate or refresh an agent-optimized map block inside a scope's CLAUDE.md — a high-signal technical description (architecture, entry points, conventions, dependencies + docs) loaded just-in-time when working there. Maintains a root/leaf hierarchy. Use to onboard a codebase or after structural changes.
---

# /stroi:analyze — scoped codebase mapping inside CLAUDE.md

Produce or refresh the **stroi map block** inside a scope's `CLAUDE.md` — an **agent-optimized**
technical description (high signal, *not* an exhaustive API dump) that loads just-in-time when
working in that scope. The map block **describes** the codebase; the rest of `CLAUDE.md` holds the
**rules**. They are two regions of one file — keep each in its place.

`$ARGUMENTS` (optional) = the scope to map (a path). If omitted, map the scope you are working in
(nearest manifest) and/or the repo root.

## Step 1 — Resolve scope(s)
Walk up from the target to the nearest package manifest (`package.json`, `pyproject.toml`,
`go.mod`, `Cargo.toml`, `build.gradle`); that boundary is a **leaf scope**. The repo root is the
**root scope**. In a monorepo there is one `CLAUDE.md` map per package plus one at the root.

## Step 2 — Gather (read-only)
Spawn `stroi-explorer` (one per scope; run them in parallel for independent scopes) to map
patterns, entry points, conventions, and integration points, and to list dependencies with
versions from the manifest. Seed it with the existing `CLAUDE.md` map block so it reports deltas.

## Step 3 — Resolve docs (you, the main agent — explorer is read-only)
For each key dependency the explorer listed, resolve a **Context7 library ID** (resolve the
library id) and/or an official doc URL. These populate `## Dependencies & Docs`. If Context7 is
unavailable, record the doc URL alone.

## Step 4 — Write the map block, honoring the hierarchy (DRY)
Fill the map sections from `claude-template.md` and write them **between the markers**
`<!-- stroi:map:start -->` and `<!-- stroi:map:end -->` in the scope's `CLAUDE.md`.

- **Root `CLAUDE.md` map** — ONLY codebase-wide facts (stack, repo layout, shared conventions,
  global commands, cross-cutting deps). The root `CLAUDE.md` is **always loaded** → keep the map
  tight (aim < ~150 lines).
- **Leaf `CLAUDE.md` map** — ONLY what is specific to that folder; **never repeat** anything
  already in the root map. Loaded just-in-time when you work in that subtree (aim < ~400 lines).
- Stamp `last-synced:` (inside the block) with the current commit short-hash
  (`git rev-parse --short HEAD`) and/or the ISO date. Read it from git — never invent a date.

## Step 5 — Place the block (idempotent refresh)
Apply exactly one case:

1. **No `CLAUDE.md` in scope** → create one from `claude-template.md`: a title, the filled map
   block, and empty `## Relevant Skills` / `## Code Review` sections. Add a lean rules stub only
   if helpful.
2. **`CLAUDE.md` has the markers** → replace ONLY the text between `<!-- stroi:map:start -->` and
   `<!-- stroi:map:end -->`. Leave everything else byte-for-byte unchanged.
3. **`CLAUDE.md` exists without the markers** (a hand-written rules file) → insert the marked map
   block, preserving all existing content: place it after any top-of-file rules and before
   `## Relevant Skills` / `## Code Review` if those exist, else append it. Never rewrite hand content.

Then clear this scope's entries from stroi's dirty log (best-effort staleness marker), which lives
outside the repo at `$STROI/dirty.log` where
`$STROI = ~/.claude/stroi/$(printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}" | sed 's#[^A-Za-z0-9]#-#g')`.

## Notes
- **The map block is the only thing you own.** Never touch the rules region or the hand-maintained
  `## Relevant Skills` / `## Code Review` sections — they live outside the markers and are preserved
  across every refresh. Do not move rules into the map; `CLAUDE.md`'s rules stay a checklist.
- A wrong map is worse than none — record only what you verified; mark uncertainty explicitly.
- `## Relevant Skills` is maintained **by hand** (there is no bind command); the template explains
  the one-ID-per-line format. Because the map loads only in-scope, listed skills apply there and
  nowhere else.
