---
name: wfb
description: 当你准备编写、修改或扩大一个 Workflow 脚本（Workflow 工具 / 多代理编排），或用户说某个 workflow「太烧 token」「太贵」、要求「模型分层」「按任务用 haiku/sonnet/opus」「让 workflow 更省」「降低 workflow 成本」「model layering」，或希望 fan-out / pipeline 代理更省成本运行时，都应使用本技能。在写 agent() 调用之前就应用它，让每个子代理跑在正确的模型档位上、并让脚本在 fan-out 之前先剪枝。即使用户只说「给 X 写个 workflow」也要用——成本分层应是默认动作，而非事后补救。
argument-hint: 无需参数。在编写 Workflow 脚本时应用「省 token + 模型分层」指导。
---

# WFB —— 模型分层、省 token 的 Workflow 编写法

把 token 花在能换来质量的地方，其余一概不花。目标**不是**「处处用最便宜的模型」，而是把每个工作单元匹配到「能把它做好的最小模型」，并且压根不去启动那些不必要的代理。

## 为什么重要

Workflow 工具的两个事实决定了这里的每一个取舍：

1. **控制流免费，只有 `agent()` 调用烧 token。** 脚本主体——`pipeline()`、`parallel()`、`while` 循环、`filter`、`map`——作为确定性 JavaScript 运行，不消耗任何模型 token。整个 workflow 的成本 = 所有 `agent()` 调用之和，每个按**它自己**模型的价格计费。所以能撬动成本的杠杆只有三个：你启动了多少代理、每个跑在什么模型上、每个读写了多少内容。

2. **省略 `model` 会继承 session 模型。** 不传 `model` 时，代理跑在当前 session 所用的模型上。如果 session 是 Opus，那么**每个未分层的代理都按 Opus 价计费**——这正是 fan-out 感觉贵得离谱的常见原因。控制成本意味着**刻意决定**模型，而不是放任默认。

## 唯一的机制

模型分层通过 `agent()` 上的一个选项实现：

```js
agent(prompt, { model: 'haiku' | 'sonnet' | 'opus', /* label, phase, schema, ... */ })
```

`meta.phases[].model` 是**纯显示**的——它只在 `/workflows` 进度视图里给某个阶段打标签，让成本画像如实可读，并**不会**真的切换模型。真正的切换永远是每个 `agent()` 上的 `model` 选项。保持两者一致，进度树才能反映你真实的花费。若某个阶段混用了档位（比如 sonnet 躯干 + opus 升档），这个标签只能显示一个——设成主导档位即可；真正计费的仍是每个 `agent()` 的 `model`。

## 如何分层：四条规则

这四条就是策略本身。下面的「难度轴」解释它们**为什么**成立——但如果别的都忘了，记住这四条：

1. **该 haiku 的活 → haiku。** 机械抽取、分类、格式化、单文件取事实、高并发低风险的 fan-out。
2. **该 sonnet 的活 → sonnet。** 默认主力：常规写代码、单维度审查、中等综合。**大多数单元落在这一档。**
3. **收口 → 一定 opus，无例外。** 任何**收口**的节点——最终综合、汇总裁决、所有其他代理喂进来后产出的交付物——都跑 opus。它的爆炸半径是全局的：它**就是**产出，这里用弱模型会拖累上游所有工作的质量。这不是「高风险也许吧」——收口就是 opus，没得商量。一个 workflow 可以有**多个**收口节点，而非只有最末尾一个：中途的「汇总裁决」——比如把大量扫描结果收成一份下游都要遵守的计划——也是收口，同样用 opus。
4. **重要实现 → opus。** 硬的或高风险的代码即使「只是写代码」也上 opus——刁钻算法、并发、安全攸关路径、跨切面重构，任何 bug 会向下游放大的实现。

### 为什么是这四条 —— 按难度分层，不按动词

把**动词**映射到模型——「读→haiku、写代码→sonnet、综合→opus」——是错的轴，会让你分层错位。真正的轴是**这个单元需要多少推理、犯错代价多大**。同一个动词横跨三档：「实现」可以是套样板的 CRUD 处理器（便宜），也可以是无锁并发队列（昂贵）。规则 3 和 4 正是「风险压倒类别」的情形——收口和重要实现无论「动词」长什么样都跳到 opus。**判断单元本身，而不是它的标签。**

**身体层单元在以下情况升档：**
- **爆炸半径大**——这步错了，下游会层层放大错误（接口/schema 设计、所有人依赖的那次综合、一个架构选择）。
- **多约束交织**——必须同时满足正确性 *和* 安全 *和* 性能 *和* API 兼容。
- **需要判断而非查找**——答案要权衡取舍，而不是检索一个事实。
- **硬实现**——刁钻算法、并发、微妙边界、跨切面重构。**重要或易错的代码即使「只是写代码」也属于 opus。**

**单元在以下情况降档：**
- 规格清晰的机械变换（抽字段、重格式化、改名）。
- 落入小而固定标签集的分类/路由。
- 单文件读取产出结构化事实。
- 沿既定模式生成的样板代码。
- 答案客观的清单式校验。

| 档位 | 用于 | 在 workflow 中的角色 |
|------|------|----------------------|
| **haiku** | 机械抽取、分类、格式化、单文件取事实、高并发低风险 fan-out | 又宽又便宜的**底座** |
| **sonnet** | 默认主力——常规写代码、单维度审查、中等综合，大多数单元 | **躯干** |
| **opus** | **收口（永远）** + 高难度/高风险：最终综合与汇总裁决、重要/硬实现、架构、对抗式裁判 | 又窄又贵的**顶点**——以及任何真正硬的节点 |

