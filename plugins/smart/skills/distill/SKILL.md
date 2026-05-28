---
description: This skill should be used when the user says "distill this conversation", "distill", "save what we discussed to the knowledge base", "persist this session by topic", "summarize the current CC output", "archive the questions and answers I asked", "extract session topics", or "write this chat to disk". The skill does NOT read source-directory files; it extracts valuable Q/A pairs directly from the CURRENT CC session context (user prompts + Claude output), clusters them semantically into kebab-case topic keys, runs a three-state comparison (duplicate / new / diff) ONLY against the resolved target directory, and writes to that directory. Target directory is resolved at runtime from .smart/settings.json (project) or ~/.smart/settings.json (global) if present, otherwise asked once via AskUserQuestion and saved so later runs are silent; default .smart/knowledges/, supports a {date} token, backward-compatible with a personal dated knowledge base. It NEVER touches any directory outside the resolved target. Reviewed files (.printed.md or md with a sibling pdf) are exempt from comparison.
argument-hint: Optional — narrow the scope ("last 5 rounds", "the part about langgraph") or name a target directory. Defaults to the whole session written to .smart/knowledges/.
---

# distill — Persist Knowledge Extracted From the Current Session

## Purpose

Extract, cluster, and format the **valuable Q/A pairs produced in the current CC session** and write them to a target directory, building a topic-keyed knowledge base that future RAG can retrieve.

Input: conversation context (user messages + assistant messages).
Output: one or more `<target-dir>/<topic-key>.md` files.

Three core commitments:

1. **Three-state comparison (target directory only, reviewed files exempt)**: every topic cluster is classified as exactly one of `duplicate / new / diff`
2. **No content deletion**: only off-topic filler, greetings, raw tool JSON, and similar noise may be removed; code, data, tables, examples, and reasoning are always kept
3. **Uniform format**: normalize per `references/format-spec.md`; every written file contains fixed sections such as `## Trigger Question` and `## Key Takeaways`

## Step 0 — Resolve the Target Directory

The target directory is resolved **once** at the start, and every read/write for this run is confined to it. The goal is to ask **at most once ever**: a saved setting is read first, and a first-time choice is persisted so later runs are silent.

Resolution precedence (stop at the first hit):

1. **Explicit path in the invocation** — the user named a directory (e.g. "distill to docs/kb", "distill into ~/knowledges/md/2026-05-28"). Use it verbatim.
2. **Project setting** — read `.smart/settings.json`; if it has a `knowledges_dir`, use that.
3. **Global setting** — read `~/.smart/settings.json`; if it has a `knowledges_dir`, use that.
4. **Ask** — nothing above resolved a path → call `AskUserQuestion` (header `Target dir`, question `Which directory should distilled knowledge be written to?`):

   | Option | Path | Meaning |
   |--------|------|---------|
   | (Recommended) | `.smart/knowledges/` | Project-local knowledge base, relative to the current working directory |
   | Personal KB | `~/knowledges/md/{date}/` | Personal dated knowledge base (backward-compatible prior convention) |
   | Other | (custom) | Any path the user types |

   After the user picks, **persist** the choice to `.smart/settings.json` (project scope) as `{"knowledges_dir": "<chosen path>"}`, so future runs skip the question. In the Step 6 report, state where it was saved and note that moving it to `~/.smart/settings.json` makes it a global default for every project.

**Path tokens and normalization** (applied to the resolved value, from whichever source):

- `{date}` → the system-injected current date (`YYYY-MM-DD`). A path without `{date}` is a static directory (e.g. `.smart/knowledges`); a path with `{date}` re-resolves each day (e.g. `~/knowledges/md/{date}` → `~/knowledges/md/2026-05-28`).
- `~` → the user's home directory.

**Create if absent** — after token substitution, create the directory (and parents) if it does not exist. An empty or freshly created directory means every extracted topic is written as `new`.

Once resolved, treat the directory as `<target-dir>` throughout. The path is fixed for this run and is not re-asked or overridden later.

**`settings.json` format** — a single key; read it with the Read tool. Ignore the file silently if missing or malformed (fall through to the next precedence step):

```json
{ "knowledges_dir": "~/knowledges/md/{date}" }
```

## Scope Iron Law

- ✅ Compare only against files **directly inside** `<target-dir>`
- ✅ `<target-dir>` absent or empty → every extracted topic is written **directly as new**
- ❌ **Never** scan the parent of `<target-dir>`, its sibling directories, or any subdirectory
- ❌ **Never** scan or rewrite any path outside `<target-dir>` (e.g. when `<target-dir>` is `~/knowledges/md/{date}/`, that means never touching other date directories or archive directories like `backend/`, `frontend/`)

