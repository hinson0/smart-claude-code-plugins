# Commit Message 格式规范实现计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 commit skill 的步骤 4 中内联默认的 commit message 格式规范（conventional commits），并支持项目 CLAUDE.md 覆盖。

**Architecture:** 修改 5 个语言版本的 SKILL 文件中步骤 4 的内容，用结构化格式规范替换原有的"风格与最近提交保持一致"描述。不新增文件，不修改其他步骤。

**Tech Stack:** Markdown (skill 文件)

---

## Chunk 1: 修改所有语言版本的步骤 4

### Task 1: 修改 SKILL.md（英文版）

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL.md:33-39`

- [ ] **Step 1: 替换步骤 4 内容**

将第 33-39 行：

```markdown
4) Generate commit message (in English):
- Single feature:
  - Generate a 1-sentence English commit message based on the changes, keeping the style consistent with recent commits.
  - The message should focus on "why the change was made", avoiding vague descriptions.
- Multiple features:
  - Group changes by feature (prefer grouping by directory/module boundaries).
  - Generate a 1-sentence English commit message for each feature, focusing on "why the change was made".
```

替换为：

```markdown
4) Generate commit message:
- **Default format (used when project CLAUDE.md does not define a custom commit format):**
  - Format: `<type>: <description>`
  - Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
  - Description rules: start with lowercase letter, no trailing period, total line length (including type prefix) must not exceed 72 characters
  - Language: English by default
  - Focus on "why the change was made", avoid vague descriptions
- **Project override:** If the project's CLAUDE.md defines custom commit message format or language requirements, follow the project's rules and ignore the defaults above.
- Single feature:
  - Generate 1 commit message following the rules above.
- Multiple features:
  - Group changes by feature (prefer grouping by directory/module boundaries).
  - Generate 1 commit message per feature following the rules above.
```

- [ ] **Step 2: 验证修改**

Run: `head -45 plugins/smart/skills/commit/SKILL.md`
Expected: 步骤 4 包含新的格式规范，不再包含 "keeping the style consistent with recent commits"

---

### Task 2: 修改 SKILL_CN.md（简体中文版）

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_CN.md:33-39`

- [ ] **Step 1: 替换步骤 4 内容**

将第 33-39 行：

```markdown
4) 生成 commit message（英文）：
- 单 feature：
  - 基于改动生成 1 句英文 commit message，风格与最近提交保持一致。
  - message 要聚焦"为什么改"，避免空泛。
- 多 feature：
  - 按 feature 将改动分组（优先按目录/模块边界分组）。
  - 每个 feature 生成 1 句英文 commit message，聚焦"为什么改"。
```

替换为：

```markdown
4) 生成 commit message：
- **默认格式（当项目 CLAUDE.md 未定义自定义 commit 格式时使用）：**
  - 格式：`<type>: <description>`
  - 允许的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description 规则：首字母小写、不以句号结尾、整行长度（含 type 前缀）不超过 72 字符
  - 语言：默认英文
  - 聚焦"为什么改"，避免空泛描述
- **项目覆盖：** 如果项目 CLAUDE.md 中定义了自定义 commit message 格式或语言要求，以项目规范为准，忽略上述默认规则。
- 单 feature：
  - 按上述规则生成 1 条 commit message。
- 多 feature：
  - 按 feature 将改动分组（优先按目录/模块边界分组）。
  - 每个 feature 按上述规则生成 1 条 commit message。
```

- [ ] **Step 2: 验证修改**

Run: `head -45 plugins/smart/skills/commit/SKILL_CN.md`
Expected: 步骤 4 包含新的格式规范

---

### Task 3: 修改 SKILL_TW.md（繁体中文版）

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_TW.md:33-39`

- [ ] **Step 1: 替换步骤 4 内容**

将第 33-39 行：

```markdown
4) 生成 commit message（英文）：
- 單 feature：
  - 基於改動生成 1 句英文 commit message，風格與最近提交保持一致。
  - message 要聚焦「為什麼改」，避免空泛。
- 多 feature：
  - 按 feature 將改動分組（優先按目錄/模組邊界分組）。
  - 每個 feature 生成 1 句英文 commit message，聚焦「為什麼改」。
```

替换为：

```markdown
4) 生成 commit message：
- **預設格式（當專案 CLAUDE.md 未定義自訂 commit 格式時使用）：**
  - 格式：`<type>: <description>`
  - 允許的 type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description 規則：首字母小寫、不以句號結尾、整行長度（含 type 前綴）不超過 72 字元
  - 語言：預設英文
  - 聚焦「為什麼改」，避免空泛描述
- **專案覆蓋：** 若專案 CLAUDE.md 中定義了自訂 commit message 格式或語言要求，以專案規範為準，忽略上述預設規則。
- 單 feature：
  - 按上述規則生成 1 條 commit message。
