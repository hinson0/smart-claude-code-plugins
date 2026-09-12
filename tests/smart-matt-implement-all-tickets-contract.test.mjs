import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const read = (path) => readFile(new URL(path, ROOT), "utf8");

test("All Tickets keeps one worker and verified closure before advancement", async () => {
  const skill = await read("plugins/smart/skills/matt-implement-all-tickets/SKILL.md");
  const translation = await read("plugins/smart/skills/matt-implement-all-tickets/CN.md");
  assert.match(skill, /Matt `implement` skill to be explicitly invoked in the same request/);
  assert.match(skill, /exactly the ordered Ticket set/);
  assert.match(skill, /one fresh worker for one Ticket/);
  assert.match(skill, /No parallel or pre-created workers/);
  assert.match(skill, /Independently verify/);
  assert.match(skill, /Only verified closure unlocks the next Ticket/);
  assert.match(skill, /does not authorize push, merge, MR\/PR creation/);
  assert.match(skill, /partial result and stop without duplicating/);
  for (const heading of ["Implementation assets", "Acceptance evidence", "Review conclusion", "Closeout boundaries"]) assert.ok(skill.includes(`## ${heading}`));
  assert.match(translation, /不并行、不预建 worker/);
  assert.match(translation, /只有核实关闭后才能开始下一个 Ticket/);
});
