# Commit Splitting Enforcement Design

## Problem

When the commit skill runs as part of the `/pr` or `/push` pipeline, Claude frequently fails to split unrelated changes into separate commits. Instead, it bundles everything under a single vague commit like:

```
refactor(mobile): replace gesture-based sheet with native Modal
- Replace react-native-gesture-handler swipe-to-dismiss with RN Modal
- Await chat_messages insert in manual entry API for data consistency
- Add expo-localization and expo-web-browser plugins
- Add .prettierrc configuration
```

This commit mixes 3 different types (refactor + fix + chore) and 4 distinct purposes, violating the skill's own splitting rules.

### Root Causes

1. **Invisible analysis** — Step 3's semantic analysis is an internal thinking step. Claude can skip or abbreviate it without anyone noticing.
2. **Pipeline attention decay** — When invoked via `/pr` (check → commit → push → PR), Claude rushes through commit analysis to reach the end goal.
3. **Scope-as-umbrella** — Claude invents a scope (e.g., `mobile`) and uses it to rationalize grouping unrelated changes.
4. **Easy escape hatch** — "If grouping fails... combine into a single commit" gives Claude an easy way out.

## Solution: Approach A + C

### A. Forced Structured Output in Step 3

Replace the current step 3 with a version that mandates terminal output:

#### New Step 3

```
3) Semantic analysis (CRITICAL — you MUST output the analysis, not just think it):

  a. Output a file-purpose table (mandatory, cannot be skipped):
     Print a markdown table to the terminal:
     | File | Purpose | Type |
     |------|---------|------|
     | src/sheet.tsx | replace gesture sheet with Modal | refactor |
     | src/api/entry.ts | await insert for data consistency | fix |
     | app.json | add expo plugins | chore |
     | .prettierrc | add prettier config | chore |

  b. Count distinct values in the Type column:
     - 1 type → single commit
     - 2+ types → multiple commits (MANDATORY, no exceptions)

  c. If multiple commits: output the grouping plan:
     Group 1 (refactor): src/sheet.tsx, src/layout.tsx
     Group 2 (fix): src/api/entry.ts
     Group 3 (chore): app.json, .prettierrc

  d. Proceed to step 4 with this grouping.
```

#### Escape Hatch Restriction

Replace:
> "If grouping fails or there is strong coupling that prevents safe splitting, combine into a single commit and explain the reason."

With:
> "Only combine groups if files have circular dependencies that make separate commits impossible (e.g., file A in group 1 imports a new export from file B in group 2 that doesn't exist yet). You must list the specific dependency chain to justify combining."

#### Negative Examples

Add to step 3:

```
❌ WRONG — bundling unrelated changes under a vague scope:
  | File | Purpose | Type |
  | src/sheet.tsx | mobile improvements | refactor |
  | src/api/entry.ts | mobile improvements | refactor |
  | .prettierrc | mobile improvements | refactor |
  → single commit: "refactor(mobile): various improvements"

✅ CORRECT — splitting by actual purpose:
  | File | Purpose | Type |
  | src/sheet.tsx | replace gesture sheet with Modal | refactor |
  | src/api/entry.ts | await insert for data consistency | fix |
  | .prettierrc | add prettier config | chore |
  → 3 commits, one per type
```

### Commit Message Format Update (scope support)

Update step 4 default format:

```
Default format: <type>(<scope>): <description>
- scope is OPTIONAL — use it when changes are scoped to a specific
  package, module, or area (e.g., mobile, api, auth, shared)
- scope describes WHERE, not WHY — it must NOT be used to group
  unrelated changes
- Splitting is ALWAYS determined by type (step 3), never by scope.
  Same scope + different types = multiple commits.
```

Negative example for scope misuse:

```
❌ WRONG — scope used as grouping umbrella:
  refactor(mobile): replace sheet, fix data consistency, add plugins

✅ CORRECT — same scope, split by type:
  refactor(mobile): replace gesture-based sheet with native Modal
  fix(mobile): await chat_messages insert for data consistency
  chore(mobile): add expo-localization and expo-web-browser plugins
  chore: add prettierrc configuration
```

### C. Pipeline-Level Isolation

#### 1. Commit Skill — Pipeline Awareness Declaration

Add before step 1:

```
IMPORTANT: This skill may run standalone or as part of a pipeline
(push/pr). Regardless of context, every step — especially the
semantic analysis in step 3 — MUST be executed fully. Do not
abbreviate or skip steps because there are subsequent phases to run.
```

#### 2. Push Skill — Anchor Around Commit Reference

Update the Phase 2 section in push/SKILL.md:

```
## Phase 2: Commit

⚠️ The commit skill below contains a CRITICAL semantic analysis step.
Execute it completely — output the file-purpose table and splitting
decision before running any git commands.

@../commit/SKILL.md

⚠️ Verify: the commit(s) above must match the grouping from the
semantic analysis. If you committed everything in one shot but the
analysis showed multiple types, STOP and redo.
```

## Files to Modify

1. `plugins/smart/skills/commit/SKILL.md` — Step 3 rewrite, step 4 format update, pipeline awareness
2. `plugins/smart/skills/commit/SKILL_CN.md` — Sync translation
3. `plugins/smart/skills/commit/SKILL_TW.md` — Sync translation
4. `plugins/smart/skills/commit/SKILL_JA.md` — Sync translation
5. `plugins/smart/skills/commit/SKILL_KO.md` — Sync translation
6. `plugins/smart/skills/push/SKILL.md` — Pipeline anchor for commit phase
7. `plugins/smart/skills/push/SKILL_CN.md` — Sync translation
8. `plugins/smart/skills/push/SKILL_TW.md` — Sync translation
9. `plugins/smart/skills/push/SKILL_JA.md` — Sync translation
10. `plugins/smart/skills/push/SKILL_KO.md` — Sync translation

## Success Criteria

- When changes span multiple conventional commit types, the skill always produces separate commits per type
- The file-purpose table is visible in terminal output, not hidden in internal reasoning
- Scope (`<type>(scope):`) is supported but never overrides type-based splitting
- Pipeline execution (via `/push` or `/pr`) produces the same splitting quality as standalone `/commit`
