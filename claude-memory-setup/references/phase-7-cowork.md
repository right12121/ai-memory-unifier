# Phase 7 — CoWork guidance (optional)

CoWork cannot be auto-synced locally. This phase installs a helper script and gives the user step-by-step instructions for the one manual sync they'll need.

## Why manual?

**CoWork Global Instructions are stored server-side** (in Claude Desktop's leveldb → synced to Anthropic's backend). There's no local file that automatically flows back to the cloud. Editing `~/.claude/CLAUDE.md` doesn't change the CoWork experience.

**CoWork does not auto-read `~/.claude/skills/` either.** It has its own plugin/skill management via the Desktop UI, which is **susceptible to known mount bugs** (issue #31542 — plugin skills in the CoWork container sometimes fail to mount even when enabled in UI).

**Therefore**: the recommended, reliable path is:
1. Keep `~/.claude/CLAUDE.md` as the local source of truth
2. Periodically paste its content into CoWork → Settings → Global Instructions
3. For skills, **manually upload** the 2-3 most-needed ones via Cowork → Customize → Skills (they appear as individual uploads, not a plugin bundle)

## What this phase installs

### 1. pbcopy helper script

Copy `templates/cowork-paste-helper.sh` to `~/bin/cowork-paste-claude-md` (chmod +x):

```bash
#!/bin/bash
# Copies ~/.claude/CLAUDE.md to system clipboard for manual paste into
# Claude Desktop → Settings → Cowork → Global Instructions

set -euo pipefail

FILE=~/.claude/CLAUDE.md
[ -f "$FILE" ] || { echo "ERROR: $FILE not found" >&2; exit 1; }

pbcopy < "$FILE"
lines=$(wc -l < "$FILE" | tr -d ' ')
bytes=$(wc -c < "$FILE" | tr -d ' ')
echo "✓ CLAUDE.md copied to clipboard ($lines lines / $bytes bytes)"
echo ""
echo "Next:"
echo "  1. Open Claude Desktop"
echo "  2. Settings → Cowork → Global Instructions"
echo "  3. Clear existing content → ⌘V to paste → Save"
```

If `~/bin` isn't in the user's PATH, add this line to `~/.zshrc` (ask first):
```
export PATH="$HOME/bin:$PATH"
```

### 2. One-shot: run the helper immediately

After installing, run it once. This populates the clipboard. Tell the user:

> Now open Claude Desktop → Settings → Cowork → Global Instructions, clear the text box, ⌘V, Save.

### 3. Explain the re-sync workflow

Put this in chat and append to the reorg log:

> Whenever you edit `~/.claude/CLAUDE.md` later:
> 1. Run `cowork-paste-claude-md` (populates clipboard)
> 2. Open Claude Desktop → Settings → Cowork → Global Instructions
> 3. Clear → Paste → Save
>
> This is a manual step because CoWork Global Instructions live server-side with no local write API exposed.

### 4. Individual skill upload guidance (optional)

If the user wants a specific skill available in CoWork too:

1. Open Claude Desktop → Cowork → Customize → Skills
2. Click "Upload skill" → pick the SKILL.md file from `~/.claude/skills/<name>/SKILL.md`
3. Wait for it to show up in the skill picker (takes a few seconds)

**Do not recommend uploading every skill** — pick the 2-3 most useful for the user's CoWork workflows. Uploading every skill clutters the CoWork skill picker and provides no benefit (these skills load on demand; unused ones are just noise).

### 5. Plugin path — not recommended

Don't suggest the plugin path (`.plugin` file upload via Cowork → Customize → Plugins). Reasons:

- **Bug #31542**: plugin skills frequently fail to mount in CoWork container
- **Bug #42651**: local plugin upload fails with cryptic errors on some Desktop versions
- **Plugin rebuild overhead**: every skill change requires re-packaging the .plugin file and re-uploading
- **Symlinks break in zip**: you'd have to dereference symlinks when packaging, losing auto-sync

If the user asks specifically about the plugin path, explain the above and show them the manual-per-skill upload as an alternative.

## What NOT to do

- **Don't try to read Cowork Global Instructions from leveldb**: it's stored encrypted-ish; not a stable API; may change any release.
- **Don't try to POST to a hypothetical Cowork API**: none exists publicly for Global Instructions.
- **Don't automate clicking in Desktop UI via Computer Use**: fragile; will break on layout changes; user has to approve access every session anyway.

## What if CoWork is NOT in use?

Skip this phase entirely. In chat, say:

> CoWork not detected (no `~/Library/Application Support/Claude/` session data). Phase 7 skipped. If you later start using CoWork, you can manually run `cowork-paste-claude-md` to sync your CLAUDE.md.

## Completion

After Phase 7 (or skip), Phase map is done. Proceed to the completion report (see main SKILL.md section "Completion report").
