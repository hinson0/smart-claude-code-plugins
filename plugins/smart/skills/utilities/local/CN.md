---
name: local
description: 创建被 git 忽略的 `.claude/CLAUDE.local.md`，保存项目级个人偏好。
disable-model-invocation: true
argument-hint: "（无参数 —— 创建一个被 git 忽略的 .claude/CLAUDE.local.md）"
---

在 `.claude/CLAUDE.local.md` 创建个人偏好文件。

1. 用 `git rev-parse --show-toplevel` 解析根目录；非 Git 项目回退到当前工作目录。
2. 仅在缺失时创建 `.claude/` 和文件，绝不覆盖已有笔记。
3. Git 仓库内用 `git check-ignore -q .claude/CLAUDE.local.md` 检查。
   尚未忽略时向根目录 `.gitignore` 追加 `.claude/CLAUDE.local.md`，不重复添加、不改其他内容。
4. 报告绝对路径、是否新建及忽略状态。

新文件使用以下模板，已有用户偏好保持权威：

```markdown
# 项目个人笔记

## 偏好
- 回复及 skill 输出使用简体中文，保留必要的英文术语。
- Plan Mode 文件：`.claude/plans/YYYY_MM_DD_HH_mm-<name>.md`

## 本地上下文
```
