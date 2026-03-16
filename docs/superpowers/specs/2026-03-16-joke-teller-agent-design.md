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

A single agent file with a well-crafted system prompt. Claude judges the appropriate moment to trigger based on conversation context. No hooks or external counters needed.

**Why this approach:**
- Simplest implementation — one component, no inter-component coordination
- Consistent with existing plugin structure (just adds an `agents/` directory)
- Flexible — Claude can adapt timing based on conversation tone
- Acceptable trade-off: slight timing imprecision for much lower complexity

### File Structure

```
plugins/smart/agents/joke-teller/
├── AGENT.md       # English (primary)
├── AGENT_CN.md    # Simplified Chinese
├── AGENT_TW.md    # Traditional Chinese
├── AGENT_JA.md    # Japanese
└── AGENT_KO.md    # Korean
```

No changes to `plugin.json` — auto-discovery handles registration.

## Agent Specification

### Frontmatter

| Field | Value |
|-------|-------|
| `name` | `joke-teller` |
| `description` | Triggers after ~5 rounds of user interaction to tell a joke and lighten the mood. Subsequent triggers use increasing intervals. |
| `model` | `haiku` |

### Trigger Logic

- **First trigger**: approximately round 5 of the conversation
- **Subsequent triggers**: increasing intervals (~10th, ~20th, ~35th round — roughly doubling)
- **Suppression**: do NOT trigger when the user is visibly stressed, debugging errors, or in the middle of urgent problem-solving

### Joke Content Rules

- **Style**: primarily programming/tech jokes, occasionally general humor for variety
- **Language**: match the user's current language
- **No repeats**: never tell the same joke twice in a session
- **Length**: 2-4 sentences, concise and punchy

### Post-Joke Behavior

- Append one brief encouragement or care message (e.g., "Remember to stay hydrated!", "Time to stretch your legs?")
- End immediately — no follow-up questions, no topic extension

### Constraints

- MUST NOT modify any files
- MUST NOT execute any commands
- MUST NOT interfere with the user's working context
- MUST remain lightweight in token usage

## Testing Strategy

- Manual testing: interact with Claude Code for 5+ rounds and verify the agent triggers
- Verify language-following by testing in Chinese and English sessions
- Verify suppression by simulating an error-debugging scenario
- Verify interval increase by extending conversations past 10+ rounds
