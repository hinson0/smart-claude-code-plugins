# 抓取剪贴板图片并通过 scp 上传到远程主机（如 EC2），随后打印并把远程路径
# 回写剪贴板。跨平台：WSL（Windows 剪贴板）和 macOS。配置在运行时从
# ~/.smart/settings.json（.sendshot）读取。zsh 下 Ctrl+G 可在任意提示符处
# 直接触发，无需输入命令（见文件底部的 widget）。
sendshot() {
  local CFG="$HOME/.smart/settings.json"
  if [ ! -f "$CFG" ]; then
    echo "sendshot: 未找到配置 $CFG（运行 /smart:sendshot 进行配置）" >&2
    return 1
  fi

  # 定位 jq：优先已知安装位置，再退回 PATH（ZLE widget 运行时 PATH 可能被
  # 精简，裸 `jq` 未必可解析）。
  local JQ=""
  if [ -x "/usr/bin/jq" ]; then
    JQ="/usr/bin/jq"
  elif [ -x "$HOME/.local/bin/jq" ]; then
    JQ="$HOME/.local/bin/jq"
  elif command -v jq >/dev/null 2>&1; then
    JQ="$(command -v jq)"
  else
    echo "sendshot: 需要 jq 但未找到" >&2
    echo "sendshot: 已检查 /usr/bin/jq、$HOME/.local/bin/jq 和 PATH" >&2
    return 1
  fi

  local REMOTE_USER REMOTE_HOST KEY REMOTE_DIR
  REMOTE_USER=$("$JQ" -r '.sendshot.remote_user // "ubuntu"' "$CFG")
  REMOTE_HOST=$("$JQ" -r '.sendshot.remote_host // empty' "$CFG")
  KEY=$("$JQ" -r '.sendshot.key // empty' "$CFG")
  REMOTE_DIR=$("$JQ" -r '.sendshot.remote_dir // "~/tmp_images"' "$CFG")
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
" >/dev/null 2>&1 || { echo "sendshot: Windows 剪贴板中没有图片" >&2; return 1; }
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
  ssh -i "$KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR" >/dev/null || { echo "sendshot: ssh mkdir 失败" >&2; return 1; }
  scp -q -i "$KEY" "$FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/" || { echo "sendshot: scp 失败" >&2; return 1; }

  local REMOTE_PATH="$REMOTE_DIR/$(basename "$FILE")"

  # 把远程路径回写剪贴板，方便直接粘贴。
  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$REMOTE_PATH" | clip.exe
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$REMOTE_PATH" | pbcopy
  fi

  printf '%s\n' "$REMOTE_PATH"
}

# 仅 zsh：把 Ctrl+G 绑定为在任意提示符处直接运行 sendshot，无需输入命令。
# 该守卫使其在 bash 下保持惰性（bash 没有 zle/bindkey）。远程路径照常被
# 打印并复制到剪贴板。
if [ -n "$ZSH_VERSION" ]; then
  sendshot_insert_widget() {
    local output
    zle -I
    print -r -- ""
    print -r -- "sendshot: uploading clipboard image..."
    output="$(sendshot)" || {
      print -r -- "sendshot: failed"
      zle redisplay
      return 1
    }
    print -r -- "sendshot: uploaded -> ${output##*$'\n'}"
    print -r -- "sendshot: copied to clipboard"
    zle redisplay
  }
  zle -N sendshot_insert_widget
  bindkey '^G' sendshot_insert_widget
fi
