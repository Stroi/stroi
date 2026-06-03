---
name: verify
description: Command-agnostic verification loop — detects the project's tooling, then runs build, typecheck, lint, tests, a security scan, and a diff review. Silent on success, verbose and actionable on failure. Use after making changes, or as the validator gate in plan-big.
---

# /stroi:verify — verification loop

Verify the current working changes against ground truth from the project's **own** tools.
This skill is **command-agnostic**: it discovers how to build/test *this* project rather than
assuming `npm`. It is also the engine that `stroi-validator` runs.

## Phase 0 — Detect tooling (do this first)
Determine the scope (the directory you're working in, or the `$ARGUMENTS` path) and discover
commands, in this order of preference:

1. **Explicit declarations** in the in-scope `CLAUDE.md` (the map block's `## Commands`, or a
   build/test/lint section). Prefer these — they are authoritative.
2. **Manifest + lockfile inference:**
   - **Node/TS** — `package.json` `scripts` → `build`, `typecheck` (or `tsc --noEmit`), `lint`,
     `test`. Pick the package manager from the lockfile: `bun.lockb`→bun, `pnpm-lock.yaml`→pnpm,
     `yarn.lock`→yarn, else npm.
   - **Python** — `pyproject.toml`/`setup.cfg` → `ruff`/`flake8`, `mypy`/`pyright`, `pytest`;
     runner `uv`/`poetry`/`hatch` if configured.
   - **Go** — `go build ./...`, `go vet ./...`, `go test ./...`.
   - **Rust** — `cargo build`, `cargo clippy`, `cargo test`.
   - **Other** — read the manifest and adapt.

If you cannot find a command for a phase, mark that phase **SKIPPED** with the reason — never
invent one and never fake a pass.

## Phases (run in order)
1. **Build** — compile/bundle. A failing build short-circuits the rest (report and stop).
2. **Typecheck** — static types, where the language has them.
3. **Lint** — the project's linter (do **not** auto-fix during verify; just report).
4. **Tests** — the test command; note coverage if the tool reports it.
5. **Security scan** — grep the changed files / diff for: hardcoded secrets (API keys, tokens,
   passwords, private keys), stray debug output (`console.log`, `print(`, `dbg!`), and obvious
   injection sinks. Report hits with `file:line`.
6. **Diff review** — `git diff` and `git status`: confirm changes are in-scope, no stray or
   unintended edits, no accidentally-committed artifacts, error paths handled.

## Scope skills
Apply any skills listed under `## Relevant Skills` in the in-scope `CLAUDE.md` — they may add
language/framework-specific checks for this scope.

## Output — verdict report
- One line per phase: `PASS` / `FAIL` / `SKIPPED (reason)`.
- On any FAIL: quote the exact failing output (trimmed to the relevant lines) and list the
  specific, actionable fixes.
- End with an overall **PASS** or **FAIL**.
- **Silent on success, verbose on failure** — when everything passes, keep it to the per-phase
  one-liners plus the verdict. Spend tokens only where something is wrong.

## Rules
- Ground every verdict in real tool output. Never report a phase as passing without running it.
- `$ARGUMENTS`, if given, is the scope to verify (a path); otherwise infer from the working changes.
