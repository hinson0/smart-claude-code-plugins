# smart-codex-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> 코딩이 끝나면 Claude Code에서 **`/smart:commit`**을, Codex에서 **`$smart:commit`**을 실행하세요.

**Claude Code**와 **Codex**를 모두 지원하며 개발 워크플로, 콘텐츠 도구, 세션 유틸리티와 엔지니어링 규칙을 제공하는 플러그인입니다.

---

## 빠른 시작

플러그인은 **두 가지 매니페스트를 모두 내장**합니다(Claude Code용 `.claude-plugin/`, Codex용 `.codex-plugin/`). 두 호스트 어느 쪽에서도 네이티브로 설치됩니다. 사용하는 호스트를 선택하세요:

### Claude Code

마켓플레이스를 추가한 뒤 플러그인을 설치합니다 — Claude Code 안에서 실행:

```
/plugin marketplace add hinson0/smart-claude-code-plugins
/plugin install smart@smart
```

> 이미 로컬에 clone했나요? 마켓플레이스를 클론 경로로 지정하세요: `/plugin marketplace add /path/to/smart-claude-code-plugins`. 설치 후 세션을 재시작하면 skills, hooks, statusline이 로드됩니다.

### Codex

가장 편한 방법은 Codex 세션 안에서 바로 추가하는 것입니다 — clone 불필요:

1. `/plugins` 실행
2. **[Add Marketplace]** 선택
3. 소스를 붙여넣기 — `hinson0/smart-claude-code-plugins`(owner/repo) 또는 전체 git URL — 후 Enter
4. **Smart** 마켓플레이스를 열고 **smart** 플러그인을 설치

> CLI를 선호하나요? Git에서 바로 가져오므로 clone이 필요 없습니다:
>
> ```bash
> codex plugin marketplace add hinson0/smart-claude-code-plugins
> codex plugin add smart@smart
> ```

---

## 이 Marketplace의 플러그인

이 저장소는 Claude Code와 Codex를 모두 지원하는 하나의 플러그인을 배포합니다.

| 플러그인 | 설치 이름 | 용도 |
|----------|-----------|------|
| Smart | `smart@smart` | 개발 워크플로, HTML/PDF/Wiki 도구, 주간 보고서, 세션 유틸리티 |

Claude Code는 `/smart:*`를 사용하고 Codex는 대응하는 `$smart:*` skills를 제공합니다.

```bash
# Claude Code: marketplace를 추가한 뒤 실행
/plugin install smart@smart

# Codex: marketplace를 추가한 뒤 실행
codex plugin add smart@smart
```

Smart는 `ask`, `close-issue`, `code-simplifier`, `commit`, `generate-wiki`, `github-skills-pdf`,
`help`, `html`, `hud`, `learning`, `local`, `matt-implement-all-tickets`,
`my-weekly`, `one-by-one`, `pair-write`, `show`의 열여섯 개 skill을 포함합니다.
일부 흐름은 Git, `gh`, `glab`, Node.js, Python/PDF 도구,
브라우저 또는 문서 기능이 필요하며 각 skill은 자체 전제 조건을 확인합니다.
모든 skill은 사용자가 직접 호출해야 합니다. 모델의 자동 호출에 의존하지 말고
해당 `/smart:*` 또는 `$smart:*` 이름을 명시적으로 사용하세요.
Codex UI는 Claude Code의 원래 호출 이름에서 `/`만 뺀 `smart:<name>`을 표시하며 별도 제목으로 바꾸지 않습니다.

---

## 주요 기능

**Smart Commit**

- **저비용 실행** — Claude Code는 Haiku를 사용합니다. Codex는 전체 커밋 워크플로를 low reasoning GPT-5.6 Luna worker 하나에 맡기며 기본 서브 에이전트 폴백은 한 번만 허용합니다.
- **의미 기반 그룹화** — type은 하드 경계, purpose는 소프트 경계이며 독립 변경은 독립 커밋이 됩니다.
- **저장소 인식 message** — 프로젝트 규칙, 최근 Git 기록, Conventional Commits 순서로 따릅니다.
- **커밋 전용** — CI 검사, 버전 변경, push, PR 생성을 실행하지 않습니다.

**보호 및 자동화**

