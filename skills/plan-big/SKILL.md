---
name: plan-big
description: Orchestrated planning + execution for complex, multi-component work. Runs Planner→Generator→Evaluator with a living plan, parallel read-only exploration, sequential development, independent validation + adversarial review, and a fixup loop. Resumable across compaction. Use for features/refactors that need design and coordination.
---

# /stroi:plan-big — orchestrated planning & execution

For genuinely complex work. You (the main agent) are the **orchestrator**: you drive the phases
and spawn `stroi-*` subagents via the Task tool. Development is **sequential**; parallelism is for
**read-only** work only (exploration, validation, review). `$ARGUMENTS` = the goal.

## Phase 0 — Resume check
If `.stroi/RESUME` exists, or a recent `.stroi/plans/*.plan.md` has unchecked `- [ ]` tasks, offer
to **resume** from the first incomplete task instead of starting over. (The PreCompact hook writes
`.stroi/RESUME`; the living plan's `## Task Status` is the durable state.)

## Phase 1 — Sprint contract
Clarify the goal and write an explicit **definition of done** up front. If the work is actually
small, stop and recommend `/stroi:plan-fast`.

## Phase 2 — Explore (parallel, read-only)
Spawn up to 3 `stroi-explorer` agents (seeded by in-scope tspecs) to map the areas involved. They
only read. Collect their reports.

## Phase 3 — Plan (living doc)
Spawn `stroi-planner` to write `.stroi/plans/<slug>.plan.md` (goal & definition of done, NOT
building, patterns to mirror, Dependencies & Docs, a `## Task Status` checklist, validation
commands, review rubric). The planner researches docs (Context7) before designing against APIs.
Use `plan-template.md` as the structure.

## Phase 4 — Develop (sequential)
Spawn `stroi-developer` to work the plan task-by-task with a per-task validation loop, applying the
scope's tspec `Relevant Skills`, and flipping `## Task Status` to `- [x]` as it goes. It reports
back; it does **not** self-grade.

## Phase 5 — Validate + review (parallel, read-only, INDEPENDENT)
Spawn together, in fresh context separate from the developer:
- `stroi-validator` → runs the `verify` loop.
- `stroi-reviewer` → reviews against the plan's rubric + the standing security dimension + the
  in-scope tspec `Relevant Skills` / `Code Review` notes.

## Phase 6 — Fixup loop
If validator/reviewer report issues, spawn `stroi-developer` again to address them, then
re-validate. Repeat until clean or clearly plateaued (then surface the remaining items to the user).

## Phase 7 — Refresh tspec (mandatory)
Run `/stroi:analyze` on each touched scope to update its `tspec.md` + `last-synced`, then clear its
dirty marker.

## Phase 8 — Close
Append outcomes (what worked / what failed) to the plan. Surface Ratchet candidates for
`/stroi:learn` (conventions you saw violated, corrections repeated).

## Rules
- Decompose so each unit is independently verifiable; preserve coherence by doing one unit at a time.
- Never let the generator grade itself — validation and review are **separate** agents.
- Parallelism is for READ-ONLY work only. Do not run parallel writers (shared-tree conflicts).
