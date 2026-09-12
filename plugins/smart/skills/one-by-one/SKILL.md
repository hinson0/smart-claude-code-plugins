---
name: one-by-one
description: Run one Red-to-Green cycle — the agent lands and validates Red, then the user lands Green.
disable-model-invocation: true
---

## Cycle boundary

Process exactly one minimal cycle at a time: the agent lands Red, the user lands
Green. Keep the cycle open until explicit acceptance; “continue” is not acceptance.
Do not prepare later cycles or create persistent cycle logs.

## Red to Green

Read repository rules, relevant code, and test entry points; select the smallest
unfinished behavior. Re-read affected files before editing to preserve user changes.
Land only the minimal Red test and run focused validation without changing the
implementation. It must fail because the target behavior is missing; otherwise
stop and explain the blocker.

Once Red is valid, omit its code and full logs. In the same response, explain the
behavior and give complete manual Green edits, precise searchable anchors,
replacement or new-file content, post-edit checks, the focused validation command,
and its expected result. Use repository-relative paths and language-tagged code.

After the user lands Green and returns results, evaluate this cycle only. Distinguish
user-run evidence from agent-run validation. Failure keeps the cycle open; success
still waits for explicit acceptance before closing it or showing the next cycle.

## Review or agent fix

When asked to review Green, review only the current cycle. Do not run tests or
modify implementation. Report findings with exact lines, evidence, and impact;
if none, disclose that tests were not run.

Only an explicit request to fix authorizes agent implementation edits, and only
for the current cycle. Re-read files, preserve newer user changes, and report the
change and whether focused validation ran. Acceptance remains required afterward.
