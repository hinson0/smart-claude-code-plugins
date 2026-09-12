import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const read = (path) => readFile(new URL(path, ROOT), "utf8");

test("Weekly reports retain read-only scope and Git evidence boundaries", async () => {
  const skill = await read("plugins/smart/skills/my-weekly/SKILL.md");
  const chinese = await read("plugins/smart/skills/my-weekly/CN.md");
  assert.match(skill, /Monday 00:00, and committer timestamps/);
  assert.match(skill, /without fetch, checkout, configuration, or worktree changes/);
  assert.match(skill, /every selected commit's parents are available/);
  assert.match(skill, /author email exactly, case-insensitively/);
  assert.match(skill, /exclude stash and merge commits, and deduplicate by full SHA/);
  assert.match(skill, /Do not invent business impact/);
  assert.match(skill, /credential-free/);
  for (const flag of ["--no-ext-diff", "--no-textconv"]) assert.ok(skill.includes(flag));
  assert.match(skill, /Reject[^.]*ext::[^.]*unknown remote helpers/);
  for (const heading of ["Completed This Week", "Commit Statistics", "Commit Evidence"]) assert.ok(skill.includes(heading));
  assert.match(skill, /no matching non-merge commits were found, show zero statistics/);
  assert.match(chinese, /周一 00:00/);
  assert.match(chinese, /按完整 SHA 去重/);
});
