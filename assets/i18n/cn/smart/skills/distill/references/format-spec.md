# distill 知识文件格式规范

本文档完整描述 distill 落盘文件的格式规范,自给自足,不依赖外部 skill。

## 标题层级

唯一 H1 = 主题名(与文件名主干一致)。
H2 = 内容分区,固定候选集,按需出现,顺序如下:

```markdown
# <主题>

## 触发提问          # distill 特有,放最前
## 关键结论          # distill 必出现
## 概念              # 一句话定义 + 必要时 2-3 句扩展
## Schema            # 数据结构(TypedDict / Pydantic / dataclass / dict)
## 字段表            # markdown 表格描述 schema 各字段
## 代码示例          # Python / bash / curl / repl 输出
## 坑 / Why          # 踩坑经验、Why 推理
## 关联              # 相关知识文件链接
```

非候选集中的 H2 一律降级为 H3(嵌入相关 H2 下)或合并。
H2 内容为空时,**整段删除**——不允许出现空 H2 占位符。

## 「触发提问」段(distill 独有)

这是 distill 区别于其他知识落盘工具的关键段落,必须出现在 `# <主题>` 之后、其他 H2 之前。

### 内容来源

- 取该主题簇内**最具体、信息量最大**的那一轮用户提问作为主提问
- 若多轮提问递进(从泛到精),只取最后一轮精确提问
- 用户原话即使措辞不正式也要保留主干,可做轻度清洗:
  - 删除明显口误重复("我我想问")
  - **保留**所有专有名词、关键参数、错误信息

### 格式

```markdown
## 触发提问

> reasoning_content 和 content 为什么是两个字段?能不能合并?
> 我在解析的时候 parser 直接拿 content 拿不到思考过程。

(可选,2~3 行的"提问背景":用户当时在做什么、上下文)
```

- 使用 markdown 引用块 `>` 包裹原始提问
- 多轮拼接用空行分隔,不要合并成一段
- 不要加"用户问:"这种冗余前缀

### 反例

❌ 不要写成转述:

```markdown
## 触发提问

用户想了解 reasoning_content 和 content 的区别。
```

转述会丢失检索锚点。原话保留才能在 RAG 召回时匹配未来类似提问。

## 「关键结论」段(distill 必出现)

- 用 3~5 个 bullet 罗列从 Claude 输出中抽出的核心答案
- 每个 bullet 一行,不超过 30 字
- bullet 间无序,不嵌套
- 若答案本质是代码,这段可仅写一句"见代码示例"指向

例:

```markdown
## 关键结论

- `reasoning_content` 在 `additional_kwargs` 里,不在 `content` 字段
- DeepSeek `v4-flash` 思考模式默认关,需 `reasoning_effort="high"` 触发
- LangChain `AIMessage` parser 读不到思考过程,要自己从 raw response 抠
```

## 代码块

所有代码块必须带语言标识。常见取值:

| 内容 | 标识 |
|------|------|
| Python | `python` |
| 命令行 | `bash` |
| JSON | `json` |
| 表/伪代码 | `text` |
| 报错堆栈 | `text` 或 `traceback` |

无语言标识的代码块需补全;判断不出语言时用 `text`。

## 字段表规范

凡涉及 schema 字段说明,统一用 markdown 表格:

```markdown
| 字段 | 类型 | 必选 | 语义 | 示例 |
|------|------|------|------|------|
| `id` | `str` | ✓ | 唯一标识 | `"msg_abc"` |
| `tool_calls` | `list[dict] \| None` | ✗ | 工具调用列表,无则为 None | `[{...}]` |
```

字段名用 inline code 包裹。类型用 Python type hint 风格。可选性用 `✓`/`✗`。

## Why / How 三段式

经验类沉淀(规则、避坑、判断)使用三段式:

```markdown
**结论**:<一句话规则或事实>

**Why**:<为什么这条规则成立——理由、机制、过去的事故>

**How to apply**:<什么时候触发、怎么应用、边界条件>
```

三段缺一不可。结论必须可独立引用,Why/How 必须解释结论的成立条件。

## 来源标注

### 段级标注(差分合并追加新段时)

```markdown
## <新段标题> <!-- from: chat 2026-05-13 14:32 (round #18) -->
```

- 时间戳精确到分钟
- `round #N` 是会话内轮次编号(只数用户消息,从 1 起)
- 不易确定具体轮次时允许只写时间:`<!-- from: chat 2026-05-13 14:32 -->`

HTML 注释形式,渲染不可见但 grep 可查。

### 文末来源段(新增整文件时)

```markdown
---
来源: distill from CC 会话
日期: 2026-05-13
覆盖轮次: round #15 - #21
```

`覆盖轮次` 可选,建议写——帮助未来回溯。

## 表格优先于段落叙述

遇到「A vs B」「多个备选方案对比」「字段含义解释」时,**优先用表格不用段落**。表格是高密度信息的最短路径。

## 链接关联

文末 `## 关联` 段使用相对路径链接:

```markdown
## 关联

- [hitl-interrupt-mechanism.md](./hitl-interrupt-mechanism.md) — interrupt 续跑机制
- [reasoning-content-vs-content.md](./reasoning-content-vs-content.md) — DeepSeek 思考字段分离
```

跨目录链接(用户显式要求时)用 `../<目录>/<文件>.md`。链接锚文本必须含一句话说明,避免裸链接。

也可用 wiki 链接形式标注未来主题:`[[bge-m3-embedding-tuning]]` — 即使该文件尚未创建,也可标记"该主题值得后续 distill"。

## 文件命名

- 全小写 kebab-case:`reasoning-content-parsing.md`
- 不含日期/版本号:主题键即检索 query,日期归属于目录路径或差分合并的来源标注,不进文件名
- 不含动词:用名词短语
- 末尾不加 `-notes` `-draft`:knowledges 都是成品

豁免相关的特殊命名:

- `*.printed.md` 是用户手动标记"已 review 打印",distill **不创建**这类文件,只识别它们做豁免
- `<键>-v2.md` / `<键>-followup.md` 是 distill 在命中豁免文件时使用的差异化命名

## 删除许可清单

仅以下内容允许删除:

| 可删 | 原因 |
|------|------|
| 连续 3+ 空行 | 排版噪音 |
| 单字符语气词独立段("嗯。" "好。") | 无信息 |
| 半句被下文完整覆盖的打字残稿 | 显式重写 |
| 与文档主题完全无关的待办(应转移而非删) | 跑题 |
| 空 H2(无内容标题占位) | 排版 |
| system reminder / hook 输出 / tool 原始 JSON | 噪音 |

**禁删**:

- 任何代码(即使看起来像草稿)
- 任何数字 / 数据 / 量化结论
- 任何报错堆栈
- 任何被推翻的推理(推翻过程是元知识)
- 任何用户写下的"猜测/直觉"标注
- 任何用户原始提问的主干(即使措辞不正式)

判不准时默认保留,在汇总报告标 `kept-uncertain`。
