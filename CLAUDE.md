# Smart Dual-Host Plugin

Smart 同时发布给 Claude Code 与 Codex。

## 发布合同

- 仓库只发布 Smart；入口使用 `/smart:*` 与 `$smart:*`，不提供 Fuzz 兼容入口。
- 两个根 marketplace 登记相同插件集合。每个插件同时提供 Claude Code 与 Codex manifest；Smart 的两份 `plugin.json` 使用同一个干净 SemVer。
- 所有 skill 均设置 `disable-model-invocation: true`，只由用户显式调用。
- 每个 skill 均提供 `agents/openai.yaml`；`display_name` 必须严格等于 `smart:<SKILL.md name>`，保留 Claude Code 原调用名并省略 `/`。
- 每个 `SKILL.md` 配同目录 `CN.md`；每个英文 reference 配 `CN[<name>].md`。修改任意一边时同步另一边。
- 除 `CN.md` 与 `CN[...].md` 外，`plugins/` 下的宿主加载文件、脚本消息和注释使用英文。
- 功能、组件或用户可见行为变更时，同步英文和简体中文两份 README 和 Smart 双宿主版本。插件集合变更时再同步两个根 marketplace。

## 能力边界

- **Commit**：type 是硬边界，purpose 是软边界；不相关改动分开提交。用户项目的 `AGENTS.md`、`CLAUDE.md`、`CLAUDE.local.md` 优先于默认格式与语言。
- **Commit 路由**：Claude Code 使用 `haiku`；Codex 主 agent 只路由给单个 `gpt-5.6-luna` low-reasoning worker，仅允许一次默认子 agent 兜底。worker 不递归委派，主 agent 不接管。
- **Commit 范围**：只分组、生成 message 和提交；不运行检查、升级版本或执行远端操作。
- **Code Simplifier 路由**：Claude Code 只调用一个插件内 `smart:code-simplifier-worker`；Codex 只派生一个 `fork_turns: none` 且不覆盖模型的 worker。worker 串行执行、不递归委派，主 agent 不读取目标代码、不接管实现。
- **Close Issue**：默认只读。关闭资产是当前实现分支的 commit、验收证据和 Review；目标分支集成不是门禁。写 note 和关闭必须有明确授权，该授权不扩展到 push、merge、MR/PR、checklist 或标签。
- **相邻能力**：`show` 与 `html`、`learning` 与 `one-by-one` 合同不同，保持独立。

## 完成标准

1. 先修改英文事实来源，再同步中文伴随文件。受影响的每个成对文件内容一致。
2. 按发布合同更新 README、manifest 版本或 marketplace；无关文件保持不变。
3. 运行 `git diff --check`、`node --test tests/*.test.mjs` 与受影响组件的就近测试。manifest 或 marketplace 变更时，再运行 `claude plugin validate plugins/smart` 与 `claude plugin validate .`。
4. 描述、调用规则或 manifest 变更后，使用本地 marketplace 重装 Smart，并在新会话确认组件发现与调用结果。

Commit message 使用 `<type>(<scope>): <description>`，type 为 `feat|fix|refactor|docs|test|chore|perf|ci`，总长不超过 72 字符。
