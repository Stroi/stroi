#!/usr/bin/env bash
# stroi — SessionStart. Flags scopes whose tspec.md is older than code changed under it.
# Detect-only: prints a one-line reminder per stale scope, silent when clean. Exit 0 always.
# Nested scopes are handled: a parent tspec ignores files that belong to a deeper scope
# (a subdirectory that has its own tspec.md).

cat >/dev/null 2>&1 || true   # drain stdin; we don't need the payload
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$proj" 2>/dev/null || exit 0

# Collect every scope directory (one per tspec.md).
dirs=()
while IFS= read -r f; do
  [ -n "$f" ] && dirs+=("$(dirname "$f")")
done < <(find . -type f -name 'tspec.md' \
            -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sort -u)
[ "${#dirs[@]}" -eq 0 ] && exit 0

stale=""
for dir in "${dirs[@]}"; do
  tspec="$dir/tspec.md"
  [ -f "$tspec" ] || continue
  # Prune any deeper scope so a parent doesn't see its children's files as "newer".
  prune=()
  for other in "${dirs[@]}"; do
    [ "$other" = "$dir" ] && continue
    case "$other/" in
      "$dir"/*) prune+=( -path "$other/*" -prune -o ) ;;
    esac
  done
  newer="$(find "$dir" "${prune[@]}" \
             -type f -newer "$tspec" \
             ! -name 'tspec.md' ! -name 'CLAUDE.md' \
             ! -path '*/.stroi/*' ! -path '*/.git/*' \
             ! -path '*/node_modules/*' ! -path '*/dist/*' ! -path '*/build/*' \
             -print 2>/dev/null | head -n1)"
  [ -n "$newer" ] && stale="$stale ${dir#./}"
done

if [ -n "$stale" ]; then
  echo "[stroi] tspec.md may be stale — code changed since last sync in:"
  for d in $stale; do
    echo "        $d   → refresh: /stroi:analyze $d"
  done
fi
exit 0
