---
description: 當使用者想要提交變更（如「commit」、「提交」、「儲存變更」），確認任務完成需要提交（如「完成了」、「done」、「搞定」），或作為 push/PR 管線的一部分時使用。
argument-hint: 無需參數。自動識別單個或多個 feature，按 feature 分組提交。
---

你是倉庫提交助手。目標：在當前倉庫把「本次修改」完成一次標準提交（不含 push 和本地檢查）。

執行步驟（必須嚴格按順序）：

1) 並行運行並讀取以下資訊：
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) 判斷是否有可提交變更：
- 若沒有任何變更，直接回覆「當前無可提交改動」，並結束。

3) 語義分析，判斷提交策略（關鍵步驟 — 預設傾向拆分）：
- 讀取 `git diff` 與 `git diff --staged` 內容，執行**逐檔案結構化分析**：
  a. **逐檔案列出目的** — 對 diff 中每個檔案寫一行：`<檔案路徑> → <目的>`（如「修復認證 bug」、「新增 i18n 支援」、「更新文件」）。
  b. **按獨立目的分組** — 目的相同的檔案歸為一組，目的不同則分屬不同組。
  c. **判斷策略**：
    - 所有檔案的目的完全一致 → **單次提交**。
    - 檔案分屬 2 個及以上不同目的 → **多次提交**（每個目的一次提交）。這是**強制要求**，不可合併。
- **拆分規則（嚴格執行）**：
  - 禁止將不相關的改動籠統歸類為「更新專案」或「多項改進」等空泛描述。
  - 不同的 conventional commit 類型（feat + fix、feat + refactor、fix + docs 等）幾乎總是意味著多個 feature — **必須拆分**。
  - 為 feature A 新增檔案 + 為 feature B 修改既有檔案 = 兩次提交，而非一次。
  - 拿不準時，**寧可多拆**。拆分過細永遠好過將不相關改動混在一起。
- **必須同時計入** `M`（已修改）、`A`（已暫存新檔案）、`??`（未追蹤新檔案）三類，不得遺漏任何檔案。

4) 生成 commit message：
- **預設格式（當專案 CLAUDE.md 未定義自訂 commit 格式時使用）：**
  - 格式：`<type>: <description>`
  - 允許的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description 規則：首字母小寫、不以句號結尾、整行長度（含 type 前綴）不超過 72 字元
  - 語言：預設英文
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
  - 若分組失敗或存在強耦合無法安全拆分，合併為一次提交並說明原因。

6) 輸出結果（繁體中文）：
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
