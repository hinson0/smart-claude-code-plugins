---
name: close-issue
description: 检查单个 GitLab Issue 是否可关闭，或在明确授权后发布可审计资产记录并关闭 Issue。
disable-model-invocation: true
---

# 关闭单个 GitLab Issue

检查一个 Issue IID 或 URL。默认只读：就绪询问或模糊意图不授权写入。明确“关闭该 Issue”授权先发布一条开发资产 note，再关闭；不包含 push、merge、创建 MR/PR、修改 checklist 或标签。

## 确认就绪

阅读仓库规则和当前 Issue，包括评论与验收条件。本流程要求 GitLab Issues 和 `glab issue`。从可选参数或当前证据确定唯一、已提交的实现 SHA；当前实现分支必须干净且包含该提交。

针对每项验收条件核实实现 diff、实际执行的检查和可信代码 Review。缺少证据时执行允许的检查或仓库 Review 流程，否则返回 `not_ready` 和阻塞原因。worker 报告和摘要只指向证据；未运行的检查不得声称通过。目标分支集成是需要披露的交付边界，不是关闭门禁。

运行只读脚本门禁：

```bash
node <this-skill-directory>/scripts/close-issue.mjs check --issue <iid-or-url> --commit <sha>
```

当前项目以外的数字 IID 增加 `--repo <group/project>`。脚本 `ready` 是必要条件，不代表验收与 Review 完整。仅检查请求到此返回 `ready` 或 `not_ready`，不创建 note 文件。

## 发布并关闭

只有明确关闭授权和全部就绪证据通过后，才在工作区外创建临时 Markdown note，使用脚本要求的标题：

- `## Implementation assets`：Issue/规格、当前实现分支、提交、范围及真实存在的持久链接。
- `## Acceptance evidence`：逐项验收证据、实际执行命令及结果。
- `## Review conclusion`：Review 来源、结论、已解决问题与剩余风险。
- `## Closeout boundaries`：未经验证的目标分支集成和未执行的交付动作。

note 应可独立审计，不含秘密或无依据结论。使用脚本重新执行门禁、先发布 note 再关闭：

```bash
node <this-skill-directory>/scripts/close-issue.mjs close --issue <iid-or-url> --commit <sha> --note-file <note.md>
```

按真实结果报告：`closed` 返回 note 和 Issue 链接；`note_failed` 表示关闭未执行；`partially_completed` 且 `stage: noted` 表示 note 已存在但 Issue 仍打开。保留链接并说明失败，不暗示成功、不重复发布 note。删除临时文件。使用 fixture 和假的 `git`/`glab` 验证流程，不用真实 Issue 做测试。
