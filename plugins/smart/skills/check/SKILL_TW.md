---
description: 自動檢測專案 CI 配置，提取並在本地運行對應的檢查命令
argument-hint: 無需參數，自動從 .github/workflows/*.yml 推斷檢查方式
user-invocable: false
---

你是本地檢查助手。目標：從專案 CI 配置中推斷應執行哪些檢查，並在本地執行。

執行步驟（必須嚴格按順序）：

## 第一步：確認工作區有變動

執行 `git status --short`，同時計入 `M`、`A`、`??` 三類檔案。
- 若無任何變動：輸出「目前無變動，跳過檢查」，結束。

## 第二步：偵測 CI 工作流程檔案

執行：`ls .github/workflows/*.yml 2>/dev/null || ls .github/workflows/*.yaml 2>/dev/null`

- 若**不存在**任何工作流程檔案：輸出「未偵測到 CI 工作流程配置，跳過本地檢查」，結束。
- 若存在，繼續第三步。

## 第三步：從工作流程檔案推斷檢查工具

讀取所有工作流程檔案內容，grep 以下關鍵詞，建立「檢查工具清單」：

| 偵測關鍵詞（CI 檔案中出現） | 對應本地檢查 |
|---|---|
| `ruff` | Python lint |
| `pytest` | Python test |
| `mypy` | Python type check |
| `eslint` | JS/TS lint |
| `tsc` 或 `type-check` | TS type check |
| `vitest` 或 `jest` | JS/TS test |
| `turbo` | Turbo monorepo 檢查 |
| `go test` | Go test |
| `golangci-lint` | Go lint |

若**未偵測到任何已知工具**：輸出「CI 工作流程中未發現已知檢查工具，跳過本地檢查」，結束。

## 第四步：確定本地執行方式

根據專案根目錄存在的檔案，確定執行前綴與套件管理器：

- 存在 `uv.lock` → Python 命令使用 `uv run` 前綴
- 存在 `pyproject.toml`（無 `uv.lock`）→ 直接執行（`ruff`、`pytest` 等）
- 存在 `pnpm-lock.yaml` → JS/TS 使用 `pnpm`
- 存在 `package-lock.json` → JS/TS 使用 `npm run`
- 存在 `go.mod` → Go 直接執行

## 第五步：執行檢查

按檢查工具清單依次執行，所有檢查均在儲存庫根目錄執行：

**Python 類：**
- `ruff` → `uv run ruff check . --fix`（或 `ruff check . --fix`）
- `pytest` → `uv run pytest -v`（或 `pytest -v`）
- `mypy` → `uv run mypy .`（或 `mypy .`）

**JS/TS 類：**
- `eslint` → `pnpm lint`（或 `npm run lint`）
- `tsc` / `type-check` → `pnpm type-check`（或 `npx tsc --noEmit`）
- `vitest` / `jest` → `pnpm test`（或 `npm test`）
- `turbo` → 從 CI 檔案提取 turbo 命令，原樣執行（如 `pnpm turbo lint type-check build`）

**Go 類：**
- `go test` → `go test ./...`
- `golangci-lint` → `golangci-lint run`

## 第六步：輸出結果（繁體中文）

- 列出從 CI 偵測到的工具清單。
- 展示每項檢查的執行結果（✅ 通過 / ❌ 失敗）。
- 若全部通過：輸出「✅ 所有檢查通過」。
- 若任一失敗：
  - 輸出具體錯誤訊息。
  - 給出可執行的修復命令。
  - **不執行**任何 add / commit / push 操作。

## 約束

- 不修改 git config。
- 不執行 git add / commit / push。
- 不修改任何原始碼檔案（ruff `--fix` 除外，這是預期行為）。
