# Phase 0 — Diagnostic inventory (across all AI products)

Read-only scan. Never write anything during this phase.

## Goal

Produce a single diagnostic report that tells the user exactly what memory artifacts exist on their machine, across **every AI product they use**, and where each one is. This is the primary input for Phase 1 (classification).

## Before scanning: load the product registry

Load `references/product-registry.md` — the canonical list of AI agents / CLIs / assistants we know how to detect and read. Use it as the scanning baseline.

## Scan order

1. **Always-scan** — Claude Code itself (we're guaranteed to be running inside it)
2. **Registry sweep** — iterate `references/product-registry.md` → detect each product on filesystem; skip those not found
3. **User-mentioned** — ask the user for any product you didn't cover; read their specified paths too
4. **Out-of-scope acknowledgment** — list server-side products (Cowork, ChatGPT, etc.) as "detected but out of scope" if the user uses them

## Step 1 — Claude Code (always)

### 1a. Global CLAUDE.md

```bash
if [ -f ~/.claude/CLAUDE.md ]; then
  wc -l ~/.claude/CLAUDE.md
  wc -c ~/.claude/CLAUDE.md
  grep -c '^## ' ~/.claude/CLAUDE.md  # section count
fi
```

Record: exists? line count? byte count? section count?

### 1b. AutoMemory projects

```bash
find ~/.claude/projects -maxdepth 2 -type d -name memory 2>/dev/null
```

For each `memory/` dir:

```bash
ls -la <memory_dir>
find <memory_dir> -maxdepth 1 -name '*.md' -type f | wc -l
du -sh <memory_dir>
```

**Deduplicate**: macOS is case-insensitive; project paths may be symlinked (e.g., `-Users-<you>-love` → `-Users-<you>-mine-Love`). Use `readlink` and inode comparison.

For each unique memory dir, record: project path (decoded), file count, total size, oldest + newest mtime.

### 1c. Existing skills

```bash
ls -la ~/.claude/skills/
```

Distinguish real directories (user-managed personal skills) from symlinks (plugin mirrors). For each real skill, `head -10 <skill>/SKILL.md` to extract `name:` and description.

### 1d. Project-root CLAUDE.md files

Ask the user which roots they use, or default to:

```bash
find ~ -maxdepth 3 -name 'CLAUDE.md' -type f -not -path '*/.claude/*' -not -path '*/node_modules/*' 2>/dev/null
```

(Depth-3 cap to avoid node_modules scans.)

### 1e. settings.json flags

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

Record settings. Never mutate.

## Step 2 — Iterate the product registry

For each product listed in `references/product-registry.md` under "Products with scannable local memory":

1. **Detection**: run the detection check (path exists / binary on PATH / etc.)
2. **Skip if not installed**
3. **Read memory files** listed for that product
4. **Record** in the diagnostic report

Products to check (from registry, v1.0):

- Codex CLI (`~/.codex/`)
- Cursor (`~/Library/Application Support/Cursor/`, `.cursorrules`, `.cursor/rules/`)
- Aider (`~/.aider.conf.yml`)
- Continue (`~/.continue/`)
- Cline (VS Code globalStorage)
- Windsurf / Codeium (`~/.codeium/windsurf/`)
- Zed (`~/.config/zed/`)
- Gemini CLI (`~/.gemini/`)
- Amp / Sourcegraph (project `AGENT.md`, `~/.amp/`)
- Qclaw / OpenClaw (`~/.qclaw/workspace/`, `~/.openclaw/workspace/`)

For the full list and detection details, see `references/product-registry.md`.

## Step 3 — Ask the user about additional products

After the automatic sweep, ask:

> I scanned for common AI products and found: [list].
> Do you regularly use any AI agent / CLI / assistant I might have missed?
> Examples: Hermes, KimiClaw, Doubao, Tongyi Lingma, internal company tool, etc.
> If yes, point me at the directory or file and I'll include it.

For each user-mentioned product, ask for the path, read it, add to findings. Do **not** assume formats — ask "what kind of data is in that file?" if it's not obvious.

## Step 4 — Acknowledge out-of-scope products

Note (but do not try to read) server-side products the user has mentioned or you suspect they use:

- **Cowork Global Instructions** — stored in Claude Desktop's leveldb, server-synced. Not scannable locally. If user uses Cowork, call out in the report that Cowork's Global Instructions won't be auto-pulled into the consolidation.
- **ChatGPT custom instructions** — stored at `chatgpt.com/settings`. Manual only.
- **Claude.ai preferences** — server-side.
- **GitHub Copilot / Workspace** — server-side.

Ask the user if they want to **manually paste** content from any server-side source into the consolidation. If yes, they paste it directly in chat, and treat it as another input.

## Diagnostic report format

Present as markdown, scannable top-to-bottom:

```markdown
# 📋 AI Memory Inventory — <today>

## Claude Code (primary)
- `~/.claude/CLAUDE.md`: X lines / Y bytes / sections: [Identity, People, …]
- AutoMemory:
  | Project | Files | Size | Latest |
  |---|---|---|---|
  | `~/mine/thebrainly` | 10 | 42 KB | 2026-04-15 |
- Existing skills: <list with name + 1-line desc>
- Project-root CLAUDE.md: <list>
- Settings flags: autoMemoryEnabled=on, autoDreamEnabled=true, model=opus[1m]

## Codex CLI
- Detected: ✅ `~/.codex/`
- `AGENTS.md`: empty
- Skills: .system, find-skills, playwright (system only)

## Cursor
- Detected: ✅ `~/Library/Application Support/Cursor/`
- Project rules: `.cursorrules` in 2 projects (`~/proj-a`, `~/proj-b`)
- Rules content: <summary>

## <other detected products>
...

## User-mentioned products
- <product name>: <path>
- <content summary>

## Out of scope (server-side)
- Cowork Global Instructions: not readable locally. You use this — note that whatever's in Cowork Settings won't be included.
- ChatGPT custom instructions: you mentioned you set some. Paste here if you want to include in the consolidation, or skip.

## Flags for attention
- 🔴 `~/mine/CLAUDE.md` + `~/.claude/CLAUDE.md` overlap 80% → merge candidate
- 🟡 Cursor `.cursorrules` in ~/proj-a says "use Python 3.12", but `~/.claude/CLAUDE.md` says "Python 3.11" — conflict
- 🟡 AutoMemory total = 54 KB / 14 files (below 500 KB alert threshold)

## Numbers
- Total memory files found: N
- Total bytes: X KB
- Estimated consolidation effort: <small/medium/large>
```

End with: **"Ready to proceed to Phase 1 (analysis & proposal)?"**

## Edge cases

- **User has zero memory artifacts anywhere**: report "Nothing to migrate. Use `templates/CLAUDE.md.template` as a starter?" Offer to scaffold a blank CLAUDE.md if they want.
- **User has only one product**: the registry sweep is fast (everything else skipped). Proceed normally.
- **User has a product not in the registry, and the paths look unusual**: ask for confirmation before reading (privacy check); read only files they explicitly point at.
- **Symlinks across skills**: trace them once; record original target in manifest.
- **User doesn't know what paths their internal tool uses**: offer to grep their home dir for recently-modified `.md` or config files, with explicit permission.
