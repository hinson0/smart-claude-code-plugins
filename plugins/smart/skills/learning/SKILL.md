---
name: learning
description: 'Toggle "learning mode" — a co-coding mode where the user writes the meaningful parts of the code themselves instead of you writing everything. Trigger on /smart:learning, or whenever the user wants to enable or disable hands-on participation in coding: phrases like "learning mode", "let me write part of the code", "I want to participate in coding", "co-code with me", "参与编码", "hands-on mode", "turn learning mode off", "change my coding share". State and the tunable per-cell ratios live in `.smart/settings.json` (shared with distill; this skill owns `learning` + `learning_ratios`, a layer × kind grid); when on, participation rules are injected into `.claude/CLAUDE.local.md` so they persist across every future session; when off, that injected block is removed. Use this skill for any request about turning the user''s own involvement in writing code on or off, or retuning how much of each kind of code they hand-write.'
argument-hint: "[0|1|config] — 1=enable, 0=disable, config layer.kind=NN → retune a cell, empty=status"
---

Learning mode lets the user write the meaningful parts of the code by hand. The point is not to slow things down — it is that some decisions (core logic, data modeling) are where the user learns the most and where their domain knowledge matters most, so those parts are handed back to them instead of being written for them. How much of each kind of code is handed back is **configurable** per project.

This skill is a switch plus a small config. It keeps machine-readable state in `.smart/settings.json` **and** mirrors the actual behavior rules into `.claude/CLAUDE.local.md`, which Claude Code auto-loads into context at the start of every session. The settings file is the source of truth; the `CLAUDE.local.md` block is the mechanism that makes the rules persist without re-invoking this skill each session.

## Argument

| `$0`                           | Action                                                                          |
| ------------------------------ | ------------------------------------------------------------------------------- |
| `1`                            | **Enable** — set `learning` to 1 and inject the participation block.             |
| `0`                            | **Disable** — set `learning` to 0 and remove the injected block.                 |
| `config` `[layer.kind=NN ...]` | **Configure** — update one or more cells in `learning_ratios`.                   |
| _(empty)_                      | **Status** — report whether learning mode is on, the effective grid, and drift.  |

If `$0` is anything else, report the usage above and stop.

## The settings file: `.smart/settings.json`

