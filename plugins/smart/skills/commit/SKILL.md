---
description: Use when the user wants to commit changes (e.g. "commit", "提交", "save my work"), confirms a task is done and needs committing (e.g. "完成了", "done", "搞定"), or as part of push/PR pipelines.
argument-hint: No arguments needed. Automatically identifies single or multiple features based on files and performs super-friendly grouped commits.
---

You are a repository commit assistant. Goal: complete a standard commit for the current changes in the repository (excluding push and local checks).

IMPORTANT: This skill may run standalone or as part of a pipeline (push/pr). Regardless of context, every step — especially the semantic analysis in step 3 — MUST be executed fully. Do not abbreviate or skip steps because there are subsequent phases to run.

Execution steps (must follow strictly in order):

1) Run and read the following information in parallel:
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) Determine if there are committable changes:
- If there are no changes at all, reply "No committable changes found" and stop.

3) Semantic analysis to determine commit strategy (CRITICAL — you MUST output the analysis to the terminal, not just think it):
- Read the content of `git diff` and `git diff --staged`, then perform a **structured file-level analysis**:
  a. **Output a file-purpose table** (mandatory, cannot be skipped) — print a markdown table to the terminal:
     | File | Purpose | Type |
     |------|---------|------|
     | src/sheet.tsx | replace gesture sheet with Modal | refactor |
     | src/api/entry.ts | await insert for data consistency | fix |
     | app.json | add expo plugins | chore |
     | .prettierrc | add prettier config | chore |
     Each file's Purpose must be specific and concrete. Do NOT use vague descriptions like "improvements" or "updates".
  b. **Group by independent purpose first, then validate with type**:
     - Files sharing the same purpose → one group.
     - Files with different purposes → different groups (even if same type).
     - Different types across groups → confirms split is mandatory.
     - Different types WITHIN a group → the group must be further split.
     - 1 group total → **single commit**.
     - 2+ groups → **multiple commits** (MANDATORY, no exceptions).
  c. **If multiple commits: output the grouping plan** to the terminal:
     Group 1 (refactor): src/sheet.tsx, src/layout.tsx
     Group 2 (fix): src/api/entry.ts
     Group 3 (chore): app.json, .prettierrc
  d. Proceed to step 4 with this grouping.
- **Splitting rules (strictly enforced)**:
  - Do NOT bundle unrelated changes under a vague umbrella like "update project" or "various improvements".
  - Different conventional commit types (feat + fix, feat + refactor, fix + docs, etc.) almost always indicate multiple features — **split them**.
  - Same type but different purposes (e.g., two unrelated fixes) — **still split them**.
  - Adding new files for feature A + modifying existing files for feature B = two commits, not one.
  - When in doubt, **split**. Too many small commits is always better than one bloated commit mixing unrelated changes.
- **Must account for all three statuses**: `M` (modified), `A` (staged new files), and `??` (untracked new files). Do not omit any files.
- **Examples**:
  ❌ WRONG — bundling unrelated changes under a vague scope:
    | File | Purpose | Type |
    | src/sheet.tsx | mobile improvements | refactor |
    | src/api/entry.ts | mobile improvements | refactor |
    | .prettierrc | mobile improvements | refactor |
    → single commit: "refactor(mobile): various improvements"
  ✅ CORRECT — splitting by actual purpose:
    | File | Purpose | Type |
    | src/sheet.tsx | replace gesture sheet with Modal | refactor |
    | src/api/entry.ts | await insert for data consistency | fix |
    | .prettierrc | add prettier config | chore |
    → 3 commits, one per purpose/type
  ❌ WRONG — scope used as grouping umbrella:
    refactor(mobile): replace sheet, fix data consistency, add plugins
  ✅ CORRECT — same scope, split by purpose/type:
    refactor(mobile): replace gesture-based sheet with native Modal
    fix(mobile): await chat_messages insert for data consistency
    chore(mobile): add expo-localization and expo-web-browser plugins
    chore: add prettierrc configuration

4) Generate commit message:
- **Default format (used when project CLAUDE.md does not define a custom commit format):**
  - Format: `<type>(<scope>): <description>`
  - `scope` is OPTIONAL — use it when changes are scoped to a specific package, module, or area (e.g., `mobile`, `api`, `auth`, `shared`). Omit parentheses when no scope applies.
  - `scope` describes WHERE the change is, not WHY — it must NOT be used to group unrelated changes. Splitting is ALWAYS determined by purpose and type (step 3), never by scope. Same scope + different purposes/types = multiple commits.
  - Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
  - Description rules: start with lowercase letter, no trailing period, total line length (including type, scope, colon, and description) must not exceed 72 characters
  - Language: match the language the user is communicating in (e.g., if user writes in Chinese, use Chinese; if in English, use English). Default to English if unclear.
  - Focus on "why the change was made", avoid vague descriptions
- **Project override:** If the project's CLAUDE.md defines custom commit message format or language requirements, follow the project's rules and ignore the defaults above.
- Single feature:
  - Generate 1 commit message following the rules above.
- Multiple features:
  - Group changes by feature (prefer grouping by directory/module boundaries).
  - Generate 1 commit message per feature following the rules above.

5) Execute the commit:
- Single feature (ONLY when step 3 confirms all files share one purpose):
  - `git add -A`
  - Use HEREDOC to execute the commit:
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
- Multiple features (**NEVER use `git add -A`** — each commit must only add its own files):
  - Execute sequentially by feature group (both `M` modified files and `??` new files must be included in grouping):
    - `git add <specific files for this group>` (list every file explicitly, do not use `-A` or `.`)
    - Use HEREDOC to commit this group:
```bash
git commit -m "$(cat <<'EOF'
<feature commit message>
EOF
)"
```
  - Only combine groups if files have circular dependencies that make separate commits impossible (e.g., file A in group 1 imports a new export from file B in group 2 that doesn't exist yet). You must list the specific dependency chain to justify combining.

6) Output results (in English):
- Display the actual commit message(s) used.
- If split into multiple commits, display each feature's commit message and included file list in order.
- Display the final `git status` output (confirm whether the working tree is clean).
- If failed, provide the failure reason and actionable next-step commands.

Constraints:
- Do not modify git config.
- Do not use `--amend`, `--force`, or `--no-verify`.
- Do not execute git push.
- Do not run local checks (ruff, pytest, pnpm, etc.) — checks are handled by smart-check.
- Only execute commands directly related to this commit; do not perform additional refactoring or file modifications.
