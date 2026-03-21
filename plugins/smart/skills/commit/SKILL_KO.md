---
description: 사용자가 변경 사항을 커밋하려 할 때(예: "commit", "커밋해", "저장해"), 작업 완료를 확인하고 커밋이 필요할 때(예: "완료", "done", "끝났어"), 또는 push/PR 파이프라인의 일부로 사용.
argument-hint: 인수 불필요. 단일 또는 다중 feature를 자동 식별하여 그룹별로 커밋합니다.
---

당신은 저장소 커밋 도우미입니다. 목표: 현재 저장소에서 "이번 변경사항"을 표준 커밋으로 완료합니다 (push 및 로컬 검사 제외).

중요: 이 스킬은 단독으로 실행되거나 파이프라인(push/pr)의 일부로 실행될 수 있습니다. 어떤 맥락이든 모든 단계 — 특히 3단계의 의미 분석 — 는 반드시 완전하게 실행해야 합니다. 이후에 실행할 단계가 있다고 해서 단계를 축약하거나 건너뛰지 마십시오.

실행 단계 (반드시 순서대로 엄격히 따를 것):

1) 다음 정보를 병렬로 실행하고 읽습니다:
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) 커밋 가능한 변경사항이 있는지 판단:
- 변경사항이 전혀 없으면 "커밋할 변경사항이 없습니다"라고 응답하고 종료합니다.

3) 의미 분석으로 커밋 전략 결정 (핵심 단계 — 분석 결과를 반드시 터미널에 출력해야 하며, 내부적으로만 생각하지 마십시오):
- `git diff`와 `git diff --staged` 내용을 읽고, **파일별 구조화 분석**을 수행합니다:
  a. **파일-목적 테이블 출력** (필수, 생략 불가) — 마크다운 테이블을 터미널에 출력합니다:
     | File | Purpose | Type |
     |------|---------|------|
     | src/sheet.tsx | replace gesture sheet with Modal | refactor |
     | src/api/entry.ts | await insert for data consistency | fix |
     | app.json | add expo plugins | chore |
     | .prettierrc | add prettier config | chore |
     각 파일의 Purpose는 구체적이고 명확해야 합니다. "개선" 또는 "업데이트" 같은 모호한 설명을 사용하지 마십시오.
  b. **1단계 — type 기준 기계적 분할** (판단 불필요):
     - `Type` 열을 기준으로 파일을 엄격하게 그룹화합니다. 다른 type의 파일이 같은 그룹에 들어가는 것은 **불가능**합니다. 이것은 협상 불가이며, 의미 판단이 필요하지 않습니다.
     - 예시: 테이블에 `refactor`, `fix`, `chore` 세 가지 type이 있는 경우 → 최소 3개 그룹, type별로 하나씩.
  c. **2단계 — 각 type 그룹 내에서 목적별 세분화** (의미 분석):
     - 1단계의 각 type 그룹 내에서, 파일이 서로 다른 독립적인 목적을 가지는지 확인합니다.
     - 동일한 목적 → 하나의 그룹으로 유지.
     - 다른 목적 → 별도의 그룹으로 분할 (예: 관련 없는 두 개의 `fix` 변경은 두 그룹이 됨).
  d. **최종 그룹 수 집계**:
     - 총 1개 그룹 → **단일 커밋**.
     - 2개 이상 그룹 → **다중 커밋** (필수, 예외 없음).
  e. **다중 커밋인 경우: 그룹화 계획을 터미널에 출력**:
     Group 1 (refactor): src/sheet.tsx, src/layout.tsx
     Group 2 (fix): src/api/entry.ts
     Group 3 (chore): app.json, .prettierrc
  f. 이 그룹화를 가지고 4단계로 진행합니다.
- **분할 규칙 (엄격히 적용)**:
  - 관련 없는 변경사항을 "프로젝트 업데이트"나 "여러 개선" 같은 모호한 설명으로 묶지 마십시오.
  - 서로 다른 conventional commit 유형 (feat + fix, feat + refactor, fix + docs 등)은 거의 항상 다중 feature를 의미합니다 — **반드시 분할하십시오**.
  - 같은 type이지만 목적이 다른 경우 (예: 관련 없는 두 개의 fix) — **역시 분할하십시오**.
  - feature A를 위한 새 파일 추가 + feature B를 위한 기존 파일 수정 = 두 개의 커밋, 하나가 아닙니다.
  - 확신이 없을 때는 **분할하십시오**. 커밋이 너무 많은 것이 관련 없는 변경을 하나로 묶는 것보다 항상 낫습니다.
