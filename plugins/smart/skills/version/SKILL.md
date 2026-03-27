---
description: Use when preparing a release, creating a PR, finishing a feature branch, or when the user says "bump version", "update version", "release", "new version". Also use proactively before pushing or opening a PR if commits exist on the branch that haven't been versioned yet. Analyzes commit messages since the base branch to determine the correct semantic version bump (major/minor/patch) and updates plugin.json accordingly.
argument-hint: "[base-branch] — defaults to main"
---

You are a version management assistant. Goal: analyze commit messages since the base branch and update the plugin version in `plugin.json` following semantic versioning (`a.b.c`).

## Steps

### 1) Read current version

- Read `plugins/smart/.claude-plugin/plugin.json` to get the current `version` field (format: `a.b.c`).

### 2) Determine base branch

- If the user provided a base branch via `$0`, use it.
- Otherwise default to `main`.

### 3) Collect commits to analyze

- Run: `git log <BASE_BRANCH>..HEAD --oneline`
- If no commits are found, report "No new commits — version unchanged" and stop.

### 4) Determine version bump type

Analyze each commit message's type prefix (Conventional Commits format `<type>[!][(scope)]: <desc>`):

| Condition | Bump |
|-----------|------|
| Type suffix `!` (e.g. `feat!:`, `fix!:`) or commit body contains `BREAKING CHANGE` | **major** |
| `feat` | **minor** |
| `fix`, `refactor`, `perf`, `docs`, `test`, `chore`, `ci`, or any other type | **patch** |

Apply the **highest** bump across all commits:
- Any major → bump major (reset minor and patch to 0)
- Else any minor → bump minor (reset patch to 0)
- Else → bump patch

### 5) Calculate and apply new version

- Major: `a.b.c` → `(a+1).0.0`
- Minor: `a.b.c` → `a.(b+1).0`
- Patch: `a.b.c` → `a.b.(c+1)`

Update the `version` field in `plugins/smart/.claude-plugin/plugin.json` with the new version.

### 6) Commit the version bump

```bash
git add plugins/smart/.claude-plugin/plugin.json
git commit -m "$(cat <<'EOF'
chore(plugin): bump version to <new_version>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### 7) Output

Display:
- `<old_version>` → `<new_version>` (bump type)
- List the commits that determined the bump type

## Constraints

- Do not modify any file other than `plugin.json`.
- Do not push — pushing is handled by the PR pipeline or the user.
- If already on the base branch (no diverged commits), do nothing.
