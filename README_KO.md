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

## 주요 기능

- **2단계 스마트 커밋 그룹화** — 1단계에서 type별 강제 분리(feat vs fix vs refactor), 2단계에서 동일 type 내 목적별 의미 분리. 무관한 변경이 하나의 커밋에 섞이는 것을 방지.
- **Fail-Fast 파이프라인** — 어떤 단계든 실패하면 즉시 중단. 불완전한 푸시나 잘못된 PR이 발생하지 않습니다.
- **CI 자동 감지** — `.github/workflows/*.yml`을 읽고 해당하는 로컬 검사 실행 (ruff, pytest, eslint, tsc, jest, go test, turbo 등).
- **GitHub 저장소 자동 생성** — remote 미설정? 자동으로 생성합니다.
- **Conventional Commits** — 모든 commit message가 자동으로 `<type>(<scope>): <description>` 형식을 따릅니다.
- **언어 일관성** — PR 제목, 요약, 테스트 계획이 자동으로 commit message와 동일한 언어를 사용합니다. 기본값은 영어이며, 프로젝트 `CLAUDE.md`로 변경 가능.
- **파일 보호 Hook** — Claude가 민감한 파일(`.env`, lock 파일 등)을 편집하지 못하도록 차단합니다. 프로젝트 수준 `.claude/.protect_files.jsonc`로 설정하며, 정확한 파일명 매칭과 glob 패턴(`*`, `**`)을 지원합니다.
- **세션 Hook** — 세션 시작 시 인사, 종료 시 작별 인사.
- **컨텍스트 분석 Agent** — 어떤 플러그인이 가장 많은 컨텍스트 윈도우를 차지하는지 분석하여, 크기별 순위 테이블과 비율을 표시합니다.

---

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
| `/smart:check` | 로컬 CI 검사만 실행 (workflow 설정 자동 감지) |

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

**2. GitHub CLI 로그인** _(최초 1회만)_

```bash
gh auth login
```

**3. 완료. 아무 저장소에서 실행하세요:**

```
/smart:pr
```

자동으로 수행됩니다: CI 설정 감지 후 로컬 검사 실행 → 스마트 커밋 → 푸시 → GitHub에서 PR 생성.

---

## 작동 방식

```
/smart:pr
    │
    ├── 1. check   — .github/workflows/*.yml을 읽고 해당하는 로컬 검사 실행
    │                (ruff/pytest, eslint/tsc, go test — CI 설정 없으면 건너뜀)
    │
    ├── 2. commit  — 2단계 의미 분석:
    │                1단계: type별 강제 분리 (feat/fix/refactor/...)
    │                2단계: 동일 type 내 목적별 분리
    │                (Conventional Commit message 자동 생성)
    │
    ├── 3. push    — origin으로 푸시
    │                (remote 미설정 시 자동으로 GitHub 저장소 생성 및 연결)
    │
    └── 4. pr      — 제목과 본문을 자동 생성하여 Pull Request 생성
                     (언어는 2단계의 commit message를 따름)
```

어떤 단계든 실패하면 즉시 중단되며, 이후 단계는 실행되지 않습니다.

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
- 와일드카드 없음 → 정확한 파일명 매칭 (`.env`는 `.env`를 차단하지만 `.env.example`은 허용)
- `*` → 단일 디렉토리 수준 glob 매칭 (`*.lock`은 `pnpm-lock.yaml`과 매칭)
- `**` → 디렉토리를 넘나드는 재귀 매칭 (`config/production/**`은 `config/production/db/secret.json`과 매칭)

---

## 사전 요구 사항

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — GitHub remote 자동 생성 및 PR 생성에 사용

---

## 저자

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
