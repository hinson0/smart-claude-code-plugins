---
name: clean-branches
description: 清理已完整合并到指定目标分支的本地和远端分支。
disable-model-invocation: true
argument-hint: "[目标分支，默认 main]"
---

1. 有目标分支参数时直接使用，不再确认。无参数时，用用户的语言询问“默认清理已合并到 main 的本地和远端分支，是否继续？”，等待明确确认后再执行。
2. 读取项目约定，确定远端，fetch 并 prune，确认远端目标分支存在。远端不明确时询问，不猜测。
3. 找出分支头提交是已获取的远端目标分支祖先的本地和远端分支。逐个独立核对；PR 已合并或分支同名都不能作为证明。
4. 排除目标分支、`main`、`master`、`dev`、`develop`、远端默认分支、项目或托管平台保护分支，以及任何 worktree 正在使用的分支名。
5. 展示候选清单，然后逐个删除。删除前复核分支头、祖先关系和排除条件，引用已变化则跳过。本地仅使用 `git branch -d`；远端使用带明确预期提交的租约删除：`git push <remote> --force-with-lease=refs/heads/<branch>:<expected-oid> :refs/heads/<branch>`，租约被拒后不得去掉租约重试。
6. 核验删除结果，汇报已删除、跳过和失败的分支及原因。无候选则说明并结束。

不删除 worktree、不丢弃未提交改动、不强删本地分支。保留无法证明完整集成的分支，包括无法确认的 squash/rebase 合并。获取远端或合并验证失败时停止。
