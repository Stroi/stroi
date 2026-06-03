#!/usr/bin/env bash
# stroi — PostToolUse(Write|Edit). Records the touched file path so the staleness
# detector can later flag scopes whose CLAUDE.md map block lags behind their code.
# Observational only: ALWAYS exits 0, never blocks.

payload="$(cat 2>/dev/null || true)"
proj="${CLAUDE_PROJECT_DIR:-$PWD}"

# Extract the edited file path from the hook payload (no jq/python dependency —
# file paths effectively never contain a double-quote).
fp="$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -z "$fp" ] && exit 0

# Ignore the harness's own artifacts and per-scope docs to avoid self-triggering
# (editing CLAUDE.md / its map block, or anything under .claude/, is not code drift).
case "$fp" in
  */.claude/*|*/CLAUDE.md) exit 0 ;;
esac

mkdir -p "$proj/.claude/stroi" 2>/dev/null || exit 0
printf '%s\n' "$fp" >> "$proj/.claude/stroi/dirty.log" 2>/dev/null || true
exit 0
