# distill Knowledge-File Format Spec

This document fully describes the format spec for distill output files; it is self-contained and does not depend on any external skill.

## Heading Levels

The single H1 = the topic name (matching the filename stem).
H2 = content sections, a fixed candidate set, appearing as needed, in this order:

```markdown
# <topic>

## Trigger Question     # distill-specific, comes first
## Key Takeaways        # distill always emits this
## Concept              # one-line definition + 2-3 sentences of expansion when needed
## Schema               # data structure (TypedDict / Pydantic / dataclass / dict)
## Field Table          # markdown table describing each schema field
## Code Example         # Python / bash / curl / repl output
## Pitfall / Why        # gotcha experience, Why reasoning
## Related              # links to related knowledge files
```

H2s not in the candidate set are demoted to H3 (nested under a relevant H2) or merged.
When an H2's content is empty, **delete the whole section** — no empty H2 placeholders allowed.

## The "Trigger Question" Section (distill-unique)

This is the section that distinguishes distill from other knowledge-persistence tools; it must appear after `# <topic>` and before the other H2s.

### Content Source

- Take the **most specific, highest-information** user question within the topic cluster as the main question
- If multiple rounds escalate (general → precise), take only the last precise question
- Keep the user's original words even if phrased informally, with light cleanup:
  - Remove obvious stutters/repeats ("I I want to ask")
  - **Keep** all proper nouns, key parameters, and error messages

### Format

```markdown
## Trigger Question

> Why are reasoning_content and content two separate fields? Can they be merged?
> When I parse it, the parser reads content but can't get the thinking process.

(optional, 2–3 lines of "question background": what the user was doing, the context)
```

- Wrap the original question in a markdown quote block `>`
- Separate multiple rounds with blank lines; do not merge into one paragraph
- Do not add a redundant prefix like "The user asked:"

### Anti-Example

❌ Do not write a paraphrase:

```markdown
## Trigger Question

The user wanted to understand the difference between reasoning_content and content.
```

A paraphrase loses the retrieval anchor. Keeping the original words is what matches future similar questions during RAG recall.

## The "Key Takeaways" Section (distill always emits)

- List the core answers extracted from Claude's output in 3–5 bullets
- One line per bullet, no more than ~30 words
- Bullets are unordered and not nested
- If the answer is essentially code, this section may just say "see Code Example" as a pointer

Example:

```markdown
## Key Takeaways

- `reasoning_content` lives in `additional_kwargs`, not in the `content` field
- DeepSeek `v4-flash` thinking mode is off by default; trigger it with `reasoning_effort="high"`
- The LangChain `AIMessage` parser can't read the thinking process; dig it out of the raw response yourself
```

## Code Blocks

Every code block must have a language tag. Common values:

| Content | Tag |
|------|------|
| Python | `python` |
| Command line | `bash` |
| JSON | `json` |
| Table/pseudocode | `text` |
| Error stack | `text` or `traceback` |

Untagged code blocks must be completed; when the language is undetectable, use `text`.

## Field-Table Spec

For any schema field description, use a markdown table uniformly:

```markdown
| Field | Type | Required | Semantics | Example |
|------|------|------|------|------|
| `id` | `str` | ✓ | unique identifier | `"msg_abc"` |
| `tool_calls` | `list[dict] \| None` | ✗ | tool-call list, None if absent | `[{...}]` |
```

Wrap field names in inline code. Use Python type-hint style for types. Use `✓`/`✗` for required.

## Why / How Three-Part Form

Experiential knowledge (rules, gotchas, judgments) uses a three-part form:

```markdown
**Conclusion**: <one-line rule or fact>

**Why**: <why this rule holds — reason, mechanism, past incident>

**How to apply**: <when it triggers, how to apply it, boundary conditions>
```

All three parts are required. The conclusion must be independently citable; Why/How must explain the conditions under which the conclusion holds.

## Source Annotation

### Section-Level Annotation (when appending a new section during a diff merge)

```markdown
## <new section title> <!-- from: chat 2026-05-13 14:32 (round #18) -->
```

- Timestamp to the minute
- `round #N` is the in-session round number (count only user messages, starting at 1)
- When the exact round is hard to determine, the time alone is allowed: `<!-- from: chat 2026-05-13 14:32 -->`

HTML-comment form: invisible when rendered, but grep-able.

### End-of-File Source Section (when creating a whole new file)

```markdown
---
Source: distill from CC session
Date: 2026-05-13
Rounds covered: round #15 - #21
```

`Rounds covered` is optional but recommended — it helps future tracing.

## Tables Over Prose

For "A vs B", "comparison of multiple options", or "explanation of field meanings", **prefer a table over prose**. A table is the shortest path for high-density information.

## Link Relations

The end-of-file `## Related` section uses relative-path links:

```markdown
## Related

- [hitl-interrupt-mechanism.md](./hitl-interrupt-mechanism.md) — interrupt resume mechanism
- [reasoning-content-vs-content.md](./reasoning-content-vs-content.md) — DeepSeek thinking-field separation
```

For cross-directory links (only when the user explicitly requests), use `../<dir>/<file>.md`. Link anchor text must include a one-line explanation; avoid bare links.

You may also use wiki-link form to mark a future topic: `[[bge-m3-embedding-tuning]]` — even if that file does not yet exist, it flags "this topic is worth distilling later".

## File Naming

- All-lowercase kebab-case: `reasoning-content-parsing.md`
- No date/version number: the topic key is the retrieval query; dates belong to the directory path or to diff-merge source annotations, not the filename
- No verbs: use noun phrases
- No trailing `-notes` `-draft`: knowledge files are finished products

Exemption-related special naming:

- `*.printed.md` is the user's manual "reviewed & printed" marker; distill **does not create** such files, it only recognizes them for exemption
- `<key>-v2.md` / `<key>-followup.md` is the differentiated naming distill uses when it hits an exempt file

## Deletion Allowlist

Only the following content may be deleted:

| Deletable | Reason |
|------|------|
| 3+ consecutive blank lines | layout noise |
| standalone single-character interjections ("hmm." "ok.") | no information |
| half-sentence typing scraps fully superseded below | explicitly rewritten |
| TODOs entirely unrelated to the document topic (move rather than delete) | off-topic |
| empty H2 (a content-less heading placeholder) | layout |
| system reminders / hook output / raw tool JSON | noise |

**Never delete**:

- Any code (even if it looks like a draft)
- Any number / data / quantitative conclusion
- Any error stack
- Any overturned reasoning (the overturning process is meta-knowledge)
- Any "guess/intuition" annotation the user wrote down
- The main substance of any user's original question (even if phrased informally)

When unsure, keep by default and mark `kept-uncertain` in the summary.
