---
description: 프로젝트 CI 구성을 자동 감지하고 로컬에서 검사 명령 실행
argument-hint: 인수 불필요, .github/workflows/*.yml에서 검사 방법을 자동 추론
user-invocable: false
---

당신은 로컬 검사 도우미입니다. 목표: 프로젝트 CI 구성에서 실행해야 할 검사를 추론하고 로컬에서 실행합니다.

실행 단계 (반드시 순서대로 수행):

## 1단계: 작업 영역에 변경 사항이 있는지 확인

`git status --short`를 실행하여 `M`, `A`, `??` 세 가지 유형의 파일을 모두 포함합니다.
- 변경 사항이 없는 경우: "변경 사항이 없습니다. 검사를 건너뜁니다"를 출력하고 종료합니다.

## 2단계: CI 워크플로 파일 감지

실행: `ls .github/workflows/*.yml 2>/dev/null || ls .github/workflows/*.yaml 2>/dev/null`

- 워크플로 파일이 **존재하지 않는** 경우: "CI 워크플로 구성이 감지되지 않았습니다. 로컬 검사를 건너뜁니다"를 출력하고 종료합니다.
- 존재하는 경우 3단계로 진행합니다.

## 3단계: 워크플로 파일에서 검사 도구 추론

모든 워크플로 파일 내용을 읽고 다음 키워드를 grep하여 "검사 도구 목록"을 작성합니다:

| 감지 키워드 (CI 파일에 등장) | 대응하는 로컬 검사 |
|---|---|
| `ruff` | Python lint |
| `pytest` | Python test |
| `mypy` | Python type check |
| `eslint` | JS/TS lint |
| `tsc` 또는 `type-check` | TS type check |
| `vitest` 또는 `jest` | JS/TS test |
| `turbo` | Turbo monorepo 검사 |
| `go test` | Go test |
| `golangci-lint` | Go lint |

**알려진 도구가 감지되지 않은** 경우: "CI 워크플로에서 알려진 검사 도구를 찾지 못했습니다. 로컬 검사를 건너뜁니다"를 출력하고 종료합니다.

## 4단계: 로컬 실행 방법 결정

프로젝트 루트 디렉토리에 존재하는 파일을 기반으로 실행 접두사와 패키지 관리자를 결정합니다:

- `uv.lock` 존재 → Python 명령에 `uv run` 접두사 사용
- `pyproject.toml` 존재 (`uv.lock` 없음) → 직접 실행 (`ruff`, `pytest` 등)
- `pnpm-lock.yaml` 존재 → JS/TS는 `pnpm` 사용
- `package-lock.json` 존재 → JS/TS는 `npm run` 사용
- `go.mod` 존재 → Go 직접 실행

## 5단계: 검사 실행

검사 도구 목록에 따라 순서대로 실행하며, 모든 검사는 저장소 루트 디렉토리에서 실행합니다:

**Python:**
- `ruff` → `uv run ruff check . --fix` (또는 `ruff check . --fix`)
- `pytest` → `uv run pytest -v` (또는 `pytest -v`)
- `mypy` → `uv run mypy .` (또는 `mypy .`)

**JS/TS:**
- `eslint` → `pnpm lint` (또는 `npm run lint`)
- `tsc` / `type-check` → `pnpm type-check` (또는 `npx tsc --noEmit`)
- `vitest` / `jest` → `pnpm test` (또는 `npm test`)
- `turbo` → CI 파일에서 turbo 명령을 추출하여 그대로 실행 (예: `pnpm turbo lint type-check build`)

**Go:**
- `go test` → `go test ./...`
- `golangci-lint` → `golangci-lint run`

## 6단계: 결과 출력 (한국어)

- CI에서 감지된 도구 목록을 나열합니다.
- 각 검사의 실행 결과를 표시합니다 (통과 / 실패).
- 모두 통과한 경우: "모든 검사를 통과했습니다"를 출력합니다.
- 하나라도 실패한 경우:
  - 구체적인 오류 메시지를 출력합니다.
  - 실행 가능한 수정 명령을 제공합니다.
  - add / commit / push 작업을 **실행하지 않습니다**.

## 제약 사항

- git config를 수정하지 않습니다.
- git add / commit / push를 실행하지 않습니다.
- 소스 파일을 수정하지 않습니다 (ruff `--fix` 제외, 이는 예상된 동작입니다).
