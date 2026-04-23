# Phase 1 — Analyze & propose

Still read-only. Read every candidate file, classify each, and propose a complete target architecture.

## Input

- Diagnostic report from Phase 0
- Access to every file listed in that report

## Classification taxonomy

Apply exactly one of these labels to each memory file:

| Label | Name | Target | Criteria |
|-------|------|--------|----------|
| 🔵 | CLAUDE.md | Global `~/.claude/CLAUDE.md` | Cross-project, high-frequency, affects every session. Identity / people / universal communication preferences / hard rules for tool use. |
| 🟢 | Existing skill | Merge into an existing `~/.claude/skills/<name>/SKILL.md` | Topic matches a skill already in place. Content extends, doesn't replace. |
| 🟡 | New skill | Create `~/.claude/skills/<new_name>/` | Topic is substantial (> ~60 lines of useful content) and doesn't fit existing skills. Benefits from progressive disclosure. |
| ⚪ | Keep in place | Stays where it is | Project-bound AutoMemory that only matters inside that project directory; low access frequency. |
| 🔴 | Archive only | Moved to archive, nothing kept live | Duplicates, expired info, stale notes, pure noise. |

### Decision rules

**Identity facts** (name, role, timezone, language, contact) → 🔵 **always**

**People / relationships** → 🔵 if used across projects; otherwise 🟡 in a `people` skill

**Project snapshots** (current projects, status, milestones) → **depends on size + frequency**:
- 1-2 sentences referencing a project → 🔵 in Active Projects section
- Full design spec, component IDs, progress tracker → 🟡 new skill
- Project that's archived or rarely referenced → 🔴 archive

**Tool-use knowledge** (API patterns, credentials, quirks):
- If it's one flagship rule that every session might need ("use User token, not Bot token") → 🔵 Tool Constraints section
- Full playbook (API reference, pagination, error codes) → 🟡 new skill

**Workflow runbooks** (how to do X step-by-step) → 🟡 new skill

**Feedback / user preferences on Claude's behavior** → 🔵 in Communication / Work Style section

**Debugging notes tied to a specific file** → ⚪ keep in place or 🔴 archive if stale

### Resolve conflicts

When two files contradict:
- **Preserve the newer one** (by mtime) as authoritative
- **Flag the conflict** in the proposal: "File X says A; File Y (newer) says B. Proposal keeps B."
- Include a conflict section in the proposal so user can review

## Proposal format

Present a structured markdown document:

```markdown
# 📐 Consolidation Proposal — <today>

## Target: ~/.claude/CLAUDE.md (<N> lines projected)

### Identity
Source: user_role.md (partial), project_xxx.md (context)
Content: …

### People
Source: …

### [every other section]

**Projected total: X lines** (target: ≤150)

---

## New skills to create

### 1. `<skill-name>`
- Trigger: "<keywords that will trigger it>"
- Description: "<what it does>"
- Source files: file1.md, file2.md
- Projected size: N lines

### 2. `<another-skill>`
- …

---

## Merges into existing skills

### Into `feishu`
- Source: reference_feishu_credentials.md → add to section 1
- Conflict: None detected

### Into `pencil-design`
- Source: feedback_pencil_frames.md
- Conflict: …

---

## Keep in place
- `~/.claude/projects/<proj>/memory/<file>.md` — project-specific debugging note

---

## Archive only
- MEMORY.md index (3 files) — replaced by CLAUDE.md + skills
- Duplicate of reference_feishu_credentials.md (in -Users-bytedance-mine-Love/memory/)
- Expired: feedback_old_workflow.md (last mtime 2025-09)

---

## Decisions flagged for attention
- 🔴 Conflict: `foo.md` and `bar.md` disagree on X. Keeping newer (`bar.md`).
- ⚠️ Heads up: `feishu` skill has 3 files aiming at it; proposal merges them but keeps section-level granularity.
- ⚠️ `~/mine/CLAUDE.md` content is 80% identical to `~/.claude/CLAUDE.md`; proposal absorbs it into the global one and archives `~/mine/CLAUDE.md`.

---

## Do you want to:
- [ ] Adjust classifications before we proceed
- [ ] Approve and continue to Phase 2 (archive setup)
- [ ] Abort
```

## Budgets to watch

- **CLAUDE.md projected lines**: target ≤ 150. If proposal pushes past, recommend moving something to a skill. See `phase-2-claude-md.md` for thresholds.
- **Per-skill size**: individual SKILL.md should ideally stay under ~500 lines. If a skill is projected to be bigger, propose splitting (e.g., `feishu` + `feishu-export`).
- **Total skills count**: no hard cap, but if proposing > 15 new skills for one user, that's probably over-decomposed — recommend merging.

## Interactive revision

Let the user edit the proposal by natural language:
- "Don't make that a new skill, just put it in CLAUDE.md"
- "Merge skills X and Y"
- "This one should be archived, not kept"

Re-generate the proposal each iteration until the user approves.

Do NOT move to Phase 2 until the user says an explicit **approve / proceed / continue**.

## Handoff to Phase 2

Once approved:
- Freeze the decision mapping into `reorg-state.json` (in-memory for now; written to disk in Phase 2)
- Emit "Phase 1 complete. Starting Phase 2 (archive setup) — building archive directory + manifest."
