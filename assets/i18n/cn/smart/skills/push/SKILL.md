---

description: 当用户想要推送代码到远程仓库时使用（如"push"、"推送"、"push to origin"），或想要执行完整的 check+commit+push 管道。不用于创建
PR——请使用 smart:pr。包含推送前的自动版本升级。
argument-hint: 无需参数。自动执行 [check+add+commit+version+push]

---

启动 **push-pipeline** agent（subagent_type: `smart:push-pipeline`），在后台执行完整管道（check → commit → version
→ push）。

向用户报告："推送管道正在后台运行，完成后会通知你。"

不要在当前对话中执行管道。立即分派给 agent。
