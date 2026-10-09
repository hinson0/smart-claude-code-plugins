# Block-by-Block Translation Guide

Use this guide only in bilingual mode. A repository already written in a
single language uses monolingual mode, with no translation or block pairing;
see the monolingual section of [book-format.md](book-format.md).

## Goal

Let the builder place every English Markdown block immediately above its
corresponding Simplified Chinese block while proving that no source content was
omitted and no executable command was mistranslated.

## Translation format

Each translation starts with:

```yaml
---
name: <original skill name, untranslated>
zh_title: <Chinese title>
description: >
  <complete Chinese translation of the original description>
---
```

Sibling references such as `MISSION-FORMAT.md` use the same front matter.
`name` remains the owning skill name, and `zh_title` names the reference. Omit
`description` only when the reference has no independent description. A
reference follows the same completeness standard as `SKILL.md`.

After front matter, every body block must correspond to the source body:

- headings have identical counts, order, and levels;
- paragraphs have identical counts and order;
- list items have identical counts, order, and list types;
- tables have identical row and column shapes; and
- fenced code blocks have identical counts, language markers, and positions.

Translate the first H1. Do not add translator notes, summaries, extra sections,
or claims absent from the source.

## Preserve verbatim

Keep these unchanged:

- skill names and invocation commands;
- code, identifiers, configuration keys, paths, and URLs;
- abbreviations such as `YAGNI` without an exact substitute; and
- labels, protocol fields, and original error messages.

Reader-facing text inside a code block may be translated, but executable
commands and configuration structure must not change.

## Style

- Write natural, precise, direct Simplified Chinese rather than word-for-word
  prose.
- Preserve the source's imperative force, limits, humor, and strictness.
- Use technical terms consistently and never omit exceptions or failure cases
  for fluency.
- Use Chinese punctuation in prose while leaving code punctuation unchanged.
- Mark emphasis next to Chinese text with `*...*`. Underscore emphasis follows
  CommonMark and never opens or closes inside a word, so `_..._` touching CJK
  characters stays literal, both in the PDF and on GitHub.