- 多 feature：
  - 按 feature 將改動分組（優先按目錄/模組邊界分組）。
  - 每個 feature 按上述規則生成 1 條 commit message。
```

- [ ] **Step 2: 验证修改**

Run: `head -45 plugins/smart/skills/commit/SKILL_TW.md`
Expected: 步骤 4 包含新的格式规范

---

### Task 4: 修改 SKILL_JA.md（日文版）

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_JA.md:33-39`

- [ ] **Step 1: 替换步骤 4 内容**

将第 33-39 行：

```markdown
4) commit message を生成（英語で）：
- 単一 feature：
  - 変更内容に基づいて1文の英語 commit message を生成し、最近のコミットとスタイルを統一します。
  - message は「なぜ変更したか」に焦点を当て、曖昧な記述を避けます。
- 複数 feature：
  - feature ごとに変更をグループ化します（ディレクトリ/モジュール境界での分類を優先）。
  - 各 feature について「なぜ変更したか」に焦点を当てた1文の英語 commit message を生成します。
```

替换为：

```markdown
4) commit message を生成：
- **デフォルト形式（プロジェクトの CLAUDE.md にカスタム commit 形式が定義されていない場合に使用）：**
  - 形式：`<type>: <description>`
  - 許可される type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description ルール：先頭は小文字、末尾にピリオドなし、行全体の長さ（type プレフィックスを含む）は72文字以内
  - 言語：デフォルトは英語
  - 「なぜ変更したか」に焦点を当て、曖昧な記述を避けること
- **プロジェクトによるオーバーライド：** プロジェクトの CLAUDE.md にカスタム commit message 形式または言語要件が定義されている場合、プロジェクトのルールに従い、上記デフォルトは無視すること。
- 単一 feature：
  - 上記ルールに従って commit message を1つ生成します。
- 複数 feature：
  - feature ごとに変更をグループ化します（ディレクトリ/モジュール境界での分類を優先）。
  - 各 feature について上記ルールに従って commit message を1つ生成します。
```

- [ ] **Step 2: 验证修改**

Run: `head -50 plugins/smart/skills/commit/SKILL_JA.md`
Expected: 步骤 4 包含新的格式规范

---

### Task 5: 修改 SKILL_KO.md（韩文版）

**Files:**
- Modify: `plugins/smart/skills/commit/SKILL_KO.md:33-39`

- [ ] **Step 1: 替换步骤 4 内容**

将第 33-39 行：

```markdown
4) commit message 생성 (영어로):
- 단일 feature:
  - 변경사항을 기반으로 1문장 영어 commit message를 생성하며, 최근 커밋과 스타일을 일관되게 유지합니다.
  - message는 "왜 변경했는지"에 초점을 맞추고, 모호한 설명을 피합니다.
- 다중 feature:
  - feature별로 변경사항을 그룹화합니다 (디렉토리/모듈 경계 기준 우선).
  - 각 feature에 대해 "왜 변경했는지"에 초점을 맞춘 1문장 영어 commit message를 생성합니다.
```

替换为：

```markdown
4) commit message 생성:
- **기본 형식 (프로젝트 CLAUDE.md에 사용자 정의 commit 형식이 정의되지 않은 경우 사용):**
  - 형식: `<type>: <description>`
  - 허용 type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
  - description 규칙: 첫 글자 소문자, 마침표로 끝나지 않음, 전체 줄 길이(type 접두사 포함) 72자 이내
  - 언어: 기본값은 영어
  - "왜 변경했는지"에 초점을 맞추고, 모호한 설명을 피할 것
- **프로젝트 오버라이드:** 프로젝트 CLAUDE.md에 사용자 정의 commit message 형식 또는 언어 요구사항이 정의되어 있으면, 프로젝트 규칙을 따르고 위의 기본값을 무시합니다.
- 단일 feature:
  - 위 규칙에 따라 commit message를 1개 생성합니다.
- 다중 feature:
  - feature별로 변경사항을 그룹화합니다 (디렉토리/모듈 경계 기준 우선).
  - 각 feature에 대해 위 규칙에 따라 commit message를 1개 생성합니다.
```

- [ ] **Step 2: 验证修改**

Run: `head -45 plugins/smart/skills/commit/SKILL_KO.md`
Expected: 步骤 4 包含新的格式规范

---

### Task 6: 提交所有修改

- [ ] **Step 1: 提交**

```bash
git add plugins/smart/skills/commit/SKILL.md plugins/smart/skills/commit/SKILL_CN.md plugins/smart/skills/commit/SKILL_TW.md plugins/smart/skills/commit/SKILL_JA.md plugins/smart/skills/commit/SKILL_KO.md
git commit -m "$(cat <<'EOF'
feat: add default commit message format rules to commit skill

EOF
)"
```

- [ ] **Step 2: 验证提交**

Run: `git log -1 --oneline && git status`
Expected: 提交成功，工作区干净
