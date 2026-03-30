# 插件相关性映射

按相关性类别对已知插件进行分类。根据此映射判断在给定项目类型下应推荐禁用哪些插件���

## 相关性类别

### 通用 — 始终保留

这些插件不分项目类型都有用。不要推荐禁用。

| 插件 ID 模式 | 用途 |
|---|---|
| `claude-md-management` | CLAUDE.md 文件管理 |
| `code-review` | 代码审查辅助 |
| `code-simplifier` | 代码简化 |
| `context7` | 查阅任意���的文档 |
| `feature-dev` | 功能开发工作流 |
| `security-guidance` | 安全最佳实践 |
| `sentry` | 错误监控与调试 |
| `smart` | 工作流自动化（自身 — 永不禁用） |
| `remember` | 记忆管理 |
| `pr-review-toolkit` | PR 审查 |

### 条件性 — 仅在特定项目类型中相关

这些插件是专用的。当项目类型不匹配时推荐禁用。

| 插件 ID 模式 | 相关场景 | 项目类型 |
|---|---|---|
| `pyright-lsp` | 存在 Python 代码 | python |
| `typescript-lsp` | 存在 TypeScript/JavaScript 代码 | typescript, javascript, react, vue, nextjs, svelte, react-native, angular |
| `frontend-design` | 存在 Web 前端 UI | react, vue, nextjs, svelte, angular, html |
| `ui-ux-pro-max` | 需要 UI/UX 设计工作 | react, vue, nextjs, svelte, angular, react-native, flutter, html |
| `playwright` | 需要浏览器测试 | react, vue, nextjs, svelte, angular, html, web |
| `supabase` | Supabase 是项目依赖 | （检��� package.json/requirements 中是否有 "supabase"） |
| `plugin-dev` | Claude Code 插件仓库 | claude-plugin |
| `skill-creator` | Claude Code 插件仓库 | claude-plugin |
| `superpowers` | Claude Code 插件仓库 | claude-plugin |

## 项目类型检测

### 标志文件 → 项目类型

| 标志 | 项目类型标签 |
|---|---|
| `pyproject.toml` | python |
| `requirements.txt` | python |
| `setup.py` | python |
| `Pipfile` | python |
| `package.json` | javascript（需检查依赖确定框架） |
| `tsconfig.json` | typescript |
| `Cargo.toml` | rust |
| `go.mod` | go |
| `Gemfile` | ruby |
| `*.sln` 或 `*.csproj` | dotnet |
| `build.gradle` 或 `pom.xml` | java |
| `pubspec.yaml` | flutter |
| `mix.exs` | elixir |
| `deno.json` 或 `deno.jsonc` | deno |
| `bun.lockb` | bun（同时添加 javascript） |
| `.claude-plugin/plugin.json` | claude-plugin |
| `*/.claude-plugin/plugin.json`（子目录） | claude-plugin |

### 从 package.json 检测框架

当 `package.json` 存在时，读取 `dependencies` 和 `devDependencies`：

| 依赖键 | 框架标签 |
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
| `nestjs` 或 `@nestjs/core` | javascript |
| `flutter`（在 pubspec.yaml 依赖中） | flutter |

### Supabase 检测

在以下位置检查 `supabase` 或 `@supabase/supabase-js`：
- `package.json` 的 dependencies/devDependencies
- `requirements.txt` 或 `pyproject.toml` 依���
- 是否存在 `supabase/` 目录

## 未知插件的启发式规则

对于上表未列出的插件，按名称启发式判断：

- 名称包含 `lsp`、`lint` 或语言名（如 `ruby-lsp`）→ 语言专用，按语言匹配
- 名���包含 `frontend`、`ui`、`design`、`css` → 前端专用
- 名称包含 `backend`、`api`、`db`、`database` ��� 后端专用
- 名称��含 `plugin`、`skill`、`hook` → 插件开发专用
- 其他 → 视为通用（不推荐禁用）

不确定时，倾向于保留插件启用状态。
