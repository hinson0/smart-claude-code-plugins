# Three-State Judgment Details (distill-specific)

This file describes the rules distill uses in Step 4 to run a three-state comparison (duplicate/new/diff) between the **topic clusters distilled from the session** and the **existing knowledge files in `<target-dir>`**.

## General Principle

A wrong three-state judgment causes one of two losses:

- Misjudged as **duplicate** → information loss (new facts/pitfalls from this conversation never get persisted)
- Misjudged as **new** → the knowledge base gains a duplicate topic file (RAG recall noise later)

**When in doubt, lean toward `diff`**: the diff operation only appends, never overwrites — it is safe; both duplicate and new have irreversible side effects.

## Scope Iron Law

- ✅ Scan: files **directly inside** `<target-dir>`
- ❌ Do not scan: the parent, sibling directories, or any subdirectory of `<target-dir>`
- ❌ Do not scan: any path outside `<target-dir>` (e.g. other date directories or archive directories like `backend/`, `frontend/`, `ai-agent/`, `tools/` when `<target-dir>` is a dated personal KB)
- ❌ Do not read: files excluded by the "reviewed-file exemption" rule (`.printed.md` and md with a sibling pdf)

Nothing outside `<target-dir>` and no exempt file is queried, modified, or used as a comparison baseline. If `<target-dir>` is absent or empty after exemption filtering → every topic cluster is written directly as new, skipping three-state judgment.

## Step 1 — Topic-Key Alignment

For each session-distilled topic key `S_key` and each existing (exemption-filtered) file `K_file` in `<target-dir>`, first establish topic alignment.

### Source of Topic Keys

distill's topic keys come from **conversation semantic clustering** (see `topic-clustering.md`); typical shapes:

| Topic-key example | Meaning |
|-----------|------|
| `langgraph-checkpointer-sqlite` | library + concept + implementation |
| `reasoning-content-vs-content` | field comparison |
| `bge-m3-embedding-dim-mismatch` | bug-characteristic word |

### Fuzzy Matching

Existing filenames usually carry suffixes like `-schema`, `-mechanism`, `-vs-`, `-quirks`, `-bug`; when aligning, **strip the suffix, then match the stem**:

```
topic key:   interrupt-control
K file:      hitl-interrupt-mechanism.md   → match (stem hitl-interrupt overlaps heavily with interrupt-control)

topic key:   stream-modes
K file:      langgraph-stream-chunks.md    → match (stems stream-chunks/stream-modes are synonymous)

topic key:   new-totally-unique-thing
K file:      (no match)                    → enter Step 2 new judgment
```

Match criterion: after stripping common suffixes, the two stems share **at least 60% of tokens or contain equivalent synonyms** (e.g. `chunks` ↔ `modes`). When unsure, lean toward no match → new.

No K matched → Step 2 new judgment; some K matched → Step 3 duplicate vs diff judgment.

## Step 2 — New Judgment

