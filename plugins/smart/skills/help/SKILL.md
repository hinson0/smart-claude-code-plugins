---
description: This skill should be used when the user says "help", "what can you do", "list skills", "list hooks", "list agents", "show commands", "how to use", or wants an overview of the smart plugin's capabilities.
argument-hint: "[skill|hook|agent] (empty=show all)"
model: sonnet
---

Display a formatted overview of the smart plugin's components by dynamically scanning the plugin directory.

## Determine Category

| Argument           | Category |
| ------------------ | -------- |
| _(empty)_          | `all`    |
| `skill` / `skills` | `skill`  |
| `hook` / `hooks`   | `hook`   |
| `agent` / `agents` | `agent`  |

## Scanning Instructions

### Skills (`skill` or `all`)

1. List all subdirectories under `${CLAUDE_PLUGIN_ROOT}/skills/`.
2. For each subdirectory containing `SKILL.md`, read the YAML frontmatter to extract:
   - **name**: the directory name (used as `/smart:<name>`)
   - **description**: from frontmatter `description` field
   - **argument-hint**: from frontmatter `argument-hint` field (if present)
3. Present as a table:

```
## Skills

| Command | Description | Arguments |
|---------|-------------|-----------|
| /smart:check | Auto-detect CI and run checks | (none) |
| /smart:commit | Commit with semantic grouping | (none) |
| ...     | ...         | ...       |
```

Skip the `help` skill itself from the listing.

### Hooks (`hook` or `all`)

1. Read `${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json`.
2. For each event type (SessionStart, PreToolUse, SessionEnd, etc.), list the hooks configured.
3. For each hook script, read the first comment block (lines starting with `#` after the shebang) to extract a one-line description.
4. Present as a table:

```
## Hooks

| Event | Script | Description |
|-------|--------|-------------|
| SessionStart | greet.sh | Greeting on session start |
| PreToolUse | session-logs.py | Log tool call inputs |
| SessionEnd | goodbye.sh | Farewell on session end |
```

### Agents (`agent` or `all`)

1. List all `.md` files under `${CLAUDE_PLUGIN_ROOT}/agents/`.
2. For each file, read the YAML frontmatter to extract:
   - **name**: from frontmatter `name` field (or filename without extension)
   - **description**: from frontmatter `description` field (first line only)
   - **model**: from frontmatter `model` field
3. Present as a table:

```
## Agents

| Name | Description | Model |
|------|-------------|-------|
| <name> | <description> | <model> |
```

## Output Format

For `all` category, combine all three sections with a header:

```
# Smart Plugin Components

<skills table>

<hooks table>

<agents table>
```

For a specific category, show only that section with a brief intro line.

## Constraints

- Do NOT read entire file contents into context — only frontmatter and leading comments.
- Present information concisely. One-line descriptions only, no full skill body.
- If a file is unreadable or frontmatter is malformed, skip that entry silently and continue scanning.
- Output in the same language as the user's conversation.
