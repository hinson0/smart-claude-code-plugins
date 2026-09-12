---
name: hud
description: Install Smart's minimal or full user statusline, or restore its backup.
disable-model-invocation: true
argument-hint: "[0|1|2|reset|normal|all] (0/reset=restore backup, 1/normal=minimal, 2/all=full, default=2)"
---

Install or restore the Claude Code statusline in user scope only.

Arguments are case-insensitive: `1`/`normal` installs session + context;
`2`/`all` (default) installs all six lines; `0`/`reset` restores the backup.

## Paths

- Sources under `${CLAUDE_PLUGIN_ROOT}/skills/hud/scripts/`:
  `statusline-command-level1.sh` for level 1, `statusline-command.sh` for level 2.
- Target: `~/.claude/statusline-command.sh`
- Backup: `~/.claude/statusline-command.sh.bak`
- Settings: `~/.claude/settings.json`

## Install

Check `command -v jq`. If missing, install it with the available platform package
manager (`brew`, `apt-get`, `dnf`, `pacman`, or `apk`) and check again. If installation
fails, give the appropriate manual command and continue; the script displays a
`jq not found` hint until resolved.

Back up an existing target to the backup path, then copy the selected source to
the target. Edit only `statusLine` in settings, preserving all other fields:

```json
{"statusLine":{"type":"command","command":"bash ~/.claude/statusline-command.sh"}}
```

## Reset

If the backup or settings file is absent, report the missing file and stop.
Copy the backup to the target and set the same `statusLine` field above.

Report the installed level or restoration, settings update, and backup location
if created. Tell the user to restart the session to apply it.
