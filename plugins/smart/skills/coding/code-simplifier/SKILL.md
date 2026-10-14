---
name: code-simplifier
description: Simplify a defined recent code change in one fresh worker while preserving observable behavior.
disable-model-invocation: true
argument-hint: "[paths-or-diff] (empty=working-tree code changes)"
license: Apache-2.0
---

<!-- Adapted and modified from Anthropic's code-simplifier agent, licensed under Apache-2.0. See LICENSE. -->

Delegate the complete run to one fresh worker, including scope discovery. Always dispatch even an empty or ambiguous scope; the worker alone may return `blocked`. The primary agent performs no repository inspection, code reading, edits, staging, or checks.

- **Claude Code:** invoke `smart:code-simplifier-worker` exactly once in the foreground.
- **Codex:** spawn exactly one subagent with `fork_turns` to `none`, without model or reasoning overrides. Tell it to read `<this-skill-directory>/references/worker.md` completely and execute it in the current checkout without delegation.

Pass the complete user request and arguments, preserving paths, symbols, constraints, exclusions, and empty scope. Run serially, wait, and relay the final result. If the worker cannot start or finish, report failure and stop; the primary agent never takes over or repeats its analysis or checks.
