#!/usr/bin/env bash
# stroi — SessionEnd. Tidies up /stroi:plan-big runtime so finished runs don't linger. Removes
# the RESUME pointer and any COMPLETED plan (no unchecked "- [ ]" tasks left); in-progress plans
# are KEPT so a later session can still resume them. Best-effort and non-destructive: only touches
# stroi's own runtime dir (~/.claude/stroi/<project>, outside the repo). Exit 0 always.

cat >/dev/null 2>&1 || true   # drain stdin; we don't need the payload
# shellcheck source=_paths.sh
. "$(dirname "${BASH_SOURCE[0]}")/_paths.sh" 2>/dev/null || exit 0
stroi="$(stroi_runtime_dir)"
[ -d "$stroi" ] || exit 0

rm -f "$stroi/RESUME" 2>/dev/null || true

plans="$stroi/plans"
[ -d "$plans" ] || exit 0
for f in "$plans"/*.plan.md; do
  [ -f "$f" ] || continue
  # Keep any plan that still has an unchecked task; delete the rest (completed runs).
  if grep -Eq '^[[:space:]]*-[[:space:]]*\[[[:space:]]\]' "$f" 2>/dev/null; then
    continue
  fi
  rm -f "$f" 2>/dev/null || true
done
exit 0
