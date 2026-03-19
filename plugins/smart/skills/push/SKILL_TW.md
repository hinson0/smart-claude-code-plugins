---
description: 當使用者想要推送程式碼到遠端（如「push」、「推一下」、「推到遠端」），或需要完整的 check+commit+push 管線時使用。不用於建立 PR — 請使用 smart:pr。
argument-hint: 無需參數。自動 [check+add+commit+push]
---

你是倉庫提交助手。目標：在當前倉庫完成本地檢查、標準提交並推送。

執行步驟（必須嚴格按順序，不可跳過）：

---

## 階段一：本地檢查

@../check/SKILL_TW.md

- 若任一檢查失敗，**立即停止**，不執行後續階段。

---

## 階段二：提交

⚠️ 下方的 commit skill 包含一個關鍵的語義分析步驟（第 3 步）。必須完整執行——先輸出檔案-目的分析表和拆分決策，然後再執行任何 git 命令。

@../commit/SKILL_TW.md

⚠️ 驗證：上方的提交結果必須與語義分析的分組一致。如果你將所有檔案合成了一次提交，但分析顯示存在多種 type/目的，請立即停止並重做。

- 若工作區無任何變更，跳過本階段，直接進入階段三。

---

## 階段三：推送

### 3.1 檢查 origin 是否已配置

執行：`git remote get-url origin 2>/dev/null`

- 若已配置：直接執行 `git push -u origin HEAD`，跳到 3.3。
- 若未配置：繼續 3.2。

### 3.2 自動建立並關聯 GitHub 遠端倉庫

依次執行：

1. 確認 `gh` CLI 已登入：`gh auth status`
   - 若未登入，輸出提示「請先執行 `gh auth login`」，並**停止**。

2. 讀取倉庫名稱：`basename $(git rev-parse --show-toplevel)`

3. 讀取當前 GitHub 使用者名稱：`gh api user --jq .login`

4. 檢查遠端是否已存在同名倉庫：`gh repo view <使用者名稱>/<倉庫名> 2>/dev/null`
   - 若已存在：直接關聯，跳到步驟 6。
   - 若不存在：繼續步驟 5。

5. 建立 GitHub 倉庫（預設為私有）：
   ```
   gh repo create <倉庫名> --private --source=. --remote=origin
   ```

6. 若已存在但未關聯，手動新增 remote：
   ```
   git remote add origin https://github.com/<使用者名稱>/<倉庫名>.git
   ```

### 3.3 執行推送

```
git push -u origin HEAD
```

---

## 輸出結果

成功時展示：
1. 階段一的檢查結果摘要。
2. 階段二實際使用的所有 commit message（若有變動）。
3. 推送目標分支與結果。
4. 最終 `git status`（確認工作區是否乾淨）。

失敗時展示：
- 失敗發生在哪個階段與步驟。
- 具體錯誤訊息。
- 下一步可執行的修復命令。

---

## 約束

- 不修改 git config。
- 不使用 `--amend`、`--force`、`--no-verify`。
- 僅執行與本次提交直接相關的命令，不做額外重構或檔案修改。
