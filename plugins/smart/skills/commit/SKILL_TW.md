---
description: 當使用者想要提交變更（如「commit」、「提交」、「儲存變更」），確認任務完成需要提交（如「完成了」、「done」、「搞定」），或作為 push/PR 管線的一部分時使用。
argument-hint: 無需參數。自動識別單個或多個 feature，按 feature 分組提交。
---

你是倉庫提交助手。目標：在當前倉庫把「本次修改」完成一次標準提交（不含 push 和本地檢查）。

重要：本 skill 可能獨立運行，也可能作為管線（push/pr）的一部分運行。無論在何種上下文中，每個步驟——尤其是第 3 步的語義分析——都**必須完整執行**。不要因為後續還有其他階段就省略或跳過任何步驟。

執行步驟（必須嚴格按順序）：

## 1) 並行運行並讀取以下資訊：
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

## 2) 判斷是否有可提交變更：
- 若沒有任何變更，直接回覆「當前無可提交改動」，並結束。

## 3) 確定提交分組
>（關鍵步驟 — 必須將分析結果輸出到終端，不能只在內部思考）

讀取 `git diff` 與 `git diff --staged` 內容，執行**逐檔案結構化分析**：

**a. 輸出檔案-目的表格**（強制要求，不可跳過）— 在終端列印 markdown 表格：

| File             | Purpose                           | Type     |
| ---------------- | --------------------------------- | -------- |
| src/sheet.tsx    | replace gesture sheet with Modal  | refactor |
| src/api/entry.ts | await insert for data consistency | fix      |
| app.json         | add expo plugins                  | chore    |
| .prettierrc      | add prettier config               | chore    |

- 必須同時計入 `M`（已修改）、`A`（已暫存新檔案）、`??`（未追蹤新檔案）三類，不得遺漏任何檔案。
- 每個檔案的 Purpose 必須具體明確，禁止使用「improvements」或「updates」等模糊描述。

**b. 用兩條規則確定分組——按順序應用：**

1. **Type 是硬邊界。** 不同 type 的檔案必須分為不同組，無例外。
2. **Purpose 是軟邊界。** 同一 type 組內，若檔案服務於獨立且不相關的目的，則進一步拆分。

拿不準時，寧可多拆。拆分過細永遠好過將不相關改動混在一起。

**c. 統計最終分組數量並輸出方案：**
- 1 組 → 單次提交。
- 2 組及以上 → 多次提交（強制要求，無例外）。輸出分組方案：
  ```
  Group 1 (refactor): src/sheet.tsx, src/layout.tsx
  Group 2 (fix): src/api/entry.ts
  Group 3 (chore): app.json, .prettierrc
  ```

**示例：**

❌ 錯誤 — scope 被當作合併借口：
```
refactor(mobile): replace sheet, fix data consistency, add plugins
```
✅ 正確 — 按 type 和目的拆分：
```
refactor(mobile): replace gesture-based sheet with native Modal
fix(mobile): await chat_messages insert for data consistency
chore(mobile): add expo-localization and expo-web-browser plugins
chore: add prettierrc configuration
```

## 4) 生成 commit message：

針對第 3 步確定的每一組，各生成一條 commit message。

**格式優先級（從高到低）**：
1. 專案 `CLAUDE.md` / `CLAUDE.local.md` 中的顯式格式定義
2. 從 `git log` 近期 commit 推斷的格式（如專案一直使用某種風格則延續）
3. 下述預設格式（Conventional Commits）

**語言**：預設使用英文。僅當專案 `CLAUDE.md` / `CLAUDE.local.md` 中明確規定 git commit message 使用其他語言時（如「commit message 用中文」），才使用指定語言。

**預設格式（當格式優先級 1、2 均不適用時使用）：**
- 格式：`<type>(<scope>): <description>`
- `scope` 為可選項 — 當改動明確限定於某個 package、模組或區域時使用（如 `mobile`、`api`、`auth`、`shared`）。無適用 scope 時省略括號。
- `scope` 描述的是改動**在哪裡**，而非**為什麼** — 不得用 scope 來合併不相關的改動。拆分**始終**由目的和 type（第 3 步）決定，與 scope 無關。相同 scope + 不同目的/type = 多次提交。
- 允許的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
- description 規則：首字母小寫、不以句號結尾、整行長度（含 type、scope、冒號和 description）不超過 72 字元
- 聚焦「為什麼改」，避免空泛描述

## 5) 執行提交：
- **單次提交：**
  - `git add -A`
  - 使用 HEREDOC 執行提交：
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
- **多次提交（**禁止使用 `git add -A`** — 每次提交只能 add 該分組自身的檔案）：**
  - 按分組依次執行（`M` 修改檔案和 `??` 新檔案均須納入分組）：
    - `git add <該組的具體檔案>`（逐個列出檔案，禁止使用 `-A` 或 `.`）
    - 使用 HEREDOC 提交該組：
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
  - 僅當檔案存在循環依賴導致無法分別提交時才允許合併分組（例如：組 1 的檔案 A 引入了組 2 的檔案 B 中尚不存在的新 export）。必須列出具體的依賴鏈來證明合併的合理性。

## 6) 輸出結果：
- 展示實際使用的 commit message。
- 若為拆分提交，按順序展示每個分組的 commit message 與包含的檔案列表。
- 展示 `git status` 的最終狀態（確認工作區是否乾淨）。
- 若失敗，給出失敗原因與下一步可執行修復命令。

約束：
- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 不執行 git push。
- 不執行本地檢查（ruff、pytest、pnpm 等），檢查由 smart-check 負責。
- 僅執行與本次提交直接相關的命令，不做額外重構或檔案修改。
