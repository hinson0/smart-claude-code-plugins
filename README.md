# smart-claude-code-plugin

<div align="center">

🌐 [English](./README.md) | [简体中文](./README_CN.md)

</div>

> Done coding? Just run `/smart:pr` — it handles everything from there.

A Claude Code plugin that takes over the moment you finish writing code: runs checks, commits, pushes, and opens a PR to `main`. Zero extra steps.

---

## Quick Start

**1. Install the plugin**

In Claude Code, register the marketplace and install:

```
/plugin marketplace add hinson0/smart-claude-code-plugin
```

```
/plugin install smart@smart-claude-code-plugin
```

**2. Authenticate GitHub CLI** _(one-time setup)_

```bash
gh auth login
```

**3. That's it. Run this in any repo:**

```
/smart:pr
```

It will automatically: detect CI checks → run them locally → stage & commit → push → open a PR on GitHub.

---

## How It Works

```
/smart:pr
    │
    ├── 1. check   — reads .github/workflows/*.yml, runs matching local checks
    │                (ruff/pytest, eslint/tsc, go test — skips if no CI config)
    │
    ├── 2. commit  — semantic diff analysis, auto-generates commit messages
    │                (splits into multiple commits if independent features detected)
    │
    ├── 3. push    — pushes to origin
    │                (auto-creates GitHub repo if origin is not configured)
    │
    └── 4. pr      — opens a Pull Request with auto-generated title & body
```

Any step that fails stops the pipeline immediately.

---

## All Commands

| Command | What it does |
|---|---|
| `/smart:pr [base]` | Full pipeline: check → commit → push → PR (default base: `main`) |
| `/smart:push` | check → commit → push (no PR) |
| `/smart:commit` | Stage & commit only (smart grouping, auto message) |
| `/smart:check` | Run local checks inferred from CI config only |

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- `git`
- [`gh` CLI](https://cli.github.com) — for push (auto-create remote) and PR creation

---

## Author

**Hinson** · [GitHub](https://github.com/hinson0)

## License

MIT
