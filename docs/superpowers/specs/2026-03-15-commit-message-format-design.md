# Commit Message 格式规范设计

## 背景

当前 commit skill 的步骤 4 对 commit message 格式没有明确的结构化要求，只要求"生成 1 句英文 commit message，风格与最近提交保持一致"。需要增加默认的格式规范，同时支持项目级别的自定义覆盖。

## 设计

### 改动范围

仅修改 commit skill 的**步骤 4（生成 commit message）**，其他步骤不变。

涉及文件：
- `plugins/smart/skills/commit/SKILL.md`（英文）
- `plugins/smart/skills/commit/SKILL_CN.md`（中文）
- `plugins/smart/skills/commit/SKILL_TW.md`（繁体中文）
- `plugins/smart/skills/commit/SKILL_JA.md`（日文）
- `plugins/smart/skills/commit/SKILL_KO.md`（韩文）

### 默认格式规范

```
<type>: <description>
```

**type 限定值：** `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

**description 约束：**
- 首字母小写
- 不以句号结尾
- 总长度（含 type 前缀）不超过 72 字符
- 聚焦"为什么改"，避免空泛描述

**语言：** 默认英文。

### 项目覆盖规则

如果项目 CLAUDE.md 中定义了 commit message 的自定义格式或语言要求，以项目规范为准，忽略上述默认规则。

### 实现方式

方案 A — 直接在 skill 步骤 4 中内联规范。CLAUDE.md 的内容本身已在 Claude Code 会话上下文中，skill 无需额外读取操作，只需声明"项目 CLAUDE.md 中的自定义规范优先"即可。
