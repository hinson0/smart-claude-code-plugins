# Commit Skill Description Optimization

**Date:** 2026-03-15
**Status:** Reviewed & Approved

## Problem

The commit skill's `description` field uses a functional summary ("Automatically execute add+commit") rather than trigger-friendly language. This prevents Claude Code from automatically invoking the skill when users express intent to commit in natural language or confirm task completion.

## Goals

1. **Natural language triggering** — Claude Code invokes the skill when users say "commit", "提交", "save my work", etc.
2. **Proactive triggering** — Claude Code invokes the skill when users confirm a task is done ("完成了", "done", "搞定")
3. **Pipeline compatibility** — Continue to work as part of push/PR pipelines

## Design

Update the `description` field in all 5 language versions of the commit skill YAML frontmatter. Keep `argument-hint`, skill body, and `plugin.json` unchanged.

### Design note

Chinese keyword examples ("提交", "完成了", "搞定") are included in the EN description because users in mixed-language environments may type Chinese commands in an English-locale session. The plugin serves multilingual users.

### New descriptions

| File | New description |
|------|----------------|
| `SKILL.md` (EN) | `Use when the user wants to commit changes (e.g. "commit", "提交", "save my work"), confirms a task is done and needs committing (e.g. "完成了", "done", "搞定"), or as part of push/PR pipelines.` |
| `SKILL_CN.md` | `当用户想要提交改动（如"commit"、"提交"、"保存改动"），确认任务完成需要提交（如"完成了"、"done"、"搞定"），或作为 push/PR 管道的一部分时使用。` |
| `SKILL_TW.md` | `當使用者想要提交變更（如「commit」、「提交」、「儲存變更」），確認任務完成需要提交（如「完成了」、「done」、「搞定」），或作為 push/PR 管線的一部分時使用。` |
| `SKILL_JA.md` | `ユーザーが変更をコミットしたい時（例：「commit」「コミットして」「保存して」）、タスク完了を確認してコミットが必要な時（例：「完了」「done」「終わった」）、またはpush/PRパイプラインの一部として使用。` |
| `SKILL_KO.md` | `사용자가 변경 사항을 커밋하려 할 때(예: "commit", "커밋해", "저장해"), 작업 완료를 확인하고 커밋이 필요할 때(예: "완료", "done", "끝났어"), 또는 push/PR 파이프라인의 일부로 사용.` |

## Approach chosen

**Mixed (condition + keyword examples)** — combines semantic trigger conditions ("Use when...") with concrete keyword anchors (e.g. "commit", "提交"). This lets the LLM both understand the intent and match specific phrases.

### Rejected alternatives

- **Keyword-dense only**: High trigger rate but mechanical; cannot enumerate all expressions
- **Condition-driven only**: Good LLM comprehension but lacks concrete anchor points for edge cases
