# 数据模型：插件能力删除状态

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。

本功能不引入业务数据或持久化模型；以下模型用于约束仓库组件及其删除状态。

## 实体 1：Skill 组件

**字段**：

- `name`：skill 目录名与公开命令名。
- `runtime_source`：宿主加载的 `SKILL.md`。
- `translation`：同目录 `CN.md`。
- `support_assets`：可选 references、scripts。
- `state`：`retained` 或 `removed`。

**验证规则**：

- `removed` 组件的目录及全部支撑资产必须不存在。
- `retained` 组件必须同时存在 `SKILL.md` 和 `CN.md`。
- `retained` 的宿主加载文件必须通过英文运行时边界检查。

**状态迁移**：

- `advance-one-step`、`distill`、`notebook`、`optimize-tokens`、`sendshot`、`wfb`、`todo`：`retained → removed`。
- `close-issue`、`commit`、`help`、`hud`、`learning`、`local`、`show`：保持 `retained`。

## 实体 2：Hook 组件

**字段**：

- `event`：宿主事件名。
- `script`：注册执行脚本。
- `documentation`：hooks 中文说明。
- `state`：`retained` 或 `removed`。

**验证规则**：

- `Stop → notebook-capture.py` 的注册、脚本和说明必须同时删除。
- `SessionStart → greet.sh` 与 `PreToolUse → session-logs.py` 必须保持不变。

**状态迁移**：

- notebook Stop hook：`registered → removed`。
- 其他两个 hook：保持 `registered`。

## 实体 3：宿主清单

**字段**：

- `host`：Codex 或 Claude Code。
- `marketplace_manifest`：宿主 marketplace 清单。
- `plugin_manifest`：宿主插件清单。
- `version`：插件 SemVer。
- `description`：用户可见能力概括。
- `skill_root`：动态发现目录。

**验证规则**：

- 两个宿主制品必须继续存在。
- 两份插件版本必须完全相同且为 `5.0.0`。
- 描述不得宣传已删除能力。
- skill 根目录继续指向保留能力所在位置。

## 实体 4：用户文档

**字段**：

- `locale`：English、简体中文、繁體中文、한국어、日本語。
- `feature_entries`：功能说明列表。
- `command_entries`：命令表。

**验证规则**：

- 五种语言不得把七个目标 skill 描述为当前能力。
- 五种语言必须保留相同的剩余功能范围。

## 实体 5：用户本地状态

**字段**：

- `smart_files`：用户项目或全局 `.smart/` 下的既有文件。
- `shell_configuration`：可能已安装的 sendshot shell 块。
- `ownership`：用户数据或用户配置。

**验证规则**：

- 本次仓库变更不得删除或改写这些状态。
- 删除后的插件不再新建 notebook 状态，但既有文件可以保留。

## 关系

- 两个宿主清单共同发现同一个 Skill 组件集合。
- Hook 组件独立于 Skill 发现；因此 notebook Skill 和其 Stop hook 必须分别完成删除迁移。
- 用户文档描述宿主清单暴露的能力面，必须与 Skill 状态一致。
- 用户本地状态由旧能力产生，但不随仓库组件删除而销毁。
