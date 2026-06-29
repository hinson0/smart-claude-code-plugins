# smart-codex-plugin

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

A plugin for **Claude Code** and **Codex** that takes over the moment you finish writing code. Just say what you want — it runs checks, commits, pushes, and opens a PR to `main`. Zero extra steps. Just say `push` — it auto-splits multiple features, generates commit messages, and pushes:

![demo](./assets/imgs/en.png)

---

## Quick Start

The plugin ships **both manifests** (`.claude-plugin/` for Claude Code and `.codex-plugin/` for Codex), so it installs natively in either host. Pick yours:

### Claude Code

Add the marketplace, then install the plugin — run these inside Claude Code:

```
/plugin marketplace add hinson0/smart-claude-code-plugins
/plugin install smart@smart
```

> Already cloned locally? Point the marketplace at your clone instead: `/plugin marketplace add /path/to/smart-claude-code-plugins`. After installing, restart the session so skills, hooks, and the statusline load.

### Codex

The friendliest way is right inside a Codex session — no clone needed:

1. Run `/plugins`
2. Select **[Add Marketplace]**
3. Paste the source — `hinson0/smart-claude-code-plugins` (owner/repo) or the full git URL — and press Enter
4. Open the **Smart** marketplace, then install the **smart** plugin

> Prefer the CLI? It fetches straight from Git — no clone needed:
>
> ```bash
> codex plugin marketplace add hinson0/smart-claude-code-plugins
> codex plugin add smart@smart
> ```

---

## Features

**Core Pipeline**

- **Fail-Fast Pipeline** — Any step fails, everything stops immediately. No partial pushes or broken PRs.
- **Auto CI Detection** — Reads `.github/workflows/*.yml` and runs matching checks locally (ruff, pytest, mypy, eslint, tsc, vitest, jest, go test, turbo, and more). Auto-detects package manager from lock files.
- **Two-Phase Smart Commit Grouping** — Phase 1 hard-splits by type (feat vs fix vs refactor), Phase 2 semantically splits within the same type by purpose. No unrelated changes sneak into a single commit.
- **Conventional Commits** — All commit messages automatically follow `<type>(<scope>): <description>` format. Respects project `AGENTS.md` / `CLAUDE.md` overrides and existing `git log` style.
- **Auto Version Bump** — Detects version files (`.codex-plugin/plugin.json`, `package.json`, `pyproject.toml`), analyzes commit types, and bumps semantic version before push. In monorepos, maps changed files to their owning package and bumps each independently.
- **Auto GitHub Repo Creation** — No remote configured? It creates a private repo on GitHub, sets it as origin, and pushes — all automatically.
- **Consistent Language** — PR title, summary, and test plan automatically use the same language as commit messages. Defaults to English; overridable via project `AGENTS.md` / `CLAUDE.md`.

**Protection & Automation**

- **Session Hooks** — Greet on session start, goodbye on session end (via macOS `say` TTS).
- **Session Logs** — Every tool call is logged to `.smart/session-logs/` with full input data for post-session debugging and audit.

**Utilities**

- **Visual Progress Tracking** — Pipeline phases display as a live task list with pending/active/completed status, timing, and token usage.
- **HUD / Statusline Installer** — One command to install a feature-rich statusline showing model, git branch, context usage, rate limits, system stats, and tool call counts. Two install levels (minimal / full) plus restore from backup, user scope.
- **Help Overview** — `/smart:help` dynamically scans and lists all skills, hooks, and agents with descriptions.
- **Joke Teller Agent** — Tells a programmer joke to lighten the mood during work.
- **Bundled Coding Rules** — Pre-written rule files (e.g. Pydantic V2 standards) in `rules/`. Symlink any file to your project's `.claude/rules/` to activate it.
- **Session Knowledge Distillation** — `/smart:distill` extracts the valuable Q&A from your current session, clusters it into topic-keyed markdown files, and writes them to a knowledge base. The target directory comes from the local `.smart/settings.json`; when it's missing, `/smart:distill` asks via `AskUserQuestion` whether to reuse the global `~/.smart/settings.json` or set up a local one — and asks for a directory when neither exists — then saves the choice locally so later runs are silent. The directory prompt stays in the main session; the heavy extraction and file-writing then run in a background **fork**, so the main context receives only a short summary. Default `.smart/knowledges/`; a `{date}` token enables date-nested dirs like `~/knowledges/md/{date}`. A duplicate/new/diff comparison appends instead of duplicating on re-distill, and reviewed files (`.printed.md` or with a sibling PDF) are never touched.
- **Workflow Model Tiering** — `/smart:wfb` makes Workflow scripts token-lean: it tiers each `agent()` by difficulty (haiku for mechanical work, sonnet for the body, opus for convergence and important/hard implementation), prunes calls before fan-out, and constrains output with schemas. Applied automatically whenever a Workflow script is being authored.
- **Clipboard Screenshot Uploader** — `/smart:sendshot` installs a cross-platform `sendshot` shell function that captures the clipboard image and uploads it to a remote host (e.g. EC2) over `scp`, then prints and re-copies the remote path. Works on WSL (Windows clipboard via PowerShell) and macOS (`pngpaste`/`osascript`). Under zsh it also binds **`Ctrl+G`** to fire sendshot from any prompt. Config — host, key, remote dir — lives in `~/.smart/settings.json` and is read at runtime, so changing the host never needs a reinstall; the remote dir is auto-created via `mkdir -p`.
- **Learning Mode** — `/smart:learning 1` turns on a co-coding mode where *you* write the meaningful parts by hand: Claude leaves the configured share of boilerplate (~30%), core logic (~60%), and database schema (100%) as TODO stubs and stops for you to fill them in. The toggle and the tunable per-bucket ratios live in `.smart/settings.json` (`learning` + `learning_ratios`, shared with distill, under the git-ignored `.smart/` dir); enabling injects the rules into `.claude/CLAUDE.local.md` so they persist across every session, `/smart:learning config boilerplate=40 core=70` retunes the shares, and `/smart:learning 0` removes the block.

