---
description: 当用户想要提交已暂存或未暂存的改动（如"commit"、"提交"、"保存改动"、"完成了"、"make a commit"）时使用。仅执行提交操作——不做 CI 检测、不做 version bump、不做 push。
argument-hint: 无需参数。自动识别单个或多个 feature，按 feature 分组提交。
---

目标：在当前仓库把"本次修改"完成一次标准提交。本 skill **仅执行提交**——不做检查、不做 version bump、不做 push。

执行步骤（必须严格按顺序）：

## 1) 并行运行并读取以下信息：

- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

## 2) 判断是否有可提交变更：

- 若 `git status --short` 返回为空（工作区完全干净），直接回复"当前无可提交改动"，并结束。

## 3) 确定提交分组

> （关键步骤 — 必须将分析结果输出到终端，不能只在内部思考）

读取 `git diff` 与 `git diff --staged` 内容，执行**逐文件结构化分析**：

**a. 输出文件-目的表格**（强制要求，不可跳过）— 在终端打印 markdown 表格：

| File             | Purpose                           | Type     |
| ---------------- | --------------------------------- | -------- |
| src/sheet.tsx    | replace gesture sheet with Modal  | refactor |
| src/api/entry.ts | await insert for data consistency | fix      |
| app.json         | add expo plugins                  | chore    |
| .prettierrc      | add prettier config               | chore    |

- 必须同时计入 `M`（已修改）、`A`（已暂存新文件）、`D`（已删除）、`??`（未追踪新文件）各类，不得遗漏任何文件。
- 对于未追踪文件（`??`），从文件名和路径推断 purpose——此类文件没有 diff 可读。
- 每个文件的 Purpose 必须具体明确，禁止使用 "improvements" 或 "updates" 等模糊描述。

**b. 用两条规则确定分组——按顺序应用：**

1. **Type 是硬边界。** 不同 type 的文件必须分为不同组，无例外。
2. **Purpose 是软边界。** 同一 type 组内，若文件服务于独立且不相关的目的，则进一步拆分。"独立无关"的判断标准：两个文件的改动可以独立回滚而不影响彼此，且各自的 commit message 会有实质性差异。

拿不准时，宁可多拆。拆分过细永远好过将不相关改动混在一起。

**c. 统计最终分组数量并输出方案：**

- 1 组 → 单次提交。
- 2 组及以上 → 多次提交（强制要求，无例外）。输出分组方案：
  ```
  Group 1 (refactor): src/sheet.tsx, src/layout.tsx
  Group 2 (fix): src/api/entry.ts
  Group 3 (chore): app.json, .prettierrc
  ```

**示例：**

❌ 错误 — scope 被当作合并借口：

```
refactor(mobile): replace sheet, fix data consistency, add plugins
```

✅ 正确 — 按 type 和目的拆分：

```
refactor(mobile): replace gesture-based sheet with native Modal
fix(mobile): await chat_messages insert for data consistency
chore(mobile): add expo-localization and expo-web-browser plugins
chore: add prettierrc configuration
```

## 4) 生成 commit message：

针对第 3 步确定的每一组，各生成一条 commit message。

**格式优先级（从高到低）**：

1. 项目 `CLAUDE.md` / `CLAUDE.local.md` 中的显式格式定义
2. 从 `git log` 近期 commit 推断的格式（如项目一直使用某种风格则延续）
3. 下述默认格式（Conventional Commits）

**语言**：按以下优先级链依次判断：

1. **CLAUDE.md / CLAUDE.local.md 显式规定** — 若项目文件中明确指定了 commit message 的语言（如"commit message 用中文"），直接使用该语言，停止判断。
2. **从 `git log` 推断** — 检查步骤 1 中已读取的近期 commit message 语言。若所有近期 commit 语言一致，则使用该语言。
3. **无法确定语言** — 若近期 commit message 存在多种语言，或仓库没有任何提交历史（新仓库），先调用 `ToolSearch`（query: `select:AskUserQuestion`）加载工具 schema，再调用 `AskUserQuestion` 询问用户："该仓库的 commit message 存在多种语言（或暂无历史记录），本次提交应使用哪种语言？（默认：英文）"

**默认格式（当格式优先级 1、2 均不适用时使用）：**

- 格式：`<type>(<scope>): <description>`
- `scope` 为可选项 — 当改动明确限定于某个 package、模块或区域时使用（如 `mobile`、`api`、`auth`、`shared`）。无适用 scope 时省略括号。
- `scope` 描述的是改动**在哪里**，而非**为什么** — 不得用 scope 来合并不相关的改动。拆分**始终**由目的和 type（第 3 步）决定，与 scope 无关。相同 scope + 不同目的/type = 多次提交。
- 允许的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
- description 规则：首字母小写、不以句号结尾、整行长度（含 type、scope、冒号和 description）不超过 72 字符
- 聚焦"为什么改"，避免空泛描述

## 5) 执行提交：

- **单次提交：**
  - `git add -A`
  - 使用 HEREDOC 执行提交：

```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

- **多次提交（**禁止使用 `git add -A`** — 每次提交只能 add 该分组自身的文件）：**
  - ⚠️ 首先执行 `git reset HEAD`，将所有已 staged 的文件全部 unstage（软重置——工作区改动完整保留）。这样可确保之前预先 staged 的文件不会泄漏进任何分组的提交。
  - 按分组依次执行（`M` 修改文件和 `??` 新文件均须纳入分组）：
    - `git add <该组的具体文件>`（逐个列出文件，禁止使用 `-A` 或 `.`）
    - 使用 HEREDOC 提交该组：

```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

- 仅当文件存在循环依赖导致无法分别提交时才允许合并分组（例如：组 1 的文件 A 导入了组 2 的文件 B 中尚不存在的新 export）。必须列出具体的依赖链来证明合并的合理性。

## 6) 输出结果：

- 展示实际使用的 commit message。
- 若为拆分提交，按顺序展示每个分组的 commit message 与包含的文件列表。
- 展示 `git status` 的最终状态（确认工作区是否干净）。
- 若失败，给出失败原因与下一步可执行修复命令。

约束：

- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 不执行 git push。
- 不执行 CI 或本地检查（ruff、pytest、pnpm 等）。
- 不执行 version bump。
- 仅执行与本次提交直接相关的命令，不做额外重构或文件修改。
