# Statusline 字段描述

用于 JSONC 输出注释的双语描述。根据用户语言选择对应列。

## 顶层字段

| JSON 路径 | EN | CN |
|-----------|----|----|
| `session_id` | Unique session identifier | 唯一会话标识符 |
| `session_name` | User-assigned session name | 用户设定的会话名称 |
| `transcript_path` | Conversation log file path (.jsonl) | 对话记录文件路径 |
| `cwd` | Current working directory (same as workspace.current_dir) | 当前工作目录（与 workspace.current_dir 相同） |
| `version` | Claude Code version | Claude Code 版本号 |
| `exceeds_200k_tokens` | Whether latest API response total tokens exceeds 200K (fixed threshold, independent of actual window size) | 最近 API 响应总 token 是否超过 200K（固定阈值，与实际窗口大小无关） |

## model

| JSON 路径 | EN | CN |
|-----------|----|----|
| `model` | Model information | 模型信息 |
| `model.id` | Current model identifier | 当前模型标识符 |
| `model.display_name` | Model display name | 模型显示名称 |

## workspace

| JSON 路径 | EN | CN |
|-----------|----|----|
| `workspace` | Workspace information | 工作区信息 |
| `workspace.current_dir` | Current working directory | 当前工作目录 |
| `workspace.project_dir` | Directory where Claude Code was launched (immutable during session) | 启动 Claude Code 时的目录（会话期间不变） |
| `workspace.added_dirs` | Additional directories added to workspace | 额外添加的目录列表 |

## output_style

| JSON 路径 | EN | CN |
|-----------|----|----|
| `output_style` | Output style configuration | 输出样式配置 |
| `output_style.name` | Current output style name | 当前输出样式名称 |

## cost

| JSON 路径 | EN | CN |
|-----------|----|----|
| `cost` | Session cost and statistics | 会话成本与统计 |
| `cost.total_cost_usd` | Total session cost (USD) | 总会话成本（美元） |
| `cost.total_duration_ms` | Wall-clock time since session start (ms) | 自会话开始的总挂钟时间（毫秒） |
| `cost.total_api_duration_ms` | Time spent waiting for API responses (ms) | 等待 API 响应的总时间（毫秒） |
| `cost.total_lines_added` | Cumulative lines of code added | 累计新增代码行数 |
| `cost.total_lines_removed` | Cumulative lines of code removed | 累计删除代码行数 |

## context_window

| JSON 路径 | EN | CN |
|-----------|----|----|
| `context_window` | Context window state | 上下文窗口状态 |
| `context_window.total_input_tokens` | Cumulative input tokens across session | 整个会话的累积输入 token 总数 |
| `context_window.total_output_tokens` | Cumulative output tokens across session | 整个会话的累积输出 token 总数 |
| `context_window.context_window_size` | Max context window size (tokens); 200K default, 1M for extended models | 最大上下文窗口大小（token），默认 200K，扩展模型为 1M |
| `context_window.current_usage` | Token breakdown of most recent API call (null before first call) | 最近一次 API 调用的 token 明细（首次调用前为 null） |
| `context_window.current_usage.input_tokens` | Input tokens in current context | 当前上下文中的输入 token |
| `context_window.current_usage.output_tokens` | Output tokens this generation | 本次生成的输出 token |
| `context_window.current_usage.cache_creation_input_tokens` | Tokens written to cache | 写入缓存的 token 数 |
| `context_window.current_usage.cache_read_input_tokens` | Tokens read from cache | 从缓存读取的 token 数 |
| `context_window.used_percentage` | Context window usage percentage (input tokens only) | 已使用上下文窗口百分比（仅计输入 token） |
| `context_window.remaining_percentage` | Remaining context window percentage | 剩余上下文窗口百分比 |

## rate_limits

| JSON 路径 | EN | CN |
|-----------|----|----|
| `rate_limits` | Rate limit information | 速率限制信息 |
| `rate_limits.five_hour` | 5-hour rolling window limit | 5 小时滚动窗口限制 |
| `rate_limits.five_hour.used_percentage` | 5-hour rate limit usage percentage | 5 小时速率限制使用百分比 |
| `rate_limits.five_hour.resets_at` | 5-hour limit reset time (Unix timestamp) | 5 小时限制重置的 Unix 时间戳 |
| `rate_limits.seven_day` | 7-day rolling window limit | 7 天滚动窗口限制 |
| `rate_limits.seven_day.used_percentage` | 7-day rate limit usage percentage | 7 天速率限制使用百分比 |
| `rate_limits.seven_day.resets_at` | 7-day limit reset time (Unix timestamp) | 7 天限制重置的 Unix 时间戳 |

## 条件字段

以下字段仅在对应功能激活时出现。

| JSON 路径 | EN | CN |
|-----------|----|----|
| `vim` | Vim mode information | Vim 模式信息 |
| `vim.mode` | Current vim mode | 当前 vim 模式 |
| `agent` | Agent information | Agent 信息 |
| `agent.name` | Agent name | Agent 名称 |
| `worktree` | Worktree information | Worktree 信息 |
| `worktree.name` | Worktree name | Worktree 名称 |
| `worktree.branch` | Worktree branch name | Worktree 分支名 |
