import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const read = (path) => readFile(new URL(path, ROOT), "utf8");

test("Wiki preserves publication targets and safe, truthful writes", async () => {
  const skill = await read("plugins/smart/skills/generate-wiki/SKILL.md");
  const chinese = await read("plugins/smart/skills/generate-wiki/CN.md");
  for (const target of ["GitLab Wiki", "GitHub Wiki", "Local Wiki"]) assert.ok(skill.includes(target));
  assert.match(skill, /Create without overwriting; update only on explicit request/);
  assert.match(skill, /Preserve concurrent changes/);
  assert.match(skill, /protections must hold at the final write/);
  assert.match(skill, /Never publish credentials/);
  assert.match(skill, /preserve the draft on remote failure/);
  assert.match(skill, /verify its content and image targets/);
  assert.match(skill, /uncertain[\s\S]*inspect remote state[\s\S]*before retrying/i);
  assert.match(skill, /non-force pushes/);
  assert.match(skill, /stable bytes[\s\S]*regular non-symlink files[\s\S]*20 MiB/);
  assert.match(skill, /upload those verified bytes without reopening an unchecked source/);
  assert.match(chinese, /保护并发改动/);
  assert.match(chinese, /远端失败时保留草稿/);
});
