import assert from "node:assert/strict";
import { access, readFile, readdir } from "node:fs/promises";
import test from "node:test";
import { discoverSkills } from "./skill-discovery.mjs";

const ROOT = new URL("../", import.meta.url);
const discovered = await discoverSkills();
const skillPath = (name) => discovered.find((skill) => skill.name === name)?.path;
const SMART_SKILLS = [
  "clean-branches",
  "code-simplifier",
  "commit",
  "generate-wiki",
  "github-skills-pdf",
  "help",
  "hud",
  "learning",
  "local",
  "my-weekly",
  "one-by-one",
  "pair-write",
  "pr",
];
const REFERENCES = [
  "skills/coding/code-simplifier/references/worker.md",
  "skills/docs/github-skills-pdf/references/book-format.md",
  "skills/docs/github-skills-pdf/references/translation-guide.md",
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

test("Smart is one dual-host version 7.5.1 release", async () => {
  const [codex, claude] = await Promise.all([
    readJson("plugins/smart/.codex-plugin/plugin.json"),
    readJson("plugins/smart/.claude-plugin/plugin.json"),
  ]);

  assert.equal(codex.name, "smart");
  assert.equal(claude.name, "smart");
  assert.equal(codex.version, "7.5.1");
  assert.equal(claude.version, "7.5.1");
  assert.equal(codex.skills, "./skills/");
  assert.deepEqual(claude.skills, ["./skills/git/", "./skills/coding/", "./skills/docs/", "./skills/utilities/"]);
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

  assert.deepEqual(actual, ["coding", "docs", "git", "utilities"]);
  assert.deepEqual(discovered.map((skill) => skill.name), SMART_SKILLS);
  assert.equal(skillPath("help"), "utilities/help");
  for (const skill of discovered) {
    assert.equal(skill.path.split("/").length, 2);
  }
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
    const files = await readdir(new URL(`plugins/smart/skills/${skillPath(skill)}/`, ROOT));
    assert.ok(files.includes("SKILL.md"), `${skill} is missing SKILL.md`);
    assert.ok(files.includes("CN.md"), `${skill} is missing CN.md`);

    const [source, translation, openaiMetadata] = await Promise.all([
      readFile(new URL(`plugins/smart/skills/${skillPath(skill)}/SKILL.md`, ROOT), "utf8"),
      readFile(new URL(`plugins/smart/skills/${skillPath(skill)}/CN.md`, ROOT), "utf8"),
      readFile(
        new URL(`plugins/smart/skills/${skillPath(skill)}/agents/openai.yaml`, ROOT),
        "utf8",
      ),
    ]);
    assert.match(source, /^disable-model-invocation: true$/m, `${skill} invocation policy`);
    assert.match(translation, /^disable-model-invocation: true$/m, `${skill} Chinese invocation policy`);

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


test("Git skills require explicit invocation on both hosts", async () => {
  for (const skill of ["commit", "pr", "clean-branches"]) {
    const [source, translation, metadata] = await Promise.all([
      readFile(new URL(`plugins/smart/skills/${skillPath(skill)}/SKILL.md`, ROOT), "utf8"),
      readFile(new URL(`plugins/smart/skills/${skillPath(skill)}/CN.md`, ROOT), "utf8"),
      readFile(new URL(`plugins/smart/skills/${skillPath(skill)}/agents/openai.yaml`, ROOT), "utf8"),
    ]);
    for (const document of [source, translation]) {
      assert.match(document.split("---")[1], /^disable-model-invocation: true$/m);
    }
    assert.match(metadata, /^policy:\n  allow_implicit_invocation: false$/m);
  }
});


test("removed presentation and ask components are not shipped", async () => {
  for (const path of [
    "plugins/smart/skills/ask",
    "plugins/smart/skills/html",
    "plugins/smart/skills/show",
    "assets/demos/plan-review-demo.html",
    "assets/demos/report-demo.html",
  ]) {
    await assert.rejects(access(new URL(path, ROOT)), { code: "ENOENT" });
  }
  const manifest = await readJson("plugins/smart/.codex-plugin/plugin.json");
  assert.ok(!manifest.keywords.includes("html"));
  assert.doesNotMatch(JSON.stringify(manifest.interface), /\$smart:(?:ask|html|show)\b|Markdown-to-HTML|read-only guidance/);
});
