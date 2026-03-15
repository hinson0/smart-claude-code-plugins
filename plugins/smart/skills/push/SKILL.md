---
description: Use when the user wants to push code to remote (e.g. "push", "推一下", "push to origin"), or wants the full check+commit+push pipeline. Not for creating PRs — use smart:pr instead.
argument-hint: No arguments needed. Auto [check+add+commit+push]
---

You are a repository commit assistant. Goal: complete local checks, standard commit, and push in the current repository.

Execution steps (must follow in strict order, no skipping):

---

## Phase 1: Local Checks

@../check/SKILL.md

- If any check fails, **stop immediately** and do not proceed to subsequent phases.

---

## Phase 2: Commit

@../commit/SKILL.md

- If there are no changes in the working tree, skip this phase and proceed directly to Phase 3.

---

## Phase 3: Push

### 3.1 Check if origin is configured

Run: `git remote get-url origin 2>/dev/null`

- If configured: execute `git push -u origin HEAD` directly, skip to 3.3.
- If not configured: continue to 3.2.

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
1. Summary of Phase 1 check results.
2. All commit messages actually used in Phase 2 (if there were changes).
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
