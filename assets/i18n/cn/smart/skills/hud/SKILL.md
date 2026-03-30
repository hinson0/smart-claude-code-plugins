---
description: "配置 smart 风格的 statusline"
argument-hint: "[rm|reset]（空=安装）"
---

安装、移除或恢复 smart 插件的 statusline。

## 确定操作

| 参数 | 操作 |
|------|------|
| _（空）_ | `install` — 安装 smart statusline |
| `rm` | `rm` — 移除 statusline |
| `reset` | `reset` — 恢复用户之前的 statusline |

## 路径

- **源脚本**: `${CLAUDE_PLUGIN_ROOT}/assets/statusline-command.sh`
- **目标脚本（用户级）**: `~/.claude/statusline-command.sh`
- **目标脚本（项目级）**: `.claude/statusline-command.sh`
- **备份脚本**: `~/.claude/statusline-command.sh.bak`（用户级）或 `.claude/statusline-command.sh.bak`（项目级）
- **配置文件（用户级）**: `~/.claude/settings.json`
- **配置文件（项目级）**: `.claude/settings.json`

## 作用域解析

根据作用域解析目标路径：
- **user**: settings = `~/.claude/settings.json`, script = `~/.claude/statusline-command.sh`, backup = `~/.claude/statusline-command.sh.bak`
- **project**: settings = `.claude/settings.json`, script = `.claude/statusline-command.sh`, backup = `.claude/statusline-command.sh.bak`

### `install` — 询问用户

1. 若用户通过参数显式指定了作用域（如 `/smart:hud --project`），使用该作用域。
2. 否则，使用 `AskUserQuestion` 询问：
   > 安装 statusline 到 **user** 作用域（`~/.claude/settings.json`，对所有项目生效）还是 **project** 作用域（`.claude/settings.json`，仅当前项目）？默认 user — 直接回车确认。
3. 若用户直接回车或留空，`SCOPE=user`。

### `rm` / `reset` — 自动检测

检查哪些作用域已安装 smart statusline（判断脚本文件是否存在）：
- `~/.claude/statusline-command.sh` 存在 → user 作用域已安装
- `.claude/statusline-command.sh` 存在 → project 作用域已安装

然后决策：
- **仅一个作用域已安装** → 自动使用该作用域，无需询问。
- **两个作用域都已安装** → 使用 `AskUserQuestion` 询问：
  > statusline 同时存在于 **user** 和 **project** 作用域。从哪个移除？（user / project / both，默认 both）
  若用户直接回车或留空，对**两个**作用域依次执行操作。
- **两个作用域都未安装** → 报告"未找到已安装的 statusline。"并停止。

## 操作: install

1. 从插件的 `assets/` 目录读取源脚本。
2. 如果目标脚本已存在，先备份：
   ```
   cp <目标脚本> <备份脚本>
   ```
3. 将源脚本复制到目标路径。
4. 读取目标配置文件。如果 `statusLine` 字段已存在，记录其当前值。然后设置：
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash <目标脚本绝对路径>"
   }
   ```
   使用 Edit 工具修改 settings.json — 不要覆盖整个文件。
   若为项目级作用域，先确保 `.claude/` 目录存在。
5. 报告成功：
   - 确认脚本已复制及作用域（user/project）
   - 确认 settings.json 已更新
   - 如果创建了备份，说明备份位置
   - 告知用户重启会话以查看新的 statusline

## 操作: rm

1. 读取目标配置文件。
2. 使用 Edit 工具完全移除 settings.json 中的 `statusLine` 字段。
3. 如果目标脚本存在，删除：
   ```
   rm -f <目标脚本>
   ```
4. 不要删除备份文件（用户可能需要稍后恢复）。
5. 报告成功 — statusline 已移除，重启会话生效。

## 操作: reset

1. 检查目标作用域的备份脚本是否存在。
   - 如果不存在，报告错误："未找到备份，无法恢复。"
2. 从备份恢复：
   ```
   cp <备份脚本> <目标脚本>
   ```
3. 读取目标配置文件。确保 `statusLine` 设置为：
   ```json
   "statusLine": {
     "type": "command",
     "command": "bash <目标脚本绝对路径>"
   }
   ```
4. 报告成功 — 已恢复之前的 statusline，重启会话生效。

## 约束

- 修改 settings.json 时始终使用 Edit 工具，不要覆盖整个文件。
- 不要修改 settings.json 中的其他字段。
