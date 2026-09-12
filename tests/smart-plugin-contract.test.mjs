import assert from "node:assert/strict";
import { access, readFile, readdir } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const SMART_SKILLS = [
  "ask",
  "clean-branches",
  "close-issue",
  "code-simplifier",
  "commit",
  "generate-wiki",
  "github-skills-pdf",
  "help",
  "html",
  "hud",
  "learning",
  "local",
  "matt-implement-all-tickets",
  "my-weekly",
  "one-by-one",
  "pair-write",
  "pr",
  "show",
];
const REFERENCES = [
  "skills/code-simplifier/references/worker.md",
  "skills/github-skills-pdf/references/book-format.md",
  "skills/github-skills-pdf/references/translation-guide.md",
  "skills/my-weekly/references/report-format.md",
  "skills/show/references/layouts.md",
];

async function readJson(path) {
  return JSON.parse(await readFile(new URL(path, ROOT), "utf8"));
}

function pluginNames(marketplace) {
  return marketplace.plugins.map((plugin) => plugin.name).sort();
}

test("both marketplaces publish only Smart", async () => {
  const [codex, claude] = await Promise.all([
    readJson(".agents/plugins/marketplace.json"),
    readJson(".claude-plugin/marketplace.json"),
  ]);

  assert.deepEqual(pluginNames(codex), ["smart"]);
  assert.deepEqual(pluginNames(claude), ["smart"]);
});

test("Smart is one dual-host version 6.6.0 release", async () => {
  const [codex, claude] = await Promise.all([
    readJson("plugins/smart/.codex-plugin/plugin.json"),
    readJson("plugins/smart/.claude-plugin/plugin.json"),
  ]);

  assert.equal(codex.name, "smart");
  assert.equal(claude.name, "smart");
  assert.equal(codex.version, "6.6.0");
  assert.equal(claude.version, "6.6.0");
  assert.equal(codex.skills, "./skills/");
  assert.ok(codex.interface.defaultPrompt.length <= 3);
});

test("Smart exposes exactly the agreed skill surface", async () => {
  const entries = await readdir(new URL("plugins/smart/skills/", ROOT), {
    withFileTypes: true,
  });
  const actual = entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();

  assert.deepEqual(actual, SMART_SKILLS);
  await assert.rejects(access(new URL("plugins/fuzz/.codex-plugin/plugin.json", ROOT)));
});

test("agent instructions have one root source of truth", async () => {
  const [agents, claude] = await Promise.all([
    readFile(new URL("AGENTS.md", ROOT), "utf8"),
    readFile(new URL("CLAUDE.md", ROOT), "utf8"),
  ]);

  assert.match(agents, /根目录 `CLAUDE\.md`/);
  assert.match(claude, /^# Smart Dual-Host Plugin$/m);
  assert.match(claude, /disable-model-invocation: true/);
  assert.match(claude, /display_name.*smart:<SKILL\.md name>/);
  await assert.rejects(access(new URL(".claude/CLAUDE.md", ROOT)));
});

test("every Smart skill and reference has its Chinese companion", async () => {
  for (const skill of SMART_SKILLS) {
    const files = await readdir(new URL(`plugins/smart/skills/${skill}/`, ROOT));
    assert.ok(files.includes("SKILL.md"), `${skill} is missing SKILL.md`);
    assert.ok(files.includes("CN.md"), `${skill} is missing CN.md`);

    const [source, translation, openaiMetadata] = await Promise.all([
      readFile(new URL(`plugins/smart/skills/${skill}/SKILL.md`, ROOT), "utf8"),
      readFile(new URL(`plugins/smart/skills/${skill}/CN.md`, ROOT), "utf8"),
      readFile(
        new URL(`plugins/smart/skills/${skill}/agents/openai.yaml`, ROOT),
        "utf8",
      ),
    ]);
    assert.match(
      source,
      /^disable-model-invocation: true$/m,
      `${skill} allows model invocation`,
    );
    assert.match(
      translation,
      /^disable-model-invocation: true$/m,
      `${skill} Chinese companion allows model invocation`,
    );

    const sourceDescription = source.match(/^description: (.+)$/m)?.[1];
    const translatedDescription = translation.match(/^description: (.+)$/m)?.[1];
    const sourceName = source.match(/^name: (.+)$/m)?.[1];
    const displayName = openaiMetadata.match(/^\s*display_name: "(.+)"$/m)?.[1];
    assert.equal(sourceName, skill, `${skill} name differs from its directory`);
    assert.equal(
      displayName,
      `smart:${sourceName}`,
      `${skill} display_name differs from its Claude Code invocation`,
    );
    assert.ok(sourceDescription, `${skill} is missing a one-line description`);
    assert.ok(
      translatedDescription,
      `${skill} Chinese companion is missing a one-line description`,
    );
    assert.ok(sourceDescription.length <= 140, `${skill} description is too long`);
    assert.ok(
      translatedDescription.length <= 140,
      `${skill} Chinese description is too long`,
    );
    assert.doesNotMatch(
      sourceDescription,
      /\b(?:use when|trigger on|should be used when)\b/i,
      `${skill} description contains model-facing trigger language`,
    );
  }

  for (const reference of REFERENCES) {
    const slash = reference.lastIndexOf("/");
    const directory = reference.slice(0, slash + 1);
    const name = reference.slice(slash + 1, -3);
    const files = await readdir(new URL(`plugins/smart/${directory}`, ROOT));
    assert.ok(files.includes(`CN[${name}].md`), `${reference} is missing CN companion`);
  }
});
