# AI product memory registry

A living list of AI coding agents, CLIs, and assistants that maintain local memory / instructions, with detection methods.

Used by:
- **Phase 0 (diagnose)** — iterate this list to find what the user has; ask user about products not in the list
- **Loop 1 (sync)** — for each "Tier 1" target below, downstream-sync `~/.claude/CLAUDE.md` content on any change

Phase 0 should:
1. Check each product in this registry
2. Ask the user: "Any other AI products you use regularly? Some agents I don't know about?"
3. For each detected or user-mentioned product, attempt to read its memory files

> **Contributing**: if you know a product not listed here, PR it to `references/product-registry.md` in this repo. Include name, detection path(s), memory file path(s), writability (see sync tiers below), and 1-line notes.

## Sync tiers

**Tier 1 — raw markdown global** (auto-synced by Loop 1 v1.1):
A single markdown file at a known global path. Write is a raw copy with header comment. Safest; what we do today for Codex, Gemini CLI, Windsurf.

**Tier 2 — structured config** (planned v1.2):
Requires writing a specific field in a JSON / YAML file (Continue's `systemMessage`, Zed's `assistant.default_model_prompt`, etc.). Carries slight risk of corrupting the user's other config. Requires opt-in.

**Tier 3 — project-local** (planned v1.3):
Per-project files like Cursor's `.cursorrules` or Amp's `AGENT.md`. User needs to maintain a list of which projects to sync to. More UX overhead.

**Tier X — out of scope**: server-side (Cowork, ChatGPT web, Claude.ai web, Gemini web, Copilot).

---

## Products with scannable local memory

### Claude Code (Anthropic)

