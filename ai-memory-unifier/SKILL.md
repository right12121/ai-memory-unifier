---
name: ai-memory-unifier
description: |
  Unify scattered memory across multiple AI coding agents / CLIs / assistants
  (Claude Code, Codex, Cursor, Aider, Continue, Cline, Windsurf, Zed, Gemini CLI,
  Qclaw/OpenClaw, and others — see `references/product-registry.md`) into a single
  structured system rooted in Claude Code: one global `~/.claude/CLAUDE.md` +
  N topic-specific skills + automated daily sync Loop to Codex.

  Designed for existing mid/heavy users whose AutoMemory, stray CLAUDE.md files,
  Codex AGENTS.md, Cursor rules, Aider configs, etc. have all drifted out of
  alignment and now contain overlapping, stale, or contradictory instructions.

  Trigger on user utterances like: "help me organize my AI memory",
  "consolidate my Claude / Cursor / Codex memory", "统一 AI 记忆",
  "整理多个 agent 的记忆", "clean up my AI assistant configs",
  "unify my AI instructions", "migrate memory to skills".

  This is a GUIDED MIGRATION skill. It does NOT ask the user to fill blank
  templates. It scans what the user already has (across a registry of known
  products + user-mentioned additions), proposes a classification, gets approval,
  and executes migration with full archiving + rollback.

  Cowork Global Instructions are **out of scope** (server-side storage, no
  reliable local API). Cowork users sync manually if needed.

  Progressive disclosure: load `references/phase-<N>-*.md` and
  `references/product-registry.md` on demand.
---

# AI Memory Unifier

This skill guides Claude through a multi-phase migration that turns scattered memory artifacts — across multiple AI products — into a single clean system, with Claude Code's `~/.claude/` as the authoritative home. Default language: **English technical output; user-facing explanations mirror the user's language**.

## When this skill triggers

- User mentions organizing / consolidating / unifying AI memory or instructions
- User references this skill by name (`/ai-memory-unifier`)
- User mentions drift across two or more AI products ("my Cursor rules say X but Claude Code thinks Y")

## When NOT to trigger

- User has one AI product and asks a one-off question about its config → just answer
- User has zero memory files anywhere → overkill; use `templates/CLAUDE.md.template` as a starter
- User explicitly says "quick fix" / "only edit this one file"
- User only wants to sync Cowork Global Instructions back (out of scope)

---

## Phase map

```
Phase 0  Diagnose        (read-only scan: registry + user-mentioned products)
Phase 1  Analyze         (classify files → propose CLAUDE.md sections + skills)
Phase 2  Archive setup   (create ~/.claude/archive-<date>/ + manifest.json)
Phase 3  Build CLAUDE.md (synthesize sections from scanned content)
Phase 4  Build skills    (create ~/.claude/skills/<name>/ directories)
Phase 5  Migrate         (mv source files into archive; NEVER direct delete)
Phase 6  Loops           (register scheduled tasks: Codex sync + daily reorg)
```

**Every phase requires explicit user approval before execution.** Skip-phase, adjust, or abort-at-any-time is always allowed.

Each phase has a detailed runbook in `references/phase-<N>-*.md` — load it on demand, not all at once.

---

## Scope: which AI products

The product registry is at `references/product-registry.md`. It lists:

