# smart-claude-code-plugins

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md) | [繁體中文](./README_TW.md) | [한국어](./README_KO.md) | [日本語](./README_JA.md)

</div>

> Done coding? Just say **"create PR"** — it handles check, commit, push, and PR for you.
>
> Don't want a PR, just a push? Say **"push"**.
>
> Just commit? Say **"commit"**.
>
> Or use slash commands: `/smart:pr`, `/smart:push`, `/smart:commit`.

A Claude Code plugin that takes over the moment you finish writing code. Just say what you want — it runs checks, commits, pushes, and opens a PR to `main`. Zero extra steps. Just say `push` — it auto-splits multiple features, generates commit messages, and pushes:

![demo](./assets/imgs/en.png)

---

## Quick Start

**1. Install the plugin** _(recommended)_

In Claude Code, register the marketplace first:

```
/plugin marketplace add hinson0/smart-claude-code-plugins
```

Then install the plugin from this marketplace:

```
/plugin install smart@smart-claude-code-plugins
```

---

## Features

**Core Pipeline**

- **Fail-Fast Pipeline** — Any step fails, everything stops immediately. No partial pushes or broken PRs.
- **Auto CI Detection** — Reads `.github/workflows/*.yml` and runs matching checks locally (ruff, pytest, mypy, eslint, tsc, vitest, jest, go test, turbo, and more). Auto-detects package manager from lock files.
- **Two-Phase Smart Commit Grouping** — Phase 1 hard-splits by type (feat vs fix vs refactor), Phase 2 semantically splits within the same type by purpose. No unrelated changes sneak into a single commit.
- **Conventional Commits** — All commit messages automatically follow `<type>(<scope>): <description>` format. Respects project `CLAUDE.md` overrides and existing `git log` style.
- **Auto Version Bump** — Detects version files (`plugin.json`, `package.json`, `pyproject.toml`), analyzes commit types, and bumps semantic version before push. In monorepos, maps changed files to their owning package and bumps each independently.
- **Auto GitHub Repo Creation** — No remote configured? It creates a private repo on GitHub, sets it as origin, and pushes — all automatically.
- **Consistent Language** — PR title, summary, and test plan automatically use the same language as commit messages. Defaults to English; overridable via project `CLAUDE.md`.

**Protection & Automation**

- **File Protection Hook** — Prevent Claude from editing sensitive files (`.env`, lock files, etc.). Configure per-project via `.claude/.protect_files.jsonc` — supports exact filename matching and glob patterns (`*`, `**`).
- **Session Hooks** — Greet on session start, goodbye on session end (via macOS `say` TTS).
- **Session Logs** — Every tool call is logged to `.claude/session-logs/` with full input data for post-session debugging and audit.

**Utilities**

- **Visual Progress Tracking** — Pipeline phases display as a live task list with pending/active/completed status, timing, and token usage.
- **HUD / Statusline Installer** — One command to install a feature-rich statusline showing model, git branch, context usage, rate limits, system stats, and tool call counts. Supports install / remove / reset, with user or project scope.
- **Help Overview** — `/smart:help` dynamically scans and lists all skills, hooks, and agents with descriptions.
- **Joke Teller Agent** — Tells a programmer joke to lighten the mood during work.

---

## Usage

**💬 Natural language** — just describe what you want:

| What you say | What happens |
|---|---|
| "commit" / "save my work" / "done" | Smart commit only (stage + group + commit) |
| "push" / "push to origin" | check → commit → version → push |
| "create PR" / "open a pull request" | check → commit → version → push → PR |

**⌨️ Slash commands** — for precise control:

| Command | What it does |
|---|---|
| `/smart:commit` | Stage & commit only (smart grouping, auto message) |
| `/smart:version [base]` | Analyze commits and bump version (auto-detects version files; only runs on the base branch) |
| `/smart:push` | check → commit → version → push (no PR) |
| `/smart:pr [base]` | Full pipeline: check → commit → version → push → PR (default base: `main`) |
| `/smart:hud [rm\|reset]` | Install, remove, or reset statusline (`--user` / `--project` scope) |
| `/smart:help [skill\|hook\|agent]` | Show overview of all plugin components (or filter by category) |

