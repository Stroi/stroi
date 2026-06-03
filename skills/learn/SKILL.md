---
name: learn
description: Capture a durable rule (the Ratchet) — turn an observed mistake or confirmed approach into a traceable convention. Asks project vs global scope and offers to escalate from a CLAUDE.md line to a hook or a reviewer check. With --review, reflects on the session for rule candidates.
---

# /stroi:learn — the Ratchet

Turn a lesson into a permanent, traceable control. `$ARGUMENTS` = the rule (e.g.
`"always use the http client in lib/, don't add a new one"`), or `--review` to reflect.

## Capture mode — `/stroi:learn "<rule>"`
1. **Sharpen** the rule into one traceable line (what + why). A rule should trace to a real
   failure or a hard constraint — never speculative.
2. **Ask scope:**
   - **Project** → append it under a `## Conventions (earned)` heading in the consuming project's
     nearest in-scope `CLAUDE.md` (or a `.claude/rules/*.md` file).
   - **Global** → write it into the user's `~/.claude` memory system: one memory file plus a
     one-line pointer in the memory `MEMORY.md` index (never copy the body into the index).
3. **Offer the escalation ladder** (pick the lightest level that actually prevents recurrence):
   - **Prose line** (default) — a rule in `CLAUDE.md` / a memory. Advisory.
   - **Hook** — for a deterministically-detectable violation, a `PreToolUse`/`PostToolUse` guard
     that blocks or warns. Enforcement, not advice — the strongest lever.
   - **Reviewer check** — add it to the in-scope `CLAUDE.md` `## Code Review` notes (or list a
     review skill under `## Relevant Skills`) so `stroi-reviewer` flags it.

## Reflect mode — `/stroi:learn --review`
Look back over the current session for **Ratchet candidates**: conventions you saw violated,
corrections the user made more than once, or approaches they confirmed. Propose each as a concrete
rule + scope + recommended escalation level, and let the user confirm before writing anything.
(This is agent reflection — there is no background analyzer; richer auto-detection is deferred.)

## Rules
- One rule per capture; keep each line short and checkable.
- Only ratchet real signal — speculative rules become noise and bloat (the thing stroi exists to avoid).
- `/stroi:learn` edits the **rules** region of `CLAUDE.md` (or memory). To refresh the codebase
  **description**, use `/stroi:analyze` (the `CLAUDE.md` map block). Two different jobs, two regions
  of the same file.
