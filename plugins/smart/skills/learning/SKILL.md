---
name: learning
description: 'Toggle "learning mode" — a co-coding mode where the user writes the meaningful parts of the code themselves instead of you writing everything. Trigger on /smart:learning, or whenever the user wants to enable or disable hands-on participation in coding: phrases like "learning mode", "let me write part of the code", "I want to participate in coding", "co-code with me", "参与编码", "hands-on mode", "turn learning mode off", "change my coding share". State and the tunable per-bucket ratios live in `.smart/settings.json` (`learning` + `learning_ratios`, shared with distill); when on, participation rules are injected into `.claude/CLAUDE.local.md` so they persist across every future session; when off, that injected block is removed. Use this skill for any request about turning the user''s own involvement in writing code on or off, or retuning how much of each kind of code they hand-write.'
argument-hint: "[0|1|config] — 1=enable, 0=disable, config bucket=NN=retune ratios, empty=status"
---

Learning mode lets the user write the meaningful parts of the code by hand. The point is not to slow things down — it is that some decisions (core logic, data modeling) are where the user learns the most and where their domain knowledge matters most, so those parts are handed back to them instead of being written for them. How much of each kind of code is handed back is **configurable** per project.

This skill is a switch plus a small config. It keeps machine-readable state in `.smart/settings.json` **and** mirrors the actual behavior rules into `.claude/CLAUDE.local.md`, which Claude Code auto-loads into context at the start of every session. The settings file is the source of truth; the `CLAUDE.local.md` block is the mechanism that makes the rules persist without re-invoking this skill each session.

## Argument

| `$0`                       | Action                                                                          |
| -------------------------- | ------------------------------------------------------------------------------- |
| `1`                        | **Enable** — set `learning` to 1 and inject the participation block.             |
| `0`                        | **Disable** — set `learning` to 0 and remove the injected block.                 |
| `config` `[bucket=NN ...]` | **Configure** — update one or more ratios in `learning_ratios`.                  |
| _(empty)_                  | **Status** — report whether learning mode is on, the effective ratios, and drift.|

If `$0` is anything else, report the usage above and stop.

## The settings file: `.smart/settings.json`

