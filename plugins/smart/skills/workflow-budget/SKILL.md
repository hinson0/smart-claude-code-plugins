---
description: This skill should be used whenever you are about to author, edit, or scale a Workflow script (the Workflow tool / multi-agent orchestration), or when the user says a workflow "burns too many tokens", "is too expensive", asks to "tier models", "use haiku/sonnet/opus per task", "make the workflow cheaper", "reduce workflow cost", "model layering / 模型分层", or wants fan-out / pipeline agents to run cost-efficiently. Apply it BEFORE writing agent() calls so each subagent runs on the right model tier and the script prunes work before spawning. Use it even when the user only says "write a workflow for X" — cost-tiering should be the default, not an afterthought.
argument-hint: No arguments needed. Applies token-lean, model-tiered guidance when authoring Workflow scripts.
---

# Workflow Budget — Model-Tiered, Token-Lean Workflow Authoring

Author Workflow scripts that spend tokens where they buy quality and nowhere else. The goal is not "use the cheapest model everywhere" — it is to match each unit of work to the smallest model that can do it *well*, and to avoid spawning agents you don't need at all.

## Why this matters

Two facts about the Workflow tool drive every decision here:

1. **Control flow is free; only `agent()` calls cost tokens.** The script body — `pipeline()`, `parallel()`, `while` loops, `filter`, `map` — runs as deterministic JavaScript and consumes no model tokens. The entire cost of a workflow is the sum of its `agent()` calls, each billed at *its own* model's rate. So the only levers that move cost are: how many agents you spawn, which model each runs on, and how much each one reads and writes.

2. **An omitted `model` inherits the session model.** When you don't pass `model`, the agent runs on the model powering the current session. If that session is Opus, *every un-tiered agent is billed at Opus rates* — this is the usual reason a fan-out feels ruinously expensive. Cost control means deciding the model deliberately, not letting it default.

## The one mechanism

Model tiering happens through a single option on `agent()`:

```js
agent(prompt, { model: 'haiku' | 'sonnet' | 'opus', /* label, phase, schema, ... */ })
```

`meta.phases[].model` is **display-only** — it labels a phase in the `/workflows` progress view so the cost profile reads honestly. It does **not** switch models. The real switch is always the per-`agent()` `model` option. Keep them consistent so the progress tree reflects what you actually spend. If one phase mixes tiers (e.g. a sonnet body with opus escalation), this single label can only show one — set it to the dominant tier; the per-`agent()` `model` is still what's billed.

## How to tier: four rules

These four are the policy. The difficulty axis below explains *why* they hold — but if you remember nothing else, remember these:

1. **haiku work → haiku.** Mechanical extraction, classification, formatting, single-file fact-gathering, high-volume low-stakes fan-out.
2. **sonnet work → sonnet.** The default workhorse: standard coding, single-dimension review, moderate synthesis. Most units live here.
3. **Convergence → always opus, no exception.** Any node that *closes the loop* — the final synthesis, the merge-and-decide, the deliverable every other agent fed into — runs on opus. Its blast radius is total: it *is* the output, so a weaker model here taxes the quality of everything the workflow did upstream. This is not a "high stakes maybe" — convergence is opus, period. A workflow can have **several** convergence nodes, not just one at the very end: an intermediate merge-and-decide — e.g. turning many scan results into the plan everything downstream obeys — is convergence too, and is also opus.
4. **Important implementation → opus.** Hard or high-stakes code goes to opus even though it is "just writing code" — tricky algorithms, concurrency, security-critical paths, cross-cutting refactors, anything whose bug compounds downstream.

### Why these rules — tier by difficulty, not by verb

Mapping *verbs* to models — "reading → haiku, coding → sonnet, synthesizing → opus" — is the wrong axis and will mis-tier you. The real axis is **how much reasoning a unit needs and how much a mistake costs.** The same verb spans all three tiers: "implement" can be a boilerplate CRUD handler (cheap) or a lock-free concurrent queue (expensive). Rules 3 and 4 are exactly the cases where stakes override category — convergence and important implementation jump to opus regardless of how their "verb" looks. Judge the unit, not its label.

**Escalate a body unit's model when:**
- **High blast radius** — if this step is wrong, everything downstream compounds the error (interface/schema design, the synthesis every other agent depends on, an architectural choice).
- **Many constraints interact** — it must satisfy correctness *and* security *and* perf *and* API compatibility at once.
- **Genuine judgment, not lookup** — the answer requires weighing trade-offs, not retrieving a fact.
- **Hard implementation** — tricky algorithms, concurrency, subtle edge cases, cross-cutting refactors. **Important or error-prone code belongs on opus even though it is "just writing code."**

**Downgrade a unit's model when:**
- It's a mechanical transform with a clear spec (extract fields, reformat, rename).
- It's classification/routing into a small fixed set of labels.
- It's a single-file read producing structured facts.
- It's boilerplate that follows an established pattern.
- It's checklist-style verification with an objective answer.

| Tier | Use for | Role in a workflow |
|------|---------|--------------------|
| **haiku** | Mechanical extraction, classification, formatting, single-file fact-gathering, high-volume low-stakes fan-out | The wide, cheap base |
| **sonnet** | The default workhorse — standard coding, single-dimension review, moderate synthesis, most units | The body |
| **opus** | **Convergence (always)** + high difficulty/stakes: final synthesis & merge-decide, important/hard implementation, architecture, adversarial judgment | The narrow, expensive apex — and any genuinely hard node |

