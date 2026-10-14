import assert from "node:assert/strict";
import { access, readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);

async function read(path) {
  return readFile(new URL(path, ROOT), "utf8");
}

test("Smart routes code simplification to one fresh non-recursive worker", async () => {
  const [skill, chinese, worker, chineseWorker, agent, openaiMetadata] =
    await Promise.all([
      read("plugins/smart/skills/coding/code-simplifier/SKILL.md"),
      read("plugins/smart/skills/coding/code-simplifier/CN.md"),
      read("plugins/smart/skills/coding/code-simplifier/references/worker.md"),
      read("plugins/smart/skills/coding/code-simplifier/references/CN[worker].md"),
      read("plugins/smart/agents/code-simplifier-worker.md"),
      read("plugins/smart/skills/coding/code-simplifier/agents/openai.yaml"),
    ]);

  assert.match(skill, /smart:code-simplifier-worker/);
  assert.match(skill, /`fork_turns` to `none`/);
  assert.match(skill, /exactly one subagent/);
  assert.match(skill, /Always dispatch/);
  assert.match(skill, /worker alone may return `blocked`/);
  assert.match(skill, /performs no\s+repository inspection/);
  assert.match(skill, /never takes over/);
  assert.match(skill, /references\/worker\.md/);

  assert.match(chinese, /smart:code-simplifier-worker/);
  assert.match(chinese, /`fork_turns` 设置为 `none`/);
  assert.match(chinese, /主 agent 不得接管/);
  assert.match(chinese, /始终派发/);
  assert.match(chinese, /只有 worker 可以返回 `blocked`/);

  assert.match(agent, /^name: code-simplifier-worker$/m);
  assert.match(agent, /^model: inherit$/m);
  assert.match(agent, /^tools: Read, Edit, Write, Bash, Glob, Grep$/m);
  assert.doesNotMatch(agent.match(/^tools:.*$/m)?.[0] ?? "", /Agent|Skill/);
  assert.match(
    agent,
    /\$\{CLAUDE_PLUGIN_ROOT\}\/skills\/coding\/code-simplifier\/references\/worker\.md/,
  );

  for (const contract of [
    "Work serially and without delegation",
    "Preserve observable behavior exactly",
    "pre-edit status and diff",
    "return `blocked`",
    "Capture the strongest practical pre-edit baseline",
    "Review the final diff line by line",
    "remove only that worker-authored edit",
  ]) {
    assert.ok(worker.includes(contract), `worker is missing contract: ${contract}`);
  }

  for (const contract of [
    "串行工作且不再委派",
    "严格保持可观察行为不变",
    "记录范围内文件编辑前的状态和 diff",
    "返回 `blocked`",
    "逐行审查最终 diff",
  ]) {
    assert.ok(chineseWorker.includes(contract), `中文 worker 缺少合同：${contract}`);
  }

  assert.match(openaiMetadata, /display_name: "smart:code-simplifier"/);
  await access(new URL("plugins/smart/skills/coding/code-simplifier/LICENSE", ROOT));
});