---

## Usage

**💬 Natural language** — just describe what you want:

| What you say | What happens |
|---|---|
| "commit" / "save my work" / "done" | Smart commit only (stage + group + commit) |
| "push" / "push to origin" | commit → version → push |
| "create PR" / "open a pull request" | check → commit → version → push → PR |

**⌨️ Slash commands** — for precise control:

| Command | What it does |
|---|---|
| `/smart:commit` | Stage & commit only (smart grouping, auto message) |
| `/smart:version [base]` | Analyze commits and bump version (auto-detects version files; only runs on the base branch) |
| `/smart:push` | commit → version → push (no PR) |
| `/smart:pr [base]` | Full pipeline: check → commit → version → push → PR (default base: `main`) |
| `/smart:hud [0\|1\|2\|reset\|normal\|all]` | Install statusline (`1`/`normal`=minimal, `2`/`all`=full) or restore backup (`0`/`reset`), user scope |
| `/smart:help [skill\|hook\|agent]` | Show overview of all plugin components (or filter by category) |
| `/smart:distill [dir]` | Distill the current session into topic-keyed knowledge files (default `.smart/knowledges/`) |
| `/smart:wfb` | Token-lean, model-tiered guidance for authoring Workflow scripts (haiku/sonnet/opus by difficulty) |
| `/smart:sendshot [install\|config\|uninstall]` | Install the cross-platform `sendshot` function (clipboard image → `scp` to remote → copy remote path); config in `~/.smart/settings.json` |
| `/smart:learning [0\|1\|config]` | Toggle learning mode — *you* hand-write part of the code; per-bucket shares (boilerplate/core/DB) configurable in `.smart/settings.json`. `1`=on, `0`=off, `config bucket=NN`=retune, empty=status. Rules persisted in `.claude/CLAUDE.local.md` |

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

1. Project `AGENTS.md` / `CLAUDE.md` — if it specifies a commit format, that takes precedence
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
- Runs on any branch (main and feature branches)
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

## Bundled Rules

The plugin ships pre-written coding rule files in `rules/`. Activate any rule in your project by symlinking it to `.claude/rules/`:

```bash
ln -s /path/to/plugin/rules/pydantic-v2.md .claude/rules/pydantic-v2.md
```

**Available rules:**

| Rule file | What it enforces |
|---|---|
| `pydantic-v2.md` | Pydantic V2 standards: `ConfigDict`, validators, discriminated unions, `TypeAdapter`, `RootModel`, `SecretStr`, `pydantic-settings`, V1→V2 migration |
| `python-3.14.md` | Python 3.14 standards: deferred annotations, `[T]` generics, `@override`, `Self`, `TaskGroup`, `StrEnum`, `datetime.UTC`, subinterpreters, `match` guards |
| `fastapi.md` | FastAPI 0.115+ standards: `Annotated` dependencies, `lifespan`, `APIRouter` organization, `BackgroundTasks`, `dependency_overrides`, security scopes |
| `sqlalchemy-v2.md` | SQLAlchemy 2.0 standards: `DeclarativeBase`, `Mapped[T]`, naming conventions, async sessions, `AsyncAttrs`, `selectinload`, UPSERT, Alembic |

Rules are inactive by default — symlink only what's relevant to your project.

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
| `/smart:hud` · `/smart:hud 2` · `/smart:hud all` | Install full statusline (all 6 lines) to user scope, auto-backup |
| `/smart:hud 1` · `/smart:hud normal` | Install minimal statusline (session + ctx only) |
| `/smart:hud 0` · `/smart:hud reset` | Restore your previous statusline from backup |

**Note:** Cross-platform (macOS + Linux/WSL/Ubuntu) — auto-detects the OS and picks the right tools for battery, CPU, memory, and IP. Requires `jq`; if it's missing, `/smart:hud` auto-installs it (apt/dnf/pacman/apk/brew).

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
| `session-logs.py` | `PreToolUse` (all tools) | Logs every tool call's full input to `.smart/session-logs/<date>/<session_id>.json` |

The bundled hook config uses `${CLAUDE_PLUGIN_ROOT}` for path resolution in Claude-compatible hosts. TTS hooks run in the background (`nohup &`) to avoid blocking the host process.

---

## Requirements

- **Claude Code** or **Codex** (with plugin support) — the plugin ships both manifests and runs natively in either
- `git`
- [`gh` CLI](https://cli.github.com) — for push (auto-create remote) and PR creation
- `jq` — for HUD statusline only (optional otherwise)

---

## Author

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