对**身体层**单元，两档之间拿不准时，从低档起，让下面的**失败升档**模式只在它确实吃力时才提升。**收口（规则 3）从不存在疑问——它永远是 opus，别对它跑升档那套。**

## 四个杠杆，按优先级

### 1. 在启动前剪枝（免费，且收益最大）
最便宜的代理是你从未启动的那个。用纯 JavaScript 在 fan-out **之前**砍掉工作：`filter` 掉不需要代理的项、对已见过的 `dedupe`、`slice` 到合理上限（并 `log()` 掉了什么——静默截断会被误读成「全覆盖了」）。剪枝胜过换模型，因为它**整个消除**了调用，而不只是让它变便宜。

### 2. 按难度给每个 `agent()` 分层
套用上面的表。在成本敏感的代理上**显式钉死**模型，别依赖 session 模型继承。

### 3. 用 `schema` 压缩输出
传 `schema` 强制代理返回校验过的结构化数据而非散文。这砍掉**输出** token（贵的那个方向），也省去你这端的解析。任何你以程序方式消费其结果的代理都该用。

### 4. 刻意选择 session 模型
因为省略 `model` 会继承 session，如果你主要靠 workflow 做开发，考虑把 *session* 跑在 Sonnet 上（`/model`）。这样每个未钉死的代理默认是 Sonnet 而非 Opus，把下限拉低——你只在 `opus` 真正物有所值处钉死它。

## 模式

### 漏斗 —— 又宽又便宜的底座，又窄又贵的顶点
「发现 + 综合」类工作的默认形态。

```js
export const meta = {
  name: 'tiered-review',
  description: '一次审查中按难度给模型分层',
  phases: [
    { title: 'Scan',      detail: '逐文件抽取结构', model: 'haiku'  },
    { title: 'Review',    detail: '审查热点文件',   model: 'sonnet' },
    { title: 'Synthesize',detail: '跨切面裁决',     model: 'opus'   },
  ],
}

// 工作清单经由 args 传入；若需先发现它，用免费的 shell/工具调用或一个 haiku 代理——绝不用 opus 扫描。
// ① haiku 底座——便宜，铺得宽
const scanned = (await parallel(args.map(f => () =>
  agent(`读取 ${f}；抽取导出符号并评估改动风险 low|med|high`,
        { model: 'haiku', phase: 'Scan', schema: FILE_SCHEMA })
))).filter(Boolean)

// ② 先剪枝，再 sonnet——只有有风险的文件存活（杠杆 #1 先于 #2）
const hot = scanned.filter(f => f.risk !== 'low')
const reviews = (await parallel(hot.map(f => () =>
  agent(`审查 ${f.path} 的正确性与边界条件`,
        { model: 'sonnet', phase: 'Review' })
))).filter(Boolean)

// ③ 顶点唯一一次 opus——真正唯一的跨切面收口判断
const verdict = await agent(`综合给出整体裁决：\n${reviews.join('\n---\n')}`,
                            { model: 'opus', phase: 'Synthesize' })
```

### 失败升档 —— 让 opus 只处理真正硬的那些
你往往事先并不知道哪些实现单元是硬的。别为它们全员预付 opus——先用 sonnet，只在 sonnet 报告低置信或通不过校验时才升到 opus。大多数单元便宜地搞定；真正的硬代码自动获得 opus。

```js
async function implement(task) {
  const draft = await agent(`实现：${task}。返回代码 + 一个 0-1 的置信度。`,
                            { model: 'sonnet', schema: IMPL_SCHEMA })
  if (draft && draft.confidence >= 0.7) return draft
  // 硬情形——把同一个单元升到 opus
  return agent(`这对小模型很吃力。请谨慎实现：${task}`,
               { model: 'opus', schema: IMPL_SCHEMA })
}
```

这个分支只有在 `schema` 带上你判断用的字段（这里是 `confidence`，或一个 `verdict`）时才会触发——否则模型可能根本不返回这个信号，结果要么全升档、要么全不升。把这个字段放进 schema。

### 混合分层迁移 —— 多数文件机械，核心不机械
迁移并非一律「代码=sonnet」。大批调用点改写是机械的（sonnet，真琐碎就 haiku）；中心的引擎/接口是高风险的（opus）。**逐节点分层：**

```js
await parallel(callSites.map(f => () =>
  agent(`机械地更新 ${f} 中的 import 调用点`, { model: 'sonnet', isolation: 'worktree' })))
const core = await agent(`重写核心适配器——每个调用点都依赖这个契约`,
                         { model: 'opus', isolation: 'worktree' })
```

## 反模式

- **全 opus 平铺 fan-out** —— 20 个代理用 opus 干 haiku 就能干的活。这是头号 token 黑洞。给它们分层。
- **按动词归档** —— 「所有写代码都给 sonnet」会给真正需要 opus 的硬实现封了质量上限。按难度分层。
- **靠继承控成本** —— 不写 `model`、指望它便宜。在 Opus session 上它一点都不便宜。钉死它。
- **跳过剪枝** —— 对一个原始列表直接 fan-out，而一个 `filter`/`dedupe` 本可免费砍掉一半调用。
- **该用 schema 处却用散文** —— 放任产数据的代理絮叨；schema 更便宜也更干净。

## 启动 workflow 前，自问：

1. 纯 JS（`filter`/`dedupe`/`slice`）能否在 `agent()` 调用发生前就消除一些？
2. 每个代理是否在「能把它做好的最小模型」上——底座 haiku、躯干 sonnet、**收口与重要/硬实现 opus**？
3. 每个产数据的代理是否都有 `schema`？
4. session 模型是否是刻意选的，让未钉死的代理默认落在合理档位？
5. `meta.phases[].model` 标签是否与真实的逐代理模型一致，让成本画像如实可读？
