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

读取**每一个**工作流文件，逐个提取两类信息：

### 3a. 检测工具

grep 以下关键词，建立"检查工具清单"：

| 检测关键词（CI 文件中出现） | 对应本地检查 |
|---|---|
| `ruff` | Python lint |
| `pytest` | Python test |
| `mypy` 或 `pyright` | Python type check |
| `eslint` | JS/TS lint |
| `tsc` 或 `type-check` | TS type check |
| `vitest` 或 `jest` | JS/TS test |
| `turbo` | Turbo monorepo 检查 |
| `go test` | Go test |
| `golangci-lint` | Go lint |

### 3b. 检测工作目录（monorepo 支持）

对每个工作流文件，检查是否存在 `working-directory` 设置（`defaults.run.working-directory` 或单步骤级别）。记录映射：**工作流文件 → 工作目录**。

CI 中的典型模式：
```yaml
defaults:
  run:
    working-directory: apps/backend
```

若某工作流有工作目录，该工作流中检测到的所有工具继承该目录。若未指定工作目录，则从仓库根目录执行。

构建最终清单表：

| 工具 | 工作目录 | 来源工作流 |
|---|---|---|

若**未检测到任何已知工具**：输出"CI 工作流中未发现已知检查工具，跳过本地检查"，结束。

## 第四步：确定本地运行方式

根据项目根目录存在的文件，确定执行前缀与包管理器：

- 存在 `uv.lock` → Python 命令使用 `uv run` 前缀
- 存在 `pyproject.toml`（无 `uv.lock`）→ 直接运行（`ruff`、`pytest` 等）
- 存在 `pnpm-lock.yaml` → JS/TS 使用 `pnpm`
- 存在 `package-lock.json` → JS/TS 使用 `npm run`
- 存在 `go.mod` → Go 直接运行

## 第五步：执行检查

**关键要求：运行清单中的全部工具。不得根据哪些文件有改动而选择性跳过。本地检查的目的是镜像 CI——CI 会运行每个工作流，本地检查也必须运行每个检测到的工具。**

对于清单中的每个工具，先 `cd` 到第三步 3b 中确定的工作目录再执行。若未检测到工作目录，则在仓库根目录执行。

**Python 类：**
- `ruff` → `cd <dir> && uv run ruff check . --fix`（或 `ruff check . --fix`）
- `pytest` → `cd <dir> && uv run pytest -v`（或 `pytest -v`）
- `mypy` / `pyright` → `cd <dir> && uv run mypy .`（或 `uv run pyright .`）

**JS/TS 类：**
- `eslint` → `cd <dir> && pnpm lint`（或 `npm run lint`）
- `tsc` / `type-check` → `cd <dir> && pnpm type-check`（或 `npx tsc --noEmit`）
- `vitest` / `jest` → `cd <dir> && pnpm test`（或 `npm test`）
- `turbo` → 从 CI 文件提取 turbo 命令，原样执行（如 `pnpm turbo lint type-check build`）

**Go 类：**
- `go test` → `cd <dir> && go test ./...`
- `golangci-lint` → `cd <dir> && golangci-lint run`

当清单跨越多个工作目录（如 `apps/backend` 和 `apps/mobile`）时，在各自目录中分别运行。不得将所有检查合并到同一目录。

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
- 不按改动文件筛选检查。每次必须运行完整的检查工具清单。
