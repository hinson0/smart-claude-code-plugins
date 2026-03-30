# smart-claude-code-plugins

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 코드 작성 끝? **"PR 만들어"**라고 말하면 검사, 커밋, 푸시, PR까지 전부 자동.
>
> PR은 필요 없고 push만? **"푸시해"**.
>
> commit만? **"커밋해"**.
>
> 슬래시 명령어도 사용 가능: `/smart:pr`, `/smart:push`, `/smart:commit`.

Claude Code용 플러그인입니다. 코드 작성이 끝나면 한마디만 하세요 — 자동으로 검사, 커밋, 푸시하고 `main` 브랜치에 Pull Request를 생성합니다. 추가 작업은 필요 없습니다. `push` 한마디면, 다중 feature 자동 분리, commit message 생성, 푸시까지 완료:

![demo](./assets/imgs/to.png)

---

## 빠른 시작

**1. 플러그인 설치** _(강력 추천)_

먼저 Claude Code에서 플러그인 마켓플레이스를 등록합니다:

```
/plugin marketplace add hinson0/smart-claude-code-plugins
```

그다음 해당 마켓플레이스에서 플러그인을 설치합니다:

```
/plugin install smart@smart-claude-code-plugins
```

---

## 주요 기능

**핵심 파이프라인**

- **Fail-Fast 파이프라인** — 어떤 단계든 실패하면 즉시 중단. 불완전한 푸시나 잘못된 PR이 발생하지 않습니다.
- **CI 자동 감지** — `.github/workflows/*.yml`을 읽고 해당하는 로컬 검사를 실행 (ruff, pytest, mypy, eslint, tsc, vitest, jest, go test, turbo 등). lock 파일에서 패키지 매니저를 자동 감지합니다.
- **2단계 스마트 커밋 그룹화** — 1단계에서 type별 강제 분리(feat vs fix vs refactor), 2단계에서 동일 type 내 목적별 의미 분리. 무관한 변경이 하나의 커밋에 섞이는 것을 방지.
- **Conventional Commits** — 모든 commit message가 자동으로 `<type>(<scope>): <description>` 형식을 따릅니다. 프로젝트 `CLAUDE.md` 설정과 기존 `git log` 스타일을 우선 존중합니다.
- **자동 버전 범프** — 버전 파일(`plugin.json`, `package.json`, `pyproject.toml`)을 자동 감지하고, 커밋 유형을 분석하여 푸시 전에 시맨틱 버전을 자동 범프합니다. 모노레포에서는 변경된 파일을 해당 패키지에 매핑하여 각각 독립적으로 범프합니다.
- **GitHub 저장소 자동 생성** — remote 미설정? 자동으로 GitHub에 비공개 저장소를 생성하고 origin으로 설정한 뒤 푸시합니다. 수동 작업이 전혀 필요 없습니다.
- **언어 일관성** — PR 제목, 요약, 테스트 계획이 자동으로 commit message와 동일한 언어를 사용합니다. 기본값은 영어이며, 프로젝트 `CLAUDE.md`로 변경 가능.

**보호 및 자동화**

- **파일 보호 Hook** — Claude가 민감한 파일(`.env`, lock 파일 등)을 편집하지 못하도록 차단합니다. 프로젝트 수준 `.claude/.protect_files.jsonc`로 설정하며, 정확한 파일명 매칭과 glob 패턴(`*`, `**`)을 지원합니다.
- **세션 Hook** — 세션 시작 시 인사, 종료 시 작별 인사 (macOS `say` TTS를 통한 음성 출력).
- **세션 로그** — 모든 도구 호출의 전체 입력 데이터가 `.claude/session-logs/`에 기록되어 사후 디버깅 및 감사에 활용할 수 있습니다.

**유틸리티**

