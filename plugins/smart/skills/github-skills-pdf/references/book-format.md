# Bilingual Project Format

## Directory layout

The calling workflow creates the project directory. Recommended layout:

```text
book/
├── book.json
├── FRONT_EN.md
├── FRONT_ZH.md
├── BACK_EN.md
├── BACK_ZH.md
├── translation/
│   ├── <skill>.md
│   └── <skill>-<reference>.md
└── source/
    └── <clone or path to clone>
```

Name reference translations `<skill>-<lowercase-source-filename>.md` so their
owner remains obvious.

Paths in `book.json` resolve relative to the project directory. Source files
may live outside that directory, but their configured paths must still be
stable and explicit.

## book.json

```json
{
  "title_en": "Ponytail",
  "title_zh": "Bilingual Study Handbook",
  "version": "4.8.4",
  "commit": "16f29800fd2681bdf24f3eb4ccffe38be3baec6b",
  "build_date": "2026-07-30",
  "original_author": "DietrichGebert",
  "output": "ponytail-bilingual-handbook.pdf",
  "logo": "source/assets/logo-dark.png",
  "cover_label": "THE LAZY SENIOR DEV, IN TWO LANGUAGES",
  "cover_subtitle": "6 official skills · English above · Chinese below",
  "header_label": "PONYTAIL · BILINGUAL LEARNING EDITION",
  "front": {
    "en": "FRONT_EN.md",
    "zh": "FRONT_ZH.md",
    "kicker": "START HERE",
    "description_en": "How to read and verify this edition.",
    "description_zh": "How to read and verify this edition."
  },
  "back": {
    "en": "BACK_EN.md",
    "zh": "BACK_ZH.md",
    "kicker": "REFERENCE",
    "description_en": "Source links and license.",
    "description_zh": "Source links and license."
  },
  "skills": [
    {
      "name": "ponytail",
      "title_en": "Ponytail",
      "source": "source/skills/ponytail/SKILL.md",
      "translation": "translation/ponytail.md",
      "source_url": "https://github.com/DietrichGebert/ponytail/blob/16f29800fd2681bdf24f3eb4ccffe38be3baec6b/skills/ponytail/SKILL.md",
      "references": [
        {
          "source": "source/skills/ponytail/BRAID-FORMAT.md",
          "translation": "translation/ponytail-braid-format.md",
          "source_url": "https://github.com/DietrichGebert/ponytail/blob/16f29800fd2681bdf24f3eb4ccffe38be3baec6b/skills/ponytail/BRAID-FORMAT.md"
        }
      ],
      "skip_references": []
    }
  ]
}
```

Required fields:

- root: `title_en`, `title_zh`, `version`, full 40-character `commit`, nonempty
  `skills`, `front`, and `back`;
- each skill: `name`, `title_en`, `source`, `translation`, and `source_url`;
- every `source_url` must contain the root full commit; and
- `front` and `back`: `en` and `zh`.

The builder uses the current date when `build_date` is omitted. `logo` is
optional; omitting it produces a black cover. `repo_url` is optional and helps
resolve relative links in front and back matter. `original_author` and
`translator` fill the PDF author metadata; set `translator` to whoever actually
translated and typeset the edition, or omit it to credit only the original
author.

## Monolingual projects

When the source repository already uses one language, there is no source/
translation pair to align. Set `"monolingual": true` at the root. The body uses
one stream while the contents, bookmarks, headers, page numbers, fixed source
links, references, and `--notes` sheets remain unchanged.

Monolingual projects use neutral field names instead of `_en` and `_zh`:

```json
{
  "monolingual": true,
  "title": "GitHub Collaboration Skill Handbook",
  "version": "1.0.0",
  "commit": "0123456789abcdef0123456789abcdef01234567",
  "front": { "file": "front.md", "description": "Read this first." },
  "back": { "file": "back.md" },
  "skills": [
    {
      "name": "github-issue-triage",
      "title": "GitHub Issue Triage",
      "source": "source/github-issue-triage/SKILL.md",
      "source_url": "https://github.com/example/skills/blob/0123456789abcdef0123456789abcdef01234567/github-issue-triage/SKILL.md",
      "references": [
        {
          "title": "Deduplication Rules",
          "source": "source/github-issue-triage/DEDUPE.md",
          "source_url": "https://github.com/example/skills/blob/0123456789abcdef0123456789abcdef01234567/github-issue-triage/DEDUPE.md"
        }
      ]
    }
  ]
}
```

The mode differences are limited to:

- `title` replaces `title_en` plus `title_zh`;
- `front.file`, `back.file`, and `description` replace `en`, `zh`,
  `description_en`, and `description_zh`;
- each skill and reference uses `title` instead of `title_en`, and has no
  `translation`; and
- chapter and section headings and bodies render once.

Configuring `translation` together with `monolingual` is an error, never a
silently ignored contradiction. Neutral aliases normalize only in monolingual
mode. Bilingual projects must continue to use `title_en`, `title_zh`, and the
language-specific fields.

## References

Many skills split format contracts, templates, and deep material into sibling
Markdown files referenced by `@FILE.md` or relative links. These files are part
of the skill body and render as in-chapter sections after `SKILL.md`.

Each `references` entry requires `source`, `translation`, and `source_url`, with
the same full-commit constraint. `title_en` is optional and otherwise comes
from the source H1. The Chinese title comes from translation front matter
`zh_title`, falling back to its H1.

For every skill whose source is `SKILL.md`, the builder scans all sibling
Markdown files. Any file missing from both `references` and `skip_references`
causes `--check` and generation to fail. This reverse validation deliberately
turns a silent broken-link omission into a build failure.

Automatic reverse validation applies only when `source` is named `SKILL.md`,
because `skills/*/SKILL.md` guarantees one owning skill per directory. A custom
source filename cannot establish that ownership, so the builder reports that
automatic checking was skipped and the caller must verify completeness.

Use `skip_references` for files that genuinely are not part of the body:

```json
"skip_references": ["CHANGELOG.md"]
```

Every skip is printed by `--check`; it is never silent.

Use `--notes 2` or `--notes 4` to reserve one or two duplex sheets after each
skill chapter. Blank pages omit headers, page numbers, and borders. Front and
back matter receive no note sheets, and omitting the option inserts none.

Notes count physical sheets rather than pages. If a chapter ends on the front
of a duplex sheet, the builder adds a blank back before complete note sheets.
The actual blank-page count can therefore exceed the option by one, but every
note run occupies complete sheets and the next chapter starts on a front.

## Front and back matter

Bilingual front and back Markdown must also be block-structurally identical
and begin with matching H1 headings.

Front matter must cover:

- included scope;
- recommended reading order;
- English-above-Chinese layout;
- installation or usage; and
- pinned version and commit.

Back matter must include:

- a skills overview;
- an explanation of fixed source links; and
- the original license plus its Chinese translation.

## Dependencies

The builder uses Python 3 and ReportLab and searches for CJK fonts on each
platform:

- macOS: STHeiti or Arial Unicode;
- Linux: Noto Sans CJK or WenQuanYi Zen Hei;
- Windows: Microsoft YaHei or Arial Unicode.

Validation uses Poppler, pypdf, pdfplumber, and Pillow. If a dependency or CJK
font is missing, first load the host workspace dependencies. If still missing,
report it rather than skipping validation.
