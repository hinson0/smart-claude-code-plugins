---
description: Use when the user wants to push code to remote (e.g. "push", "push to origin"), or wants the full commit+push pipeline. Not for creating PRs — use smart:pr instead. Includes automatic version bump before push.
argument-hint: No arguments needed. Auto [add+commit+version+push]
model: sonnet
---

You are a repository push pipeline assistant. Goal: complete standard commit, version bump, and push in the current repository.

## Task Tracking

When running standalone (not called from pr pipeline), create the following tasks using TaskCreate before starting:

1. Subject: "Commit changes", activeForm: "Committing changes"
2. Subject: "Version bump", activeForm: "Bumping version"
3. Subject: "Push to remote", activeForm: "Pushing to remote"

Mark each task `in_progress` (via TaskUpdate) when starting the corresponding phase, and `completed` when the phase succeeds. If a phase is skipped (e.g. no changes to commit) or fails, mark it `completed` immediately.

Execution steps (must follow in strict order, no skipping):

---

## Phase 1: Commit

⚠️ The commit skill below contains a CRITICAL semantic analysis step (step 3). Execute it completely — output the file-purpose table and splitting decision before running any git commands.

@../commit/SKILL.md

⚠️ Verify: the commit(s) above must match the grouping from the semantic analysis. If you committed everything in one shot but the analysis showed multiple types/purposes, STOP and redo.

- If there are no changes in the working tree, skip this phase and proceed directly to Phase 2.

**After all commits, run `git status --short` to check for remaining changes.** If there are still modified or untracked files, automatically run the commit phase again for those files — do not pause or ask the user. Repeat until the working tree is clean. The user's intent when running push is to push everything.

---

## Phase 2: Version Bump

@../version/SKILL.md

- Run the version skill to analyze commits since the last version bump and update the detected version file(s) automatically.
- If the version skill reports "no new commits" or the version is unchanged, skip this phase and continue.

---

## Phase 3: Push

### 3.1 Check if origin is configured

Run: `git remote get-url origin 2>/dev/null`

- If configured: skip to 3.3.
- If not configured: continue to 4.2.

### 3.2 Automatically create and link a GitHub remote repository

Execute in order:

1. Confirm `gh` CLI is logged in: `gh auth status`
   - If not logged in, output the prompt "Please run `gh auth login` first", and **stop**.

2. Read the repository name: `basename $(git rev-parse --show-toplevel)`

3. Read the current GitHub username: `gh api user --jq .login`

4. Check if a remote repository with the same name already exists: `gh repo view <username>/<repo-name> 2>/dev/null`
   - If it exists: link directly, skip to step 6.
   - If it does not exist: continue to step 5.

5. Create a GitHub repository (private by default):
   ```
   gh repo create <repo-name> --private --source=. --remote=origin
   ```

6. If it exists but is not linked, manually add the remote:
   ```
   git remote add origin https://github.com/<username>/<repo-name>.git
   ```

### 3.3 Execute push

```
git push -u origin HEAD
```

---

## Output

On success, display:
1. All commit messages actually used in Phase 1 (if there were changes).
2. Version bump result from Phase 2: relay the **exact** skip/result message from the version skill (e.g. "No new commits — version unchanged", or "old → new"). Do NOT rephrase or summarize — use the version skill's own wording.
3. Push target branch and result.
4. Final `git status` (confirm whether the working tree is clean).

On failure, display:
- Which phase and step the failure occurred in.
- Specific error message.
- Next actionable fix command.

---

## Constraints

- Do not modify git config.
- Do not use `--amend`, `--force`, or `--no-verify`.
- Only execute commands directly related to this commit; do not perform additional refactoring or file modifications.
