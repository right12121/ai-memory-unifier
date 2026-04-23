# Phase 4 — Build skills

Materialize each 🟡 (new skill) and append to each 🟢 (existing skill) from the Phase 1 proposal.

## Skill file layout

```
~/.claude/skills/<name>/
├── SKILL.md              required; main content + frontmatter
├── references/           optional; progressive-disclosure detail files
│   └── <topic>.md
└── templates/            optional; files the skill generates from
    └── <whatever>
```

**Rule**: one directory per skill. No nested skills.

## Frontmatter

`SKILL.md` must start with YAML frontmatter:

```yaml
---
name: <skill-name>            # kebab-case, must match directory name
description: |
  <1-3 paragraph description of what the skill does, what it triggers on,
  what it produces>

  Triggers: "<keyword 1>", "<keyword 2>", "<specific scenarios>".

  Also triggers when <specific condition>.
---
```

### description is the critical field

Claude decides whether to activate the skill by matching the **description** against the current conversation. Good descriptions:

- **Specific triggers**: list concrete keywords the user might say
- **Scenario descriptions**: "when user forwards a Feishu message and asks to file a bug"
- **Negative scope** (when useful): "Do NOT trigger for simple factual lookups that a single web search can answer"

Bad descriptions:
- Vague: "Helps with Feishu things"
- Too broad: "General utility skill"
- Missing triggers: description describes the content but doesn't tell Claude *when* to load

### Length rule of thumb

- `description:` — 3-10 sentences is typical. Progressive disclosure means Claude only sees the description until activation, so invest here.
- Body of SKILL.md — target 100-400 lines. If > 500, split into reference files.

## Content structure

After frontmatter, body should follow this rough pattern:

```markdown
# <Title> (optional but helps readability)

## 1. <First topical section>
...

## 2. <Second>
...

## N. Anti-patterns / gotchas / edge cases
```

Section names depend on topic; there's no fixed schema like CLAUDE.md has.

## Migrating 🟡 new skills from source files

For each 🟡 classified target:

1. Collect all source files assigned to this skill
2. Draft the `description:` — enumerate the triggers, scenarios, out-of-scope cases
3. Merge source content into numbered sections; **preserve granularity**, don't flatten
4. Keep attribution in comments where the source was a specific lesson learned:
   ```markdown
   <!-- Source: feedback_feishu_token_identity.md, 2026-03-31 -->
   ```
5. Add cross-references to related skills (e.g., `feishu-export` depending on `feishu`)

## 🟢 Merging into existing skills

For each 🟢 target:

1. Read the existing SKILL.md
2. Find the right section (or add one) where the new content belongs
3. Insert the content, keeping existing structure intact
4. Update `description:` if the merge adds new triggers
5. Increment the implicit version — just update mtime, no semver needed

**Never replace** existing skill content without explicit user confirmation. Only append / extend.

## Codex symlinks (if Codex detected)

After creating each skill, mirror to Codex:

```bash
ln -s ~/.claude/skills/<name> ~/.codex/skills/<name>
```

Why: Codex reads `~/.codex/skills/` and follows symlinks. One skill, two engines.

Skip this step if `~/.codex/` doesn't exist on the user's machine.

## File permissions

```bash
chmod 644 SKILL.md  # default for markdown
chmod 755 <skill>/  # directory
```

No special permissions needed.

## Post-creation verification

For each skill created, do a sanity check:

```bash
# 1. File exists and is non-empty
[ -s ~/.claude/skills/<name>/SKILL.md ] || echo "MISSING"

# 2. Has frontmatter
head -1 ~/.claude/skills/<name>/SKILL.md | grep -q '^---$' || echo "NO FRONTMATTER"

# 3. Has name that matches dir
grep -E '^name: <name>$' ~/.claude/skills/<name>/SKILL.md || echo "NAME MISMATCH"

# 4. Has non-trivial description
awk '/^description:/,/^---$/' ~/.claude/skills/<name>/SKILL.md | wc -l
# Should be > 3 lines
```

Emit a green checkmark per skill in chat; flag any that failed.

## Common mistakes to avoid

- **Frontmatter with `name: My Skill`** (spaces). Use kebab-case: `my-skill`. Directory name must match.
- **Two skills with overlapping descriptions** — Claude will struggle to pick which to activate. Either merge, or sharpen the descriptions so they're mutually exclusive.
- **Putting credentials in the description** — descriptions are visible at session start. Put credentials in body sections so they're only loaded when the skill activates.
- **Skill directory as a symlink**. Make it a real directory. `~/.claude/skills/<name>/` should be a real dir; mirror *to* Codex via symlink, don't mirror *from*.

## Handoff to Phase 5

After all skills created/merged and verified, emit:

> Phase 4 complete. Created N new skills, merged M extensions into existing skills. Next: Phase 5 — archive sources and clean up AutoMemory directories.

Then proceed to Phase 5 only after user confirms.
