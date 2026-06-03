---
name: plan-fast
description: Lightweight planning for small, well-understood changes (small fixes, minor refactors). Produces a concise inline plan, low pushback, and only asks when it finds a convention violation or real ambiguity. Use when you already know what to do.
---

# /stroi:plan-fast — lean planning

For changes where you already know what to do. Produce a tight plan, then proceed — minimal
ceremony, low pushback. `$ARGUMENTS` = the change request.

## Do
1. **Restate** the request in ≤3 bullets so intent is explicit.
2. **Quick rule check** — read the in-scope `CLAUDE.md` (its rules and stroi map block) and scan
   for obvious conflicts with existing patterns. If the change touches a version-sensitive library
   API, do a quick docs check via the map's `Dependencies & Docs` pointers (Context7 → WebFetch).
3. **Concise plan** — a short ordered list of edits (files + what changes). No living-plan file,
   no orchestration, no subagents.
4. **Proceed** — implement directly (subject to normal permissions), matching surrounding code.

## Ask only when
- A step would violate a stated convention or break an existing pattern, **or**
- the request is genuinely ambiguous.

Otherwise do not push back or brainstorm — that is `/stroi:plan-big`'s job.

## Boundaries
- Trivial single-file change → state intent in one line and proceed (after the rule check).
- If it turns out to span many modules / needs design or independent review → stop and recommend
  `/stroi:plan-big`.
- **CLAUDE.md map:** do not refresh it unless the change altered structure (a new module/dir/entry
  point); the PostToolUse hook records touched paths, so drift is flagged next session regardless.
- **Model:** this is the one flow where a faster model is appropriate — it spawns no agents.
