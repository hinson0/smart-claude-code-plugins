---
name: sendshot
description: This skill should be used when the user says "sendshot", "install sendshot", "setup sendshot", "send screenshot to ec2", "upload clipboard image", "send clipboard to remote", or wants to install the cross-platform sendshot shell function that uploads a clipboard image to a remote host.
argument-hint: "[install|config|uninstall] (empty=config then install)"
---

Install a cross-platform `sendshot` shell function that captures the clipboard image, uploads it to a remote host (e.g. EC2) over `scp`, and prints + re-copies the remote path. Config lives in the global `~/.smart/settings.json` and is read at runtime, so changing the host or key never requires reinstalling.

Supported platforms: **WSL/Ubuntu** (reads the Windows clipboard via PowerShell) and **macOS** (reads the clipboard via `pngpaste`, falling back to `osascript`). Any other platform is rejected at runtime.

Under **zsh**, the function block also binds **`Ctrl+G`** to a ZLE widget (`sendshot_insert_widget`) so the user can fire sendshot from any prompt without typing the command. The widget is guarded behind a `$ZSH_VERSION` check, so it stays inert when installed into bash.

## Determine Action

| Argument    | Action                  | Description                                           |
| ----------- | ----------------------- | ----------------------------------------------------- |
| `config`    | `config`                | Only write/update the `sendshot` config, no install   |
| `uninstall` | `uninstall`             | Remove the function block from the shell rc           |
| `install`   | `install`               | Only install the function (config must already exist) |
| _(empty)_   | `config` then `install` | Default: configure, then install                      |

## Paths

- **Function source**: `${CLAUDE_PLUGIN_ROOT}/skills/sendshot/scripts/sendshot.sh`
- **Config file**: `~/.smart/settings.json` (global scope only — `sendshot` is a global shell function)
- **Shell rc**: `~/.zshrc` for zsh, `~/.bashrc` for bash (detect from `$SHELL`; default to `~/.zshrc`)
- **Marker block** wrapping the function in the rc:
  ```
  # >>> smart sendshot >>>
  ...function body...
  # <<< smart sendshot <<<
  ```

## Action: config

1. Read `~/.smart/settings.json` (create the file with `{}` if absent). Look at the `sendshot` object.
2. For each required field, reuse the existing value if present; otherwise ask the user (one concise prompt, show the default):
   - `remote_host` — **required**, the EC2 public IP or hostname (e.g. `35.74.250.39`)
   - `key` — **required**, the SSH key path (e.g. `~/.ssh/WitMani_Agent.pem`); a leading `~` is allowed
   - `remote_user` — default `ubuntu`
   - `remote_dir` — default `~/tmp_images` (the function auto-creates it via `mkdir -p`, so the user does NOT need to pre-create it on the remote host)
3. Merge into `~/.smart/settings.json` under the `sendshot` key with the Edit tool (preserve other keys — never overwrite the whole file):
   ```json
   {
     "sendshot": {
       "remote_user": "ubuntu",
       "remote_host": "35.74.250.39",
       "key": "~/.ssh/WitMani_Agent.pem",
       "remote_dir": "~/tmp_images"
     }
   }
   ```

## Preflight: ensure jq (required, run before install)

The function reads its config with `jq`. Mirror the `hud` skill's jq handling:

1. `command -v jq` — if found, continue.
2. If missing, auto-install via the platform package manager: macOS+brew `brew install jq`; Linux `apt-get`/`dnf`/`pacman`/`apk`.
3. Re-verify. If install fails, do NOT abort — warn with the manual command and continue (the function prints a `jq is required` hint until resolved).

On **macOS only**, also recommend `pngpaste` for reliable clipboard image reads: if `command -v pngpaste` is missing and `brew` exists, offer `brew install pngpaste`. The `osascript` fallback works without it, so this is a recommendation, not a hard requirement.

## Action: install

0. Run **Preflight: ensure jq** above first.
1. Read the function source from `${CLAUDE_PLUGIN_ROOT}/skills/sendshot/scripts/sendshot.sh`.
2. Detect the shell rc: zsh → `~/.zshrc`, bash → `~/.bashrc` (from `$SHELL`); default `~/.zshrc`. Create the rc if absent.
3. Read the rc. If a `# >>> smart sendshot >>>` … `# <<< smart sendshot <<<` block already exists, replace it (idempotent reinstall). Otherwise append a new block at the end. The block is the marker lines wrapping the function source verbatim. Use the Edit tool to replace an existing block; use Edit/Write to append a new one — never clobber unrelated rc content.
4. Report success:
   - Confirm the function was installed into which rc file
   - Tell the user to run `source <rc>` (or open a new shell) to activate it
   - Remind them config lives in `~/.smart/settings.json` → editing it takes effect immediately, no reinstall
   - One-line usage: copy an image to the clipboard, run `sendshot` (or press **`Ctrl+G`** in zsh), the remote path is printed and copied to the clipboard

## Action: uninstall

1. Read the shell rc. Remove the `# >>> smart sendshot >>>` … `# <<< smart sendshot <<<` block (and the blank line around it) with the Edit tool.
2. If no block is found, report "sendshot not installed in <rc>." and stop.
3. Report success and tell the user to open a new shell. Note that the config in `~/.smart/settings.json` is left untouched (remove it manually if desired).

## Constraints

- Config is **global only** (`~/.smart/settings.json`) — do not write project-level `.smart/settings.json` for sendshot.
- Always use the Edit tool for `settings.json` and rc changes; never overwrite the whole file.
- Do NOT bake config values into the rc — the function reads them at runtime from `~/.smart/settings.json`.
- Install the function verbatim from `skills/sendshot/scripts/sendshot.sh`; do not inline a hand-edited copy.
- If the platform is neither WSL nor macOS, still install (the function self-guards), but warn the user it only runs on WSL/macOS.
- Output in the same language as the user's conversation.
