# Capture a clipboard image and upload it to a remote host (e.g. EC2) over scp,
# then print and re-copy the remote path. Cross-platform: WSL (Windows clipboard)
# and macOS. Config is read at runtime from ~/.smart/settings.json (.sendshot).
sendshot() {
  local CFG="$HOME/.smart/settings.json"
  if [ ! -f "$CFG" ]; then
    echo "sendshot: config not found at $CFG (run /smart:sendshot to set it up)" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "sendshot: jq is required but not installed" >&2
    return 1
  fi

  local REMOTE_USER REMOTE_HOST KEY REMOTE_DIR
  REMOTE_USER=$(jq -r '.sendshot.remote_user // "ubuntu"' "$CFG")
  REMOTE_HOST=$(jq -r '.sendshot.remote_host // empty' "$CFG")
  KEY=$(jq -r '.sendshot.key // empty' "$CFG")
  REMOTE_DIR=$(jq -r '.sendshot.remote_dir // "~/tmp_images"' "$CFG")
  # Expand a leading ~ in the key path (jq returns it literally).
  KEY="${KEY/#\~/$HOME}"

  if [ -z "$REMOTE_HOST" ] || [ -z "$KEY" ]; then
    echo "sendshot: remote_host and key must be set in $CFG (.sendshot)" >&2
    return 1
  fi

  local FILE="/tmp/clipboard-$(date +%s).png"

  # --- Capture the clipboard image into $FILE, per platform ---
  if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    # WSL: pull the image from the Windows clipboard via PowerShell.
    local WIN_FILE
    WIN_FILE="$(wslpath -w "$FILE")"
    powershell.exe -NoProfile -Command "
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
\$img = [System.Windows.Forms.Clipboard]::GetImage();
if (\$null -eq \$img) { Write-Error 'Clipboard does not contain an image.'; exit 1; }
\$img.Save('$WIN_FILE', [System.Drawing.Imaging.ImageFormat]::Png);
" || { echo "sendshot: no image in Windows clipboard" >&2; return 1; }
  elif [ "$(uname -s)" = "Darwin" ]; then
    # macOS: prefer pngpaste; fall back to osascript reading «class PNGf».
    if command -v pngpaste >/dev/null 2>&1; then
      pngpaste "$FILE" || { echo "sendshot: no image in clipboard (pngpaste)" >&2; return 1; }
    else
      osascript \
        -e "set theFile to (POSIX file \"$FILE\")" \
        -e 'set png to (the clipboard as «class PNGf»)' \
        -e 'set fileRef to (open for access theFile with write permission)' \
        -e 'write png to fileRef' \
        -e 'close access fileRef' 2>/dev/null \
        || { echo "sendshot: no image in clipboard (install pngpaste for reliability: brew install pngpaste)" >&2; return 1; }
    fi
  else
    echo "sendshot: unsupported platform (only WSL and macOS are supported)" >&2
    return 1
  fi

  # --- Upload (remote dir auto-created) and report the remote path ---
  ssh -i "$KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR" || { echo "sendshot: ssh mkdir failed" >&2; return 1; }
  scp -i "$KEY" "$FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" || { echo "sendshot: scp failed" >&2; return 1; }

  local REMOTE_PATH="$REMOTE_DIR/$(basename "$FILE")"
  echo "$REMOTE_PATH"

  # Copy the remote path back to the clipboard for easy pasting.
  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$REMOTE_PATH" | clip.exe
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$REMOTE_PATH" | pbcopy
  fi
}
