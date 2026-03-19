# Smart Claude Code Plugin

Claude Code 插件，自动化 check → commit → push → PR 流程。

## 项目结构

```
plugins/smart/
├── .claude-plugin/plugin.json    # 插件元数据
└── skills/
    ├── check/    # 本地 CI 检查（lint/test/typecheck）
    ├── commit/   # 智能提交（核心，支持多 feature 拆分）
    ├── push/     # check → commit → push 管道
    └── pr/       # push → 创建 PR 管道
```

每个 skill 目录包含 5 个语言版本：SKILL.md (EN), SKILL_CN.md, SKILL_TW.md, SKILL_JA.md, SKILL_KO.md

## 架构原则

- **Fail-fast 管道**：任何阶段失败立即停止，不执行后续操作
- **多 feature 智能拆分**：commit skill 逐文件语义分析，不同目的的改动强制拆分为多次提交
- **Skill 链式引用**：push 和 pr skill 通过 `@../path/SKILL.md` 引用上游 skill
- **项目级覆盖**：用户项目的 CLAUDE.md 可覆盖默认 commit 格式

## 注意事项

- 修改任何 SKILL.md 内容后，必须同步更新全部 5 个语言版本（EN/CN/TW/JA/KO）
- commit message 遵循 Conventional Commits：`<type>(<scope>): <description>`
  - type: feat, fix, refactor, docs, test, chore, perf, ci
  - scope: 可选，指明改动范围（如 mobile, api, auth）；省略时格式为 `<type>: <description>`
  - description: 首字母小写，无句号，含 type/scope 在内总长不超过 72 字符
- plugin.json 中的版本号需与实际发布版本一致

## 开发工作流

1. 修改 SKILL.md（英文版为主）
2. 同步翻译到其他 4 个语言版本
3. 验证 skill 引用路径正确（`@../` 前缀）
4. 测试完整管道：check → commit → push → pr
