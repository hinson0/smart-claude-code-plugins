---
name: code-simplifier
description: 由一个全新上下文 worker 简化明确范围内的近期代码，同时保持可观察行为不变。
disable-model-invocation: true
argument-hint: "[路径或 diff]（空=工作区代码改动）"
license: Apache-2.0
---

<!-- 改编自 Anthropic 的 code-simplifier agent，并已作修改；采用 Apache-2.0 许可。详见 LICENSE。 -->

把完整流程（包括范围发现）交给一个全新上下文 worker。始终派发，即使范围为空或含糊；只有 worker 可以返回 `blocked`。主 agent 不检查仓库、不读取代码、不编辑、不暂存，也不运行检查。

- **Claude Code：** 仅在前台调用一次 `smart:code-simplifier-worker`。
- **Codex：** 只派生一个子 agent，将 `fork_turns` 设置为 `none`，不覆盖模型或 reasoning。指示它完整读取 `<本-skill-目录>/references/worker.md`，在当前 checkout 执行，不再委派。

完整传递用户请求和参数，保留路径、符号、约束、排除项及空范围。串行运行，等待并转述最终结果。worker 无法启动或完成时报告失败并停止；主 agent 不得接管，也不重复其分析或检查。