- **시각적 진행 추적** — 파이프라인 단계가 실시간 작업 목록으로 표시되며, 대기/진행 중/완료 상태, 타이밍 및 토큰 통계를 보여줍니다.
- **HUD / Statusline 설치기** — 한 줄 명령어로 모델, Git 브랜치, 컨텍스트 사용량, 속도 제한, 시스템 리소스, 도구 호출 통계를 표시하는 상태 표시줄을 설치합니다. 설치 / 제거 / 초기화를 지원하며, user 또는 project 스코프를 선택할 수 있습니다.
- **도움말 개요** — `/smart:help`로 모든 스킬, 훅, 에이전트를 동적으로 스캔하여 설명과 함께 나열합니다.
- **Joke Teller Agent** — 적절한 타이밍에 프로그래머 농담을 들려주어 업무 스트레스를 해소합니다.

---

## 사용 방법

**💬 자연어** — 채팅에서 원하는 것을 직접 설명:

| 말하는 내용 | 실행 결과 |
|---|---|
| "commit" / "커밋해" / "완료" | 스마트 커밋만 (스테이징 + 그룹화 + 커밋) |
| "push" / "푸시해" | check → commit → version → push |
| "PR 만들어" / "create PR" / "open a pull request" | check → commit → version → push → PR |

**⌨️ 슬래시 명령어** — 정확한 제어:

| 명령어 | 기능 |
|---|---|
| `/smart:commit` | 커밋만 수행 (스마트 그룹화, 자동 메시지 생성) |
| `/smart:version [베이스 브랜치]` | 커밋을 분석하고 버전 범프 (버전 파일 자동 감지; 베이스 브랜치에서만 실행) |
| `/smart:push` | check → commit → version → push (PR 생성 안 함) |
| `/smart:pr [대상 브랜치]` | 전체 파이프라인: check → commit → version → push → PR (기본: `main`) |
| `/smart:hud [rm\|reset]` | 상태 표시줄 설치, 제거 또는 초기화 (`--user` / `--project` 스코프) |
| `/smart:help [skill\|hook\|agent]` | 모든 플러그인 컴포넌트 개요 표시 (또는 카테고리별 필터) |

---

## 파이프라인

### 개요

```
/smart:pr
    │
    ├── 1. check   — CI 자동 감지 및 로컬 실행
    │
    ├── 2. commit  — 2단계 의미 분석 및 스마트 그룹화
    │
    ├── 3. version — 시맨틱 버전 범프 (모노레포 지원)
    │
    ├── 4. push    — origin에 푸시 (필요시 GitHub 저장소 자동 생성)
    │
    └── 5. pr      — Pull Request 생성
```

각 단계는 독립적인 skill이며 `@../path/SKILL.md` 참조로 연결됩니다. 어떤 단계든 실패하면 전체 파이프라인이 즉시 중단됩니다.

### 1단계: Check

프로젝트의 CI 설정을 자동 감지하고 해당 검사를 로컬에서 실행합니다.

**작동 방식:**

1. `.github/workflows/*.yml`을 스캔하여 도구 키워드 식별
2. 매칭 도구: `ruff`, `pytest`, `mypy`, `eslint`, `tsc`, `vitest`, `jest`, `go test`, `golangci-lint`, `turbo` 등
3. lock 파일에서 패키지 매니저 감지 (`uv.lock` → `uv run`, `pnpm-lock.yaml` → `pnpm`, `package-lock.json` → `npm run`, `go.mod` → 직접 실행)
4. 감지된 모든 검사를 순차 실행 — 하나라도 실패하면 파이프라인 중단
5. `ruff --fix`가 실패 전에 문제를 자동 수정하도록 허용

**지원 생태계:**

| 생태계 | 도구 |
|---|---|
| Python | ruff (lint + format), pytest, mypy |
| JavaScript / TypeScript | eslint, tsc, vitest, jest, turbo |
| Go | go test, golangci-lint |

프로젝트에 `.github/workflows/` 디렉토리가 없으면 이 단계는 자동으로 건너뜁니다.

### 2단계: Commit

핵심 인텔리전스 — 모든 대기 중인 변경사항을 분석하고 깔끔하게 그룹화된 커밋을 생성합니다.

**2단계 그룹화 알고리즘:**

1. **type별 강제 분리** — Conventional Commit 유형(`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`)으로 먼저 분류합니다. 다른 type은 **반드시** 별도 커밋이 됩니다.
2. **목적별 의미 분리** — 동일 type 내에서 다른 목적의 변경사항은 추가로 분리됩니다. 예를 들어, 두 개의 독립적인 `feat` 추가는 두 개의 별도 커밋이 됩니다.

