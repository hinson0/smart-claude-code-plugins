---
name: commit
description: Analyze, group, and commit current changes without checks, version bumps, pushes, or PRs.
argument-hint: No arguments needed. Group changes by type and independent purpose.
model: haiku
---

1. **Model:** Claude Code runs here on `haiku`. A Codex primary agent spawns one low-reasoning worker on the latest Luna model to run steps 2–5 without delegating, then relays its result.
2. **Read** repository instructions, `git status --short`, staged and unstaged diffs, untracked file contents, and recent commit messages; with no changes, stop.
3. **Group** by type (hard boundary), then independent purpose (soft boundary), splitting hunks when one file mixes purposes. Write each message per `AGENTS.md`, `CLAUDE.md`, `CLAUDE.local.md`, then recent history, else English `<type>(<scope>): <description>` within 72 characters. List each group's message and files.
4. **Commit** groups one at a time: stage only that group's explicit paths or hunks, confirm the staged diff holds exactly that group, commit, and stop on the first failure. Report hashes, messages, and remaining changes.
5. **Boundary:** only group and commit. Files, checks, versions, remotes, PRs, and Git config stay untouched; every commit is new (no `--amend`, `--force`, or `--no-verify`).