- **Detection**: `~/.claude/` directory exists
- **Memory sources**:
  - `~/.claude/CLAUDE.md` — global always-loaded instructions
  - `~/.claude/projects/*/memory/*.md` — AutoMemory per-project files (also `MEMORY.md` index)
  - `~/.claude/skills/*/SKILL.md` — user-installed personal skills (read for inventory; they're already the target format)
  - Project-root `CLAUDE.md` or `.claude/CLAUDE.md` (walk-up loaded)
- **Writable**: yes. This is our primary target.
- **Notes**: treat symlinks in `skills/` specially — follow them to source, don't double-count.

### Codex CLI (OpenAI)

- **Detection**: `~/.codex/` directory, `which codex` on PATH
- **Memory sources**:
  - `~/.codex/AGENTS.md` — global agent instructions
  - `~/.codex/AGENTS.override.md` — optional override
  - `~/.codex/skills/*/SKILL.md` — Codex skills (some ship with the CLI: `.system`, `find-skills`, `playwright`; treat those as system, don't migrate)
  - `~/.codex/instructions.md`, `~/.codex/prompt.md` — older or fallback names; check if present
  - `~/.codex/config.toml` — references `project_doc_fallback_filenames` that may point elsewhere
- **Writable**: **Tier 1 (raw-md)** → Loop 1 writes `~/.codex/AGENTS.md`

### Cursor

- **Detection**: `~/Library/Application Support/Cursor/` or `~/.cursor/`
- **Memory sources**:
  - Project-level: `.cursorrules` (legacy), `.cursor/rules/*.mdc` (new)
  - Global user prompts: `~/Library/Application Support/Cursor/User/globalStorage/cursor.cursor/` (less standardized)
- **Writable**: **Tier 3 (project-local)** — Cursor reads `.cursorrules` per-project. v1.1 does not auto-write; planned v1.3 may let user list projects to sync.
- **Notes**: Cursor's memory is **project-local by design**. Consider extracting only generic (non-project-specific) rules and offer to mirror them to CLAUDE.md.

### Aider

- **Detection**: `which aider`, `~/.aider.conf.yml` or project `.aider.conf.yml`
- **Memory sources**:
  - `~/.aider.conf.yml` — global config including system prompt prefix
  - Project `.aider.conf.yml` — per-repo override
  - `.aider.chat.history.md` (chat log, not really memory)
- **Writable**: **Tier 2 (yaml-field / --read pointer)** — cleanest is to `--read ~/.claude/CLAUDE.md` via yaml config; planned v1.2.

### Continue (VS Code / JetBrains extension)

- **Detection**: `~/.continue/`
- **Memory sources**:
  - `~/.continue/config.json` — system message, custom prompts, rules
  - `~/.continue/rules/*.md` (if using rules feature)
- **Writable**: **Tier 2 (json-field)** — edit `systemMessage` inside config.json; planned v1.2.

### Cline (VS Code extension, formerly Claude Dev)

- **Detection**: `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/`
- **Memory sources**:
  - `settings.json` inside that storage directory — custom instructions live here
- **Writable**: **Tier 2 (json-field)** with caveat — VS Code must be closed to avoid conflicts. Deferred to v1.2+.

### Windsurf / Codeium

- **Detection**: `~/.codeium/windsurf/` or `~/Library/Application Support/Windsurf/`
- **Memory sources**:
  - `memories/global_rules.md` — Cascade's global memory file
  - Project `.windsurfrules`
- **Writable**: **Tier 1 (raw-md)** → Loop 1 writes `~/.codeium/windsurf/memories/global_rules.md`

### Zed

- **Detection**: `~/.config/zed/` or `~/Library/Application Support/Zed/`
- **Memory sources**:
  - `~/.config/zed/settings.json` → `assistant.default_model_prompt` etc.
- **Writable**: **Tier 2 (json-field)** — edit `assistant.default_model_prompt`; planned v1.2.

### Gemini CLI / Gemini Code Assist

- **Detection**: `~/.gemini/` or `which gemini`
- **Memory sources**:
  - `~/.gemini/GEMINI.md` — Gemini CLI's version of CLAUDE.md
  - `~/.gemini/settings.json`
- **Writable**: **Tier 1 (raw-md)** → Loop 1 writes `~/.gemini/GEMINI.md`

### Amp (Sourcegraph)

- **Detection**: `which amp`, `~/.amp/`
- **Memory sources**:
  - `AGENT.md` (project-root standard Sourcegraph uses)
  - `~/.amp/` config
- **Writable**: **Tier 3 (project-local)** for `AGENT.md`. Global `~/.amp/AGENT.md` (if exists) could be Tier 1; add to sync targets in v1.2 once format confirmed.

### Warp (terminal with Agent Mode)

- **Detection**: `/Applications/Warp.app` or `~/.warp/`
- **Memory sources**:
  - Warp's AI context is stored server-side mostly; limited local
  - Warp Drive workflow files (not memory per se)
- **Writable**: no (server-side)

### Grok-based CLIs (e.g., xAI agents)

- **Detection**: varies; check `~/.xai/`, `which grok`
- **Memory sources**: (ask user; format varies per distribution)

---

## Products mentioned but less documented

These are worth detecting and **asking the user** about memory formats rather than hardcoding a location:

### Hermes

- Likely refers to [Nous Research Hermes](https://nousresearch.com/) model integrations or [OpenWebUI Hermes plugin]. Multiple projects use the name.
- **Detection**: ask user
- **Memory sources**: varies by integration; user should specify

### KimiClaw (Moonshot AI)

- Chinese agent built on Moonshot's Kimi. Memory format not publicly documented (as of 2026-04).
- **Detection**: `~/.kimi/` or similar; ask user
- **Memory sources**: ask user

### Qclaw / OpenClaw

- Chinese agents (QClaw 腾讯, OpenClaw 开源). Known to use `~/.qclaw/workspace/` or `~/.openclaw/workspace/` with `MEMORY.md`, `AGENTS.md`, `SOUL.md` files.
- **Detection**: check `~/.qclaw/workspace/` and `~/.openclaw/workspace/`
- **Memory sources**: `MEMORY.md`, `AGENTS.md`, `USER.md`, `memory/*.md`
- **Writable**: yes (but these may be used by specific running agents; check with user before modifying)

### Doubao / Tongyi / Lingma

- ByteDance / Alibaba assistants. Most are server-side only; CLI versions if any have undocumented local formats.
- **Detection**: ask user

---

## Products explicitly out of scope (server-side only)

No local memory to scan or write:

- **ChatGPT custom instructions** — server-side (unified at `chatgpt.com/settings`)
- **Claude.ai preferences / Projects** — server-side
- **Gemini custom instructions** — server-side
- **GitHub Copilot / Copilot Workspace** — server-side
- **Cowork Global Instructions (Claude Desktop)** — server-side; out of scope for this skill (no local API to read/write; manual paste is brittle)
- **Amazon Q Developer / Q Business** — cloud-only
- **Cursor web session / Bugbot / BackgroundAgent** — cloud features; local `.cursorrules` is still readable

For these, the skill does **not** try to read or sync. In Phase 0 it may report "detected but out of scope". In the final CLAUDE.md, user can manually mention important facts they want cross-product.

---

## Phase 0 usage

1. Iterate through the "Products with scannable local memory" list
2. For each, check the detection path(s); if present, read the memory sources
3. After the automatic sweep, ask the user:
   > Besides the products I detected, do you regularly use any AI agent / assistant that maintains its own memory or instructions file? Examples: Hermes, KimiClaw, Qclaw, some internal tool. Point me at the directory or file and I'll try to include it.
4. For user-mentioned products, ask for the path(s) to their memory files and read those too
5. Include findings from all sources in the Phase 0 diagnostic report

---

## How to add a new product

Append a section under "Products with scannable local memory":

```markdown
### <Product name>

- **Detection**: <how to tell it's installed>
- **Memory sources**: <file paths>
- **Writable**: yes / no / partial
- **Notes**: <quirks, compatibility, warnings>
```

Open a PR to this repo. Include a brief rationale in the PR description (how common is the product, any verification you did).
