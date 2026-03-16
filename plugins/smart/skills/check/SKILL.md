---
description: Auto-detect project CI configuration, extract and run corresponding check commands locally (generic, no fixed directory structure dependency)
argument-hint: No arguments needed, automatically infers check method from .github/workflows/*.yml
user-invocable: false
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

Read all workflow file contents, grep for the following keywords, and build a "check tool inventory":

| Detection keyword (appears in CI files) | Corresponding local check |
|---|---|
| `ruff` | Python lint |
| `pytest` | Python test |
| `mypy` | Python type check |
| `eslint` | JS/TS lint |
| `tsc` or `type-check` | TS type check |
| `vitest` or `jest` | JS/TS test |
| `turbo` | Turbo monorepo check |
| `go test` | Go test |
| `golangci-lint` | Go lint |

If **no known tools are detected**: output "No known check tools found in CI workflows, skipping local checks", and stop.

## Step 4: Determine local execution method

Based on files present in the project root directory, determine the execution prefix and package manager:

- `uv.lock` exists → Python commands use `uv run` prefix
- `pyproject.toml` exists (no `uv.lock`) → run directly (`ruff`, `pytest`, etc.)
- `pnpm-lock.yaml` exists → JS/TS uses `pnpm`
- `package-lock.json` exists → JS/TS uses `npm run`
- `go.mod` exists → Go runs directly

## Step 5: Execute checks

Run each tool in the check tool inventory sequentially, all checks executed from the repository root:

**Python:**
- `ruff` → `uv run ruff check . --fix` (or `ruff check . --fix`)
- `pytest` → `uv run pytest -v` (or `pytest -v`)
- `mypy` → `uv run mypy .` (or `mypy .`)

**JS/TS:**
- `eslint` → `pnpm lint` (or `npm run lint`)
- `tsc` / `type-check` → `pnpm type-check` (or `npx tsc --noEmit`)
- `vitest` / `jest` → `pnpm test` (or `npm test`)
- `turbo` → extract turbo command from CI file, execute as-is (e.g., `pnpm turbo lint type-check build`)

**Go:**
- `go test` → `go test ./...`
- `golangci-lint` → `golangci-lint run`

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
