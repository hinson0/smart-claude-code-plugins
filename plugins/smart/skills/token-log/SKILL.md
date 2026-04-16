---
description: This skill should be used when the user says "capture context", "save context", "context snapshot", "token-log", "token log","context", "context usage", "statusline", "statusline usage", "dump statusline", "save session info", "export session", or wants to export the current Claude Code session's statusline data as an annotated JSONC snapshot to .claude/token-logs/. Invoked explicitly via /smart:token-log.
argument-hint: No arguments needed. Captures current statusline data snapshot.
model: haiku
---

# Token Log

Capture the current Claude Code session's statusline data and save it as an annotated JSONC file with descriptive comments.

## Prerequisites

The statusline script must be configured and running. It saves raw JSON to `~/.claude/.statusline-latest.json` on each update. If this file does not exist, inform the user that the statusline is not configured or has not run yet.

## Steps

### 1) Read the statusline data

Read `~/.claude/.statusline-latest.json`. If the file is missing, empty, or contains malformed JSON (e.g., interrupted write), report the error clearly and stop.

### 2) Determine output language

Use the current conversation language for JSONC comments:

- If the user communicates in Chinese → Chinese comments
- If the user communicates in English → English comments
- Otherwise, follow the user's language

Consult `references/field-descriptions.md` for the comment text in each language.

### 3) Format as annotated JSONC

Construct the JSONC file with this structure:

```
// Claude Code Statusline JSON — captured {ISO_8601_TIMESTAMP}
// Ref: https://docs.claude.dev/docs/statusline#available-data
{
  "field": value, // description in user's language
  ...
}
```

Rules:

- Add the capture timestamp header (current UTC time in ISO 8601)
- Add a descriptive comment after each field using the descriptions from `references/field-descriptions.md`
- For nested objects, add a comment on the opening brace line describing the group
- Preserve the exact JSON values from the source data — do not modify, round, or omit any fields
- Include all fields present in the source JSON, even conditional ones (vim, agent, worktree)
- Omit fields that are absent or null in the source data

### 4) Write the file

1. Extract `session_id` from the JSON data
2. Determine the project root directory (use the current working directory)
3. Create the output directory if needed: `{project_root}/.claude/token-logs/`
4. Write to: `{project_root}/.claude/token-logs/{session_id}.jsonc`
5. Overwrite if the file already exists (same session, latest snapshot wins)
6. If `.claude/token-logs/` is not already in the project's `.gitignore`, remind the user to add it — these are personal session snapshots, not shared project data

### 5) Report

Display a brief confirmation:

- Output file path
- Session ID
- Capture timestamp

## Additional Resources

### Reference Files

- **`references/field-descriptions.md`** — Bilingual (EN/CN) descriptions for every statusline JSON field. Read this when formatting the JSONC comments.
