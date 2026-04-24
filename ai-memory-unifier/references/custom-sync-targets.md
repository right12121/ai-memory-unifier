# Custom sync targets — post-setup reference

> **Primary path**: tell Claude during Phase 0 (the kickoff interview).
> Claude will write `state.json` for you — you never need to touch JSON by hand during normal setup.
>
> This doc is for **after** setup: tweaking, adding, disabling, removing targets
> later on. You don't read this during your first run.

Loop 1 iterates every entry in `~/.claude/reorg-log/state.json` → `targets`. You can tell Claude to add, remove, or toggle a target any time — just say:

> "Add KimiClaw as a sync target at `~/.kimi/RULES.md`"
> "Disable gemini-cli sync for now"
> "Remove the my-internal-agent target"
> "What sync targets do I have right now?"

Claude will do the config edit itself. You don't have to run Python.

The rest of this doc is a **reference** for the underlying schema + manual snippets, in case:
- You're debugging and want to see what the file looks like
- You want to script a change yourself
- Claude isn't available (offline tweak)

---

## state.json target schema

```json
"<target-id>": {
  "path": "<absolute-or-tilde-expandable path>",
  "format": "raw-md",
  "enabled": true,
  "last_target_hash": "<SHA256, managed by loop>",
  "last_synced_at": "<ISO datetime, managed by loop>"
}
```

Fields:
- **`path`** — absolute path (supports `~` and `$VAR`)
- **`format`** — only `raw-md` is handled by Loop 1 in v1.3. Future: `json-field`, `yaml-field`, `project-md`
- **`enabled`** — `false` = temporarily skip without removing
- **`last_target_hash`** / **`last_synced_at`** — internal, don't edit manually

## Manual snippets (for the rare case you want to bypass Claude)

### Add a target

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
print(f"Added: {NAME}")
PY
```

### Disable / re-enable

```bash
python3 -c "
import json
from pathlib import Path
NAME, ENABLED = 'gemini-cli', False   # or True to re-enable
s = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
s['targets'][NAME]['enabled'] = ENABLED
json.dump(s, open(Path.home() / '.claude/reorg-log/state.json', 'w'), indent=2)
"
```

### Remove a target

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

> Note: removing a built-in like `codex` works, but Loop 1's init block will re-add it (as default) on next run. Use `enabled: false` instead to permanently exclude a built-in.

### List current targets

```bash
python3 -c "
import json
from pathlib import Path
s = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
for name, t in s['targets'].items():
    en = '✓' if t.get('enabled', True) else '✗'
    synced = t.get('last_synced_at', '—') or '—'
    print(f'[{en}] {name:20s} {t[\"path\"]}  (synced: {synced})')
"
```

## Edge cases

### Non-markdown format

Claude won't let you add a target as `raw-md` if it's actually JSON / YAML. If you bypass the interview and hand-add a non-markdown target as `raw-md`, you'll corrupt your config on first sync. Tier 2 support is planned for v1.4+.

**Workaround for now**: if your tool supports a "point at a file" config (Aider's `--read`, some tools' `systemPromptFile` option), point it at `~/.claude/CLAUDE.md` directly. No Loop 1 writing needed.

### Target's directory doesn't exist yet

That's fine. Loop 1 checks parent-dir existence per target and silently skips missing ones. When you install the tool later and its directory appears, next Loop 1 run picks it up.

### Two machines, different target sets

`state.json` is per-machine. To keep machines in sync, add the same targets via Claude on each machine (or copy `state.json` — but remember, per-target hashes will force one extra "first sync" on the second machine).

### Security

`state.json` is a plain-text config you own; Loop 1 only writes CLAUDE.md content (with a header comment) to target paths. Treat CLAUDE.md as non-secret — it's loaded into every AI session anyway. Don't put anything in CLAUDE.md you wouldn't want spread to every AI tool.
