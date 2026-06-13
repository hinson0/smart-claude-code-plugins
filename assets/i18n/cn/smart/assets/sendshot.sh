# 抓取剪贴板图片并通过 scp 上传到远程主机（如 EC2），随后打印并把远程路径
# 回写剪贴板。跨平台：WSL（Windows 剪贴板）和 macOS。配置在运行时从
# ~/.smart/settings.json（.sendshot）读取。
sendshot() {
  local CFG="$HOME/.smart/settings.json"
  if [ ! -f "$CFG" ]; then
    echo "sendshot: 未找到配置 $CFG（运行 /smart:sendshot 进行配置）" >&2
    return 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "sendshot: 需要 jq 但未安装" >&2
    return 1
  fi

  local REMOTE_USER REMOTE_HOST KEY REMOTE_DIR
  REMOTE_USER=$(jq -r '.sendshot.remote_user // "ubuntu"' "$CFG")
  REMOTE_HOST=$(jq -r '.sendshot.remote_host // empty' "$CFG")
  KEY=$(jq -r '.sendshot.key // empty' "$CFG")
  REMOTE_DIR=$(jq -r '.sendshot.remote_dir // "~/tmp_images"' "$CFG")
  # 展开 key 路径开头的 ~（jq 原样返回）。
  KEY="${KEY/#\~/$HOME}"

  if [ -z "$REMOTE_HOST" ] || [ -z "$KEY" ]; then
    echo "sendshot: 必须在 $CFG（.sendshot）中设置 remote_host 和 key" >&2
    return 1
  fi

  local FILE="/tmp/clipboard-$(date +%s).png"

  # --- 按平台把剪贴板图片抓取到 $FILE ---
  if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    # WSL：通过 PowerShell 从 Windows 剪贴板取图。
    local WIN_FILE
    WIN_FILE="$(wslpath -w "$FILE")"
    powershell.exe -NoProfile -Command "
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
\$img = [System.Windows.Forms.Clipboard]::GetImage();
if (\$null -eq \$img) { Write-Error 'Clipboard does not contain an image.'; exit 1; }
\$img.Save('$WIN_FILE', [System.Drawing.Imaging.ImageFormat]::Png);
" || { echo "sendshot: Windows 剪贴板中没有图片" >&2; return 1; }
  elif [ "$(uname -s)" = "Darwin" ]; then
    # macOS：优先 pngpaste；否则退回 osascript 读取 «class PNGf»。
    if command -v pngpaste >/dev/null 2>&1; then
      pngpaste "$FILE" || { echo "sendshot: 剪贴板中没有图片（pngpaste）" >&2; return 1; }
    else
      osascript \
        -e "set theFile to (POSIX file \"$FILE\")" \
        -e 'set png to (the clipboard as «class PNGf»)' \
        -e 'set fileRef to (open for access theFile with write permission)' \
        -e 'write png to fileRef' \
        -e 'close access fileRef' 2>/dev/null \
        || { echo "sendshot: 剪贴板中没有图片（建议安装 pngpaste 更稳定：brew install pngpaste）" >&2; return 1; }
    fi
  else
    echo "sendshot: 不支持的平台（仅支持 WSL 和 macOS）" >&2
    return 1
  fi

  # --- 上传（远程目录自动创建）并报告远程路径 ---
  ssh -i "$KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR" || { echo "sendshot: ssh mkdir 失败" >&2; return 1; }
  scp -i "$KEY" "$FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" || { echo "sendshot: scp 失败" >&2; return 1; }

  local REMOTE_PATH="$REMOTE_DIR/$(basename "$FILE")"
  echo "$REMOTE_PATH"

  # 把远程路径回写剪贴板，方便直接粘贴。
  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$REMOTE_PATH" | clip.exe
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$REMOTE_PATH" | pbcopy
  fi
}