This is the **same** project-level file distill uses — there is exactly one. Always read-modify-write it: preserve every key you do not own (especially distill's `knowledges_dir`). This skill owns two keys:

- **`learning`** — `0 | 1`, the on/off toggle.
- **`learning_ratios`** — optional object; the user's hand-written share per bucket, as integer percentages. Missing keys fall back to the defaults below.

  | Bucket        | Meaning                                          | Default |
  | ------------- | ------------------------------------------------ | ------- |
  | `boilerplate` | scaffolding / repetitive code the user writes     | `30`    |
  | `core`        | meaningful logic the user writes (a *minimum*)    | `60`    |
  | `database`    | table creation / schema / migrations / indexes    | `100`   |

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
- Whenever you need the **effective ratios**, read `learning_ratios` from the settings file and fill any missing bucket from the defaults table.

### 2) Enable (`$0 == 1`)

1. `mkdir -p <root>/.smart`.
2. **Write state.** Read `<root>/.smart/settings.json` if present, set `learning` to `1`, and write it back **preserving all other keys**. If absent, create `{"learning": 1}`.
3. **Ensure `.claude/CLAUDE.local.md` exists and is git-ignored.** If the file is absent, bootstrap it (and its `.gitignore` entry) by following `@../local/SKILL.md`. If it already exists, leave its content alone.
4. **Inject the participation block** (see "The participation block" below), substituting the effective ratios. Do it idempotently:
   - If the `<!-- SMART:LEARNING:BEGIN -->` … `<!-- SMART:LEARNING:END -->` markers already exist, replace everything between them (markers inclusive) — this refreshes a stale block after a ratio change or a version update.
   - Otherwise append the block to the end of the file, separated by one blank line.
5. **Ensure `.smart/` is git-ignored.** Check `git check-ignore -q .smart/settings.json`. If that fails (nothing ignores it yet), append the single line `.smart/` to `<root>/.gitignore` with the Edit/Write tool — create `.gitignore` if absent, never duplicate, never rewrite unrelated content. In repos that already ignore `.smart/`, this is a no-op.
6. **Apply immediately.** The rules are now active. Acknowledge that for the remainder of *this* session you will also follow them, not just future sessions.
7. **Report**: `learning = 1`, the effective ratios, block added vs. updated, git-ignore added vs. already in effect.

### 3) Disable (`$0 == 0`)

1. **Write state.** Read `<root>/.smart/settings.json` (create if needed), set `learning` to `0`, preserve other keys. Leave `learning_ratios` intact so the configured values survive for the next enable.
2. **Remove the injected block.** If `<root>/.claude/CLAUDE.local.md` exists and contains the markers, delete the region from `<!-- SMART:LEARNING:BEGIN -->` through `<!-- SMART:LEARNING:END -->` inclusive, plus one adjacent blank line so no gap is left. Leave every other line untouched. **Never delete the `CLAUDE.local.md` file itself**, and never touch the `.gitignore`.
   - If the file or the markers are absent, there is nothing to remove — say so.
3. **Stop applying.** Note that the participation rules no longer apply for the rest of this session.
4. **Report**: `learning = 0`, block removed vs. not present.

### 4) Configure (`$0 == config`)

1. **Parse the remaining tokens** as `bucket=NN` pairs (`boilerplate`, `core`, `database`); `NN` is an integer in `0..100`. Reject unknown buckets or out-of-range values with a short usage line and stop.
2. **If no valid pairs were given**, print the current effective ratios and the usage (`/smart:learning config boilerplate=40 core=70 database=100`), and note they can also be edited directly in `.smart/settings.json`. Then stop — do not guess values.
3. **Merge and persist.** Read settings (create if needed), merge the given buckets into `learning_ratios` (a partial update — untouched buckets keep their value), and write back preserving all other keys.
4. **Re-inject if active.** If `learning == 1`, refresh the `CLAUDE.local.md` block (step 2.4) so the new ratios take effect immediately. If learning is off, just persist — the values apply on the next enable.
5. **Report** the old → new ratios and whether the live block was refreshed.

### 5) Status (no argument)

1. Read `<root>/.smart/settings.json`; treat a missing file or missing `learning` key as `0`.
2. Resolve the effective ratios (configured values, with defaults filling the gaps).
3. Check whether `.claude/CLAUDE.local.md` contains the managed markers.
4. Report `learning = 0 | 1`, the effective ratios, and whether the block is present. **Flag drift**: if state is `1` but the block is missing (or state is `0` but the block is present), say so and offer to reconcile by re-running `/smart:learning 1` or `/smart:learning 0`.

## The participation block

Inject exactly this content between the markers, with `{boilerplate}`, `{core}`, `{database}` replaced by the effective ratios. **Localize the prose to the user's working language** — the language of their `CLAUDE.local.md` and conversation. The English below is the canonical version to translate; do not change its meaning, only its language.

```markdown
<!-- SMART:LEARNING:BEGIN -->
## Learning mode (ON)

The user wants to write the meaningful parts of the code themselves. When implementing, hand the listed portions back to the user instead of writing them yourself. The percentages are the user's hand-written share (configured in `.smart/settings.json` → `learning_ratios`):

- **Boilerplate / scaffolding**: the user writes ~{boilerplate}%. You write the remainder, but leave their share as clearly-marked TODO stubs.
- **Core business logic**: the user writes at least ~{core}% of the meaningful decision points (algorithms, branching, error-handling strategy, data structures). Leave those as TODO stubs, explain the trade-offs first, then stop and ask the user to fill them in.
- **Database (table creation / schema / migrations / indexes)**: the user designs ~{database}% of it. At 100%, write none of it — provide the requirements and constraints only.

When you reach one of these portions: build the surrounding context, write clear signatures and comments, mark the spot with a TODO, then STOP and wait for the user to submit their code before continuing. Frame each request as a real design decision, not busywork — name the file and location, and the trade-offs to weigh.
<!-- SMART:LEARNING:END -->
```

## Constraints

- `.smart/settings.json` is shared with distill: **always read-modify-write, never overwrite**. Preserve `knowledges_dir` and any other key you do not own.
- Only ever touch the marked region of `CLAUDE.local.md`; never clobber the user's other notes.
- All edits are idempotent — re-running the same command leaves the same end state, never a duplicate block or a duplicate `.gitignore` line.
- Use the Edit/Write tool for `.gitignore` (append a single line `.smart/`); never clobber the whole file. Skip it when `.smart/` is already ignored.
- Ratios are integer percentages in `0..100`; `core` is a *minimum* share, `database` defaults to 100 (user designs the schema entirely).
- Output in the same language as the user's conversation.
