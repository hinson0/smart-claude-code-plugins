---
description: "Configure claude-hud as your statusline"
argument-hint: "[rm|rewind] (empty=install)"
allowed-tools: [Agent]
---

Handle the user's statusline request by launching the `cp-my-statusline` agent.

Determine the action from the argument:

| Argument | Action |
|----------|--------|
| _(empty)_ | `install` |
| `rm` | `rm` |
| `rewind` | `rewind` |

Launch the agent:

```
Agent(subagent_type=None, description="statusline setup", prompt="Action: <action>")
```

The agent identifier is `cp-my-statusline`. Use it as the `subagent_type` value — but since it is a plugin-defined agent, just include the action word in the prompt and the system will route to the correct agent based on the description match.

**Important**: Launch the agent and wait for it to complete. Relay its result to the user. Do not perform any file operations yourself.
