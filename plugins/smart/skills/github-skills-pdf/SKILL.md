---
name: github-skills-pdf
description: Build a verified A4 handbook from a pinned GitHub skills repository, with English source above Simplified Chinese translation.
disable-model-invocation: true
argument-hint: "<repository-or-url> [full=true] -- once an edition is printed, later runs print only changed chapters unless full=true"
---

# GitHub Skills PDF

Build a reproducible A4 handbook from a pinned repository.

1. Read the repository through the host's GitHub capability; clone when a complete tree is needed. Record repository, default branch, full commit, version basis, license, and build date. Report missing source or metadata rather than guessing.
2. Discover every official skill from manifests, README commands, and `skills/*/SKILL.md`, excluding examples, fixtures, and deprecated skills. Inventory all Markdown in each skill directory: include supporting material in `references`, or record it in `skip_references` with a reason.
3. Inspect source files to choose language mode: English source uses block-matched Simplified Chinese translation below the original; Chinese or another non-English single-language source uses `monolingual: true` without duplicate translation.
4. Reuse the repository's preserved build project when one exists, asking for its path if unknown; otherwise create one outside this skill directory. Read [book-format.md](references/book-format.md) for `book.json`, front/back matter, dependencies, and update packs; set `translator` to whoever actually translates and typesets the edition. In bilingual mode read [translation-guide.md](references/translation-guide.md) and translate every included skill and reference; in an update, translate only the chapters `--check --update` lists and keep other translations unchanged. If delegating translations, keep each skill with its references and reread the output yourself.
5. Run the bundled builder from this skill's actual path, fixing pairing errors without weakening validation:

   ```bash
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --check
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --output <output.pdf>
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --check --update
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --update
   ```

   When the project has `print-ledger.json` and the invocation lacks `full=true`, build an update pack with `--update` as book-format.md describes: only updated and new chapters, opened by an update sheet naming the printed pages to replace, insert, or remove. Stop at the builder's "nothing to print". An edition printed before ledgers existed is first rebuilt at its printed commit to record its ledger. When `--check` reports an unclosed fence in the pinned source, register a fence-only `source_override` with a reason as book-format.md describes; never edit the pinned source. Use the builder's A4 layout, source-above-translation order, chapter references, fixed source links, contents, bookmarks, and page furniture. When given a screenshot, follow its typography, spacing, dividers, and code background.
6. Inspect PDF metadata, page count, bookmarks, links, and text; render every page with `pdftoppm -png -r 144 <output.pdf> <render-dir>/page`. Check all skills and included references, source links, and rendered pages for clipping, truncation, orphan headings, unexpected blanks, or placeholders. Confirm rendered and PDF page counts agree and requested styling is visible.
7. Report skipped or failed validation before delivery. Return the PDF link, page/skill counts, pinned version, and validation result; for an update pack, also the update sheet's replace/insert/remove list. Preserve the build project for reproducibility and keep temporary renders separate.