For *body* units, when unsure between two tiers, start at the lower one and let the **escalate-on-failure** pattern below promote it only if it actually struggles. Convergence (rule 3) is never in doubt — it is always opus, so don't run the escalation dance on it.

## Four levers, in priority order

### 1. Prune before you spawn (free, and the biggest win)
The cheapest agent is the one you never start. Use plain JavaScript to cut work *before* the fan-out: `filter` out items that don't need an agent, `dedupe` against what you've already seen, `slice` to a sane cap (and `log()` what you dropped — silent truncation reads as "covered everything"). Pruning beats model-swapping because it removes the call entirely rather than just making it cheaper.

### 2. Tier each `agent()` by difficulty
Apply the table above. Pin the model explicitly on cost-sensitive agents rather than relying on session-model inheritance.

### 3. Constrain output with `schema`
Passing a `schema` forces the agent to return validated structured data instead of prose. This cuts *output* tokens (the expensive direction) and removes parsing on your end. Use it for any agent whose result you consume programmatically.

### 4. Pick the session model deliberately
Because omitted `model` inherits the session, if you mostly drive development through workflows, consider running the *session* on Sonnet (`/model`). Then every un-pinned agent defaults to Sonnet instead of Opus, lowering the floor — and you pin `opus` only where it earns its keep.

## Patterns

### Funnel — wide cheap base, narrow expensive apex
The default shape for discovery + synthesis work.

```js
export const meta = {
  name: 'tiered-review',
  description: 'Tier models by difficulty across a review',
  phases: [
    { title: 'Scan',      detail: 'extract structure per file', model: 'haiku'  },
    { title: 'Review',    detail: 'review hot files',           model: 'sonnet' },
    { title: 'Synthesize',detail: 'cross-cutting verdict',      model: 'opus'   },
  ],
}

// Work-list arrives in args; if you must discover it first, use a free shell/tool call or ONE haiku agent — never an opus scan.
// ① haiku base — cheap, fan out wide
const scanned = (await parallel(args.map(f => () =>
  agent(`Read ${f}; extract exports and rate change risk low|med|high`,
        { model: 'haiku', phase: 'Scan', schema: FILE_SCHEMA })
))).filter(Boolean)

// ② prune, THEN sonnet — only the risky files survive (lever #1 before #2)
const hot = scanned.filter(f => f.risk !== 'low')
const reviews = (await parallel(hot.map(f => () =>
  agent(`Review ${f.path} for correctness and edge cases`,
        { model: 'sonnet', phase: 'Review' })
))).filter(Boolean)

// ③ one opus call at the apex — the only true cross-cutting judgment
const verdict = await agent(`Synthesize an overall verdict:\n${reviews.join('\n---\n')}`,
                            { model: 'opus', phase: 'Synthesize' })
```

### Escalate-on-failure — let opus handle only the hard ones
You rarely know in advance which implementation units are hard. Don't pre-pay opus for all of them — try sonnet, and promote to opus only when sonnet reports low confidence or fails verification. Most units settle cheaply; the genuinely hard code gets opus automatically.

```js
async function implement(task) {
  const draft = await agent(`Implement: ${task}. Return code + a confidence 0-1.`,
                            { model: 'sonnet', schema: IMPL_SCHEMA })
  if (draft && draft.confidence >= 0.7) return draft
  // hard case — escalate the SAME unit to opus
  return agent(`This was hard for a smaller model. Implement carefully: ${task}`,
               { model: 'opus', schema: IMPL_SCHEMA })
}
```

The branch only fires if `schema` carries the field you test (`confidence` here, or a `verdict`) — without it the model may omit the signal, and then either everything escalates or nothing does. Put that field in the schema.

### Mixed-tier migration — most files mechanical, the core is not
A migration is not uniformly "code = sonnet". Bulk call-site rewrites are mechanical (sonnet, or haiku if truly trivial); the engine/interface at the center is high-stakes (opus). Tier per node:

```js
await parallel(callSites.map(f => () =>
  agent(`Mechanically update import sites in ${f}`, { model: 'sonnet', isolation: 'worktree' })))
const core = await agent(`Rewrite the core adapter — every call site depends on this contract`,
                         { model: 'opus', isolation: 'worktree' })
```

## Anti-patterns

- **Flat all-opus fan-out** — 20 agents on opus doing work haiku could do. This is the #1 token sink. Tier them.
- **Verb-based pigeonholing** — "all coding goes to sonnet" caps quality on the hard implementation that actually needs opus. Tier by difficulty.
- **Relying on inheritance for cost** — leaving `model` off and hoping it's cheap. On an Opus session it is not. Pin it.
- **Skipping the prune** — fanning out over a raw list when a `filter`/`dedupe` would have removed half the calls for free.
- **Prose where schema fits** — letting a data-producing agent ramble; schema is cheaper and cleaner.

## Before launching a workflow, ask:

1. Can plain JS (`filter`/`dedupe`/`slice`) remove any `agent()` calls before they happen?
2. Is each agent on the *smallest model that does it well* — base on haiku, body on sonnet, **convergence and important/hard implementation on opus**?
3. Does every data-producing agent have a `schema`?
4. Is the session model deliberate, so un-pinned agents default to a sane tier?
5. Do `meta.phases[].model` labels match the real per-agent models, so the cost profile reads honestly?