---

## Pipeline

### Overview

```
/smart:pr
    │
    ├── 1. check   — Auto CI detection & local execution
    │
    ├── 2. commit  — Two-phase semantic analysis & smart grouping
    │
    ├── 3. version — Semantic version bump (monorepo-aware)
    │
    ├── 4. push    — Push to origin (auto-creates GitHub repo if needed)
    │
    └── 5. pr      — Generate & create Pull Request
```

Each phase is a standalone skill linked via `@../path/SKILL.md` references. Any failure stops the entire pipeline immediately.

### Phase 1: Check

Automatically detects your project's CI configuration and runs the corresponding checks locally.

**How it works:**

1. Scans `.github/workflows/*.yml` for tool keywords
2. Identifies matching tools: `ruff`, `pytest`, `mypy`, `eslint`, `tsc`, `vitest`, `jest`, `go test`, `golangci-lint`, `turbo`, and more
3. Detects your package manager from lock files (`uv.lock` → `uv run`, `pnpm-lock.yaml` → `pnpm`, `package-lock.json` → `npm run`, `go.mod` → direct execution)
4. Runs all detected checks sequentially — any failure halts the pipeline
5. Allows `ruff --fix` to auto-fix issues before failing

**Supported ecosystems:**

| Ecosystem | Tools |
|---|---|
| Python | ruff (lint + format), pytest, mypy |
| JavaScript / TypeScript | eslint, tsc, vitest, jest, turbo |
| Go | go test, golangci-lint |

If no `.github/workflows/` directory is found, this phase is skipped silently.

### Phase 2: Commit

The core intelligence — analyzes all pending changes and produces clean, well-grouped commits.

**Two-phase grouping algorithm:**

1. **Hard split by type** — Changes are categorized by Conventional Commit type (`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`). Different types are **always** separate commits.
2. **Semantic split by purpose** — Within the same type, changes serving different purposes are further split. For example, two independent `feat` additions become two separate commits.

The `scope` field describes *where* the change happened — it does not affect grouping. Grouping is driven purely by type + purpose.

**Commit message generation priority:**

1. Project `CLAUDE.md` — if it specifies a commit format, that takes precedence
2. `git log` style — if existing commits follow a consistent style, it's matched
3. Default — Conventional Commits: `<type>(<scope>): <description>`

**Execution:**
- Single group → `git add -A` + commit
- Multiple groups → each group gets `git add <specific files>` + HEREDOC commit
- Loops until the working tree is clean (handles cases where hooks or formatters modify files during commit)

### Phase 3: Version

Analyzes commit history and automatically bumps the semantic version number.

**Semver rules:**

| Commit pattern | Bump | Example |
|---|---|---|
| `feat` | minor | 0.1.0 → 0.2.0 |
| `fix`, `refactor`, `perf`, `docs`, etc. | patch | 0.1.0 → 0.1.1 |
| `BREAKING CHANGE` or `!` suffix | major | 0.1.0 → 1.0.0 |

**Version file detection:**

Scans for `plugin.json`, `package.json`, and `pyproject.toml` in the project root and workspace directories.

**Monorepo support:**

Each changed file is traced up the directory tree to find the closest version file (the "closest owner" strategy). Each package is bumped independently based on its own commits.

**Behavior:**
- Only runs on the base branch (skipped on feature branches)
- Skipped if no new commits since the last version bump
- All version changes are committed as a single `chore(version): bump version to X.X.X`

### Phase 4: Push

Pushes commits to the remote repository.

If no `origin` remote is configured:
1. Creates a new **private** repository on GitHub via `gh repo create`
2. Adds it as `origin`
3. Pushes with `git push -u origin HEAD`

### Phase 5: PR

Generates and creates a Pull Request on GitHub.

**How it works:**

