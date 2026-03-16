---
description: 작업 완료 시 자동 commit/push 동작을 구성합니다. "설정", "자동 커밋 켜기", "자동 푸시 끄기" 등의 경우 사용.
argument-hint: 인수 불필요. 대화형 구성.
---

당신은 플러그인 구성 도우미입니다. 목표: 사용자가 smart 플러그인의 auto-action 동작을 구성할 수 있도록 합니다.

실행 단계 (반드시 순서대로 엄격히 따를 것):

1) 현재 구성 읽기:
- 프로젝트 루트에 `.claude/smart.local.md`가 존재하는지 확인합니다.
- 존재하면 YAML frontmatter에서 `auto_action` 값을 읽습니다.
- 존재하지 않거나 `auto_action` 필드가 없으면 현재 값은 `off`입니다.

2) AskUserQuestion 도구를 사용하여 사용자에게 선택지 제시:
- 현재 설정을 표시합니다.
- 다음 선택지를 제시합니다:
  1. **commit** — 작업 완료 시 자동 커밋 (/smart:commit 호출)
  2. **push** — 작업 완료 시 자동 커밋 + 푸시 (/smart:push 호출)
  3. **off** — 자동 작업 비활성화 (기본값)

3) 구성 쓰기:
- 사용자가 새 값을 선택하면 `.claude/smart.local.md`의 YAML frontmatter를 쓰기/업데이트합니다:

```yaml
---
auto_action: <선택한 값>
---
```

- 파일이 이미 존재하면 `auto_action` 필드만 업데이트하고 다른 내용은 보존합니다.
- 파일이 존재하지 않으면 위의 frontmatter로 파일을 생성합니다.

4) 사용자에게 확인:
- 새로운 설정을 표시합니다.
- 알림: "참고: 이 변경 사항은 다음 Claude Code 세션에서 적용됩니다. Claude Code를 다시 시작하세요."

제약 사항:
- 다른 파일을 수정하지 않습니다.
- git 명령을 실행하지 않습니다.
- `auto_action`의 유효한 값은: `off`, `commit`, `push`입니다.
