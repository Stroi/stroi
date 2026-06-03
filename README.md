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
# from GitHub (recommended)
/plugin marketplace add https://github.com/Stroi/stroi
/plugin install stroi@stroi
```

While iterating on a local checkout instead:

```bash
git clone https://github.com/Stroi/stroi
/plugin marketplace add ./stroi      # the cloned directory
# or point Claude Code at it directly:
claude --plugin-dir ./stroi
```

Then confirm: `/stroi:plan-fast`, `/stroi:plan-big`, `/stroi:verify`, `/stroi:analyze`,
`/stroi:learn` appear; the five `stroi-*` agents show under `/agents`; and Context7 is connected
(`/mcp`).

## What you get

### Skills (slash commands)
| Command | Use it for |
|---|---|
| `/stroi:plan-fast <ask>` | Small, well-understood changes. Concise inline plan, **presented for your approval** before editing. Low pushback. |
| `/stroi:plan-big <goal>` | Complex work. Writes a living plan and **waits for your approval/edits** (like plan mode) before building. Then Planner→Generator→Evaluator: parallel read-only exploration, sequential dev, independent validation + adversarial review, fixup loop. Resumable across compaction. |
| `/stroi:verify [scope]` | Command-agnostic verification: detects tooling, runs build/typecheck/lint/test/security/diff. Silent on pass. |
| `/stroi:analyze [scope]` | Generate/refresh a scoped `CLAUDE.md` map block — agent-optimized codebase knowledge, loaded just-in-time. |
| `/stroi:learn "<rule>"` | Ratchet a lesson into a rule (project or global), with an escalation ladder. `--review` reflects on the session. |

### Agents (spawned by `plan-big`)
`stroi-explorer` (read-only mapping) · `stroi-planner` (living plan) · `stroi-developer`
(sequential implementation) · `stroi-validator` (runs verify; can't edit) · `stroi-reviewer`
(adversarial review + standing security dimension; can't edit). All on `opus`; effort `high` for
planner/developer/reviewer, `medium` for explorer/validator.

### Hooks
- **Safety guard** (PreToolUse/Bash) — deterministically blocks catastrophic commands
  (`rm -rf /`, force-push, `mkfs`, `dd`, a DB client running `DROP TABLE`, …). Tight by design.
- **CLAUDE.md map staleness** (PostToolUse + SessionStart) — flags scopes whose `CLAUDE.md` map
  block lags behind code changes. Detect-only; silent when clean.
- **plan-big handoff** (PreCompact) — snapshots `.claude/stroi/RESUME` so a long run survives compaction.
- **plan-big cleanup** (SessionEnd) — clears `.claude/stroi/RESUME` and completed plans at session
  end so finished runs don't linger; in-progress plans are kept for resume.

### Docs research (Context7)
`stroi` bundles the Context7 MCP server. `/stroi:analyze` records each scope's key libraries →
Context7 IDs / doc URLs in the `CLAUDE.md` map's `Dependencies & Docs`; the planner and developer
**consult current docs before using version-sensitive APIs**, falling back to WebFetch if Context7
is down.

## CLAUDE.md — scoped codebase knowledge

Each scope's `CLAUDE.md` carries both the *rules* (a short hand-maintained checklist) **and** a
generated **stroi map block** — an agent-optimized *description* of the scope (architecture, entry
points, conventions, dependencies + docs). `/stroi:analyze` owns only the region between the
`<!-- stroi:map:start -->` / `<!-- stroi:map:end -->` markers; everything else is yours and is
preserved across refreshes. Claude Code's own loading makes this scoped and DRY:

- The **root** `CLAUDE.md` (codebase-wide facts) is always loaded → keep its map tight.
- A **leaf** `CLAUDE.md` per app/package holds only folder-specific facts → loaded just-in-time
  when you work in that subtree.

### Linking a skill to a scope (manual — no command)
Open the scope's `CLAUDE.md` and add a skill ID under `## Relevant Skills` (outside the map
markers), one per line:

```md
## Relevant Skills
- everything-claude-code:react-native-patterns
- my-rn-a11y-checks
```

Because the `CLAUDE.md` loads only in-scope, those skills are applied automatically during
development, verification, and review **in that app and nowhere else**. Use `## Code Review` in the
same file for scope-specific review notes. `/stroi:analyze` never touches anything outside the map
markers, so both blocks survive every refresh.

## Runtime artifacts (written into the consuming project)
All stroi runtime lives under `.claude/stroi/` — gitignored and auto-cleaned, never part of the codebase:
- `.claude/stroi/plans/<slug>.plan.md` — the living plan for a `plan-big` run (with `## Task Status`).
  Deleted on successful close; the SessionEnd hook also clears completed plans.
- `.claude/stroi/RESUME` — resume pointer written by the PreCompact hook; cleared at session end.
- `.claude/stroi/dirty.log` — touched-path log feeding staleness detection.

The codebase maps are the exception: they live in each scope's committed `CLAUDE.md` (the stroi map
block), not under `.claude/stroi/`. Add `.claude/stroi/` to your project's `.gitignore`.

## Philosophy
This harness is deliberately small. Add to it only when you hit a real, repeated need — and use
`/stroi:learn` to make each addition traceable. Prune on model upgrades. See `HARNESS.md`.

## License
MIT — see [LICENSE](./LICENSE).
