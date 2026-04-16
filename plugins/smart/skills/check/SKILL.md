---
description: Auto-detect project CI configuration, extract and run corresponding check commands locally (generic, no fixed directory structure dependency)
argument-hint: No arguments needed, automatically infers check method from .github/workflows/*.yml
user-invocable: false
model: haiku
---

You are a local check assistant. Goal: infer which checks should be run from the project CI configuration and execute them locally.

Execution steps (must follow in strict order):

## Step 1: Confirm workspace has changes

Run `git status --short`, counting files with `M`, `A`, and `??` statuses.

- If no changes: output "No changes detected, skipping checks", and stop.

## Step 2: Detect CI workflow files

Run: `ls .github/workflows/*.yml 2>/dev/null || ls .github/workflows/*.yaml 2>/dev/null`

- If **no** workflow files exist: output "No CI workflow configuration detected, skipping local checks", and stop.
- If found, proceed to step 3.

## Step 3: Infer check tools from workflow files

Read **every** workflow file found. For each file, extract two things:

### 3a. Detect tools

Grep for the following keywords and build a "check tool inventory":

| Detection keyword (appears in CI files) | Corresponding local check |
| --------------------------------------- | ------------------------- |
| `ruff`                                  | Python lint               |
| `pytest`                                | Python test               |
| `mypy` or `pyright`                     | Python type check         |
| `eslint`                                | JS/TS lint                |
| `tsc` or `type-check`                   | TS type check             |
| `vitest` or `jest`                      | JS/TS test                |
| `turbo`                                 | Turbo monorepo check      |
| `go test`                               | Go test                   |
| `golangci-lint`                         | Go lint                   |

### 3b. Detect working directories (monorepo support)

For each workflow file, check for a `working-directory` setting (either under `defaults.run.working-directory` or per-step). Record the mapping: **workflow file → working directory**.

Example CI pattern:

```yaml
defaults:
  run:
    working-directory: apps/backend
```

If a workflow has a working directory, all tools detected in that workflow inherit it. If no working directory is specified, the tools run from the repository root.

Build the final inventory as a table:

| Tool | Working directory | Source workflow |
| ---- | ----------------- | --------------- |

If **no known tools are detected**: output "No known check tools found in CI workflows, skipping local checks", and stop.

## Step 4: Determine local execution method

Based on files present in the project root directory, determine the execution prefix and package manager:

- `uv.lock` exists → Python commands use `uv run` prefix
- `pyproject.toml` exists (no `uv.lock`) → run directly (`ruff`, `pytest`, etc.)
- `pnpm-lock.yaml` exists → JS/TS uses `pnpm`
- `package-lock.json` exists → JS/TS uses `npm run`
- `go.mod` exists → Go runs directly

## Step 5: Execute checks

**CRITICAL: Run ALL tools in the inventory. Do NOT selectively skip tools based on which files were changed. The purpose of local check is to mirror CI — CI runs every workflow, so local check must run every detected tool.**

For each tool in the inventory, `cd` into its working directory (from step 3b) before executing. If no working directory was detected, execute from the repository root.

**Python:**

- `ruff` → `cd <dir> && uv run ruff check . --fix` (or `ruff check . --fix`)
- `pytest` → `cd <dir> && uv run pytest -v` (or `pytest -v`)
- `mypy` / `pyright` → `cd <dir> && uv run mypy .` (or `uv run pyright .`)

**JS/TS:**

- `eslint` → `cd <dir> && pnpm lint` (or `npm run lint`)
- `tsc` / `type-check` → `cd <dir> && pnpm type-check` (or `npx tsc --noEmit`)
- `vitest` / `jest` → `cd <dir> && pnpm test` (or `npm test`)
- `turbo` → extract turbo command from CI file, execute as-is (e.g., `pnpm turbo lint type-check build`)

**Go:**

- `go test` → `cd <dir> && go test ./...`
- `golangci-lint` → `cd <dir> && golangci-lint run`

When the inventory spans multiple working directories (e.g., `apps/backend` and `apps/mobile`), run each group in its own directory. Never collapse all checks into one directory.

## Step 6: Output results (in English)

- List the tool inventory detected from CI.
- Show the execution result for each check (pass / fail).
- If all pass: output "All checks passed".
- If any fail:
  - Output the specific error message.
  - Provide actionable fix commands.
  - **Do not execute** any add / commit / push operations.

## Constraints

- Do not modify git config.
- Do not execute git add / commit / push.
- Do not modify any source files (except ruff `--fix`, which is expected behavior).
- Do not filter checks by changed files. Run the FULL check tool inventory every time.
