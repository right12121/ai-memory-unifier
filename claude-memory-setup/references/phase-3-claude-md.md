# Phase 3 — Build CLAUDE.md

Generate `~/.claude/CLAUDE.md` by synthesizing content from 🔵-classified source files into the canonical section structure.

## Why CLAUDE.md matters more than skills

CLAUDE.md is **loaded at the start of every Claude Code + CoWork session, in full, without progressive disclosure**. Every byte costs tokens on every turn, forever. Skills are cheap (loaded on demand); CLAUDE.md is expensive.

**Therefore**: CLAUDE.md should hold only what's needed *every session*. Anything topic-specific belongs in a skill.

## Size budget (community-tested thresholds)

Based on community consensus (HumanLayer, Sabrina.dev, Anthropic's own Best Practices page):

| Line count | State | Action |
|------------|-------|--------|
| ≤ 100 | ✅ Lean | Ideal. Maintain. |
| 101 – 150 | ✅ Healthy | Fine. Watch for drift. |
| 151 – 200 | ⚠️ Consider splitting | Start identifying sections that could move to a skill. |
| > 200 | 🔴 Refactor | Actively move content out. Anthropic has warned that bloated CLAUDE.md files cause Claude to *ignore* the instructions. |

Target for first generation: **≤ 120 lines**. Leave room to grow.

## Canonical section structure

Follow `templates/CLAUDE.md.template`. Sections (in recommended order):

### 1. Identity
- Name(s), nickname, role, company/org, timezone, language(s), contact
- Facts that are stable for years
- 5–10 lines typical

### 2. People
- A short table of people the user interacts with repeatedly
- Used by: meeting transcription speaker ID, context in projects, remembering relationships
- 0–10 rows; drop if user has no need

### 3. Speaker Identification (optional)
- Only if the user uses meeting transcription tools (Granola, Feishu Minutes, etc.)
- Rules for identifying "me" vs "the other person(s)" in transcripts
- 3–6 lines

### 4. Active Projects
- One line per project, pointer to skill if it has one
- Typical: 3–6 items
- Keep each line to < 100 chars

### 5. Communication
- Response language preference
- Format preferences (markdown, no PDF/Docx, etc.)
- Brevity / verbosity / trailing summaries
- Meeting recording tools in use

### 6. Work Style
- How the user wants Claude to engage (ask clarifying questions? just do? etc.)
- Code style preferences at a high level (detail goes in a skill)
- Any "don't assume X" rules

### 7. Tool Constraints
- Hard rules about specific tools (one subsection per tool family)
- Common subsections: Feishu / Computer Use / Browser Automation / CoWork sandbox
- Only the **absolute constraints**; implementation detail goes in that tool's skill

### 8. Active Configs (optional, terse)
- Any one-liners about current model, effort level, custom hooks setup
- Pointer to `settings.json` rather than duplicating it

### 9. 🔴 Memory Mechanism (required, boilerplate)
This is a **fixed rule block** — include as-is:

> Persistent memory has exactly two authoritative locations:
> 1. This file `~/.claude/CLAUDE.md` — cross-project, every session
> 2. Skill files `~/.claude/skills/<name>/SKILL.md` — topic-specific, on-demand
> 3. `~/.codex/skills/<name>` symlinks point at the same source (Codex reads them)
> 4. Claude Code + CoWork + Codex share a common skills directory
>
> AutoMemory products (`~/.claude/projects/*/memory/*.md`):
> - Acknowledge their existence (harness behavior, can't be banned from this file)
> - Not treated as authoritative: daily Loop 2 scans, classifies, and suggests migration
> - Claude should **not** actively write manually to `projects/*/memory/` (AutoMemory's auto-writes are fine)
>
> Disallowed:
> - New CLAUDE.md files inside project subdirectories (except existing project technical docs)
> - Scattered note files, log files, TODO.md, etc.

### 10. Project-Level CLAUDE.md 保留清单 (optional)
If the user keeps any project-root CLAUDE.md files intentionally (technical project docs), list them here so this skill knows not to touch them on future runs.

### 11. Reorg History (required, minimal)
Just the latest archive path:

> `~/.claude/archive-<YYYY-MM-DD>/` — archived from `~/.claude/projects/*/memory/` and any scattered `CLAUDE.md`. See `manifest-<date>.json` for per-file lookup.

## Synthesis instructions (for Claude during Phase 3)

1. Start from the template skeleton
2. For each 🔵-classified source file, **extract the minimum viable fact set**, not the entire content
   - User preferences: keep the rule, drop the backstory
   - Identity: one line per attribute
   - Projects: one line per project, with skill pointer
3. Dedupe mercilessly — if two sources say "use User token", they collapse to one line
4. Resolve contradictions by preferring newer file (by mtime); flag the choice in chat
5. After drafting, count lines. If > 150, identify the 2-3 heaviest sections and offer to split them to skills
6. Show the draft to the user **before** writing to disk; accept edits inline
7. Write to `~/.claude/CLAUDE.md` only after explicit approval
8. Verify line count and print a health badge (✅ / ⚠️ / 🔴) in chat

## Edge case: user wants to keep long identity / interests / hobbies sections

This is fine as a preference, but warn: "That section pushes CLAUDE.md to X lines, which is ⚠️/🔴. Every line costs tokens every session. Proceed?"

If user wants to keep long-form bio content, recommend a `user-bio` skill triggered by "tell me about myself" / "remind me of my interests". Keeps CLAUDE.md lean.

## Edge case: CLAUDE.md already exists with hand-written content

If `~/.claude/CLAUDE.md` exists before Phase 3:
- Archive the existing one to `~/.claude/archive-<date>/CLAUDE.md.pre-reorg` first
- Read it, compare to what we'd generate, and **merge**, preserving user's explicit writing
- Show diff in chat; user approves merge

Never silently overwrite user-written CLAUDE.md content.
