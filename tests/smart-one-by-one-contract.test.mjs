import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const read = (path) => readFile(new URL(path, ROOT), "utf8");

test("Smart one-by-one preserves one complete Red-to-Green cycle", async () => {
  const [skill, translation, metadata] = await Promise.all([
    read("plugins/smart/skills/one-by-one/SKILL.md"),
    read("plugins/smart/skills/one-by-one/CN.md"),
    read("plugins/smart/skills/one-by-one/agents/openai.yaml"),
  ]);

  assert.match(skill, /^name: one-by-one$/m);
  assert.match(skill, /^disable-model-invocation: true$/m);
  assert.match(skill, /## Cycle boundary/);
  assert.doesNotMatch(skill, /Invocation boundary|explicitly invokes/);
  assert.match(skill, /exactly one minimal cycle/);
  assert.match(skill, /Land only the minimal Red test/);
  assert.match(skill, /target behavior is missing/);
  assert.match(skill, /same response/);
  assert.match(skill, /repository-relative paths/);
  assert.match(skill, /Do not run tests/);
  assert.match(skill, /exact lines, evidence, and impact/);
  assert.match(skill, /preserve newer user changes/);
  assert.match(skill, /until explicit acceptance/);
  assert.match(skill, /“continue” is not acceptance/);
  assert.match(skill, /the agent lands Red, the user lands\s+Green/);
  assert.match(skill, /explicit request to fix authorizes/);
  assert.doesNotMatch(skill, /[\p{Script=Han}]/u);

  assert.match(translation, /每轮只处理一个最小 Cycle/);
  assert.match(translation, /用户明确验收通过前/);
  assert.match(metadata, /default_prompt: "Use \$smart:one-by-one/);
  assert.match(metadata, /allow_implicit_invocation: false/);
  assert.doesNotMatch(metadata, /[\p{Script=Han}]/u);
});
