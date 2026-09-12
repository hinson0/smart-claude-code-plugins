---
name: github-skills-pdf
description: Build a verified A4 handbook from a pinned GitHub skills repository, with English source above Simplified Chinese translation.
disable-model-invocation: true
argument-hint: "<repository-or-url> [--notes 2|4] -- decide before building; 2 or 4 inserts one or two sheets of blank note pages after each chapter"
---

# GitHub Skills PDF

Build a reproducible A4 handbook from a pinned repository.

1. Read the repository through the host's GitHub capability; clone when a complete tree is needed. Record repository, default branch, full commit, version basis, license, and build date. Report missing source or metadata rather than guessing.
2. Discover every official skill from manifests, README commands, and `skills/*/SKILL.md`, excluding examples, fixtures, and deprecated skills. Inventory all Markdown in each skill directory: include supporting material in `references`, or record it in `skip_references` with a reason.
3. Inspect source files to choose language mode: English source uses block-matched Simplified Chinese translation below the original; Chinese or another non-English single-language source uses `monolingual: true` without duplicate translation.
4. Create a project outside this skill directory. Read [book-format.md](references/book-format.md) for `book.json`, front/back matter, dependencies, and note sheets. In bilingual mode read [translation-guide.md](references/translation-guide.md) and translate every included skill and reference. If delegating translations, keep each skill with its references and reread the output yourself.
5. Run the bundled builder from this skill's actual path, fixing pairing errors without weakening validation:

   ```bash
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --check
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --output <output.pdf>
   ```

   Add `--notes 2` or `--notes 4` for one or two complete duplex note sheets after each chapter; omit for none. Use the builder's A4 layout, source-above-translation order, chapter references, fixed source links, contents, bookmarks, and page furniture. When given a screenshot, follow its typography, spacing, dividers, and code background.
6. Inspect PDF metadata, page count, bookmarks, links, and text; render every page with `pdftoppm -png -r 144 <output.pdf> <render-dir>/page`. Check all skills and included references, source links, and rendered pages for clipping, truncation, orphan headings, unexpected blanks, or placeholders. Confirm rendered and PDF page counts agree and requested styling is visible.
7. Report skipped or failed validation before delivery. Return the PDF link, page/skill counts, pinned version, and validation result. Preserve the build project for reproducibility and keep temporary renders separate.
