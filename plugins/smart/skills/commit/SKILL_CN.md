---
description: 当用户想要提交改动（如"commit"、"提交"、"保存改动"），确认任务完成需要提交（如"完成了"、"done"、"搞定"），或作为 push/PR 管道的一部分时使用。
argument-hint: 无需参数。自动识别单个或多个 feature，按 feature 分组提交。
---

你是仓库提交助手。目标：在当前仓库把"本次修改"完成一次标准提交（不含 push 和本地检查）。

重要：本 skill 可能独立运行，也可能作为管道（push/pr）的一部分运行。无论在何种上下文中，每个步骤——尤其是第 3 步的语义分析——都**必须完整执行**。不要因为后续还有其他阶段就省略或跳过任何步骤。

执行步骤（必须严格按顺序）：

1) 并行运行并读取以下信息：
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) 判断是否有可提交变更：
- 若没有任何变更，直接回复"当前无可提交改动"，并结束。

3) 语义分析，判断提交策略（关键步骤 — 必须将分析结果输出到终端，不能只在内部思考）：
- 读取 `git diff` 与 `git diff --staged` 内容，执行**逐文件结构化分析**：
  a. **输出文件-目的表格**（强制要求，不可跳过）— 在终端打印 markdown 表格：
     | File | Purpose | Type |
     |------|---------|------|
     | src/sheet.tsx | replace gesture sheet with Modal | refactor |
     | src/api/entry.ts | await insert for data consistency | fix |
     | app.json | add expo plugins | chore |
     | .prettierrc | add prettier config | chore |
     每个文件的 Purpose 必须具体明确，禁止使用 "improvements" 或 "updates" 等模糊描述。
  b. **阶段一 — 按 type 硬分组**（机械操作，无需语义判断）：
     - 严格按 `Type` 列分组。不同 type 的文件**不可能**出现在同一组中。此规则不可商量，无需语义判断。
     - 示例：若表格中包含 `refactor`、`fix`、`chore` 三种 type → 至少 3 组，每种 type 各一组。
  c. **阶段二 — 在同 type 组内按目的细分**（语义分析）：
     - 在阶段一的每个 type 组内部，判断文件是否服务于不同的独立目的。
     - 目的相同 → 保持为一组。
     - 目的不同 → 拆分为多组（例如：两个不相关的 `fix` 改动变为两组）。
  d. **统计最终分组数量**：
     - 总计 1 组 → **单次提交**。
     - 总计 2 组及以上 → **多次提交**（强制要求，无例外）。
  e. **若为多次提交：在终端输出分组方案**：
     Group 1 (refactor): src/sheet.tsx, src/layout.tsx
     Group 2 (fix): src/api/entry.ts
     Group 3 (chore): app.json, .prettierrc
  f. 携带此分组方案进入第 4 步。
- **拆分规则（严格执行）**：
  - 禁止将不相关的改动笼统归类为 "update project" 或 "various improvements" 等空泛描述。
  - 不同的 conventional commit 类型（feat + fix、feat + refactor、fix + docs 等）几乎总是意味着多个 feature — **必须拆分**。
  - 同一 type 但目的不同（如两个互不相关的 fix）— **仍须拆分**。
  - 为 feature A 新增文件 + 为 feature B 修改已有文件 = 两次提交，而非一次。
  - 拿不准时，**宁可多拆**。拆分过细永远好过将不相关改动混在一起。
- **必须同时计入** `M`（已修改）、`A`（已暂存新文件）、`??`（未追踪新文件）三类，不得遗漏任何文件。
- **示例**：
  ❌ 错误 — 将不相关改动笼统归入模糊 scope：
    | File | Purpose | Type |
    | src/sheet.tsx | mobile improvements | refactor |
    | src/api/entry.ts | mobile improvements | refactor |
    | .prettierrc | mobile improvements | refactor |
    → 单次提交: "refactor(mobile): various improvements"
  ✅ 正确 — 按实际目的拆分：
    | File | Purpose | Type |
    | src/sheet.tsx | replace gesture sheet with Modal | refactor |
    | src/api/entry.ts | await insert for data consistency | fix |
    | .prettierrc | add prettier config | chore |
    → 3 次提交，每个目的/类型各一次
  ❌ 错误 — scope 被当作合并借口：
    refactor(mobile): replace sheet, fix data consistency, add plugins
  ✅ 正确 — 相同 scope，按目的/类型拆分：
    refactor(mobile): replace gesture-based sheet with native Modal
    fix(mobile): await chat_messages insert for data consistency
    chore(mobile): add expo-localization and expo-web-browser plugins
    chore: add prettierrc configuration

4) 生成 commit message：
- **默认格式（当项目 CLAUDE.md 未定义自定义 commit 格式时使用）：**
  - 格式：`<type>(<scope>): <description>`
  - `scope` 为可选项 — 当改动明确限定于某个 package、模块或区域时使用（如 `mobile`、`api`、`auth`、`shared`）。无适用 scope 时省略括号。
  - `scope` 描述的是改动**在哪里**，而非**为什么** — 不得用 scope 来合并不相关的改动。拆分**始终**由目的和 type（第 3 步）决定，与 scope 无关。相同 scope + 不同目的/type = 多次提交。
  - 允许的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description 规则：首字母小写、不以句号结尾、整行长度（含 type、scope、冒号和 description）不超过 72 字符
  - 语言：默认使用英文。仅当项目的 `CLAUDE.md` 或 `CLAUDE.local.md` 明确指定了 commit message 语言时，才使用指定语言。
  - 聚焦"为什么改"，避免空泛描述
- **项目覆盖：** 如果项目 `CLAUDE.md` 或 `CLAUDE.local.md` 中定义了自定义 commit message 格式或语言要求，以项目规范为准，忽略上述默认规则。
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
  - 仅当文件存在循环依赖导致无法分别提交时才允许合并分组（例如：组 1 的文件 A 导入了组 2 的文件 B 中尚不存在的新 export）。必须列出具体的依赖链来证明合并的合理性。

6) 输出结果：
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
