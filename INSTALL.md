# Installation & First Run

## 1. Clone the repo

```bash
git clone https://github.com/right12121/ai-memory-unifier.git
cd ai-memory-unifier
```

## 2. Copy the skill into your personal skills directory

```bash
cp -r ai-memory-unifier ~/.claude/skills/
```

That's it for installation. Claude Code picks up new personal skills automatically — no restart needed.

Verify:

```bash
ls ~/.claude/skills/ai-memory-unifier/
# should show SKILL.md, references/, templates/
```

## 3. Run it

Open any Claude Code session (CLI or IDE extension). Say:

> **"Help me unify my AI memory"**

or in Chinese:

> **"帮我整合我的 AI 记忆"**

Claude will load the skill and start Phase 0 (diagnostic scan). You'll see:

1. **A unified diagnostic report** listing every memory-related file from every detected AI product on your machine
2. **A follow-up question**: any products not in the registry you want included (Hermes, KimiClaw, internal tools, etc.)
3. **A classification proposal** — what goes where
4. **Approval prompts** at each phase — you can adjust or skip anything

Expected duration: 10–30 minutes depending on how many AI products and how much memory you've accumulated.

## 4. After it finishes

- **CLAUDE.md** is at `~/.claude/CLAUDE.md` (loaded every session)
- **Skills** are at `~/.claude/skills/<name>/SKILL.md`
- **Codex mirror** (if you have Codex): `~/.codex/AGENTS.md` + `~/.codex/skills/<name>` symlinks
- **Archive** with original Claude Code files + `rollback.sh` at `~/.claude/archive-<date>/`
- **Other products' source files** (`.cursorrules`, `~/.aider.conf.yml`, etc.) are **not moved** — they still work with their original tools. The skill copies content into CLAUDE.md / skills but leaves the sources in place.
- **Daily Loops** registered (check Claude Desktop → Scheduled tasks panel)

## Rollback

If something went wrong:

```bash
bash ~/.claude/archive-<YYYY-MM-DD>/rollback.sh
```

The archive is kept for at least 30 days. Don't delete it until you're confident.

Note: rollback restores Claude Code's scattered files (AutoMemory, stray CLAUDE.md). It does **not** undo content changes to other products' files because we don't touch those in the first place.

## Troubleshooting

### "Skill didn't trigger when I said 'help me unify my AI memory'"

Try:

- Check `ls ~/.claude/skills/ai-memory-unifier/SKILL.md` — file exists?
- Start a fresh Claude Code session (the skill catalog is refreshed at session start)
- Invoke explicitly with `/ai-memory-unifier` if slash-command syntax is available in your version
- Use more specific trigger wording: "use the ai-memory-unifier skill to consolidate my memory"

### "AutoMemory keeps recreating files I archived"

That's expected. AutoMemory writes based on session activity; it doesn't know we archived files. Loop 2 will catch new AutoMemory files nightly and suggest classification.

If AutoMemory volume is really getting out of hand:

```bash
# Option A: disable AutoMemory globally via env var
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1

# Option B: add to ~/.claude/settings.json
# { "autoMemoryEnabled": false }
```

### "Loop 1 keeps saying 'conflicts=[codex]' (or gemini-cli / windsurf)"

Some other tool (or you, manually) wrote to the target's memory file between Loop 1 runs, so the per-target hash no longer matches what Loop 1 recorded. The loop fail-closes to avoid overwriting your edit.

Fix by resetting just that target's state to its current on-disk hash (we trust the external edit):

```bash
# Reconcile one target. Replace TARGET_NAME with codex / gemini-cli / windsurf
python3 -c "
import json, hashlib
from pathlib import Path

TARGET_NAME = 'codex'   # <-- change me

state_path = Path.home() / '.claude/reorg-log/state.json'
s = json.load(open(state_path))
target_path = Path(s['targets'][TARGET_NAME]['path']).expanduser()
s['targets'][TARGET_NAME]['last_target_hash'] = hashlib.sha256(target_path.read_bytes()).hexdigest()
json.dump(s, open(state_path, 'w'), indent=2)
print(f'Reset {TARGET_NAME} last_target_hash to current on-disk value.')
"
```

Next Loop 1 run will see the reset state and sync cleanly from CLAUDE.md on top of the current target.

**Alternative**: if you'd rather pull the external edit *back* into `~/.claude/CLAUDE.md` (so every downstream target inherits it), copy the content manually to CLAUDE.md first, then just wait — the next Loop 1 run notices CLAUDE.md changed and re-syncs everything.

### "Did anything actually change? My Claude still behaves the same"

Start a **new** Claude Code session. Existing sessions don't reload `CLAUDE.md` mid-conversation. Ask in the new session: "What do you know about me?" and you should see details from the newly consolidated CLAUDE.md.

### "My Cursor / Cline / other tool seems not to know what I did"

Intended. This skill **consolidates content into CLAUDE.md + skills** for Claude Code, but does not modify other products' source files. Cursor keeps reading its `.cursorrules`; Cline keeps reading its config. If you want to remove duplication in the source tool, do it manually — the skill won't touch other products' files by default.

## Uninstall

```bash
# Remove the skill
rm -rf ~/.claude/skills/ai-memory-unifier/

# Optional: remove scheduled Loops (via Claude Desktop Scheduled panel, or)
# mcp__scheduled-tasks__update_scheduled_task with enabled=false

# Your consolidated CLAUDE.md + skills remain intact — removing the skill doesn't undo the migration.
# If you want to fully restore pre-migration state:
bash ~/.claude/archive-<YYYY-MM-DD>/rollback.sh
```
