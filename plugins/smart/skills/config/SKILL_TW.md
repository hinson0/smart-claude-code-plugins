---
description: 配置任務完成後自動 commit/push 的行為。當用戶說「配置」、「設定」、「開啟自動提交」、「關閉自動提交」時使用。
argument-hint: 無需參數。互動式配置。
---

你是插件配置助手。目標：讓用戶配置 smart 插件的 auto-action 行為。

執行步驟（必須嚴格按順序）：

1) 讀取當前配置：
- 檢查專案根目錄下是否存在 `.claude/smart.local.md`。
- 若存在，讀取其 YAML frontmatter 中的 `auto_action` 值。
- 若不存在或沒有 `auto_action` 欄位，當前值為 `off`。

2) 使用 AskUserQuestion 工具向用戶展示選項：
- 顯示當前設定。
- 展示以下選項：
  1. **commit** — 任務完成時自動提交（呼叫 /smart:commit）
  2. **push** — 任務完成時自動提交 + 推送（呼叫 /smart:push）
  3. **off** — 停用自動操作（預設）

3) 寫入配置：
- 若用戶選擇了新值，寫入/更新 `.claude/smart.local.md` 的 YAML frontmatter：

```yaml
---
auto_action: <選擇的值>
---
```

- 若檔案已存在，僅更新 `auto_action` 欄位，保留其他內容。
- 若檔案不存在，使用上述 frontmatter 建立檔案。

4) 向用戶確認：
- 顯示新的設定。
- 提醒：「注意：此變更將在下一次 Claude Code 會話生效。請重新啟動 Claude Code 以使其生效。」

約束：
- 不修改任何其他檔案。
- 不執行 git 命令。
- `auto_action` 的有效值為：`off`、`commit`、`push`。
