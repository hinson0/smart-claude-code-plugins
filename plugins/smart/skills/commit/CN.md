---
name: commit
description: 分析、分组并提交当前改动，不运行检查、不升级版本、不推送或创建 PR。
argument-hint: 无需参数。按 type 和独立目的分组提交。
model: haiku
---

## 宿主路由

- **Claude Code：** frontmatter 将本轮固定为 `haiku`。直接执行下方“提交工作流”。
- **Codex commit worker：** 若调度 prompt 明确说明你是 commit worker，跳过本节余下内容，直接执行“提交工作流”，不得再次委派。
- **Codex 主 agent：** 将全部工作流步骤交给一个继承完整当前上下文的子 agent。明确其 commit worker 身份，要求读取本 skill 并完成工作流，不再委派。指定模型 `gpt-5.6-luna`、reasoning effort `low`，等待其完成后原样转述结果，不得重做其分析。
- 若 Luna 仅因模型不可用而派生失败，使用相同 worker 指令且不指定模型重试一次，让用户配置的默认子 agent 生效。若重试仍失败，报告失败并停止；主 agent 不得自行执行工作流。

## 提交工作流

1. 读取项目约定、`git status --short`、已暂存和未暂存的差异、未追踪文件内容及近期提交记录。无改动则结束。
2. 先按 type，再按独立目的分组。不同 type 必须分开，不因目录或 scope 相同而合并无关改动。同一文件包含多个独立目的时，按改动块拆分。
3. 提交前简要列出每组的提交信息和文件。
4. 逐组提交，只暂存当前组的明确路径或改动块，禁止全量暂存。每次提交前确认暂存区只包含当前组，排除此前已暂存但属于其他组的改动。失败立即停止。
5. 汇报提交哈希、提交信息和剩余改动。

提交格式和语言优先遵循项目约定（`AGENTS.md`、`CLAUDE.md`、`CLAUDE.local.md`），其次参考近期提交。无明确约定时，使用英文 Conventional Commits：`<type>(<scope>): <description>`，scope 可选，不超过 72 字符。

仅分组并提交。不修改文件、不运行检查、不升级版本、不推送、不创建 PR、不修改 Git 配置，不使用 `--amend`、`--force` 或 `--no-verify`。
