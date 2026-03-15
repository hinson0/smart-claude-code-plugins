# Commit Skill Description Optimization — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the `description` field in all 5 language versions of the commit skill to enable automatic triggering by Claude Code.

**Architecture:** Edit-only change to YAML frontmatter in 5 SKILL files. No new files, no logic changes, no tests needed.

**Tech Stack:** Markdown / YAML frontmatter

**Spec:** `docs/superpowers/specs/2026-03-15-commit-skill-description-design.md`

---

## Chunk 1: Update all 5 commit skill descriptions

### Task 1: Update EN description

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL.md:2`

- [ ] **Step 1: Replace the description line**

Old:
```yaml
description: Automatically execute add+commit (auto-generate commit message)
```

New:
```yaml
description: Use when the user wants to commit changes (e.g. "commit", "提交", "save my work"), confirms a task is done and needs committing (e.g. "完成了", "done", "搞定"), or as part of push/PR pipelines.
```

- [ ] **Step 2: Verify the frontmatter is valid**

Run: `head -4 plugins/smart/skills/commit/SKILL.md`
Expected: valid YAML frontmatter with `---` delimiters and the new description.

### Task 2: Update CN description

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_CN.md:2`

- [ ] **Step 1: Replace the description line**

Old:
```yaml
description: 自动执行 add+commit（自动生成 commit message）
```

New:
```yaml
description: 当用户想要提交改动（如"commit"、"提交"、"保存改动"），确认任务完成需要提交（如"完成了"、"done"、"搞定"），或作为 push/PR 管道的一部分时使用。
```

### Task 3: Update TW description

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_TW.md:2`

- [ ] **Step 1: Replace the description line**

Old:
```yaml
description: 自動執行 add+commit（自動生成 commit message）
```

New:
```yaml
description: 當使用者想要提交變更（如「commit」、「提交」、「儲存變更」），確認任務完成需要提交（如「完成了」、「done」、「搞定」），或作為 push/PR 管線的一部分時使用。
```

### Task 4: Update JA description

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_JA.md:2`

- [ ] **Step 1: Replace the description line**

Old:
```yaml
description: add+commit を自動実行（commit message を自動生成）
```

New:
```yaml
description: ユーザーが変更をコミットしたい時（例：「commit」「コミットして」「保存して」）、タスク完了を確認してコミットが必要な時（例：「完了」「done」「終わった」）、またはpush/PRパイプラインの一部として使用。
```

### Task 5: Update KO description

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_KO.md:2`

- [ ] **Step 1: Replace the description line**

Old:
```yaml
description: 자동으로 add+commit 실행 (commit message 자동 생성)
```

New:
```yaml
description: 사용자가 변경 사항을 커밋하려 할 때(예: "commit", "커밋해", "저장해"), 작업 완료를 확인하고 커밋이 필요할 때(예: "완료", "done", "끝났어"), 또는 push/PR 파이프라인의 일부로 사용.
```

### Task 6: Commit all changes

- [ ] **Step 1: Stage and commit**

```bash
git add plugins/smart/skills/commit/SKILL.md plugins/smart/skills/commit/SKILL_CN.md plugins/smart/skills/commit/SKILL_TW.md plugins/smart/skills/commit/SKILL_JA.md plugins/smart/skills/commit/SKILL_KO.md
git commit -m "$(cat <<'EOF'
feat: improve commit skill description for auto-triggering

EOF
)"
```
