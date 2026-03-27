---
description: 当准备发布、创建 PR、完成 feature 分支时使用，或当用户提到"升级版本"、"更新版本号"、"发布"、"新版本"时触发。也应在 push 或开 PR 之前主动使用——如果分支上存在尚未计入版本号的 commit。根据基准分支以来的 commit 信息自动确定语义化版本升级类型（major/minor/patch）并更新 plugin.json。
argument-hint: "[目标分支] — 默认为 main"
---

你是版本管理助手。目标：分析基准分支以来的 commit 信息，按语义化版本规范（`a.b.c`）更新 `plugin.json` 中的版本号。

## 执行步骤

### 1) 读取当前版本

- 读取 `plugins/smart/.claude-plugin/plugin.json`，获取当前 `version` 字段（格式：`a.b.c`）。

### 2) 确定基准分支

- 如果用户通过 `$0` 指定了基准分支，使用该分支。
- 否则默认为 `main`。

### 3) 收集待分析的 commit

- 执行：`git log <BASE_BRANCH>..HEAD --oneline`
- 如果没有新 commit，报告"无新 commit — 版本号不变"并停止。

### 4) 确定版本升级类型

分析每个 commit 信息的类型前缀（Conventional Commits 格式 `<type>[!][(scope)]: <desc>`）：

| 条件 | 升级类型 |
|------|---------|
| 类型后缀 `!`（如 `feat!:`、`fix!:`）或 commit body 包含 `BREAKING CHANGE` | **major** |
| `feat` | **minor** |
| `fix`、`refactor`、`perf`、`docs`、`test`、`chore`、`ci` 或其他类型 | **patch** |

取所有 commit 中**最高级别**的升级：
- 存在 major → 升级 major（minor 和 patch 归零）
- 否则存在 minor → 升级 minor（patch 归零）
- 否则 → 升级 patch

### 5) 计算并应用新版本

- Major: `a.b.c` → `(a+1).0.0`
- Minor: `a.b.c` → `a.(b+1).0`
- Patch: `a.b.c` → `a.b.(c+1)`

更新 `plugins/smart/.claude-plugin/plugin.json` 中的 `version` 字段。

### 6) 提交版本变更

```bash
git add plugins/smart/.claude-plugin/plugin.json
git commit -m "$(cat <<'EOF'
chore(plugin): bump version to <new_version>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 7) 输出

显示：
- `<旧版本>` → `<新版本>`（升级类型）
- 列出决定升级类型的 commit

## 约束

- 不修改 `plugin.json` 以外的任何文件。
- 不执行 push — push 由 PR 流程或用户自行处理。
- 如果当前已在基准分支上（无分叉 commit），不做任何操作。
