<!--
  stroi living plan — DASHBOARD format. Written by stroi-planner, executed checkpoint-by-
  checkpoint by stroi-developer, gated by the orchestrator after each checkpoint, then judged
  by stroi-validator + stroi-reviewer. Lives OUTSIDE the repo at
    $STROI/plans/<slug>.plan.md   (STROI = ~/.claude/stroi/<dashified-project-dir>)
  one file per feature.

  DURABLE STATE = the "- [ ]" task lines under each checkpoint. The developer flips - [ ] to
  - [x] as tasks complete; the PreCompact hook points $STROI/RESUME at the first unchecked task.
  Keep tasks as a "- [ ]" LIST (never a table row) — the hooks grep for exactly that pattern.

  CHECKPOINTS are the gate boundaries: each "### CP<n>" groups 1–4 related tasks plus one fast
  `verify:` smoke command the orchestrator runs (itself) before advancing to the next checkpoint.

  Only CHECKPOINT TASKS use "- [ ]". The Review Rubric uses plain "- " bullets on purpose — a
  "- [ ]" there would read as an unfinished task and stop cleanup/handoff from ever closing the plan.

  STYLE = caveman-terse. Tables and fragments over prose. No filler, no hedging.
-->
# 📐 <title>

| Field | |
| --- | --- |
| Goal | <one-line goal> |
| Done when | <concrete, checkable conditions> |
| Scope | <N> files · <M> tasks · <K> checkpoints |
| Risk | low / medium / high — <one clause why> |
| Updated | <ISO date — from git/caller, never invented> |

## ⛔ Not Building
- <explicit scope boundary> · <another>

## ♻️ Reuse
| Copy from | For |
| --- | --- |
| `path` | <existing pattern/utility to copy instead of inventing> |

## 📦 Deps & Docs
| Lib | Ver | Docs |
| --- | --- | --- |
| `<lib>` | <version> | ctx7 `</org/lib>` · <doc url consulted> |

## 🚦 Checkpoints — gate must be green to advance
### CP1 · <milestone name>   verify: `<fast smoke cmd>`
- [ ] 1. <task> — `file` · reuse `path`
- [ ] 2. <task> — `file`
### CP2 · <milestone name>   verify: `<fast smoke cmd>`
- [ ] 3. <task> — `file`

## 🧪 Final Validation
build · typecheck · lint · test  — the full independent pass over the whole change

## ⚖️ Review Rubric
- <concrete pass/fail criterion the reviewer judges against>  (plain bullets — never `- [ ]`)
