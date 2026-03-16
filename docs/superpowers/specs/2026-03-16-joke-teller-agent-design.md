# Joke Teller Agent Design

## Overview

Create a `joke-teller` subagent for the `smart` Claude Code plugin that automatically tells a joke after approximately 5 rounds of user interaction, lightening the work atmosphere. This is the plugin's first agent component.

## Goals

- Inject lighthearted humor into coding sessions to reduce fatigue
- Be non-intrusive — never disrupt active debugging or urgent workflows
- Follow the user's language naturally

## Non-Goals

- Precise round-counting (±1-2 rounds deviation is acceptable)
- Pre-built joke databases or external API calls
- Any file modification or command execution

## Architecture

### Approach: Pure Agent (Self-Triggering)

A single agent file with a well-crafted system prompt. The main Claude session invokes this agent based on the `description` field's triggering examples. The description includes concrete `<example>` blocks that teach Claude **when** to invoke the agent — specifically, after ~5 rounds of interaction when the conversation tone is relaxed enough.

**Why this approach:**
- Simplest implementation — one file, no inter-component coordination
- Consistent with existing plugin structure (just adds an `agents/` directory)
- Flexible — Claude can adapt timing based on conversation tone
- Acceptable trade-off: slight timing imprecision for much lower complexity

**How triggering works:**
The main Claude session (not the agent itself) is responsible for:
1. Judging when ~5 rounds have passed based on conversation history
2. Deciding if the moment is appropriate (not during debugging/errors)
3. Invoking the joke-teller agent via the Agent tool
4. Tracking prior invocations to apply increasing intervals for subsequent triggers

This works because the main session has full conversation context and can count rounds naturally. The `description` field with `<example>` blocks teaches Claude this proactive behavior pattern.

### File Structure

```
plugins/smart/agents/
└── joke-teller.md    # Single agent file (auto-discovered)
```

Agents use flat `.md` files in the `agents/` directory (NOT the `AGENT.md` subdirectory pattern that skills use). Auto-discovery handles registration — no changes to `plugin.json` needed.

**i18n approach:** Unlike skills which use `SKILL_CN.md` variants, agents are single files. Language adaptation is handled in the system prompt ("match the user's current language"), not via separate files.

## Agent Specification

### Frontmatter

| Field | Value |
|-------|-------|
| `name` | `joke-teller` |
| `description` | See full description below (includes `<example>` blocks) |
| `model` | `haiku` |
| `color` | `yellow` |
| `tools` | `[]` (empty — no tool access) |

### Description Field (Critical for Triggering)

The `description` must teach Claude when to proactively invoke this agent. Draft:

```
Use this agent proactively after approximately 5 rounds of user interaction to tell a joke and lighten the work atmosphere. Subsequent invocations should use increasing intervals (~10 rounds, ~20 rounds, ~35 rounds). Do NOT invoke during active debugging, error resolution, or when the user appears stressed. Examples:

<example>
Context: User has been working with Claude for about 5 rounds on a feature implementation. The conversation is flowing smoothly with no errors or urgency.
user: "ok looks good, let me check the next part"
assistant: "Before we continue, let me lighten the mood a bit."
<commentary>
About 5 rounds of normal interaction have passed. The user is not stressed or debugging. This is a good moment to invoke the joke-teller agent for the first time.
</commentary>
</example>

<example>
Context: User has been interacting for about 10 rounds. The joke-teller was already invoked once around round 5. The current conversation is calm.
user: "great, that test passes now"
assistant: "Nice progress! Let me bring in a quick mood booster."
<commentary>
About 10 rounds in (double the first interval). Previous joke was around round 5. The user just had a small win — good timing for the second joke.
</commentary>
</example>

<example>
Context: User is actively debugging a crash with stack traces. About 6 rounds have passed.
user: "why is this null pointer happening??"
assistant: [Does NOT invoke joke-teller, focuses on debugging]
<commentary>
Even though 5+ rounds have passed, the user is stressed and debugging. This is NOT the time for a joke. Skip this round.
</commentary>
</example>
```

### System Prompt (Body)

The agent's system prompt defines its behavior when invoked:

**Role:** A friendly mood-lightener that tells a single joke and a brief encouragement.

**Joke Content Rules:**
- Style: primarily programming/tech jokes, occasionally general humor for variety
- Language: match the user's current language in the conversation
- Length: 2-4 sentences, concise and punchy
- Creativity: generate original jokes, don't rely on well-known classics

**Post-Joke Behavior:**
- After the joke, append one brief encouragement or care message (e.g., "Remember to stay hydrated!", "Time to stretch your legs?")
- End immediately — no follow-up questions, no topic extension, no tool usage

**Constraints:**
- No tool access (enforced by `tools: []` in frontmatter)
- Output only: a joke + one encouragement line
- Keep total output under 100 tokens

### Trigger Logic (Managed by Main Session)

The main Claude session manages invocation timing:

- **First trigger**: approximately round 5 of the conversation
- **Subsequent triggers**: increasing intervals (~10th, ~20th, ~35th round — roughly doubling)
- **Suppression**: do NOT trigger when the user is visibly stressed, debugging errors, or in the middle of urgent problem-solving
- **State tracking**: the main session can see its own conversation history, including prior joke-teller invocations, to determine the next interval

Note: Since the agent is ephemeral (no memory across invocations), repetition avoidance relies on the agent generating diverse jokes. With `haiku` model and short output, the probability of exact repetition is very low. This is an acceptable trade-off for simplicity.

## Testing Strategy

1. **Trigger verification**: interact with Claude Code for 5+ rounds on a normal task and verify the agent is invoked
2. **Non-trigger verification**: simulate an error-debugging session for 5+ rounds and verify the agent is NOT invoked
3. **Language following**: test in Chinese and English sessions, verify jokes match the user's language
4. **Tool restriction**: verify the agent cannot read/write files or execute commands (enforced by `tools: []`)
5. **Interval increase**: extend a conversation past 15+ rounds and verify the second invocation happens later than the first
6. **Fallback plan**: if auto-triggering proves unreliable, consider adding a `UserPromptSubmit` hook as a counting mechanism (out of scope for this design, but noted as fallback)
