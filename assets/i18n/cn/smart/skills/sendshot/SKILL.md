---
name: sendshot
description: 当用户说"sendshot"、"安装 sendshot"、"配置 sendshot"、"把截图发到 ec2"、"上传剪贴板图片"、"把剪贴板发到远程"，或想安装那个把剪贴板图片上传到远程主机的跨平台 sendshot shell 函数时，使用本技能。
argument-hint: "[install|config|uninstall]（空=先配置再安装）"
---

安装一个跨平台的 `sendshot` shell 函数：抓取剪贴板图片，通过 `scp` 上传到远程主机（如 EC2），随后打印并把远程路径回写剪贴板。配置位于全局 `~/.smart/settings.json`，运行时读取，所以更换主机或密钥都无需重新安装。

支持平台：**WSL/Ubuntu**（通过 PowerShell 读 Windows 剪贴板）和 **macOS**（用 `pngpaste` 读剪贴板，退回 `osascript`）。其他平台在运行时被拒绝。

## 判定动作

| 参数        | 动作                  | 说明                                |
| ----------- | --------------------- | ----------------------------------- |
| `config`    | `config`              | 仅写入/更新 `sendshot` 配置，不安装 |
| `uninstall` | `uninstall`           | 从 shell rc 中移除函数块            |
| `install`   | `install`             | 仅安装函数（配置须已存在）          |
| _(空)_      | `config` 再 `install` | 默认：先配置，再安装                |

## 路径

- **函数源文件**：`${CLAUDE_PLUGIN_ROOT}/skills/sendshot/scripts/sendshot.sh`
- **配置文件**：`~/.smart/settings.json`（仅全局——`sendshot` 是全局 shell 函数）
- **Shell rc**：zsh 用 `~/.zshrc`，bash 用 `~/.bashrc`（从 `$SHELL` 检测；默认 `~/.zshrc`）
- **标记块**（在 rc 中包裹函数）：
  ```
  # >>> smart sendshot >>>
  ...函数体...
  # <<< smart sendshot <<<
  ```

## 动作：config

1. 读取 `~/.smart/settings.json`（不存在则创建为 `{}`）。查看 `sendshot` 对象。
2. 每个必填字段，已有值则复用；否则向用户询问（一句简洁提示，显示默认值）：
   - `remote_host` —— **必填**，EC2 公网 IP 或主机名（如 `35.74.250.39`）
   - `key` —— **必填**，SSH 密钥路径（如 `~/.ssh/WitMani_Agent.pem`）；允许开头的 `~`
   - `remote_user` —— 默认 `ubuntu`
   - `remote_dir` —— 默认 `~/tmp_images`（函数用 `mkdir -p` 自动创建，用户**无需**在远程预先建好）
3. 用 Edit 工具把配置合并进 `~/.smart/settings.json` 的 `sendshot` 键（保留其他键——绝不整体覆盖文件）：
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

## 前置检查：确保 jq（必需，安装前先跑）

函数用 `jq` 读配置。沿用 `hud` 技能对 jq 的处理：

1. `command -v jq` —— 找到则继续。
2. 缺失则按平台包管理器自动安装：macOS+brew 用 `brew install jq`；Linux 用 `apt-get`/`dnf`/`pacman`/`apk`。
3. 重新验证。安装失败时**不要**中止——给出手动命令并继续（函数会持续提示 `需要 jq` 直到解决）。

**仅 macOS**：另外建议安装 `pngpaste` 以更稳定地读剪贴板图片：若 `command -v pngpaste` 缺失且存在 `brew`，建议 `brew install pngpaste`。`osascript` 退路无需它即可工作，因此这是建议而非硬性要求。

## 动作：install

0. 先跑上面的**前置检查：确保 jq**。
1. 从 `${CLAUDE_PLUGIN_ROOT}/skills/sendshot/scripts/sendshot.sh` 读取函数源文件。
2. 检测 shell rc：zsh → `~/.zshrc`，bash → `~/.bashrc`（来自 `$SHELL`）；默认 `~/.zshrc`。不存在则创建。
3. 读取 rc。若已存在 `# >>> smart sendshot >>>` … `# <<< smart sendshot <<<` 块，则替换它（幂等重装）；否则在文件末尾追加新块。块即标记行包裹函数源文件原文。用 Edit 工具替换已有块；用 Edit/Write 追加新块——绝不破坏 rc 的其他内容。
4. 报告成功：
   - 确认函数安装进了哪个 rc 文件
   - 提示用户运行 `source <rc>`（或开新 shell）以激活
   - 提醒配置在 `~/.smart/settings.json` —— 编辑即时生效，无需重装
   - 一句用法：复制一张图片到剪贴板，运行 `sendshot`，远程路径会被打印并复制到剪贴板

## 动作：uninstall

1. 读取 shell rc。用 Edit 工具移除 `# >>> smart sendshot >>>` … `# <<< smart sendshot <<<` 块（及周围空行）。
2. 未找到块则报告"sendshot 未安装在 <rc>。"并停止。
3. 报告成功并提示用户开新 shell。说明 `~/.smart/settings.json` 中的配置保持不动（如需可手动删除）。

## 约束

- 配置**仅全局**（`~/.smart/settings.json`）—— 不要为 sendshot 写项目级 `.smart/settings.json`。
- `settings.json` 和 rc 的改动一律用 Edit 工具；绝不整体覆盖文件。
- 不要把配置值烤进 rc —— 函数在运行时从 `~/.smart/settings.json` 读取。
- 从 `skills/sendshot/scripts/sendshot.sh` 原样安装函数；不要内联手改的副本。
- 若平台既非 WSL 也非 macOS，仍可安装（函数自带守卫），但提醒用户它只在 WSL/macOS 上运行。
- 输出语言与用户对话语言一致。