`scope` 필드는 "어디를 변경했는지"를 설명하며, 그룹화에는 영향을 주지 않습니다. 그룹화 로직은 순수하게 type + purpose로 결정됩니다.

**Commit message 생성 우선순위:**

1. 프로젝트 `CLAUDE.md` — commit 형식이 지정되어 있으면 우선 사용
2. `git log` 스타일 — 기존 커밋이 일관된 스타일을 따르면 자동 매칭
3. 기본값 — Conventional Commits: `<type>(<scope>): <description>`

**실행 방식:**
- 단일 그룹 → `git add -A` + 커밋
- 다중 그룹 → 그룹별 `git add <특정 파일>` + HEREDOC 커밋
- 작업 트리가 깨끗해질 때까지 반복 (hook이나 formatter가 커밋 중 파일을 수정하는 경우 처리)

### 3단계: Version

커밋 이력을 분석하고 시맨틱 버전 번호를 자동 범프합니다.

**Semver 규칙:**

| 커밋 패턴 | 범프 유형 | 예시 |
|---|---|---|
| `feat` | minor | 0.1.0 → 0.2.0 |
| `fix`, `refactor`, `perf`, `docs` 등 | patch | 0.1.0 → 0.1.1 |
| `BREAKING CHANGE` 또는 `!` 접미사 | major | 0.1.0 → 1.0.0 |

**버전 파일 감지:**

프로젝트 루트와 workspace 디렉토리에서 `plugin.json`, `package.json`, `pyproject.toml`을 자동 스캔합니다.

**모노레포 지원:**

각 변경 파일은 디렉토리 트리를 따라 올라가며 가장 가까운 버전 파일을 찾습니다 ("closest owner" 전략). 각 패키지는 자체 커밋에 기반하여 독립적으로 범프됩니다.

**동작:**
- 베이스 브랜치에서만 실행 (feature 브랜치에서는 자동 건너뜀)
- 마지막 버전 범프 이후 새 커밋이 없으면 건너뜀
- 모든 버전 변경은 단일 `chore(version): bump version to X.X.X`로 커밋

### 4단계: Push

원격 저장소에 커밋을 푸시합니다.

`origin` remote가 설정되지 않은 경우:
1. `gh repo create`를 통해 GitHub에 **비공개** 저장소 생성
2. `origin`으로 설정
3. `git push -u origin HEAD` 실행

### 5단계: PR

GitHub에서 Pull Request를 생성합니다.

**작동 방식:**

1. 현재 브랜치와 언어를 감지 (commit 단계의 언어 결정을 계승하거나 `git log`에서 추론)
2. 프롬프트를 통해 대상 브랜치 확인 (기본값 `main`)
3. 동일한 head branch의 오픈 PR이 있는지 확인 — 있으면 URL을 표시하고 중단
4. `BASE_BRANCH..HEAD` 사이의 모든 커밋 수집
5. PR 제목 생성:
   - 단일 커밋 → commit message를 직접 사용
   - 다중 커밋 → 요약 제목 생성
6. Markdown 형식의 PR 본문 생성:
   - **Summary** — 변경사항 설명 요점
   - **Commits** — 전체 커밋 목록
   - **Test Plan** — 커밋 유형에 따라 `- [ ]` 체크리스트 자동 생성 (예: `feat` → "verify new feature works", `fix` → "confirm bug is resolved")
7. `gh pr create`를 통해 PR 생성

PR 제목, 본문, 테스트 계획의 언어는 commit message와 일치합니다.

---

## 파일 보호

프로젝트 루트에 `.claude/.protect_files.jsonc`를 생성하여 Claude가 민감한 파일을 편집하지 못하도록 차단합니다:

```jsonc
// 보호 대상 파일 목록 — Claude Code가 편집할 수 없습니다
// 와일드카드가 없으면 정확한 파일명 매칭, * 또는 **가 있으면 glob 패턴 매칭
[
  ".env",
  "package-lock.json",
  "pnpm-lock.yaml",
  "yarn.lock",
  "*.secret",
  "config/production/**"
]
```

