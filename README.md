# claude-memory-setup

**A guided migration skill for Claude Code users whose memory has drifted — scattered AutoMemory, stray CLAUDE.md, empty Codex AGENTS.md, out-of-date CoWork Global Instructions. Install the skill, tell Claude to organize, answer a few yes/no questions, and end up with one lean global CLAUDE.md + topic skills + automated sync Loops.**

<sub>English | [中文](#中文)</sub>

---

## What it does

- **Phase 0 — Diagnose**: scans `~/.claude/CLAUDE.md`, `~/.claude/projects/*/memory/`, existing skills, project-root `CLAUDE.md` files, `~/.codex/`, CoWork state, and `settings.json`. Produces a diagnostic report.
- **Phase 1 — Analyze**: classifies every source file into one of 5 targets (🔵 CLAUDE.md / 🟢 existing skill / 🟡 new skill / ⚪ keep / 🔴 archive). Proposes a target architecture.
- **Phase 2–5 — Archive + Build + Migrate**: generates a dated archive with SHA256 manifest + rollback script, synthesizes a clean CLAUDE.md, builds new skills from source files, moves originals into archive. **Copy-first, never direct-delete.**
- **Phase 6 — Loops**: registers two daily scheduled tasks — (a) sync CLAUDE.md → Codex AGENTS.md, (b) nightly reorg scan + symlink maintenance + AutoMemory triage.
- **Phase 7 — CoWork guidance**: installs a pbcopy helper; walks you through one-time manual paste into CoWork Global Instructions (there's no local API for this yet).

Every phase asks for your approval before executing. You can skip phases, adjust classifications, or abort any time.

## Who it's for

Existing mid/heavy Claude Code users. Typical profile:

- AutoMemory has been running for months; `projects/*/memory/` has 10–50+ files
- `~/.claude/CLAUDE.md` is empty or has only a few lines
- You might have Codex installed; `~/.codex/AGENTS.md` might be empty
- You might use CoWork; Global Instructions contains something old
- You haven't done topic-level skill organization or set up sync Loops

If your Claude setup is clean already, this skill is overkill.

## Requirements

- macOS (primary) or Linux with `bash`, `python3`, `shasum`, `jq`, `flock`
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI or Claude Desktop with Code feature
- Optional: [Codex](https://developers.openai.com/codex/cli) CLI (Phase 6 Loop 1 only runs if detected)
- Optional: Claude Desktop with CoWork (Phase 7 only runs if detected)

## Install

```bash
git clone https://github.com/<your-user>/claude-memory-setup.git
cp -r claude-memory-setup/claude-memory-setup ~/.claude/skills/
```

Then open any Claude Code session and say:

> Help me organize my Claude memory

(Or in Chinese: **"帮我整理 Claude 记忆"**)

Full walkthrough: see [INSTALL.md](./INSTALL.md).

## Safety

- **Copy-first, never direct-delete.** All migrations are `mv` into a dated archive dir.
- **SHA256 manifest** of every moved file. Rollback by file is exact and verifiable.
- **Auto-generated `rollback.sh`** sits inside each archive. One command reverses everything.
- **Read-only through Phase 1.** No filesystem changes until you approve Phase 2.
- **`settings.json` is never modified automatically** — it's your config, this skill only reads it.

## Limits / honest caveats

- **CoWork Global Instructions can't be auto-synced** — they're server-side. You'll do a one-step manual paste after each CLAUDE.md change. The skill installs a helper so this is a 5-second operation.
- **Plugin-based CoWork skill mount is flaky** (Anthropic [issue #31542](https://github.com/anthropics/claude-code/issues/31542)). This skill doesn't use the plugin path for CoWork. It recommends manual individual-skill upload if needed.
- **Claude isn't perfect at classifying** — Phase 1 proposals are not infallible. You can adjust before execution.

## License

MIT — see [LICENSE](./LICENSE).

---

<a name="中文"></a>

# claude-memory-setup（中文）

**给已经用了一段时间 Claude Code、但记忆散得到处都是的人。Claude Code 的 AutoMemory、零散的 CLAUDE.md、空的 Codex AGENTS.md、老旧的 CoWork Global Instructions —— 装上这个 skill，让 Claude 扫描、分类、搬家，最后你得到一份干净的全局 CLAUDE.md + 按主题组织的 skill + 每日自动同步 Loop。**

## 解决什么问题

- **Phase 0 — 诊断**：扫 `~/.claude/CLAUDE.md`、`~/.claude/projects/*/memory/`、已有 skills、项目根 `CLAUDE.md`、`~/.codex/`、CoWork 状态、`settings.json`。输出一份当前状态报告。
- **Phase 1 — 分析**：把每个源文件分类到 5 个目标之一（🔵 进 CLAUDE.md / 🟢 并入现有 skill / 🟡 独立成新 skill / ⚪ 原地保留 / 🔴 归档）。给出完整架构提案。
- **Phase 2–5 — 归档 + 构建 + 迁移**：生成带 SHA256 manifest 和回滚脚本的日期归档目录，合成干净的 CLAUDE.md，基于源文件创建 skill，把原文件 `mv` 进归档。**只 copy-first，永不直删。**
- **Phase 6 — 自动 Loop**：注册两个每日计划任务 —— (a) 同步 CLAUDE.md → Codex AGENTS.md；(b) 夜间扫描 + symlink 维护 + AutoMemory 归类建议。
- **Phase 7 — CoWork 指引**：安装 pbcopy 辅助脚本；引导你把 CLAUDE.md 手动粘到 CoWork Global Instructions（目前本地没 API）。

每个 Phase 执行前都等你确认。随时跳过、调整、中止。

## 适合谁

已经用 Claude Code 一段时间的中重度用户。典型状态：

- AutoMemory 默认开了几个月，`projects/*/memory/` 堆了 10-50+ 个文件
- `~/.claude/CLAUDE.md` 为空或只有几行
- 可能装了 Codex，`~/.codex/AGENTS.md` 是空的
- 可能用 CoWork，Global Instructions 里是老的 prompt
- 没按主题做过 skill 拆分，也没设自动同步

如果你的 Claude 设置本来就很干净，这个 skill 没必要装。

## 环境要求

- macOS（主要支持）或 Linux，需要 `bash`、`python3`、`shasum`、`jq`、`flock`
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 或带 Code 功能的 Claude Desktop
- 可选：[Codex](https://developers.openai.com/codex/cli) CLI（没有则 Phase 6 Loop 1 跳过）
- 可选：Claude Desktop + CoWork（没有则 Phase 7 跳过）

## 安装

```bash
git clone https://github.com/<your-user>/claude-memory-setup.git
cp -r claude-memory-setup/claude-memory-setup ~/.claude/skills/
```

然后在任意 Claude Code 会话里说：

> **帮我整理 Claude 记忆**

完整走读流程见 [INSTALL.md](./INSTALL.md)。

## 安全保障

- **只 copy-first，永不直删**。所有迁移都是 `mv` 到按日期命名的 archive 目录。
- **每个文件都有 SHA256**，按文件级回滚精确且可验证。
- **自动生成 `rollback.sh`**，放在 archive 目录里，一条命令全撤。
- **Phase 0 和 1 纯只读**，第 2 阶段起才动文件系统，且每步要你点头。
- **永远不会自动改 `settings.json`** —— 那是你的配置，这个 skill 只读。

## 局限 & 坦白的告知

- **CoWork Global Instructions 无法自动同步** —— 它存在服务端。每次改完 CLAUDE.md 要手动粘一下。Skill 装了辅助脚本让这一步变成 5 秒操作。
- **Plugin 方式装 CoWork skill 挂载不稳定**（Anthropic [issue #31542](https://github.com/anthropics/claude-code/issues/31542)）。这个 skill 不走 plugin 路径。如果确实要给 CoWork 单独装某个 skill，推荐单个上传。
- **Claude 不是完美的分类器** —— Phase 1 提案不一定全对，你可以在执行前调整。

## License

MIT，详见 [LICENSE](./LICENSE)。
