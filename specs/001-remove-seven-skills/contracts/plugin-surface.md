# 接口契约：Smart 5.0.0 能力面

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。

## Skill 发现契约

两个宿主安装 Smart 5.0.0 后，只能发现以下七个 skill：

- `/smart:close-issue`
- `/smart:commit`
- `/smart:help`
- `/smart:hud`
- `/smart:learning`
- `/smart:local`
- `/smart:show`

以下旧命令不得再被 Smart 识别为可用 skill：

- `/smart:advance-one-step`
- `/smart:distill`
- `/smart:notebook`
- `/smart:optimize-tokens`
- `/smart:sendshot`
- `/smart:todo`
- `/smart:wfb`

`/smart:help skill` 的动态输出必须与保留清单一致，不得出现目标名称。

## Hook 契约

Claude Code 侧只保留：

- `SessionStart → greet.sh`
- `PreToolUse → session-logs.py`

不得注册 Stop hook，不得加载 `notebook-capture.py`，也不得因普通回复新建 `.smart/notebook.md`。

## 清单与版本契约

- Codex 与 Claude Code 的 marketplace 和插件制品必须继续存在。
- 两份 `plugin.json` 版本必须同时为 `5.0.0`。
- Codex 清单不得再宣传 session knowledge distillation。
- `session utilities` 的通用描述可以保留，因为 HUD、help、learning、local、show 仍受支持。

## 文档契约

- 五份 README 必须删除六项现行功能说明与命令表项；`optimize-tokens` 原本无 README 表项。
- `.claude/CLAUDE.md` 的组件清单和架构原则必须只描述当前能力。
- `assets/demos/explainer-demo.html` 不得保留 notebook 专属演示；另外两个 show 演示继续保留。

## 数据保留契约

升级到 Smart 5.0.0 不会主动删除：

- 既有 `.smart/notebook.md`、`.smart/todo-list.md` 或知识文件；
- `.smart/settings.json` 中的旧配置；
- 用户 shell rc 中以前安装的 sendshot 函数。

这些属于用户数据或仓库外配置。插件仅停止继续提供和触发对应能力。

## 兼容性

本次删除是破坏性变更，不提供兼容别名、迁移命令或弃用过渡期。使用旧命令的自动化需要由用户自行迁移。
