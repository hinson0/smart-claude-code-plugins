---
name: commit
description: Analyze, group, and commit current changes without checks, version bumps, pushes, or PRs.
argument-hint: No arguments needed. Group changes by type and independent purpose.
model: haiku
---

## Host routing

- **Claude Code:** the frontmatter pins this turn to `haiku`. Execute the Commit Workflow below directly.
- **Codex commit worker:** if the dispatch prompt explicitly identifies you as the commit worker, skip the rest of this section and execute the Commit Workflow directly. Never delegate again.
- **Codex primary agent:** delegate all workflow steps to exactly one subagent with the complete current context. Identify it as the commit worker and instruct it to read this skill and complete the workflow without delegation. Request model `gpt-5.6-luna` with reasoning effort `low`, then wait and relay its result without redoing its analysis.
- If the Luna spawn fails because that model is unavailable, retry exactly once with the same worker instruction and no model override so the user's configured default subagent model applies. If that retry fails, report the failure and stop; the primary agent must not execute the workflow itself.

## Commit Workflow

1. Read repository instructions, `git status --short`, staged and unstaged diffs, untracked file contents, and recent commit messages. Stop if there are no changes.
2. Split changes by type, then independent purpose. Different types stay separate; shared directories or scopes never justify combining unrelated changes. Split hunks when one file contains multiple purposes.
3. Briefly list each group's commit message and files before committing.
4. Commit groups sequentially. Stage only the current group's explicit paths or hunks; never use bulk staging. Before each commit, verify the staged diff contains only that group, excluding any previously staged changes belonging to other groups. Stop on failure.
5. Report commit hashes, messages, and remaining changes.

Follow project message format and language rules (`AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`), then recent history. Otherwise use English Conventional Commits: `<type>(<scope>): <description>`, optional scope, at most 72 characters.

Only group and commit. Do not edit files, run checks, bump versions, push, create PRs, change Git config, or use `--amend`, `--force`, or `--no-verify`.
