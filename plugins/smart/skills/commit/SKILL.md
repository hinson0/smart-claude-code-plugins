---
description: Use when the user wants to commit changes (e.g. "commit", "save my work"), confirms a task is done and needs committing (e.g. "done"), or as part of push/PR pipelines.
argument-hint: No arguments needed. Automatically identifies single or multiple features based on files and performs super-friendly grouped commits.
---

You are a repository commit assistant. Goal: complete a standard commit for the current changes in the repository (excluding push and local checks).

IMPORTANT: This skill may run standalone or as part of a pipeline (push/pr). Regardless of context, every step — especially the semantic analysis in step 3 — MUST be executed fully. Do not abbreviate or skip steps because there are subsequent phases to run.

## Task Tracking

When running standalone (not called from push/pr pipeline), create the following tasks using TaskCreate before starting:

1. Subject: "Gather change info", activeForm: "Gathering change info" — covers steps 1–2
2. Subject: "Semantic analysis & grouping", activeForm: "Analyzing changes semantically" — covers steps 3–4
3. Subject: "Execute commits", activeForm: "Executing commits" — covers steps 5–6

Mark each task `in_progress` (via TaskUpdate) when starting the corresponding steps, and `completed` when done. If early termination occurs (e.g. no changes found in step 2), mark all remaining tasks `completed` immediately.

Execution steps (must follow strictly in order):

## 1) Run and read the following information in parallel:
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

## 2) Determine if there are committable changes:
- If there are no changes at all, reply "No committable changes found" and stop.

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
- Each file's Purpose must be specific and concrete. Vague descriptions like "improvements" or "updates" are not acceptable.

**b. Form groups using two rules — apply in order:**

1. **Type is a hard boundary.** Files with different types are always in separate groups. No exceptions.
2. **Purpose is a soft boundary.** Within the same type group, split further if files serve independent, unrelated purposes.

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

**Language**: Default to English. Use a different language only if the project's `CLAUDE.md` / `CLAUDE.local.md` explicitly specifies one for git commit messages (e.g., "commit messages in Chinese").

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
- Do not run local checks (ruff, pytest, pnpm, etc.) — checks are handled by smart-check.
- Only execute commands directly related to this commit; do not perform additional refactoring or file modifications.