**매칭 규칙:**

| 패턴 | 매칭 방식 | 예시 |
|---|---|---|
| 와일드카드 없음 | 정확한 파일명 | `.env`는 `.env`를 차단하지만 `.env.example`은 허용 |
| `*` | 단일 디렉토리 glob | `*.lock`은 `pnpm-lock.yaml`과 매칭 |
| `**` | 디렉토리 횡단 재귀 | `config/production/**`은 `config/production/db/secret.json`과 매칭 |

이 hook은 `PreToolUse`를 통해 `Edit`과 `Write` 도구 호출을 가로챕니다. 보호 대상 파일이 매칭되면 작업이 차단되고 오류 메시지가 반환됩니다.

---

## HUD (상태 표시줄)

한 줄 명령어로 기능이 풍부한 상태 표시줄을 설치합니다:

```
/smart:hud
```

![hud](./assets/imgs/hud.png)

**표시 내용 (6줄):**

| 줄 | 내용 |
|----|------|
| 1 | 세션 ID / 세션 이름, 모델@버전, 총 비용 (USD) |
| 2 | 디렉토리, Git 브랜치 (dirty/ahead/behind/stash), 최근 커밋 시간, worktree 이름, 배터리 |
| 3 | 컨텍스트 진행 바 + 토큰 + 캐시, 속도 제한 (5h/7d) 리셋 카운트다운, 세션 시간, agent 이름 |
| 4 | CPU, 메모리, 디스크, 가동 시간, 런타임 버전 (Node/Python/Go/Rust/Ruby), 로컬 IP |
| 5 | 도구 호출 통계 (Bash/Skill/Agent/Edit 횟수, transcript에서 실시간 파싱) |
| 6 | 출력 스타일, vim 모드 (활성화 시에만 표시) |

**명령어:**

| 명령어 | 동작 |
|--------|------|
| `/smart:hud` | user 스코프에 설치 (기존 상태 표시줄 자동 백업) |
| `/smart:hud --project` | project 스코프에 설치 (`.claude/settings.json`, 현재 프로젝트만) |
| `/smart:hud rm` | 상태 표시줄 제거 (설치된 스코프 자동 감지) |
| `/smart:hud reset` | 백업에서 이전 상태 표시줄 복원 |

**참고:** `jq`가 필요합니다. 상태 표시줄 스크립트는 macOS에 최적화되어 있습니다 (`pmset`으로 배터리, `sysctl`로 시스템 정보 확인).

---

## Agents

### 농담 전달자 (Joke Teller)

프로그래머 농담을 들려주어 업무 스트레스를 해소합니다.

```
"tell me a joke" / "농담 해줘" / "I need a laugh"
```

- 대화 언어를 자동 감지하여 해당 언어로 농담을 전달
- 짧은 형식 (2–4문장, 펀치라인 스타일 — Q&A 형식 아님)
- 부드러운 셀프케어 알림 포함 (수분 섭취, 스트레칭, 휴식)

---

## 세션 Hooks

세션 경계와 도구 호출 시 트리거되는 hook이 포함되어 있습니다:

| Hook | 트리거 | 기능 |
|------|--------|------|
| `greet.sh` | `SessionStart` | macOS TTS (`say`)를 통해 환영 메시지 재생 |
| `goodbye.sh` | `SessionEnd` | macOS TTS (`say`)를 통해 작별 메시지 재생 |
| `session-logs.py` | `PreToolUse` (모든 도구) | 모든 도구 호출의 전체 입력을 `.claude/session-logs/<날짜>/<session_id>.json`에 기록 |
| `protect-files.py` | `PreToolUse` (Edit/Write) | 보호 대상 파일 편집 차단 ([파일 보호](#파일-보호) 참조) |

모든 hook은 `${CLAUDE_PLUGIN_ROOT}`를 통해 경로를 해석합니다. TTS hook은 백그라운드에서 실행되어 (`nohup &`) Claude Code를 차단하지 않습니다.

---

## 사전 요구 사항

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — 푸시 (원격 자동 생성) 및 PR 생성에 사용
- `jq` — HUD 상태 표시줄에만 필요 (다른 기능은 불필요)

---

## 저자

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
