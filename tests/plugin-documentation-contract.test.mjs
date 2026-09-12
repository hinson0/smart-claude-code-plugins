import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const READMES = ["README.md", "README_CN.md"];
const REQUIRED = [
  "smart@smart",
  "/smart:*",
  "smart:<name>",
  "ask",
  "/smart:pr",
  "/smart:clean-branches",
  "close-issue",
  "code-simplifier",
  "matt-implement-all-tickets",
  "generate-wiki",
  "github-skills-pdf",
  "my-weekly",
  "one-by-one",
  "html",
  "show",
];
const REMOVED = ["fuzz@smart", "/fuzz:*", "fuzz@ce-workflow", "Joke Teller"];

test("both README variants describe the same Smart plugin surface", async () => {
  for (const file of READMES) {
    const content = await readFile(new URL(file, ROOT), "utf8");
    for (const token of REQUIRED) {
      assert.ok(content.includes(token), `${file} is missing ${token}`);
    }
    for (const token of REMOVED) {
      assert.ok(!content.includes(token), `${file} still contains ${token}`);
    }
  }
});


test("only English and Simplified Chinese README variants are published", async () => {
  const files = await readdir(ROOT);
  assert.deepEqual(files.filter((file) => /^README.*\.md$/.test(file)).sort(), READMES);
  for (const file of READMES) {
    const content = await readFile(new URL(file, ROOT), "utf8");
    assert.ok(content.includes("[English](./README.md) | [简体中文](./README_CN.md)"));
    assert.doesNotMatch(content, /README_(?:TW|KO|JA)\.md/);
  }
});
