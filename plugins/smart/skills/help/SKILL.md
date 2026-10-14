---
name: help
description: Show every Smart skill with a brief explanation of its capability and purpose.
disable-model-invocation: true
---

Show a concise guide to every installed Smart skill, including `help` itself.
Always show the full guide; accept and ignore legacy arguments.

Use `${CLAUDE_PLUGIN_ROOT}`, or resolve the plugin root two directories above
this skill's directory. Read frontmatter from `skills/*/SKILL.md` and
`skills/*/*/SKILL.md`. Use each skill's `name` and `description` as the source
of truth; do not maintain a static catalog or invoke the listed skills.

Return one table in the user's language: Category | Command | Capability and purpose.
Use `/smart:<name>` in Claude Code and `$smart:<name>` in Codex.
Group by `git`, `coding`, `docs`, then `utilities`; place root-level `help` last
under Help. Sort skills within each group by name. Translate category labels.
Give each skill one short sentence describing what it does and what it is for.
Omit arguments, implementation details, hooks, and agents.

Read only the metadata needed. If an entry is unreadable or malformed, skip it
and add one brief note identifying the omitted entry; do not claim a complete list.