A topic key with no match in `<target-dir>` (and no conflict with an exempt file's stem) → marked as new.

Write path: `<target-dir>/<topic-key>.md`, content organized per the template in `format-spec.md` (must contain the `Trigger Question` and `Key Takeaways` sections).

If the topic key matches an **exempt** file's stem, use a differentiated name (append `-v2`, `-followup`, `-cont`) to write a new file, and record `frozen-hit` in the summary.

## Step 3 — Duplicate vs Diff Judgment

After a topic aligns to some K file, extract both sides' "information-point sets" and compare.

### Definition of an Information Point

In the distill context, one information point = one independent, citable fact/experience; typical types:

- **Concept definition**: a one-line definition or schema of a term
- **Schema field**: field name + type + semantics
- **Code example**: a runnable snippet and its trigger scenario
- **Bug triple**: symptom + root cause + fix
- **Why/How experience**: a rule + the reason it holds + its application boundary
- **Numeric conclusion**: `σ=0`, `26.7% token savings`, etc.
- **User's original question**: the question itself (a distill-unique information-point type, serving as a recall anchor)

Not an information point:

- Vague "I learned X" narration
- A restatement already fully covered by another passage in the same conversation
- Greetings / confirmations / transitional connectives

### Comparison Algorithm

```python
S_points = extract_from_conversation(theme_cluster)   # extract from the conversation cluster
K_points = extract_from_file(K_file)                  # extract from the existing file
new_points = S_points - K_points                       # set difference (after semantic-equivalence dedup)

if not new_points:
    state = "duplicate"   # skip, list in report only
else:
    state = "diff"        # merge new_points into K
```

During diff judgment, **no element of new_points may be lost**, not even a one-line comment.

### Equivalence Judgment

Whether two information points are equal uses "semantic equivalence", not character equality:

| S (in conversation) | K (existing file) | Equivalent? |
|---------|---------------|---------|
| `tool_calls is list[dict]` | `tool_calls: list[ToolCall]` | Equivalent (synonymous types) |
| `interrupt raises GraphInterrupt` | `interrupt() raises GraphInterrupt` | Equivalent |
| `MemorySaver is for in-memory checkpoints` | `MemorySaver suits dev; use SqliteSaver in prod` | **Not equivalent**; S is a subset of K, still duplicate |
| `drift on the 3rd tool call` | `key drift on retry` | Equivalent (same symptom) |

When unsure about equivalence, lean toward not equivalent → enter the diff flow.

## Special Handling of the "Trigger Question" Section (distill-unique)

Each distill file contains a `## Trigger Question` section recording the user's original question. When merging a diff, **do not** replace or overwrite K's existing questions; instead:

- If the topic is identical, append the new question after the existing quote block, separated by a blank line:
  ```markdown
  ## Trigger Question

  > existing question (left from an earlier session)

  > new question this time (added this session) <!-- from: chat 2026-05-13 14:32 -->
  ```
- Multiple accumulated questions reflect the topic's "user-perspective evolution"; for RAG recall this is a plus, not noise

## Boundary Cases

### Case A: the conversation's refined version is better than K's wording

A conclusion produced in the session = a subset of K's existing content + a more refined expression.

Handling: judge as diff, append the refined version as an "alternative phrasing" section to K, **without deleting** K's original:

```markdown
## Alternative Phrasing <!-- from: chat 2026-05-13 14:32 -->
<the refined version distilled from the conversation>
```

### Case B: the conversation overturns a K conclusion

New evidence appears in the session that overturns a conclusion in K.

Handling: judge as diff, **keep K's original conclusion**, append a correction section:

```markdown
## Correction <!-- from: chat 2026-05-13 14:32 -->
Original conclusion: "<K's original words>"
New evidence: <the new fact from the conversation>
Current judgment: <the new conclusion>
Why: <why the earlier judgment was wrong>
```

Never directly rewrite K's original conclusion — the overturning process is itself meta-knowledge.

### Case C: one session clusters into multiple topics

One conversation produces N topic clusters; each cluster runs its own three-state judgment. A mixed result like "2 diffs into existing K + 3 new + 1 duplicate skip" can occur.

Slicing is handled by the "Slicing a Session That Mixes Multiple Topics" rule in `topic-clustering.md`.

### Case D: the topic seems to already exist outside `<target-dir>` (not queried)

Paths outside `<target-dir>` (other date directories or archive directories) may hold a same-topic file, but this skill **does not query them** — it always treats the topic as "absent in `<target-dir>`" and writes new.

Reasons:

1. Paths outside `<target-dir>` are the user's assets; cross-directory rewriting risks breaking the historical index
2. The user can cross-link days via grep / RAG themselves, which is more controllable than the skill auto-merging across directories
3. A new `<topic-key>.md` in `<target-dir>` may collide with an outside file — that is allowed; the two exist independently without conflict

Only if the user **explicitly requests** merging into a specific outside file (e.g. "merge this into `~/knowledges/md/backend/fastapi/xxx.md`") does it perform an Edit incremental append; otherwise it never crosses directories on its own.

### Case E: both sides are incomplete

The conversation and K each hold partial information, and neither is complete.

Handling: judge as diff, append the part the conversation has that K lacks. The conversation has no "source file" to modify (distill's input is context), so there is no reverse-modification problem.

### Case F: hits an exempt file

A topic key, after suffix stripping, equals some exempt file's (`.printed.md` or sibling-pdf) stem.

Handling: **do not enter Step 3**, go directly to Step 2 new, but use a differentiated name (`-v2` / `-followup`), and mark `frozen-hit` in the report. The exempt file itself is neither read nor modified.

## Report Format

After each run, print one summary block to the conversation (do not write a file), template:

```
Scope: this session (N rounds) → <target-dir>
Kept: M rounds  Discarded: K rounds (greetings/duplicates)
Topic clusters: T
Target-dir files: F (active A, frozen Z)
─ new: N1  ─ diff: N2  ─ duplicate: N3  ─ frozen-hit: N4

New files:
  + <new_file_1>.md
  + ...

Merged files:
  ↻ <existing_file>.md  (+P sections, +Q fields)

duplicate (skip):
  · <topic-key> → <existing_file>

frozen-hit (forced new):
  ⊘ <topic-key> → matched frozen file <stem>, rewritten as <topic-key>-v2.md

Frozen files (skipped comparison):
  · <file>.printed.md           (.printed.md suffix)
  · <file>.md + .pdf            (sibling pdf)

uncertain (kept verbatim):
  ? <topic-key>: <information-point summary>
```
