# ai-memory-unifier

**Your AI memory is scattered across Claude Code, Codex, Cursor, Aider, Continue, Windsurf, Gemini CLI, Qclaw, and god knows what else. Each tool has its own CLAUDE.md / AGENTS.md / .cursorrules / config.yml with its own half-remembered rules. This skill scans all of them, proposes one clean structure (global `~/.claude/CLAUDE.md` + topic skills), migrates everything with archive + rollback, and registers daily sync loops so it stays clean.**

<sub>English | [中文](#中文)</sub>

---

## What it does

- **Phase 0 — Diagnose**: scans a registry of common AI products (Claude Code, Codex, Cursor, Aider, Continue, Cline, Windsurf, Zed, Gemini CLI, Amp, Qclaw/OpenClaw, …) for their memory files. Asks you about products not in the registry (Hermes, KimiClaw, internal tools). Produces a unified diagnostic report.
- **Phase 1 — Analyze**: classifies every source file into 5 targets (🔵 CLAUDE.md / 🟢 existing skill / 🟡 new skill / ⚪ keep / 🔴 archive). Flags conflicts across products (e.g., Cursor rules say Python 3.12, Claude thinks 3.11).
- **Phase 2–5 — Archive + Build + Migrate**: dated archive with SHA256 manifest + auto-generated rollback script. Synthesizes a clean CLAUDE.md. Creates topic skills. Moves Claude Code's own scattered files into archive (other products' original files are **left intact** so those tools keep working).
- **Phase 6 — Loops**: registers two daily scheduled tasks — (a) **multi-target sync**: CLAUDE.md → Codex AGENTS.md, Gemini CLI GEMINI.md, Windsurf global_rules.md (every detected downstream agent, hash-idempotent per target), (b) nightly reorg scan + symlink maintenance + AutoMemory triage.

Every phase asks for your approval before executing. You can skip phases, adjust classifications, or abort any time.

## Who it's for

Mid/heavy AI tool users with drift. Typical profile:

- You use 2+ AI coding agents (Claude Code + Cursor, Claude + Codex, Cursor + Aider, etc.)
- Each has its own config / rules / instructions, and they've started contradicting each other
- Claude Code AutoMemory has 10–50+ files in `~/.claude/projects/*/memory/`
- `~/.claude/CLAUDE.md` is empty or near-empty
- You've never done topic-level skill organization or set up cross-product sync

If you only use one tool and it's well-organized, this is overkill.

## Scope

### In scope (we can read + migrate)

- **Claude Code** — primary target; we write the new global CLAUDE.md + skills here
- **Tier 1 sync targets** (Loop 1 writes daily, auto-detected): Codex CLI `~/.codex/AGENTS.md`, Gemini CLI `~/.gemini/GEMINI.md`, Windsurf `~/.codeium/windsurf/memories/global_rules.md`
- **Custom user targets** (v1.2+): use a product we don't know? Tell Phase 6 its file path, or add it to `state.json` yourself via the snippet in [custom-sync-targets.md](./ai-memory-unifier/references/custom-sync-targets.md). Loop 1 is data-driven — anything you add gets synced automatically.
- **Readable sources** (scanned in Phase 0; migrated content copied into CLAUDE.md/skills but original files left intact): Cursor, Aider, Continue, Cline, Zed, Amp, Qclaw/OpenClaw, and more (see [product-registry.md](./ai-memory-unifier/references/product-registry.md))
- **User-mentioned products**: tell Phase 0 where they live and we scan them too
- **Tier 2/3 sync targets** (Continue, Zed, Aider, Cline, Cursor): structured-config / project-local writes planned for v1.3+

### Out of scope (server-side, no reliable local API)

- **Cowork Global Instructions** — Claude Desktop's CoWork stores these server-side. We won't touch them. If you want Cowork in sync with CLAUDE.md, you'll still have to paste manually. A future version may tackle this when Anthropic exposes an API.
- **ChatGPT custom instructions**, **Claude.ai preferences**, **Gemini custom instructions**, **GitHub Copilot / Workspace** — all server-side. Phase 0 will note them and you can manually paste content if you want it included.

