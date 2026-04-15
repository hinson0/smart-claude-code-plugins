---
description: This skill should be used when the user says "hud", "statusline", "install statusline", "setup statusline", "configure statusline", "reset statusline", "restore statusline", or wants to install or restore the smart plugin's statusline.
argument-hint: "[1|2|reset] (1=minimal, 2=full, reset=restore backup, default=2)"
---

Install or restore the smart plugin's statusline (user scope only).

## Determine Action

| Argument    | Action            | Description                                     |
|-------------|-------------------|-------------------------------------------------|
| `1`         | `install-level1`  | Install minimal statusline (session + ctx only) |
| `2`         | `install-level2`  | Install full statusline (all 6 lines)           |
| _(empty)_   | `install-level2`  | Default: install full statusline                |
| `reset`     | `reset`           | Restore previous statusline backup              |

## Paths (user scope only)

- **Source script level 1**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command-level1.sh`
- **Source script level 2**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command.sh`
- **Target script**: `~/.claude/statusline-command.sh`
- **Backup script**: `~/.claude/statusline-command.sh.bak`
- **Settings file**: `~/.claude/settings.json`

## Action: install-level1 / install-level2

1. Read the appropriate source script from the plugin's `assets/` directory:
   - Level 1 → `statusline-command-level1.sh`
   - Level 2 → `statusline-command.sh`
2. If the target script already exists, back it up:
   ```
   cp ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.bak
   ```
3. Copy the source script to the target path:
   ```
   cp <source-script> ~/.claude/statusline-command.sh
   ```
4. Read `~/.claude/settings.json`. Set the `statusLine` field:
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash ~/.claude/statusline-command.sh"
   }
   ```
   Use the Edit tool to modify settings.json — do NOT overwrite the entire file.
5. Report success:
   - Confirm which level was installed
   - Confirm settings.json updated
   - Note backup location if a backup was made
   - Tell user to restart the session to see the new statusline

## Action: reset

1. Check if the backup script exists at `~/.claude/statusline-command.sh.bak`.
   - If not found, report error: "No backup found. Nothing to restore." and stop.
2. Restore from backup:
   ```
   cp ~/.claude/statusline-command.sh.bak ~/.claude/statusline-command.sh
   ```
3. Read `~/.claude/settings.json`. Ensure `statusLine` is set to:
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash ~/.claude/statusline-command.sh"
   }
   ```
   If the file does not exist, report error and stop.
4. Report success — previous statusline restored, restart session to take effect.

## Constraints

- Always use Edit tool for settings.json changes, never overwrite the whole file.
- Do NOT modify any other fields in settings.json.
- Only user scope (`~/.claude/`) is supported.
