import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";

const ROOT = new URL("../", import.meta.url);
const READMES = ["README.md", "README_CN.md", "README_TW.md", "README_KO.md", "README_JA.md"];
const REQUIRED = [
  "smart@smart",
  "/smart:*",
  "smart:<name>",
  "ask",
  "/smart:pr",
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

test("all five README variants describe the same Smart plugin surface", async () => {
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
