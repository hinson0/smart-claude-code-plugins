# Smart Claude Code Plugins

Claude Code 插件，自动化 check → commit → push → PR 流程。

## 对话语言
请用中文回复,包括思考过程/回复用户

## 项目结构

```
根目录
├── .claude-plugin/marketplace.json  # 项目级 marketplace 注册文件（指向 plugins/smart）
├── assets/                          # i18n/ 多语言镜像 + imgs/ 截图资源
├── README.md / README_CN/TW/KO/JA.md # 多语言用户文档
└── docs/                            # 设计文档（gitignored，不提交）

assets/i18n/cn/smart/             # CN 镜像目录（仅供阅读，结构与 plugins/smart/ 对称）
├── agents/                       # CN agents（中文版，仅供参考）
├── assets/
│   └── statusline-command.sh
├── hooks/
│   ├── hooks.json
│   ├── greet.sh / goodbye.sh     # 会话开始/结束 hook
│   ├── protect-files.py
│   └── session-logs.py
└── skills/                       # CN skills（中文版，仅供参考）
    ├── check/SKILL.md
    ├── commit/SKILL.md
    ├── help/SKILL.md
    ├── hud/SKILL.md
    ├── pr/SKILL.md
    ├── push/SKILL.md
    └── version/SKILL.md

plugins/smart/                    # EN 主插件目录（被 Claude Code 实际加载）
├── .claude-plugin/plugin.json    # 插件元数据
├── agents/                       # EN agents
├── assets/
│   └── statusline-command.sh     # 打包的 statusline 脚本
├── hooks/
│   ├── hooks.json                # hook 配置
│   ├── greet.sh / goodbye.sh     # 会话开始/结束 hook
│   ├── protect-files.py          # 文件保护 hook（PreToolUse）
│   └── session-logs.py           # hook 输入日志（PreToolUse）
└── skills/                       # EN skills
    ├── check/SKILL.md
    ├── commit/SKILL.md
    ├── help/SKILL.md
    ├── hud/SKILL.md
    ├── push/SKILL.md
    ├── pr/SKILL.md
    └── version/SKILL.md
```

语言版本组织：EN 文件在 `plugins/smart/`（被加载），CN 文件在 `assets/i18n/cn/smart/`（仅供阅读参考），文件名完全相同。

## 架构原则

- **Fail-fast 管道**：任何阶段失败立即停止，不执行后续操作
- **多 feature 智能拆分**：commit skill 逐文件语义分析，不同目的的改动强制拆分为多次提交
- **Skill 链式引用**：push 和 pr skill 通过 `@../path/SKILL.md` 引用上游 skill
- **项目级覆盖**：用户项目的 CLAUDE.md 可覆盖默认 commit 格式
- **语言决策链**：commit skill（step 4）为语言的唯一决策源，PR skill 继承 commit 阶段确定的语言；若 commit 阶段被跳过，则从 `git log` 推断
- **版本自动升级**：push 管道在提交后、推送前自动执行 version bump（check → commit → version → push）；PR 不再单独处理版本
- **版本文件自动检测**：version skill 自动检测 plugin.json / package.json / pyproject.toml，monorepo 中按变更文件归属独立 bump

## 注意事项

- 修改任何 SKILL.md 内容后，必须同步更新 `assets/i18n/cn/smart/` 目录中的对应文件
- 修改 agent 文件同理，`agents/` 和 `assets/i18n/cn/smart/agents/` 需同步更新
- 修改 hooks/assets 的脚本和文件：逻辑与结构保持 EN/CN 一致，但语言严格分离——
  - `plugins/` 下所有文件（注释、description、skill body 等）全英文
  - `assets/i18n/cn/` 下所有文件（注释、description、skill body 等）全中文
- 文件保护配置文件名为 `.claude/.protect_files.jsonc`（注意前导点），hook 代码硬编码此路径；多语言 README 也需一致
- agent EN 版（`plugins/smart/agents/`）：frontmatter + body 全英文（被 Claude Code 实际加载）
- agent CN 版（`assets/i18n/cn/smart/agents/`）：frontmatter（description/example）和 body 均为中文（仅供阅读参考，不被加载）
- commit message 遵循 Conventional Commits：`<type>(<scope>): <description>`
  - type: feat, fix, refactor, docs, test, chore, perf, ci
  - scope: 可选，指明改动范围（如 mobile, api, auth）；省略时格式为 `<type>: <description>`
  - description: 首字母小写，无句号，含 type/scope 在内总长不超过 72 字符
- plugin.json 中的版本号需与实际发布版本一致
- 修改功能、新增/删除组件、或变更用户可见行为后，必须同步更新所有 README 文件（`README.md`、`README_CN.md`、`README_TW.md`、`README_KO.md`、`README_JA.md`），保持 5 个语言版本内容一致

## 常用命令

```bash
# 验证 EN skills 引用路径
grep -r '@\.\./' plugins/smart/skills/ --include='*.md' -h | sort -u

# 验证 CN skills 引用路径
grep -r '@\.\./' assets/i18n/cn/smart/skills/ --include='*.md' -h | sort -u

# 检查 EN/CN 两个语言版本是否齐全
for d in plugins/smart/skills/*/; do
  name=$(basename "$d")
  echo "=== $name ===" && ls "$d"SKILL.md "assets/i18n/cn/smart/skills/$name/SKILL.md"
done

# 测试完整管道（push 已含 version bump）
/smart:check → /smart:commit → /smart:push → /smart:pr
```

## 开发工作流

1. 修改 `skills/<name>/SKILL.md`（英文版为主）
2. 同步更新 `assets/i18n/cn/smart/skills/<name>/SKILL.md`
3. 验证 skill 引用路径正确（`@../` 前缀）
4. 测试完整管道：check → commit → push → pr
