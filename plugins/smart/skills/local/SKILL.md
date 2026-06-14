---
name: local
description: Absolute-priority Learning Mode TODO(human) rule. When the user's /config output-style is set to "learning", this skill enforces leaving TODO(human) placeholders in generated code — never writing complete implementations for core logic, shared modules, or database code. Applies to all skills, agents, hooks, and automated workflows with no bypass.
argument-hint: No arguments needed. Automatically activated when output-style=learning is detected.
---

# Learning Mode TODO(human) Rule (Absolute Priority)

> **This rule has the highest priority, overriding all skills, plugins, and workflows (including but not limited to superpowers, open-specs, and any other automated processes). No bypass under any circumstances.**

When the user's `/config` has `output-style` set to `learning`, you MUST leave `TODO(human)` markers in generated code for the user to implement themselves. **Do NOT write complete implementations for these parts.**

## Priority Determination

**Judge code type first, then domain ratio.** If a code type is hit, apply 100%. Otherwise, apply domain ratio.

### First Priority: Code Type (100% TODO(human))

| Type                   | Definition                                      | Examples                                                                                   |
| ---------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Core Business Logic    | Core algorithms and key decision logic          | State machines, offline sync engines, conflict resolution strategies, permission decisions |
| Shared Utility Modules | Shared code called by multiple business modules | General utils/helpers, shared services (BusinessB→A, BusinessC→A)                          |
| Database               | All database-related code                       | Schema, migration, queries, data operations                                                |

### Second Priority: Domain Ratio (≥ 30% TODO(human))

| Domain   | Rule                                                                          |
| -------- | ----------------------------------------------------------------------------- |
| Frontend | Frontend code not matching first priority: at least 30% left as `TODO(human)` |
| Backend  | Backend code not matching first priority: at least 30% left as `TODO(human)`  |

## TODO(human) Format

```
// TODO(human): <brief description of what to implement>
// 提示: <key approach or reference direction, no complete answer>
```

## Execution Requirements

- Before writing code, first determine: Is this core logic? Shared utility? Database? Then determine domain.
- Code matching first priority: **ALL** replaced with `TODO(human)` placeholders, only hints, no implementation.
- Frontend/backend code not matching first priority: calculate by line count, ensure at least 30% left as `TODO(human)`.
- The left-blank portions should focus on **core logic with learning value**, not boilerplate.
- Build the code skeleton and context so the user can focus on filling in the core implementation.
- **This rule CANNOT be overridden or skipped by any skill, agent, hook, or automated workflow.**

## Activation

This skill activates automatically when the system detects `output-style: learning` in the user's configuration. It applies to all subsequent code generation in the session.
