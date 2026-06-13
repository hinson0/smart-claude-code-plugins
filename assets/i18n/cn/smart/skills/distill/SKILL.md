---
name: distill
description: 当用户要求蒸馏、总结、归档、持久化或保存当前会话/聊天到知识库时使用；包括提到 /smart:distill、distill、知识库、会话主题、问答归档、当前 CC 输出、把这次聊天落盘，或指定范围/目标目录做会话知识沉淀。仅适用于当前对话上下文，不用于读取源目录文件。
argument-hint: 可选 —— 收窄范围（如"最近 5 轮"、"关于 langgraph 的部分"）或指定目标目录。默认提炼整场会话并落盘到 .smart/knowledges/。
---

# distill — 从当前会话提炼知识落盘

## 用途

把**当前 CC 会话中产生的有价值问答对**抽取、聚类、格式化,落盘到目标目录,形成可被未来 RAG 检索的主题化知识库。

输入:对话上下文(用户消息 + 助手消息)。
输出:`<目标目录>/<主题键>.md` 一到多个文件。

三个核心承诺:

1. **三态比对(仅目标目录,且豁免已 review 文件)**:每个主题簇必须明确归类为「重复 / 新增 / 差分」之一
2. **不删内容**:仅可删除与主题无关的废话、寒暄、tool 原始 JSON 等噪音;代码、数据、表格、示例、推理过程一律保留
3. **格式统一**:按 `references/format-spec.md` 规范化,所有落盘文件含 `## 触发提问` `## 关键结论` 等固定段落

## Step 0 — 解析目标目录

目标目录在开始时**解析一次**,本次运行的所有读写都限定在该目录内。目标是**最多只问一次**:先读已保存的设置,首次选择落盘后,后续运行就静默读取。

解析优先级(命中即停):

1. **调用时显式带路径** —— 用户指明了目录(如"distill 到 docs/kb"、"distill 到 ~/knowledges/md/2026-05-28"),直接照用。
2. **项目设置** —— 读 `.smart/settings.json`,若含 `knowledges_dir` 则用它。
3. **全局设置** —— 读 `~/.smart/settings.json`,若含 `knowledges_dir` 则用它。
4. **询问** —— 以上都没解析出路径 → 调用 `AskUserQuestion`(header 用 `目标目录`,问题用 `提炼出的知识落盘到哪个目录?`):

   | 选项 | 路径 | 含义 |
   |------|------|------|
   | (推荐) | `.smart/knowledges/` | 项目本地知识库,相对当前工作目录 |
   | 个人库 | `~/knowledges/md/{date}/` | 个人当日知识库(向后兼容的旧约定) |
   | 其他 | (自定义) | 用户输入的任意路径 |

   用户选定后,**持久化**该选择到 `.smart/settings.json`(项目级),写为 `{"knowledges_dir": "<所选路径>"}`,让后续运行跳过询问。在 Step 6 报告里说明保存位置,并提示:把它移到 `~/.smart/settings.json` 即成为所有项目通用的全局默认。

**路径占位符与归一化**(对任意来源解析出的值都适用):

- `{date}` → 系统注入的今日日期(`YYYY-MM-DD`)。不含 `{date}` 的路径是静态目录(如 `.smart/knowledges`);含 `{date}` 的路径每天重新解析(如 `~/knowledges/md/{date}` → `~/knowledges/md/2026-05-28`)。
- `~` → 用户 home 目录。

**不存在则创建** —— 占位符替换后,若目录(及其父目录)不存在则创建。空目录或新建目录意味着所有提炼出的主题都走新增。

解析完成后,全程以 `<目标目录>` 称之。该路径本次运行固定,不再二次询问或覆盖。

**`settings.json` 格式** —— 单一键,用 Read 工具读取。文件缺失或格式错误则静默忽略(落到下一优先级):

```json
{ "knowledges_dir": "~/knowledges/md/{date}" }
```

## 扫描范围铁律

- ✅ 只与 `<目标目录>` 中**直接位于该层**的文件做三态比对
- ✅ `<目标目录>` 不存在或为空 → 所有提炼出的主题**直接新增**
- ❌ **绝不**扫描 `<目标目录>` 的父目录、兄弟目录或任何子目录
- ❌ **绝不**扫描或改写目标目录之外的任何路径(例如当 `<目标目录>` 为 `~/knowledges/md/{date}/` 时,即绝不触碰其他日期目录或 `backend/`、`frontend/` 等主题归档目录)

目标目录之外的一切都不查询、不修改、不引用作为比对基准。

## 已 review 文件豁免(不参与三态比对)

