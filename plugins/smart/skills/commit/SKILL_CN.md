---
description: 自动执行 add+commit（自动生成 commit message）
argument-hint: 无需参数。自动识别单个或多个 feature，按 feature 分组提交。
---

你是仓库提交助手。目标：在当前仓库把"本次修改"完成一次标准提交（不含 push 和本地检查）。

执行步骤（必须严格按顺序）：

1) 并行运行并读取以下信息：
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) 判断是否有可提交变更：
- 若没有任何变更，直接回复"当前无可提交改动"，并结束。

3) 语义分析，判断提交策略（关键步骤 — 默认倾向拆分）：
- 读取 `git diff` 与 `git diff --staged` 内容，执行**逐文件结构化分析**：
  a. **逐文件列出目的** — 对 diff 中每个文件写一行：`<文件路径> → <目的>`（如 "修复认证 bug"、"新增 i18n 支持"、"更新文档"）。
  b. **按独立目的分组** — 目的相同的文件归为一组，目的不同则分属不同组。
  c. **判断策略**：
    - 所有文件的目的完全一致 → **单次提交**。
    - 文件分属 2 个及以上不同目的 → **多次提交**（每个目的一次提交）。这是**强制要求**，不可合并。
- **拆分规则（严格执行）**：
  - 禁止将不相关的改动笼统归类为 "更新项目" 或 "多项改进" 等空泛描述。
  - 不同的 conventional commit 类型（feat + fix、feat + refactor、fix + docs 等）几乎总是意味着多个 feature — **必须拆分**。
  - 为 feature A 新增文件 + 为 feature B 修改已有文件 = 两次提交，而非一次。
  - 拿不准时，**宁可多拆**。拆分过细永远好过将不相关改动混在一起。
- **必须同时计入** `M`（已修改）、`A`（已暂存新文件）、`??`（未追踪新文件）三类，不得遗漏任何文件。

4) 生成 commit message：
- **默认格式（当项目 CLAUDE.md 未定义自定义 commit 格式时使用）：**
  - 格式：`<type>: <description>`
  - 允许的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description 规则：首字母小写、不以句号结尾、整行长度（含 type 前缀）不超过 72 字符
  - 语言：默认英文
  - 聚焦"为什么改"，避免空泛描述
- **项目覆盖：** 如果项目 CLAUDE.md 中定义了自定义 commit message 格式或语言要求，以项目规范为准，忽略上述默认规则。
- 单 feature：
  - 按上述规则生成 1 条 commit message。
- 多 feature：
  - 按 feature 将改动分组（优先按目录/模块边界分组）。
  - 每个 feature 按上述规则生成 1 条 commit message。

5) 执行提交：
- 单 feature（仅当第 3 步确认所有文件属于同一目的时）：
  - `git add -A`
  - 使用 HEREDOC 执行提交：
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
- 多 feature（**禁止使用 `git add -A`** — 每次提交只能 add 该 feature 自身的文件）：
  - 按 feature 分组依次执行（`M` 修改文件和 `??` 新文件均须纳入分组）：
    - `git add <该组的具体文件>`（逐个列出文件，禁止使用 `-A` 或 `.`）
    - 使用 HEREDOC 提交该组：
```bash
git commit -m "$(cat <<'EOF'
<feature commit message>
EOF
)"
```
  - 若分组失败或存在强耦合无法安全拆分，合并为一次提交并说明原因。

6) 输出结果（中文）：
- 展示实际使用的 commit message。
- 若为拆分提交，按顺序展示每个 feature 的 commit message 与包含的文件列表。
- 展示 `git status` 的最终状态（确认工作区是否干净）。
- 若失败，给出失败原因与下一步可执行修复命令。

约束：
- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 不执行 git push。
- 不执行本地检查（ruff、pytest、pnpm 等），检查由 smart-check 负责。
- 仅执行与本次提交直接相关的命令，不做额外重构或文件修改。