- **세션 Hook** — 세션 시작 시 인사 (macOS `say` TTS를 통한 음성 출력).
- **세션 로그** — 모든 도구 호출의 전체 입력 데이터가 `.smart/session-logs/`에 기록되어 사후 디버깅 및 감사에 활용할 수 있습니다.
- **직렬 Ticket 전달** — `/smart:matt-implement-all-tickets`를 Matt `/implement`와 함께 명시적으로 로드하면 하나의 오케스트레이터 세션이 새 worker를 차례로 실행해 현재 `/to-tickets` 출력의 각 Ticket을 구현, 검증, 기록하고 닫습니다. 구성된 GitHub, GitLab, 로컬 Markdown tracker를 지원하며 첫 미완료 마감에서 중단합니다.
- **감사 가능한 GitLab Issue 마감** — `/implement`가 구현을 commit하고 Review를 완료한 뒤 `/smart:close-issue`는 현재 브랜치의 구현 commit, 인수 증거, Review 결론을 확인합니다. 명시적인 종료 승인이 있으면 해당 개발 자산을 게시한 뒤 Issue를 닫습니다. 대상 브랜치 통합은 공개할 경계일 뿐 종료 조건이 아닙니다. `glab`만 사용하며 push, merge, MR/PR 생성, checklist 또는 label 변경 권한을 포함하지 않습니다.

**유틸리티**

- **시각적 진행 추적** — 파이프라인 단계가 실시간 작업 목록으로 표시되며, 대기/진행 중/완료 상태, 타이밍 및 토큰 통계를 보여줍니다.
- **HUD / Statusline 설치기** — 한 줄 명령어로 모델, Git 브랜치, 컨텍스트 사용량, 속도 제한, 시스템 리소스, 도구 호출 통계를 표시하는 상태 표시줄을 설치합니다. 두 가지 설치 레벨(최소 / 전체)과 백업 복원을 지원하며, user 스코프만 지원합니다.
- **도움말 개요** — `/smart:help`로 모든 스킬, 훅, 에이전트를 동적으로 스캔하여 설명과 함께 나열합니다.
- **읽기 전용 안내** — `/smart:ask`는 파일이나 도구를 변경하지 않고 간결한 판단, 명령, 코드 조각 또는 체크리스트를 반환합니다.
- **새 컨텍스트 코드 단순화** — `/smart:code-simplifier`는 전체 실행을 대화 기록이 없는 직렬 비재귀 worker 하나에 맡깁니다. 기본 agent는 대상 코드를 다루지 않으며, worker가 최근 변경 범위를 정하고 저장소 규칙을 따르며 동작 동등성을 입증합니다.
- **단일 Cycle TDD** — `/smart:one-by-one`은 최소 Red 하나를 검증한 뒤 대응하는 Green 구현을 안내합니다.
- **페어 라이팅** — `/smart:pair-write`는 사용자가 작성할 한 단계에 주석 골격과 펼쳐진 전체 참고 구현을 제공하며, 기본적으로 작성 정확성과 안내와의 일치만 확인합니다.
- **Markdown to HTML** — `/smart:html`은 Markdown을 안전한 자체 완결형 HTML로 결정적으로 변환하며 브라우저를 자동으로 열지 않습니다.
- **Wiki 생성** — `/smart:generate-wiki`는 자료를 GitLab, GitHub 또는 로컬 Markdown Wiki로 정리하고 안전하게 게시합니다.
- **이중 언어 Skills PDF** — `/smart:github-skills-pdf`는 GitHub skills 저장소를 고정하고 검증된 영중 A4 핸드북을 만듭니다.
- **개인 주간 보고서** — `/smart:my-weekly`는 선택한 자연 주의 현재 사용자 Git 커밋을 요약합니다.
- **내장 코딩 규칙** — 사전 작성된 규칙 파일(예: Pydantic V2 표준)이 `rules/`에 저장됩니다. 프로젝트의 `.claude/rules/`에 심볼릭 링크를 생성하면 활성화됩니다.
- **학습 모드** — `/smart:learning 1`은 *당신이* 코드를 직접 손으로 작성하는 간단한 협업 코딩 모드를 켭니다. 비율도 설정도 없는 단순한 켜기/끄기 스위치입니다. 켜져 있는 동안 Claude가 작성할 코드는 대신 콘솔로 출력됩니다 — 각 조각은 새 파일 / 새 코드 / 수정 / 삭제로 파일과 위치와 함께 표시되어 — 당신이 입력하고, Claude는 당신이 저장한 코드를 검토한 뒤 다음으로 넘어갑니다(한 번에 한 작업). 켜면 규칙이 `.claude/CLAUDE.local.md`(Claude Code가 매 세션 로드하는 git-ignore된 프로젝트별 메모리)에 주입되어 지속되며, 그 블록의 존재 자체가 전체 상태이고, `/smart:learning 0`이 그것을 제거합니다. `.smart/settings.json`에는 아무것도 저장되지 않습니다.
- **HTML 리뷰 페이지** — `/smart:show`는 긴 산출물 — 현재 대화의 계획/분석/리뷰 또는 Markdown 파일 — 을 단일 파일, 제로 JavaScript의 자체 완결형 HTML 리뷰 페이지로 렌더링해 브라우저로 엽니다. 회색 배경 + 흰 카드 비주얼 시스템: 고정 목차, 번호 섹션, 리스크 배지, 대안 비교 카드(선택안 강조), 인라인 SVG 다이어그램, `<details>` 접기. 세 가지 고정 레이아웃 레시피(plan-review / explainer / report)가 페이지 구조의 일관성을 보장합니다. 모든 페이지는 출처 푸터(시간, commit SHA, 소스)를 필수로 포함하며 파생 뷰일 뿐 — Markdown이 여전히 사실의 원천입니다. 실행할 때마다 `.smart/pages/`(git-ignore)에 타임스탬프가 붙은 새 파일을 쓰며, 이전 페이지를 덮어쓰지 않고 불변 리뷰 자산으로 보존합니다. 데모는 `assets/demos/` 참고.

