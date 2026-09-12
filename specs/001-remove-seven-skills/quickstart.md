# 快速验证：移除七个 Smart Skills

> 历史说明（2026-09-12）：现行文档仅维护英文 README.md 和简体中文 README_CN.md；以下五语文档描述及旧文件名仅保留为历史记录，不再作为维护要求。

## 前置条件

- 在仓库根目录执行命令。
- 可用工具：`bash` 或 `zsh`、`rg`、`jq`、Node.js、Claude Code CLI、Codex CLI。
- 先完成实现，再执行本指南；本指南不会删除用户数据。

## 1. 对账最终 skill 清单

```bash
for skill_name in advance-one-step distill notebook optimize-tokens sendshot wfb todo; do
  test ! -e "plugins/smart/skills/$skill_name"
done

diff -u \
  <(printf '%s\n' close-issue commit help hud learning local show) \
  <(find plugins/smart/skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
```

预期：退出码为 0，实际目录精确等于七个保留 skill。

## 2. 确认 notebook 后台行为已移除

```bash
test ! -e plugins/smart/hooks/notebook-capture.py
! rg -n -i 'notebook|notebook-capture' plugins/smart/hooks
jq -e '.hooks | has("Stop") | not' plugins/smart/hooks/hooks.json
```

预期：全部退出 0；hooks 目录不再含 notebook 或 Stop 注册。

## 3. 扫描产品残留

```bash
! rg -n -i \
  'advance-one-step|distill|notebook|optimize-tokens|sendshot|\bwfb\b|/smart:todo\b|skills/todo\b|todo-list\.md' \
  . --hidden -g '!.git/**' -g '!specs/001-remove-seven-skills/**'
```

预期：无输出。本次规格目录保留目标名称用于记录删除事实，因此明确排除。

## 4. 验证双宿主清单与版本

```bash
claude plugin validate --strict plugins/smart
claude plugin validate --strict .

node - <<'NODE'
const fs = require('fs')
const codex = JSON.parse(fs.readFileSync('plugins/smart/.codex-plugin/plugin.json'))
const claude = JSON.parse(fs.readFileSync('plugins/smart/.claude-plugin/plugin.json'))
if (codex.version !== '5.0.0') throw new Error('unexpected Codex version')
if (claude.version !== codex.version) throw new Error('version mismatch')
if (!/^\d+\.\d+\.\d+$/.test(codex.version)) throw new Error('unclean SemVer')
NODE
```

预期：严格清单校验通过，两份版本均为干净 SemVer `5.0.0`。

## 5. 验证配对、语言和保留能力回归

```bash
for skill_dir in plugins/smart/skills/*/; do
  test -f "${skill_dir}SKILL.md" && test -f "${skill_dir}CN.md"
done

! rg '[\p{Script=Han}]' plugins/smart/skills --glob 'SKILL.md' --glob '*.mjs'

node --test plugins/smart/skills/close-issue/scripts/close-issue.test.mjs
```

预期：全部 skill 成对；宿主加载文件无中文；close-issue 回归测试保持 19/19 通过。

## 6. 人工核对五语文档

逐份检查 `README.md`、`README_CN.md`、`README_TW.md`、`README_KO.md`、`README_JA.md`：

- 功能列表和命令表均不再出现七个目标能力；
- 剩余能力范围在五种语言中一致；
- 删除行后表格、分组和上下文仍连贯。

## 7. 双宿主新会话验证

将本地 marketplace 指向当前仓库；若已配置同名 marketplace，先刷新或复用该本地路径，再安装 Smart：

```bash
claude plugin marketplace add "$PWD"
claude plugin install smart@smart

codex plugin marketplace add "$PWD"
codex plugin add smart@smart
```

分别开启全新的 Claude Code 与 Codex 会话，验证：

1. `/smart:help skill` 或宿主 skill 列表只显示七个保留能力。
2. 七个旧命令不再被识别为 Smart skill。
3. `commit`、`help`、`hud` 中至少一个保留能力仍可发现。
4. Claude Code 新会话得到一段带 `★ Insight` 标记的回复后，项目内不会新建 `.smart/notebook.md`。

旧会话可能持有缓存，不能用于最终发现验收。Codex CLI 当前没有清单验证子命令，因此 Codex 的真实安装与新会话检查是必需验收项。
