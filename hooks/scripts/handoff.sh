#!/usr/bin/env bash
# stroi — PreCompact. Snapshots a resume pointer for an in-progress /stroi:plan-big run
# so a post-compaction window can pick up where it left off. Exit 0 always.
# The durable state is the on-disk living plan (kept current by stroi-developer); this
# hook only writes a tiny pointer — it does not author a summary.

cat >/dev/null 2>&1 || true   # drain stdin
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
plans="$proj/.claude/stroi/plans"
[ -d "$plans" ] || exit 0

# Find the most-recently-modified plan that still has an unchecked task "- [ ]".
newest=""; newest_t=0
for f in "$plans"/*.plan.md; do
  [ -f "$f" ] || continue
  grep -Eq '^[[:space:]]*-[[:space:]]*\[[[:space:]]\]' "$f" 2>/dev/null || continue
  t="$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)"
  if [ "$t" -gt "$newest_t" ]; then newest_t="$t"; newest="$f"; fi
done

# No in-progress plan -> clear any stale pointer and exit.
if [ -z "$newest" ]; then
  rm -f "$proj/.claude/stroi/RESUME" 2>/dev/null || true
  exit 0
fi

next="$(grep -nE '^[[:space:]]*-[[:space:]]*\[[[:space:]]\]' "$newest" 2>/dev/null | head -n1)"
{
  echo "PLAN: ${newest#$proj/}"
  echo "NEXT: ${next}"
  echo "NOTE: resume /stroi:plan-big from the first unchecked task in PLAN."
} > "$proj/.claude/stroi/RESUME" 2>/dev/null || true
exit 0
