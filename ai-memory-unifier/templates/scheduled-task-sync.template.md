---
name: memory-sync-agents
description: Daily at ~09:17 — sync ~/.claude/CLAUDE.md → detected downstream AI agent memory files (Codex AGENTS.md, Gemini GEMINI.md, Windsurf global_rules.md). Hash-idempotent per target, fail-closed on external conflict.
---

You are the "Memory Sync Loop". Run once per day.

Your job: **mechanically copy** `~/.claude/CLAUDE.md` into every detected downstream AI agent's global memory file (Tier 1 raw-markdown targets). Do not rewrite, summarize, or re-format content. The only added content is a single header comment on each target.

## Sync targets

**Targets are data-driven**: Loop 1 reads the full list from `~/.claude/reorg-log/state.json` → `targets` map. Users can add their own without touching this template.

**Built-in Tier 1 targets** (auto-populated in state.json on first run):

```
codex        →  ~/.codex/AGENTS.md                               (Codex CLI)
gemini-cli   →  ~/.gemini/GEMINI.md                              (Gemini CLI)
windsurf     →  ~/.codeium/windsurf/memories/global_rules.md     (Windsurf)
```

**User-added custom targets** (optional): any raw-markdown global file. Users edit `state.json` to add entries like:

```json
"my-internal-agent": {
  "path": "~/.my-agent/INSTRUCTIONS.md",
  "format": "raw-md",
  "enabled": true,
  "last_target_hash": "",
  "last_synced_at": null
}
```

See `references/custom-sync-targets.md` for how to add, disable, or remove custom targets.

**Activation rules per target**:
- `enabled: false` → skipped ("disabled")
- `format` other than `raw-md` → skipped ("Tier 2+ not yet supported")
- Parent directory doesn't exist → skipped ("not installed")
- Otherwise → synced with header comment

Tier 2 (structured-config) and Tier 3 (project-local) writes are planned for future versions; for now `format: raw-md` is the only handled format.

## Execution

Run the following bash. Do not deviate.

