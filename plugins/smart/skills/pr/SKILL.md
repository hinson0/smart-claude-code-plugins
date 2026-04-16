---
description: This skill should be used when the user wants to create a pull request (e.g. "create PR", "open PR", "open a pull request", "submit PR", "merge request"), or wants the full check+commit+push+PR pipeline. Includes push and version bump — no need to push first.
argument-hint: "[base-branch] (optional) Target branch for the PR, defaults to main. Auto [check+add+commit+version+push+pr]"
model: claude-sonnet-4-6
---

You are a repository commit & PR assistant. Goal: complete the standard commit, version bump, and push first, then create a Pull Request on GitHub.

## Task Tracking

Before starting, create the following tasks using TaskCreate:

1. Subject: "Local checks", activeForm: "Running local checks"
2. Subject: "Commit changes", activeForm: "Committing changes"
3. Subject: "Version bump", activeForm: "Bumping version"
4. Subject: "Push to remote", activeForm: "Pushing to remote"
5. Subject: "Create Pull Request", activeForm: "Creating Pull Request"

Mark each task `in_progress` (via TaskUpdate) when starting the corresponding phase, and `completed` when the phase succeeds. If a phase is skipped (e.g. no changes to commit) or fails, mark it `completed` immediately.

Execution steps (must follow in strict order, no skipping):

---

## Phase 1: Push

@../push/SKILL.md

- If the working tree is clean (no changes at all) and there are no unpushed commits, skip Phase 1 and proceed directly to Phase 2.

---

## Phase 2: Create Pull Request

1) Gather basic information (run in parallel):
- `git branch --show-current` (current branch name, referred to as `HEAD_BRANCH`)
- `git log -1 --oneline` (latest commit, used to determine single-commit scenario)
- Determine the language for PR title, summary, and test plan: use the same language as the commit messages generated in Phase 1 (the commit skill's language rules are the single source of truth). If Phase 1 was skipped (no changes), apply the same rules: default to English unless CLAUDE.md / CLAUDE.local.md explicitly specifies a language for git commit messages. Section headers (## Summary, ## Commits, ## Test Plan) always stay in English, and commit messages are never translated.

2) Determine the target branch (base branch):
- If the user explicitly specified a target branch via $0, use that branch name as the base branch.
- Otherwise, you **must** interactively ask the user:
  1. First call `ToolSearch` with query `select:AskUserQuestion` to fetch the tool schema.
  2. Then call `AskUserQuestion` to ask:
     > What is the target branch for the PR? (Default: `main`, just press Enter)
- Record the user's answer as `BASE_BRANCH`; if the user presses Enter or leaves it blank, set `BASE_BRANCH=main`.

3) Check if a PR already exists:
- Run: `gh pr list --head <HEAD_BRANCH> --json number,url,state`
- If an **open** PR with the same head branch already exists, display the existing PR URL, inform the user that the PR already exists, and stop.

4) Collect the full commit list:
- Run: `git log <BASE_BRANCH>..HEAD --oneline`
- Record all commits (hash + message) for generating the PR body.

5) Generate PR title and body:
- **Language**: Use the language determined in step 7. Section headers (## Summary, ## Commits, ## Test Plan) always stay in English.
- **Title**:
  - If this branch has only 1 commit, use that commit message directly as the title.
  - If there are multiple commits, generate a one-sentence summary title (under 50 characters) based on the branch name and commit list, matching the style of recent commits.
  - If the user appended descriptive text after the command, prioritize incorporating it into the title.
- **Body** (Markdown format):
  ```markdown
  ## Summary
  <3-10 bullet points explaining what this PR does and why.
   Each bullet must answer "what changed" AND "why" — not just list files or repeat commit messages. Focus on the intent and impact of the change.>

  ## Commits
  <List all commits from git log BASE_BRANCH..HEAD, format: `- <hash>: <message>` — keep original commit messages as-is, never translate>

  ## Test Plan
  <Generate test items based on the commit types present in the commit list:
   - `feat` commits → verify new feature's core behavior and edge cases
   - `fix` commits → verify the original bug no longer reproduces, check for regressions
   - `refactor` commits → verify existing behavior is unchanged
   - `docs` commits → verify documentation accuracy and link validity
   - `test` commits → verify tests pass and coverage is adequate
   - `perf` commits → verify performance improvement is measurable
   - `chore`/`ci` commits → verify build/CI pipeline runs correctly
   - Commits without a type prefix → infer intent from message/files and generate appropriate items

   Use `- [ ]` format (unchecked/pending), not `- [x]`. Each item must be specific to the actual changes in this PR — no generic "verify it works" items.>
  ```

6) Execute PR creation:
```bash
gh pr create \
  --title "<PR title>" \
  --base <BASE_BRANCH> \
  --body "$(cat <<'EOF'
<PR body>
EOF
)"
```
- If the `gh` command is not found, prompt the user to install it: `brew install gh && gh auth login`, and stop.

---

## Output

On success, display:
1. All commit messages used in Phase 1 (if there were changes).
2. **PR URL** (prominent format): `PR: <url>`
3. PR title and target branch (`HEAD_BRANCH` -> `BASE_BRANCH`).
4. Final `git status` (confirm the working tree is clean).

On failure, display:
- Which step the failure occurred in.
- Specific error message.
- Next actionable fix command.

---

## Constraints

- Do not modify git config.
- Do not use `--amend`, `--force`, or `--no-verify`.
- Only execute commands directly related to this commit and PR; do not perform additional refactoring or file modifications.
- Do not auto-merge the PR or auto-assign reviewers; after creation, let the user decide next steps.
