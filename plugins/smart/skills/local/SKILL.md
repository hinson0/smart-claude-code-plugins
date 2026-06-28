---
name: local
description: 'Personal local config for Claude Code sessions. Trigger on /smart:local, or when the user says "create CLAUDE.local.md", "setup local memory", "local preferences", "git-ignore my local claude file", or wants a per-project personal memory file that is never committed. Bootstraps a git-ignored `.claude/CLAUDE.local.md` in the current project, seeded with the personal preferences below, and ensures it is git-ignored. The personal preferences also apply on their own: always reply in Simplified Chinese, store Plan Mode files under `.claude/plans/`.'
argument-hint: "(no args — bootstraps a git-ignored .claude/CLAUDE.local.md)"
---

## Personal Preferences (always apply)

Reply in **Simplified Chinese** throughout (a hard requirement), including:

- All explanations, questions, and summaries Claude Code produces, plus its internal thinking/reasoning process
- Daily communication, technical discussions, code comments, specs, and plans
- Skill (slash-command) output — titles, step descriptions, and prompts — translated into Chinese even when the skill's template is written in English
- Necessary English technical terms may be kept.

Claude Code Plan Mode plan files are stored in the **current project directory**:
`.claude/plans/YYYY_MM_DD_HH_mm-<name>.md`

## Action: bootstrap a git-ignored `.claude/CLAUDE.local.md`

When this skill is invoked explicitly (`/smart:local`), set up a per-project personal memory file that stays out of version control. The point is a place for machine- or person-specific notes (the preferences above, local paths, scratch context) that should never reach a shared commit.

1. **Resolve the project root.** Use `git rev-parse --show-toplevel`; if not in a git repo, fall back to the current working directory.
2. **Ensure the directory.** `mkdir -p <root>/.claude`.
3. **Create the file if absent.** If `<root>/.claude/CLAUDE.local.md` does not exist, write it from the template below. If it already exists, leave it untouched so the user's own notes are never clobbered — just report that it was already there.
4. **Ensure it is git-ignored** (only meaningful inside a git repo). Check with `git check-ignore -q .claude/CLAUDE.local.md`. If that command fails (the file is not yet ignored), append the line `.claude/CLAUDE.local.md` to `<root>/.gitignore` (create `.gitignore` if absent). This is idempotent — never add a duplicate line, and never rewrite unrelated `.gitignore` content; append a single line with the Edit/Write tool.
5. **Report** the absolute path of the file (created vs. already present) and whether the ignore rule was added or already in effect. Remind the user that `.claude/CLAUDE.local.md` is personal and will not be committed.

### Template for a fresh `.claude/CLAUDE.local.md`

```markdown
# CLAUDE.local.md — personal, git-ignored

Per-project notes for this machine/person. Not committed.

## Language
- Reply in Simplified Chinese (hard requirement); keep necessary English technical terms.
- Translate skill (slash-command) output — titles, steps, prompts — into Chinese even when the template is English.
- Plan Mode files: `.claude/plans/YYYY_MM_DD_HH_mm-<name>.md`

## Local context
<!-- local paths, credentials location, scratch notes, etc. -->
```

## Constraints

- Honor the exact path the user asked for: `.claude/CLAUDE.local.md` (under `.claude/`, not the project root).
- Never overwrite an existing `.claude/CLAUDE.local.md`; treat the user's content as authoritative.
- Always use the Edit/Write tool for `.gitignore`; append a single line, never clobber the whole file.
- Output in the same language as the user's conversation.
