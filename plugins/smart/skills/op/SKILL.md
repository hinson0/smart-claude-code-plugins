---
description: This skill should be used when the user says "analyze","optimize plugins", "disable unused plugins", "save context", "reduce context usage", "which plugins do I need", "clean up plugins", "focus context", "trim plugins", or wants to detect the project type and disable irrelevant plugins to save context window space. Invoked explicitly via /smart:op.
argument-hint: No arguments needed. Automatically detects project type and recommends plugin changes.
model: sonnet
---

# Analyze — Context-Aware Plugin Optimizer

Detect the current project type, identify enabled plugins irrelevant to this project, and offer to disable them — reducing context window overhead from always-loaded plugin metadata.

## Why This Matters

Every enabled plugin contributes ~100-500 tokens of metadata (name + description) to the context window on every turn. Disabling plugins not relevant to the current project reclaims that space for actual work.

## Steps

### 1) Detect project type

Scan the current working directory root for indicator files. Consult `references/plugin-relevance.md` § "Project Type Detection" for the full mapping.

Quick reference:

| Indicator                                                            | Type                                                  |
| -------------------------------------------------------------------- | ----------------------------------------------------- |
| `pyproject.toml`, `requirements.txt`, `setup.py`, `Pipfile`          | python                                                |
| `package.json`                                                       | javascript (inspect deps for framework — see step 1b) |
| `tsconfig.json`                                                      | typescript                                            |
| `Cargo.toml`                                                         | rust                                                  |
| `go.mod`                                                             | go                                                    |
| `Gemfile`                                                            | ruby                                                  |
| `*.sln`, `*.csproj`                                                  | dotnet                                                |
| `build.gradle`, `pom.xml`                                            | java                                                  |
| `pubspec.yaml`                                                       | flutter                                               |
| `.claude-plugin/plugin.json` or child `*/.claude-plugin/plugin.json` | claude-plugin                                         |

**1b) Framework detection** — if `package.json` exists, read `dependencies` and `devDependencies` keys to identify frameworks (react, vue, next, svelte, angular, react-native, express, etc.). Add each detected framework as an additional type tag.

**1c) Supabase detection** — check `package.json` deps or Python deps for `supabase` / `@supabase/supabase-js`. If found, add `supabase` tag.

If multiple indicators exist, the project has multiple types (e.g., a monorepo with Python + TypeScript).

Output the detected types:

```
Detected project type(s): python, typescript, react
```

If no indicator files are found, report "Unable to detect project type — no changes recommended" and stop.

### 2) Read enabled plugins

Read both settings files to determine the effective plugin state:

1. **Global**: Read `~/.claude/settings.json` → extract `enabledPlugins` map.
2. **Project**: Read `.claude/settings.json` (project root) → extract `enabledPlugins` map if it exists.
3. **Merge**: Project-level entries override global entries. A plugin is active if its effective value is `true`.

Collect all effectively active plugins — these are the ones to classify.

### 3) Classify each plugin

Consult `references/plugin-relevance.md` for the full relevance mapping.

For each enabled plugin:

1. Extract the plugin name (the part before `@`).
2. Check the **Universal** list — if the plugin is universal, mark as **keep**.
3. Check the **Conditional** list — if the plugin's required project types overlap with the detected types, mark as **keep**. Otherwise, mark as **recommend disable**.
4. If the plugin is not in either list, apply the **heuristic rules** from the references file (name-based matching). When uncertain, default to **keep**.

### 4) Present recommendations

**If there are plugins to recommend disabling:**

Display a summary table:

```
Project type: python

| Plugin            | Status           | Reason                                      |
|-------------------|------------------|---------------------------------------------|
| pyright-lsp       | Keep             | Python LSP — matches project type            |
| typescript-lsp    | Recommend disable| TypeScript LSP — no TS/JS in this project    |
| frontend-design   | Recommend disable| Frontend design — no web frontend detected   |
| playwright        | Recommend disable| Browser testing — no web project detected     |
| ui-ux-pro-max     | Recommend disable| UI/UX design — no frontend detected           |
| plugin-dev        | Recommend disable| Plugin dev — not a Claude Code plugin repo    |
```

Then use AskUserQuestion to confirm:

- List each plugin recommended for disabling with a one-line reason
- Ask: "Disable these plugins for this project? (They can be re-enabled anytime in .claude/settings.json)"

**If confirmed:**

Edit `.claude/settings.json` (project-level, not global `~/.claude/settings.json`) — add or update each confirmed plugin's value to `false` in the `enabledPlugins` map. If `.claude/settings.json` does not exist, create it with the `enabledPlugins` key. If it exists but has no `enabledPlugins` key, add it. Use the Edit tool for precision; do not rewrite the entire file. Never modify the global `~/.claude/settings.json`.

**If the user declines or wants to keep some:**

Respect the user's choice. Only disable the ones explicitly approved.

**If no plugins to recommend disabling:**

Report: "All enabled plugins are relevant to this project — no changes needed."

### 5) Report

Display a final summary:

- Detected project type(s)
- Plugins disabled (count and names)
- Plugins kept (count)
- Reminder: "Run `/smart:op` again after switching projects to re-optimize."

## Edge Cases

- **Monorepo with mixed types**: If both Python and TypeScript indicators exist, keep plugins relevant to either type.
- **Empty/new repo**: No indicator files → cannot determine type → do not recommend any changes.
- **Plugin repo that is also a dev project**: If both `.claude-plugin/plugin.json` and language indicators exist, keep both plugin-dev tools and language tools.

## Additional Resources

### Reference Files

- **`references/plugin-relevance.md`** — Complete mapping of known plugins to project types, detection indicators, framework detection rules, and heuristic fallback rules for unknown plugins.
