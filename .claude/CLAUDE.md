# Smart Claude Code Plugins

Claude Code 插件，自动化 check → commit → push → PR 流程。

## 对话语言
请用中文回复,包括思考过程/回复用户

## 项目结构

```
cn/smart/                         # CN 镜像目录（仅供阅读，结构与 plugins/smart/ 对称）
├── agents/                       # CN agents（中文版，仅供参考）
│   ├── context-analyzer.md
│   ├── cp-my-statusline.md
│   └── joke-teller.md
├── assets/
│   └── statusline-command.sh
├── hooks/
│   ├── hooks.json
│   ├── protect-files.py
│   └── session-logs.py
└── skills/                       # CN skills（中文版，仅供参考）
    ├── check/SKILL.md
    ├── commit/SKILL.md
    ├── hud/SKILL.md
    ├── pr/SKILL.md
    └── push/SKILL.md

plugins/smart/                    # EN 主插件目录（被 Claude Code 实际加载）
├── .claude-plugin/plugin.json    # 插件元数据
├── agents/                       # EN agents
│   ├── context-analyzer.md
│   ├── cp-my-statusline.md
│   └── joke-teller.md
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
    ├── push/SKILL.md
    ├── pr/SKILL.md
    └── hud/SKILL.md
```

语言版本组织：EN 文件在 `plugins/smart/`（被加载），CN 文件在顶层 `cn/smart/`（仅供阅读参考），文件名完全相同。

## 架构原则

- **Fail-fast 管道**：任何阶段失败立即停止，不执行后续操作
- **多 feature 智能拆分**：commit skill 逐文件语义分析，不同目的的改动强制拆分为多次提交
- **Skill 链式引用**：push 和 pr skill 通过 `@../path/SKILL.md` 引用上游 skill
- **项目级覆盖**：用户项目的 CLAUDE.md 可覆盖默认 commit 格式
- **语言决策链**：commit skill（step 4）为语言的唯一决策源，PR skill 继承 commit 阶段确定的语言；若 commit 阶段被跳过，则从 `git log` 推断

## 注意事项

- 修改任何 SKILL.md 内容后，必须同步更新 `cn/smart/` 目录中的对应文件
- 修改 agent 文件同理，`agents/` 和 `cn/smart/agents/` 需同步更新
- agent EN 版（`plugins/smart/agents/`）：frontmatter + body 全英文（被 Claude Code 实际加载）
- agent CN 版（`cn/smart/agents/`）：frontmatter（description/example）和 body 均为中文（仅供阅读参考，不被加载）
- commit message 遵循 Conventional Commits：`<type>(<scope>): <description>`
  - type: feat, fix, refactor, docs, test, chore, perf, ci
  - scope: 可选，指明改动范围（如 mobile, api, auth）；省略时格式为 `<type>: <description>`
  - description: 首字母小写，无句号，含 type/scope 在内总长不超过 72 字符
- plugin.json 中的版本号需与实际发布版本一致

## 常用命令

```bash
# 验证 EN skills 引用路径
grep -r '@\.\./' plugins/smart/skills/ --include='*.md' -h | sort -u

# 验证 CN skills 引用路径
grep -r '@\.\./' cn/smart/skills/ --include='*.md' -h | sort -u

# 检查 EN/CN 两个语言版本是否齐全
for d in plugins/smart/skills/*/; do
  name=$(basename "$d")
  echo "=== $name ===" && ls "$d"SKILL.md "cn/smart/skills/$name/SKILL.md"
done

# 测试完整管道
/smart:check → /smart:commit → /smart:push → /smart:pr
```

## 开发工作流

1. 修改 `skills/<name>/SKILL.md`（英文版为主）
2. 同步更新 `cn/smart/skills/<name>/SKILL.md`
3. 验证 skill 引用路径正确（`@../` 前缀）
4. 测试完整管道：check → commit → push → pr
