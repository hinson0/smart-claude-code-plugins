---

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。

description: "移除七个 Smart Skills 的依赖有序实施任务"
---

# 任务：移除七个 Smart Skills

**输入**：`specs/001-remove-seven-skills/` 下的规格、计划、研究、数据模型、能力面契约和快速验证指南

**前置条件**：[plan.md](plan.md)、[spec.md](spec.md)、[research.md](research.md)、[data-model.md](data-model.md)、[contracts/plugin-surface.md](contracts/plugin-surface.md)、[quickstart.md](quickstart.md)

**验证要求**：规格明确要求确定性验证与双宿主新会话验收，因此本任务清单包含验证任务，但不新增无需求依据的测试框架。

**评审门禁**：[checklists/removal-review.md](checklists/removal-review.md) 是评审者维护的需求质量清单。执行 `$speckit-implement` 前应由评审者完成审查；实现执行者不得自行勾选该清单。

**组织方式**：任务按用户故事分组，使 P1 能先形成可独立验收的 MVP，再增量完成文档同步和残留清理。

## 格式：`[ID] [P?] [Story] 描述`

- **[P]**：可与同阶段其他 `[P]` 任务并行，文件无冲突且不依赖尚未完成的任务
- **[Story]**：对应规格中的用户故事（US1、US2、US3）
- 所有任务均给出明确文件或目录路径

## Phase 1：准备与范围锁定

**目的**：在破坏性删除前确认仓库没有偏离研究时的组件边界。

- [X] T001 对照 `specs/001-remove-seven-skills/research.md` 核对 `plugins/smart/skills/` 的 14 个现有目录、七个删除目标、七个保留目标及 `plugins/smart/hooks/notebook-capture.py`、`assets/demos/explainer-demo.html` 两个专属外围资产；若范围漂移则停止并更新设计产物

**检查点**：删除和保留边界与设计一致，可进入共享基础修改。

---

## Phase 2：共享基础修改

**目的**：先完成所有用户故事共同依赖的版本和运行时语言门禁。

**⚠️ 关键门禁**：本阶段完成前不得开始用户故事验收。

- [X] T002 [P] 将 `plugins/smart/.codex-plugin/plugin.json` 与 `plugins/smart/.claude-plugin/plugin.json` 的版本同步升级为干净 SemVer `5.0.0`
- [X] T003 [P] 将 `plugins/smart/skills/learning/SKILL.md` 的中文触发短语改写为等价纯英文通用描述，并同步更新 `plugins/smart/skills/learning/CN.md`
- [X] T004 [P] 将 `plugins/smart/skills/show/SKILL.md` 的中文触发短语改写为等价纯英文通用描述，并同步更新 `plugins/smart/skills/show/CN.md`

**检查点**：双宿主版本一致，两个保留 skill 的语言基线修正已成对完成。

---

## Phase 3：用户故事 1——不再发现已删除的 Skills（优先级：P1）🎯 MVP

**目标**：两个宿主不再发现、加载或触发七个目标 skill，Claude Code 也不再运行 notebook Stop hook；七个保留 skill 仍可发现。

**独立测试**：按照 `specs/001-remove-seven-skills/quickstart.md` 的第 1、2、4、5、7 节完成精确目录对账、hook 消失断言、版本检查及双宿主新会话发现检查。

### 实施

- [X] T005 [P] [US1] 删除 `plugins/smart/skills/advance-one-step/` 整个目录及其中英文源文件
- [X] T006 [P] [US1] 删除 `plugins/smart/skills/distill/` 整个目录及全部中英文 references
- [X] T007 [P] [US1] 删除 `plugins/smart/skills/notebook/` 整个目录及其中英文源文件
- [X] T008 [P] [US1] 删除 `plugins/smart/skills/optimize-tokens/` 整个目录及全部中英文 references
- [X] T009 [P] [US1] 删除 `plugins/smart/skills/sendshot/` 整个目录及 `plugins/smart/skills/sendshot/scripts/sendshot.sh`
- [X] T010 [P] [US1] 删除 `plugins/smart/skills/todo/` 整个目录及其中英文源文件
- [X] T011 [P] [US1] 删除 `plugins/smart/skills/wfb/` 整个目录及其中英文源文件
- [X] T012 [P] [US1] 从 `plugins/smart/hooks/hooks.json` 删除整个 Stop 注册，删除 `plugins/smart/hooks/notebook-capture.py`，并将 `plugins/smart/hooks/CN.md` 改为只说明 SessionStart 与 PreToolUse 两个保留 hook
- [X] T013 [US1] 按 `specs/001-remove-seven-skills/quickstart.md` 第 1、2 节验证 `plugins/smart/skills/` 精确等于七个保留目录，且 `plugins/smart/hooks/` 不含 notebook 脚本、说明或 Stop 注册
- [X] T014 [US1] 按 `specs/001-remove-seven-skills/quickstart.md` 第 7 节从当前仓库重装本地 Smart，并在全新 Claude Code 与 Codex 会话中核对 `specs/001-remove-seven-skills/contracts/plugin-surface.md` 的删除及保留命令清单；无法执行时记录宿主、原因和缺失证据
  - 验证记录：Codex 0.149.0 新会话通过，精确发现 `smart:close-issue`、`smart:commit`、`smart:help`、`smart:hud`、`smart:learning`、`smart:local`、`smart:show`；Claude Code 2.1.238 通过 `--plugin-dir plugins/smart` 启动交互式新会话，`/skills` 搜索显示 `7/92` 并精确列出同一组七个 skill。Claude 的非交互模型请求曾返回 HTTP 403，但本地技能发现验收不依赖模型调用并已通过。

