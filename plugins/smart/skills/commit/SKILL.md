---
description: This skill should be used when the user wants to commit staged or unstaged changes (e.g. "commit", "save my work", "done", "make a commit"). Performs only the commit operation — no CI checks, no version bump, no push.
argument-hint: No arguments needed. Automatically identifies single or multiple features based on files and performs grouped commits.
model: sonnet
---

Goal: Complete a standard commit for the current repository changes. This skill performs ONLY the commit — no checks, no version bump, no push.

Execution steps (must follow strictly in order):

## 1) Run and read the following information in parallel:

- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

## 2) Determine if there are committable changes:

- If `git status --short` returns empty (working tree is completely clean), reply "No committable changes found" and stop.

## 3) Determine commit groups

> (CRITICAL — output the analysis to the terminal, not just think it)

Read `git diff` and `git diff --staged`, then perform a structured file-level analysis:

**a. Output a file-purpose table** (mandatory — print to terminal):

| File             | Purpose                           | Type     |
| ---------------- | --------------------------------- | -------- |
| src/sheet.tsx    | replace gesture sheet with Modal  | refactor |
| src/api/entry.ts | await insert for data consistency | fix      |
| app.json         | add expo plugins                  | chore    |
| .prettierrc      | add prettier config               | chore    |

- Include ALL files across all statuses: `M` (modified), `A` (staged new), `D` (deleted), `??` (untracked new).
- For untracked files (`??`), infer purpose from filename and path context — there is no diff to read.
- Each file's Purpose must be specific and concrete. Vague descriptions like "improvements" or "updates" are not acceptable.

**b. Form groups using two rules — apply in order:**

1. **Type is a hard boundary.** Files with different types are always in separate groups. No exceptions.
2. **Purpose is a soft boundary.** Within the same type group, split further if files serve independent, unrelated purposes. Two files are "independently purposed" if their changes could be reverted independently without breaking each other, and their commit messages would be meaningfully different.

When in doubt, split. Too many small commits is always better than one bloated commit mixing unrelated changes.

**c. Count final groups and output the plan:**

- 1 group → single commit.
- 2+ groups → multiple commits (mandatory, no exceptions). Output the grouping plan:
  ```
  Group 1 (refactor): src/sheet.tsx, src/layout.tsx
  Group 2 (fix): src/api/entry.ts
  Group 3 (chore): app.json, .prettierrc
  ```

**Example:**

❌ WRONG — scope used as a grouping umbrella:

```
refactor(mobile): replace sheet, fix data consistency, add plugins
```

✅ CORRECT — split by type and purpose:

```
refactor(mobile): replace gesture-based sheet with native Modal
fix(mobile): await chat_messages insert for data consistency
chore(mobile): add expo-localization and expo-web-browser plugins
chore: add prettierrc configuration
```

## 4) Generate commit messages:

For each group determined in step 3, generate one commit message.

**Format priority (highest to lowest)**:

1. Explicit format defined in the project's `CLAUDE.md` / `CLAUDE.local.md`
2. Format inferred from recent `git log` commits (if the project consistently uses a style, follow it)
3. Default format below (Conventional Commits)

**Language**: Determine the language using the following priority chain:

1. **CLAUDE.md / CLAUDE.local.md explicit rule** — if the project file specifies a language for git commit messages (e.g., "commit messages in Chinese"), use that language and stop here.
2. **Infer from `git log`** — examine the recent commit messages already read in step 1. If all recent commits share the same language consistently, use that language.
3. **Cannot determine language** — if recent commits contain messages in multiple languages, or there is no commit history to infer from (new repository), first call `ToolSearch` with query `select:AskUserQuestion` to load the tool schema, then call `AskUserQuestion` to ask: "Commit messages in this repo use mixed languages (or no history exists). Which language should I use for this commit? (Default: English)"

**Default format (used when format priority 1 and 2 do not apply):**

- Format: `<type>(<scope>): <description>`
- `scope` is OPTIONAL — use when changes are scoped to a specific package, module, or area (e.g., `mobile`, `api`, `auth`, `shared`). Omit parentheses when no scope applies.
- `scope` describes WHERE the change is, not WHY — it must NOT be used to group unrelated changes. Splitting is ALWAYS determined by type and purpose (step 3), never by scope. Same scope + different purposes/types = multiple commits.
- Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
- Description rules: start with lowercase letter, no trailing period, total line length (including type, scope, colon, and description) must not exceed 72 characters
- Focus on "why the change was made", avoid vague descriptions

## 5) Execute the commit:

- **Single commit:**
  - `git add -A`
  - Commit using HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

- **Multiple commits (NEVER use `git add -A` — each commit must only stage its own files):**
  - ⚠️ First, run `git reset HEAD` to unstage all currently staged files (soft reset — working tree changes are fully preserved). This ensures no pre-staged files leak into any group's commit.
  - For each group, sequentially:
    - `git add <specific files for this group>` (list every file explicitly, do not use `-A` or `.`)
    - Commit using HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```

- Only combine groups if files have circular dependencies that make separate commits impossible (e.g., file A in group 1 imports a new export from file B in group 2 that doesn't exist yet). You must list the specific dependency chain to justify combining.

## 6) Output results:

- Display the actual commit message(s) used.
- If split into multiple commits, display each commit's message and included file list in order.
- Display the final `git status` output (confirm whether the working tree is clean).
- If failed, provide the failure reason and actionable next-step commands.

Constraints:

- Do not modify git config.
- Do not use `--amend`, `--force`, or `--no-verify`.
- Do not execute git push.
- Do not run CI or local checks (ruff, pytest, pnpm, etc.).
- Do not perform version bumps.
- Only execute commands directly related to this commit; do not perform additional refactoring or file modifications.