## Requirements

- macOS (primary) or Linux with `bash`, `python3`, `shasum`, `jq`, `flock`
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI or Claude Desktop with Code feature

Optional:
- [Codex](https://developers.openai.com/codex/cli) CLI (Phase 6 Loop 1 only runs if detected)
- Any of the other registered products (Phase 0 will pick them up if present)

## Install

```bash
git clone https://github.com/right12121/ai-memory-unifier.git
cp -r ai-memory-unifier/ai-memory-unifier ~/.claude/skills/
```

Then in any Claude Code session:

> Help me unify my AI memory

(Or in Chinese: **"帮我整合我的 AI 记忆"**)

Full walkthrough: see [INSTALL.md](./INSTALL.md).

## Safety

- **Copy-first, never direct-delete.** All Claude Code migrations are `mv` into a dated archive dir. Other products' source files are **not moved** — we copy content into CLAUDE.md/skills, but leave `.cursorrules` / `~/.aider.conf.yml` / etc. alone so those tools keep working.
- **SHA256 manifest** of every moved file. Rollback by file is exact and verifiable.
- **Auto-generated `rollback.sh`** in each archive. One command reverses the migration.
- **Read-only through Phase 1.** No filesystem changes until you approve Phase 2.
- **`settings.json` is never modified automatically** — it's your config, this skill only reads it.

## Contributing

Know a product we don't yet scan? PR it to [`references/product-registry.md`](./ai-memory-unifier/references/product-registry.md). Include detection method, memory file paths, and whether it's writable.

## License

MIT — see [LICENSE](./LICENSE).

---

<a name="中文"></a>

# ai-memory-unifier（中文）

**你的 AI 记忆散落在 Claude Code、Codex、Cursor、Aider、Continue、Windsurf、Gemini CLI、Qclaw、天知道还有啥。每个工具都有它自己的 CLAUDE.md / AGENTS.md / .cursorrules / config.yml，各说各话，规则互相打架。这个 skill 把它们一起扫描、按主题重新分类、迁移到一份干净的结构（全局 `~/.claude/CLAUDE.md` + 按主题的 skill），带 archive + rollback，然后建每日同步 Loop 让它保持干净。**

## 解决什么问题

- **Phase 0 — 诊断**：扫描一份内置的产品 registry（Claude Code、Codex、Cursor、Aider、Continue、Cline、Windsurf、Zed、Gemini CLI、Amp、Qclaw/OpenClaw……）找它们各自的记忆文件。还会问你有没有别的（Hermes、KimiClaw、内部工具），然后一起扫。给出一份统一的状态报告。
- **Phase 1 — 分析**：把每个源文件分到 5 个目标之一（🔵 进 CLAUDE.md / 🟢 并入现有 skill / 🟡 独立成新 skill / ⚪ 原地保留 / 🔴 归档）。自动标记跨产品冲突（比如 Cursor rules 说 Python 3.12，Claude 觉得 3.11）。
- **Phase 2–5 — 归档 + 构建 + 迁移**：带 SHA256 manifest 和自动生成回滚脚本的日期归档目录。合成干净的 CLAUDE.md。创建主题 skill。把 Claude Code 自己的零散文件 `mv` 进归档；**其他产品的原始文件保留不动**，让那些工具继续工作。
- **Phase 6 — 自动 Loop**：注册两个每日计划任务 —— (a) **多目标同步**：CLAUDE.md → Codex AGENTS.md、Gemini CLI GEMINI.md、Windsurf global_rules.md（检测到哪个产品就同步哪个，每个目标独立 hash 幂等）；(b) 夜间扫描 + symlink 维护 + AutoMemory 归类建议。

每个 Phase 执行前都等你确认。随时跳过、调整、中止。

## 适合谁

记忆散了的中重度 AI 工具用户。典型状态：

- 你同时用 2+ 个 AI 编码 agent（Claude Code + Cursor，或 Claude + Codex，或 Cursor + Aider……）
- 每个都有自己的 config / rules，而且开始互相打架
- Claude Code AutoMemory 在 `~/.claude/projects/*/memory/` 堆了 10-50+ 个文件
- `~/.claude/CLAUDE.md` 是空的或几乎是空的
- 你没做过主题级的 skill 整理，也没搭过跨产品同步

如果你就用一个工具、而且组织得挺好，这 skill 用不上。

## 覆盖范围

### 在范围内（能读 + 能迁移）

- **Claude Code** — 主要目标，新的全局 CLAUDE.md + skill 都在这
- **Tier 1 同步目标**（Loop 1 每天自动写入，自动检测）：Codex CLI `~/.codex/AGENTS.md`、Gemini CLI `~/.gemini/GEMINI.md`、Windsurf `~/.codeium/windsurf/memories/global_rules.md`
- **用户自定义 target**（v1.2+）：你用了我们不知道的产品？在 Phase 6 告诉我文件路径，或者用 [custom-sync-targets.md](./ai-memory-unifier/references/custom-sync-targets.md) 里的 snippet 自己加到 `state.json`。Loop 1 是数据驱动的 —— 你加什么它就同步什么。
- **可读源**（Phase 0 扫描；内容复制进 CLAUDE.md / skill，原文件保留不动）：Cursor、Aider、Continue、Cline、Zed、Amp、Qclaw/OpenClaw 等（完整列表见 [product-registry.md](./ai-memory-unifier/references/product-registry.md)）
- **用户补充的产品**：告诉 Phase 0 文件在哪，它就会扫
- **Tier 2/3 同步目标**（Continue / Zed / Aider / Cline / Cursor）：结构化配置/项目级回写，计划在 v1.3+ 支持

### 不在范围内（服务端存储，没有可靠的本地接口）

- **Cowork Global Instructions** — Claude Desktop 的 CoWork 这部分数据存在服务端，我们不碰。如果你想让 Cowork 跟 CLAUDE.md 同步，还是得手动粘贴。未来如果 Anthropic 开放 API，这个 skill 会考虑支持。
- **ChatGPT 自定义指令**、**Claude.ai preferences**、**Gemini 自定义指令**、**GitHub Copilot / Workspace** —— 都是服务端的。Phase 0 会标记它们，你可以手动把内容粘到聊天里让我一起处理。

## 环境要求

- macOS（主要支持）或 Linux，需要 `bash`、`python3`、`shasum`、`jq`、`flock`
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 或带 Code 功能的 Claude Desktop

可选：
- [Codex](https://developers.openai.com/codex/cli) CLI（没装就跳过 Loop 1）
- 任何 registry 里的其他产品（Phase 0 检测到了就扫）

## 安装

```bash
git clone https://github.com/right12121/ai-memory-unifier.git
cp -r ai-memory-unifier/ai-memory-unifier ~/.claude/skills/
```

然后在任意 Claude Code 会话里说：

> **帮我整合我的 AI 记忆**

完整走读流程见 [INSTALL.md](./INSTALL.md)。

## 安全保障

- **只 copy-first，永不直删**。Claude Code 的文件都是 `mv` 到按日期命名的 archive。其他产品的原始文件**不会被 mv**，只是把内容复制进 CLAUDE.md / skill，`.cursorrules` / `~/.aider.conf.yml` 这些留着让对应工具继续用。
- **每个文件都有 SHA256**，按文件级回滚精确可验证。
- **自动生成 `rollback.sh`**，一条命令回滚。
- **Phase 0 和 1 纯只读**，第 2 阶段起才动文件系统，每步都等你确认。
- **永远不会自动改 `settings.json`** —— 那是你的配置，这个 skill 只读。

## 贡献

知道一个我们还没扫到的产品？欢迎 PR 加到 [`references/product-registry.md`](./ai-memory-unifier/references/product-registry.md)。附上检测方法、记忆文件路径、是否可写。

## License

MIT，详见 [LICENSE](./LICENSE)。
