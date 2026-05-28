# Topic Clustering and Value-Judgment Details

This document provides detailed execution rules for the distill skill's Step 2 and Step 3.

## Value-Judgment Details

### Content That Must Be Kept

1. **New concept introduction**
   - User asks "what is X" and Claude gives a definition/schema/field table
   - Claude proactively introduces a term not seen earlier and explains it

2. **Code snippets** (any one of)
   - More than 3 lines
   - Contains a key API call (`STORE.put`, `graph.invoke`, `embeddings.embed_query`, etc.)
   - Contains non-obvious parameters (`reasoning_effort="high"`, `thinking={"type": "enabled"}`)
   - Contains a data-structure definition (TypedDict / Pydantic / dataclass)

3. **Error–root-cause pairs**
   - User pastes a traceback / error symptom
   - Claude provides root-cause analysis (not "try this" but "because X, therefore Y")

4. **A/B decisions**
   - Multi-option comparison tables
   - A "why not A, choose B" reasoning passage
   - Performance number comparisons (σ, tokens, latency)

5. **User-expressed preferences/constraints**
   - "From now on I want..."
   - "In this project we use..."
   - User corrects Claude's attempt ("don't do it this way, it should be...")

### Content That Must Be Discarded

- Greetings (`hi` / `you there` / `ok` / `continue`)
- Brief confirmations of tool-call results (`got it` / `ok` / `understood`)
- Failed attempts already corrected later (keep only the corrected final version)
- Pure command execution with no explanation (`run ls` / `run pytest`)
- Rounds that merely re-confirm an existing conclusion ("say X again" but Claude restates existing content)
- System reminders / hook output / raw tool JSON

### Gray Zone (lean toward keeping, mark kept-uncertain)

- Half-finished code (user wrote half then got interrupted)
- Errors that are abnormal but whose root cause was never found
- Discussions that flip-flop across rounds (may settle later)

## Topic-Clustering Rules

### Clustering Granularity

**One topic file = one independently retrievable knowledge point**. Test by:

- If you give this topic a kebab-case filename, does it accurately recall the content?
- Six months later, if the user searches this filename, will they find what they wanted?

### Slice Boundaries (key decision)

When multiple rounds cover "seemingly related but different-angle" content, split or not?

| Situation | Decision | Example |
|------|------|------|
| Same object, same angle | Merge | `AIMessage tool_calls field` (multiple rounds deepening the same field) → one file |
| Same object, different angle | Split | `AIMessage schema` vs `parsing reasoning in AIMessage.additional_kwargs` → two files |
| Different objects, same theme | Merge | `interrupt usage` and `Command usage` (both HITL control flow) → one file `hitl-control-primitives` |
| Same object, same angle but with a bug experience | Split | `bge-m3 embedding basics` vs `bge-m3 dimension-mismatch bug` → two files |

**Prefer splitting**: finer file granularity improves RAG recall precision. Unless two passages strongly depend on each other (one makes no sense without the other), lean toward splitting.

### Topic-Key Naming Rules

**Goal**: the filename itself is the retrieval query.

**Good names**:

| Name | Why good |
|------|---------|
| `langgraph-checkpointer-sqlite` | library + concept + implementation → precise |
| `reasoning-content-vs-content` | comparison relation is obvious, easy to recall |
| `bge-m3-embedding-dim-mismatch` | contains a bug-characteristic word, locates the error |
| `arq-worker-graceful-shutdown` | library + behavior + state, precise |

**Bad names**:

| Name | Problem |
|------|------|
| `langgraph-tips` | generic word, cannot locate |
| `embedding-notes` | "notes" is a dead word |
| `bug-fix-1` | a number carries no information |
| `general-stuff` | a disaster |

### Name Length

- 2–5 kebab segments is best
- More than 6 segments means it should be split into multiple topics
- A single-segment word is allowed only for proper nouns (`langgraph.md` — avoid unless it really is a langgraph overview)

### Matching Against Existing Files

After clustering, fuzzy-match each topic key against the existing filenames in `<target-dir>`:

- Compare after stripping suffixes `-schema` / `-mechanism` / `-bug` / `-error`
- If the head words (first 2–3 segments) fully match → judged same topic, enter diff judgment
- If head words partially overlap (e.g. `langgraph-stream-modes` vs `langgraph-checkpointer`) → different topics, new

## Slicing a Session That Mixes Multiple Topics

One session may span multiple unrelated topics (the user asks about docker mid-way while debugging langgraph).

**Approach**:

1. Scan the kept rounds in chronological order
2. Tag each round with a "candidate topic label"
3. Adjacent rounds with the same/related labels → merge into one cluster
4. A label jump (from langgraph to docker) → start a new cluster
5. If after a jump the original topic returns, **do not merge it back** — handle it independently as a "second occurrence"; decide at the merge stage

Avoid one mistake: forcing the whole session into a single topic named `2026-05-13-session.md`. This violates the "topic key = retrieval query" principle.