Anything outside `<target-dir>` is off-limits: not queried, not modified, not used as a comparison baseline.

## Reviewed-File Exemption (excluded from the three-state comparison)

Inside `<target-dir>`, the following two file classes are treated as **user-reviewed and finalized**; the skill **does not read, compare, overwrite, or merge** them:

| Exemption type | Rule | Meaning |
|---------|---------|------|
| `.printed.md` suffix | Filename ends with `.printed.md` (e.g. `langgraph-checkpointer.printed.md`) | User has printed/archived it |
| Sibling pdf | A pdf with the **same stem** exists in the same directory (e.g. `1.md` + `1.pdf`, `langgraph-checkpointer.md` + `langgraph-checkpointer.pdf`) | User has exported a PDF → treated as reviewed |

**Execution logic**:

1. Before enumerating the target-directory file list in Step 3, **filter out** these exempt files first; only the filtered list participates in topic matching
2. Even if a distilled topic key **matches** an exempt file's stem, **force `new`** — write to a new file with a differentiated name (append `-v2`, `-followup`, or a short time suffix). Never modify an exempt file
3. In the Step 6 summary, add a `frozen` section listing exempt files and "the topic key that would otherwise have matched", so the user understands why no merge happened

**Implementation notes**:

- Stem matching uses **exact match** (`stem(md) == stem(pdf)`, i.e. literal equality after stripping `.md`/`.pdf`); no fuzzy matching, to avoid false positives
- `.printed.md` exemption takes priority over sibling-pdf exemption; both matching still counts as one exemption
- `.printed.md` is self-exempting; it does not need an accompanying sibling pdf

**Pseudocode**:

```python
from pathlib import Path
from glob import glob

def list_target_files(target_dir: str) -> tuple[list[str], list[str]]:
    """Return (active, frozen): active participates in the three-state comparison, frozen is skipped."""
    all_md = glob(f"{target_dir}/*.md")
    pdf_stems = {Path(p).stem for p in glob(f"{target_dir}/*.pdf")}
    active, frozen = [], []
    for md in all_md:
        name = Path(md).name
        stem = Path(md).stem  # stem after stripping .md (may include a .printed infix)
        if name.endswith(".printed.md") or stem in pdf_stems:
            frozen.append(md)
        else:
            active.append(md)
    return active, frozen
```

## Execution Flow After Triggering

### Step 1 — Define the Distillation Scope

Default scope: **all user and assistant messages from session start up to when this skill is triggered**. The user may narrow it explicitly:

- "distill the last 5 rounds" → take only the final 5 Q/A pairs
- "distill the langgraph part" → topic-word filter, keep only matching rounds
- "distill from when I asked about reasoning_content" → anchor-based truncation

Do not treat system reminders, raw tool-call JSON, or command-line stdout as "conversation content" — they are noise and must be stripped.

### Step 2 — Value Judgment (decide which rounds are worth persisting)

Walk every round and keep only content satisfying **at least one** value criterion:

1. **Concept explanation**: Claude produced a new concept's definition, schema, or field table
2. **Code example**: a reusable code snippet appeared (>3 lines, or containing a key API call)
3. **Pitfall / Why**: a user error + Claude's root-cause explanation, or Claude proactively flagging "this is easy to get wrong because..."
4. **Decision reasoning**: multi-option comparison, A/B trade-offs, selection rationale
5. **Non-obvious user question**: the question itself carries context (e.g. "why isn't reasoning_content inside content" — the question is itself a knowledge entry point)

**Discard outright**:

- Greetings ("hi" / "you there" / "ok")
- Pure command execution ("run ls" / "run the tests") with no explanation
- Failed attempts already corrected later (keep the corrected final conclusion)
- Brief user acknowledgements of tool-call results ("got it" / "ok")

When unsure, lean toward keeping and mark "kept-uncertain" in the summary.

See `references/topic-clustering.md` for detailed criteria.

### Step 3 — Topic Clustering and Topic-Key Generation

Cluster the kept rounds semantically into topic clusters. One session may yield 0–N topics.

**Topic-key rules**:

- Extract the head noun phrase → kebab-case
- 2–5 words recommended, e.g. `langgraph-checkpointer`, `reasoning-content-vs-content`, `bge-m3-embedding-dim`
- Avoid generic words as standalone keys (`python-tips` ❌, `python-asyncio-gather-bug` ✓)
- If multiple rounds focus on the same object from different angles (schema vs usage), merge into one topic or split? See "slice boundaries" in `references/topic-clustering.md`

