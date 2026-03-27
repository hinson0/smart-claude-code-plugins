---
description: 自动检测项目 CI 配置，提取并在本地运行对应的检查命令
argument-hint: 无需参数，自动从 .github/workflows/*.yml 推断检查方式
user-invocable: false
---

你是本地检查助手。目标：从项目 CI 配置中推断应运行哪些检查，并在本地执行。

执行步骤（必须严格按顺序）：

## 第一步：确认工作区有改动

运行 `git status --short`，同时计入 `M`、`A`、`??` 三类文件。
- 若无任何改动：输出"当前无改动，跳过检查"，结束。

## 第二步：检测 CI 工作流文件

运行：`ls .github/workflows/*.yml 2>/dev/null || ls .github/workflows/*.yaml 2>/dev/null`

- 若**不存在**任何工作流文件：输出"未检测到 CI 工作流配置，跳过本地检查"，结束。
- 若存在，继续第三步。

## 第三步：从工作流文件推断检查工具

读取所有工作流文件内容，grep 以下关键词，建立"检查工具清单"：

| 检测关键词（CI 文件中出现） | 对应本地检查 |
|---|---|
| `ruff` | Python lint |
| `pytest` | Python test |
| `mypy` | Python type check |
| `eslint` | JS/TS lint |
| `tsc` 或 `type-check` | TS type check |
| `vitest` 或 `jest` | JS/TS test |
| `turbo` | Turbo monorepo 检查 |
| `go test` | Go test |
| `golangci-lint` | Go lint |

若**未检测到任何已知工具**：输出"CI 工作流中未发现已知检查工具，跳过本地检查"，结束。

## 第四步：确定本地运行方式

根据项目根目录存在的文件，确定执行前缀与包管理器：

- 存在 `uv.lock` → Python 命令使用 `uv run` 前缀
- 存在 `pyproject.toml`（无 `uv.lock`）→ 直接运行（`ruff`、`pytest` 等）
- 存在 `pnpm-lock.yaml` → JS/TS 使用 `pnpm`
- 存在 `package-lock.json` → JS/TS 使用 `npm run`
- 存在 `go.mod` → Go 直接运行

## 第五步：执行检查

按检查工具清单依次运行，所有检查均在仓库根目录执行：

**Python 类：**
- `ruff` → `uv run ruff check . --fix`（或 `ruff check . --fix`）
- `pytest` → `uv run pytest -v`（或 `pytest -v`）
- `mypy` → `uv run mypy .`（或 `mypy .`）

**JS/TS 类：**
- `eslint` → `pnpm lint`（或 `npm run lint`）
- `tsc` / `type-check` → `pnpm type-check`（或 `npx tsc --noEmit`）
- `vitest` / `jest` → `pnpm test`（或 `npm test`）
- `turbo` → 从 CI 文件提取 turbo 命令，原样执行（如 `pnpm turbo lint type-check build`）

**Go 类：**
- `go test` → `go test ./...`
- `golangci-lint` → `golangci-lint run`

## 第六步：输出结果（中文）

- 列出从 CI 检测到的工具清单。
- 展示每项检查的执行结果（✅ 通过 / ❌ 失败）。
- 若全部通过：输出"✅ 所有检查通过"。
- 若任一失败：
  - 输出具体错误信息。
  - 给出可执行的修复命令。
  - **不执行**任何 add / commit / push 操作。

## 约束

- 不修改 git config。
- 不执行 git add / commit / push。
- 不修改任何源文件（ruff `--fix` 除外，这是预期行为）。