`<目标目录>` 中,以下两类文件视为**用户已 review 完成、内容定稿**,本 skill **不读取、不比对、不覆盖、不合并**:

| 豁免类型 | 判定规则 | 含义 |
|---------|---------|------|
| `.printed.md` 后缀 | 文件名以 `.printed.md` 结尾(如 `langgraph-checkpointer.printed.md`) | 用户已打印归档 |
| 同名 pdf 伴随 | 同目录下存在与 md **主干名相同**的 pdf(如 `1.md` + `1.pdf`,`langgraph-checkpointer.md` + `langgraph-checkpointer.pdf`) | 用户已导出 PDF,视为 review 完成 |

**执行逻辑**:

1. 在 Step 3 枚举目标目录文件清单前,**先过滤掉**这两类豁免文件,过滤后的清单才参与主题匹配
2. 即使本次 distill 提炼的主题键与被豁免文件的主干名**命中**,也**强制走新增**——用差异化命名(如追加 `-v2`、`-followup`,或加时间短串)落到新文件,绝不修改已豁免文件
3. 在 Step 6 汇总报告中加 `frozen` 段,列出被豁免的文件以及"原本可能命中的主题键",让用户知道为什么没合并

**实现要点**:

- 主干名匹配使用**精确匹配**(`stem(md) == stem(pdf)`,即去掉 `.md`/`.pdf` 后字面相等),不做模糊匹配,避免误判
- `.printed.md` 豁免优先于同名 pdf 豁免;两条都命中只算一次豁免
- `.printed.md` 自带豁免,不需要它再额外配套同名 pdf

**伪代码**:

```python
from pathlib import Path
from glob import glob

def list_target_files(target_dir: str) -> tuple[list[str], list[str]]:
    """返回 (active, frozen):active 参与三态比对,frozen 跳过。"""
    all_md = glob(f"{target_dir}/*.md")
    pdf_stems = {Path(p).stem for p in glob(f"{target_dir}/*.pdf")}
    active, frozen = [], []
    for md in all_md:
        name = Path(md).name
        stem = Path(md).stem  # 去掉 .md 的主干名(包含可能的 .printed 中缀)
        if name.endswith(".printed.md") or stem in pdf_stems:
            frozen.append(md)
        else:
            active.append(md)
    return active, frozen
```

## 触发后的执行流程

### Step 1 — 圈定会话提炼范围

默认范围:**本次 CC 会话从启动到触发本 skill 之间**的所有用户消息与助手消息。用户可显式收窄:

- "distill 最近 5 轮" → 只取末尾 5 个 Q/A 对
- "distill 关于 langgraph 的部分" → 主题词过滤,只保留命中的轮次
- "distill 从我问 reasoning_content 开始" → 锚点截断

不要把 system reminder、tool call 原始 JSON、命令行 stdout 当作"对话内容"——它们是噪音,要剥离。

### Step 2 — 价值判定(决定哪些轮次值得落盘)

逐个轮次过一遍,只保留满足**至少一条**价值标准的内容:

1. **概念解释**:Claude 输出了新概念的定义、schema、字段表
2. **代码示例**:出现了可复用的代码片段(>3 行 或 含关键 API 调用)
3. **坑/Why**:用户报错 + Claude 解释根因,或 Claude 主动指出"这里容易踩坑因为..."
4. **决策推理**:多方案对比、A/B 权衡、选型理由
5. **用户的非显然提问**:问题本身蕴含上下文(比如"为什么 reasoning_content 不在 content 里" — 提问本身就是知识入口)

**直接丢弃**的轮次:

- 寒暄("你好"/"在吗"/"好的")
- 纯命令执行("ls 一下"/"运行测试")没有解释
- 已被后续修正的错误尝试(保留修正后的最终结论)
- 用户对工具调用结果的简短确认("收到"/"好")

判断不准时倾向保留,在汇总报告里标 "kept-uncertain"。

详细判定见 `references/topic-clustering.md`。

### Step 3 — 主题聚类与主题键生成

把保留下来的轮次按语义聚成若干主题簇。一次会话可能产出 0~N 个主题。

**主题键规则**:

- 提取主名词短语 → kebab-case
- 长度建议 2~5 个词,如 `langgraph-checkpointer`、`reasoning-content-vs-content`、`bge-m3-embedding-dim`
- 避免泛词单独成键(`python-tips` ❌,`python-asyncio-gather-bug` ✓)
- 若多轮聚焦同一对象但视角不同(schema vs 用法),合成一个主题还是拆开?见 `references/topic-clustering.md` 的"切片边界"

