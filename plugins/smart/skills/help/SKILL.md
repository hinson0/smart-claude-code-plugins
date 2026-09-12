---
name: help
description: Show Smart skills, hooks, or agents, optionally filtered by component type.
disable-model-invocation: true
argument-hint: "[skill|hook|agent] (empty=show all)"
---

Read the installed plugin's current components; do not maintain a static catalog.

Accept `skill`/`skills`, `hook`/`hooks`, or `agent`/`agents`; no argument shows all.
Use `${CLAUDE_PLUGIN_ROOT}`, or resolve the plugin root from this skill's location.

- Skills: read `skills/*/SKILL.md` frontmatter, excluding `help`. Show command,
  description, and optional `argument-hint`; use `/smart:<name>` in Claude Code
  and `$smart:<name>` in Codex.
- Hooks: read `hooks/hooks.json`. Show event, script, and a one-line description
  from the script's leading comments.
- Agents: read `agents/*.md` frontmatter. Show name (fallback: filename), first
  description line, and model.

Read only the metadata needed, skip unreadable or malformed entries, and present
one compact table per requested category in the conversation's language.
