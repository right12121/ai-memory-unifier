# Phase 6 — Register automated Loops

Two scheduled tasks keep the consolidated memory system healthy without daily user involvement:

1. **Loop 1 — Memory Sync**: propagates `~/.claude/CLAUDE.md` to every detected Tier-1 downstream agent (Codex, Gemini CLI, Windsurf)
2. **Loop 2 — Reorg Scan**: nightly scan across CLAUDE.md, skills, AutoMemory; auto-maintains symlinks; suggests migrations

## Tooling

Use `mcp__scheduled-tasks__create_scheduled_task` (Claude Desktop's durable scheduled task API). Tasks persist across Claude Desktop restarts; state kept in `~/.claude/scheduled-tasks/<taskId>/`.

---

## Loop 1 — Memory Sync (multi-target)

**Task ID**: `memory-sync-agents`
**Cron**: `17 9 * * *` (daily at ~09:17; Claude Desktop adds jitter)
**Template**: `templates/scheduled-task-sync.template.md`
**`notifyOnCompletion`**: `false` (runs quietly; log is the audit trail)

**Targets are data-driven** — Loop 1 iterates all entries in `state.json` → `targets`. No hardcoded list in the loop. This means users can add their own custom targets without modifying skill files. See `references/custom-sync-targets.md`.

**Built-in Tier 1 targets** (auto-populated into state.json on first init):

| Target | Path | Detection signal |
|--------|------|------------------|
| `codex` | `~/.codex/AGENTS.md` | `~/.codex/` dir exists |
| `gemini-cli` | `~/.gemini/GEMINI.md` | `~/.gemini/` dir exists |
| `windsurf` | `~/.codeium/windsurf/memories/global_rules.md` | `~/.codeium/windsurf/` dir exists |

**Custom user-added targets**: any additional raw-markdown global file. See `references/custom-sync-targets.md` for the exact snippet to add one.

**Per-target state** in `~/.claude/reorg-log/state.json` (schema v2):

```json
{
  "version": 2,
  "last_claude_hash": "<SHA256 of CLAUDE.md at last sync>",
  "targets": {
    "codex":      { "path": "...", "format": "raw-md", "enabled": true,
                    "last_target_hash": "...", "last_synced_at": "..." },
    "gemini-cli": { ... },
    "windsurf":   { ... },
    "<custom-id>": { ... user-added entries ... }
  },
  "initialized_at": "..."
}
```

Per-target fields:
- `path` — absolute path (or `~/`-style). Supports `$VAR` expansion.
- `format` — `raw-md` is the only handled format in v1.2. Future: `json-field`, `yaml-field`, `project-md`.
- `enabled` — set to `false` to temporarily skip this target without removing the entry (preserves last_target_hash for later re-enable).
- `last_target_hash`, `last_synced_at` — managed by the loop; don't edit manually.

**Logic** (summary; full prompt in `templates/scheduled-task-sync.template.md`):

1. Acquire `flock` on `~/.claude/reorg-log/.loop1.lock`
2. Initialize or migrate `state.json` (v1 → v2 on first v1.1 run; preserves old `last_codex_hash`)
3. Hash `~/.claude/CLAUDE.md`. If same as `state.last_claude_hash` → skip all targets
4. For each target:
   - Skip if target's parent dir doesn't exist (product not installed)
   - Check current target hash; if it differs from `state.targets[<n>].last_target_hash` AND state has a recorded hash → **conflict**, skip this target (per-target fail-closed)
   - Otherwise atomic write: tmp file → `mv` into target path (with header comment)
   - Update `state.targets[<n>].last_target_hash` + `last_synced_at`
5. If at least one target synced, update `state.last_claude_hash`
6. Log summary to `~/.claude/reorg-log/<today>.md`

**Key property**: each target is independent. A conflict on Windsurf doesn't block Codex from syncing.

### Phase 6 — ask about user custom targets

Before registering the Loop, Claude should prompt:

> **Sync targets detected**: codex (installed), gemini-cli (not installed, will skip), windsurf (installed).
>
> Any other product you want auto-synced by this Loop? If it has a single global markdown file (one absolute path) that acts as its "global instructions", I can add it.
>
> Examples: an internal company agent, KimiClaw, Hermes, a forked tool. Skip if you're not sure.

If the user mentions one, collect:
- Short ID (kebab-case, e.g., `hermes`)
- Absolute file path
- Confirm it's a **raw-markdown** file (not JSON/YAML)

Then add it to state.json by running the snippet in `references/custom-sync-targets.md`. No need to re-register the Loop — it picks up new state.json entries on next run.

### Tier 2 / Tier 3 targets

Not handled by this loop in v1.2. See `references/product-registry.md` for the tier classification and planned timeline (v1.3+).

---

## Loop 2 — Daily reorg scan

**Task ID**: `memory-reorg-scan`
**Cron**: `23 21 * * *` (daily at ~21:23)
**Template**: `templates/scheduled-task-reorg-scan.template.md`
**`notifyOnCompletion`**: `true` (the user sees the nightly report)

**Intent**: one nightly sanity pass. Detects drift, maintains symlinks, reminds the user to migrate new AutoMemory items.

### Scan areas

**1. CLAUDE.md health** (line-count thresholds, community-tested):

- `≤ 100`: ✅ lean (ideal)
- `101 – 150`: ✅ healthy
- `151 – 200`: ⚠️ consider splitting
- `> 200`: 🔴 strongly recommend splitting

**2. Skill changes + symlink maintenance (auto-execute)**:

Source of truth: `~/.claude/skills/<name>/` (real dirs)
Mirror: `~/.codex/skills/<name>` (symlinks, if Codex installed)

The loop ensures:
- Every real skill source in `~/.claude/skills/` has a corresponding symlink in `~/.codex/skills/`
- Orphan symlinks (pointing at removed skills) are cleaned up
- Codex-shipped system skills (`.system`, `find-skills`, `playwright`) are left alone

**3. AutoMemory scan** (`find ~/.claude/projects/*/memory -newermt "24 hours ago"`):

For each new or modified memory file, suggest classification (🔵 CLAUDE.md / 🟢 existing skill / 🟡 new skill / ⚪ keep / 🔴 archive). Suggestions only — no auto-execute.

**4. AutoMemory volume**:

- `count > 50 OR size > 500 KiB` → ⚠️ alert recommending a migration pass

### Output format

Append to `~/.claude/reorg-log/<today>.md` (and post to chat if `notifyOnCompletion=true`):

```markdown
## Loop 2 @ <HH:MM:SS>

### 1. CLAUDE.md health
- Lines: N / Bytes: N / mtime: <date>
- Status: ✅/⚠️/🔴 <reason>

### 2. Skill changes + symlink maintenance
- Added: <list>
- Removed orphans: <list>

### 3. AutoMemory new files (past 24h)
<list with classification suggestions>

### 4. AutoMemory volume
- Files: N / Size: X KiB / Status: ✅/⚠️

### 📋 Suggested actions (pending your confirmation)
- [ ] ...
```

---

## Registration API

```
# Loop 1
mcp__scheduled-tasks__create_scheduled_task(
  taskId="memory-sync-agents",
  cronExpression="17 9 * * *",
  description="Daily 9:17 — sync CLAUDE.md to detected Tier-1 AI agents (Codex, Gemini, Windsurf); hash-idempotent per target, fail-closed on conflict",
  notifyOnCompletion=false,
  prompt=<from templates/scheduled-task-sync.template.md>
)

# Loop 2
mcp__scheduled-tasks__create_scheduled_task(
  taskId="memory-reorg-scan",
  cronExpression="23 21 * * *",
  description="Daily 21:23 — scan CLAUDE.md / skills / AutoMemory, maintain symlinks, suggest migrations",
  notifyOnCompletion=true,
  prompt=<from templates/scheduled-task-reorg-scan.template.md>
)
```

### If only Claude Code (no Tier-1 targets)

Register Loop 1 anyway. It will find zero detected targets and silently log `skipped=[...]` each day. Cheap to run; no harm. When the user later installs Codex / Gemini CLI / Windsurf, the loop picks up automatically on next run (no re-registration needed).

### State file

Canonical format in `templates/state.json.template`. Initialize once at end of Phase 6 (or let Loop 1 bootstrap it on first run — the template's bash includes init + v1→v2 migration).

## Test immediately

After registering, execute each loop once manually (from Claude Desktop's Scheduled panel → "Run now"):

- Permission prompts get approved upfront (nightly runs won't pause)
- Output is sane (state.json initialized correctly, first sync produces valid downstream files)
- Sync targets all write cleanly

## Edge cases

- **User has multiple Claude Desktop installations**: scheduled tasks are per-install. Nothing special needed.
- **CLAUDE.md modified during Loop 1 run**: atomic rename + flock protects readers; worst case the current run syncs the stale version, next run catches the new version.
- **state.json corrupted**: Loop 1 init block rewrites a clean state on failure (but losing target-hash history means a one-time false conflict on any manually-edited targets; unlikely but document).
- **User installs a new Tier-1 product later**: Loop 1's init block auto-adds the target on next run via the `default_targets` merge logic. No user action needed.
