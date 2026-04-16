# Plugin Relevance Mapping

Classification of known plugins by relevance category. Use this to determine which plugins to recommend disabling for a given project type.

## Relevance Categories

### Universal — Always Keep

These plugins are useful regardless of project type. Never recommend disabling them.

| Plugin ID Pattern | Purpose |
|---|---|
| `claude-md-management` | CLAUDE.md file management |
| `code-review` | Code review assistance |
| `code-simplifier` | Code simplification |
| `context7` | Documentation lookup for any library |
| `feature-dev` | Feature development workflows |
| `security-guidance` | Security best practices |
| `sentry` | Error monitoring and debugging |
| `smart` | Workflow automation (self — never disable) |
| `remember` | Memory management |
| `pr-review-toolkit` | Pull request review |

### Conditional — Only Relevant for Specific Project Types

These plugins are specialized. Recommend disabling when the project type does not match.

| Plugin ID Pattern | Relevant When | Project Types |
|---|---|---|
| `pyright-lsp` | Python code exists | python |
| `typescript-lsp` | TypeScript/JavaScript code exists | typescript, javascript, react, vue, nextjs, svelte, react-native, angular |
| `frontend-design` | Web frontend UI exists | react, vue, nextjs, svelte, angular, html |
| `ui-ux-pro-max` | UI/UX design work needed | react, vue, nextjs, svelte, angular, react-native, flutter, html |
| `playwright` | Browser testing needed | react, vue, nextjs, svelte, angular, html, web |
| `supabase` | Supabase is a dependency | (check package.json/requirements for "supabase") |
| `plugin-dev` | Claude Code plugin repo | claude-plugin |
| `skill-creator` | Claude Code plugin repo | claude-plugin |
| `superpowers` | Claude Code plugin repo | claude-plugin |

## Project Type Detection

### Indicator Files → Project Type

| Indicator | Project Type Tag |
|---|---|
| `pyproject.toml` | python |
| `requirements.txt` | python |
| `setup.py` | python |
| `Pipfile` | python |
| `package.json` | javascript (check deps for framework) |
| `tsconfig.json` | typescript |
| `Cargo.toml` | rust |
| `go.mod` | go |
| `Gemfile` | ruby |
| `*.sln` or `*.csproj` | dotnet |
| `build.gradle` or `pom.xml` | java |
| `pubspec.yaml` | flutter |
| `mix.exs` | elixir |
| `deno.json` or `deno.jsonc` | deno |
| `bun.lockb` | bun (also add javascript) |
| `.claude-plugin/plugin.json` | claude-plugin |
| `*/.claude-plugin/plugin.json` (child dirs) | claude-plugin |

### Framework Detection from package.json

When `package.json` exists, read `dependencies` and `devDependencies`:

| Dependency Key | Framework Tag |
|---|---|
| `react` | react |
| `react-native` | react-native |
| `next` | nextjs |
| `vue` | vue |
| `nuxt` | vue |
| `svelte` | svelte |
| `@sveltejs/kit` | svelte |
| `@angular/core` | angular |
| `express` | javascript |
| `fastify` | javascript |
| `nestjs` or `@nestjs/core` | javascript |
| `flutter` (in pubspec.yaml deps) | flutter |

### Supabase Detection

Check for `supabase` or `@supabase/supabase-js` in:
- `package.json` dependencies/devDependencies
- `requirements.txt` or `pyproject.toml` dependencies
- Presence of `supabase/` directory

## Heuristic for Unknown Plugins

For plugins not listed above, apply name-based heuristics:

- Name contains `lsp`, `lint`, or language name (e.g., `ruby-lsp`) → language-specific, match by language
- Name contains `frontend`, `ui`, `design`, `css` → frontend-specific
- Name contains `backend`, `api`, `db`, `database` ��� backend-specific
- Name contains `plugin`, `skill`, `hook` → plugin-dev-specific
- Otherwise → treat as universal (do not recommend disabling)

When uncertain, err on the side of keeping the plugin enabled.
