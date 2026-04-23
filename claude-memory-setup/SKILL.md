---
name: claude-memory-setup
description: |
  Consolidate scattered Claude memory into a structured system: one global `~/.claude/CLAUDE.md`
  + N topic-specific skills + automated daily sync Loops + CoWork manual-sync path.
  Designed for existing mid/heavy Claude Code users whose AutoMemory, stray CLAUDE.md files,
  Codex AGENTS.md, and CoWork Global Instructions have all drifted out of alignment.

  Trigger on user utterances like: "help me organize my Claude memory", "整理 Claude 记忆",
  "整合 CLAUDE.md 和 skill", "clean up my AutoMemory", "set up Claude memory like Leo's",
  "migrate memory to skills", "give my Claude Code a memory framework".

  This is a GUIDED MIGRATION skill. It does NOT ask the user to fill blank templates. It scans
  what the user already has, proposes a classification, gets approval, and executes migration
  with full archiving + rollback.

  Process uses progressive disclosure: load `references/phase-<N>-*.md` for each phase detail.
---

# Claude Memory Setup

This skill guides Claude through a multi-phase migration that turns scattered memory artifacts into a clean, structured system. Default language: **English technical output; user-facing explanations mirror the user's language**.

## When this skill triggers

- User mentions organizing / consolidating / cleaning up Claude memory
- User references this skill by name (`/claude-memory-setup`)
- User asks to set up Claude memory "like Leo's" or "with a framework"

## When NOT to trigger

- User is asking a one-off question about CLAUDE.md syntax → just answer
- User has zero memory files and just wants a fresh CLAUDE.md → overkill; use a lightweight template approach
- User explicitly says "quick fix" or "only edit this one file"

---

## Phase map

```
Phase 0  Diagnose        (read-only scan of 4-6 memory sources)
Phase 1  Analyze         (classify files → propose CLAUDE.md sections + skills)
Phase 2  Archive setup   (create ~/.claude/archive-<date>/ + manifest.json)
Phase 3  Build CLAUDE.md (synthesize sections from scanned content)
Phase 4  Build skills    (create ~/.claude/skills/<name>/ directories)
Phase 5  Migrate         (mv source files into archive; NEVER direct delete)
Phase 6  Loops           (register 2 scheduled tasks: Codex sync + daily reorg)
Phase 7  CoWork guidance (optional; install pbcopy helper + instructions)
```

**Every phase requires explicit user approval before execution.** Skip-phase, adjust, or abort-at-any-time is always allowed.

Each phase has a detailed runbook in `references/phase-<N>-*.md` — load it on demand, not all at once.

---

## Core operating principles (read before starting)

### 1. Read-only → Propose → Approve → Execute

For phases 0–1: only read the filesystem, never modify. Present findings to the user first. Only act after explicit "yes, proceed".

### 2. Copy-first; never direct-delete

Phase 5 "migration" is actually `mv source → ~/.claude/archive-<date>/`. Archive is kept for at least 30 days. Users delete when they're ready.

### 3. SHA256 manifest for every file moved

Before moving any file, hash it and record `{source, archive, sha256, size, category, decision}` in `manifest-<date>.json`. This makes rollback precise and verifiable.

### 4. Dynamic detection, not assumed setup

Don't assume the user has Codex or CoWork. Check the filesystem:
- `~/.codex/` exists? → offer Loop 1 (Codex sync) + Codex skill symlinks
- `~/Library/Application Support/Claude/` shows CoWork sessions? → offer Phase 7
- No match? → skip that capability and tell the user why

### 5. Never modify settings.json automatically

The user likely has custom hooks, permissions, and plugins in `~/.claude/settings.json`. **Read-only** from this skill. If AutoMemory is out of control, *recommend* toggling `autoMemoryEnabled: false` but require explicit user confirmation to change.

### 6. Log everything

Append to `~/.claude/reorg-log/<date>.md` as each phase completes. The log is the audit trail and the rollback instruction sheet.

### 7. Progressive disclosure in this skill

- SKILL.md (this file) stays short (< 250 lines). Overview only.
- Details for each phase in `references/phase-<N>-*.md`.
- Templates in `templates/` are loaded when generating specific files.

---

## Phase 0 — Diagnose

**Intent**: enumerate every memory-relevant file/location; characterize the user's starting point.

**Load**: `references/phase-0-diagnose.md`

**Scan targets**:
1. `~/.claude/CLAUDE.md` — exists? line count? current sections?
2. `~/.claude/projects/*/memory/` — count files per project, total bytes
3. `~/.claude/skills/` — enumerate existing skills (distinguish real dirs vs symlinks)
4. Project-root `CLAUDE.md` files (common spots: `~/mine/`, `~/axon-web/`, any user-provided paths)
5. `~/.codex/AGENTS.md` + `~/.codex/skills/` if `~/.codex/` exists
6. `~/Library/Application Support/Claude/` presence → CoWork detected
7. `~/.claude/settings.json` for relevant flags: `autoMemoryEnabled`, `autoDreamEnabled`, `enabledPlugins`, `hooks`
8. Optional: third-party agent directories (`~/.openclaw/`, `~/.qclaw/` etc.) — ask user before scanning unknown dirs

