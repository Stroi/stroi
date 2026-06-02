<!--
  stroi tspec — agent-optimized technical spec for ONE scope.
  Generated/refreshed by /stroi:analyze. It DESCRIBES the code (CLAUDE.md holds the RULES).

  Hierarchy (DRY): the ROOT tspec holds only codebase-wide facts and is always loaded; a LEAF
  tspec (per app/package) holds ONLY folder-specific facts and never repeats the root.
  Budget: root < ~150 lines, leaf < ~400. High signal only — not an exhaustive API dump.

  The "## Relevant Skills" and "## Code Review" blocks are maintained BY HAND and preserved
  verbatim across refreshes.
-->
# tspec: <scope name>
last-synced: <commit-short-hash and/or ISO date — from git, never invented>

## Purpose
<1–2 lines: what this scope is for.>

## Entry Points
- <file:line — mains, route files, exported modules>

## Key Directories
- `dir/` — <what lives here, why it matters>

## Core Modules & Responsibilities
- `path` — <responsibility>

## Data Flow / Critical Paths
<how a request/action moves through this scope; only the few paths worth knowing.>

## Conventions (scope-specific)
<naming, error handling, state, testing — only what is specific to this scope, each with a path.>

## Integration Points
<APIs, databases, queues, sibling packages this scope talks to.>

## Dependencies & Docs
<!-- Key libraries for this scope → Context7 id (preferred) and/or doc URL. Used for
     research-before-implement by the planner/developer. Refreshed by /stroi:analyze. -->
- `<lib>@<version>` → ctx7: `</org/lib>`  (docs: <url>)

## Commands
- build: <cmd>
- typecheck: <cmd>
- lint: <cmd>
- test: <cmd>

## Gotchas / Landmines
- <anything surprising or easy to break>

## Relevant Skills
<!-- MAINTAINED BY HAND (no command). One installed skill ID per line. These are applied
     automatically during development, verification, and review for THIS scope only — because
     this tspec loads just-in-time when you work here. Examples:
       - my-react-native-checks
       - everything-claude-code:react-native-patterns
     Leave empty if none. /stroi:analyze preserves this block across refreshes. -->

## Code Review
<!-- MAINTAINED BY HAND. Prose: what specifically matters when reviewing code in this scope,
     beyond the universal correctness/security checks the reviewer always runs. Preserved
     across refreshes. -->