**检查点**：US1 可独立验收；两个宿主只发现七个保留 skill，Claude Code 普通回复不再触发 notebook 写入。

---

## Phase 4：用户故事 2——文档准确反映剩余能力（优先级：P2）

**目标**：五种语言 README、插件说明和项目维护说明只描述实际剩余能力，版本与破坏性变更含义一致。

**独立测试**：扫描五份 README、两份插件清单和 `.claude/CLAUDE.md`，目标能力现行宣传为 0；人工核对五种语言的剩余命令、边界、前置条件和行为语义一致。

### 实施

- [X] T015 [P] [US2] 从 `README.md` 删除 distill、wfb、sendshot、advance-one-step、todo、notebook 的功能说明和命令表项，并保持剩余英文段落与表格连贯
- [X] T016 [P] [US2] 从 `README_CN.md` 删除对应六项功能说明和命令表项，并保持剩余简体中文段落与表格连贯
- [X] T017 [P] [US2] 从 `README_TW.md` 删除对应六项功能说明和命令表项，并保持剩余繁体中文段落与表格连贯
- [X] T018 [P] [US2] 从 `README_KO.md` 删除对应六项功能说明和命令表项，并保持剩余韩文段落与表格连贯
- [X] T019 [P] [US2] 从 `README_JA.md` 删除对应六项功能说明和命令表项，并保持剩余日文段落与表格连贯
- [X] T020 [P] [US2] 更新 `.claude/CLAUDE.md` 的 skill 目录示例，移除七个目标名称，并删除 distill 与 notebook 两条专属架构原则
- [X] T021 [P] [US2] 从 `plugins/smart/.codex-plugin/plugin.json` 的 `longDescription` 删除 session knowledge distillation 宣传，同时保留对现有 session utilities 的准确概括
- [X] T022 [US2] 按 `specs/001-remove-seven-skills/quickstart.md` 第 3、6 节检查 `README.md`、`README_CN.md`、`README_TW.md`、`README_KO.md`、`README_JA.md`、`.claude/CLAUDE.md` 和 `plugins/smart/.codex-plugin/plugin.json`，确认无现行目标能力宣传且五语剩余能力语义一致

**检查点**：US2 可独立验收；所有当前用户与维护文档准确描述 Smart 5.0.0 的剩余能力面。

---

## Phase 5：用户故事 3——删除专属残留并保持插件健康（优先级：P3）

**目标**：删除全部专属外围资产，保留共享资产和用户数据边界，并通过仓库规定的完整质量门禁。

**独立测试**：完成全仓残留扫描、双宿主严格清单验证、剩余 skill 配对与语言检查及 close-issue 回归测试；所有失败或未执行项均被明确披露。

### 实施

- [X] T023 [P] [US3] 删除 notebook 专属演示 `assets/demos/explainer-demo.html`，保留 `assets/demos/plan-review-demo.html` 与 `assets/demos/report-demo.html`
- [X] T024 [US3] 审查最终差异，确保 `.gitignore` 的 `.smart/` 规则、`plugins/smart/hooks/greet.sh`、`plugins/smart/hooks/session-logs.py`、七个保留 skill 及用户既有 `.smart/` 数据和 shell rc 均未被删除或自动改写
- [X] T025 [US3] 按 `specs/001-remove-seven-skills/quickstart.md` 第 3 节执行排除 `specs/001-remove-seven-skills/` 的全仓目标词扫描，逐项分类任何命中并使误导性、可执行或孤儿残留归零
- [X] T026 [US3] 按 `specs/001-remove-seven-skills/quickstart.md` 第 4、5 节运行两项 `claude plugin validate --strict`、双宿主 JSON/SemVer 断言、剩余 skill 中英文配对检查和宿主加载语言检查
- [X] T027 [US3] 运行 `plugins/smart/skills/close-issue/scripts/close-issue.test.mjs` 的 Node 回归测试，确认保留能力仍为 19/19 通过

**检查点**：US3 可验收；无专属残留、无共享资产误删，双宿主和保留能力健康。

---

## Phase 6：收尾与跨故事门禁

**目的**：在交接前重跑完整验收并审计最终变更范围。

- [X] T028 按 `specs/001-remove-seven-skills/quickstart.md` 从第 1 节到第 7 节重跑全部适用自动化和人工验收，汇总每项通过、失败或无法执行的结果
  - 验证汇总：精确 skill 目录、hook 消失、全仓残留、五语命令面、双宿主版本、严格清单、配对、运行时语言、19 项回归测试及 Claude Code/Codex 新会话发现验收全部通过；无失败或未执行项。