聚类完成后,与 `<目标目录>` 的**已过滤清单**(按"已 review 文件豁免"规则剔除 `.printed.md` 与有同名 pdf 的 md)做文件名模糊匹配(去 `-schema` `-mechanism` `-bug` 等后缀),命中即进入差分判定。

若聚类得到的主题键与被**豁免**的文件主干名命中,记录到 frozen 报告并以差异化命名落新文件(如 `<键>-v2.md`),不要修改豁免文件本体。

### Step 4 — 三态判定

| 状态 | 判定标准 | 操作 |
|------|---------|------|
| **重复** | 本次会话提炼出的主题完全被 `<目标目录>` 已有文件覆盖(无新事实/代码/坑) | 跳过,仅在汇总报告中列出 |
| **新增** | `<目标目录>` 无对应主题文件(或命中豁免被强制改走新增) | 在 `<目标目录>/<主题键>.md` 创建新文件 |
| **差分** | 主题已存在,但本次会话补充了新示例/字段/坑 | 用 Edit 把**新增部分**追加到已有文件,原内容不动 |

详细判定算法、语义等价规则、Case A~F 边界处理,见 `references/diff-rules.md`。

### Step 5 — 格式化与写入

每个主题文件按以下模板组织:

```markdown
# <主题>

## 触发提问
<把用户的原始提问引用块保留,多轮用空行分隔>

## 关键结论
<从 Claude 输出中抽取核心答案,3~5 个 bullet>

## Schema / 字段表
<若涉及数据结构,见 references/format-spec.md>

## 代码示例
<带语言标识的代码块>

## 坑 / Why
<报错根因、A/B 对比、避坑要点>

## 关联
<指向同目录其他主题的链接,如 [[reasoning-content-vs-content]]>
```

字段命名、代码块语言标识、Why/How 段落、来源标注、删除许可清单,全部规范参见 `references/format-spec.md`。

差分合并用 Edit `old_string`/`new_string` 增量追加;新增用 Write 整文件落盘。

### Step 6 — 输出汇总报告

执行结束在对话中输出简表(不写文件):

```
范围: 本次会话 (24 轮) → .smart/knowledges/
保留: 18 轮  丢弃: 6 轮(寒暄/重复)
主题聚类: 4 个
目标目录文件: 6 个 (active 4, frozen 2)
─ 新增(new): 3  ─ 差分(merge): 1  ─ 重复(skip): 0  ─ 命中冻结(frozen-hit): 0
新落盘文件:
  + langgraph-stream-modes.md
  + interrupt-vs-breakpoint.md
  + reasoning-content-parsing.md
被合并文件:
  ↻ checkpointer-vs-store.md  (+1 段:跨 thread 隔离)
被豁免文件(frozen, 跳过比对):
  · ai-message-schema.printed.md          (.printed.md 后缀)
  · langgraph-checkpointer.md + .pdf      (同名 pdf 伴随)
```

`frozen-hit` 是本次聚类的主题键命中了豁免文件主干名却被强制改走新增的次数;为 0 说明无冲突。

## 不删内容护栏(必读)

唯一允许删除的内容类型:

- 寒暄、连续 3+ 空行、单字符语气词独立段、明显的打字残稿、被后续完整覆盖的半句话
- system reminder、hook 输出、tool 原始 JSON(噪音)
- 与文档主题完全无关的待办(应转移而非删)

**永远不删**:代码片段、报错信息、数据/数字、表格、示例、命令行输出、用户推理过程(即使被推翻——推翻过程本身是知识)。

特别注意:**用户的原始提问** 即使措辞不正式也要在「触发提问」段落里**完整保留主干**——它常常是检索召回的最佳锚点。

判断不准时默认保留,并在汇总报告里标注 `kept-uncertain`。

## 目标目录的硬约束

落盘目录由 Step 0 解析确定,是本次运行的唯一真相源。所有读写都限定在 `<目标目录>` 内,本 skill 绝不向上回溯到父目录或横向进入兄弟目录。当 `<目标目录>` 为个人当日知识库(`~/knowledges/md/{date}/`)时,其日期在解析时即固定,之后不可被覆盖——与全局 AGENTS.md / CLAUDE.md 约定一致。

## 附加资源

- **`references/topic-clustering.md`** — 主题聚类边界、价值判定细则、主题键命名规则
- **`references/diff-rules.md`** — 三态判定(重复/新增/差分)细则、语义等价规则、6 种边界 case 处理
- **`references/format-spec.md`** — 知识文件格式规范(标题层级、触发提问/关键结论段、代码块、字段表、Why/How、来源标注、删除许可清单)
