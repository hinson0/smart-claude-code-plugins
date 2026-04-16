---
description: This skill should be used when the user says "bump version", "update version", "release", "new version", "version bump", "prepare release", "increment version", or when preparing a release. Also triggers proactively in the push pipeline on any branch. Supports plugin.json, package.json (including monorepo), pyproject.toml, and app.json (Expo/React Native).
argument-hint: "[base-branch] — defaults to main"
model: claude-sonnet-4-6
---

Analyze commits since the last version bump (or since branching from the base), map changed files to their owning version files, and bump each version independently following semantic versioning (`a.b.c`).

## Steps

### 1) Determine base branch and current branch

- Use the base branch from `$0` if provided; otherwise default to `main`.
- Run: `git branch --show-current` — record as `CURRENT_BRANCH`.

### 2) Discover all version files

Scan the project for all version files:

```bash
# Claude Code plugins
find . -maxdepth 4 -path '*/.claude-plugin/plugin.json' -not -path '*/node_modules/*' 2>/dev/null

# Node.js / frontend (root + workspace packages)
find . -maxdepth 4 -name 'package.json' -not -path '*/node_modules/*' -not -path '*/.claude-plugin/*' 2>/dev/null

# Python
find . -maxdepth 4 -name 'pyproject.toml' -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null

# Expo / React Native
find . -maxdepth 4 -name 'app.json' -not -path '*/node_modules/*' 2>/dev/null
```

Filter: keep only files that contain a `"version"` (JSON) or `version =` (TOML) field. Discard the rest.

**Special case for `app.json`:** The version field is nested under `expo.version`, not at the root level. When filtering, check that the file contains both `"expo"` and `"version"` keys. When a root-level `package.json` already exists in the same directory, skip `app.json` to avoid double-bumping the same project (the `package.json` takes precedence for Node tooling).

If no version file is found, report "No version file detected — skipping version bump" and **stop**.

Record the results as `VERSION_FILES` with their directory paths.

### 3) Collect commits to analyze

Gather new commits with a fallback chain:

1. Run: `git log <BASE_BRANCH>..HEAD --oneline`
2. If empty (e.g. already on base branch), locate the last version bump commit:
   ```bash
   LAST_BUMP=$(git log --all --oneline --grep="chore(version): bump" -1 --format="%H")
   ```
   - If found: `git log ${LAST_BUMP}..HEAD --oneline`
   - If not found (no prior bump): `git log -20 --oneline`
3. Exclude commits matching `chore(version): bump` (previous version bumps).
4. If no commits remain, report "No new commits — version unchanged" and **stop**.

Record as `COMMITS`.

### 4) Map commits to version files

Fetch all commits and their changed files in a **single command** (avoids per-commit shell calls):

```bash
git log <BASE_BRANCH>..HEAD --name-only --format="COMMIT:%H" | grep -v '^$'
```

Parse the output: lines starting with `COMMIT:` are commit hashes; subsequent non-empty lines are files changed by that commit.

For each changed file, walk up the directory tree to find the nearest version file:
- At each level, check if any `VERSION_FILES` entry resides in that directory (match by directory prefix).
- The first (closest) match is the **owner** of that changed file.
- If no version file is found in any ancestor, the file is **unowned** — skip it.

Record the mapping: `version_file → [list of commits that touched its scope]`

A single commit may map to **multiple** version files if it changed files across packages.

### 5) Determine bump type per version file

For each version file with associated commits:

1. Read current version:
   - **JSON** (`plugin.json`, `package.json`): read root-level `"version"` field.
   - **Expo** (`app.json`): read `expo.version` (nested under the `"expo"` key).
   - **TOML** (`pyproject.toml`): read `version` under `[project]`. If absent, check `[tool.poetry]`.

2. Classify each commit using Conventional Commits (`<type>[!][(scope)]: <desc>`):

   | Condition                                                          | Bump      |
   | ------------------------------------------------------------------ | --------- |
   | Type suffix `!` or body contains `BREAKING CHANGE`                 | **major** |
   | `feat`                                                             | **minor** |
   | `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `ci`, or other | **patch** |

3. Apply the **highest** bump:
   - Any major → `(a+1).0.0`
   - Else any minor → `a.(b+1).0`
   - Else → `a.b.(c+1)`

### 6) Apply new versions

Update the `version` field in each version file using the Edit tool:
- **JSON** (`plugin.json`, `package.json`): match and replace root-level `"version": "<old_version>"`.
- **Expo** (`app.json`): the version is nested — match the surrounding context to avoid ambiguity:
  ```json
  "expo": {
    ...
    "version": "<old_version>",
  ```
  Replace only the `"version"` line inside the `expo` block.
- **TOML**: `version = "<new_version>"`

### 7) Commit the version bumps

Stage all modified version files and create a **single** commit:

- Single version file — subject: `chore(version): bump version to <new_version>`
- Multiple version files — subject: `chore(version): bump versions`, body lists each bump.

```bash
git add <all modified VERSION_FILES>
git commit -m "$(cat <<'EOF'
chore(version): bump version to <new_version>

- <path>: <old> → <new> (<bump_type>)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 8) Output

Display a summary table:

```
| Version File                    | Type    | Old   | New   | Bump  | Key Commits   |
| ------------------------------- | ------- | ----- | ----- | ----- | ------------- |
| packages/frontend/package.json  | Node.js | 1.2.0 | 1.3.0 | minor | feat(ui): ... |
| packages/backend/pyproject.toml | Python  | 0.5.1 | 0.5.2 | patch | fix(api): ... |
| app.json                        | Expo    | 1.0.0 | 1.1.0 | minor | feat(rn): ... |
```

## Constraints

- Do not modify any file other than the version files being bumped.
- Do not push — pushing is handled by the push/PR pipeline or the user.
- If no version file is detected or no new commits exist, do nothing.
- Never mix changes from different packages — each version file is bumped based only on commits that touched its scope.
