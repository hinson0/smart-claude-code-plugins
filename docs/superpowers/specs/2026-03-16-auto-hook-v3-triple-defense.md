# Auto-Hook V3: Triple Defense Architecture (Future Upgrade)

> Status: **Not implemented** — saved as reference for future upgrade if V2 (SessionStart) proves insufficient.

## Problem

Stop hook `systemMessage` cannot reliably make Claude invoke a skill. Tested twice with different wording, 0% success rate.

## Architecture: Three-Layer Progressive Defense

| Layer | Hook Type | Role | Trigger | Fallback |
|-------|-----------|------|---------|----------|
| **L1 Active** | SessionStart (command) | Coach | Session start | If fails → Claude doesn't know about auto-action, falls through to L2 |
| **L2 Defense** | Stop (prompt) | Self-reflection | Claude tries to stop | If fails → Claude doesn't self-evaluate, falls through to L3 |
| **L3 Guardrail** | Stop (command) | Gatekeeper | After L2 | block + systemMessage (last resort, known unreliable) |

## Flow

```
Session Start
  │
  ├─ L1: SessionStart hook reads .claude/smart.local.md
  │   └─ auto_action=push → systemMessage: standing instruction for entire session
  │
  ├─ Claude works... modifies files...
  │
  ├─ Claude completes task (has L1 context)
  │   └─ Invokes /smart:push autonomously ← primary path
  │       └─ commit + push done → Stop → clean tree → approve
  │
  └─ Claude tries to Stop (forgot to invoke skill)
      │
      ├─ L2: Prompt-based Stop hook
      │   prompt: "Check .claude/smart.local.md for auto_action.
      │            If enabled and git has uncommitted changes,
      │            invoke Skill tool with /smart:push before stopping.
      │            Return 'approve' only if no action needed."
      │   └─ Claude self-evaluates → should invoke skill
      │
      └─ L3: Command Stop hook (if L2 didn't work)
          └─ Checks dirty tree → block + systemMessage reminder
```

## hooks.json Structure

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if file $CLAUDE_PROJECT_DIR/.claude/smart.local.md exists and has auto_action set to 'commit' or 'push' in its YAML frontmatter. If so, check git status for uncommitted changes. If uncommitted changes exist, you MUST invoke the Skill tool with the appropriate skill (/smart:commit or /smart:push) before stopping. Return 'approve' only if auto_action is off, not configured, or no uncommitted changes exist.",
            "timeout": 30
          },
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/auto-commit.sh",
            "timeout": 15
          }
        ]
      }
    ]
  }
}
```

## Trade-offs

- **Pros**: Maximum reliability (85-95%), three independent layers, graceful degradation
- **Cons**: Most complex, 3 hooks + 2 scripts, higher maintenance cost, prompt hook timeout adds latency
- **When to upgrade**: If V2 (SessionStart only) shows < 80% reliability in real-world usage

## Open Questions

- Does prompt-based Stop hook evaluate in the main Claude instance or a separate LLM call?
- How does prompt hook interact with command hook in the same Stop event (parallel or sequential)?
- What is the actual reliability improvement of prompt hooks over command hooks?
