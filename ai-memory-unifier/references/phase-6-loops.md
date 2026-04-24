# Phase 6 — Register automated Loops

Two scheduled tasks keep the consolidated memory system healthy without daily user involvement.

## Tooling

Use `mcp__scheduled-tasks__create_scheduled_task` (Claude Desktop's durable scheduled task API). Tasks persist across Claude Desktop restarts; state kept in `~/.claude/scheduled-tasks/<taskId>/`.

Set `notifyOnCompletion: true` so the user sees output in Desktop's notification panel.

## Loop 1 — CLAUDE.md → Codex AGENTS.md sync

**When**: only if `~/.codex/` exists on the user's machine.

**Cron**: `17 9 * * *` (daily at ~09:17; Claude Desktop adds a small jitter).

**Task ID**: `memory-sync-codex-agents`

**Full prompt** (load from `templates/scheduled-task-sync-codex.template.md` — here's the gist):

```
You are Claude Code's "Memory Sync Loop 1". Run once per day, syncing
~/.claude/CLAUDE.md → ~/.codex/AGENTS.md. Hash-idempotent, fail-closed.

Logic (bash):

STATE=~/.claude/reorg-log/state.json
LOCK=~/.claude/reorg-log/.loop1.lock
TODAY=$(date +%Y-%m-%d)
LOG=~/.claude/reorg-log/$TODAY.md

exec 9> "$LOCK"
if ! flock -n 9; then echo "Loop 1 already running, exit"; exit 0; fi

[ -f "$STATE" ] || echo '{"last_claude_hash":"","last_codex_hash":""}' > "$STATE"

CLAUDE_HASH=$(shasum -a 256 ~/.claude/CLAUDE.md | awk '{print $1}')
LAST_CLAUDE=$(python3 -c "import json;print(json.load(open('$STATE')).get('last_claude_hash',''))")

if [ "$CLAUDE_HASH" = "$LAST_CLAUDE" ]; then
  echo "## Loop 1 @ $(date '+%H:%M:%S')" >> "$LOG"
  echo "- ⏭️  CLAUDE.md unchanged (hash=${CLAUDE_HASH:0:12}), skipping sync" >> "$LOG"
  echo "" >> "$LOG"
  exit 0
fi

# Conflict detection: if Codex AGENTS.md changed externally, bail
CODEX_HASH=""
[ -f ~/.codex/AGENTS.md ] && CODEX_HASH=$(shasum -a 256 ~/.codex/AGENTS.md | awk '{print $1}')
LAST_CODEX=$(python3 -c "import json;print(json.load(open('$STATE')).get('last_codex_hash',''))")

if [ -n "$CODEX_HASH" ] && [ "$CODEX_HASH" != "$LAST_CODEX" ] && [ -n "$LAST_CODEX" ]; then
  echo "## Loop 1 @ $(date '+%H:%M:%S') ⚠️ conflict" >> "$LOG"
  echo "- ❌ Codex AGENTS.md was modified outside this loop (hash=${CODEX_HASH:0:12}, expected=${LAST_CODEX:0:12})" >> "$LOG"
  echo "- fail-closed — waiting for human review" >> "$LOG"
  exit 1
fi

# Atomic write: tmp + rename
TMP=$(mktemp)
{ printf '<!-- synced from ~/.claude/CLAUDE.md at %s -->\n\n' "$(date -Iseconds)"; cat ~/.claude/CLAUDE.md; } > "$TMP"
mv "$TMP" ~/.codex/AGENTS.md

NEW_CODEX_HASH=$(shasum -a 256 ~/.codex/AGENTS.md | awk '{print $1}')
python3 -c "
import json
s = json.load(open('$STATE'))
s['last_claude_hash'] = '$CLAUDE_HASH'
s['last_codex_hash'] = '$NEW_CODEX_HASH'
json.dump(s, open('$STATE','w'), indent=2)
"

echo "## Loop 1 @ $(date '+%H:%M:%S') ✅ synced" >> "$LOG"
echo "- CLAUDE.md hash: ${CLAUDE_HASH:0:12}" >> "$LOG"
echo "- Codex AGENTS.md hash: ${NEW_CODEX_HASH:0:12}" >> "$LOG"
echo "" >> "$LOG"
```

**After running**: report `Loop 1 @ <time> — <status>` where status is ✅ synced / ⏭️ skipped / ⚠️ conflict.

**Never modify** CLAUDE.md or AGENTS.md content (beyond the sync header). This is a raw copy, not a rewrite.

## Loop 2 — Daily reorg scan + maintenance

**Cron**: `23 21 * * *` (daily at ~21:23; one side-ish from Loop 1)

**Task ID**: `memory-reorg-scan`

**Intent**: one nightly sanity pass. Detects drift, maintains symlinks, reminds the user to migrate new AutoMemory items.

**Full prompt** (load from `templates/scheduled-task-reorg-scan.template.md`). Highlights:

### Section 1: CLAUDE.md health
Line count thresholds (same as Phase 3's budget):
- ≤ 100: ✅ lean
- 101-150: ✅ healthy
- 151-200: ⚠️ consider splitting
- \> 200: 🔴 strongly recommend splitting

If > 200, suggest 2-3 candidate sections to move to skills.

### Section 2: Skill changes + symlink maintenance (auto-execute)

Source of truth: `~/.claude/skills/<name>/` (real dirs)
Mirrors: `~/.codex/skills/<name>` (symlinks)

Sweep:

```bash
SOURCE_DIR=~/.claude/skills
MIRRORS=(~/.codex/skills)  # CoWork removed since it doesn't read here

for mirror in "${MIRRORS[@]}"; do
  [ -d "$mirror" ] || continue
  # Ensure every real skill source has a symlink in the mirror
  for src in "$SOURCE_DIR"/*/; do
    name=$(basename "$src")
    [ -L "$SOURCE_DIR/$name" ] && continue  # skip symlinks (like find-skills)
    target="$mirror/$name"
    if [ ! -L "$target" ] || [ "$(readlink "$target")" != "$SOURCE_DIR/$name" ]; then
      ln -sfn "$SOURCE_DIR/$name" "$target"
      # log "added $target"
    fi
  done
  # Clean orphan symlinks (target gone)
  for link in "$mirror"/*; do
    [ -L "$link" ] || continue
    name=$(basename "$link")
    case "$name" in .system|find-skills|playwright) continue ;; esac
    if [ ! -d "$SOURCE_DIR/$name" ] || [ -L "$SOURCE_DIR/$name" ]; then
      rm "$link"
      # log "removed orphan $link"
    fi
  done
done
```

### Section 3: AutoMemory scan

```bash
find ~/.claude/projects/*/memory -maxdepth 2 -name '*.md' -newermt "24 hours ago" 2>/dev/null
```

For each file created in last 24h, give a classification suggestion:
- 🔵 move to CLAUDE.md
- 🟢 merge into existing skill `<name>`
- 🟡 worth a new skill
- ⚪ keep in place
- 🔴 archive

Suggestions only — don't auto-execute.

### Section 4: AutoMemory volume

```bash
COUNT=$(find ~/.claude/projects/*/memory -name '*.md' 2>/dev/null | wc -l)
SIZE=$(du -sh ~/.claude/projects 2>/dev/null | awk '{print $1}')
```

If file count > 50 or size > 500 KB, alert.

### Output format

Append to `~/.claude/reorg-log/<today>.md`:

```markdown
## Loop 2 @ <HH:MM:SS>

### 1. CLAUDE.md health
- Lines: N / Bytes: N / mtime: <date>
- Status: ✅/⚠️/🔴 <reason>

### 2. Skill changes + symlink maintenance
- Added: <list>
- Removed orphans: <list>
- (no changes if empty)

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

## Registration API

```
mcp__scheduled-tasks__create_scheduled_task(
  taskId="memory-sync-codex-agents",
  cronExpression="17 9 * * *",
  description="Daily 9:17 — sync CLAUDE.md to Codex AGENTS.md (hash-idempotent, fail-closed on conflict)",
  notifyOnCompletion=false,       # runs quietly
  prompt=<loop-1-prompt-above>
)

mcp__scheduled-tasks__create_scheduled_task(
  taskId="memory-reorg-scan",
  cronExpression="23 21 * * *",
  description="Daily 21:23 — scan CLAUDE.md / skills / AutoMemory, maintain symlinks, suggest migrations",
  notifyOnCompletion=true,        # user sees the nightly report
  prompt=<loop-2-prompt-above>
)
```

## State file

Canonical format in `templates/state.json.template`:

```json
{
  "last_claude_hash": "<SHA256 of CLAUDE.md>",
  "last_codex_hash": "<SHA256 of Codex AGENTS.md>",
  "initialized_at": "<ISO datetime>"
}
```

Path: `~/.claude/reorg-log/state.json`. Initialize once at the end of Phase 6 using the template (substitute `__ISO_DATETIME__`), or let Loop 1 bootstrap it on first run.

## Test immediately

After registering, execute each loop once manually (from Claude Desktop's Scheduled panel → "Run now") so the user sees:
- permission prompts get approved upfront (so nightly runs don't pause)
- output is sane
- state.json gets initialized

## Skip Loop 1 entirely if no Codex

If `~/.codex/` doesn't exist, create only Loop 2. In chat, note:
> Codex not detected — skipping Loop 1. If you install Codex later, re-run this skill and it will register Loop 1 for you.

## Edge cases

- **User has multiple Claude Desktop installations**: scheduled tasks are per-install. Nothing to do here.
- **CLAUDE.md modified in flight during Loop 1 run**: atomic rename protects the reader; worst case a Loop 1 run misses this edit, next run catches it.
- **state.json corrupted**: loop logs the error and exits non-zero. User rebuilds state.json from current hashes manually.
