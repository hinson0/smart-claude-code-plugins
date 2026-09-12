---
name: hud
description: 安装 Smart 的简化版或完整版用户级 statusline，或恢复备份。
disable-model-invocation: true
argument-hint: "[0|1|2|reset|normal|all]（0/reset=恢复备份，1/normal=简化版，2/all=完整版，默认=2）"
---

只安装或恢复 Claude Code 用户级 statusline。

参数不区分大小写：`1`/`normal` 安装 session + context 两行；
`2`/`all`（默认）安装全部六行；`0`/`reset` 恢复备份。

## 路径

- 源文件位于 `${CLAUDE_PLUGIN_ROOT}/skills/hud/scripts/`：
  level 1 用 `statusline-command-level1.sh`，level 2 用 `statusline-command.sh`。
- 目标：`~/.claude/statusline-command.sh`
- 备份：`~/.claude/statusline-command.sh.bak`
- 配置：`~/.claude/settings.json`

## 安装

用 `command -v jq` 检查依赖。缺失时通过平台可用的包管理器
（`brew`、`apt-get`、`dnf`、`pacman` 或 `apk`）安装后复查。
若安装失败，给出对应的手动安装命令并继续；解决前脚本会显示 `jq not found` 提示。

目标已存在时先备份，再把所选源脚本复制到目标。配置中只编辑 `statusLine`，保留其他字段：

```json
{"statusLine":{"type":"command","command":"bash ~/.claude/statusline-command.sh"}}
```

## 恢复

备份或配置文件缺失时说明缺失项并停止。把备份复制回目标，设置与上面相同的 `statusLine`。

报告安装级别或恢复结果、配置更新，以及本次创建的备份位置；提醒用户重启会话生效。
