import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const read = (path) => readFile(new URL(path, ROOT), "utf8");

test("Smart pair-write preserves the focused comparison loop", async () => {
  const [skill, translation, metadata] = await Promise.all([
    read("plugins/smart/skills/coding/pair-write/SKILL.md"),
    read("plugins/smart/skills/coding/pair-write/CN.md"),
    read("plugins/smart/skills/coding/pair-write/agents/openai.yaml"),
  ]);

  for (const document of [skill, translation]) {
    assert.match(document, /^name: pair-write$/m);
    assert.match(document, /^disable-model-invocation: true$/m);
    assert.doesNotMatch(document, /<details>/);
    assert.match(document, /Comment skeleton|注释骨架/);
    assert.match(document, /Complete reference implementation|完整参考实现/);
    assert.match(document, /transcription correctness|书写是否正确/);
    assert.match(document, /Equivalent code is\s+valid|等价写法有效/);
    assert.match(document, /only when the user requests them|只有用户要求时/);
    assert.doesNotMatch(document, /risk-matched formatting|与风险匹配的真实格式/);
    assert.match(document, /Migration|Migration/);
    assert.match(document, /\.claude\/CLAUDE\.local\.md/);
  }

  assert.match(metadata, /allow_implicit_invocation: false/);
  assert.match(metadata, /default_prompt: "Use \$smart:pair-write/);
});
