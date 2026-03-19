---
description: 當使用者想要建立 Pull Request（如「create PR」、「發個PR」、「提個PR」、「建立合併請求」），或需要完整的 check+commit+push+PR 管線時使用。已包含 push — 無需先手動推送。
argument-hint: 無需參數。自動 [check+add+commit+push+pr]
---

你是倉庫提交與 PR 助手。目標：先完成標準提交推送，再在 GitHub 上建立 Pull Request。

執行步驟（必須嚴格按順序，不可跳過）：

---

## 階段一：Push

@../push/SKILL_TW.md

- 若工作區乾淨（無任何變更），跳過階段一，直接進入階段二。

---

## 階段二：建立 Pull Request

7) 收集基礎資訊（並行執行）：
- `git branch --show-current`（當前分支名，記為 `HEAD_BRANCH`）
- `git log -1 --oneline`（最新一條 commit，用於判斷單 commit 場景）
- 確定 PR 標題、Summary 和 Test Plan 的語言：跟隨使用者的交流語言（如使用者使用中文則用中文，使用英文則用英文）。不確定時預設英文。若專案 CLAUDE.md 中定義了明確的語言指令，以專案規則為準。Section headers（## Summary、## Commits、## Test Plan）始終保持英文，commit messages 不翻譯。

8) 確定目標分支（base branch）：
- 如果使用者透過 $0 明確指定了目標分支，則使用該分支名稱作為 base branch。
- 否則**一定要**使用 `AskUserQuestion` 工具詢問使用者：
  > 請問 PR 的目標分支是？（預設 `main`，直接按 Enter 即可）
- 將使用者回答記為 `BASE_BRANCH`；若使用者直接按 Enter 或留空，則 `BASE_BRANCH=main`。

9) 檢查 PR 是否已存在：
- 執行：`gh pr list --head <HEAD_BRANCH> --json number,url,state`
- 若已存在同 head 分支的 **open** PR，直接展示現有 PR 的 URL，提示使用者 PR 已存在，並結束。

10) 收集完整 commit 列表：
- 執行：`git log <BASE_BRANCH>..HEAD --oneline`
- 記錄所有 commit（hash + message），用於產生 PR 正文。

11) 產生 PR 標題和正文：
- **語言**：使用步驟 7 中確定的語言。Section headers（## Summary, ## Commits, ## Test Plan）始終保持英文。
- **標題**：
  - 若本分支只有 1 個 commit，直接使用該 commit message 作為標題。
  - 若有多個 commit，基於分支名和 commit 列表產生 1 句概括性標題（50 字以內），風格與最近提交一致。
  - 若使用者在命令後附加了描述文字，優先將其融入標題。
- **正文**（Markdown 格式）：
  ```markdown
  ## Summary
  <3-10 條要點，說明本次 PR 做了什麼、為什麼這樣做。
   每條要點必須回答「改了什麼」和「為什麼改」——不要只是列出檔案名稱或重複 commit message。聚焦改動的意圖和影響。>

  ## Commits
  <列出 git log BASE_BRANCH..HEAD 的所有 commit，格式：`- <hash>: <message>` — 保持原始 commit message，不翻譯>

  ## Test Plan
  <根據 commit 列表中的 commit 類型產生測試項：
   - `feat` commits → 驗證新功能的核心行為和邊界情況
   - `fix` commits → 驗證原始 bug 不再重現，檢查回歸問題
   - `refactor` commits → 驗證現有行為未受影響
   - `docs` commits → 驗證文件準確性和連結有效性
   - `test` commits → 驗證測試通過且覆蓋率達標
   - `perf` commits → 驗證效能改善可度量
   - `chore`/`ci` commits → 驗證建置/CI 流程正常運行
   - 無類型前綴的 commit → 從 message 和檔案變更推斷意圖，產生對應測試項

   使用 `- [ ]` 格式（未勾選/待驗證），不要用 `- [x]`。每條必須針對本 PR 的實際改動，禁止使用空泛的「驗證功能正常」。>
  ```

12) 執行 PR 建立：
```bash
gh pr create \
  --title "<PR 標題>" \
  --base <BASE_BRANCH> \
  --body "$(cat <<'EOF'
<PR 正文>
EOF
)"
```
- 若 `gh` 命令不存在，提示使用者安裝：`brew install gh && gh auth login`，並結束。

---

## 輸出結果

成功時展示：
1. 階段一使用的所有 commit message（若有變動）。
2. **PR URL**（醒目格式）：`PR: <url>`
3. PR 標題與目標分支（`HEAD_BRANCH` -> `BASE_BRANCH`）。
4. 最終 `git status`（確認工作區乾淨）。

失敗時展示：
- 失敗發生在哪個步驟。
- 具體錯誤訊息。
- 下一步可執行的修復命令。

---

## 約束

- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 僅執行與本次提交和 PR 直接相關的命令，不做額外重構或檔案修改。
- PR 不自動 merge，也不自動 assign reviewer，建立後由使用者決定後續操作。
