---
name: local
description: Create a git-ignored .claude/CLAUDE.local.md for per-project personal preferences.
disable-model-invocation: true
argument-hint: "(no args — bootstraps a git-ignored .claude/CLAUDE.local.md)"
---

Create a personal preferences file at `.claude/CLAUDE.local.md`.

1. Resolve the root with `git rev-parse --show-toplevel`, falling back to the
   working directory outside Git.
2. Create `.claude/` and the file only if absent. Never overwrite existing notes.
3. In a Git repository, check `git check-ignore -q .claude/CLAUDE.local.md`.
   If not ignored, append `.claude/CLAUDE.local.md` to the root `.gitignore`
   without duplicating the entry or changing other content.
4. Report the absolute path, whether it was created, and its ignore status.

Use this template for a new file; existing user preferences remain authoritative:

```markdown
# Personal project notes

## Preferences
- Reply in Simplified Chinese, including skill output; keep necessary English terms.
- Plan Mode files: `.claude/plans/YYYY_MM_DD_HH_mm-<name>.md`

## Local context
```
