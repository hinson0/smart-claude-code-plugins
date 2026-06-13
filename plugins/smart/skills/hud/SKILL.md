---
name: hud
description: This skill should be used when the user says "hud", "statusline", "install statusline", "setup statusline", "configure statusline", "reset statusline", "restore statusline", or wants to install or restore the smart plugin's statusline.
argument-hint: "[0|1|2|reset|normal|all] (0/reset=restore backup, 1/normal=minimal, 2/all=full, default=2)"
---

Install or restore the smart plugin's statusline (user scope only).

## Determine Action

Arguments are case-insensitive, and each level accepts either the number or its word alias — `1` and `normal` are equivalent, as are `2`/`all` and `0`/`reset`.

| Argument       | Action           | Description                                     |
| -------------- | ---------------- | ----------------------------------------------- |
| `1` / `normal` | `install-level1` | Install minimal statusline (session + ctx only) |
| `2` / `all`    | `install-level2` | Install full statusline (all 6 lines)           |
| `0` / `reset`  | `reset`          | Restore previous statusline backup              |
| _(empty)_      | `install-level2` | Default: install full statusline                |

## Paths (user scope only)

- **Source script level 1**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command-level1.sh`
- **Source script level 2**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command.sh`
- **Target script**: `~/.claude/statusline-command.sh`
- **Backup script**: `~/.claude/statusline-command.sh.bak`
- **Settings file**: `~/.claude/settings.json`

## Preflight: ensure jq (required, run first for any install)

The statusline parses Claude's JSON with `jq`. If `jq` is missing, almost every field renders blank — this is the #1 cause of "statusline shows only partial info on Linux/WSL" (macOS usually has jq via Homebrew, Linux often does not).

1. Check availability: `command -v jq`. If found, skip to the install action.
2. If missing, auto-install by detecting the platform's package manager (run via Bash):
   - macOS (`uname -s` = Darwin) with `brew`: `brew install jq`
   - Linux with `apt-get`: `sudo apt-get update && sudo apt-get install -y jq`
   - Linux with `dnf`: `sudo dnf install -y jq`
   - Linux with `pacman`: `sudo pacman -S --noconfirm jq`
   - Linux with `apk`: `sudo apk add jq`
3. Re-verify with `command -v jq`. If now present, continue. If install failed (no package manager, no sudo, network error), do NOT abort — warn the user with the exact manual command for their platform and continue (the script itself prints a one-line `jq not found` hint until resolved).

## Action: install-level1 / install-level2

0. Run **Preflight: ensure jq** above first.
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
