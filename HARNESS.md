# HARNESS.md — Building an Effective Agent Harness

A reference for understanding what an agent harness *does* and how to build a lean one of your own — instead of inheriting a bloated all-in-one config.

Part 1 is vendor-neutral theory (the functions). Part 2 maps those functions onto Claude Code primitives. Parts 3–5 are the build guide, checklists, and a copy-paste template.

> **Citation tags** (full list in [Sources](#sources)): `[BEA]` Building Effective Agents · `[CE]` Effective Context Engineering · `[HD]` Harness Design for Long-Running Apps · `[MA]` Scaling Managed Agents · `[AO]` Osmani, Agent Harness Engineering. Every non-obvious claim carries a tag so you can verify it.

---

## Part 0 — Orientation

**The equation.** `Agent = Model + Harness` `[AO]`. The model only generates tokens. *Everything else* — the context it sees, the tools it can call, the memory it keeps, the loop that drives it, the checks on its output, the guardrails on its actions — is the harness. A decent model with a great harness beats a great model with a bad harness `[AO]`.

**The one rule.** Find the simplest solution that works, and only add complexity when it demonstrably improves outcomes `[HD][BEA]`. Most "the model is dumb" failures are actually harness gaps: a missing rule, a missing check, bad task decomposition `[AO]`.

**How to use this doc.** Read Part 1 once to build the mental model. Use Part 2 as a lookup when deciding *where* a given need belongs. Drive your actual build from Part 3, audit with Part 4, and seed your repo from Part 5.

---

## Part 1 — Concepts (vendor-neutral)

### 1.1 What a harness is

A harness is the scaffolding that turns a raw model into a reliable, governed actor over time. A useful way to decompose it `[MA]`:

| Layer | Role | Lives where |
|---|---|---|
| **Brain** | The inference loop — calls the model, reads its output, routes tool calls. | Your orchestration code / the agent runtime. |
| **Hands** | Execution environments — shell, filesystem, browser, APIs, MCP servers. | Sandboxes / tool backends, ideally isolated. |
| **Session** | The durable, append-only record of everything that happened. | Storage *outside* the model's context window. |

Keeping these three decoupled is the central architectural move `[MA]`: each can fail, be debugged, and scale independently. Couple them into one process ("adopt a pet") and a single crash loses everything with no visibility.

### 1.2 Why it matters

- **The harness gap.** There's a gap between what a model *can* do and what it *actually* does in a given setup. That gap is mostly harness, not model — fix the harness and you unlock capability the old setup left on the floor `[AO]`.
- **Harnesses encode assumptions that go stale** `[MA]`. Every piece of scaffolding reflects something the model couldn't do *at the time you added it*. As models improve, some scaffolding becomes dead weight. Concretely: a model generation that needed elaborate hand-holding to stay on task may not need it next generation `[HD]`.
- **Implication:** a harness is a *living system*, not a one-time setup. Revisit it on every model upgrade — add what unlocks new capability, remove what's now redundant.

### 1.3 The agent loop

Almost every harness drives the same core cycle (often called ReAct):

```
perceive  → assemble what the model sees this turn (context engineering)
   ↓
plan      → call the model; it reasons and emits a tool call or answer
   ↓
act       → execute the tool in an environment (the "hands")
   ↓
observe   → feed the real result back as ground truth
   ↺ repeat until done / blocked / budget hit
```

Every harness function below plugs into one of these stages. Get the loop right and most of the rest is refinement `[BEA]`.

### 1.4 Core functions

The canonical inventory — the jobs *any* harness must cover, regardless of vendor:

| Function | What it does | Failure if absent |
|---|---|---|
| **Context management** | Curates the token set the model sees each turn. | Context rot, wasted budget, lost focus. |
| **Tool / action interface (ACI)** | Defines the tools and how the model invokes them. | Wrong tool, malformed calls, thrash. |
| **Memory & state persistence** | Keeps durable state outside the context window. | Amnesia across turns/sessions. |
| **Control loop & orchestration** | Drives the loop; decomposes and delegates work. | Stalls, runaway loops, incoherence at scale. |
| **Verification & feedback** | Supplies ground truth and grades output. | Plausible-but-wrong results ship. |
| **Observability** | Records what happened and why. | Can't debug or improve the harness. |
| **Safety & permissions** | Bounds what the agent may do. | Destructive or unauthorized actions. |

### 1.5 Best practices by domain

#### Context engineering `[CE]`
Context engineering — curating the whole token set (system prompt, tools, history, retrieved data) — has largely superseded prompt engineering as the core discipline `[CE]`.

- **Treat context as finite with diminishing returns.** Every token spends attention budget; more is not better. Don't wait for bigger context windows to fix coherence — they still suffer attention degradation `[CE]`.
- **Just-in-time retrieval over pre-loading.** Let the agent navigate via lightweight identifiers (paths, URLs, queries) and pull data when needed, rather than dumping everything upfront — the way `grep`/`head`/`tail` beat loading a whole dataset `[CE]`.
- **Progressive disclosure.** Surface tool/context *metadata* and let the agent discover the rest on demand `[CE]`.
- **Compaction for long tasks.** When history nears the limit, summarize it — preserve decisions and open threads, discard redundant tool dumps. The skill is choosing what to keep `[CE]`.
- **Context reset vs. compaction (long-horizon).** Compaction leaves the agent on a shortened history; a *full reset* rebuilds a clean window from a compact handoff brief. Resets counter "context anxiety" — the tendency to wrap up prematurely as the limit approaches `[HD]`.
- **Structured note-taking (agentic memory).** Let the agent write notes to files/DB and pull them back later — enables coherence across thousands of steps `[CE]`.
- **Start minimal.** Begin with the smallest context that works; add instructions/examples only in response to observed failures `[CE]`.

#### Tool design (the ACI) `[BEA]`
Anthropic reports spending *more* effort tuning the agent-computer interface than the top-level prompt `[BEA]`.

- **Minimal, non-overlapping set.** If you can't say which tool fits a situation, neither can the model. Ten focused tools beat fifty overlapping ones `[BEA][AO]`.
- **Docstring-quality descriptions.** Write each tool like docs for a junior dev: purpose, parameters, examples, edge cases `[BEA]`.
- **Poka-yoke (mistake-proofing).** Shape arguments so errors are hard — e.g. require absolute paths instead of relative `[BEA]`.
- **Token-efficient returns.** Return high-signal output; offload bulky results to the filesystem and return a handle `[CE][AO]`.
- **Test extensively.** Run many real examples, watch where the model trips, iterate `[BEA]`.
- **Tool descriptions are trusted code.** They're injected into the prompt every request, so a sloppy or malicious MCP server can prompt-inject before you type anything. Validate every server you add `[AO]`.

#### Memory & persistence `[CE][MA]`
- **The session log is not the context window** `[MA]`. The session is the full append-only history living outside the window; you query slices of it, rewind it, or transform events before showing them to the model.
- **Files are the simplest durable memory** `[CE][AO]`. A `PROGRESS.md` / `NOTES.md` / handoff brief survives compaction and resets and coordinates multiple agents.
- **Handoff briefs** — a compact "here's where things stand" file is what makes a context reset safe `[HD]`.

#### Verification & feedback `[HD][BEA]`
- **Ground truth from the environment every step** — tool results, test outcomes, type/lint output, not the model's say-so `[BEA]`.
- **Write the rubric before iterating.** For subjective work (design, prose), define gradable criteria up front `[HD]`.
- **Separate the evaluator from the generator.** Agents grade their own work leniently; an independent evaluator (different prompt, ideally different context) is a strong lever — "GANs for prose" `[HD][AO]`.
- **Iterate to plateau.** Quality work often takes several generate→evaluate→refine rounds, not one shot `[HD]`.

#### Long-horizon execution `[HD][AO]`
- **Decompose into tractable units** (one feature / one sprint at a time) so coherence survives `[HD]`.
- **Plan files.** Have the agent write a plan to disk and work against it; the harness keeps it honest `[HD][AO]`.
- **Continuation loops (the "Ralph loop").** A hook intercepts a premature exit and re-injects the goal into a fresh window, each iteration reading prior state from disk — forcing progress toward completion `[AO]`.

#### Observability `[MA][AO]`
- **Log the *assembled* prompt, not just the response** — you can't debug what you can't see `[AO]`.
- **Keep traces and decision records** — tool calls, results, approvals, errors, interventions `[MA][AO]`.
- **Watch entropy / maintenance burden** — agents leave stale docs, churned deps, weakened tests. Track it as a signal `[AO]`.

#### Safety & permissions `[MA][AO]`
- **Credentials live outside the sandbox** — hold tokens in a proxy/vault, not in the agent's reach `[MA]`.
- **Scope every tool and permission narrowly** — no blanket access `[MA]`.
- **Block deterministically, don't rely on the prompt.** A rule asking the model not to `rm -rf` is advisory; a hook that refuses it is enforcement `[AO]`.

### 1.6 Architectural frameworks

**Planner → Generator → Evaluator** `[HD]`. Split long-running work into three roles:
- **Planner** expands a vague goal into a scoped spec/plan without over-specifying *how*.
- **Generator** implements one discrete unit at a time.
- **Evaluator** grades the result against the written rubric — and is *not* the generator.

Glue them with a **sprint contract**: planner/generator and evaluator agree on what "done" means *before* work starts, which catches scope drift early `[HD]`.

**The layered harness.** Think of effort in concentric layers `[AO]`:
1. **Model** — commodity, interchangeable. Don't build here.
2. **Execution runtime** — the agent CLI/IDE (e.g. Claude Code) handles the loop, tool plumbing, sandboxing. Don't rebuild it.
3. **Project harness** — *your* lint rules, type checks, tests, conventions. **Spend effort here.**
4. **Domain harness** — org/domain context, custom tools, specialized agents. Grows over time.

**Decouple brain / hands / session** (see §1.1) for reliability and scale `[MA]`.

### 1.7 The Ratchet — a discipline, not a framework

The highest-leverage habit `[AO]`:

- **Treat every agent mistake as a permanent signal, not a one-off.** Saw the agent comment out a failing test? Add a `CLAUDE.md` line ("never disable tests — fix or delete"), then a pre-commit hook that greps for `.skip(`/`xit(`, then a reviewer subagent that flags it. Each failure ratchets a control into place.
- **Only add a constraint after a real failure.** No speculative rules.
- **Only remove a constraint when a stronger model makes it redundant.** Prune on upgrades.
- **Work backwards from behavior.** Start from the behavior you want, derive the minimal harness piece that delivers it. If you can't name a component's job, delete it. This is what keeps a harness from bloating into ECC.

### 1.8 Anti-patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| "Wait for the next model" | The gap is usually harness, not model `[AO]`. | Fix the harness now. |
| Coupling brain+hands+session | One crash loses all state, zero visibility `[MA]`. | Decouple the three. |
| Bloated/overlapping tool menu | Model can't choose; thrash `[BEA]`. | ≤ ~10 focused tools. |
| Stuffing every edge case in the prompt | Brittle, token-heavy `[CE]`. | Few canonical examples + tools. |
| Self-grading generator | Lenient, misses defects `[HD]`. | Independent evaluator. |
| Static, never-revisited config | Accumulates stale assumptions `[MA]`. | Ratchet + prune on upgrades. |
| Blocking only via prompt rules | Advisory, not enforced `[AO]`. | Deterministic hooks. |
| Pre-loading all context | Context rot, premature stopping `[CE]`. | Just-in-time + compaction/reset. |
| Copying a giant starter harness | Inherits 100s of unowned components | Start empty; earn each piece. |

### 1.9 Glossary

- **ACI (Agent-Computer Interface)** — the tool layer's contract with the model; deserves as much care as the prompt `[BEA]`.
- **Context engineering** — curating the full token set per turn; distinct from prompt engineering `[CE]`.
- **Context rot** — degradation of reasoning as the window fills `[CE]`.
- **Context anxiety** — a model wrapping up prematurely as it nears its perceived limit `[HD]`.
- **Compaction** — summarizing history to free budget while preserving essentials `[CE]`.
- **Context reset** — tearing down and rebuilding the window from a compact handoff brief `[HD]`.
- **Progressive disclosure / just-in-time context** — discovering and loading context on demand `[CE]`.
- **Sprint contract** — explicit "definition of done" agreed before work begins `[HD]`.
- **The Ratchet** — turning every observed failure into a permanent, traceable control `[AO]`.
- **Brain / Hands / Session** — inference loop / execution env / durable log `[MA]`.
- **HaaS (Harness-as-a-Service)** — framing the harness, not the raw API, as the product `[AO]`.

---

## Part 2 — Applying it to Claude Code

The concepts above are universal. Here's where each one lives in Claude Code specifically. (Generic across projects — pick the components a given project actually needs.)

### 2.1 Concept → primitive map

| Harness function (Part 1) | Claude Code primitive |
|---|---|
| Context management | `CLAUDE.md` + imported rules; compaction; memory dir; output styles |
| Tool / action interface | Built-in tools; MCP servers; Skills (as gated capabilities) |
| Memory & persistence | `CLAUDE.md`; `./.claude/` files; memory directory; session transcripts |
| Control loop & orchestration | The built-in agent loop; subagents; plan mode |
| Verification & feedback | Hooks (lint/type/test); evaluator subagents |
| Observability | Hook logging; transcripts; statusline; `--verbose` |
| Safety & permissions | `permissions` allow/ask/deny in settings; PreToolUse hooks |

### 2.2 Anatomy of a Claude Code harness

For each primitive: what it is, the job it does, when to reach for it.

- **`settings.json` — the spine.** Layered: `~/.claude/settings.json` (user, all projects) → `.claude/settings.json` (project, committed) → `.claude/settings.local.json` (project, gitignored). Configures `model`, `permissions`, `hooks`, `env`, MCP enablement, `statusLine`, `outputStyle`, `enabledPlugins`, `extraKnownMarketplaces`. **Job:** the single place that wires everything else together.
- **`CLAUDE.md` + rules — the rulebook.** Auto-loaded into context every session; supports `@path` imports (this is how ECC pulls in modular `rules/*.md`). **Job:** project conventions, commands, constraints. Keep it *short and traceable* — a pilot's checklist, not a style guide; every line should trace to a real failure or a hard constraint `[AO]`.
- **Skills (`.claude/skills/<name>/SKILL.md`).** Markdown + frontmatter (`name`, `description`). Only the name+description load until the skill is invoked (model-chosen or `/name`) — built-in progressive disclosure `[CE]`. **Job:** package a repeatable workflow or domain knowledge without permanently spending context.
- **Subagents (`.claude/agents/<name>.md`).** Frontmatter (`name`, `description`, `tools`, `model`); run in a *separate context window*. **Job:** context isolation, parallel fan-out, and crucially the independent **evaluator** role `[HD]`.
- **Slash commands (`.claude/commands/<name>.md`).** Map a file to `/name` as a reusable prompt. **Job:** quick, deterministic prompt shortcuts (lighter than a skill).
- **Hooks (in `settings.json`).** Shell commands fired at lifecycle events. **Job:** deterministic enforcement and observability. Lifecycle:

  | Event | Fires | Typical use |
  |---|---|---|
  | `SessionStart` | session begins | load context/state |
  | `UserPromptSubmit` | on each user message | inject context, gate input |
  | `PreToolUse` | before a tool runs | **block** destructive actions (exit 2) |
  | `PostToolUse` | after a tool runs | format/lint/type/test on edits |
  | `Stop` / `SubagentStop` | turn ends | verification, continuation loops |
  | `PreCompact` | before compaction | persist a handoff brief |
  | `SessionEnd` | session ends | final checks, cleanup |

- **MCP servers.** External tool backends (`.mcp.json` or `claude mcp add`), stdio/SSE/HTTP. **Job:** give the hands real reach (GitHub, browser, DBs). Add sparingly — each one's tool descriptions enter your prompt and must be trusted `[AO]`.
- **Memory.** `CLAUDE.md` is the always-on memory; a dedicated memory directory / files persist facts across sessions. **Job:** durable state outside the window `[CE]`.
- **Output styles & statusline.** Output styles reshape system behavior; the statusline renders live status from a command. **Job:** mode-switching and at-a-glance observability.
- **Plugins & marketplaces.** `enabledPlugins` + `extraKnownMarketplaces` in settings install bundles (skills+agents+commands+hooks+MCP) from a git marketplace — this is exactly how ECC is wired. **Trade-off:** one toggle installs *everything* in the bundle (the source of bloat). Hand-curated dotfiles cost more to assemble but every component is one you chose and own. **For a lean harness, prefer dotfiles; cherry-pick from a plugin rather than enabling it wholesale.**

### 2.3 Selection principles — the "earn its place" test

Before adding *any* skill / agent / hook / MCP server, it must pass all four `[AO][HD]`:
1. **Named job** — you can state the behavior it delivers in one sentence.
2. **Traceable** — it answers a real, observed failure or a hard external constraint (not "might be handy").
3. **Right layer** — it belongs to *your* project/domain harness, not something the runtime already does (§1.6).
4. **Cheap to carry** — its standing context cost (prompt text, tool descriptions) is justified by its frequency of use.

Fail any one → leave it out. This single test is what separates your lean harness from a 300-component bundle.

### 2.4 Wiring patterns

- **Minimal `settings.json`** — see Part 5. Start with just `model` + a couple of `permissions`.
- **"Success is silent, failures are verbose"** `[AO]` — the core hook pattern. On pass, the hook prints nothing and the agent spends no tokens on it; on fail, it exits non-zero and prints the error, which loops back into context as directly actionable feedback. Nearly free in the common case, maximally useful on error.
- **Permission/approval gates** — route low-risk tools to `allow`, irreversible/outward-facing ones to `ask`, and forbidden ones to `deny`; back the hard stops with a `PreToolUse` hook (exit 2) so they're enforced, not merely requested.

---

## Part 3 — Build guide (step by step)

Build the harness the way the Ratchet says to: empty first, each piece earned.

0. **Don't clone a mega-harness.** Start from nothing. You'll add only what you can justify.
1. **Baseline.** Create `~/.claude/settings.json` (or project `.claude/settings.json`) with just your `model` and a few obviously-safe `permissions`. Confirm a normal session works.
2. **Codify conventions** in a lean `CLAUDE.md`: build/test commands, package manager, directories that are off-limits, the 3–5 conventions you most want enforced. Keep it short `[AO]`.
3. **Add tools/MCP only on need.** When you hit a task the agent can't do (open PRs, drive a browser, query a DB), add *that* MCP server — and validate it `[AO]`.
4. **Add hooks for what the agent reliably forgets.** Each time you correct the same mistake twice, encode it: a `PostToolUse` formatter/linter/typechecker, a `PreToolUse` block on a dangerous command. Apply "silent on success" `[AO]`.
5. **Add skills for repeated workflows.** A multi-step process you've explained more than twice becomes a skill — gated, so it costs context only when used `[CE]`.
6. **Add subagents for isolation / parallelism / evaluation.** Heavy exploration that would pollute the main window → a subagent. Quality-sensitive work → a separate **evaluator** subagent `[HD]`.
7. **Wire a verification loop.** Tie tests/type-check/lint into hooks (or an evaluator) so the agent gets ground truth automatically `[BEA]`. For subjective work, write the rubric first `[HD]`.
8. **Add observability.** Log assembled prompts and tool traces; surface state in the statusline `[AO][MA]`.
9. **Iterate via the Ratchet; prune on upgrades.** Every failure → a new control. Every model upgrade → re-read the harness and delete what's now redundant `[MA]`.

---

## Part 4 — Checklists

### Pre-build
- [ ] Can I name, in one line, what I want the harness to *do* that the bare runtime doesn't?
- [ ] Am I starting empty rather than copying a bundle?
- [ ] Do I know my project's build/test/lint commands to wire as ground truth?

### Per-component "earn its place"
- [ ] Named job (one sentence)?
- [ ] Traces to a real failure or hard constraint?
- [ ] Right layer (not duplicating the runtime)?
- [ ] Standing context cost justified by usage frequency?
- [ ] If a hook: silent on success, verbose+actionable on failure?
- [ ] If an MCP server: source trusted, tool descriptions reviewed, scope narrow?

### Lean-harness audit (trimming an existing bloated setup)
- [ ] List every active skill/agent/command/hook/MCP server.
- [ ] For each, can you name its job *and* the last time it ran? If not → remove.
- [ ] Remove rules/agents for languages & domains you don't use.
- [ ] Collapse overlapping tools down to one each.
- [ ] Replace plugin-wholesale installs with cherry-picked components you own.
- [ ] Re-measure: is `CLAUDE.md` still short enough to be a checklist?

### Per-model-upgrade review
- [ ] Which constraints existed only to compensate for the *old* model? Remove them `[MA]`.
- [ ] Did the new model unlock a capability worth a new component?
- [ ] Re-run your hardest real task and compare behavior.

---

## Part 5 — Template / skeleton

A generic seed for your own `~/.claude/` (or project `.claude/`). Replace placeholders; keep it minimal and grow via the Ratchet.

### Directory skeleton
```
.claude/
├── settings.json            # the spine — wires everything
├── CLAUDE.md                # lean rulebook (imports optional)
├── rules/                   # OPTIONAL: modular @imports for CLAUDE.md
│   └── conventions.md
├── skills/                  # add when a workflow repeats 3+ times
│   └── <skill-name>/
│       └── SKILL.md
├── agents/                  # add for isolation / parallel / evaluation
│   └── evaluator.md
├── commands/                # OPTIONAL: lightweight /prompt shortcuts
│   └── <command>.md
└── hooks/                   # scripts invoked by settings.json hooks
    └── verify.sh
```

### `settings.json` (annotated — remove comments; JSON disallows them)
```jsonc
{
  // pin the model you build the harness against
  "model": "claude-opus-4-8",

  // route tools by risk: allow / ask / deny
  "permissions": {
    "allow": ["Read", "Grep", "Glob"],
    "ask":   ["Bash", "Write", "Edit"],
    "deny":  []
  },

  // deterministic enforcement + verification
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": ".claude/hooks/verify.sh"}]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": ".claude/hooks/guard.sh"}]
      }
    ]
  }

  // add MCP servers / plugins ONLY when a task demands them
}
```

### `CLAUDE.md` (keep it a checklist, not an essay)
```markdown
# Project: <name>

## Commands
- Install: <cmd>
- Test:    <cmd>
- Lint/Typecheck: <cmd>

## Conventions (each line earned from a real failure)
- <e.g. never disable a failing test — fix or delete it>
- <e.g. use the existing HTTP client in lib/, don't add a new one>

## Off-limits
- <dirs/files the agent must not touch>
```

### Hook — "silent on success, verbose on failure"
```bash
#!/usr/bin/env bash
# .claude/hooks/verify.sh — runs after Write/Edit
set -euo pipefail
if ! <your-typecheck-or-lint-cmd> 2>err.log; then
  echo "Verification failed:" >&2
  cat err.log >&2
  exit 2          # non-zero → error text loops back to the agent
fi
# success: print nothing, exit 0
```

### `PreToolUse` guard — deterministic block
```bash
#!/usr/bin/env bash
# .claude/hooks/guard.sh — refuse destructive bash
payload="$(cat)"
if echo "$payload" | grep -Eq 'rm -rf|git push --force|DROP TABLE'; then
  echo "[guard] blocked destructive command" >&2
  exit 2
fi
exit 0
```

### Skill skeleton (`skills/<name>/SKILL.md`)
```markdown
---
name: <skill-name>
description: <one line; this is what the model sees before invoking>
---
# <Skill>
Steps the agent should follow when this skill is invoked.
Reference files with @relative/paths so they load just-in-time.
```

### Subagent skeleton (`agents/evaluator.md`)
```markdown
---
name: evaluator
description: Independently grades generated work against a rubric. Not the generator.
tools: Read, Grep, Glob, Bash
---
You are a skeptical reviewer. Grade the work against these criteria: <rubric>.
Look for obvious defects and edge cases. Report PASS/FAIL with specifics.
```

### Minimal viable harness (your starting point)
Just three files: `settings.json` (model + permissions), `CLAUDE.md` (commands + a few conventions), and one `verify.sh` hook wired to `PostToolUse`. That's a complete, working harness. Everything else is earned, one Ratchet click at a time.

---

## Sources

All verified at time of writing (2026-06-01); dates shown so staleness is auditable. Secondary arXiv/whitepaper material surfaced during research was **excluded** as unverifiable.

| Tag | Title | URL | Date | Best for |
|---|---|---|---|---|
| `[BEA]` | Building Effective AI Agents | anthropic.com/research/building-effective-agents | Dec 2024 | Foundations: simplicity, tools/ACI, workflow vs. agent |
| `[CE]` | Effective Context Engineering for AI Agents | anthropic.com/engineering/effective-context-engineering-for-ai-agents | Sep 2025 | Context as finite resource; compaction, notes, just-in-time |
| `[HD]` | Harness Design for Long-Running Apps | anthropic.com/engineering/harness-design-long-running-apps | Mar 2026 | Planner/Generator/Evaluator, sprint contracts, context resets |
| `[MA]` | Scaling Managed Agents (Brain/Hands) | anthropic.com/engineering/managed-agents | Apr 2026 | Decoupling brain/hands/session; stale assumptions |
| `[AO]` | Osmani — Agent Harness Engineering | addyosmani.com/blog/agent-harness-engineering | Apr 2026 | The Ratchet, layered harness, hook patterns, industry framing |

> **Remember the meta-lesson** `[MA]`: this guide itself encodes assumptions about today's models and tools. Re-read it when you upgrade — keep what still earns its place, prune the rest.
