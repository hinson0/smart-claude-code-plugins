# 主题聚类与价值判定细则

本文档为 distill skill 的 Step 2、Step 3 提供详细执行规则。

## 价值判定细则

### 一定要保留的内容

1. **新概念引入**
   - 用户问"X 是什么"且 Claude 给出定义/schema/字段表
   - Claude 主动引入未在前文出现过的术语并解释

2. **代码片段**(满足任一)
   - 行数 >3 行
   - 含关键 API 调用(`STORE.put`、`graph.invoke`、`embeddings.embed_query` 等)
   - 含非显然的参数(`reasoning_effort="high"`、`thinking={"type": "enabled"}`)
   - 含数据结构定义(TypedDict / Pydantic / dataclass)

3. **报错-根因对**
   - 用户贴出 traceback / 错误现象
   - Claude 给出根因分析(不是"试试这个"而是"因为 X 所以 Y")

4. **A/B 决策**
   - 多方案对比表
   - "为什么不选 A 选 B"的推理段
   - 性能数字对比(σ、token、延迟)

5. **用户表达的偏好/约束**
   - "我希望以后..."
   - "在这个项目里我们用..."
   - 用户纠正 Claude 的尝试("不要这样,应该...")

### 一定要丢弃的内容

- 寒暄(`你好` / `在吗` / `好的` / `继续`)
- 工具调用结果的简短确认(`收到` / `好` / `知道了`)
- 已被后续修正的错误尝试(只保留修正后的最终版本)
- 纯命令执行无解释(`ls 一下` / `运行 pytest`)
- 重复确认已有结论的轮次("再说一下 X" 但 Claude 复述已存在的内容)
- system reminder / hook 输出 / 工具原始 JSON

### 灰区(倾向保留,标 kept-uncertain)

- 半成品代码(用户写一半被打断)
- 异常但未追到根因的报错
- 多轮反复横跳的讨论(可能后续会沉淀)

## 主题聚类规则

### 聚类的颗粒度

**一个主题文件 = 一个可被独立检索的知识点**。判断标准:

- 给这个主题起一个 kebab-case 文件名,是否能准确召回内容?
- 半年后用户搜这个文件名,是否能找到他想要的内容?

### 切片边界(关键决策)

当多轮对话涉及"看起来相关但视角不同"的内容,要不要拆?

| 情况 | 决策 | 例子 |
|------|------|------|
| 同对象同视角 | 合并 | `AIMessage 的 tool_calls 字段`(多轮深入同一字段)→ 一个文件 |
| 同对象不同视角 | 拆分 | `AIMessage schema` vs `AIMessage.additional_kwargs 的 reasoning 解析` → 两个文件 |
| 不同对象同主题 | 合并 | `interrupt 用法` 和 `Command 用法`(都是 HITL 控制流)→ 一个文件 `hitl-control-primitives` |
| 同对象同视角但有 bug 经验 | 拆分 | `bge-m3 embedding 基础` vs `bge-m3 维度不匹配 bug` → 两个文件 |

**优先拆分**:文件粒度细更利于 RAG 召回精度。除非两段内容互相强依赖(脱离其一另一个不成立),否则倾向拆。

### 主题键命名规则

**目标**:文件名本身就是检索 query。

**好的命名**:

| 命名 | 为什么好 |
|------|---------|
| `langgraph-checkpointer-sqlite` | 库名 + 概念 + 实现 → 精确 |
| `reasoning-content-vs-content` | 对比关系明显,易召回 |
| `bge-m3-embedding-dim-mismatch` | 含 bug 特征词,定位错误 |
| `arq-worker-graceful-shutdown` | 库 + 行为 + 状态,精准 |

**坏的命名**:

| 命名 | 问题 |
|------|------|
| `langgraph-tips` | 泛词,无法定位 |
| `embedding-notes` | "notes" 是无效词 |
| `bug-fix-1` | 编号无信息量 |
| `general-stuff` | 灾难 |

### 命名长度

- 2~5 个 kebab 段为佳
- 超过 6 段说明应该拆成多个主题
- 单段词只在专有名词时允许(`langgraph.md` 除非真的是 langgraph 总览,否则别用)

### 与已有文件的匹配

聚类完成后,把每个主题键与 `<目标目录>` 已有文件名做模糊匹配:

- 去掉后缀 `-schema` / `-mechanism` / `-bug` / `-error` 后比较
- 若主词(前 2~3 段)完全一致 → 判为同主题,走差分判定
- 若主词部分重合(如 `langgraph-stream-modes` vs `langgraph-checkpointer`)→ 不同主题,新增

## 多主题混合的会话切片

一次会话可能横跨多个不相关主题(用户在调 langgraph 时顺便问了 docker)。

**做法**:

1. 按时间顺序扫描保留下来的轮次
2. 每轮打"主题候选标签"
3. 相邻轮次标签相同/相关 → 合并为同一簇
4. 标签跳变(从 langgraph 跳到 docker)→ 起新簇
5. 跳变后若再次回到原主题,**不合并回去**——按"二次出现"独立处理,合并阶段再决定

避免一种错误:把整个会话当作一个主题强行命名为 `2026-05-13-session.md`。这违反了"主题键 = 检索 query"原则。