This is the **same** project-level file distill uses — there is exactly one. Always read-modify-write it: preserve every key you do not own (especially distill's `knowledges_dir`). This skill owns two keys:

- **`learning`** — `0 | 1`, the on/off toggle.
- **`learning_ratios`** — optional two-level object: each **layer** maps to `{ "boilerplate": NN, "business": NN }`, where `NN` is the user's hand-written share as an integer percentage (`0` = you write it all, `100` = the user writes it all). Missing layers or kinds fall back to the defaults below. The grid is a fixed **3 layers × 2 kinds**; the cells never overlap, so every *chunk* of work has exactly one home cell. (A whole task can still span several cells — that is handled in the per-task loop below.)

  | Layer      | `boilerplate` (scaffolding / wiring) | `business` (meaningful decisions) |
  | ---------- | ------------------------------------ | --------------------------------- |
  | `frontend` | `0`                                  | `30`                              |
  | `backend`  | `30`                                 | `70`                              |
  | `db`       | `0`                                  | `100`                             |

  Example: `"learning_ratios": { "backend": { "boilerplate": 50, "business": 100 } }` means in the backend the user hand-writes half the scaffolding and all the business logic; every other cell falls back to its default.

The whole `.smart/` directory is the conventional personal-config location and is normally git-ignored, so the learning state stays local and is never committed.

## The CLAUDE.local.md block

This skill manages only the region between its markers; everything else in `.claude/CLAUDE.local.md` is the user's and must never be touched:

```
<!-- SMART:LEARNING:BEGIN -->
...managed block...
<!-- SMART:LEARNING:END -->
```

## Steps

### 1) Resolve project root and parse the argument

- Project root: `git rev-parse --show-toplevel`; if not in a git repo, fall back to the current working directory.
- Read `$0` and branch to Enable / Disable / Configure / Status below.
- Whenever you need the **effective grid**, read `learning_ratios` from the settings file and fill any missing layer or kind from the defaults table, so you always have all 3 layers × 2 kinds resolved.

### 2) Enable (`$0 == 1`)

1. `mkdir -p <root>/.smart`.
2. **Write state.** Read `<root>/.smart/settings.json` if present, set `learning` to `1`, and write it back **preserving all other keys**. If absent, create `{"learning": 1}`.
3. **Ensure `.claude/CLAUDE.local.md` exists and is git-ignored.** If the file is absent, bootstrap it (and its `.gitignore` entry) by following `@../local/SKILL.md`. If it already exists, leave its content alone.
4. **Inject the participation block** (see "The participation block" below), substituting the effective grid. Do it idempotently:
   - If the `<!-- SMART:LEARNING:BEGIN -->` … `<!-- SMART:LEARNING:END -->` markers already exist, replace everything between them (markers inclusive) — this refreshes a stale block after a ratio change or a version update.
   - Otherwise append the block to the end of the file, separated by one blank line.
5. **Ensure `.smart/` is git-ignored.** Check `git check-ignore -q .smart/settings.json`. If that fails (nothing ignores it yet), append the single line `.smart/` to `<root>/.gitignore` with the Edit/Write tool — create `.gitignore` if absent, never duplicate, never rewrite unrelated content. In repos that already ignore `.smart/`, this is a no-op.
6. **Apply immediately.** The rules are now active. Acknowledge that for the remainder of *this* session you will also follow them, not just future sessions.
7. **Report**: `learning = 1`, the effective grid, block added vs. updated, git-ignore added vs. already in effect.

### 3) Disable (`$0 == 0`)

1. **Write state.** Read `<root>/.smart/settings.json` (create if needed), set `learning` to `0`, preserve other keys. Leave `learning_ratios` intact so the configured values survive for the next enable.
2. **Remove the injected block.** If `<root>/.claude/CLAUDE.local.md` exists and contains the markers, delete the region from `<!-- SMART:LEARNING:BEGIN -->` through `<!-- SMART:LEARNING:END -->` inclusive, plus one adjacent blank line so no gap is left. Leave every other line untouched. **Never delete the `CLAUDE.local.md` file itself**, and never touch the `.gitignore`.
   - If the file or the markers are absent, there is nothing to remove — say so.
3. **Stop applying.** Note that the participation rules no longer apply for the rest of this session.
4. **Report**: `learning = 0`, block removed vs. not present.

### 4) Configure (`$0 == config`)

1. **Parse the remaining tokens** as `layer.kind=NN` pairs — `layer` ∈ {`frontend`, `backend`, `db`}, `kind` ∈ {`boilerplate`, `business`}, `NN` an integer in `0..100` (e.g. `backend.business=100`). Reject unknown layers/kinds, malformed paths, or out-of-range values with a short usage line and stop.
2. **If no valid pairs were given**, print the current effective grid (rendered as the layer × kind table) and the usage (`/smart:learning config backend.boilerplate=50 backend.business=100 frontend.boilerplate=0`), and note the cells can also be edited directly in `.smart/settings.json`. Then stop — do not guess values.
3. **Merge and persist.** Read settings (create if needed), deep-merge the given cells into `learning_ratios` (a partial update — untouched cells keep their value), and write back preserving all other keys.
4. **Re-inject if active.** If `learning == 1`, refresh the `CLAUDE.local.md` block (step 2.4) so the new grid takes effect immediately. If learning is off, just persist — the values apply on the next enable.
5. **Report** the old → new cells and whether the live block was refreshed.

### 5) Status (no argument)

1. Read `<root>/.smart/settings.json`; treat a missing file or missing `learning` key as `0`.
2. Resolve the effective grid (configured cells, with defaults filling the gaps).
3. Check whether `.claude/CLAUDE.local.md` contains the managed markers.
4. Report `learning = 0 | 1`, the effective grid (rendered as the 3 layers × 2 kinds table), and whether the block is present. **Flag drift**: if state is `1` but the block is missing (or state is `0` but the block is present), say so and offer to reconcile by re-running `/smart:learning 1` or `/smart:learning 0`.

## The participation block

Inject exactly this content between the markers, filling the table cells with the effective grid (e.g. `{frontend.boilerplate}`, `{backend.business}`). **Localize the prose to the user's working language** — the language of their `CLAUDE.local.md` and conversation. The English below is the canonical version to translate; do not change its meaning, only its language.

```markdown
<!-- SMART:LEARNING:BEGIN -->
## Learning mode (ON)

The user hand-writes the meaningful parts of the code to learn. The split is a fixed layer × kind grid; each number is the **user's hand-written share** (`0` = you write it all, `100` = the user writes it all). Configured in `.smart/settings.json` → `learning_ratios`:

| Layer    | Boilerplate (scaffolding / wiring) | Business (meaningful decisions) |
| -------- | ---------------------------------- | ------------------------------- |
| frontend | ~{frontend.boilerplate}%           | ~{frontend.business}%           |
| backend  | ~{backend.boilerplate}%            | ~{backend.business}%            |
| db       | ~{db.boilerplate}%                 | ~{db.business}%                 |

**Boilerplate** = scaffolding, wiring, repetitive setup. **Business** = the meaningful decisions (algorithms, rules, branching, error-handling, schema / table design). For `db`, for instance: boilerplate = connection / ORM wiring / the migration runner; business = the schema, indexes, and table / relationship design. The cells never overlap, so each *chunk* of work has one home cell — but a single task can span several cells (adding an endpoint touches backend boilerplate *and* business), so classify each chunk on its own and apply that cell's share.

**Per-task loop — one task at a time, never several stubs at once:**

1. **Classify each chunk, then handle it by its share.** For each chunk of the task, decide its cell (layer × boilerplate/business) and read that cell's user-share %. Treat the share as a rough emphasis dial, not a literal line count:
   - **0%** — write the whole chunk yourself and keep going; there is nothing to hand back, so do not pause.
   - **100%** — write none of it; hand the whole chunk to the user.
   - **1–99%** — you take the more mechanical / repetitive part, the user takes the decision-dense part. Round an atomic chunk (a single config file, one import block) to whoever owns most of it rather than splitting it down the middle.
   For any chunk the user owns part or all of: write *your* part straight to disk, but do NOT write the user's part into the file. Instead, in the conversation, give two things in this order — first the **decision framing** (the exact file + location and the trade-offs to weigh), then below it **one working reference solution** that covers the user's whole part, under a clear "stuck? one way to do it" label. Framing first, reference last, so the user meets the decision before the answer; the reference is there so a stuck user can glance at it instead of starting another round-trip. Showing a reference in the console is *not* writing it for them — you never land the user's part; their typing it in themselves is the learning act. Then STOP and let the user write their part.
2. **The user lands their share.** The user writes their portion into the file themselves — ideally from the framing, falling back to the reference only when stuck. Do not write the user's share to disk for them.
3. **Review what the user landed.** Read the actual file on disk and review the part the user wrote — correctness, style, and whether the design intent was met (and that it fits the part you wrote). Acknowledge what is right first, then list issues by severity (must-fix vs. nice-to-have). Iterate if needed.
4. **Advance only after the code passes review.** Move to the next task only when the landed code is solid.

**Working agreement:**

- **Never fabricate.** Do not narrate fake tool calls or invent tool output, test results, or "it's green / it's done." Every such claim must come from a real executed tool — verify the artifact (`test -f` / `wc` / `grep` / actual test output) before claiming it exists or passes.
- **Verify the artifact at its referenced path before diagnosing.** When something looks broken, confirm the file is actually where it is referenced from before blaming the framework or mechanism.
- **Treat fresh IDE/LSP diagnostics skeptically.** A "cannot find module" or unresolved-symbol error right after creating a file is usually indexing lag — confirm with the authoritative compiler or test runner before acting on it.
- **Don't invent domain values.** Codes, keys, identifiers, and enum values must be checked against the real system, not guessed.
- **Review with calibration.** Categorize feedback by severity; praise what is correct so the rest of the feedback is trusted.
<!-- SMART:LEARNING:END -->
```

## Constraints

- `.smart/settings.json` is shared with distill: **always read-modify-write, never overwrite**. Preserve `knowledges_dir` and any other key you do not own.
- Only ever touch the marked region of `CLAUDE.local.md`; never clobber the user's other notes.
- All edits are idempotent — re-running the same command leaves the same end state, never a duplicate block or a duplicate `.gitignore` line.
- Use the Edit/Write tool for `.gitignore` (append a single line `.smart/`); never clobber the whole file. Skip it when `.smart/` is already ignored.
- `learning_ratios` is a two-level grid (layer → {`boilerplate`, `business`}); cells are integer percentages in `0..100` where the number is the user's hand-written share (`0` = you write it all, `100` = the user writes it all). Deep-merge on config — never drop layers or kinds the user did not name. An older flat `learning_ratios` (`boilerplate`/`core`/`database`) predates this grid; treat it as unset and use the grid defaults.
- Output in the same language as the user's conversation.
