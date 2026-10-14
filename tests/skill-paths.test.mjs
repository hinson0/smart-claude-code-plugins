import assert from "node:assert/strict";
import { access, readFile, readdir } from "node:fs/promises";
import test from "node:test";
import { discoverSkills } from "./skill-discovery.mjs";

const PLUGIN = new URL("../plugins/smart/", import.meta.url);

test("manifest skill roots cover the published entrypoints exactly once", async () => {
  const manifest = JSON.parse(await readFile(new URL(".claude-plugin/plugin.json", PLUGIN), "utf8"));
  const roots = ["./skills/", ...manifest.skills];
  const published = [];
  for (const root of roots) {
    const directory = new URL(root, PLUGIN);
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      if (!entry.isDirectory()) continue;
      const files = await readdir(new URL(`${entry.name}/`, directory));
      if (files.includes("SKILL.md")) published.push(entry.name);
    }
  }
  assert.deepEqual(published.sort(), (await discoverSkills()).map((skill) => skill.name));
});

test("moved skills retain valid Markdown and plugin-root resource links", async () => {
  async function check(directory) {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const file = new URL(entry.name, directory);
      if (entry.isDirectory()) {
        await check(new URL(`${entry.name}/`, directory));
      } else if (entry.name.endsWith(".md")) {
        const source = await readFile(file, "utf8");
        for (const [, path] of source.matchAll(/\]\(([^\s)]+)\)/g)) {
          if (/^(?:https?:|#)/.test(path)) continue;
          await access(new URL(path, file));
        }
        for (const [, path] of source.matchAll(/\$\{CLAUDE_PLUGIN_ROOT\}\/([^`\s]+)/g)) {
          await access(new URL(path, PLUGIN));
        }
      }
    }
  }
  await check(new URL("skills/", PLUGIN));
  await check(new URL("agents/", PLUGIN));
});