```bash
set -uo pipefail

STATE=~/.claude/reorg-log/state.json
LOCK=~/.claude/reorg-log/.loop1.lock
TODAY=$(date +%Y-%m-%d)
LOG=~/.claude/reorg-log/$TODAY.md
mkdir -p ~/.claude/reorg-log

# Acquire lock
exec 9> "$LOCK"
if ! flock -n 9; then echo "Loop 1 already running, exit"; exit 0; fi

# Initialize or migrate state.json
python3 <<'PY'
import json, datetime as dt
from pathlib import Path

state_path = Path.home() / ".claude/reorg-log/state.json"
home = str(Path.home())

default_targets = {
    "codex":      {"path": home + "/.codex/AGENTS.md",
                   "format": "raw-md", "enabled": True,
                   "last_target_hash": "", "last_synced_at": None},
    "gemini-cli": {"path": home + "/.gemini/GEMINI.md",
                   "format": "raw-md", "enabled": True,
                   "last_target_hash": "", "last_synced_at": None},
    "windsurf":   {"path": home + "/.codeium/windsurf/memories/global_rules.md",
                   "format": "raw-md", "enabled": True,
                   "last_target_hash": "", "last_synced_at": None},
}

if not state_path.exists():
    state = {
        "version": 2,
        "last_claude_hash": "",
        "targets": default_targets,
        "initialized_at": dt.datetime.now().isoformat(),
    }
else:
    state = json.load(open(state_path))
    # v1 → v2 migration
    if state.get("version", 1) < 2:
        migrated = {
            "version": 2,
            "last_claude_hash": state.get("last_claude_hash", ""),
            "targets": default_targets,
            "initialized_at": state.get("initialized_at", ""),
        }
        # Preserve old codex hash
        migrated["targets"]["codex"]["last_target_hash"] = state.get("last_codex_hash", "")
        state = migrated
    # Ensure all default targets present (in case registry grew).
    # Does NOT overwrite user-added custom targets or user-modified enabled/path fields.
    for name, cfg in default_targets.items():
        state.setdefault("targets", {}).setdefault(name, cfg)
    # Backfill format/enabled on existing targets that predate these fields
    for name, tgt in state["targets"].items():
        tgt.setdefault("format", "raw-md")
        tgt.setdefault("enabled", True)
json.dump(state, open(state_path, "w"), indent=2)
PY

CLAUDE_MD=~/.claude/CLAUDE.md
CLAUDE_HASH=$(shasum -a 256 "$CLAUDE_MD" | awk '{print $1}')

LAST_CLAUDE=$(python3 -c "
import json
print(json.load(open('$STATE')).get('last_claude_hash',''))
")

# Quick skip: if CLAUDE.md hash hasn't changed since last successful sync, skip everything
if [ "$CLAUDE_HASH" = "$LAST_CLAUDE" ]; then
  echo "## Loop 1 @ $(date '+%H:%M:%S')" >> "$LOG"
  echo "- ⏭️  CLAUDE.md unchanged (hash=${CLAUDE_HASH:0:12}), skipping all targets" >> "$LOG"
  echo "" >> "$LOG"
  exit 0
fi

synced=()
skipped=()
conflicts=()
failed=()
disabled=()

# Iterate all targets declared in state.json (built-ins + user-added custom)
target_names=$(python3 -c "
import json
s = json.load(open('$STATE'))
print('\n'.join(s['targets'].keys()))
")

for target_name in $target_names; do
  # Per-target config
  target_info=$(python3 -c "
import json, os
s = json.load(open('$STATE'))
t = s['targets']['$target_name']
print(os.path.expanduser(os.path.expandvars(t['path'])))
print('1' if t.get('enabled', True) else '0')
print(t.get('format', 'raw-md'))
")
  target_path=$(echo "$target_info" | sed -n '1p')
  target_enabled=$(echo "$target_info" | sed -n '2p')
  target_format=$(echo "$target_info" | sed -n '3p')

  # Skip disabled
  if [ "$target_enabled" != "1" ]; then
    disabled+=("$target_name")
    continue
  fi

  # Only raw-md supported in v1.2; skip Tier 2+ formats
  if [ "$target_format" != "raw-md" ]; then
    skipped+=("$target_name (format=$target_format, Tier 2+ not yet supported)")
    continue
  fi

  target_parent=$(dirname "$target_path")

  # Skip if product not installed (parent dir doesn't exist)
  if [ ! -d "$target_parent" ]; then
    skipped+=("$target_name (not installed: $target_parent missing)")
    continue
  fi

  # Conflict detection
  last_target_hash=$(python3 -c "
import json
print(json.load(open('$STATE'))['targets']['$target_name'].get('last_target_hash',''))
")

  current_target_hash=""
  [ -f "$target_path" ] && current_target_hash=$(shasum -a 256 "$target_path" | awk '{print $1}')

  if [ -n "$current_target_hash" ] && [ -n "$last_target_hash" ] && [ "$current_target_hash" != "$last_target_hash" ]; then
    conflicts+=("$target_name: expected=${last_target_hash:0:12} actual=${current_target_hash:0:12}")
    continue
  fi

  # Atomic write: tmp + rename
  mkdir -p "$target_parent"
  TMP=$(mktemp)
  {
    printf '<!-- synced from ~/.claude/CLAUDE.md by ai-memory-unifier at %s -->\n\n' "$(date -Iseconds)"
    cat "$CLAUDE_MD"
  } > "$TMP"

  if mv "$TMP" "$target_path"; then
    new_hash=$(shasum -a 256 "$target_path" | awk '{print $1}')
    python3 -c "
import json, datetime as dt
s = json.load(open('$STATE'))
s['targets']['$target_name']['last_target_hash'] = '$new_hash'
s['targets']['$target_name']['last_synced_at'] = dt.datetime.now().isoformat()
json.dump(s, open('$STATE','w'), indent=2)
"
    synced+=("$target_name")
  else
    failed+=("$target_name (mv failed)")
  fi
done

# Only bump last_claude_hash if at least one target synced successfully
if [ ${#synced[@]} -gt 0 ]; then
  python3 -c "
import json
s = json.load(open('$STATE'))
s['last_claude_hash'] = '$CLAUDE_HASH'
json.dump(s, open('$STATE','w'), indent=2)
"
fi

# Write log entry
{
  echo "## Loop 1 @ $(date '+%H:%M:%S')"
  echo "- CLAUDE.md hash: ${CLAUDE_HASH:0:12}"
  [ ${#synced[@]}    -gt 0 ] && echo "- ✅ Synced: ${synced[*]}"
  if [ ${#skipped[@]}   -gt 0 ]; then
    echo "- ⏭️  Skipped:"
    for x in "${skipped[@]}"; do echo "  - $x"; done
  fi
  if [ ${#disabled[@]}  -gt 0 ]; then
    echo "- 💤 Disabled (enabled=false in state.json): ${disabled[*]}"
  fi
  if [ ${#conflicts[@]} -gt 0 ]; then
    echo "- ⚠️  Conflicts (fail-closed, needs review):"
    for x in "${conflicts[@]}"; do echo "  - $x"; done
  fi
  if [ ${#failed[@]}    -gt 0 ]; then
    echo "- ❌ Failed:"
    for x in "${failed[@]}"; do echo "  - $x"; done
  fi
  echo ""
} >> "$LOG"
```

## Output to chat (notifyOnCompletion=false recommended)

After the script, the loop prints nothing to chat by default (runs quietly). The log at `~/.claude/reorg-log/<today>.md` is the audit trail.

If the user wants periodic summaries, they can toggle `notifyOnCompletion=true` when registering the task.

## Rules

- **Do not** modify CLAUDE.md content.
- **Do not** modify downstream target content beyond the header comment.
- **Do not** ask the user for approval — silent background task.
- **Per-target fail-closed** — one conflict does not stop other targets.
- Skip all targets if CLAUDE.md hash matches last recorded (idempotent).
- On first run (state.json missing), initialize with empty hashes; first sync writes fresh content everywhere.

## Conflict resolution (document in log)

If `conflicts=[<target>]` appears in the log: the target's memory file was edited outside this loop. Either:

1. **Accept the external edit**: pull the content back into `~/.claude/CLAUDE.md`, next loop will re-sync from there
2. **Discard the external edit**: reset target state to current hash, next loop proceeds
   ```bash
   python3 -c "
   import json, hashlib
   from pathlib import Path
   target_name = '<conflicted-target>'
   s = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
   target_path = Path(s['targets'][target_name]['path']).expanduser()
   s['targets'][target_name]['last_target_hash'] = hashlib.sha256(target_path.read_bytes()).hexdigest()
   json.dump(s, open(Path.home() / '.claude/reorg-log/state.json', 'w'), indent=2)
   "
   ```
