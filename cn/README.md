# cn/ — 中文镜像目录

本目录是 `plugins/smart/` 的中文版本镜像，供中文用户阅读参考。

## 用途

- **仅供阅读**：此目录中的文件不会被 Claude Code 加载执行
- **被加载的版本**：`plugins/smart/`（英文版，Claude Code 实际使用）
- **中文版本**：`cn/smart/`（中文翻译，便于中文用户理解插件逻辑）

## 目录结构

```
cn/smart/
├── agents/       # agent 定义（中文翻译版）
├── assets/       # 静态资源（与 EN 版相同）
├── hooks/        # hook 脚本（与 EN 版相同）
└── skills/       # skill 定义（中文翻译版）
```

## 同步说明

修改 `plugins/smart/` 中的英文文件后，需同步更新 `cn/smart/` 中对应的中文版本：

| EN 文件 | 对应 CN 文件 |
|---------|------------|
| `plugins/smart/skills/*/SKILL.md` | `cn/smart/skills/*/SKILL.md` |
| `plugins/smart/agents/*.md` | `cn/smart/agents/*.md` |
