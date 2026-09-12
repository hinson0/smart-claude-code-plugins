# 研究结论：移除七个 Smart Skills

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。 `ask`、`html`、`show` 及 show 专属示例已于 7.0.0 移除，以下保留要求同样仅供历史追溯。

## 决定 1：整体删除七个 skill 目录

**决定**：递归删除七个目标目录内共 23 个文件，不保留翻译、reference 或脚本孤儿。

**理由**：Codex 通过 `plugins/smart/.codex-plugin/plugin.json` 的 `skills: ./skills/` 动态发现，Claude Code 清单也没有逐项 skill 注册；`help` 同样动态扫描目录。整体删除能同时终止两个宿主的发现，并维持资产配对边界。

**考虑过的替代方案**：只删 `SKILL.md`。虽然可阻止加载，但会留下 16 个无归属翻译、reference 和脚本文件，因此拒绝。

## 决定 2：删除 notebook 专属 Stop hook

**决定**：删除 `plugins/smart/hooks/notebook-capture.py`，从 `hooks.json` 删除整个 Stop 注册，并从 `hooks/CN.md` 删除对应说明；SessionStart 和 PreToolUse 保持不变。

**理由**：该 hook 独立于 skill 发现，每次回复后仍会写入 `.smart/notebook.md`。只删 skill 会留下不可发现但持续运行的幽灵功能。

**考虑过的替代方案**：把 hook 保留为独立能力。与用户删除 `notebook` 及规格 FR-004 冲突，因此拒绝。

## 决定 3：删除 notebook 专属演示页

**决定**：删除 `assets/demos/explainer-demo.html`，保留 `plan-review-demo.html` 与 `report-demo.html`。

**理由**：explainer 页面全部讲解 notebook、todo、distill 和 `notebook-capture.py`，保留会继续公开宣传被删除功能；另外两个页面不依赖目标 skill，仍支撑 show 的演示说明。

**考虑过的替代方案**：将 explainer 重写为其他主题。这会扩大内容工作，且另外两份演示已足够，因此拒绝。

## 决定 4：同步清理当前产品文档

**决定**：五份 README 各删除 `distill`、`wfb`、`sendshot`、`advance-one-step`、`todo`、`notebook` 的功能说明和命令表项；`optimize-tokens` 当前没有 README 条目。同步更新 `.claude/CLAUDE.md` 的 skill 清单，并删除 distill/notebook 专属架构原则。

**理由**：组件删除属于用户可见行为变化，项目铁律要求五语文档同次同步；维护说明也必须与当前结构一致。

**考虑过的替代方案**：在 README 保留“已移除”公告。仓库没有版本迁移或 changelog 约定，README 是当前能力说明，直接删除更准确。

## 决定 5：版本统一升级到 5.0.0

**决定**：两份 `plugin.json` 从 `4.0.1` 同步升级为干净 SemVer `5.0.0`；同时从 Codex `longDescription` 移除 `session knowledge distillation`。两份 marketplace 的通用描述仍准确，不修改。

**理由**：删除一半公开 skill 与旧命令是破坏性变更。仓库历史提交 `4e39b0b` 对同类能力收缩采用了 `3.34.0 → 4.0.0`，支持本次升级主版本。

**考虑过的替代方案**：`4.1.0` 或 `4.0.2`。它们分别表示向后兼容新增或修复，不能准确表达公开命令删除，因此拒绝。

## 决定 6：保留用户数据与本机安装副作用

**决定**：不删除用户已有 `.smart/notebook.md`、`.smart/todo-list.md`、knowledge 文件或 `.smart/settings.json`；不主动清理 shell rc 中既有 sendshot 函数；保留仓库 `.gitignore` 的 `.smart/` 规则。

**理由**：产品能力删除不授权销毁用户数据或修改仓库外配置；保留的 session logs 和 show 仍使用 `.smart/`。

**考虑过的替代方案**：自动迁移或卸载用户状态。操作具有破坏性、跨出仓库范围，因此拒绝。

## 决定 7：使用确定性契约加双宿主新会话验证

**决定**：用精确目录对账、目标词残留扫描、hook 消失断言、版本一致性、skill 配对、运行时语言检查、严格 Claude 清单校验和现有 close-issue 测试构成自动化门禁；再以本地 marketplace 重装后的 Claude Code/Codex 新会话验证真实发现结果。

**理由**：Codex CLI 当前没有 manifest validate 子命令；旧会话还可能缓存 skill，静态检查不足以单独证明双宿主实际发现结果。

**考虑过的替代方案**：只运行 `claude plugin validate` 或只扫目标名称。前者不覆盖 Codex 与动态发现，后者可能漏掉结构错误，均不足够。

## 决定 8：顺带修复两个最小运行时语言基线命中

**决定**：把保留的 `learning/SKILL.md` 与 `show/SKILL.md` frontmatter 中中文触发短语改写为等价纯英文通用描述，并同步对应 `CN.md`。

**理由**：删除目标 skill 后，项目规定的运行时中文扫描仍会命中这两个保留文件；规格 FR-009 与宪法原则 III 要求交付时满足语言边界。改为“任意语言下表达参与编码/HTML 展示意图”等英文描述可保留触发语义。

**考虑过的替代方案**：把两处记录为范围外基线失败。这样无法通过本功能明确要求的门禁，也不能声称验证完成，因此拒绝。

## 研究结论

所有技术未知项已解决，没有待澄清内容。当前严格 Claude 清单校验通过，现有 close-issue 回归测试为 19/19 通过；这些结果作为实施前基线，实施后必须重复验证。
