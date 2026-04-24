# Phase 0 — Kickoff interview + diagnostic inventory

Phase 0 has two parts:

**Part A — Interview** (interactive, no file writes yet): ask the user upfront which AI products they use, so we know what to scan and what to eventually sync to. User answers in natural language. Claude does the config.

**Part B — Inventory** (read-only filesystem scan): guided by the interview answers, list the actual memory files present on disk.

Never write anything during Phase 0. The goal is to build a complete picture of the starting point and a confirmed product list before anything else happens.

---

## Part A — Kickoff interview

Before any scanning, **always** have this conversation with the user. Don't skip straight to filesystem detection — the user may not have all products actually installed locally, or may have tools we can't detect.

### Step A.1 — Show what's automatically detectable

Claude silently runs detection first (filesystem checks for each product in `references/product-registry.md`). Then reports:

> **I'll be unifying your AI memory. Here's what I detected on this machine**:
>
> Products you have installed (I'll scan these for memory):
> - Claude Code (always)
> - [Codex CLI, Gemini CLI, Cursor, Aider, ... — whichever actually exist]
>
> For each **Tier-1** one (raw-markdown global file), I can also set up **auto-sync** so when CLAUDE.md changes, it propagates automatically. These are typically: Codex, Gemini CLI, Windsurf.

### Step A.2 — Ask about products we can't auto-detect

> **Are there any AI products you use that I didn't detect?** They could be:
>
> - Internal / company-specific tools
> - Regional products like KimiClaw, Hermes, Doubao, Tongyi Lingma
> - Forks or rebranded agents
> - Tools that store memory somewhere unusual
>
> If yes, tell me the name (short, for the ID) and the path to its memory file. Example:
> > "I use KimiClaw, its rules are at `~/.kimi/RULES.md`"

Collect from user. For each:
- **Short ID** (kebab-case, e.g., `kimi-claw`, `my-internal-agent`)
- **Absolute path** to the memory file (expand `~` on their behalf)
- **Format**: ask "is it a single markdown file that represents the product's global instructions?" — if yes, treat as `raw-md` (sync-capable). If JSON/YAML/project-local, treat as scan-only for now.

### Step A.3 — Acknowledge server-side products

> **I can't read server-side products locally** (no file to scan), but if you use any of these, tell me and I'll include them in the final report so you remember to update them manually:
>
> - Claude Desktop Cowork Global Instructions
> - ChatGPT custom instructions (web)
> - Claude.ai preferences
> - Gemini custom instructions (web)
> - GitHub Copilot / Workspace

User confirms which they use. These become "note-only" entries.

### Step A.4 — Confirm sync target subset

For products confirmed in A.1 and A.2 that are **Tier-1 writable**, ask:

> I can set up auto-sync for these going forward (daily Loop 1 will update them whenever `~/.claude/CLAUDE.md` changes):
>
> - codex → ~/.codex/AGENTS.md
> - gemini-cli → ~/.gemini/GEMINI.md
> - windsurf → ~/.codeium/windsurf/memories/global_rules.md
> - kimi-claw → ~/.kimi/RULES.md  *(user-added)*
>
> Is this correct? Anything to exclude?

User says yes, or picks a subset. The final list is `sync_target_list`.

### Step A.5 — Build internal lists

After the interview, Claude has three internal lists (not yet written to disk):

1. **`scan_sources`** — what Part B will read from (everything confirmed in A.1 + A.2)
2. **`sync_target_list`** — what Phase 6 will write to state.json for Loop 1 (subset of scan_sources that's Tier-1 writable + user-approved)
3. **`note_only`** — server-side products to mention in the final report

Present all three lists to the user and ask confirmation:

> **Ready to start the scan**. Here's what I'll do:
>
> **Scan** (read-only, Phase 0): [scan_sources]
> **Future sync** (set up in Phase 6): [sync_target_list]
> **Noted for manual handling** (can't touch): [note_only]
>
> Looks right?

After confirmation, proceed to Part B.

---

## Part B — Filesystem inventory

For each item in `scan_sources`, read the memory files. Logic is the same as before (file counts, dedup, etc.).

### B.1 — Claude Code (always)

```bash
# Global CLAUDE.md
[ -f ~/.claude/CLAUDE.md ] && wc -l ~/.claude/CLAUDE.md && wc -c ~/.claude/CLAUDE.md

# AutoMemory projects (dedup symlinked dirs)
find ~/.claude/projects -maxdepth 2 -type d -name memory 2>/dev/null

# Existing skills (real dirs only)
ls -la ~/.claude/skills/

# Project-root CLAUDE.md
find ~ -maxdepth 3 -name 'CLAUDE.md' -type f -not -path '*/.claude/*' -not -path '*/node_modules/*' 2>/dev/null

# settings.json flags (read-only)
python3 -c "
import json
s = json.load(open('$HOME/.claude/settings.json'))
for k in ['autoMemoryEnabled', 'autoDreamEnabled', 'model']:
    print(f'{k}:', s.get(k, 'default'))
"
```

### B.2 — Confirmed other products

For each product in `scan_sources` that's in `product-registry.md`:

- Run its detection check
- Read its memory file(s) per registry entry
- Record size, mtime, content summary

For user-added products (not in registry):

- Read the path the user provided
- Ask user "what kind of data is this?" if format is unclear
- Record as-is

### B.3 — settings flags

Already covered in B.1 for Claude Code. For other products, note their config flags if relevant (e.g., Codex `model` setting).

---

## Diagnostic report format

After both parts, present:

```markdown
# 📋 AI Memory Inventory — <today>

## Products in scope
- **Claude Code** (primary) — will be the authority after migration
- **Codex CLI** — detected, will sync + migrate
- **Cursor** — detected, will scan only (project-local rules)
- **KimiClaw** — user-provided, will sync to ~/.kimi/RULES.md
- ...

## Claude Code
- `~/.claude/CLAUDE.md`: X lines / Y bytes / sections: [...]
- AutoMemory: N files across M projects, ~K KB total
- Existing skills: [list]
- Project-root CLAUDE.md: [list]
- Settings: autoMemoryEnabled=<v>, autoDreamEnabled=<v>, model=<v>

## <Other scanned products>
- [same structure per product]

## Sync targets (Phase 6 will register these)
- codex → ~/.codex/AGENTS.md (auto)
- gemini-cli → ~/.gemini/GEMINI.md (auto)
- windsurf → ~/.codeium/windsurf/memories/global_rules.md (auto)
- kimi-claw → ~/.kimi/RULES.md (user-added)

## Note-only (server-side, can't touch locally)
- Cowork Global Instructions
- ChatGPT custom instructions (web)

## Flags for attention
- 🔴 conflicts found: ...
- 🟡 ...

## Numbers
- Total memory files found: N
- Total bytes: X KB

Ready to proceed to Phase 1 (analyze + propose)?
```

---

## Edge cases

### User says "just scan everything, I don't care"

Skip the interview detail; use filesystem auto-detection only. Note in the report which assumptions were made. This is fine for quick runs but loses the chance to add custom tools.

### User has zero memory anywhere

Report "nothing to migrate" and offer `templates/CLAUDE.md.template` as a starter. Still set up Loop 1 + state.json so future runs work.

### User mentions a product they think is Tier-1 but it's actually structured config

Politely correct: "That tool stores its rules in a JSON config; I can read it during scan but can't auto-sync to it yet (Tier 2 support planned). OK to scan-only for now?"

### User refuses to answer the interview

Fine — auto-detect via registry, use those as both scan_sources and sync_target_list. Log that the interview was skipped so we don't miss anything critical on later runs.

### User mentions a product we don't know; path they give doesn't exist

Ask: "the path `~/.foo/memory.md` doesn't exist — did you mean something else? Or is this a product that hasn't been used yet and will create the file later?"

If "hasn't been used yet": **still add to sync_target_list**. When the file gets created, Loop 1 picks it up automatically (next run after parent dir exists).

---

## Key principle: Claude writes the config, not the user

After this interview, when Phase 6 populates `~/.claude/reorg-log/state.json`, Claude does it directly. The user never needs to hand-edit JSON. The only exception: post-setup tweaks (enable/disable/remove a target later, after the skill has finished) — see `references/custom-sync-targets.md` for those advanced operations.