- [X] T029 审查 `git diff` 与 `git status`，对照 `specs/001-remove-seven-skills/spec.md` 的 FR-001–FR-011 和 `specs/001-remove-seven-skills/contracts/plugin-surface.md`，确认无范围外文件、远端操作、提交、推送或用户数据删除，并运行 `git diff --check`

---

## 依赖与执行顺序

### 阶段依赖

- **Phase 1（准备）**：无依赖，立即开始。
- **Phase 2（共享基础）**：依赖 T001；完成后才进入用户故事验收。
- **US1（Phase 3）**：依赖 Phase 2；MVP 主线。
- **US2（Phase 4）**：依赖 Phase 2；T015–T021 可与 US1 实施并行，但 T022 应在 US1 能力清单稳定后执行。
- **US3（Phase 5）**：T023 可在 Phase 2 后并行执行；T024–T027 依赖 US1 与 US2 完成。
- **Phase 6（收尾）**：依赖所有目标用户故事完成。

### 用户故事依赖

- **US1（P1）**：共享基础完成后无其他故事依赖，可作为 MVP 单独交付和验收。
- **US2（P2）**：文档修改可独立实施；最终准确性检查依赖 US1 的剩余能力面稳定。
- **US3（P3）**：专属演示删除可独立实施；完整插件健康验收依赖 US1、US2。

### 故事内部顺序

- US1：T005–T012 可并行 → T013 静态验收 → T014 双宿主新会话验收。
- US2：T015–T021 可并行 → T022 五语与说明面一致性验收。
- US3：T023 删除演示 → T024 范围审计 → T025–T027 完整验证。

### 并行机会

- Phase 2 的 T002、T003、T004 修改不同文件组，可并行。
- US1 的七个 skill 目录删除与 notebook hook 原子清理互不冲突，可并行。
- US2 的五语 README、项目维护说明和 Codex 长描述修改不同文件，可并行。
- US1 与 US2 的实施任务可在共享基础完成后由不同执行者并行；各自验收按依赖顺序收口。
- US3 的演示删除可与 US1、US2 实施并行，其余健康检查在变更稳定后执行。

---

## 并行示例：用户故事 1

```text
并行任务：T005 删除 plugins/smart/skills/advance-one-step/
并行任务：T006 删除 plugins/smart/skills/distill/
并行任务：T007 删除 plugins/smart/skills/notebook/
并行任务：T008 删除 plugins/smart/skills/optimize-tokens/
并行任务：T009 删除 plugins/smart/skills/sendshot/
并行任务：T010 删除 plugins/smart/skills/todo/
并行任务：T011 删除 plugins/smart/skills/wfb/
并行任务：T012 清理 plugins/smart/hooks/ 的 notebook Stop hook
```

## 并行示例：用户故事 2

```text
并行任务：T015–T019 分别更新五份 README
并行任务：T020 更新 .claude/CLAUDE.md
并行任务：T021 更新 plugins/smart/.codex-plugin/plugin.json
```

## 并行示例：用户故事 3

```text
并行任务：T023 删除 assets/demos/explainer-demo.html
跨故事并行：T023 可与 US1 的目录删除及 US2 的文档更新同时执行
串行收口：T024 → T025、T026、T027
```

---

## 实施策略

### MVP 优先（只完成用户故事 1）

1. 完成 Phase 1 的范围锁定。
2. 完成 Phase 2 的版本与语言基础修改。
3. 完成 Phase 3 的七个 skill 和 notebook hook 删除。
4. 停止并独立执行 T013、T014；只有两个宿主的发现结果都满足契约，MVP 才完成。

### 增量交付

1. Setup + Foundational → 版本和语言门禁就绪。
2. US1 → 七个旧能力不再可发现，形成 MVP。
3. US2 → 五语文档与说明面同步到 Smart 5.0.0。
4. US3 → 清除专属残留并完成健康验证。
5. Cross-Cutting → 重跑全部门禁并审计最终差异。

### 多执行者并行策略

1. 共同完成 T001–T004。
2. 共享基础完成后：执行者 A 负责 US1，执行者 B 负责 US2，执行者 C 提前完成 T023。
3. US1、US2 稳定后由单一执行者串行完成 T024–T029，避免验证期间文件继续变化。

## 备注

- `[P]` 只表示文件边界允许并行，不表示可以绕过阶段依赖。
- 删除目录时必须保留 Git 历史，不创建替代占位文件。
- `optimize-tokens` 在五份 README 中本来无现行条目，不要新增“已删除”说明。
- 不删除或改写用户既有 `.smart/` 数据、`.smart/settings.json` 或 shell rc；本仓库只停止继续提供对应能力。
- `$speckit-implement` 可以更新 `tasks.md` 的任务勾选状态，但不得修改 `checklists/removal-review.md` 的评审标记。
- 任一必需验证失败或未执行时，不得声称发布完成，必须明确披露。
