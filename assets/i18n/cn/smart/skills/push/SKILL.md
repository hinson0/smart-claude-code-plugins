---
description: 当用户想要推送代码到远程（如"push"、"推一下"、"推到远程"），或需要完整的 check+commit+push 管道时使用。不用于创建 PR — 请使用 smart:pr。推送前会自动进行版本升级。
argument-hint: 无需参数。自动 [check+add+commit+version+push]
---

你是仓库提交助手。目标：在当前仓库完成本地检查、标准提交、版本升级并推送。

执行步骤（必须严格按顺序，不可跳过）：

---

## 阶段一：本地检查

@../check/SKILL.md

- 若任一检查失败，**立即停止**，不执行后续阶段。

---

## 阶段二：提交

⚠️ 下方的 commit skill 包含一个关键的语义分析步骤（第 3 步）。必须完整执行——先输出文件-目的分析表和拆分决策，然后再运行任何 git 命令。

@../commit/SKILL.md

⚠️ 验证：上方的提交结果必须与语义分析的分组一致。如果你将所有文件合成了一次提交，但分析显示存在多种 type/目的，请立即停止并重做。

- 若工作区无任何变更，跳过本阶段，直接进入阶段三。

**提交完成后，运行 `git status --short` 检查是否还有剩余改动。** 若仍有未提交的文件，自动对这些文件再次执行提交阶段——不要停下来询问用户。重复执行，直至工作区干净。用户执行 push 的意图就是推送所有改动。

---

## 阶段三：版本升级

@../version/SKILL.md

- 执行 version skill，分析自上次版本升级以来的 commit 并自动更新检测到的版本文件。
- 若 version skill 报告"无新 commit"或版本无变化，跳过此阶段继续。

---

## 阶段四：推送

### 4.1 检查 origin 是否已配置

运行：`git remote get-url origin 2>/dev/null`

- 若已配置：直接执行 `git push -u origin HEAD`，跳到 4.3。
- 若未配置：继续 4.2。

### 4.2 自动创建并关联 GitHub 远程仓库

依次执行：

1. 确认 `gh` CLI 已登录：`gh auth status`
   - 若未登录，输出提示"请先运行 `gh auth login`"，并**停止**。

2. 读取仓库名称：`basename $(git rev-parse --show-toplevel)`

3. 读取当前 GitHub 用户名：`gh api user --jq .login`

4. 检查远程是否已存在同名仓库：`gh repo view <用户名>/<仓库名> 2>/dev/null`
   - 若已存在：直接关联，跳到步骤 6。
   - 若不存在：继续步骤 5。

5. 创建 GitHub 仓库（默认私有）：
   ```
   gh repo create <仓库名> --private --source=. --remote=origin
   ```

6. 若已存在但未关联，手动添加 remote：
   ```
   git remote add origin https://github.com/<用户名>/<仓库名>.git
   ```

### 4.3 执行推送

```
git push -u origin HEAD
```

---

## 输出结果

成功时展示：
1. 阶段一的检查结果摘要。
2. 阶段二实际使用的所有 commit message（若有改动）。
3. 阶段三的版本升级结果：必须**原样转述** version skill 输出的跳过/结果消息（如"在特性分支上——跳过"、"无新 commit——版本不变"、或"旧版本 → 新版本"）。不要自行改写或概括。
4. 推送目标分支与结果。
5. 最终 `git status`（确认工作区是否干净）。

失败时展示：
- 失败发生在哪个阶段与步骤。
- 具体错误信息。
- 下一步可执行的修复命令。

---

## 约束

- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 仅执行与本次提交直接相关的命令，不做额外重构或文件修改。
