---
name: memory-sync-codex-agents
description: Daily at ~09:17 — sync ~/.claude/CLAUDE.md → ~/.codex/AGENTS.md. Hash-idempotent, fail-closed on external conflict.
---

You are Claude Code's "Memory Sync Loop 1". Run once per day.

Your job: **mechanically copy** `~/.claude/CLAUDE.md` to `~/.codex/AGENTS.md` when (and only when) the source has changed. Do not rewrite, summarize, or re-format the content. The only added content is a single header comment on the target.

## Execution

Run the following bash script. Do not deviate from this logic.

```bash
set -euo pipefail

STATE=~/.claude/reorg-log/state.json
LOCK=~/.claude/reorg-log/.loop1.lock
TODAY=$(date +%Y-%m-%d)
LOG=~/.claude/reorg-log/$TODAY.md
mkdir -p ~/.claude/reorg-log

# Acquire lock to prevent concurrent runs
exec 9> "$LOCK"
if ! flock -n 9; then echo "Loop 1 already running, exit"; exit 0; fi

# Initialize state.json if missing
[ -f "$STATE" ] || echo '{"last_claude_hash":"","last_codex_hash":""}' > "$STATE"

CLAUDE_HASH=$(shasum -a 256 ~/.claude/CLAUDE.md | awk '{print $1}')
LAST_CLAUDE=$(python3 -c "import json;print(json.load(open('$STATE')).get('last_claude_hash',''))")

# Skip if nothing changed
if [ "$CLAUDE_HASH" = "$LAST_CLAUDE" ]; then
  echo "## Loop 1 @ $(date '+%H:%M:%S')" >> "$LOG"
  echo "- ⏭️  CLAUDE.md unchanged (hash=${CLAUDE_HASH:0:12}), skipping sync" >> "$LOG"
  echo "" >> "$LOG"
  exit 0
fi

# Conflict detection: Codex AGENTS.md modified externally?
CODEX_HASH=""
[ -f ~/.codex/AGENTS.md ] && CODEX_HASH=$(shasum -a 256 ~/.codex/AGENTS.md | awk '{print $1}')
LAST_CODEX=$(python3 -c "import json;print(json.load(open('$STATE')).get('last_codex_hash',''))")

if [ -n "$CODEX_HASH" ] && [ "$CODEX_HASH" != "$LAST_CODEX" ] && [ -n "$LAST_CODEX" ]; then
  echo "## Loop 1 @ $(date '+%H:%M:%S') ⚠️ conflict" >> "$LOG"
  echo "- ❌ Codex AGENTS.md was modified outside this loop" >> "$LOG"
  echo "  - expected: ${LAST_CODEX:0:12}" >> "$LOG"
  echo "  - actual:   ${CODEX_HASH:0:12}" >> "$LOG"
  echo "- fail-closed — waiting for human review" >> "$LOG"
  exit 1
fi

# Atomic write: tmp + rename (never clobber partial content)
TMP=$(mktemp)
{
  printf '<!-- synced from ~/.claude/CLAUDE.md at %s -->\n\n' "$(date -Iseconds)"
  cat ~/.claude/CLAUDE.md
} > "$TMP"
mv "$TMP" ~/.codex/AGENTS.md

# Update state
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

## Output

After the script, report one of:
- `Loop 1 @ <HH:MM:SS> ✅ synced` (CLAUDE.md changed; Codex updated)
- `Loop 1 @ <HH:MM:SS> ⏭️ skipped` (no change since last sync)
- `Loop 1 @ <HH:MM:SS> ⚠️ conflict` (Codex AGENTS.md changed externally; needs human review)

## Rules

- **Do not** modify CLAUDE.md or AGENTS.md content beyond the header comment.
- **Do not** ask the user for approval — this is a silent background task.
- **Do not** "fix" the conflict by re-syncing. Exit non-zero and log; user investigates.