- **반드시 세 가지 상태를 모두 포함**: `M` (수정됨), `A` (스테이징된 새 파일), `??` (추적되지 않는 새 파일). 어떤 파일도 누락하지 마십시오.
- **예시**:
  ❌ 잘못된 예 — 관련 없는 변경을 모호한 scope로 묶음:
    | File | Purpose | Type |
    | src/sheet.tsx | mobile improvements | refactor |
    | src/api/entry.ts | mobile improvements | refactor |
    | .prettierrc | mobile improvements | refactor |
    → 단일 커밋: "refactor(mobile): various improvements"
  ✅ 올바른 예 — 실제 목적별로 분할:
    | File | Purpose | Type |
    | src/sheet.tsx | replace gesture sheet with Modal | refactor |
    | src/api/entry.ts | await insert for data consistency | fix |
    | .prettierrc | add prettier config | chore |
    → 3개의 커밋, 목적/type별로 하나씩
  ❌ 잘못된 예 — scope를 그룹화 수단으로 사용:
    refactor(mobile): replace sheet, fix data consistency, add plugins
  ✅ 올바른 예 — 같은 scope라도 목적/type별로 분할:
    refactor(mobile): replace gesture-based sheet with native Modal
    fix(mobile): await chat_messages insert for data consistency
    chore(mobile): add expo-localization and expo-web-browser plugins
    chore: add prettierrc configuration

4) commit message 생성:
- **기본 형식 (프로젝트 CLAUDE.md에 사용자 정의 commit 형식이 정의되지 않은 경우 사용):**
  - 형식: `<type>(<scope>): <description>`
  - `scope`는 선택 사항 — 변경이 특정 패키지, 모듈, 또는 영역(예: `mobile`, `api`, `auth`, `shared`)에 한정될 때 사용합니다. scope가 해당되지 않으면 괄호를 생략합니다.
  - `scope`는 변경이 어디에서 이루어졌는지를 설명하며, 왜 변경했는지가 아닙니다 — 관련 없는 변경을 그룹화하는 데 사용해서는 안 됩니다. 분할은 항상 목적과 type(3단계)에 의해 결정되며, scope에 의해 결정되지 않습니다. 같은 scope + 다른 목적/type = 다중 커밋.
  - 허용 type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
  - description 규칙: 첫 글자 소문자, 마침표로 끝나지 않음, 전체 줄 길이(type, scope, 콜론, description 포함) 72자 이내
  - 언어: 기본값은 영어입니다. 프로젝트의 `CLAUDE.md` 또는 `CLAUDE.local.md`에서 commit message 언어를 명시적으로 지정한 경우에만 해당 언어를 사용합니다.
  - "왜 변경했는지"에 초점을 맞추고, 모호한 설명을 피할 것
- **프로젝트 오버라이드:** 프로젝트 `CLAUDE.md` 또는 `CLAUDE.local.md`에 사용자 정의 commit message 형식 또는 언어 요구사항이 정의되어 있으면, 프로젝트 규칙을 따르고 위의 기본값을 무시합니다.
- 단일 feature:
  - 위 규칙에 따라 commit message를 1개 생성합니다.
- 다중 feature:
  - feature별로 변경사항을 그룹화합니다 (디렉토리/모듈 경계 기준 우선).
  - 각 feature에 대해 위 규칙에 따라 commit message를 1개 생성합니다.

5) 커밋 실행:
- 단일 feature (3단계에서 모든 파일이 하나의 목적을 공유한다고 확인된 경우에만):
  - `git add -A`
  - HEREDOC을 사용하여 커밋 실행:
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
- 다중 feature (**절대 `git add -A` 사용 금지** — 각 커밋은 해당 feature의 파일만 add해야 함):
  - feature 그룹별로 순차적으로 실행 (`M` 수정 파일과 `??` 새 파일 모두 그룹에 포함해야 함):
    - `git add <해당 그룹의 구체적인 파일>` (파일을 하나씩 나열, `-A`나 `.` 사용 금지)
    - HEREDOC을 사용하여 해당 그룹 커밋:
```bash
git commit -m "$(cat <<'EOF'
<feature commit message>
EOF
)"
```
  - 파일 간 순환 의존성으로 인해 별도 커밋이 불가능한 경우에만 그룹을 합칩니다 (예: 그룹 1의 파일 A가 그룹 2의 파일 B에서 아직 존재하지 않는 새로운 export를 import하는 경우). 합치는 것을 정당화하려면 구체적인 의존성 체인을 나열해야 합니다.

6) 결과 출력:
- 실제 사용된 commit message를 표시합니다.
- 분할 커밋인 경우, 각 feature의 commit message와 포함된 파일 목록을 순서대로 표시합니다.
- `git status`의 최종 상태를 표시합니다 (작업 트리가 깨끗한지 확인).
- 실패한 경우, 실패 원인과 다음 단계 실행 가능한 복구 명령을 제공합니다.

제약 사항:
- git config를 수정하지 않습니다.
- `--amend`, `--force`, `--no-verify`를 사용하지 않습니다.
- git push를 실행하지 않습니다.
- 로컬 검사 (ruff, pytest, pnpm 등)를 실행하지 않습니다 — 검사는 smart-check가 담당합니다.
- 이번 커밋과 직접 관련된 명령만 실행하며, 추가적인 리팩토링이나 파일 수정을 하지 않습니다.
