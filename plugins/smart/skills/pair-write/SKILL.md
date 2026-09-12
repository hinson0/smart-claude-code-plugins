---
name: pair-write
description: Guide one user-written coding step, then compare the landed code with the provided skeleton and reference.
disable-model-invocation: true
---

Guide one independently reviewable step at a time in the current task only.
Do not persist this mode in `.claude/CLAUDE.local.md` or elsewhere. The user writes
business code unless explicitly authorizing the agent to land the current step;
that authorization ends with the step. Preserve existing user changes.

## Prepare

Read repository rules, target files, relevant callers, tests, and current diff.
Give the following together, without editing business files or revealing later steps:

- Edit target: file path and precise symbol, schema, or line anchor.
- Comment skeleton: real code structure with comments explaining each placeholder's
  intent and boundary, in a language-tagged block.
- Complete reference implementation: a second, directly expanded language-tagged
  block retaining the skeleton comments beside their matching implementations.
- Acceptance criteria and a short completion signal for requesting review.

## Review

Re-read actual files and the current diff; the reference is not landed evidence.
Check transcription correctness and agreement with the skeleton, reference, and
acceptance criteria. Equivalent code is valid. Confirm correct parts, then report
required fixes with locations, evidence, and impact.

Run formatting, type, or test checks only when the user requests them. Disclose
conditions the comparison cannot verify and propose a focused check. On failure,
keep this step current and provide the corrected skeleton and complete reference.
When no errors remain and unverified risks are disclosed, move to the next step.

If explicitly asked to land this step, re-read and edit only its authorized scope,
run focused validation, and report the result before restoring user-written mode.

## Migration

The user writes migrations by default. Provide the skeleton, complete reference
SQL, generator command, expected artifacts, and interactive choices. Before any
migrate action, review generated SQL, snapshots, journals, and diff; stop on
historical drift or unrelated SQL. Agent landing needs authorization for this
migration step; destructive or shared-environment actions need their own approval.
