---
description: 當使用者想要提交變更（如「commit」、「提交」、「儲存變更」），確認任務完成需要提交（如「完成了」、「done」、「搞定」），或作為 push/PR 管線的一部分時使用。
argument-hint: 無需參數。自動識別單個或多個 feature，按 feature 分組提交。
---

你是倉庫提交助手。目標：在當前倉庫把「本次修改」完成一次標準提交（不含 push 和本地檢查）。

重要提示：本 skill 可獨立執行，也可作為管線（push/pr）的一部分執行。無論在何種上下文中，每個步驟 — 特別是第 3 步的語義分析 — 都必須完整執行。不得因為後續還有其他階段要執行就省略或跳過任何步驟。

執行步驟（必須嚴格按順序）：

1) 並行運行並讀取以下資訊：
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) 判斷是否有可提交變更：
- 若沒有任何變更，直接回覆「當前無可提交改動」，並結束。

3) 語義分析，判斷提交策略（關鍵步驟 — 你必須將分析結果輸出到終端，而不僅僅是在思考中完成）：
- 讀取 `git diff` 與 `git diff --staged` 內容，執行**逐檔案結構化分析**：
  a. **輸出檔案用途表**（強制要求，不可跳過）— 在終端輸出一個 markdown 表格：
     | File | Purpose | Type |
     |------|---------|------|
     | src/sheet.tsx | replace gesture sheet with Modal | refactor |
     | src/api/entry.ts | await insert for data consistency | fix |
     | app.json | add expo plugins | chore |
     | .prettierrc | add prettier config | chore |
     每個檔案的 Purpose 必須具體明確。禁止使用「improvements」或「updates」等空泛描述。
  b. **先按獨立目的分組，再用 type 驗證**：
     - 目的相同的檔案 → 歸為一組。
     - 目的不同的檔案 → 分屬不同組（即使 type 相同）。
     - 不同組之間 type 不同 → 確認必須拆分。
     - 同一組內部 type 不同 → 該組必須進一步拆分。
     - 總共 1 組 → **單次提交**。
     - 2 組及以上 → **多次提交**（強制要求，無例外）。
  c. **若為多次提交：將分組計畫輸出到終端**：
     Group 1 (refactor): src/sheet.tsx, src/layout.tsx
     Group 2 (fix): src/api/entry.ts
     Group 3 (chore): app.json, .prettierrc
  d. 按此分組進入第 4 步。
- **拆分規則（嚴格執行）**：
  - 禁止將不相關的改動籠統歸類為「update project」或「various improvements」等空泛描述。
  - 不同的 conventional commit 類型（feat + fix、feat + refactor、fix + docs 等）幾乎總是意味著多個 feature — **必須拆分**。
  - 相同類型但目的不同（例如兩個不相關的 fix）— **仍須拆分**。
  - 為 feature A 新增檔案 + 為 feature B 修改既有檔案 = 兩次提交，而非一次。
  - 拿不準時，**寧可多拆**。拆分過細永遠好過將不相關改動混在一起。
- **必須同時計入** `M`（已修改）、`A`（已暫存新檔案）、`??`（未追蹤新檔案）三類，不得遺漏任何檔案。
- **範例**：
  ❌ 錯誤 — 將不相關改動歸入空泛的 scope：
    | File | Purpose | Type |
    | src/sheet.tsx | mobile improvements | refactor |
    | src/api/entry.ts | mobile improvements | refactor |
    | .prettierrc | mobile improvements | refactor |
    → 單次提交："refactor(mobile): various improvements"
  ✅ 正確 — 按實際目的拆分：
    | File | Purpose | Type |
    | src/sheet.tsx | replace gesture sheet with Modal | refactor |
    | src/api/entry.ts | await insert for data consistency | fix |
    | .prettierrc | add prettier config | chore |
    → 3 次提交，每個目的/類型各一次
  ❌ 錯誤 — scope 被當作合併的藉口：
    refactor(mobile): replace sheet, fix data consistency, add plugins
  ✅ 正確 — 相同 scope，按目的/類型拆分：
    refactor(mobile): replace gesture-based sheet with native Modal
    fix(mobile): await chat_messages insert for data consistency
    chore(mobile): add expo-localization and expo-web-browser plugins
    chore: add prettierrc configuration

4) 生成 commit message：
- **預設格式（當專案 CLAUDE.md 未定義自訂 commit 格式時使用）：**
  - 格式：`<type>(<scope>): <description>`
  - `scope` 為可選項 — 當改動限於特定 package、模組或區域時使用（例如 `mobile`、`api`、`auth`、`shared`）。無適用 scope 時省略括號。
  - `scope` 描述的是改動「在哪裡」，而非「為什麼」— 不得用 scope 來合併不相關的改動。拆分始終由目的和 type（第 3 步）決定，永遠不由 scope 決定。相同 scope + 不同目的/type = 多次提交。
  - 允許的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description 規則：首字母小寫、不以句號結尾、整行長度（含 type、scope、冒號及 description）不超過 72 字元
  - 語言：跟隨使用者的交流語言（如使用者使用中文則用中文，使用英文則用英文）。不確定時預設英文。
  - 聚焦「為什麼改」，避免空泛描述
- **專案覆蓋：** 若專案 CLAUDE.md 中定義了自訂 commit message 格式或語言要求，以專案規範為準，忽略上述預設規則。
- 單 feature：
  - 按上述規則生成 1 條 commit message。
- 多 feature：
  - 按 feature 將改動分組（優先按目錄/模組邊界分組）。
  - 每個 feature 按上述規則生成 1 條 commit message。

5) 執行提交：
- 單 feature（僅當第 3 步確認所有檔案屬於同一目的時）：
  - `git add -A`
  - 使用 HEREDOC 執行提交：
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
- 多 feature（**禁止使用 `git add -A`** — 每次提交只能 add 該 feature 自身的檔案）：
  - 按 feature 分組依次執行（`M` 修改檔案和 `??` 新檔案均須納入分組）：
    - `git add <該組的具體檔案>`（逐個列出檔案，禁止使用 `-A` 或 `.`）
    - 使用 HEREDOC 提交該組：
```bash
git commit -m "$(cat <<'EOF'
<feature commit message>
EOF
)"
```
  - 僅在檔案存在循環依賴導致無法分開提交時（例如組 1 的檔案 A 引入了組 2 檔案 B 中尚不存在的新 export），才可合併分組。你必須列出具體的依賴鏈來證明合併的合理性。

6) 輸出結果：
- 展示實際使用的 commit message。
- 若為拆分提交，按順序展示每個 feature 的 commit message 與包含的檔案列表。
- 展示 `git status` 的最終狀態（確認工作區是否乾淨）。
- 若失敗，給出失敗原因與下一步可執行修復命令。

約束：
- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 不執行 git push。
- 不執行本地檢查（ruff、pytest、pnpm 等），檢查由 smart-check 負責。
- 僅執行與本次提交直接相關的命令，不做額外重構或檔案修改。
