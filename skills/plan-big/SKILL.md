---
name: plan-big
description: Orchestrated planning + execution for complex, multi-component work. Writes a living plan, STOPS for your approval, then runs Planner→Generator→Evaluator — development advances checkpoint by checkpoint with a verify gate between each, then independent validation + adversarial review and a fixup loop. Resumable across compaction. Use for features/refactors that need design and coordination.
---

# /stroi:plan-big — orchestrated planning & execution

For genuinely complex work. You (the main agent) are the **orchestrator**: you drive the phases
and spawn `stroi-*` subagents via the Task tool. Development is **sequential**; parallelism is for
**read-only** work only (exploration, validation, review). `$ARGUMENTS` = the goal.

> **Approval gate (hard rule).** This skill behaves like plan mode: planning (explore + write the
> plan) runs autonomously, but **execution does not**. After the plan is written you **stop and wait**
> for the user to approve or edit it. Never spawn the developer or touch code before explicit approval.

## Phase 0 — Resolve runtime, then resume check
stroi's runtime lives **outside the repo**. Resolve it once and reuse it as `$STROI`:

```bash
echo "$HOME/.claude/stroi/$(printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}" | sed 's#[^A-Za-z0-9]#-#g')"
```

(Same formula as `hooks/scripts/_paths.sh` — keep them in sync.) All plan files and the RESUME
pointer live under `$STROI/`; nothing stroi-written lands in the project tree.

If `$STROI/RESUME` exists, or a recent `$STROI/plans/*.plan.md` has unchecked `- [ ]` tasks, offer
to **resume**: find the first unchecked task, identify the **checkpoint** it belongs to, and
re-enter the Phase 5 loop at that checkpoint instead of starting over. (The PreCompact hook writes
`$STROI/RESUME`; the living plan's checkpoint tasks are the durable state.)

## Phase 1 — Sprint contract
Clarify the goal and write an explicit **definition of done** up front. If the work is actually
small, stop and recommend `/stroi:plan-fast`.

## Phase 2 — Explore (parallel, read-only)
Spawn up to 3 `stroi-explorer` agents (seeded by in-scope `CLAUDE.md` map blocks) to map the areas
involved. They only read. Collect their reports.

## Phase 3 — Plan (living doc)
Spawn `stroi-planner` to write `$STROI/plans/<slug>.plan.md` in the **Dashboard** format of
`plan-template.md`: header table, Not Building, Reuse (patterns to copy), Deps & Docs, then
**`## 🚦 Checkpoints`** — tasks grouped into checkpoints (1–4 tasks each), every checkpoint
carrying a fast `verify:` smoke command — plus Final Validation and a review rubric. Pass the
planner the resolved `$STROI/plans/<slug>.plan.md` path. The planner researches docs (Context7)
before designing against APIs.

## Phase 4 — Approve (STOP — wait for the user)
Present the plan: its path plus a concise summary (goal, definition of done, the **checkpoints**
with their tasks and verify gates). Then **end your turn and wait.** Do **not** proceed to
development until the user explicitly approves.
- If the user requests changes, revise the plan (re-spawn `stroi-planner` or edit the file
  directly), re-present, and wait again. Loop until approved.
- Only an explicit go-ahead unlocks Phase 5.

## Phase 5 — Develop (checkpoint loop, sequential)
Work the **approved** plan one **checkpoint** at a time. For each `### CP` in order:

1. **Build it.** Spawn `stroi-developer` scoped to *this checkpoint's tasks only*, applying the
   scope's `CLAUDE.md` `Relevant Skills`. It implements, self-checks each task, flips that task's
   `- [ ]` → `- [x]`, and reports back. It does **not** self-grade the checkpoint.
2. **Gate it (independent of the developer).** *You*, the orchestrator, run the checkpoint's
   `verify:` command via Bash — fresh, not the developer's say-so. This is the gate.
3. **Green → advance.** Print one status line and move to the next checkpoint automatically:
   `✓ CP<k> <name> — tasks <ids> done, gate \`<cmd>\` green`. No pause; no waiting.
4. **Red → fix before advancing.** Print `✗ CP<k> <name> — gate red: <short reason>`, re-spawn
   `stroi-developer` with the failure output to fix *this* checkpoint, then re-run the gate.
   Repeat until green or clearly plateaued (then stop and surface the blocker to the user).
   **Never carry a broken checkpoint forward.**

This per-checkpoint gate is a fast smoke test that catches breakage early; the thorough,
independent judgment still happens once over the whole change in Phase 6.

> **Fallback.** If the plan has no `### CP` sections (an old or hand-written plan), treat the whole
> task list as a single checkpoint gated by the plan's Final Validation commands.

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
`$STROI/plans/<slug>.plan.md` and `$STROI/RESUME` — the work is done and these are throwaway, and
they live outside the repo so nothing lingers in the tree. (The SessionEnd hook also clears
completed plans + RESUME as a safety net; in-progress plans are kept for resume.) Surface Ratchet
candidates for `/stroi:learn` (conventions you saw violated, corrections repeated).

## Rules
- **Approval before execution.** Never begin development before the user approves the plan (Phase 4).
- Decompose so each unit is independently verifiable; preserve coherence by doing one checkpoint at a time.
- **Gate every checkpoint yourself** before advancing — the developer never grades its own checkpoint, and a red gate is fixed, not carried forward.
- Never let the generator grade itself — validation and review are **separate** agents.
- Parallelism is for READ-ONLY work only. Do not run parallel writers (shared-tree conflicts).
