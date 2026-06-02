---
name: analyze
description: Generate or refresh an agent-optimized tspec.md for a scope — a high-signal technical map (architecture, entry points, conventions, dependencies + docs) loaded just-in-time when working there. Maintains a root/leaf hierarchy and wires it into CLAUDE.md. Use to onboard a codebase or after structural changes.
---

# /stroi:analyze — scoped codebase technical-spec mapping

Produce or refresh a `tspec.md` — an **agent-optimized** technical map (high signal, *not* an
exhaustive API dump) that loads just-in-time when working in its scope. `tspec.md` describes the
codebase; `CLAUDE.md` holds the rules. Keep the two separate.

`$ARGUMENTS` (optional) = the scope to map (a path). If omitted, map the scope you are working in
(nearest manifest) and/or the repo root.

## Step 1 — Resolve scope(s)
Walk up from the target to the nearest package manifest (`package.json`, `pyproject.toml`,
`go.mod`, `Cargo.toml`, `build.gradle`); that boundary is a **leaf scope**. The repo root is the
**root scope**. In a monorepo there is one `tspec.md` per package plus one at the root.

## Step 2 — Gather (read-only)
Spawn `stroi-explorer` (one per scope; run them in parallel for independent scopes) to map
patterns, entry points, conventions, and integration points, and to list dependencies with
versions from the manifest. Seed it with any existing `tspec.md` so it reports deltas.

## Step 3 — Resolve docs (you, the main agent — explorer is read-only)
For each key dependency the explorer listed, resolve a **Context7 library ID** (resolve the
library id) and/or an official doc URL. These populate `## Dependencies & Docs`. If Context7 is
unavailable, record the doc URL alone.

## Step 4 — Write the tspec, honoring the hierarchy (DRY)
Fill `tspec-template.md` and write `tspec.md` into the scope directory.

- **Root `tspec.md`** — ONLY codebase-wide facts (stack, repo layout, shared conventions, global
  commands, cross-cutting deps). It is `@`-imported by the root `CLAUDE.md`, so it is **always
  loaded** → keep it tight (aim < ~150 lines).
- **Leaf `tspec.md`** — ONLY what is specific to that folder; **never repeat** anything already
  in the root tspec. Loaded just-in-time via the scope's nested `CLAUDE.md` (aim < ~400 lines).
- Stamp `last-synced:` with the current commit short-hash (`git rev-parse --short HEAD`) and/or
  the ISO date. Read it from git — never invent a date.

## Step 5 — Wire into CLAUDE.md (first run in a scope only)
Ensure the scope's `CLAUDE.md` exists (create a lean stub if not) and contains:
- An `@tspec.md` import line, so the map loads with that scope.
- One instruction line: *"When working in this scope, apply the skills under `tspec.md` →
  Relevant Skills, and the `tspec.md` → Code Review notes."*

Do not move rules into the tspec; `CLAUDE.md` stays a checklist.

## Step 6 — Refresh semantics (idempotent)
When a `tspec.md` already exists, regenerate ONLY the descriptive sections and `last-synced`.
**Preserve verbatim** the human-maintained `## Relevant Skills` and `## Code Review` blocks. Then
clear this scope's entries from `.stroi/dirty.log` (the staleness marker).

## Notes
- A wrong tspec is worse than none — record only what you verified; mark uncertainty explicitly.
- `## Relevant Skills` is maintained **by hand** (there is no bind command); the template explains
  the one-ID-per-line format. Because the tspec loads only in-scope, listed skills apply there and
  nowhere else.
