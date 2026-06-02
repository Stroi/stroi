# stroi

A **lean software-development agent harness** for Claude Code, packaged as a plugin.

`stroi` is *mechanism, not content*: it gives you tiered planning, command-agnostic
verification, deterministic safety, scoped just-in-time codebase knowledge, docs research, and
a learning ratchet — and **no** domain/language skills. You bring those and bind them per-scope.

It is built to the doctrine in [`HARNESS.md`](./HARNESS.md): *start minimal, earn each piece,
decouple brain/hands/session, Planner→Generator→Evaluator, and ratchet every fix into a control.*

---

## Install

```bash
# from this repo (local marketplace)
/plugin marketplace add /path/to/stroi
/plugin install stroi@stroi

# or point Claude Code at the dir directly while iterating
claude --plugin-dir /path/to/stroi
```

Then confirm: `/stroi:plan-fast`, `/stroi:plan-big`, `/stroi:verify`, `/stroi:analyze`,
`/stroi:learn` appear; the five `stroi-*` agents show under `/agents`; and Context7 is connected
(`/mcp`).

## What you get

### Skills (slash commands)
| Command | Use it for |
|---|---|
| `/stroi:plan-fast <ask>` | Small, well-understood changes. Concise inline plan, low pushback, asks only on a rule conflict or ambiguity. |
| `/stroi:plan-big <goal>` | Complex work. Orchestrated Planner→Generator→Evaluator with a living plan, parallel read-only exploration, sequential dev, independent validation + adversarial review, fixup loop. Resumable across compaction. |
| `/stroi:verify [scope]` | Command-agnostic verification: detects tooling, runs build/typecheck/lint/test/security/diff. Silent on pass. |
| `/stroi:analyze [scope]` | Generate/refresh a scoped `tspec.md` — agent-optimized codebase knowledge, loaded just-in-time. |
| `/stroi:learn "<rule>"` | Ratchet a lesson into a rule (project or global), with an escalation ladder. `--review` reflects on the session. |

### Agents (spawned by `plan-big`)
`stroi-explorer` (read-only mapping) · `stroi-planner` (living plan) · `stroi-developer`
(sequential implementation) · `stroi-validator` (runs verify; can't edit) · `stroi-reviewer`
(adversarial review + standing security dimension; can't edit). All on `opus`; effort `high` for
planner/developer/reviewer, `medium` for explorer/validator.

### Hooks
- **Safety guard** (PreToolUse/Bash) — deterministically blocks catastrophic commands
  (`rm -rf /`, force-push, `mkfs`, `dd`, a DB client running `DROP TABLE`, …). Tight by design.
- **tspec staleness** (PostToolUse + SessionStart) — flags scopes whose `tspec.md` lags behind
  code changes. Detect-only; silent when clean.
- **plan-big handoff** (PreCompact) — snapshots `.stroi/RESUME` so a long run survives compaction.

### Docs research (Context7)
`stroi` bundles the Context7 MCP server. `/stroi:analyze` records each scope's key libraries →
Context7 IDs / doc URLs in the tspec's `Dependencies & Docs`; the planner and developer **consult
current docs before using version-sensitive APIs**, falling back to WebFetch if Context7 is down.

## tspec.md — scoped codebase knowledge

`tspec.md` files describe the codebase for the agent (CLAUDE.md holds the *rules*; tspec holds the
*description*). They are scoped and DRY:

- A **root** `tspec.md` (codebase-wide facts) is `@`-imported by the root `CLAUDE.md` → always loaded.
- A **leaf** `tspec.md` per app/package holds only folder-specific facts → loaded just-in-time when
  you work in that scope (via that scope's nested `CLAUDE.md`).

### Linking a skill to a scope (manual — no command)
Open the scope's `tspec.md` and add a skill ID under `## Relevant Skills`, one per line:

```md
## Relevant Skills
- everything-claude-code:react-native-patterns
- my-rn-a11y-checks
```

Because the tspec loads only in-scope, those skills are applied automatically during development,
verification, and review **in that app and nowhere else**. Use `## Code Review` in the same file
for scope-specific review notes. `/stroi:analyze` preserves both blocks across refreshes.

## Runtime artifacts (written into the consuming project)
- `.stroi/plans/<slug>.plan.md` — the living plan for a `plan-big` run (with `## Task Status`).
- `.stroi/RESUME` — resume pointer written by the PreCompact hook.
- `.stroi/dirty.log` — touched-path log feeding staleness detection.
- `<scope>/tspec.md` — the codebase maps.

Add `.stroi/` to your project's `.gitignore` (or commit the plans/tspecs if you want them shared).

## Philosophy
This harness is deliberately small. Add to it only when you hit a real, repeated need — and use
`/stroi:learn` to make each addition traceable. Prune on model upgrades. See `HARNESS.md`.

## License
MIT — see [LICENSE](./LICENSE).
