---
name: memory-reorg-scan
description: Daily at ~21:23 — three-way scan (CLAUDE.md health / skills / AutoMemory) + auto-maintain symlinks + suggest migrations. Proposes only; never executes migrations.
---

You are Claude Code's "Memory Reorg Loop 2". Run once per day. Scan the past 24h for changes, auto-maintain symlinks, and propose migration actions. **Never execute migrations** — suggest only.

## Output

Write a complete report to `~/.claude/reorg-log/<today>.md` (append) AND paste the same report back to chat (if notifyOnCompletion=true).

Structure:

```markdown
## Loop 2 @ <HH:MM:SS>

### 1. CLAUDE.md health
- Lines: N / Bytes: N / mtime: <date>
- Status: ✅/⚠️/🔴 <reason>

### 2. Skill changes + symlink maintenance
- Added symlinks: <list>
- Removed orphan symlinks: <list>
- Newly created skills: <list>
- (if none: "no changes")

### 3. AutoMemory new files (past 24h)
<list with classification suggestions>

### 4. AutoMemory volume
- Files: N
- Size: X KB
- Status: ✅/⚠️

### 📋 Suggested actions (pending your confirmation)
- [ ] <action 1>
- [ ] <action 2>
```

## Scan details

### 1. CLAUDE.md health

```bash
LINES=$(wc -l < ~/.claude/CLAUDE.md)
BYTES=$(wc -c < ~/.claude/CLAUDE.md)
MTIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" ~/.claude/CLAUDE.md 2>/dev/null || stat -c "%y" ~/.claude/CLAUDE.md | cut -d'.' -f1)
```

Four thresholds (community-tested):
- `≤ 100`: ✅ **lean** (ideal)
- `101 – 150`: ✅ **healthy**
- `151 – 200`: ⚠️ **consider splitting** — identify 2-3 section candidates to move to skills
- `> 200`: 🔴 **strongly recommend refactor** — list top candidates with line counts

### 2. Skill changes + symlink maintenance (auto-execute)

Scan skills changed in the past 24h:

```bash
find ~/.claude/skills -maxdepth 3 -name SKILL.md -newermt "24 hours ago"
```

For each change, report it.

Then **auto-maintain symlinks** (execute, don't ask):

```bash
SOURCE_DIR=~/.claude/skills
MIRRORS=()
[ -d ~/.codex/skills ] && MIRRORS+=(~/.codex/skills)

for mirror in "${MIRRORS[@]}"; do
  # Ensure every real skill source has a symlink
  for src in "$SOURCE_DIR"/*/; do
    name=$(basename "$src")
    [ -L "$SOURCE_DIR/$name" ] && continue  # skip symlinks like find-skills
    target="$mirror/$name"
    if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$SOURCE_DIR/$name" ]; then
      ln -sfn "$SOURCE_DIR/$name" "$target"
      echo "Added symlink: $target"
    fi
  done
  # Clean orphan symlinks (target no longer exists)
  for link in "$mirror"/*; do
    [ -L "$link" ] || continue
    name=$(basename "$link")
    case "$name" in .system|find-skills|playwright) continue ;; esac
    if [ ! -d "$SOURCE_DIR/$name" ] || [ -L "$SOURCE_DIR/$name" ]; then
      rm "$link"
      echo "Removed orphan: $link"
    fi
  done
done
```

### 3. AutoMemory new files

```bash
find ~/.claude/projects/*/memory -maxdepth 2 -name '*.md' -newermt "24 hours ago" 2>/dev/null
```

For each file created/modified in past 24h:
- Read the content (up to 200 lines)
- Summarize in one sentence
- Suggest classification using the same taxonomy as Phase 1:
  - 🔵 merge into `~/.claude/CLAUDE.md`
  - 🟢 merge into existing skill `<name>`
  - 🟡 new skill `<name>` (worth standing alone)
  - ⚪ keep in place (project-bound, low freq)
  - 🔴 archive (noise)

These are **suggestions only** — user reviews and confirms before anything moves.

### 4. AutoMemory volume

```bash
COUNT=$(find ~/.claude/projects/*/memory -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
SIZE_KB=$(du -sk ~/.claude/projects 2>/dev/null | awk '{print $1}')
```

- `COUNT ≤ 50 AND SIZE_KB ≤ 500`: ✅ healthy
- `COUNT > 50 OR SIZE_KB > 500`: ⚠️ **growing** — recommend triggering this skill's Phase 1 analysis to migrate

## Rules

- **Auto-execute**: only the symlink maintenance in Section 2. Everything else is propose-only.
- **Log even when nothing changed** — a line like `## Loop 2 @ 21:23 — ✅ no changes` is fine.
- **Don't load tool-heavy skills** — this loop should be fast. Pure bash + basic file reading.
- **Don't spam notifications** if nothing changed. If all sections are ✅ and no suggestions: emit minimal output.
