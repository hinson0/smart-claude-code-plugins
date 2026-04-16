---
description: 当用户说"hud"、"statusline"、"安装 statusline"、"配置 statusline"、"恢复 statusline"，或需要安装、恢复 smart 插件的 statusline 时使用此技能。
argument-hint: "[1|2|reset]（1=简化版，2=完整版，reset=恢复备份，默认=2）"
model: sonnet
---

安装或恢复 smart 插件的 statusline（仅支持 user 级别）。

## 确定操作

| 参数     | 操作             | 说明                                               |
| -------- | ---------------- | -------------------------------------------------- |
| `1`      | `install-level1` | 安装简化版 statusline（只显示 session + ctx 两行） |
| `2`      | `install-level2` | 安装完整版 statusline（全部 6 行）                 |
| _（空）_ | `install-level2` | 默认：安装完整版                                   |
| `reset`  | `reset`          | 恢复之前的 statusline 备份                         |

## 路径（仅 user 级别）

- **源脚本 level 1**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command-level1.sh`
- **源脚本 level 2**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command.sh`
- **目标脚本**: `~/.claude/statusline-command.sh`
- **备份脚本**: `~/.claude/statusline-command.sh.bak`
- **配置文件**: `~/.claude/settings.json`

## 操作: install-level1 / install-level2

1. 从插件 `assets/` 目录读取对应源脚本：
   - Level 1 → `statusline-command-level1.sh`
   - Level 2 → `statusline-command.sh`
2. 如果目标脚本已存在，先备份：
   ```
   cp ~/.claude/statusline-command.sh ~/.claude/statusline-command.sh.bak
   ```
3. 将源脚本复制到目标路径：
   ```
   cp <源脚本> ~/.claude/statusline-command.sh
   ```
4. 读取 `~/.claude/settings.json`，设置 `statusLine` 字段：
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash ~/.claude/statusline-command.sh"
   }
   ```
   使用 Edit 工具修改 settings.json — 不要覆盖整个文件。
5. 报告成功：
   - 确认安装的是哪个 level
   - 确认 settings.json 已更新
   - 如果创建了备份，说明备份位置
   - 告知用户重启会话以查看新的 statusline

## 操作: reset

1. 检查备份脚本 `~/.claude/statusline-command.sh.bak` 是否存在。
   - 如果不存在，报告错误："未找到备份，无法恢复。"并停止。
2. 从备份恢复：
   ```
   cp ~/.claude/statusline-command.sh.bak ~/.claude/statusline-command.sh
   ```
3. 读取 `~/.claude/settings.json`，确保 `statusLine` 设置为：
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash ~/.claude/statusline-command.sh"
   }
   ```
   若文件不存在，报告错误并停止。
4. 报告成功 — 已恢复之前的 statusline，重启会话生效。

## 约束

- 修改 settings.json 时始终使用 Edit 工具，不要覆盖整个文件。
- 不要修改 settings.json 中的其他字段。
- 仅支持 user 级别（`~/.claude/`）。
