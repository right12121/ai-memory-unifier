# Changelog

All notable changes to this skill.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [1.0.0] — 2026-04-24

Initial release.

### Added

- `SKILL.md` — main entry point, 7-phase progressive-disclosure skill
- `references/phase-0-diagnose.md` — diagnostic scan (read-only inventory of 4-6 memory sources)
- `references/phase-1-analyze.md` — classification proposal (🔵 CLAUDE.md / 🟢 existing skill / 🟡 new skill / ⚪ keep / 🔴 archive)
- `references/phase-3-claude-md.md` — CLAUDE.md generation guide with line-count budget (community thresholds)
- `references/phase-4-skills.md` — skill creation + merging + Codex symlink setup
- `references/phase-5-migrate.md` — copy-first migration + SHA256 manifest + auto-generated rollback script
- `references/phase-6-loops.md` — two daily scheduled tasks (Codex sync + reorg scan)
- `references/phase-7-cowork.md` — CoWork manual-paste workflow (server-side limitation)
- `templates/CLAUDE.md.template` — skeleton with canonical sections
- `templates/skill.template.md` — frontmatter + content skeleton
- `templates/scheduled-task-sync-codex.template.md` — Loop 1 prompt (hash-idempotent, fail-closed)
- `templates/scheduled-task-reorg-scan.template.md` — Loop 2 prompt (auto-maintain symlinks, suggest migrations)
- `templates/state.json.template` — state file format for Loop 1
- `templates/manifest.json.template` — migration manifest schema
- `templates/cowork-paste-helper.sh` — pbcopy helper for CoWork Global Instructions
- Bilingual (EN/中文) README.md
- INSTALL.md with first-run walkthrough + troubleshooting
- MIT LICENSE
