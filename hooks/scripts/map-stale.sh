#!/usr/bin/env bash
# stroi — SessionStart. Flags scopes whose CLAUDE.md map block is older than code changed
# under it. Detect-only: prints a one-line reminder per stale scope, silent when clean. Exit 0.
# A CLAUDE.md is a "mapped scope" only if it contains the stroi map marker, so hand-written,
# rules-only CLAUDE.md files are never flagged. Nested scopes are handled: a parent ignores
# files that belong to a deeper mapped scope (a subdirectory with its own map block).

cat >/dev/null 2>&1 || true   # drain stdin; we don't need the payload
proj="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$proj" 2>/dev/null || exit 0

marker='<!-- stroi:map:start -->'

# Collect every mapped scope directory (one per CLAUDE.md that carries a stroi map block).
dirs=()
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qF "$marker" "$f" 2>/dev/null && dirs+=("$(dirname "$f")")
done < <(find . -type f -name 'CLAUDE.md' \
            -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | sort -u)
[ "${#dirs[@]}" -eq 0 ] && exit 0

stale=""
for dir in "${dirs[@]}"; do
  claudemd="$dir/CLAUDE.md"
  [ -f "$claudemd" ] || continue
  # Prune any deeper mapped scope so a parent doesn't see its children's files as "newer".
  prune=()
  for other in "${dirs[@]}"; do
    [ "$other" = "$dir" ] && continue
    case "$other/" in
      "$dir"/*) prune+=( -path "$other/*" -prune -o ) ;;
    esac
  done
  newer="$(find "$dir" "${prune[@]}" \
             -type f -newer "$claudemd" \
             ! -name 'CLAUDE.md' \
             ! -path '*/.stroi/*' ! -path '*/.git/*' \
             ! -path '*/node_modules/*' ! -path '*/dist/*' ! -path '*/build/*' \
             -print 2>/dev/null | head -n1)"
  [ -n "$newer" ] && stale="$stale ${dir#./}"
done

if [ -n "$stale" ]; then
  echo "[stroi] CLAUDE.md map may be stale — code changed since last sync in:"
  for d in $stale; do
    echo "        $d   → refresh: /stroi:analyze $d"
  done
fi
exit 0
