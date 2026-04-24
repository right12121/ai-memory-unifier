# Custom sync targets

**The built-in registry only knows about mainstream products.** If you use a product we don't detect — an internal company agent, a regional tool like KimiClaw / Hermes, a fork, or something brand-new — you can still get it auto-synced by adding it to `~/.claude/reorg-log/state.json`.

## When this works

Only for **Tier 1** style targets:

- One global markdown file
- At a known absolute path (or `~/` / `$VAR` expandable)
- You're OK with the file being overwritten (with a `<!-- synced from ... -->` header) whenever `~/.claude/CLAUDE.md` changes

If your tool uses a JSON/YAML config field, or needs per-project files, this path does **not** work yet — see product-registry.md for the tier scheme.

## How it works under the hood

Loop 1 (`memory-sync-agents` scheduled task) iterates **every entry** in `state.json` → `targets`. There's no hardcoded list in the loop. Built-ins are just defaults populated on first run. Custom entries you add are treated identically.

## Add a custom target

Pick a short kebab-case ID (e.g., `hermes`, `kimi-claw`, `my-internal-agent`) and run:

```bash
python3 <<'PY'
import json
from pathlib import Path

NAME = "my-internal-agent"           # <-- change me
PATH = "~/.my-agent/INSTRUCTIONS.md"  # <-- change me

state_path = Path.home() / ".claude/reorg-log/state.json"
s = json.load(open(state_path))
s["targets"][NAME] = {
    "path": PATH,
    "format": "raw-md",
    "enabled": True,
    "last_target_hash": "",
    "last_synced_at": None,
}
json.dump(s, open(state_path, "w"), indent=2)
print(f"Added target: {NAME} → {PATH}")
PY
```

Next Loop 1 run (or manual "Run now" in Claude Desktop's Scheduled panel) will:

1. See your new target
2. If its parent directory exists, sync on next CLAUDE.md change
3. If the parent directory doesn't exist (product not installed), log as "skipped"

## Disable a target temporarily

Don't want a target to receive updates right now (but keep the entry for later)?

```bash
python3 -c "
import json
from pathlib import Path
NAME = 'gemini-cli'   # <-- change me
s = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
s['targets'][NAME]['enabled'] = False
json.dump(s, open(Path.home() / '.claude/reorg-log/state.json', 'w'), indent=2)
"
```

Re-enable: same snippet with `True`.

## Remove a target permanently

```bash
python3 -c "
import json
from pathlib import Path
NAME = 'my-internal-agent'   # <-- change me
s = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
s['targets'].pop(NAME, None)
json.dump(s, open(Path.home() / '.claude/reorg-log/state.json', 'w'), indent=2)
"
```

(Removing a built-in target like `codex` also works, but note: Loop 1's init block will re-add it on next run since it's a default. If you want to permanently exclude a built-in, use `enabled: false` instead.)

## List current targets

```bash
python3 -c "
import json
from pathlib import Path
s = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
for name, t in s['targets'].items():
    en = '✓' if t.get('enabled', True) else '✗'
    synced = t.get('last_synced_at', '—') or '—'
    print(f\"[{en}] {name:20s} {t['path']}  (synced: {synced})\")
"
```

## Edge cases

### The target file format isn't markdown

For now, the loop writes CLAUDE.md content as-is with a comment header. If your tool expects JSON/YAML/other, **don't** add it as `raw-md` — you'll corrupt the file. Wait for Tier 2 support.

Workaround: if the target accepts a "point at a file" config (like Aider's `--read` or a `systemPromptFile` option), point it at `~/.claude/CLAUDE.md` directly. Then you don't need Loop 1 to write anywhere at all.

### Your tool's memory directory doesn't exist until first use

No problem — the loop checks `dirname(path)` before writing. If the dir doesn't exist, the target is skipped with "not installed". Once the tool is used and creates its config dir, the next Loop 1 run will start syncing automatically.

### Two Claude machines, different custom target sets

state.json is per-machine (at `~/.claude/reorg-log/state.json`). If you want the same custom targets on both machines, run the add snippet on each.

### Security

`state.json` is a plain-text config you own. Loop 1 only reads the paths and writes CLAUDE.md content there. If you put a sensitive path in as a target, CLAUDE.md content will land there. Treat CLAUDE.md as non-secret (anyway, it's loaded into every AI session).

## Tell the skill about your target once, from Phase 6

If you're running the setup skill (`ai-memory-unifier`) and hit Phase 6, just say:

> Also add `<product name>` at `~/.my-path/INSTRUCTIONS.md` as a sync target.

Claude will run the add snippet for you and include it in the initial state.json. Same effect as running the bash manually.
