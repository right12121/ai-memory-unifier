# Changelog

All notable changes to this skill.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [1.1.0] — 2026-04-24

### Changed

- **Loop 1 is now multi-target** (was Codex-only in v1.0). Auto-detects and syncs `~/.claude/CLAUDE.md` into:
  - `~/.codex/AGENTS.md` (Codex CLI) — already in v1.0
  - `~/.gemini/GEMINI.md` (Gemini CLI) — **new**
  - `~/.codeium/windsurf/memories/global_rules.md` (Windsurf) — **new**
- Per-target hash state + per-target fail-closed conflict detection. One target's drift does not block other targets from syncing.
- Task ID renamed: `memory-sync-codex-agents` → `memory-sync-agents` (more general)
- Template renamed: `scheduled-task-sync-codex.template.md` → `scheduled-task-sync.template.md`
- `state.json` schema bumped to v2 (`targets` map). Loop 1 auto-migrates v1 state on first run (preserves old `last_codex_hash`).

### Added

- Sync tier classification in `references/product-registry.md`:
  - **Tier 1**: raw-markdown global files (auto-sync by Loop 1 now)
  - **Tier 2**: structured-config writes (Continue, Zed, Aider, Cline — planned v1.2)
  - **Tier 3**: project-local writes (Cursor, Amp — planned v1.3)
- Per-product writability annotation in registry

### Migration notes (from v1.0)

If you ran `ai-memory-unifier` at v1.0 and have a scheduled task called `memory-sync-codex-agents`:

1. Your existing task keeps running with the old prompt — no action required
2. To upgrade to multi-target: re-run the skill's Phase 6, or manually recreate the task with the new `memory-sync-agents` ID + template
3. `state.json` is backward-compatible — Loop 1 auto-migrates v1 state schema to v2 on first run

## [1.0.0] — 2026-04-24

Initial release under the name `ai-memory-unifier`.

### Scope

Unify scattered memory across multiple AI coding agents / CLIs / assistants into a single Claude Code–rooted structure. Supports detecting and reading from: Claude Code, Codex CLI, Cursor, Aider, Continue, Cline, Windsurf, Zed, Gemini CLI, Amp, Qclaw/OpenClaw, plus user-specified products.

Out of scope for v1: server-side products (Cowork Global Instructions, ChatGPT custom instructions, Claude.ai preferences, Gemini custom instructions, GitHub Copilot) — no local API to reliably read/write.

### Added

- `ai-memory-unifier/SKILL.md` — main entry point, 6-phase progressive-disclosure guided migration
- `ai-memory-unifier/references/product-registry.md` — canonical registry of AI products with detection methods and memory file locations; Phase 0 iterates this + asks user for additions
- `ai-memory-unifier/references/phase-0-diagnose.md` — read-only cross-product diagnostic scan
- `ai-memory-unifier/references/phase-1-analyze.md` — classification proposal (🔵 CLAUDE.md / 🟢 existing skill / 🟡 new skill / ⚪ keep / 🔴 archive)
- `ai-memory-unifier/references/phase-3-claude-md.md` — CLAUDE.md synthesis guide with line-count budget (community thresholds)
- `ai-memory-unifier/references/phase-4-skills.md` — skill creation + merging + Codex symlink setup
- `ai-memory-unifier/references/phase-5-migrate.md` — copy-first migration + SHA256 manifest + auto-generated rollback script (Claude Code's own files only; other products' sources are left intact)
- `ai-memory-unifier/references/phase-6-loops.md` — two daily scheduled tasks (Codex sync + cross-product reorg scan)
- `ai-memory-unifier/templates/CLAUDE.md.template` — canonical section skeleton
- `ai-memory-unifier/templates/skill.template.md` — frontmatter + content skeleton for new skills
- `ai-memory-unifier/templates/scheduled-task-sync-codex.template.md` — Loop 1 prompt (hash-idempotent, fail-closed)
- `ai-memory-unifier/templates/scheduled-task-reorg-scan.template.md` — Loop 2 prompt (auto-maintain symlinks, suggest migrations)
- `ai-memory-unifier/templates/state.json.template` — Loop 1 state schema
- `ai-memory-unifier/templates/manifest.json.template` — migration manifest schema
- Bilingual (EN/中文) `README.md`
- `INSTALL.md` with first-run walkthrough + troubleshooting
- MIT `LICENSE` (attribution: right12121)
