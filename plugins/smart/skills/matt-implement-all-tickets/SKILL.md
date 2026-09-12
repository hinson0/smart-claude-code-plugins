---
name: matt-implement-all-tickets
description: Serially implement and close the ordered Tickets from the current /to-tickets output.
disable-model-invocation: true
---

# Matt Implement All Tickets

Require the Matt `implement` skill to be explicitly invoked in the same request and already loaded; otherwise ask for both skills before accessing the repository. Use exactly the ordered Ticket set from the most recent `/to-tickets` output in this conversation. Stop if it is missing or ambiguous; do not discover more work.

Read repository rules and `docs/agents/issue-tracker.md`; if missing, request `/setup-matt-pocock-skills`. Support GitHub Issues, GitLab Issues, or local Markdown Tickets under `.scratch/` only. Verify tracker access and a clean, writable, non-protected current branch before development.

Invocation authorizes one completion record and closure per listed Ticket. It does not authorize push, merge, MR/PR creation, assignees, labels, checklist or parent-Ticket edits, or extra work.

## Process serially

The orchestrator does not edit implementation files or the Git index. Run one fresh worker for one Ticket in the current worktree, wait, verify and close it, then start the next worker in publication order. No parallel or pre-created workers. On interruption, report the current Ticket; do not infer cross-session progress.

For each Ticket:

1. Reread its current specification, acceptance criteria, state, and blockers. Require it open with all blockers closed or `done`; stop on drift instead of skipping or reordering.
2. Record branch and HEAD as `ticket_base`. Give one fresh worker the Ticket, repository rules, base, and loaded Matt `implement` instructions. It owns only this Ticket's implementation, tests, review, and commits, returning the commit interval, files, checks, and review result.
3. Independently verify `ticket_base..ticket_tip`, branch containment, clean worktree, scope, every acceptance criterion, checks actually run, and final review. A worker report is a pointer to evidence. Stop for a blocked worker, missing commit, dirty worktree, expanded scope, failed check, or actionable review finding.
4. Prepare a concise record under `## Implementation assets`, `## Acceptance evidence`, `## Review conclusion`, and `## Closeout boundaries`: commit interval and scope, criterion evidence and actual check results, review source/conclusion, residual risks and delivery actions not performed.
5. Publish and verify closure:
   - **GitHub:** publish and verify one Issue comment, close, then reread and require `CLOSED`.
   - **GitLab:** use sibling `close-issue/scripts/close-issue.mjs close` with Ticket, `ticket_tip`, and a temporary record file. Require `closed`, then reread the note and Issue state.
   - **Local Markdown:** append the record under `## Completion`, set the exact `Status:` field to `done`, and reread both. If tracked, commit only that tracker update under repository rules and restore a clean worktree.

Remove temporary record files. Only verified closure unlocks the next Ticket. If a record is published but closing fails, report the partial result and stop without duplicating it.

Return the ordered Ticket list with commits, checks, review conclusions, record locations, and final states. Claim completion only after every listed Ticket is verified closed or `done`.
