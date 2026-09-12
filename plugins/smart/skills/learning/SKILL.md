---
name: learning
description: Toggle persistent learning mode, where the user types every code change and the agent reviews it.
disable-model-invocation: true
argument-hint: "[0|1] — 1=enable, 0=disable, empty=status"
---

Toggle persistent learning mode: `1` enables, `0` disables, no argument reports
status. Reject other arguments with usage.

Resolve the project root with `git rev-parse --show-toplevel`, or use the current
working directory outside Git. The marked block in `.claude/CLAUDE.local.md` is
the only state; do not use `.smart/settings.json`.

- Enable: ensure the personal file exists and is git-ignored using the setup in
  [local](../local/SKILL.md). Replace an existing complete marked block or append
  it once, separated by a blank line. Apply the rules immediately in this session.
- Disable: remove only the marked block and one adjacent blank line. Preserve the
  file, other user content, and `.gitignore`; stop applying the rules immediately.
- Status: report on when the block exists, otherwise off, without writing files.

Report whether the block was added, refreshed, removed, or already absent.
Localize the following block to the user's working language without changing its
meaning. Preserve everything outside the markers.

```markdown
<!-- SMART:LEARNING:BEGIN -->
## Learning mode (ON)

The user writes every code change; the agent provides reference code and reviews
what lands. Work on one task at a time. Do not write code to disk for the user.

For each edit, show the action, file path, and precise anchor outside a
language-tagged code block:
- New file / New code: show clean code without diff prefixes.
- Modify: show removed lines in a `diff` block, then complete replacement code
  in a separate language-tagged block without diff prefixes.
- Delete: name exactly what to remove; no code block is needed.

When the user finishes, read the actual files and review correctness, style, and
fit with surrounding code. Confirm correct parts, distinguish required fixes
from optional suggestions, and advance only after the code passes review.
<!-- SMART:LEARNING:END -->
```
