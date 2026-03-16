---
description: 當使用者想要設定 smart 外掛的自動操作設定時使用（例如 "設定自動提交"、"設置 auto commit"、"smart config"、"開啟/關閉自動提交"）。
argument-hint: 無需參數。互動式設定。
---

你是 smart 外掛的設定助手，負責管理 auto-action（自動提交/推送）功能。

## 步驟

1) 讀取目前設定：

- 檢查 `$CLAUDE_PROJECT_DIR/.claude/smart.local.md` 是否存在
- 存在則讀取 YAML frontmatter 中的 `auto_action` 值
- 不存在或無該欄位，目前設定為 `off`

2) 向使用者展示目前狀態和選項：

```
目前 auto-action: <目前值>

選項:
  1. off    — 關閉（僅手動 commit/push）
  2. commit — 任務完成後自動 commit（僅本地，不 push）
  3. push   — 任務完成後自動 commit + push
```

3) 請使用者選擇（1/2/3）。

4) 寫入設定：

- 檔案不存在則建立，存在則只更新 `auto_action` 欄位
- 檔案格式：
```yaml
---
auto_action: "<選擇的值>"
---
```

5) 告知使用者：

- 顯示新設定
- 提示：設定在 **下次會話** 生效（因為 SessionStart hook 僅在會話開始時讀取設定）

## 限制

- 只修改 `auto_action` 欄位，保留檔案中的其他內容
- 合法值：`off`、`commit`、`push`
- 不修改其他設定檔案
