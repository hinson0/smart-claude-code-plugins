---
name: commit
description: 分析、分组并提交当前改动，不运行检查、不升级版本、不推送或创建 PR。
argument-hint: 无需参数。按 type 和独立目的分组提交。
model: haiku
---

1. **模型**：Claude Code 在本轮以 `haiku` 执行。Codex 主 agent 派生一个 `gpt-5.6-luna` low reasoning worker，执行第 2–5 步且不再委派，再转述其结果。
2. **读取**项目约定、`git status --short`、已暂存和未暂存的差异、未追踪文件内容及近期提交记录；无改动则结束。
3. **分组**：先按 type（硬边界），再按独立目的（软边界）；同一文件混有多个目的时按改动块拆分。提交信息依次遵循 `AGENTS.md`、`CLAUDE.md`、`CLAUDE.local.md` 与近期提交，否则使用英文 `<type>(<scope>): <description>`，不超过 72 字符。列出每组的提交信息和文件。
4. **提交**：逐组进行，只暂存当前组的明确路径或改动块，确认暂存区恰好只含当前组后提交，首次失败即停止。汇报提交哈希、提交信息和剩余改动。
5. **边界**：仅分组并提交。文件、检查、版本、远端、PR 与 Git 配置保持不动；每次都是新提交（不使用 `--amend`、`--force` 或 `--no-verify`）。
