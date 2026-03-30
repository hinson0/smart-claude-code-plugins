---
description: "Configure claude-hud as your statusline"
argument-hint: "[rm|reset] (empty=install)"
---

Install, remove, or restore the smart plugin's statusline.

## Determine Action

| Argument  | Action    |
|-----------|-----------|
| _(empty)_ | `install` |
| `rm`      | `rm`      |
| `reset`   | `reset`   |

## Paths

- **Source script**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command.sh`
- **Target script (user)**: `~/.claude/statusline-command.sh`
- **Target script (project)**: `.claude/statusline-command.sh`
- **Backup script**: `~/.claude/statusline-command.sh.bak` (user) or `.claude/statusline-command.sh.bak` (project)
- **Settings file (user)**: `~/.claude/settings.json`
- **Settings file (project)**: `.claude/settings.json`

## Scope Resolution

Resolve target paths based on scope:
- **user**: settings = `~/.claude/settings.json`, script = `~/.claude/statusline-command.sh`, backup = `~/.claude/statusline-command.sh.bak`
- **project**: settings = `.claude/settings.json`, script = `.claude/statusline-command.sh`, backup = `.claude/statusline-command.sh.bak`

### For `install` — ask user

1. If the user explicitly specified a scope via the argument (e.g. `/smart:hud --project`), use that scope.
2. Otherwise, use `AskUserQuestion` to ask:
   > Install statusline to **user** scope (`~/.claude/settings.json`, applies to all projects) or **project** scope (`.claude/settings.json`, this project only)? Default: user — press Enter to confirm.
3. If the user presses Enter or leaves blank, `SCOPE=user`.

### For `rm` / `reset` — auto-detect

Check which scopes have the smart statusline installed by testing whether the script file exists:
- `~/.claude/statusline-command.sh` → user scope installed
- `.claude/statusline-command.sh` → project scope installed

Then decide:
- **Only one scope installed** → use that scope automatically, no need to ask.
- **Both scopes installed** → use `AskUserQuestion` to ask:
  > Statusline found in both **user** and **project** scope. Remove from which? (user / project / both, default: both)
  If the user presses Enter or leaves blank, operate on **both** scopes (execute the action on each sequentially).
- **Neither scope installed** → report "No statusline installation found." and stop.

## Action: install

1. Read the source script from the plugin's `assets/` directory.
2. If the target script already exists, back it up:
   ```
   cp <target-script> <backup-script>
   ```
3. Copy the source script to the target path.
4. Read the target settings file. If `statusLine` field exists, note its current value. Then set:
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash <target-script-absolute-path>"
   }
   ```
   Use the Edit tool to modify settings.json — do NOT overwrite the entire file.
   For project scope, ensure `.claude/` directory exists first.
5. Report success:
   - Confirm script copied and scope (user/project)
   - Confirm settings.json updated
   - Note backup location if a backup was made
   - Tell user to restart the session to see the new statusline

## Action: rm

1. Read the target settings file.
2. Remove the `statusLine` field entirely from settings.json using Edit tool.
3. Delete the target script if it exists:
   ```
   rm -f <target-script>
   ```
4. Do NOT delete the backup file (user may want to reset later).
5. Report success — statusline removed, restart session to take effect.

## Action: reset

1. Check if the backup script exists at the target scope.
   - If not, report error: "No backup found. Nothing to restore."
2. Restore from backup:
   ```
   cp <backup-script> <target-script>
   ```
3. Read the target settings file. Ensure `statusLine` is set to:
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash <target-script-absolute-path>"
   }
   ```
4. Report success — previous statusline restored, restart session to take effect.

## Constraints

- Always use Edit tool for settings.json changes, never overwrite the whole file.
- Do NOT modify any other fields in settings.json.