---

## 사용 방법

**💬 명시적 호출** — 각 skill은 사용자가 이름을 지정할 때만 시작합니다.
Claude Code에서는 `/smart:*`, Codex에서는 `$smart:*`를 사용하세요.

**⌨️ Skill 명령어** — Codex에서는 `/smart:`를 `$smart:`로 바꾸세요:

| 명령어 | 기능 |
|---|---|
| `/smart:commit` | 커밋만 수행 (스마트 그룹화, 자동 메시지 생성) |
| `/smart:ask` | 실행이나 변경 없이 간결한 읽기 전용 안내 반환 |
| `/smart:close-issue <IID-or-URL>` | 단일 GitLab Issue를 읽기 전용으로 확인하고, 명시적 종료 승인 후 감사 가능한 개발 자산 note를 게시한 다음 닫기 |
| `/smart:code-simplifier [paths-or-diff]` | 새 컨텍스트 worker 하나로 관찰 가능한 동작을 유지하며 최근 코드 단순화 |
| `/smart:matt-implement-all-tickets` | Matt `/implement`를 명시적으로 로드한 뒤 현재 `/to-tickets` 출력을 직렬로 구현하고 닫기 |
| `/smart:generate-wiki` | 자료를 보호된 GitLab, GitHub 또는 로컬 Wiki로 정리 |
| `/smart:github-skills-pdf [--notes 2\|4]` | GitHub skills 저장소에서 검증된 영중 A4 핸드북 생성 |
| `/smart:html <input.md> [output.html]` | Markdown을 안전한 자체 완결형 HTML로 변환 |
| `/smart:hud [0\|1\|2\|reset\|normal\|all]` | 상태 표시줄 설치 (`1`/`normal`=최소, `2`/`all`=전체) 또는 백업 복원 (`0`/`reset`), user 스코프 |
| `/smart:help [skill\|hook\|agent]` | 모든 플러그인 컴포넌트 개요 표시 (또는 카테고리별 필터) |
| `/smart:learning [0\|1]` | 학습 모드 토글 — *당신이* 코드를 직접 작성; Claude가 각 조각을 새 파일 / 새 코드 / 수정 / 삭제로 표시해 콘솔에 출력하면 당신이 입력하고, 저장한 코드를 검토. `1`=켜기, `0`=끄기, 비어 있음=상태. 상태는 `.claude/CLAUDE.local.md`에 주입된 블록 — 설정도 비율도 없음 |
| `/smart:my-weekly <repo> [-N]` | 선택한 자연 주의 현재 사용자 Git 커밋 요약 |
| `/smart:one-by-one` | 한 번에 하나의 최소 Red-to-Green Cycle 실행 |
| `/smart:pair-write` | 사용자가 한 단계를 작성하도록 안내한 뒤 저장된 코드를 골격 및 참고 구현과 비교 |
| `/smart:show [<path>.md]` | 현재 대화 산출물(또는 Markdown 파일)을 타임스탬프가 붙은 새로운 자체 완결형 제로 JS HTML 리뷰 페이지로 렌더링해 `.smart/pages/`에 쓰고, 이전 페이지를 보존한 채 브라우저로 열기. 레이아웃 레시피 3종: plan-review / explainer / report |

---

## Smart Commit

`/smart:commit`은 상태, staged/unstaged diff, 추적되지 않은 파일 내용과 최근 기록을 읽고 type과 독립 목적에 따라 분리합니다. 같은 파일도 hunk 단위로 나누고 커밋 전에 각 그룹의 메시지와 파일을 간단히 보여 줍니다.