1. Detects the current branch and language (inherited from commit phase, or inferred from `git log`)
2. Asks for the target branch via prompt (defaults to `main`)
3. Checks for existing open PRs with the same head branch — if found, shows the URL and stops
4. Collects all commits between `BASE_BRANCH..HEAD`
5. Generates PR title:
   - Single commit → uses the commit message directly
   - Multiple commits → generates a summary title
6. Generates PR body in Markdown:
   - **Summary** — bullet points describing the changes
   - **Commits** — full commit list
   - **Test Plan** — auto-generated `- [ ]` checklist based on commit types (e.g., `feat` → "verify new feature works", `fix` → "confirm bug is resolved")
7. Creates the PR via `gh pr create`

The language of the PR title, body, and test plan follows the language used in commit messages.

---

## File Protection

Prevent Claude from editing sensitive files by creating `.claude/.protect_files.jsonc` in your project root:

```jsonc
// Protected files — Claude Code cannot edit these
// Exact filenames match precisely; patterns with * or ** use glob matching
[
  ".env",
  "package-lock.json",
  "pnpm-lock.yaml",
  "yarn.lock",
  "*.secret",
  "config/production/**"
]
```

**Matching rules:**

| Pattern | Match type | Example |
|---|---|---|
| No wildcards | Exact filename | `.env` blocks `.env` but allows `.env.example` |
| `*` | Single-level glob | `*.lock` matches `pnpm-lock.yaml` |
| `**` | Recursive glob | `config/production/**` matches `config/production/db/secret.json` |

The hook intercepts `Edit` and `Write` tool calls via `PreToolUse`. If a protected file is matched, the operation is blocked with an error message.

---

## HUD (Statusline)

Install a feature-rich statusline with one command:

```
/smart:hud
```

![hud](./assets/imgs/hud.png)

**What it shows (6 lines):**

| Line | Content |
|------|---------|
| 1 | Session ID / session name, model@version, total cost (USD) |
| 2 | Directory, git branch (dirty/ahead/behind/stash), last commit time, worktree name, battery |
| 3 | Context progress bar + tokens + cache, rate limits (5h/7d) with reset countdown, session duration, agent name |
| 4 | CPU, memory, disk, uptime, runtime versions (Node/Python/Go/Rust/Ruby), local IP |
| 5 | Tool call stats (Bash/Skill/Agent/Edit counts, parsed from transcript in real time) |
| 6 | Output style, vim mode (shown only when enabled) |

**Commands:**

| Command | Action |
|---------|--------|
| `/smart:hud` | Install to user scope (backs up existing statusline automatically) |
| `/smart:hud --project` | Install to project scope (`.claude/settings.json`, this project only) |
| `/smart:hud rm` | Remove statusline (auto-detects which scope is installed) |
| `/smart:hud reset` | Restore your previous statusline from backup |

**Note:** Requires `jq`. The statusline script is macOS-optimized (uses `pmset` for battery, `sysctl` for system info).

---

## Agents

### Joke Teller

Tells a programmer joke to lighten the mood.

```
"tell me a joke" / "I need a laugh"
```

- Detects conversation language and tells jokes accordingly
- Short format (2–4 sentences, punchline style — no Q&A templates)
- Includes a gentle self-care reminder (hydrate, stretch, rest)

---

## Session Hooks

The plugin includes hooks that trigger at session boundaries and tool calls:

| Hook | Trigger | What it does |
|------|---------|--------------|
| `greet.sh` | `SessionStart` | Plays a welcome message via macOS TTS (`say`) |
| `goodbye.sh` | `SessionEnd` | Plays a farewell message via macOS TTS (`say`) |
| `session-logs.py` | `PreToolUse` (all tools) | Logs every tool call's full input to `.claude/session-logs/<date>/<session_id>.json` |
| `protect-files.py` | `PreToolUse` (Edit/Write) | Blocks edits to protected files (see [File Protection](#file-protection)) |

All hooks use `${CLAUDE_PLUGIN_ROOT}` for path resolution. TTS hooks run in the background (`nohup &`) to avoid blocking Claude Code.

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — for push (auto-create remote) and PR creation
- `jq` — for HUD statusline only (optional otherwise)

---

## Author

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
