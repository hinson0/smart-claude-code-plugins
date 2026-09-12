---
name: matt-implement-all-tickets
description: 串行实现并关闭当前 /to-tickets 输出中的有序 Tickets。
disable-model-invocation: true
---

# Matt 串行实现全部 Ticket

要求同一请求显式调用 Matt 的 `implement` skill，且其指令已加载；否则在访问仓库前请用户同时调用两个 skill。仅使用本会话最近 `/to-tickets` 输出的固定、有序 Ticket 集合。缺失或有歧义则停止，不发现额外工作。

阅读仓库规则和 `docs/agents/issue-tracker.md`；文件缺失时请用户运行 `/setup-matt-pocock-skills`。仅支持 GitHub Issues、GitLab Issues 和 `.scratch/` 下本地 Markdown Ticket。开发前验证 tracker 访问能力，以及干净、可写、非受保护的当前分支。

调用授权为清单中每个 Ticket 发布一条完成记录并关闭。不授权 push、merge、创建 MR/PR、改 assignee、标签、checklist、父 Ticket 或额外工作。

## 串行处理

主会话不编辑实现文件或 Git index。在当前工作区为一个 Ticket 启动一个全新 worker，等待、验证并关闭后，再按发布顺序启动下一 worker。不并行、不预建 worker。中断时报告当前 Ticket，不推断跨会话进度。

逐个 Ticket：

1. 重读当前规格、验收条件、状态和阻塞项。要求 Ticket 打开且所有阻塞项已关闭或 `done`；发生漂移就停止，不跳过或重排。
2. 记录分支和 HEAD 为 `ticket_base`。给一个全新 worker 提供 Ticket、仓库规则、base 和已加载的 Matt `implement` 指令。worker 只负责该 Ticket 的实现、测试、Review 与提交，返回提交区间、文件、检查和 Review 结果。
3. 独立核验 `ticket_base..ticket_tip`、分支包含关系、干净工作区、修改范围、每项验收条件、实际检查和最终 Review。worker 报告只指向证据。worker 阻塞、缺少提交、工作区脏、范围扩大、检查失败或 Review 有可处理问题时停止。
4. 用 `## Implementation assets`、`## Acceptance evidence`、`## Review conclusion`、`## Closeout boundaries` 整理简洁记录：提交区间及范围、逐项验收证据与实际检查结果、Review 来源和结论、剩余风险与未执行交付动作。
5. 发布并验证关闭：
   - **GitHub：** 发布并核验一条 Issue 评论，关闭后重读，要求 `CLOSED`。
   - **GitLab：** 使用相邻 `close-issue/scripts/close-issue.mjs close`，传入 Ticket、`ticket_tip` 和临时记录文件。要求 `closed`，再重读 note 和 Issue 状态。
   - **本地 Markdown：** 在 `## Completion` 下追加记录，把准确的 `Status:` 字段改为 `done`，重读核验两者。如果文件已被跟踪，按仓库规则仅提交该 tracker 更新，恢复干净工作区。

删除临时记录文件。只有核实关闭后才能开始下一个 Ticket。记录发布后关闭失败，报告部分完成并停止，不重复发布。

按顺序返回 Ticket 清单、提交、检查、Review 结论、记录位置和最终状态。只有全部 Ticket 都核实已关闭或 `done` 后才能声称完成。
