import { readdir } from "node:fs/promises";

const ROOT = new URL("../plugins/smart/skills/", import.meta.url);

// Discover entrypoints rather than treating category folders as skills.
export async function discoverSkills(directory = ROOT, prefix = "") {
  const entries = await readdir(directory, { withFileTypes: true });
  if (entries.some((entry) => entry.isFile() && entry.name === "SKILL.md")) {
    return [{ name: prefix.split("/").at(-1), path: prefix }];
  }
  const nested = await Promise.all(entries.filter((entry) => entry.isDirectory()).map(
    (entry) => discoverSkills(new URL(`${entry.name}/`, directory), prefix ? `${prefix}/${entry.name}` : entry.name),
  ));
  return nested.flat().sort((left, right) => left.name.localeCompare(right.name));
}