Claude Code는 전체 turn을 `haiku`로 실행합니다. Codex는 전체 워크플로를 low reasoning `gpt-5.6-luna` worker 하나에 맡기며, Luna를 사용할 수 없으면 사용자 기본 서브 에이전트로 한 번 재시도합니다. 기본 agent는 직접 그룹화하거나 커밋하지 않습니다.

각 그룹의 명시적 경로나 hunk만 stage하고 커밋 전에 staged diff를 확인합니다. 일괄 stage는 금지합니다. 커밋 해시, 메시지와 남은 변경을 보고하며 검사, 버전 변경, push, PR 생성을 실행하지 않습니다.


---

## 내장 규칙

플러그인에는 미리 작성된 코딩 규칙 파일이 `rules/` 디렉터리에 포함되어 있습니다. 프로젝트의 `.claude/rules/`에 심볼릭 링크를 생성하면 활성화됩니다:

```bash
ln -s /path/to/plugin/rules/pydantic-v2.md .claude/rules/pydantic-v2.md
```

**사용 가능한 규칙:**

| 규칙 파일 | 적용 내용 |
|---|---|
| `pydantic-v2.md` | Pydantic V2 표준: `ConfigDict`, 검증기, 판별 유니온, `TypeAdapter`, `RootModel`, `SecretStr`, `pydantic-settings`, V1→V2 마이그레이션 |
| `python-3.14.md` | Python 3.14 표준: 지연 어노테이션, `[T]` 제네릭, `@override`, `Self`, `TaskGroup`, `StrEnum`, `datetime.UTC`, 서브인터프리터, `match` 가드 |
| `fastapi.md` | FastAPI 0.115+ 표준: `Annotated` 의존성 주입, `lifespan`, `APIRouter` 조직, `BackgroundTasks`, `dependency_overrides`, 보안 스코프 |
| `sqlalchemy-v2.md` | SQLAlchemy 2.0 표준: `DeclarativeBase`, `Mapped[T]`, 명명 규칙, 비동기 세션, `AsyncAttrs`, `selectinload`, UPSERT, Alembic |

규칙은 기본적으로 비활성화되어 있습니다 — 필요한 것만 심볼릭 링크하세요.

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
| `/smart:hud` · `/smart:hud 2` · `/smart:hud all` | 전체 상태 표시줄(6줄 전체) user 스코프 설치, 자동 백업 |
| `/smart:hud 1` · `/smart:hud normal` | 최소 상태 표시줄 설치 (session + ctx만) |
| `/smart:hud 0` · `/smart:hud reset` | 백업에서 이전 상태 표시줄 복원 |

**참고:** 크로스 플랫폼(macOS + Linux/WSL/Ubuntu) — OS를 자동 감지하여 배터리·CPU·메모리·IP에 맞는 도구를 사용합니다. `jq`가 필요하며, 없으면 `/smart:hud`가 자동으로 설치합니다(apt/dnf/pacman/apk/brew).

---

## 세션 Hooks

세션 경계와 도구 호출 시 트리거되는 hook이 포함되어 있습니다:

| Hook | 트리거 | 기능 |
|------|--------|------|
| `greet.sh` | `SessionStart` | macOS TTS (`say`)를 통해 환영 메시지 재생 |
| `session-logs.py` | `PreToolUse` (모든 도구) | 모든 도구 호출의 전체 입력을 `.smart/session-logs/<날짜>/<session_id>.json`에 기록 |

번들 hook 구성은 Claude 호환 host에서 `${CLAUDE_PLUGIN_ROOT}`를 통해 경로를 해석합니다. TTS hook은 백그라운드에서 실행되어 (`nohup &`) host 프로세스를 차단하지 않습니다.

---

## 사전 요구 사항

- **Claude Code** 또는 **Codex**(플러그인 지원) — 플러그인이 두 매니페스트를 모두 내장하여 어느 호스트에서도 네이티브로 동작
- `git`
- Matt Pocock Skills의 `/implement` — `/smart:matt-implement-all-tickets`에 필요
- [`gh` CLI](https://cli.github.com/) — `/smart:matt-implement-all-tickets`에서 GitHub Issues 사용 시 필요
- [`glab` CLI](https://gitlab.com/gitlab-org/cli) — `/smart:close-issue`와 `/smart:matt-implement-all-tickets`에서 GitLab Issues 사용 시 필요
- Node.js — `/smart:html` 및 마감 스크립트에 사용
- Python 3, `reportlab`, 임베드 가능한 CJK 글꼴 — `/smart:github-skills-pdf`에 사용
- `jq` — HUD 상태 표시줄에만 필요 (다른 기능은 불필요)

---

## 저자

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
