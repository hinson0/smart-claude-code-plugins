---

description: 当用户想要创建 Pull Request 时使用（如"创建 PR"、"开 PR"、"create PR"、"open PR"、"submit PR"、"merge request"），或想要执行完整的
check+commit+push+PR 管道。包含推送和版本升级——无需先推送。
argument-hint: "[base-branch]（可选）PR 的目标分支，默认为 main。自动执行 [check+add+commit+version+push+pr]"

---

启动 **pr-pipeline** agent（subagent_type: `smart:pr-pipeline`），在后台执行完整管道（check → commit → version →
push → PR）。

若用户通过 `$ARGUMENTS` 提供了 base branch 参数，在 agent prompt 中包含："Base branch: <参数>"。否则 agent 默认使用 `main`。

向用户报告："PR 管道正在后台运行，完成后会通知你。"

不要在当前对话中执行管道。立即分派给 agent。
