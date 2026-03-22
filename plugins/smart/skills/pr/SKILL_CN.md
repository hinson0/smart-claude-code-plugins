---
description: 当用户想要创建 Pull Request（如"pr"、"PR"、"create PR"、"发个PR"、"提个PR"、"创建合并请求"），或需要完整的 check+commit+push+PR 管道时使用。已包含 push — 无需先手动推送。
argument-hint: 无需参数。自动 [check+add+commit+push+pr]
---

你是仓库提交与 PR 助手。目标：先完成标准提交推送，再在 GitHub 上创建 Pull Request。

执行步骤（必须严格按顺序，不可跳过）：

---

## 阶段一：Push

@../push/SKILL_CN.md

- 若工作区干净（无任何变更），跳过阶段一，直接进入阶段二。

---

## 阶段二：创建 Pull Request

7) 收集基础信息（并行运行）：
- `git branch --show-current`（当前分支名，记为 `HEAD_BRANCH`）
- `git log -1 --oneline`（最新一条 commit，用于判断单 commit 场景）
- 确定 PR 标题、Summary 和 Test Plan 的语言：默认使用英文。仅当项目的 `CLAUDE.md` 或 `CLAUDE.local.md` 明确指定了 PR/commit 内容语言时，才使用指定语言。Section headers（## Summary、## Commits、## Test Plan）始终保持英文，commit messages 不翻译。

8) 确定目标分支（base branch）：
- 如果用户使用了 $0 来显式指定了目标分支，则使用此分支名字作为 base branch。
- 否则**一定要**使用 `AskUserQuestion` 工具询问用户：
  > 请问 PR 的目标分支是？（默认 `main`，直接回车即可）
- 将用户回答记为 `BASE_BRANCH`；若用户直接回车或留空，则 `BASE_BRANCH=main`。

9) 检查 PR 是否已存在：
- 运行：`gh pr list --head <HEAD_BRANCH> --json number,url,state`
- 若已存在同 head 分支的 **open** PR，直接展示现有 PR 的 URL，提示用户 PR 已存在，并结束。

10) 收集完整 commit 列表：
- 运行：`git log <BASE_BRANCH>..HEAD --oneline`
- 记录所有 commit（hash + message），用于生成 PR 正文。

11) 生成 PR 标题和正文：
- **语言**：使用步骤 7 中确定的语言。Section headers（## Summary, ## Commits, ## Test Plan）始终保持英文。
- **标题**：
  - 若本分支只有 1 个 commit，直接使用该 commit message 作为标题。
  - 若有多个 commit，基于分支名和 commit 列表生成 1 句概括性标题（50 字以内），风格与最近提交一致。
  - 若用户在命令后附加了描述文字，优先将其融入标题。
- **正文**（Markdown 格式）：
  ```markdown
  ## Summary
  <3-10 条要点，说明本次 PR 做了什么、为什么这样做。
   每条要点必须回答"改了什么"和"为什么改"——不要只是列出文件名或重复 commit message。聚焦改动的意图和影响。>

  ## Commits
  <列出 git log BASE_BRANCH..HEAD 的所有 commit，格式：`- <hash>: <message>` — 保持原始 commit message，不翻译>

  ## Test Plan
  <根据 commit 列表中的 commit 类型生成测试项：
   - `feat` commits → 验证新功能的核心行为和边界情况
   - `fix` commits → 验证原始 bug 不再复现，检查回归问题
   - `refactor` commits → 验证现有行为未受影响
   - `docs` commits → 验证文档准确性和链接有效性
   - `test` commits → 验证测试通过且覆盖率达标
   - `perf` commits → 验证性能改善可度量
   - `chore`/`ci` commits → 验证构建/CI 流程正常运行
   - 无类型前缀的 commit → 从 message 和文件变更推断意图，生成对应测试项

   使用 `- [ ]` 格式（未勾选/待验证），不要用 `- [x]`。每条必须针对本 PR 的实际改动，禁止使用泛泛的"验证功能正常"。>
  ```

12) 执行 PR 创建：
```bash
gh pr create \
  --title "<PR 标题>" \
  --base <BASE_BRANCH> \
  --body "$(cat <<'EOF'
<PR 正文>
EOF
)"
```
- 若 `gh` 命令不存在，提示用户安装：`brew install gh && gh auth login`，并结束。

---

## 输出结果

成功时展示：
1. 阶段一使用的所有 commit message（若有改动）。
2. **PR URL**（醒目格式）：`PR: <url>`
3. PR 标题与目标分支（`HEAD_BRANCH` -> `BASE_BRANCH`）。
4. 最终 `git status`（确认工作区干净）。

失败时展示：
- 失败发生在哪个步骤。
- 具体错误信息。
- 下一步可执行的修复命令。

---

## 约束

- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 仅执行与本次提交和 PR 直接相关的命令，不做额外重构或文件修改。
- PR 不自动 merge，也不自动 assign reviewer，创建后由用户决定后续操作。
