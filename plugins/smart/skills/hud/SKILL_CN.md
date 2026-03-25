---
description: "配置 smart 风格的 statusline"
argument-hint: "[rm|rewind]（空=安装）"
allowed-tools: [Agent]
---

根据用户参数启动 `cp-my-statusline` agent 来处理 statusline 请求。

参数对应操作：

| 参数 | 操作 |
|------|------|
| _（空）_ | `install` — 安装 smart statusline |
| `rm` | `rm` — 移除 statusline |
| `rewind` | `rewind` — 恢复用户之前的 statusline |

启动 agent 并将操作指令传入 prompt，等待完成后把结果转述给用户。不要自己执行任何文件操作。
