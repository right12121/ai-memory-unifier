# Phase 0 — Diagnostic inventory

Read-only scan. Never write anything during this phase.

## Goal

Produce a single diagnostic report that tells the user exactly what memory artifacts exist on their machine and where they are. This is also the primary input for Phase 1 (classification).

## Scan order & commands

### 1. Global CLAUDE.md

```bash
if [ -f ~/.claude/CLAUDE.md ]; then
  wc -l ~/.claude/CLAUDE.md
  wc -c ~/.claude/CLAUDE.md
  head -n 1 ~/.claude/CLAUDE.md
  grep -c '^## ' ~/.claude/CLAUDE.md
fi
```

Record: exists? line count? byte count? section count? first-line (for title context).

### 2. AutoMemory projects

```bash
find ~/.claude/projects -maxdepth 2 -type d -name memory 2>/dev/null
```

For each `memory/` directory found:

```bash
ls -la <memory_dir>
find <memory_dir> -maxdepth 1 -name '*.md' -type f | wc -l
du -sh <memory_dir>
```

**Deduplicate**: macOS filesystem is case-insensitive by default, and some project paths are symlinked (e.g., `-Users-bytedance-love` → `-Users-bytedance-mine-Love`). Use `readlink` and inode comparison to avoid double-counting.

For each unique `memory/` dir, list:
- Project path (decoded: `-Users-bytedance-mine-thebrainly` → `~/mine/thebrainly`)
- File count
- Total size
- Oldest + newest mtime

### 3. Existing skills

```bash
ls -la ~/.claude/skills/
```

Distinguish:
- Real directories (user-managed personal skills)
- Symlinks (typically to plugins — follow the link and note target)
- Stray files (unusual; flag for user)

For each real skill dir, `head -10 <skill>/SKILL.md` to extract `name:` and first line of `description:`.

### 4. Project-root CLAUDE.md files

**Don't go hunting**. Ask the user which project roots they use, or default to scanning:

```bash
find ~ -maxdepth 3 -name 'CLAUDE.md' -type f -not -path '*/.claude/*' -not -path '*/node_modules/*' 2>/dev/null
```

(Cap depth at 3 to avoid runaway scans of node_modules / archives.)

For each hit: filepath, line count. Flag any that look substantive (>30 lines) — user may want to consolidate.

### 5. Codex detection

```bash
[ -d ~/.codex ] && {
  ls -la ~/.codex/
  [ -f ~/.codex/AGENTS.md ] && wc -l ~/.codex/AGENTS.md
  [ -d ~/.codex/skills ] && ls ~/.codex/skills/
  [ -f ~/.codex/config.toml ] && grep -E 'model|profile' ~/.codex/config.toml | head -5
}
```

Record: Codex present? AGENTS.md exists and its size? Existing Codex skills (distinguish Codex system skills: `.system`, `find-skills`, `playwright` from user-added ones)?

### 6. CoWork detection

```bash
if [ -d ~/Library/Application\ Support/Claude ]; then
  ls ~/Library/Application\ Support/Claude/ | grep -iE 'cowork|local-agent|claude-code-sessions'
fi
```

If any hit → CoWork detected. Note: we can't read Global Instructions (server-stored, encrypted in Local Storage leveldb); don't try.

### 7. settings.json flags

```bash
if [ -f ~/.claude/settings.json ]; then
  python3 -c "
import json
s = json.load(open('$HOME/.claude/settings.json'))
print('autoMemoryEnabled:', s.get('autoMemoryEnabled', 'default (on)'))
print('autoDreamEnabled:', s.get('autoDreamEnabled', 'default'))
print('model:', s.get('model', 'default'))
print('enabledPlugins:', list((s.get('enabledPlugins') or {}).keys()))
print('has hooks:', bool(s.get('hooks')))
"
fi
```

Record settings. Don't mutate.

### 8. Third-party agent directories (ask first)

Common locations: `~/.openclaw/`, `~/.qclaw/`, `~/.aider/`, `~/.cursor/`, etc.

**Ask the user**: "Do you use any other local AI agent that has its own memory? Point me at the directory if so."

Don't auto-scan unknown dotdirs — privacy + noise.

## Diagnostic report format

Present as markdown with a clear top-down structure:

```markdown
# 📋 Memory Inventory — <today>

## ~/.claude/CLAUDE.md
- Size: X lines / Y bytes
- Sections: [Identity, People, …]  (or "empty")

## AutoMemory (~/.claude/projects/*/memory/)
| Project | Files | Size | Latest change |
|---------|-------|------|---------------|
| `~/mine/thebrainly` | 10 | 42 KB | 2026-04-15 |
| `~/mine/Love` | 4 | 12 KB | 2026-04-10 |

## Existing skills (~/.claude/skills/)
- `feishu` (real dir) — "飞书 API 凭证 + OAuth Token 管理 + 常用 API"
- `lante-app` (real dir) — "Lante APP 完整设计规范"
- `find-skills` (symlink → …) — built-in

## Project-root CLAUDE.md files
- `~/mine/CLAUDE.md` — 27 lines  ← **candidate for merge**
- `~/axon-web/CLAUDE.md` — 120 lines  ← project-specific, keep

## Codex
- Detected at `~/.codex/`
- `AGENTS.md` empty
- Skills: [.system, find-skills, playwright] (system only)

## CoWork
- Desktop app usage detected
- Local sessions in ~/Library/Application Support/Claude/

## Active settings
- autoMemoryEnabled: on (default)
- autoDreamEnabled: true
- Model: opus[1m]

## Flags for attention
- 🔴 ~/mine/CLAUDE.md overlaps with ~/.claude/CLAUDE.md (merge candidate)
- 🟡 AutoMemory total = 54 KB across 14 files (below 500 KB alert threshold)
```

End with: **"Ready to proceed to Phase 1 (analysis & proposal)?"**

## Edge cases

- **User has zero memory artifacts**: Report "Nothing to migrate. You may still benefit from the templates — would you like me to scaffold a starter CLAUDE.md instead?" Offer `templates/CLAUDE.md.template` as a starting skeleton.
- **User has only project-root CLAUDE.md, no AutoMemory**: simpler migration path; skip AutoMemory-related logic.
- **User has massive AutoMemory (>100 files)**: flag and recommend starting with dry-run mode; suggest asking user if they want AutoMemory turned off before continuing.
- **Symlinks across skills**: trace them once so we don't double-process; include the original target path in the manifest.