- **Primary target** (writable, authoritative): Claude Code
- **Sync target** (writable): Codex CLI via `~/.codex/AGENTS.md` + `~/.codex/skills/`
- **Scannable sources** (read during Phase 0): Cursor, Aider, Continue, Cline, Windsurf, Zed, Gemini CLI, Amp, Qclaw/OpenClaw, and more
- **Out of scope** (server-side, can't reliably read/write locally): Cowork Global Instructions, ChatGPT custom instructions, Claude.ai preferences, Gemini custom instructions, GitHub Copilot

Phase 0 iterates the registry; Phase 0 also **asks the user** whether they use products not in the registry (especially smaller or regional ones like Hermes, KimiClaw, Doubao, Tongyi Lingma, etc.), and adds those to the scan.

---

## Core operating principles (read before starting)

### 1. Read-only → Propose → Approve → Execute

For phases 0–1: only read the filesystem, never modify. Present findings to the user first. Only act after explicit "yes, proceed".

### 2. Copy-first; never direct-delete

Phase 5 "migration" is actually `mv source → ~/.claude/archive-<date>/`. Archive is kept for at least 30 days. Users delete when they're ready.

### 3. SHA256 manifest for every file moved

Before moving any file, hash it and record `{source, archive, sha256, size, category, decision}` in `manifest-<date>.json`. This makes rollback precise and verifiable.

### 4. Dynamic detection, not assumed setup

Don't assume the user has Codex, Cursor, Aider, or any other specific product. Use `references/product-registry.md` to enumerate detection methods; skip products that aren't installed.

Also ask the user: "any AI products I might have missed?" — the registry isn't exhaustive.

### 5. Never modify settings.json automatically

The user likely has custom hooks, permissions, and plugins in `~/.claude/settings.json` (and analogs for other products). **Read-only** from this skill. If AutoMemory is out of control, *recommend* toggling `autoMemoryEnabled: false` but require explicit user confirmation to change.

### 6. Log everything

Append to `~/.claude/reorg-log/<date>.md` as each phase completes. The log is the audit trail and the rollback instruction sheet.

### 7. Progressive disclosure in this skill

- SKILL.md (this file) stays short (< 300 lines). Overview only.
- Details for each phase in `references/phase-<N>-*.md`.
- Product registry in `references/product-registry.md`.
- Templates in `templates/` — loaded when generating specific files.

---

## Phase 0 — Diagnose

**Intent**: enumerate every memory-relevant file/location across the product registry; characterize the user's starting point.

**Load**: `references/phase-0-diagnose.md` + `references/product-registry.md`

**Output**: a diagnostic report (printed to chat) listing every detected product and its memory files. Concludes by asking the user about additional products not in the registry. Ask the user to confirm before Phase 1.

---

## Phase 1 — Analyze & propose

**Intent**: read every candidate file; classify each into a target; propose a final structure.

**Load**: `references/phase-1-analyze.md`

**Classification labels** (apply per file):
- 🔵 **CLAUDE.md** — cross-product, high-frequency, identity/preference/rule content
- 🟢 **Existing skill** — fits an existing skill's topic
- 🟡 **New skill** — topic is thick enough to stand alone
- ⚪ **Keep in place** — project-bound or product-bound, low-frequency, fine where it is
- 🔴 **Archive only** — noise, duplicates, or expired info

**Propose**:
- CLAUDE.md target structure (sections, estimated line count; keep under 150)
- List of new skills to create (name + one-line description + source files)
- List of files going to archive-only

**User approval**: the user can edit classifications before Phase 2.

---

## Phase 2 — Archive setup

**Intent**: create the safety net before touching anything.

**Load**: `references/phase-5-migrate.md` (sections on archive layout + manifest schema)

**Actions**:
1. `mkdir -p ~/.claude/archive-<YYYY-MM-DD>/{projects,per-product,misc}`
2. `mkdir -p ~/.claude/reorg-log/`
3. Compute SHA256 of every source file in Phase 1's plan
4. Write `~/.claude/reorg-log/manifest-<YYYY-MM-DD>.json` using `templates/manifest.json.template`
5. Start `~/.claude/reorg-log/<YYYY-MM-DD>.md` with "Phase 0-1 findings + Phase 2 starting"

**Nothing moves yet** — this is all preparation.

---

## Phase 3 — Build CLAUDE.md

**Intent**: synthesize the global CLAUDE.md from extracted content.

**Load**: `references/phase-3-claude-md.md` + `templates/CLAUDE.md.template`

**Process**:
1. Read template skeleton (sections: Identity, People, Speaker Identification, Active Projects, Communication, Work Style, Tool Constraints, Memory Mechanism, Reorg History)
2. For each 🔵-classified source file (from any product), extract key facts into the right section
3. Add the fixed **Memory Mechanism** meta-rule (CLAUDE.md + skills are authority; AutoMemory absorbed by daily Loop)
4. Add **Reorg History** footnote pointing at `archive-<date>/`
5. Write to `~/.claude/CLAUDE.md`. Verify line count ≤ 150; warn if > 200

**User review**: show the generated CLAUDE.md; let the user edit before committing.

---

## Phase 4 — Build skills

**Intent**: materialize each 🟡 (new skill) and update each 🟢 (existing skill).

**Load**: `references/phase-4-skills.md` + `templates/skill.template.md`

**Process** (for each new skill):
1. `mkdir -p ~/.claude/skills/<name>/`
2. Fill `SKILL.md` from template: `frontmatter.name`, `frontmatter.description` (with trigger words), content body drawn from source files
3. Preserve section granularity (don't flatten multiple source files into one blob)
4. If Codex detected: `ln -s ~/.claude/skills/<name> ~/.codex/skills/<name>`

**User review**: list all new/modified skills. Let user approve en masse or skip some.

---

## Phase 5 — Migrate sources

**Intent**: move everything migrated into archive, leaving the authority locations pristine.

**Load**: `references/phase-5-migrate.md`

**Process** (per classified file):
1. `mv <source> <archive_path>` (the `archive_path` from manifest)
2. Verify move succeeded; update manifest entry with `migrated_at: <timestamp>`
3. Append to `~/.claude/reorg-log/<date>.md`

**Never direct delete**. Never `rm -rf`. Only `mv`.

Sources from **other products** (Cursor, Aider, etc.) are **NOT moved by default** — we only moved Claude Code's own scattered files. Other products' configs stay where they are; the consolidation copies content into CLAUDE.md + skills, but leaves original files alone so the other products keep working.

Exception: if the user explicitly asks "strip Cursor rules I've migrated to CLAUDE.md", do it per-file with confirmation and archive the stripped version.

---

## Phase 6 — Register Loops

**Intent**: set up two durable scheduled tasks to keep the system healthy.

**Load**: `references/phase-6-loops.md` + `templates/scheduled-task-*.template.md`

**Loop 1 — Memory Sync** (multi-target, data-driven):
- Cron: `17 9 * * *` (daily ~09:17)
- Reads `~/.claude/CLAUDE.md`; on change, writes to every enabled target in `state.json` with header comment
- Built-in Tier-1 targets (auto-populated first run):
  - `~/.codex/AGENTS.md` (Codex CLI)
  - `~/.gemini/GEMINI.md` (Gemini CLI)
  - `~/.codeium/windsurf/memories/global_rules.md` (Windsurf)
- **User custom targets**: during Phase 6, ask the user if they use any product not in the built-in list that has a single global markdown file — add it to `state.json` so Loop 1 syncs it too. See `references/custom-sync-targets.md`.
- Per-target hash state; per-target fail-closed on external edit
- Runs silently (no user notification)
- Tier 2 / 3 targets (JSON/YAML fields, project-local) planned for future versions

**Loop 2 — Daily reorg scan**:
- Cron: `23 21 * * *` (daily ~21:23)
- Scans: CLAUDE.md health (line-count thresholds), skill changes, AutoMemory new files, symlink consistency
- Appends a daily report to `~/.claude/reorg-log/<date>.md`
- Suggests migrations but never executes without user confirmation
- Runs with `notifyOnCompletion: true` so user sees the nightly report

**Register using** `mcp__scheduled-tasks__create_scheduled_task`. Target IDs: `memory-sync-agents` and `memory-reorg-scan`.

---

## Completion report

At the very end, print a summary to chat and append to `~/.claude/reorg-log/<date>.md`:

- CLAUDE.md: X lines (target < 150)
- Skills: N total (M newly created, K merged)
- Products scanned: list with detection status
- Archive: `~/.claude/archive-<date>/` with Y files totaling Z KB
- Loops registered: Loop 1 (if applicable) + Loop 2
- Out-of-scope products (e.g., Cowork): listed for user awareness, no action taken
- Rollback: "Run `bash ~/.claude/archive-<date>/rollback.sh` to restore (script generated during Phase 2)"

---

## Boundaries & anti-patterns

- **Don't invent content**. If a section has no source material, leave it empty with a `<!-- TODO: fill when info available -->` comment.
- **Don't suggest plugin packaging**. CoWork plugin mount bug (#31542) makes that path unreliable and Cowork sync is out of scope anyway.
- **Don't touch `settings.json`**. Only read it.
- **Don't move other products' source files** (like `.cursorrules`) unless user explicitly asks. They serve that product; consolidation means copying content into CLAUDE.md/skills, not stealing the source.
- **Don't try to sync Cowork Global Instructions**. Server-side; no local API. Out of scope for this skill's v1.
- **Don't try to read ChatGPT / Gemini / Copilot / Claude.ai server-side custom instructions**. Mention them in the diagnostic report as "manual reference" and let the user paste if they want to include that content.