**Output**: a diagnostic report (printed to chat) listing every source with file count, size, and any flags to call out. Ask the user to confirm before Phase 1.

---

## Phase 1 — Analyze & propose

**Intent**: read every candidate file; classify each into a target; propose a final structure.

**Load**: `references/phase-1-analyze.md`

**Classification labels** (apply per file):
- 🔵 **CLAUDE.md** — cross-project, high-frequency, identity/preference/rule content
- 🟢 **Existing skill** — fits an existing skill's topic (e.g., a feishu note → existing `feishu` skill)
- 🟡 **New skill** — topic is thick enough to stand alone
- ⚪ **Keep in place** — project-bound, low-frequency, fine where it is
- 🔴 **Archive only** — noise, duplicates, or expired info

**Propose**:
- CLAUDE.md target structure (sections, estimated line count; keep under 150)
- List of new skills to create (name + one-line description + source files)
- List of files going to archive-only

**User approval**: the user can edit classifications before Phase 2 starts. Common moves: "this one goes to CLAUDE.md, not a skill"; "merge these two into one skill"; "drop this entirely".

---

## Phase 2 — Archive setup

**Intent**: create the safety net before touching anything.

**Load**: `references/phase-5-migrate.md` (sections on archive layout + manifest schema)

**Actions**:
1. `mkdir -p ~/.claude/archive-<YYYY-MM-DD>/{projects,openclaw-extract,misc}`
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
2. For each 🔵-classified source file, extract key facts into the right section
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

After Phase 5:
- `~/.claude/projects/*/memory/` directories → moved to archive
- Old `~/mine/CLAUDE.md` or similar → archived (if merged into global)
- New `~/.claude/CLAUDE.md` + `~/.claude/skills/` → pristine, Claude Code should pick them up instantly

---

## Phase 6 — Register Loops

**Intent**: set up two durable scheduled tasks to keep the system healthy.

**Load**: `references/phase-6-loops.md` + `templates/scheduled-task-*.template.md`

**Loop 1 — Codex sync** (only if `~/.codex/` exists):
- Cron: `17 9 * * *` (daily ~09:17)
- Reads `~/.claude/CLAUDE.md`, checks SHA256 vs state; if changed, writes to `~/.codex/AGENTS.md` with header comment
- Fail-closed: refuses to overwrite if Codex AGENTS.md was manually edited outside this loop

**Loop 2 — Daily reorg scan**:
- Cron: `23 21 * * *` (daily ~21:23)
- Scans: CLAUDE.md health (line-count thresholds), skill changes, AutoMemory new files, symlink consistency
- Appends a daily report to `~/.claude/reorg-log/<date>.md`
- Suggests migrations but never executes without user confirmation

**Register using** `mcp__scheduled-tasks__create_scheduled_task` with `notifyOnCompletion: true` so the user sees results in Claude Desktop's notification panel.

---

## Phase 7 — CoWork guidance (optional)

**Intent**: handle the one-way sync to CoWork Global Instructions (server-stored; no local auto-sync API).

**Load**: `references/phase-7-cowork.md` + `templates/cowork-paste-helper.sh`

**Process** (only if CoWork detected):
1. Install `~/bin/cowork-paste-claude-md` helper (reads CLAUDE.md → pbcopy)
2. Print instructions for one-time paste into Cowork → Settings → Global Instructions
3. Explain issue #31542 (plugin mount bug) and why manual paste is the current recommended path
4. Note: whenever the user edits CLAUDE.md later, they should re-run `cowork-paste-claude-md` and re-paste

---

## Completion report

At the very end, print a summary to chat and append to `~/.claude/reorg-log/<date>.md`:

- CLAUDE.md: X lines (target < 150)
- Skills: N total (M newly created, K merged)
- Archive: `~/.claude/archive-<date>/` with Y files totaling Z KB
- Loops registered: Loop 1 (if applicable) + Loop 2
- CoWork: helper script installed (or skipped)
- Rollback: "Run `bash ~/.claude/archive-<date>/rollback.sh` to restore (script is generated as part of Phase 2)"

---

## Boundaries & anti-patterns

- **Don't invent content**. If a section has no source material, leave it empty with a `<!-- TODO: fill when info available -->` comment.
- **Don't suggest plugin packaging**. CoWork plugin mount bug makes this path unreliable. Phase 7 manual path is the recommended default.
- **Don't touch `settings.json`**. Only read it.
- **Don't bundle Leo-specific skills**. This skill is the framework, not the content.
- **Don't try to sync CoWork Global Instructions programmatically**. It's server-side; no API exposed.
