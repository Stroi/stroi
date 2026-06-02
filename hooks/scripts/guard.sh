#!/usr/bin/env bash
# stroi safety guard — PreToolUse(Bash). Deterministically blocks catastrophic shell
# commands (HARNESS.md §2.4). Reads the hook JSON payload on stdin.
#   exit 2  -> block; stderr is surfaced to the agent as actionable feedback
#   exit 0  -> allow
#
# The list is intentionally TIGHT: each entry is a near-always-unintentional hazard.
# Extend it only via the Ratchet, after a real incident — not speculatively.

payload="$(cat 2>/dev/null || true)"
# Normalize: turn newlines AND JSON structural punctuation ( " { } , : \ ) into spaces so
# the command's tokens are cleanly space-delimited regardless of JSON quoting/escaping.
# Without this, a target at the END of the command (e.g. the / in "rm -rf /") is followed
# by the JSON closing quote rather than whitespace, and end-anchored patterns would miss.
cmd="$(printf '%s' "$payload" | tr '\n\r\t"\\{},:' '         ')"

block() {
  echo "[stroi:guard] BLOCKED — $1" >&2
  echo "[stroi:guard] If this is genuinely intended, run it yourself outside the agent loop." >&2
  exit 2
}

# rm -rf (any flag order) targeting /, ~, $HOME, or a bare *
grep -Eq '(^|[^[:alnum:]_/.])rm[[:space:]]+-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+([^|;&]*[[:space:]])?(/|~|\$HOME|\*)([[:space:]]|$)' <<<"$cmd" \
  && block "recursive force-delete targeting /, ~, \$HOME, or * (rm -rf …)"

# git push --force / -f  (force-with-lease is safer; this still blocks plain force)
grep -Eq 'git[[:space:]]+push[[:space:]]+[^|;&]*(--force([[:space:]]|$)|-[a-zA-Z]*f[a-zA-Z]*([[:space:]]|$))' <<<"$cmd" \
  && block "force push (git push --force/-f) — prefer --force-with-lease and run it yourself"

# Destructive SQL — only when paired with a database-client invocation, so a commit
# message, doc, or grep that merely mentions "drop table" is NOT blocked.
if grep -Eiq '(^|[[:space:]])(psql|mysql|mariadb|sqlite3?|sqlcmd|cockroach|mongosh?|prisma)([[:space:]]|$)' <<<"$cmd" \
   && grep -Eiq 'drop[[:space:]]+(table|database|schema)([[:space:]]|;|$)' <<<"$cmd"; then
  block "destructive SQL (DROP TABLE/DATABASE/SCHEMA) via a database client"
fi

# Filesystem / disk destroyers
grep -Eq '(^|[^[:alnum:]_])mkfs(\.[a-z0-9]+)?[[:space:]]' <<<"$cmd" && block "filesystem format (mkfs)"
grep -Eq '(^|[^[:alnum:]_])dd[[:space:]]+[^|;&]*of=/dev/'  <<<"$cmd" && block "raw disk write (dd of=/dev/…)"
grep -Eq '>[[:space:]]*/dev/(sd|nvme|disk|hd)'             <<<"$cmd" && block "redirect to a raw disk device"
grep -Eq 'chmod[[:space:]]+-R[[:space:]]+0?777[[:space:]]+/' <<<"$cmd" && block "chmod -R 777 on an absolute path"

# Classic fork bomb
grep -Eq ':[[:space:]]*\([[:space:]]*\)[[:space:]]*\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:[[:space:]]*&[[:space:]]*\}[[:space:]]*;[[:space:]]*:' <<<"$cmd" \
  && block "fork bomb"

exit 0
