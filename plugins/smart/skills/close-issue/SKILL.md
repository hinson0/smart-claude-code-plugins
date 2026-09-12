---
name: close-issue
description: Check one GitLab Issue for close readiness, or publish an auditable asset note and close it after explicit authorization.
disable-model-invocation: true
---

# Close One GitLab Issue

Check one Issue IID or URL. Default to read-only: a readiness question or ambiguous intent authorizes no writes. Explicit “close this Issue” authorization covers one development asset note followed by closure, not push, merge, MR/PR creation, checklist edits, or labels.

## Establish readiness

Read repository rules and the current Issue, including comments and acceptance criteria. This workflow requires GitLab Issues and `glab issue`. Resolve a unique committed implementation SHA from the optional argument or current evidence; the clean current implementation branch must contain it.

Verify the implementation diff against every acceptance criterion, checks actually run, and a trustworthy code review. Run allowed checks or the repository review workflow where evidence is missing; otherwise return `not_ready` with blockers. Worker reports and summaries only point to evidence. Never claim an unrun check passed. Target-branch integration is a disclosed delivery boundary, not a close gate.

Run the read-only script gate:

```bash
node <this-skill-directory>/scripts/close-issue.mjs check --issue <iid-or-url> --commit <sha>
```

Add `--repo <group/project>` for a numeric IID outside the current project. Script `ready` is necessary but does not establish acceptance or review completeness. A check-only request ends with `ready` or `not_ready`, without creating a note file.

## Publish and close

Only after explicit close authorization and all readiness evidence passes, create a temporary Markdown note outside the worktree with the script's required headings:

- `## Implementation assets`: Issue/specification, current implementation branch, commit, scope, and existing durable links.
- `## Acceptance evidence`: each criterion's evidence and commands actually run with results.
- `## Review conclusion`: review source, conclusion, resolved findings, and residual risks.
- `## Closeout boundaries`: unverified target integration and delivery actions not performed.

Keep the note independently auditable and exclude secrets or unsupported claims. Use the script, which repeats its gates and publishes the note before closing:

```bash
node <this-skill-directory>/scripts/close-issue.mjs close --issue <iid-or-url> --commit <sha> --note-file <note.md>
```

Report the actual result: `closed` with note and Issue links; `note_failed` means no closure ran; `partially_completed` at `stage: noted` means the note exists but the Issue remains open. Preserve its link and report the failure without implying success or duplicating the note. Remove the temporary file. Validate this workflow with fixtures and fake `git`/`glab`, never real test Issues.
