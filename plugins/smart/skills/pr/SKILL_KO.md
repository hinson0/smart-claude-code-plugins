---
description: 사용자가 Pull Request를 만들려 할 때(예: "create PR", "PR 만들어", "풀리퀘 올려"), 또는 전체 check+commit+push+PR 파이프라인이 필요할 때 사용. push 포함 — 먼저 push할 필요 없음.
argument-hint: 인수 불필요. 자동 [check+add+commit+push+pr]
---

당신은 저장소 커밋 및 PR 어시스턴트입니다. 목표: 표준 커밋과 푸시를 먼저 완료한 후 GitHub에서 Pull Request를 생성합니다.

실행 단계 (반드시 순서대로 수행, 건너뛰기 불가):

---

## 1단계: Push

@../push/SKILL_KO.md

- 작업 트리가 깨끗한 경우(변경 사항 없음), 1단계를 건너뛰고 2단계로 바로 진행합니다.

---

## 2단계: Pull Request 생성

7) 기본 정보 수집 (병렬 실행):
- `git branch --show-current` (현재 브랜치 이름, `HEAD_BRANCH`로 기록)
- `git log -1 --oneline` (최신 커밋 1건, 단일 커밋 시나리오 판단용)
- PR 제목, Summary, Test Plan의 언어 결정: 기본값은 영어입니다. 프로젝트의 `CLAUDE.md` 또는 `CLAUDE.local.md`에서 PR/commit 콘텐츠 언어를 명시적으로 지정한 경우에만 해당 언어를 사용합니다. Section headers (## Summary, ## Commits, ## Test Plan)는 항상 영어로 유지하며, commit messages는 번역하지 않습니다.

8) 대상 브랜치(base branch) 결정:
- 사용자가 $0을 통해 대상 브랜치를 명시적으로 지정한 경우, 해당 브랜치 이름을 base branch로 사용합니다.
- 그렇지 않으면 **반드시** `AskUserQuestion` 도구를 사용하여 사용자에게 질문합니다:
  > PR의 대상 브랜치는 무엇인가요? (기본값: `main`, Enter를 누르면 됩니다)
- 사용자의 답변을 `BASE_BRANCH`로 기록합니다. 사용자가 Enter를 누르거나 비워두면 `BASE_BRANCH=main`으로 설정합니다.

9) PR 존재 여부 확인:
- 실행: `gh pr list --head <HEAD_BRANCH> --json number,url,state`
- 동일한 head 브랜치의 **open** PR이 이미 존재하면, 기존 PR URL을 표시하고 PR이 이미 존재함을 알린 후 종료합니다.

10) 전체 커밋 목록 수집:
- 실행: `git log <BASE_BRANCH>..HEAD --oneline`
- 모든 커밋(hash + message)을 기록하여 PR 본문 생성에 사용합니다.

11) PR 제목 및 본문 생성:
- **언어**: 7단계에서 결정된 언어를 사용합니다. Section headers (## Summary, ## Commits, ## Test Plan)는 항상 영어로 유지합니다.
- **제목**:
  - 이 브랜치에 커밋이 1개뿐이면, 해당 커밋 메시지를 그대로 제목으로 사용합니다.
  - 커밋이 여러 개이면, 브랜치 이름과 커밋 목록을 기반으로 요약 제목 1문장(50자 이내)을 생성하며, 최근 커밋 스타일과 일치시킵니다.
  - 사용자가 명령어 뒤에 설명 텍스트를 추가한 경우, 이를 우선적으로 제목에 반영합니다.
- **본문** (Markdown 형식):
  ```markdown
  ## Summary
  <3-10개 요점, 이 PR이 무엇을 하며 왜 이렇게 했는지 설명.
   각 요점은 "무엇이 변경되었는지"와 "왜 변경했는지" 모두 답해야 합니다 — 파일 이름만 나열하거나 커밋 메시지를 반복하지 마세요. 변경의 의도와 영향에 집중하세요.>

  ## Commits
  <git log BASE_BRANCH..HEAD의 모든 커밋 나열, 형식: `- <hash>: <message>` — 원본 커밋 메시지를 그대로 유지, 번역하지 않음>

  ## Test Plan
  <커밋 목록의 커밋 유형에 따라 테스트 항목 생성:
   - `feat` 커밋 → 새 기능의 핵심 동작 및 엣지 케이스 검증
   - `fix` 커밋 → 원래 버그가 더 이상 재현되지 않는지 확인, 회귀 문제 점검
   - `refactor` 커밋 → 기존 동작이 영향받지 않았는지 확인
   - `docs` 커밋 → 문서 정확성 및 링크 유효성 확인
   - `test` 커밋 → 테스트 통과 및 커버리지 충족 확인
   - `perf` 커밋 → 성능 개선이 측정 가능한지 확인
   - `chore`/`ci` 커밋 → 빌드/CI 파이프라인 정상 실행 확인
   - 유형 접두사가 없는 커밋 → 메시지와 파일 변경에서 의도를 추론하여 적절한 테스트 항목 생성

   `- [ ]` 형식(미체크/검증 대기)을 사용하고 `- [x]`는 사용하지 마세요. 각 항목은 이 PR의 실제 변경 사항에 구체적이어야 합니다 — 일반적인 "기능이 작동하는지 확인"은 금지합니다.>
  ```

12) PR 생성 실행:
```bash
gh pr create \
  --title "<PR 제목>" \
  --base <BASE_BRANCH> \
  --body "$(cat <<'EOF'
<PR 본문>
EOF
)"
```
- `gh` 명령어가 없으면, 사용자에게 설치를 안내합니다: `brew install gh && gh auth login`, 그리고 종료합니다.

---

## 출력 결과

성공 시 표시:
1. 1단계에서 사용된 모든 커밋 메시지 (변경 사항이 있었던 경우).
2. **PR URL** (눈에 띄는 형식): `PR: <url>`
3. PR 제목 및 대상 브랜치 (`HEAD_BRANCH` -> `BASE_BRANCH`).
4. 최종 `git status` (작업 트리가 깨끗한지 확인).

실패 시 표시:
- 어떤 단계에서 실패가 발생했는지.
- 구체적인 오류 메시지.
- 다음으로 실행할 수 있는 수정 명령어.

---

## 제약 사항

- git config를 수정하지 않습니다.
- `--amend`, `--force`, `--no-verify`를 사용하지 않습니다.
- 이번 커밋 및 PR과 직접 관련된 명령어만 실행하며, 추가적인 리팩토링이나 파일 수정은 하지 않습니다.
- PR을 자동으로 merge하거나 reviewer를 자동 assign하지 않으며, 생성 후 다음 단계는 사용자가 결정합니다.
