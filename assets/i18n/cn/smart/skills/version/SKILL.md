---
description: 当用户提到"升级版本"、"更新版本号"、"发布"、"新版本"、"版本升级"、"准备发布"、"递增版本"时触发。在 push 管道中也会主动触发，支持任意分支执行。支持 plugin.json、package.json（含 monorepo）和 pyproject.toml。
argument-hint: "[目标分支] — 默认为 main"
model: sonnet
---

分析自上次版本升级（或分支从基准分叉）以来的 commit，将变更文件映射到其所属的版本文件，按语义化版本规范（`a.b.c`）独立升级每个版本号。

## 执行步骤

### 1) 确定基准分支与当前分支

- 若用户通过 `$0` 指定了基准分支，使用该分支；否则默认为 `main`。
- 执行：`git branch --show-current`，记录为 `CURRENT_BRANCH`。

### 2) 发现所有版本文件

**重要：直接执行下方 bash 命令。禁止使用 Glob 工具 — Glob 不尊重 `.gitignore`，会从 `node_modules` 等忽略目录中返回大量无关文件。**

使用 `git ls-files` 自动尊重 `.gitignore`，无需硬编码任何排除路径：

```bash
# 包含已跟踪文件 + 未跟踪但未被忽略的新文件
# 自动排除 .gitignore 中的所有路径（node_modules、.venv、dist 等）
{
  git ls-files
  git ls-files --others --exclude-standard
} 2>/dev/null | sort -u | grep -E '(^|/)package\.json$|(^|/)pyproject\.toml$|(^|/)app\.json$|\.claude-plugin/plugin\.json$'
```

过滤：仅保留包含 `"version"`（JSON）或 `version =`（TOML）字段的文件，丢弃其余。

**`app.json` 特殊处理：** 版本字段嵌套在 `expo.version` 下，而非根级别。过滤时，需确认文件同时包含 `"expo"` 和 `"version"` 字段。若同一目录下已存在 `package.json`，则跳过 `app.json`，避免重复升级（Node 工具链以 `package.json` 为准）。

若未找到任何版本文件，报告"未检测到版本文件 — 跳过版本升级"并**停止**。

将结果记录为 `VERSION_FILES`，包含各文件的目录路径。

### 3) 收集待分析的 commit

按优先级链式回退收集新 commit：

1. 执行：`git log <BASE_BRANCH>..HEAD --oneline`
2. 若为空（如已在基准分支上），定位上次版本升级 commit：

   ```bash
   LAST_BUMP=$(git log --all --oneline --grep="chore(version): bump" -1 --format="%H")
   ```

   - 若找到：`git log ${LAST_BUMP}..HEAD --oneline`
   - 若未找到（无历史版本升级记录）：`git log -20 --oneline`

3. 排除匹配 `chore(version): bump` 的 commit（之前的版本升级提交）。
4. 若无 commit 剩余，报告"无新 commit — 版本号不变"并**停止**。

记录为 `COMMITS`。

### 4) 将 commit 映射到版本文件

用**单条命令**一次性获取所有 commit 及其变更文件（避免逐 commit 调用 shell）：

```bash
git log <BASE_BRANCH>..HEAD --name-only --format="COMMIT:%H" | grep -v '^$'
```

解析输出：以 `COMMIT:` 开头的行是 commit 哈希；紧随其后的非空行是该 commit 变更的文件。

对每个变更文件，沿目录树向上查找最近的版本文件：

- 在每一级目录，检查 `VERSION_FILES` 中是否有文件位于该目录（按目录前缀匹配）。
- 第一个（最近的）匹配即为该变更文件的**所有者**。
- 若在所有祖先目录中都未找到版本文件，该文件**无归属**——跳过。

记录映射关系：`版本文件 → [触及其作用域的 commit 列表]`

一个 commit 若修改了跨包的文件，可能映射到**多个**版本文件。

### 5) 按版本文件确定升级类型

对每个有关联 commit 的版本文件：

1. 读取当前版本：
   - **JSON**（`plugin.json`、`package.json`）：读取 `"version"` 字段。
   - **TOML**（`pyproject.toml`）：读取 `[project]` 节下的 `version`。若未找到，检查 `[tool.poetry]`。

2. 按 Conventional Commits 格式（`<type>[!][(scope)]: <desc>`）分类每个 commit：

   | 条件                                                            | 升级类型  |
   | --------------------------------------------------------------- | --------- |
   | 类型后缀 `!` 或 body 包含 `BREAKING CHANGE`                     | **major** |
   | `feat`                                                          | **minor** |
   | `fix`、`refactor`、`perf`、`docs`、`test`、`chore`、`ci` 或其他 | **patch** |

3. 取**最高级别**的升级：
   - 存在 major → `(a+1).0.0`
   - 否则存在 minor → `a.(b+1).0`
   - 否则 → `a.b.(c+1)`

### 6) 应用新版本

使用 Edit 工具更新每个版本文件的 `version` 字段：

- **JSON**：`"version": "<new_version>"`
- **TOML**：`version = "<new_version>"`

### 7) 提交版本变更

暂存所有修改的版本文件，创建**一个** commit：

- 单个版本文件——主题：`chore(version): bump version to <new_version>`
- 多个版本文件——主题：`chore(version): bump versions`，body 逐一列出升级详情。

```bash
git add <所有修改的 VERSION_FILES>
git commit -m "$(cat <<'EOF'
chore(version): bump version to <new_version>

- <路径>: <旧版本> → <新版本> (<升级类型>)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 8) 输出

展示汇总表格：

```
| 版本文件                        | 类型    | 旧版本 | 新版本 | 升级  | 关键 Commit   |
| ------------------------------- | ------- | ------ | ------ | ----- | ------------- |
| packages/frontend/package.json  | Node.js | 1.2.0  | 1.3.0  | minor | feat(ui): ... |
| packages/backend/pyproject.toml | Python  | 0.5.1  | 0.5.2  | patch | fix(api): ... |
```

## 约束

- 不修改版本文件以外的任何文件。
- 不执行 push — push 由 push/PR 流程或用户自行处理。
- 若未检测到版本文件或无新 commit，不做任何操作。
- 不同包的变更绝不混淆——每个版本文件仅基于触及其作用域的 commit 进行升级。
