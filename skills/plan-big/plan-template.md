<!--
  stroi living plan — written by stroi-planner, executed by stroi-developer, judged by
  stroi-validator + stroi-reviewer. The "## Task Status" checklist is the DURABLE, RESUMABLE
  state: the developer flips - [ ] to - [x] as tasks complete; the PreCompact hook points
  .claude/stroi/RESUME at the first unchecked task. One plan per feature:
  .claude/stroi/plans/<slug>.plan.md
-->
# Plan: <title>
last-updated: <ISO date — from the caller/git, never invented>

## Goal & Definition of Done
<the goal, and the concrete, checkable conditions that mean "done">

## NOT Building
<explicit scope boundaries — what this plan deliberately excludes>

## Patterns to Mirror
- `path` — <the existing pattern/utility to copy instead of inventing a new one>

## Dependencies & Docs
- `<lib>@<version>` → ctx7: `</org/lib>` (docs consulted: <url>)

## Task Status
- [ ] 1. <task> — files: `...`; mirror: `path`; verify: `<check>`
- [ ] 2. ...

## Validation Commands
- build / typecheck / lint / test for this scope

## Review Rubric
- <concrete pass/fail criteria the reviewer will judge against>
