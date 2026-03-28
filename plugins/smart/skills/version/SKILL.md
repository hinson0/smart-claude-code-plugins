---
name: version
description: This skill should be used when the user says "bump version", "update version", "release", "new version", or when preparing a release after merging to main. Also triggers proactively in the push pipeline, but only on the base branch (main). Supports plugin.json, package.json (including monorepo), and pyproject.toml.
argument-hint: "[base-branch] — defaults to main"
---

Analyze commits on the base branch, map changed files to their owning version files, and bump each version independently following semantic versioning (`a.b.c`).

**Important:** Version bumps only happen on the base branch (e.g. `main`). On feature branches, skip — version will be bumped after the branch merges to main.

## Steps

### 1) Determine base branch and check current branch

- If the user provided a base branch via `$0`, use it. Otherwise default to `main`.
- Run: `git branch --show-current`
- If the current branch is **not** the base branch, report "On feature branch `<branch>` — skipping version bump (bump after merge to `<base>`)" and **stop**.
- If the user explicitly invoked `/smart:version` (not via push pipeline), proceed regardless of branch — the user knows what they want.

### 2) Discover all version files

Scan the project for **all** version files. Collect every match:

```bash
# Claude Code plugins
find . -maxdepth 4 -path '*/.claude-plugin/plugin.json' -not -path '*/node_modules/*' 2>/dev/null

# Node.js / frontend (root + workspace packages)
find . -maxdepth 4 -name 'package.json' -not -path '*/node_modules/*' -not -path '*/.claude-plugin/*' 2>/dev/null

# Python
find . -maxdepth 4 -name 'pyproject.toml' -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null
```

Filter: only keep files that actually contain a `"version"` (JSON) or `version =` (TOML) field. Discard the rest.

If no version file found, report "No version file detected — skipping version bump" and **stop**.

Record the list as `VERSION_FILES` with their directory paths.

### 3) Collect commits to analyze

- Run: `git log <BASE_BRANCH>..HEAD --oneline`
- If no commits are found (e.g. already on base branch), fall back to commits since the last version bump: `git log $(git log --oneline --grep="bump version" | head -1 | awk '{print $1}')..HEAD --oneline`
- Exclude commits whose message matches `chore(version): bump` (previous version bump commits).
- If still no commits, report "No new commits — version unchanged" and stop.

Record as `COMMITS`.

### 4) Map commits to version files

For each commit in `COMMITS`:

1. Get the changed files: `git show --name-only --format="" <hash>`
2. For each changed file, **walk up its directory tree** to find the nearest version file:
   - At each directory level, check if any file from `VERSION_FILES` lives there (match by directory prefix).
   - The first (closest) match is the **owner** of that changed file.
   - If no version file is found in any ancestor, the file is **unowned** (skip it for versioning).
3. Record a mapping: `version_file → [list of commits that touched its scope]`

A single commit may map to **multiple** version files if it changed files across packages.

### 5) Determine bump type per version file

For each version file that has associated commits:

1. Read current version from the file:
   - **JSON** (`plugin.json`, `package.json`): read `"version"` field.
   - **TOML** (`pyproject.toml`): read `version` under `[project]`. If not found, check `[tool.poetry]`.

2. Analyze each associated commit's type prefix (Conventional Commits `<type>[!][(scope)]: <desc>`):

   | Condition | Bump |
   |-----------|------|
   | Type suffix `!` or commit body contains `BREAKING CHANGE` | **major** |
   | `feat` | **minor** |
   | `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `ci`, or other | **patch** |

3. Apply the **highest** bump:
   - Any major → `(a+1).0.0`
   - Else any minor → `a.(b+1).0`
   - Else → `a.b.(c+1)`

### 6) Apply new versions

For each version file to bump, update the `version` field using the Edit tool:
- **JSON**: update `"version": "<new_version>"`
- **TOML**: update `version = "<new_version>"`

### 7) Commit the version bumps

Stage all modified version files and create a **single** commit:

```bash
git add <all modified VERSION_FILES>
git commit -m "$(cat <<'EOF'
chore(version): bump version to <new_version>

<If multiple files bumped, list each:>
- <path>: <old> → <new> (<bump_type>)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

For a single version file, the commit message subject is:
`chore(version): bump version to <new_version>`

For multiple version files, the commit message subject is:
`chore(version): bump versions`
with the body listing each file's bump.

### 8) Output

Display a table:

```
| Version File | Type | Old | New | Bump | Key Commits |
|--------------|------|-----|-----|------|-------------|
| packages/frontend/package.json | Node.js | 1.2.0 | 1.3.0 | minor | feat(ui): ... |
| packages/backend/pyproject.toml | Python | 0.5.1 | 0.5.2 | patch | fix(api): ... |
```

## Constraints

- Do not modify any file other than the version files being bumped.
- Do not push — pushing is handled by the push/PR pipeline or the user.
- If no version file is detected or no new commits exist, do nothing.
- Never mix changes from different packages — each version file is bumped based only on commits that touched its scope.
