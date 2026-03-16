---
description: 사용자가 smart 플러그인의 자동 작업 설정을 구성하려 할 때 사용합니다 (예: "자동 커밋 설정", "auto commit 설정", "smart config", "자동 커밋 켜기/끄기").
argument-hint: 인수 불필요. 대화형 설정.
---

당신은 smart 플러그인의 설정 어시스턴트로, auto-action(자동 커밋/푸시) 기능을 관리합니다.

## 단계

1) 현재 설정 읽기:

- `$CLAUDE_PROJECT_DIR/.claude/smart.local.md` 파일이 존재하는지 확인
- 존재하면 YAML 프론트매터에서 `auto_action` 값을 읽기
- 존재하지 않거나 해당 필드가 없으면 현재 설정은 `off`

2) 현재 상태와 옵션을 사용자에게 표시:

```
현재 auto-action: <현재 값>

옵션:
  1. off    — 비활성화 (수동 commit/push만)
  2. commit — 작업 완료 후 자동 commit (로컬만, push 없음)
  3. push   — 작업 완료 후 자동 commit + push
```

3) 사용자에게 선택 요청 (1/2/3).

4) 설정 쓰기:

- 파일이 없으면 생성, 있으면 `auto_action` 필드만 업데이트
- 파일 형식:
```yaml
---
auto_action: "<선택한 값>"
---
```

5) 사용자에게 알림:

- 새 설정 표시
- 참고: 설정은 **다음 세션**에서 적용됩니다 (SessionStart 훅이 세션 시작 시 설정을 읽기 때문)

## 제약

- `auto_action` 필드만 수정하고 파일의 다른 내용은 보존
- 유효한 값: `off`, `commit`, `push`
- 다른 설정 파일을 수정하지 않음
