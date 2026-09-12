# 实现计划：移除七个 Smart Skills

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。 `ask`、`html`、`show` 及 show 专属示例已于 7.0.0 移除，以下保留要求同样仅供历史追溯。

**Branch**: `001-remove-seven-skills`（逻辑功能名；当前工作区为 detached HEAD） | **Date**: 2026-08-23 | **Spec**: [spec.md](spec.md)

**Input**: 来自 `specs/001-remove-seven-skills/spec.md` 的功能规格

## 摘要

从 Smart 双宿主插件中完整移除 `advance-one-step`、`distill`、`notebook`、`optimize-tokens`、`sendshot`、`wfb` 和 `todo`：递归删除七个 skill 目录，清理 `notebook` 专属 Stop hook 与演示页，同步五语 README、项目维护说明和双宿主插件描述，并将两份插件版本从 `4.0.1` 统一升级到 `5.0.0`。保留其余七个 skill、共享 hook、用户既有 `.smart/` 数据和已安装的 shell 配置，通过静态契约、严格清单校验、现有回归测试及双宿主新会话发现检查完成验证。

## 技术上下文

**语言/版本**：Markdown；JSON；Python 3.14（现有 hook）；POSIX shell；Node.js 24（验证脚本与现有测试）

**主要依赖**：Claude Code 插件清单与 hook 约定、Codex 插件清单、Claude Code CLI 2.1.238、Codex CLI 0.149.0、`rg`、`jq`

**存储**：仓库内文件；用户侧 `.smart/` 状态和 shell rc 不迁移、不删除

**测试**：`claude plugin validate --strict`、目录和残留引用的 shell 断言、JSON/SemVer 断言、skill 中英文配对检查、运行时语言检查、Node 内置测试运行器、双宿主新会话人工发现检查

**目标平台**：Claude Code 与 Codex 双宿主；仓库验证环境为 macOS/Unix shell

**项目类型**：双宿主插件包

**性能目标**：不适用；删除后不得新增运行时 hook 或后台写入

**约束**：双宿主结构必须保留；两份 `plugin.json` 版本必须相同且为干净 SemVer；组件增删必须同步五语 README；宿主加载文件必须为英文；每个保留 skill 必须保留 `SKILL.md`/`CN.md` 配对；不得删除用户数据、自动卸载 shell 函数或执行远端写操作

**规模/范围**：skill 数量从 14 减至 7；删除目标目录内 23 个文件、2 个专属外围资产；修改 hook 注册与说明、五语 README、项目维护说明、两份插件清单，并最小修复 2 个保留 skill 的运行时语言基线问题及其中文同步文件

## 宪法检查

*门禁：Phase 0 前必须通过，Phase 1 设计后重新检查。*

### Phase 0 前

- **I. 双宿主一致性：通过**。保留两套 marketplace 与插件目录；两份 `plugin.json` 统一升级到 `5.0.0`，skill 继续由共同目录动态发现。
- **II. 用户文档同步：通过**。五份 README 在同一变更中删除相同六项现行宣传和命令表项；`optimize-tokens` 当前无 README 条目。
- **III. 中英文源文件配对：通过（含必要修正）**。七个目标目录成对整体删除；七个保留 skill 继续成对。现有 `learning/SKILL.md`、`show/SKILL.md` 描述含中文触发短语，计划改为纯英文的等价通用描述，并同步对应 `CN.md`。
- **IV. 自动化范围与安全：通过**。仅删除仓库能力与专属注册；不删除既有 `.smart/` 文件、不清理用户 shell rc、不提交、不推送、不创建远端变更。
- **V. 版本化且经过验证的交付：通过**。破坏性删除采用 `5.0.0`；设计包含严格清单验证、确定性静态契约、现有 19 项 close-issue 回归测试和双宿主新会话检查。

无需要例外说明的宪法违规。

### Phase 1 后复核

- [x] [research.md](research.md) 已解决删除边界、版本级别、专属资产、用户数据和验证策略。
- [x] [data-model.md](data-model.md) 明确组件状态、关系和保留边界。
- [x] [contracts/plugin-surface.md](contracts/plugin-surface.md) 同时约束两个宿主的删除后能力面与 hook 面。
- [x] [quickstart.md](quickstart.md) 覆盖自动化门禁和双宿主端到端发现验证。
- [x] 设计没有引入远程写入、用户数据清理或无理由复杂度。

结论：Phase 1 后仍满足全部宪法门禁。

## 项目结构

### 本功能文档

```text
specs/001-remove-seven-skills/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── plugin-surface.md
├── checklists/
│   └── requirements.md
└── tasks.md                  # 后续由 $speckit-tasks 生成
```

### 仓库源文件

```text
.
├── .agents/plugins/marketplace.json       # 保留并验证 Codex marketplace
├── .claude-plugin/marketplace.json        # 保留并验证 Claude marketplace
├── .claude/CLAUDE.md                      # 更新剩余组件与架构原则
├── README.md                              # 同步删除现行功能与命令
├── README_CN.md
├── README_TW.md
├── README_KO.md
├── README_JA.md
├── assets/demos/
│   ├── explainer-demo.html                # 删除：notebook 专属演示
│   ├── plan-review-demo.html              # 保留
│   └── report-demo.html                   # 保留
└── plugins/smart/
    ├── .codex-plugin/plugin.json          # 5.0.0；移除 distill 宣传
    ├── .claude-plugin/plugin.json         # 5.0.0
    ├── hooks/
    │   ├── hooks.json                     # 删除 Stop/notebook 注册
    │   ├── CN.md                          # 仅说明剩余两个 hook
    │   ├── notebook-capture.py            # 删除
    │   ├── greet.sh                       # 保留
    │   └── session-logs.py                # 保留
    └── skills/
        ├── advance-one-step/               # 删除整个目录
        ├── distill/                        # 删除整个目录及 references
        ├── notebook/                       # 删除整个目录
        ├── optimize-tokens/                # 删除整个目录及 references
        ├── sendshot/                       # 删除整个目录及脚本
        ├── todo/                           # 删除整个目录
        ├── wfb/                            # 删除整个目录
        ├── learning/{SKILL.md,CN.md}       # 最小语言边界同步修正
        ├── show/{SKILL.md,CN.md}           # 最小语言边界同步修正
        └── {close-issue,commit,help,hud,local}/ # 保留
```

**结构决策**：插件能力由 `plugins/smart/skills/` 动态发现，没有逐项 skill 注册表，因此目录整体删除是两个宿主共同的最小生效边界；`notebook` 的 Stop hook 位于独立目录，必须单独删除注册、脚本和说明。两份 marketplace 不含目标名称，不修改正文，只参与验证。

## 实施顺序

1. 先按目标目录删除 23 个 skill 文件，同时删除 `notebook-capture.py` 和专属演示页。
2. 更新 `hooks.json` 与 `hooks/CN.md`，保留 SessionStart 和 PreToolUse 两个 hook。
3. 同步修改五语 README 与 `.claude/CLAUDE.md`，确保只描述剩余七个 skill。
4. 更新 Codex 插件长描述，并把两份 `plugin.json` 统一升级到 `5.0.0`。
5. 将 `learning`、`show` 的宿主加载描述改写为纯英文等价表达，同步各自 `CN.md`，清除剩余运行时中文基线命中。
6. 按 quickstart 运行静态检查、严格清单校验和现有测试；最后在两个宿主的新会话中验证发现结果与 notebook 后台行为消失。
