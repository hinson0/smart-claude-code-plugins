---
name: pr
description: Commit current changes and create or update a PR targeting the specified branch.
argument-hint: "[target branch, default: main]"
---

1. Use the supplied branch argument as the target without confirmation. If omitted, ask “Create a PR targeting main by default?” in the user's language and wait for explicit confirmation before proceeding.
2. Read project instructions and Git status; verify the remote target branch exists. If on the target branch or detached HEAD, create a working branch following project naming rules.
3. If there are uncommitted changes, follow [Commit](../commit/SKILL.md), including its host routing, to group and commit them; then resume here.
4. Run project-required checks and review the full diff against the target. Stop on blocking findings or an empty PR diff.
5. Push the working branch and create a PR against the target using the project's PR template and conventions. If an open PR already has the same source repository, source branch, and target, update it instead of creating a duplicate.
6. Return the PR link with a brief change and validation summary.

Do not force-push or merge automatically. Stop and report any failed step.
