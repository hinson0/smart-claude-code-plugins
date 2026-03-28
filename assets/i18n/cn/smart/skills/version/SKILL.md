---
name: version
description: 当用户提到"升级版本"、"更新版本号"、"发布"、"新版本"时触发，或在合并到 main 后准备发布时使用。在 push 管道中也会主动触发，但仅限基准分支（main）上执行。支持 plugin.json、package.json（含 monorepo）和 pyproject.toml。
argument-hint: "[目标分支] — 默认为 main"
---

分析基准分支上的 commit，将变更文件映射到其所属的版本文件，按语义化版本规范（`a.b.c`）独立升级每个版本号。

**重要：** 版本升级仅在基准分支（如 `main`）上执行。Feature 分支上跳过——等分支合并到 main 后再统一升级。

## 执行步骤

### 1) 确定基准分支并检查当前分支

- 如果用户通过 `$0` 指定了基准分支，使用该分支。否则默认为 `main`。
- 执行：`git branch --show-current`
- 若当前分支**不是**基准分支，报告"当前在 feature 分支 `<branch>` — 跳过版本升级（合并到 `<base>` 后再升级）"并**停止**。
- 若用户直接调用了 `/smart:version`（非通过 push 管道），无论在哪个分支都继续执行——用户明确知道自己在做什么。

### 2) 发现所有版本文件

扫描项目中的**所有**版本文件，收集每一个匹配项：

```bash
# Claude Code 插件
find . -maxdepth 4 -path '*/.claude-plugin/plugin.json' -not -path '*/node_modules/*' 2>/dev/null

# Node.js / 前端（根目录 + 工作区子包）
find . -maxdepth 4 -name 'package.json' -not -path '*/node_modules/*' -not -path '*/.claude-plugin/*' 2>/dev/null

# Python
find . -maxdepth 4 -name 'pyproject.toml' -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null
```

过滤：仅保留实际包含 `"version"`（JSON）或 `version =`（TOML）字段的文件，丢弃其余。

若未找到任何版本文件，报告"未检测到版本文件 — 跳过版本升级"并**停止**。

将结果记录为 `VERSION_FILES`，包含各文件的目录路径。

### 3) 收集待分析的 commit

- 执行：`git log <BASE_BRANCH>..HEAD --oneline`
- 若无 commit（如已在基准分支上），回退至上次版本升级以来的 commit：`git log $(git log --oneline --grep="bump version" | head -1 | awk '{print $1}')..HEAD --oneline`
- 排除 message 匹配 `chore(version): bump` 的 commit（之前的版本升级提交）。
- 若仍无 commit，报告"无新 commit — 版本号不变"并停止。

记录为 `COMMITS`。

### 4) 将 commit 映射到版本文件

对 `COMMITS` 中的每个 commit：

1. 获取变更文件：`git show --name-only --format="" <hash>`
2. 对每个变更文件，**沿目录树向上查找**最近的版本文件：
   - 在每一级目录，检查 `VERSION_FILES` 中是否有文件位于该目录（按目录前缀匹配）。
   - 第一个（最近的）匹配即为该变更文件的**所有者**。
   - 若在所有祖先目录中都未找到版本文件，该文件**无归属**（跳过，不参与版本升级）。
3. 记录映射关系：`版本文件 → [触及其作用域的 commit 列表]`

一个 commit 若修改了跨包的文件，可能映射到**多个**版本文件。

### 5) 按版本文件确定升级类型

对每个有关联 commit 的版本文件：

1. 从文件中读取当前版本：
   - **JSON**（`plugin.json`、`package.json`）：读取 `"version"` 字段。
   - **TOML**（`pyproject.toml`）：读取 `[project]` 节下的 `version`。若未找到，检查 `[tool.poetry]`。

2. 分析每个关联 commit 的类型前缀（Conventional Commits 格式 `<type>[!][(scope)]: <desc>`）：

   | 条件 | 升级类型 |
   |------|---------|
   | 类型后缀 `!` 或 commit body 包含 `BREAKING CHANGE` | **major** |
   | `feat` | **minor** |
   | `fix`、`refactor`、`perf`、`docs`、`test`、`chore`、`ci` 或其他 | **patch** |

3. 取**最高级别**的升级：
   - 存在 major → `(a+1).0.0`
   - 否则存在 minor → `a.(b+1).0`
   - 否则 → `a.b.(c+1)`

### 6) 应用新版本

对每个需要升级的版本文件，使用 Edit 工具更新 `version` 字段：
- **JSON**：更新 `"version": "<new_version>"`
- **TOML**：更新 `version = "<new_version>"`

### 7) 提交版本变更

暂存所有修改的版本文件，创建**一个** commit：

```bash
git add <所有修改的 VERSION_FILES>
git commit -m "$(cat <<'EOF'
chore(version): bump version to <new_version>

<若升级了多个文件，逐一列出：>
- <路径>: <旧版本> → <新版本>（<升级类型>）

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

单个版本文件时，commit message 主题为：
`chore(version): bump version to <new_version>`

多个版本文件时，commit message 主题为：
`chore(version): bump versions`
body 中列出每个文件的升级详情。

### 8) 输出

展示表格：

```
| 版本文件 | 类型 | 旧版本 | 新版本 | 升级 | 关键 Commit |
|---------|------|-------|-------|------|------------|
| packages/frontend/package.json | Node.js | 1.2.0 | 1.3.0 | minor | feat(ui): ... |
| packages/backend/pyproject.toml | Python | 0.5.1 | 0.5.2 | patch | fix(api): ... |
```

## 约束

- 不修改版本文件以外的任何文件。
- 不执行 push — push 由 push/PR 流程或用户自行处理。
- 若未检测到版本文件或无新 commit，不做任何操作。
- 不同包的变更绝不混淆——每个版本文件仅基于触及其作用域的 commit 进行升级。
