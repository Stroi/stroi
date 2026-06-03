---
name: plan-big
description: Orchestrated planning + execution for complex, multi-component work. Writes a living plan, STOPS for your approval, then runs Planner→Generator→Evaluator with sequential development, independent validation + adversarial review, and a fixup loop. Resumable across compaction. Use for features/refactors that need design and coordination.
---

# /stroi:plan-big — orchestrated planning & execution

For genuinely complex work. You (the main agent) are the **orchestrator**: you drive the phases
and spawn `stroi-*` subagents via the Task tool. Development is **sequential**; parallelism is for
**read-only** work only (exploration, validation, review). `$ARGUMENTS` = the goal.

> **Approval gate (hard rule).** This skill behaves like plan mode: planning (explore + write the
> plan) runs autonomously, but **execution does not**. After the plan is written you **stop and wait**
> for the user to approve or edit it. Never spawn the developer or touch code before explicit approval.

## Phase 0 — Resume check
If `.claude/stroi/RESUME` exists, or a recent `.claude/stroi/plans/*.plan.md` has unchecked `- [ ]`
tasks, offer to **resume** from the first incomplete task instead of starting over. (The PreCompact
hook writes `.claude/stroi/RESUME`; the living plan's `## Task Status` is the durable state.)

## Phase 1 — Sprint contract
Clarify the goal and write an explicit **definition of done** up front. If the work is actually
small, stop and recommend `/stroi:plan-fast`.

## Phase 2 — Explore (parallel, read-only)
Spawn up to 3 `stroi-explorer` agents (seeded by in-scope `CLAUDE.md` map blocks) to map the areas
involved. They only read. Collect their reports.

## Phase 3 — Plan (living doc)
Spawn `stroi-planner` to write `.claude/stroi/plans/<slug>.plan.md` (goal & definition of done, NOT
building, patterns to mirror, Dependencies & Docs, a `## Task Status` checklist, validation
commands, review rubric). The planner researches docs (Context7) before designing against APIs.
Use `plan-template.md` as the structure.

## Phase 4 — Approve (STOP — wait for the user)
Present the plan: its path plus a concise summary (goal, definition of done, the `## Task Status`
task list, validation commands). Then **end your turn and wait.** Do **not** proceed to development
until the user explicitly approves.
- If the user requests changes, revise the plan (re-spawn `stroi-planner` or edit the file
  directly), re-present, and wait again. Loop until approved.
- Only an explicit go-ahead unlocks Phase 5.

## Phase 5 — Develop (sequential)
Spawn `stroi-developer` to work the **approved** plan task-by-task with a per-task validation loop,
applying the scope's `CLAUDE.md` `Relevant Skills`, and flipping `## Task Status` to `- [x]` as it
goes. It reports back; it does **not** self-grade.

## Phase 6 — Validate + review (parallel, read-only, INDEPENDENT)
Spawn together, in fresh context separate from the developer:
- `stroi-validator` → runs the `verify` loop.
- `stroi-reviewer` → reviews against the plan's rubric + the standing security dimension + the
  in-scope `CLAUDE.md` `Relevant Skills` / `Code Review` notes.

## Phase 7 — Fixup loop
If validator/reviewer report issues, spawn `stroi-developer` again to address them, then
re-validate. Repeat until clean or clearly plateaued (then surface the remaining items to the user).

## Phase 8 — Refresh the CLAUDE.md map (mandatory)
Run `/stroi:analyze` on each touched scope to refresh its `CLAUDE.md` map block + `last-synced`,
then clear its dirty marker.

## Phase 9 — Close
Append outcomes (what worked / what failed) to the plan, then **delete the finished run's**
`.claude/stroi/plans/<slug>.plan.md` and `.claude/stroi/RESUME` — the work is done and these are
throwaway. (The SessionEnd hook also clears completed plans + RESUME as a safety net; in-progress
plans are kept for resume.) Surface Ratchet candidates for `/stroi:learn` (conventions you saw
violated, corrections repeated).

## Rules
- **Approval before execution.** Never begin development before the user approves the plan (Phase 4).
- Decompose so each unit is independently verifiable; preserve coherence by doing one unit at a time.
- Never let the generator grade itself — validation and review are **separate** agents.
- Parallelism is for READ-ONLY work only. Do not run parallel writers (shared-tree conflicts).
