# Installation & First Run

## 1. Clone the repo

```bash
git clone https://github.com/<your-user>/claude-memory-setup.git
cd claude-memory-setup
```

## 2. Copy the skill into your personal skills directory

```bash
cp -r claude-memory-setup ~/.claude/skills/
```

That's it for installation. Claude Code picks up new personal skills automatically — no restart needed.

Verify:

```bash
ls ~/.claude/skills/claude-memory-setup/
# should show SKILL.md, references/, templates/
```

## 3. Run it

Open any Claude Code session (CLI or IDE extension). Say:

> **"Help me organize my Claude memory"**

or in Chinese:

> **"帮我整理 Claude 记忆"**

Claude will load the skill and start Phase 0 (diagnostic scan). You'll see:

1. **A diagnostic report** listing every memory-related file on your machine
2. **A classification proposal** — what goes where
3. **Approval prompts** at each phase — you can adjust or skip anything

Expected duration: 10–20 minutes depending on how much memory you've accumulated.

## 4. After it finishes

- **CLAUDE.md** is at `~/.claude/CLAUDE.md` (loaded every session)
- **Skills** are at `~/.claude/skills/<name>/SKILL.md`
- **Codex mirror** (if you have Codex): `~/.codex/AGENTS.md` + `~/.codex/skills/<name>` symlinks
- **Archive** with original files + `rollback.sh` at `~/.claude/archive-<date>/`
- **Daily Loops** registered (check Claude Desktop → Scheduled tasks panel)
- **CoWork helper** (if you use CoWork): `~/bin/cowork-paste-claude-md`

## Rollback

If something went wrong:

```bash
bash ~/.claude/archive-<YYYY-MM-DD>/rollback.sh
```

The archive is kept for at least 30 days. Don't delete it until you're confident.

## Troubleshooting

### "Skill didn't trigger when I said 'help me organize my claude memory'"

Try:

- Check `ls ~/.claude/skills/claude-memory-setup/SKILL.md` — file exists?
- Start a fresh Claude Code session (the skill catalog is refreshed at session start)
- Invoke explicitly with `/claude-memory-setup` if slash-command syntax is available in your version
- Use more specific trigger wording: "use the claude-memory-setup skill to organize my memory"

### "AutoMemory keeps recreating files I archived"

That's expected. AutoMemory writes based on session activity; it doesn't know we archived files. Loop 2 will catch new AutoMemory files nightly and suggest classification.

If AutoMemory volume is really getting out of hand:

```bash
# Option A: disable AutoMemory globally via env var
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1

# Option B: add to ~/.claude/settings.json
# { "autoMemoryEnabled": false }
```

### "CoWork is still showing old Global Instructions"

CoWork Global Instructions are server-side. You need to manually paste the new content:

```bash
cowork-paste-claude-md   # copies CLAUDE.md to clipboard
```

Then: Claude Desktop → Settings → Cowork → Global Instructions → Clear → Paste → Save.

### "Loop 1 keeps saying 'conflict — Codex AGENTS.md modified externally'"

Something else (or you, manually) wrote to `~/.codex/AGENTS.md` between Loop 1 runs. Fix:

```bash
# Reconcile: treat current CLAUDE.md as truth, reset state to current Codex hash
python3 -c "
import json, hashlib
from pathlib import Path
state = json.load(open(Path.home() / '.claude/reorg-log/state.json'))
state['last_codex_hash'] = hashlib.sha256(
    (Path.home() / '.codex/AGENTS.md').read_bytes()
).hexdigest()
json.dump(state, open(Path.home() / '.claude/reorg-log/state.json', 'w'), indent=2)
"
```

Next Loop 1 run will detect CLAUDE.md changed and sync cleanly.

### "Did anything actually change? My Claude still behaves the same"

Start a **new** Claude Code session. Existing sessions don't reload `CLAUDE.md` mid-conversation. Ask in the new session: "What do you know about me?" and you should see details from the newly consolidated CLAUDE.md.

## Uninstall

```bash
# Remove the skill
rm -rf ~/.claude/skills/claude-memory-setup/

# Optional: remove scheduled Loops (via Claude Desktop Scheduled panel, or)
# mcp__scheduled-tasks__update_scheduled_task with enabled=false

# Your reorg'd CLAUDE.md + skills remain intact — removing the skill doesn't undo the migration.
# If you want to fully restore pre-migration state:
bash ~/.claude/archive-<YYYY-MM-DD>/rollback.sh
```
