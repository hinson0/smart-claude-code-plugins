# README "Two Ways to Use" Optimization

**Date:** 2026-03-15
**Status:** Reviewed & Approved

## Problem

The README only documents slash commands (`/smart:pr`, etc.) as the usage method. Since v1.2.0, all skills support natural language triggering (e.g. "commit", "push", "create PR"). The README should communicate this simpler usage path to users.

## Goals

1. Add a "Two Ways to Use" section showing both natural language and slash command usage
2. Remove the now-redundant "All Commands" section (its content is absorbed into the new section)
3. Bump plugin version to 1.3.0
4. Update all 5 language versions (EN/CN/TW/JA/KO)

## Design

### Structural change (all 5 READMEs)

Replace the "All Commands" section with "Two Ways to Use". All other sections remain unchanged.

```
Before:                     After:
├── blockquote              ├── blockquote (unchanged)
├── Quick Start             ├── Quick Start (unchanged)
├── How It Works            ├── How It Works (unchanged)
├── All Commands  ← DELETE  ├── Two Ways to Use  ← NEW
├── Requirements            ├── Requirements (unchanged)
├── Author                  ├── Author (unchanged)
└── License                 └── License (unchanged)
```

### New section content

**EN (`README.md`):**
```markdown
## Two Ways to Use

**💬 Just say it** — type naturally in chat:

- "commit" / "提交" → stages & commits with smart grouping
- "push" → check + commit + push
- "create PR" / "发个PR" → check + commit + push + PR

**⌨️ Slash commands** — for when you want to be explicit:

| Command | What it does |
|---|---|
| `/smart:pr [base]` | Full pipeline: check → commit → push → PR (default base: `main`) |
| `/smart:push` | check → commit → push (no PR) |
| `/smart:commit` | Stage & commit only (smart grouping, auto message) |
| `/smart:check` | Run local checks inferred from CI config only |
```

**CN (`README_CN.md`):**
```markdown
## 两种使用方式

**💬 直接说** — 在对话中自然表达：

- "commit" / "提交" / "完成了" → 智能提交
- "push" / "推一下" → check + commit + push
- "发个PR" / "create PR" → check + commit + push + PR

**⌨️ 斜杠命令** — 精确控制：

| 命令 | 作用 |
|---|---|
| `/smart:pr [目标分支]` | 完整流程：check → commit → push → PR（默认目标分支：`main`） |
| `/smart:push` | check → commit → push（不创建 PR） |
| `/smart:commit` | 仅提交（智能分组，自动生成 message） |
| `/smart:check` | 仅运行 CI 配置推断出的本地检查 |
```

**TW (`README_TW.md`):**
```markdown
## 兩種使用方式

**💬 直接說** — 在對話中自然表達：

- "commit" / "提交" / "完成了" → 智慧提交
- "push" / "推一下" → check + commit + push
- "發個PR" / "create PR" → check + commit + push + PR

**⌨️ 斜線指令** — 精確控制：

| 指令 | 作用 |
|---|---|
| `/smart:pr [目標分支]` | 完整流程：check → commit → push → PR（預設目標分支：`main`） |
| `/smart:push` | check → commit → push（不建立 PR） |
| `/smart:commit` | 僅提交（智慧分組，自動產生 message） |
| `/smart:check` | 僅執行 CI 設定推斷出的本機檢查 |
```

**JA (`README_JA.md`):**
```markdown
## 2つの使い方

**💬 話しかけるだけ** — チャットで自然に入力：

- "commit" / "コミットして" → スマートグルーピングでコミット
- "push" / "プッシュして" → check + commit + push
- "PRを作って" / "create PR" → check + commit + push + PR

**⌨️ スラッシュコマンド** — 明示的に指定したい時に：

| コマンド | 機能 |
|---|---|
| `/smart:pr [ターゲットブランチ]` | フルパイプライン：check → commit → push → PR（デフォルト：`main`） |
| `/smart:push` | check → commit → push（PR は作成しない） |
| `/smart:commit` | コミットのみ（スマートグルーピング、メッセージ自動生成） |
| `/smart:check` | CI 設定から推論されたローカルチェックのみ実行 |
```

**KO (`README_KO.md`):**
```markdown
## 두 가지 사용 방법

**💬 그냥 말하세요** — 채팅에서 자연스럽게 입력:

- "commit" / "커밋해" → 스마트 그룹화로 커밋
- "push" / "푸시해" → check + commit + push
- "PR 만들어" / "create PR" → check + commit + push + PR

**⌨️ 슬래시 명령어** — 명시적으로 지정하고 싶을 때:

| 명령어 | 기능 |
|---|---|
| `/smart:pr [대상 브랜치]` | 전체 파이프라인: check → commit → push → PR (기본: `main`) |
| `/smart:push` | check → commit → push (PR 생성 안 함) |
| `/smart:commit` | 커밋만 수행 (스마트 그룹화, 자동 메시지 생성) |
| `/smart:check` | CI 설정에서 추론된 로컬 검사만 실행 |
```

### plugin.json

Update `"version": "1.2.0"` → `"version": "1.3.0"`
