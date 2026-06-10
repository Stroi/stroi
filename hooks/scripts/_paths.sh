#!/usr/bin/env bash
# stroi — shared path resolver (sourced, not a hook entry; leading "_" marks it as a lib).
# Single source of truth for stroi's runtime dir, kept OUTSIDE the consuming project's
# working tree so plans/RESUME/dirty.log never appear in `ls`/`git status` and never risk
# being committed. The plan-big skill computes the same path with the one-liner documented
# in its Phase 0; keep the two formulas in sync.
#
# Layout (per project, keyed by the dashified absolute project dir, mirroring the scheme
# Claude Code uses for ~/.claude/projects/):
#   ~/.claude/stroi/<key>/plans/<slug>.plan.md   living plans (durable "- [ ]" checklist)
#   ~/.claude/stroi/<key>/RESUME                 resume pointer (PreCompact)
#   ~/.claude/stroi/<key>/dirty.log              touched-path log (PostToolUse)

# Echo stroi's runtime dir for the current project, creating it if absent. Always succeeds
# enough to print a path; callers stay best-effort and never block on failure.
stroi_runtime_dir() {
  local proj key
  proj="${CLAUDE_PROJECT_DIR:-$PWD}"
  key="$(printf '%s' "$proj" | sed 's#[^A-Za-z0-9]#-#g')"
  local dir="${HOME}/.claude/stroi/${key}"
  mkdir -p "$dir" 2>/dev/null || true
  printf '%s' "$dir"
}
