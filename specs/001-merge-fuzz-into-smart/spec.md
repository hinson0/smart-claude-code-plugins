# 功能规格：将 Fuzz 合并到 Smart

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。

## 目标

仓库只发布一个同时支持 Claude Code 与 Codex 的 `smart` 插件。Fuzz 中拥有完整独立合同的能力迁入 Smart，用户只需安装和理解一个插件、一个命名空间和一个版本边界。

## 功能需求

1. 两个根 marketplace 只登记 `smart`，不再登记或发布独立 `fuzz`。
2. Smart 同时提供原有七个 skill，以及从 Fuzz 迁入的六个 skill：`ask`、`generate-wiki`、`github-skills-pdf`、`html`、`my-weekly`、`one-by-one`。
3. 六个迁入 skill 使用 `/smart:*` 与 `$smart:*` 入口，不保留 `/fuzz:*`、`$fuzz:*` 或 `fuzz@smart` 兼容入口。
4. Smart 继续使用现有 `close-issue` 合同；Fuzz 的同名实现不迁入。
5. `handle-all-tickets` 和 `verify-all-tickets` 不迁入，相关共享 reference 与合同测试一并删除。
6. `show` 与 `html`、`learning` 与 `one-by-one` 分别保留，不合并其行为合同。
7. Smart 双宿主 manifest 使用相同的干净 SemVer `6.0.0`；两个根 marketplace 保持相同插件集合。
8. 五份 README、`.claude/CLAUDE.md`、Smart help 文档及 Codex 默认提示同步反映单插件能力面。
9. 删除 `plugins/fuzz/` 和旧的 `specs/001-migrate-fuzz-plugin/`；不保留 CE 来源说明。
10. Smart 现有 hooks、rules、会话日志默认行为和七个原有 skill 行为保持不变。
11. 删除 README 中不存在的 Joke Teller Agent 说明，以及 HUD 脚本中已删除 `token-log` 的陈旧引用；不做其他无关重构。
12. `docs/adr/` 与 `docs/agents/` 可被 Git 跟踪，其他根 `docs/` 内容继续默认忽略。

## 验收标准

- Smart、根 marketplace 均通过 Claude 插件严格校验。
- 根 Node 测试、Smart `close-issue` 测试以及迁入 skill 的脚本行为测试全部通过。
- `plugins/` 中的每个 `SKILL.md` 均有同目录 `CN.md`，英文 reference 均有对应中文 reference。
- `plugins/` 下宿主加载的 `SKILL.md` 与脚本不包含中文运行时内容。
- 全仓不再出现有效的 Fuzz 安装入口、Fuzz 命名空间或独立 Fuzz 发布清单。
- 工作区最终由提交完整收口，不执行 push。
