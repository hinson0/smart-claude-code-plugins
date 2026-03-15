# Push & PR Skill Description Optimization

**Date:** 2026-03-15
**Status:** Reviewed & Approved

## Problem

The push and pr skills' `description` fields use functional summaries rather than trigger-friendly language, same issue as the commit skill (see `2026-03-15-commit-skill-description-design.md`).

## Goals

1. **Natural language triggering** — Claude Code invokes the correct skill when users express intent to push or create a PR
2. **Strict boundary** — push and pr descriptions do not overlap in trigger keywords, avoiding ambiguous invocation
3. **Pipeline transparency** — descriptions clarify what stages each skill includes

## Design

Update the `description` field in all 5 language versions of both push and pr skills. Keep `argument-hint`, skill body, and `plugin.json` unchanged.

### Design note

Push description explicitly states "Not for creating PRs — use smart:pr instead." PR description explicitly states "Includes push — no need to push first." This prevents overlap and guides both the LLM and the user.

### Push skill — new descriptions

| File | New description |
|------|----------------|
| `SKILL.md` (EN) | `Use when the user wants to push code to remote (e.g. "push", "推一下", "push to origin"), or wants the full check+commit+push pipeline. Not for creating PRs — use smart:pr instead.` |
| `SKILL_CN.md` | `当用户想要推送代码到远程（如"push"、"推一下"、"推到远程"），或需要完整的 check+commit+push 管道时使用。不用于创建 PR — 请使用 smart:pr。` |
| `SKILL_TW.md` | `當使用者想要推送程式碼到遠端（如「push」、「推一下」、「推到遠端」），或需要完整的 check+commit+push 管線時使用。不用於建立 PR — 請使用 smart:pr。` |
| `SKILL_JA.md` | `ユーザーがコードをリモートにプッシュしたい時（例：「push」「プッシュして」「リモートに送って」）、またはcheck+commit+pushの完全パイプラインが必要な時に使用。PR作成には使用しない — smart:prを使用。` |
| `SKILL_KO.md` | `사용자가 코드를 원격에 푸시하려 할 때(예: "push", "푸시해", "원격에 올려"), 또는 전체 check+commit+push 파이프라인이 필요할 때 사용. PR 생성에는 사용하지 않음 — smart:pr 사용.` |

### PR skill — new descriptions

| File | New description |
|------|----------------|
| `SKILL.md` (EN) | `Use when the user wants to create a pull request (e.g. "create PR", "发个PR", "open a pull request", "提个PR"), or wants the full check+commit+push+PR pipeline. Includes push — no need to push first.` |
| `SKILL_CN.md` | `当用户想要创建 Pull Request（如"create PR"、"发个PR"、"提个PR"、"创建合并请求"），或需要完整的 check+commit+push+PR 管道时使用。已包含 push — 无需先手动推送。` |
| `SKILL_TW.md` | `當使用者想要建立 Pull Request（如「create PR」、「發個PR」、「提個PR」、「建立合併請求」），或需要完整的 check+commit+push+PR 管線時使用。已包含 push — 無需先手動推送。` |
| `SKILL_JA.md` | `ユーザーがPull Requestを作成したい時（例：「create PR」「PRを作って」「プルリクを出して」）、またはcheck+commit+push+PRの完全パイプラインが必要な時に使用。push込み — 先にpushする必要なし。` |
| `SKILL_KO.md` | `사용자가 Pull Request를 만들려 할 때(예: "create PR", "PR 만들어", "풀리퀘 올려"), 또는 전체 check+commit+push+PR 파이프라인이 필요할 때 사용. push 포함 — 먼저 push할 필요 없음.` |

## Approach chosen

**Mixed (condition + keyword examples)** with **strict boundary enforcement** — same approach as commit skill, plus explicit cross-references between push and pr to prevent overlap.

### Rejected alternatives

- **Overlapping triggers**: Would cause ambiguous invocation between push and pr
- **No pipeline info**: Users wouldn't know pr includes push, leading to redundant manual push before PR