After clustering, fuzzy-match each topic key against the **filtered file list** of `<target-dir>` (with `.printed.md` and sibling-pdf md files removed per the reviewed-file exemption), stripping suffixes like `-schema` `-mechanism` `-bug`. A match enters diff judgment.

If a topic key matches an **exempt** file's stem, record it in the frozen report and write a new file with a differentiated name (e.g. `<key>-v2.md`); do not modify the exempt file itself.

### Step 4 — Three-State Judgment

| State | Criterion | Action |
|------|---------|------|
| **duplicate** | The distilled topic is fully covered by an existing file in `<target-dir>` (no new facts/code/pitfalls) | Skip; list it in the summary only |
| **new** | No matching topic file in `<target-dir>` (or an exempt match forced to new) | Create a new file at `<target-dir>/<topic-key>.md` |
| **diff** | The topic already exists, but this session adds new examples/fields/pitfalls | Use Edit to append the **new portion** to the existing file; leave the original untouched |

See `references/diff-rules.md` for the detailed algorithm, semantic-equivalence rules, and Case A–F boundary handling.

### Step 5 — Format and Write

Organize each topic file with this template:

```markdown
# <topic>

## Trigger Question
<keep the user's original question as a quote block; separate multiple rounds with blank lines>

## Key Takeaways
<extract the core answer from Claude's output, 3–5 bullets>

## Schema / Field Table
<if a data structure is involved, see references/format-spec.md>

## Code Example
<code block with a language tag>

## Pitfall / Why
<error root cause, A/B comparison, gotchas>

## Related
<links to other topics in the same directory, e.g. [[reasoning-content-vs-content]]>
```

Field naming, code-block language tags, Why/How sections, source annotation, and the deletion-allowlist are all specified in `references/format-spec.md`.

For diff merges, use Edit `old_string`/`new_string` to append incrementally; for new topics, use Write for the whole file.

### Step 6 — Output the Summary Report

At the end, print a compact table to the conversation (do not write it to a file):

```
Scope: this session (24 rounds) → .smart/knowledges/
Kept: 18 rounds  Discarded: 6 rounds (greetings/duplicates)
Topic clusters: 4
Target-dir files: 6 (active 4, frozen 2)
─ new: 3  ─ diff: 1  ─ duplicate: 0  ─ frozen-hit: 0
New files:
  + langgraph-stream-modes.md
  + interrupt-vs-breakpoint.md
  + reasoning-content-parsing.md
Merged files:
  ↻ checkpointer-vs-store.md  (+1 section: cross-thread isolation)
Frozen files (skipped comparison):
  · ai-message-schema.printed.md          (.printed.md suffix)
  · langgraph-checkpointer.md + .pdf      (sibling pdf)
```

`frozen-hit` counts how many times this run's topic key matched an exempt file's stem but was forced to `new`; 0 means no conflict.

## No-Deletion Guardrail (must read)

The only content types allowed to be deleted:

- Greetings, 3+ consecutive blank lines, standalone single-character interjections, obvious typing scraps, half-sentences fully superseded later
- System reminders, hook output, raw tool JSON (noise)
- TODOs entirely unrelated to the document topic (move rather than delete)

**Never delete**: code snippets, error messages, data/numbers, tables, examples, command-line output, the user's reasoning process (even if overturned — the overturning process is itself knowledge).

Special note: **the user's original question** must be preserved with its main substance intact in the `## Trigger Question` section, even if phrased informally — it is often the best anchor for retrieval recall.

When unsure, keep by default and annotate `kept-uncertain` in the summary.

## Hard Constraint on the Target Directory

The output directory is fixed by Step 0 resolution and is the single source of truth for this run. All reads and writes confine to `<target-dir>`; the skill never walks up to its parent or into sibling directories. When `<target-dir>` is the personal dated knowledge base (`~/knowledges/md/{date}/`), the date is fixed at resolution time and cannot be overridden afterward — consistent with the global CLAUDE.md convention.

## Additional Resources

- **`references/topic-clustering.md`** — topic-clustering boundaries, value-judgment details, topic-key naming rules
- **`references/diff-rules.md`** — three-state judgment (duplicate/new/diff) details, semantic-equivalence rules, 6 boundary cases
- **`references/format-spec.md`** — knowledge-file format spec (heading levels, Trigger Question/Key Takeaways sections, code blocks, field tables, Why/How, source annotation, deletion allowlist)
