---
name: clean-branches
description: Delete local and remote branches fully merged into the specified target branch.
disable-model-invocation: true
argument-hint: "[target branch, default: main]"
---

1. Use the supplied target branch without confirmation. If omitted, ask “Delete local and remote branches already merged into main?” in the user's language and wait for explicit confirmation before proceeding. Silence is not confirmation.
2. Read project instructions, resolve the remote, fetch and prune, and verify its target branch exists. If the remote is ambiguous, ask rather than guess.
3. Find local and remote branch tips that are ancestors of the fetched remote target. Check each tip independently; a merged PR or matching branch name is not proof.
4. Exclude the target, `main`, `master`, `dev`, `develop`, the remote default branch, project/host-protected branches, and branch names checked out in any worktree.
5. Show the candidate list, then delete one at a time. Recheck tips, ancestry, and exclusions before deleting; skip changed refs. Use only `git branch -d` locally. Delete remote branches with an explicit expected-tip lease: `git push <remote> --force-with-lease=refs/heads/<branch>:<expected-oid> :refs/heads/<branch>`; never retry a rejected lease without it.
6. Verify deletions and report deleted, skipped, and failed branches with reasons. If no candidates exist, report that and stop.

Do not delete worktrees, discard uncommitted changes, or force-delete local branches. Keep branches whose complete integration cannot be proven, including uncertain squash/rebase merges. Stop if fetching or merge verification fails.
