#!/usr/bin/env python3
"""Build a bilingual Smart skills handbook."""

from __future__ import annotations

import argparse
import hashlib
import html
import json
import re
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from urllib.parse import urljoin

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen.canvas import Canvas
from reportlab.platypus import (
    BaseDocTemplate,
    CondPageBreak,
    Flowable,
    Frame,
    HRFlowable,
    KeepTogether,
    NextPageTemplate,
    PageBreak,
    PageTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.platypus.xpreformatted import XPreformatted


BLACK = colors.HexColor("#111111")
INK = colors.HexColor("#24272B")
MUTED = colors.HexColor("#697078")
LINE = colors.HexColor("#D9DDE2")
PALE = colors.HexColor("#F3F4F6")
CODE_BG = colors.HexColor("#F1F3F4")
WHITE = colors.white
PAGE_WIDTH, PAGE_HEIGHT = A4
CONTENT_WIDTH = 169 * mm
# Records which chapter versions are on paper, so updates print only changes.
LEDGER_FILE = "print-ledger.json"


@dataclass(frozen=True)
class Block:
    kind: str
    text: str = ""
    level: int = 0
    marker: str = ""
    language: str = ""
    rows: tuple[tuple[str, ...], ...] = ()


class BookArgumentParser(argparse.ArgumentParser):
    """Argument parser kept as a named seam for contract tests."""


def normalize_monolingual(config: dict) -> None:
    """Normalize neutral monolingual fields to internal `_en` fields.

    Bilingual projects use language-specific fields. A monolingual project has
    one stream, so public neutral aliases are mapped here and the rendering
    layer does not need mode-specific field access.
    """
    if config.get("title"):
        config.setdefault("title_en", config["title"])
    config.setdefault("title_zh", "")
    for label in ("front", "back"):
        section = config.get(label)
        if not isinstance(section, dict):
            continue
        if section.get("file"):
            section.setdefault("en", section["file"])
        if section.get("description"):
            section.setdefault("description_en", section["description"])
    for skill in config.get("skills") or []:
        if not isinstance(skill, dict):
            continue
        if skill.get("title"):
            skill.setdefault("title_en", skill["title"])
        for reference in skill.get("references") or []:
            if isinstance(reference, dict) and reference.get("title"):
                reference.setdefault("title_en", reference["title"])


def load_config(project_dir: Path) -> dict:
    path = project_dir / "book.json"
    if not path.exists():
        raise FileNotFoundError(f"Missing configuration file: {path}")
    config = json.loads(path.read_text(encoding="utf-8"))
    if "skills" in config and not isinstance(config["skills"], list):
        raise ValueError("book.json skills must be an array")
    monolingual = bool(config.get("monolingual"))
    if monolingual:
        normalize_monolingual(config)
    required = ["title_en", "version", "commit", "skills", "front", "back"]
    if not monolingual:
        required.insert(1, "title_zh")
    for key in required:
        if not config.get(key):
            raise ValueError(f"book.json is missing required field: {key}")
    commit = str(config["commit"])
    if not re.fullmatch(r"[0-9a-fA-F]{40}", commit):
        raise ValueError("book.json commit must be a 40-character Git commit SHA")
    config["commit"] = commit.lower()
    config.setdefault("build_date", date.today().isoformat())
    if monolingual:
        config.setdefault("cover_label", "SKILLS LEARNING EDITION")
        config.setdefault(
            "cover_subtitle", f"{len(config['skills'])} 个正式技能"
        )
    else:
        config.setdefault("cover_label", "BILINGUAL SKILLS LEARNING EDITION")
        config.setdefault(
            "cover_subtitle",
            f"{len(config['skills'])} 个正式技能 · 英文原文在上 · 简体中文翻译在下",
        )
    return config


def project_path(project_dir: Path, value: str) -> Path:
    return (project_dir / value).resolve()


def register_fonts() -> None:
    regular = [
        ("/System/Library/Fonts/STHeiti Light.ttc", 0),
        ("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc", 0),
        ("/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.otf", None),
        ("/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc", 0),
        ("C:/Windows/Fonts/msyh.ttc", 0),
    ]
    bold = [
        ("/System/Library/Fonts/STHeiti Medium.ttc", 0),
        ("/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc", 0),
        ("/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.otf", None),
        ("C:/Windows/Fonts/msyhbd.ttc", 0),
        *regular,
    ]
    mono = [
        ("/System/Library/Fonts/Supplemental/Arial Unicode.ttf", None),
        ("/usr/share/fonts/opentype/noto/NotoSansMonoCJK-Regular.ttc", 0),
        ("C:/Windows/Fonts/arialuni.ttf", None),
        *regular,
    ]

    def register(name: str, candidates: list[tuple[str, int | None]]) -> None:
        failures: list[str] = []
        for raw_path, subfont_index in candidates:
            path = Path(raw_path)
            if not path.exists():
                continue
            try:
                options = (
                    {"subfontIndex": subfont_index}
                    if subfont_index is not None
                    else {}
                )
                pdfmetrics.registerFont(TTFont(name, str(path), **options))
                return
            except Exception as error:
                failures.append(f"{path}: {error}")
        detail = f"; read failures: {'; '.join(failures)}" if failures else ""
        raise RuntimeError(
            "No embeddable CJK font was found; install Noto Sans CJK or "
            f"Microsoft YaHei, or use the built-in macOS CJK fonts{detail}"
        )

    register("BookSans", regular)
    register("BookSansBold", bold)
    register("BookMono", mono)
    pdfmetrics.registerFontFamily(
        "BookSans",
        normal="BookSans",
        bold="BookSansBold",
        italic="BookSans",
        boldItalic="BookSansBold",
    )


def build_styles() -> dict[str, ParagraphStyle]:
    sample = getSampleStyleSheet()
    return {
        "cover-label": ParagraphStyle(
            "CoverLabel",
            parent=sample["BodyText"],
            fontName="BookSansBold",
            fontSize=9,
            leading=13,
            textColor=colors.HexColor("#B8BDC4"),
            spaceAfter=7 * mm,
        ),
        "cover-title": ParagraphStyle(
            "CoverTitle",
            parent=sample["Title"],
            fontName="BookSansBold",
            fontSize=31,
            leading=40,
            textColor=WHITE,
            alignment=TA_LEFT,
            spaceAfter=8 * mm,
        ),
        "cover-subtitle": ParagraphStyle(
            "CoverSubtitle",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=12,
            leading=19,
            textColor=colors.HexColor("#E6E8EA"),
            spaceAfter=31 * mm,
        ),
        "cover-meta": ParagraphStyle(
            "CoverMeta",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=8.5,
            leading=14,
            textColor=colors.HexColor("#A8AEB5"),
        ),
        "toc-title": ParagraphStyle(
            "TocTitle",
            parent=sample["Heading1"],
            fontName="BookSansBold",
            fontSize=25,
            leading=32,
            textColor=BLACK,
            spaceAfter=4 * mm,
        ),
        "small": ParagraphStyle(
            "Small",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=8.2,
            leading=13,
            textColor=MUTED,
            wordWrap="CJK",
        ),
        "chapter-kicker": ParagraphStyle(
            "ChapterKicker",
            parent=sample["BodyText"],
            fontName="BookSansBold",
            fontSize=8.5,
            leading=12,
            textColor=MUTED,
            spaceAfter=4 * mm,
        ),
        "chapter-title": ParagraphStyle(
            "ChapterTitle",
            parent=sample["Heading1"],
            fontName="BookSansBold",
            fontSize=24,
            leading=31,
            textColor=BLACK,
            spaceAfter=5 * mm,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "chapter-en": ParagraphStyle(
            "ChapterEnglish",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=9.5,
            leading=14.5,
            textColor=INK,
            spaceAfter=1.5 * mm,
            wordWrap="CJK",
        ),
        "chapter-zh": ParagraphStyle(
            "ChapterChinese",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=9.5,
            leading=15.2,
            textColor=INK,
            spaceAfter=3 * mm,
            wordWrap="CJK",
        ),
        "section": ParagraphStyle(
            "Section",
            parent=sample["Heading2"],
            fontName="BookSansBold",
            fontSize=15,
            leading=21,
            textColor=BLACK,
            spaceBefore=5 * mm,
            spaceAfter=1.6 * mm,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "subsection": ParagraphStyle(
            "Subsection",
            parent=sample["Heading3"],
            fontName="BookSansBold",
            fontSize=11.5,
            leading=17,
            textColor=BLACK,
            spaceBefore=4 * mm,
            spaceAfter=2 * mm,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "body-en": ParagraphStyle(
            "BodyEnglish",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=9.7,
            leading=14.6,
            textColor=INK,
            spaceAfter=1.2 * mm,
            wordWrap="CJK",
            allowWidows=0,
            allowOrphans=0,
        ),
        "body-zh": ParagraphStyle(
            "BodyChinese",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=9.7,
            leading=15.3,
            textColor=INK,
            spaceAfter=4 * mm,
            wordWrap="CJK",
            allowWidows=0,
            allowOrphans=0,
        ),
        "list-en": ParagraphStyle(
            "ListEnglish",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=9.5,
            leading=14.4,
            textColor=INK,
            spaceAfter=1 * mm,
            wordWrap="CJK",
        ),
        "list-zh": ParagraphStyle(
            "ListChinese",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=9.5,
            leading=15,
            textColor=INK,
            wordWrap="CJK",
        ),
        "list-marker": ParagraphStyle(
            "ListMarker",
            parent=sample["BodyText"],
            fontName="BookSansBold",
            fontSize=9.5,
            leading=14,
            textColor=BLACK,
            alignment=TA_LEFT,
        ),
        "code": ParagraphStyle(
            "Code",
            parent=sample["Code"],
            fontName="BookMono",
            fontSize=7.5,
            leading=10.7,
            leftIndent=3.5 * mm,
            rightIndent=3.5 * mm,
            borderPadding=(2.8 * mm, 3 * mm, 2.8 * mm, 3 * mm),
            borderColor=LINE,
            borderWidth=0.5,
            borderRadius=2,
            backColor=colors.HexColor("#F7F7F8"),
            textColor=INK,
            # The background extends 2.8 mm beyond the text on both sides, so
            # stacked code blocks need that padding twice plus a visible gap,
            # or the second box paints over the last line of the first.
            spaceBefore=4.3 * mm,
            spaceAfter=7.1 * mm,
            wordWrap="CJK",
        ),
        "source": ParagraphStyle(
            "Source",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=8,
            leading=12,
            textColor=MUTED,
            spaceAfter=5 * mm,
            wordWrap="CJK",
        ),
        "reference-kicker": ParagraphStyle(
            "ReferenceKicker",
            parent=sample["BodyText"],
            fontName="BookSansBold",
            fontSize=7.6,
            leading=11,
            textColor=MUTED,
            spaceBefore=8 * mm,
            spaceAfter=1.5 * mm,
            keepWithNext=True,
        ),
        "reference-title": ParagraphStyle(
            "ReferenceTitle",
            parent=sample["Heading2"],
            fontName="BookSansBold",
            fontSize=17,
            leading=23,
            textColor=BLACK,
            spaceAfter=1.8 * mm,
            keepWithNext=True,
            wordWrap="CJK",
        ),
        "table-head": ParagraphStyle(
            "TableHead",
            parent=sample["BodyText"],
            fontName="BookSansBold",
            fontSize=8.2,
            leading=12,
            textColor=BLACK,
            wordWrap="CJK",
        ),
        "table-body": ParagraphStyle(
            "TableBody",
            parent=sample["BodyText"],
            fontName="BookSans",
            fontSize=8.1,
            leading=12,
            textColor=INK,
            wordWrap="CJK",
        ),
    }


def normalize_text(text: str) -> str:
    return (
        text.replace("\u2011", "-")
        .replace("\u2013", "-")
        .replace("\u2014", "-")
        .replace("\u00a0", " ")
    )


def plain_text(text: str) -> str:
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    return normalize_text(re.sub(r"[`*_]", "", text))


_link_base_url = ""


def set_link_base_url(url: str) -> None:
    """Set the current document's pinned source URL for relative links."""
    global _link_base_url
    _link_base_url = url


def resolve_link(target: str) -> str | None:
    """Resolve a Markdown target to a PDF-safe absolute URL when possible.

    Relative links resolve against the pinned source URL. In-page anchors have
    no target in the generated PDF and degrade to emphasized, non-clickable
    text.
    """
    if target.startswith(("http://", "https://", "mailto:")):
        return target
    if target.startswith("#") or not _link_base_url:
        return None
    return urljoin(_link_base_url, target)


def inline_markup(text: str) -> str:
    text = normalize_text(text)
    tokens: list[str] = []

    def token(value: str) -> str:
        index = len(tokens)
        tokens.append(value)
        return f"@@INLINE{index}@@"

    def code_repl(match: re.Match[str]) -> str:
        value = html.escape(match.group(1), quote=False)
        return token(
            f'<span fontName="BookMono" color="#24272B" '
            f'backColor="#F1F3F4">{value}</span>'
        )

    def link_repl(match: re.Match[str]) -> str:
        label = html.escape(match.group(1), quote=False)
        target = resolve_link(match.group(2))
        if target is None:
            return token(f"<u>{label}</u>")
        url = html.escape(target, quote=True)
        return token(f'<a href="{url}" color="#24272B"><u>{label}</u></a>')

    text = re.sub(r"`([^`\n]+)`", code_repl, text)
    text = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", link_repl, text)
    text = html.escape(text, quote=False)
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"(?<!\*)\*([^*\n]+?)\*(?!\*)", r"<i>\1</i>", text)
    # Underscore emphasis follows CommonMark flanking: it never opens or
    # closes inside a word, so snake_case identifiers stay literal.
    text = re.sub(r"(?<!\w)_(?=\S)([^_\n]+?)(?<=\S)_(?!\w)", r"<i>\1</i>", text)
    for index in range(len(tokens) - 1, -1, -1):
        text = text.replace(f"@@INLINE{index}@@", tokens[index])
    return text


def parse_frontmatter(markdown: str) -> tuple[dict[str, str], str]:
    lines = markdown.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, markdown
    try:
        end = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        raise ValueError("YAML front matter is not closed")

    metadata: dict[str, str] = {}
    current_key: str | None = None
    folded: list[str] = []

    def flush() -> None:
        nonlocal current_key, folded
        if current_key is not None:
            metadata[current_key] = " ".join(part for part in folded if part).strip()
        current_key = None
        folded = []

    for raw in lines[1:end]:
        field = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", raw)
        if field:
            flush()
            key, value = field.groups()
            if value in {">", "|"}:
                current_key = key
            else:
                metadata[key] = value.strip().strip("\"'")
        elif current_key is not None:
            folded.append(raw.strip())
    flush()
    return metadata, "\n".join(lines[end + 1 :]).lstrip()


def split_table_row(line: str) -> tuple[str, ...]:
    return tuple(cell.strip() for cell in line.strip().strip("|").split("|"))


def is_table_separator(row: tuple[str, ...]) -> bool:
    return bool(row) and all(re.fullmatch(r":?-{3,}:?", cell) for cell in row)


FENCE = re.compile(r"^\s*(`{3,}|~{3,})(.*)$")


def opening_fence(line: str) -> tuple[str, str] | None:
    """Return (fence, info string) when the line opens a fenced code block."""
    match = FENCE.match(line)
    if not match:
        return None
    fence, info = match.group(1), match.group(2).strip()
    if fence[0] == "`" and "`" in info:
        return None
    return fence, info


def closes_fence(line: str, fence: str) -> bool:
    """Apply CommonMark closing rules for a fence opened with `fence`.

    A closing fence uses the same character, is at least as long as the
    opening fence, and carries no info string. A nested ```ts line therefore
    stays inside a ```markdown block, and ```` blocks can contain ``` blocks.
    """
    match = FENCE.match(line)
    return bool(
        match
        and match.group(1)[0] == fence[0]
        and len(match.group(1)) >= len(fence)
        and not match.group(2).strip()
    )


def is_block_start(line: str) -> bool:
    stripped = line.strip()
    return bool(
        not stripped
        or stripped.startswith("#")
        or opening_fence(line)
        or stripped in {"---", "***", "___"}
        or stripped.startswith("|")
        or re.match(r"^\s*[-*+]\s+", line)
        or re.match(r"^\s*\d+[.)]\s+", line)
    )


def parse_blocks(markdown: str) -> list[Block]:
    _, body = parse_frontmatter(markdown)
    lines = body.splitlines()
    # Report file line numbers, counting the front matter removed above.
    line_offset = len(markdown.splitlines()) - len(lines)
    blocks: list[Block] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()
        if not stripped:
            index += 1
            continue

        fence = opening_fence(line)
        if fence:
            opened_at = index + 1 + line_offset
            language = fence[1].split()[0] if fence[1] else ""
            index += 1
            code_lines: list[str] = []
            while index < len(lines) and not closes_fence(lines[index], fence[0]):
                code_lines.append(lines[index])
                index += 1
            if index >= len(lines):
                raise ValueError(
                    f"fenced code block opened at line {opened_at} with "
                    f"{fence[0]} is not closed. If the upstream source is "
                    "malformed, register a corrected copy as source_override "
                    "with an override_reason in book.json."
                )
            blocks.append(
                Block(kind="code", text="\n".join(code_lines), language=language)
            )
            index += 1
            continue

        heading = re.match(r"^(#{1,6})\s+(.+?)\s*$", stripped)
        if heading:
            blocks.append(
                Block(
                    kind="heading",
                    text=heading.group(2),
                    level=len(heading.group(1)),
                )
            )
            index += 1
            continue

        if stripped.startswith("|"):
            table_rows: list[tuple[str, ...]] = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                row = split_table_row(lines[index])
                if not is_table_separator(row):
                    table_rows.append(row)
                index += 1
            blocks.append(Block(kind="table", rows=tuple(table_rows)))
            continue

        bullet = re.match(r"^(\s*)[-*+]\s+(.+)$", line)
        numbered = re.match(r"^(\s*)(\d+)[.)]\s+(.+)$", line)
        if bullet or numbered:
            match = bullet or numbered
            marker = "•" if bullet else f"{match.group(2)}."
            content = match.group(2) if bullet else match.group(3)
            index += 1
            continuation: list[str] = [content.strip()]
            while index < len(lines) and not is_block_start(lines[index]):
                continuation.append(lines[index].strip())
                index += 1
            blocks.append(
                Block(kind="list", text=" ".join(continuation), marker=marker)
            )
            continue

        if stripped in {"---", "***", "___"}:
            blocks.append(Block(kind="rule"))
            index += 1
            continue

        paragraph = [stripped]
        index += 1
        while index < len(lines) and not is_block_start(lines[index]):
            paragraph.append(lines[index].strip())
            index += 1
        blocks.append(Block(kind="paragraph", text=" ".join(paragraph)))

    return blocks


def validate_pair(label: str, english: list[Block], chinese: list[Block]) -> None:
    if len(english) != len(chinese):
        raise ValueError(
            f"{label}: source and translation block counts differ "
            f"({len(english)} != {len(chinese)})"
        )
    for index, (source, translation) in enumerate(zip(english, chinese), start=1):
        if source.kind != translation.kind:
            raise ValueError(
                f"{label}: block {index} types differ: "
                f"({source.kind} != {translation.kind})"
            )
        if source.kind == "heading" and source.level != translation.level:
            raise ValueError(f"{label}: heading levels differ at block {index}")
        if source.kind == "list":
            source_type = source.marker == "•"
            translation_type = translation.marker == "•"
            if source_type != translation_type:
                raise ValueError(f"{label}: list types differ at block {index}")
        if source.kind == "table":
            source_shape = tuple(len(row) for row in source.rows)
            translation_shape = tuple(len(row) for row in translation.rows)
            if source_shape != translation_shape:
                raise ValueError(
                    f"{label}: table shapes differ at block {index}: "
                    f"{source_shape} != {translation_shape}"
                )
        if source.kind == "code" and source.language != translation.language:
            raise ValueError(
                f"{label}: code fence languages differ at block {index}"
            )


def read_markdown(path: Path) -> tuple[dict[str, str], list[Block]]:
    """Parse one Markdown file, naming the file in any parse error."""
    text = path.read_text(encoding="utf-8")
    try:
        metadata, _ = parse_frontmatter(text)
        return metadata, parse_blocks(text)
    except ValueError as error:
        raise ValueError(f"{path}: {error}") from None


def content_path(project_dir: Path, entry: dict) -> Path:
    """Return the file whose content is rendered for a skill or reference.

    This is the pinned upstream `source` unless a validated `source_override`
    replaces it. `source` still identifies the file for reference discovery,
    names and source links.
    """
    override = entry.get("source_override")
    return project_path(project_dir, override or entry["source"])


def validate_override(project_dir: Path, entry: dict, label: str) -> str | None:
    """Check a source override and describe it, or return None when absent.

    An override exists only to repair malformed upstream code fences. It must
    give a reason and differ from the pinned source in fence lines alone, so
    no upstream wording can be changed through it.
    """
    override = entry.get("source_override")
    if not override:
        if entry.get("override_reason"):
            raise ValueError(f"{label}: override_reason requires source_override")
        return None
    reason = str(entry.get("override_reason", "")).strip()
    if not reason:
        raise ValueError(f"{label}: source_override requires an override_reason")
    source_path = project_path(project_dir, entry["source"])
    override_path = project_path(project_dir, override)
    if not override_path.exists():
        raise FileNotFoundError(f"{label}: source_override {override} is missing")
    source_lines = source_path.read_text(encoding="utf-8").splitlines()
    override_lines = override_path.read_text(encoding="utf-8").splitlines()
    if len(source_lines) != len(override_lines):
        raise ValueError(
            f"{label}: source_override must keep the source's line count "
            f"({len(override_lines)} != {len(source_lines)})"
        )
    changed = [
        number
        for number, (original, patched) in enumerate(
            zip(source_lines, override_lines), start=1
        )
        if original != patched
    ]
    for number in changed:
        original, patched = source_lines[number - 1], override_lines[number - 1]
        if not (FENCE.match(original) and FENCE.match(patched)):
            raise ValueError(
                f"{label}: source_override may change only code fence lines; "
                f"line {number} differs"
            )
    lines = ", ".join(str(number) for number in changed) or "none"
    return (
        f"{label}: source override {override} replaces {entry['source']} "
        f"(fence lines changed: {lines}); reason: {reason}"
    )


def load_pair(
    english_path: Path, chinese_path: Path | None
) -> tuple[dict[str, str], dict[str, str], list[Block], list[Block] | None]:
    """Load source and its optional translation.

    A null translation path selects monolingual mode. Returned translation
    blocks are null so rendering emits one stream and skips structural pairing.
    """
    english_meta, english_blocks = read_markdown(english_path)
    if chinese_path is None:
        return english_meta, {}, english_blocks, None
    chinese_meta, chinese_blocks = read_markdown(chinese_path)
    validate_pair(english_path.stem, english_blocks, chinese_blocks)
    return english_meta, chinese_meta, english_blocks, chinese_blocks


def wrap_code(text: str, max_width: float = 151 * mm) -> str:
    lines: list[str] = []
    for raw in normalize_text(text).splitlines():
        if not raw:
            lines.append("")
            continue
        indent = re.match(r"^\s*", raw).group(0)
        continuation = indent + "  "
        current = ""
        for character in raw:
            candidate = current + character
            if (
                current
                and pdfmetrics.stringWidth(candidate, "BookMono", 7.5) > max_width
            ):
                lines.append(current.rstrip())
                current = continuation + character
            else:
                current = candidate
        lines.append(current.rstrip())
    return "\n".join(lines)


def code_flowable(text: str, styles: dict[str, ParagraphStyle]) -> Flowable:
    return XPreformatted(
        html.escape(wrap_code(text), quote=False),
        styles["code"],
    )


def table_flowable(
    rows: tuple[tuple[str, ...], ...], styles: dict[str, ParagraphStyle]
) -> Table:
    if not rows:
        raise ValueError("Table must not be empty")
    column_count = len(rows[0])
    if column_count == 2:
        widths = [47 * mm, CONTENT_WIDTH - 47 * mm]
    else:
        widths = [CONTENT_WIDTH / column_count] * column_count
    data: list[list[Paragraph]] = []
    for row_index, row in enumerate(rows):
        style = styles["table-head"] if row_index == 0 else styles["table-body"]
        data.append([Paragraph(inline_markup(cell), style) for cell in row])
    table = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), PALE),
                ("GRID", (0, 0), (-1, -1), 0.45, LINE),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 2.5 * mm),
                ("RIGHTPADDING", (0, 0), (-1, -1), 2.5 * mm),
                ("TOPPADDING", (0, 0), (-1, -1), 2 * mm),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2 * mm),
            ]
        )
    )
    return table


def list_pair_flowable(
    english: Block, chinese: Block | None, styles: dict[str, ParagraphStyle]
) -> Table:
    marker = english.marker
    if chinese is None:
        content = [Paragraph(inline_markup(english.text), styles["list-zh"])]
    else:
        content = [
            Paragraph(inline_markup(english.text), styles["list-en"]),
            Paragraph(inline_markup(chinese.text), styles["list-zh"]),
        ]
    table = Table(
        [[Paragraph(html.escape(marker), styles["list-marker"]), content]],
        colWidths=[8 * mm, CONTENT_WIDTH - 8 * mm],
        hAlign="LEFT",
    )
    table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (0, -1), 1.5 * mm),
                ("RIGHTPADDING", (1, 0), (1, -1), 0),
                ("TOPPADDING", (0, 0), (-1, -1), 0),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3 * mm),
            ]
        )
    )
    return table


def pair_flowables(
    english: list[Block],
    chinese: list[Block] | None,
    styles: dict[str, ParagraphStyle],
) -> list[Flowable]:
    """Render the body, using one content stream in monolingual mode.

    The monolingual stream uses the roomier translation style, which remains
    readable for either Latin or CJK source text.
    """
    flowables: list[Flowable] = []
    pending_heading: list[Flowable] | None = None

    def render_content(source: Block, translation: Block | None) -> list[Flowable]:
        if source.kind == "paragraph":
            if translation is None:
                return [Paragraph(inline_markup(source.text), styles["body-zh"])]
            return [
                Paragraph(inline_markup(source.text), styles["body-en"]),
                Paragraph(inline_markup(translation.text), styles["body-zh"]),
            ]
        if source.kind == "list":
            return [list_pair_flowable(source, translation, styles)]
        if source.kind == "code":
            if translation is None:
                return [code_flowable(source.text, styles), Spacer(1, 2 * mm)]
            return [
                code_flowable(source.text, styles),
                code_flowable(translation.text, styles),
                Spacer(1, 2 * mm),
            ]
        if source.kind == "table":
            if translation is None:
                return [table_flowable(source.rows, styles), Spacer(1, 4 * mm)]
            return [
                table_flowable(source.rows, styles),
                Spacer(1, 2 * mm),
                table_flowable(translation.rows, styles),
                Spacer(1, 4 * mm),
            ]
        if source.kind == "rule":
            return [
                HRFlowable(
                    width="100%",
                    thickness=0.55,
                    color=LINE,
                    spaceBefore=2 * mm,
                    spaceAfter=4 * mm,
                )
            ]
        return []

    pairs = zip(english, chinese) if chinese is not None else (
        (block, None) for block in english
    )
    for source, translation in pairs:
        if source.kind == "heading":
            # A heading directly above another heading (an H2 over an H3)
            # stays pending with it, so the whole stack keeps with the first
            # content block instead of being stranded at a page foot.
            pending_heading = pending_heading or []
            style = styles["section"] if source.level <= 2 else styles["subsection"]
            title = inline_markup(source.text)
            toc_text = plain_text(source.text)
            if translation is not None:
                title = f"{title}　{inline_markup(translation.text)}"
                toc_text = f"{toc_text}  {plain_text(translation.text)}"
            heading = Paragraph(title, style)
            pending_heading.append(heading)
            if source.level <= 2:
                heading._toc_level = 1
                heading._toc_text = toc_text
                pending_heading.append(
                    HRFlowable(
                        width="100%",
                        thickness=0.55,
                        color=LINE,
                        spaceBefore=0,
                        spaceAfter=4 * mm,
                    )
                )
            continue

        content = render_content(source, translation)
        if pending_heading:
            minimum_space = {
                "paragraph": 42 * mm,
                "list": 42 * mm,
                "code": 80 * mm,
                "table": 150 * mm,
            }.get(source.kind, 35 * mm)
            # Each extra stacked heading needs room on the same page too.
            minimum_space += 12 * mm * (
                sum(isinstance(item, Paragraph) for item in pending_heading) - 1
            )
            flowables.append(CondPageBreak(minimum_space))
            flowables.append(KeepTogether([*pending_heading, *content]))
            pending_heading = None
        elif source.kind in {"paragraph", "list", "code", "table"}:
            flowables.append(KeepTogether(content))
        else:
            flowables.extend(content)

    if pending_heading:
        flowables.extend(pending_heading)
    return flowables


class SheetParityBreak(PageBreak):
    """Finish the current duplex sheet.

    Odd pages are sheet fronts. When a section ends on a front, append one
    blank back so the next chapter starts on a front. The inserted back uses
    the headerless Notes template.
    """


class BookDocTemplate(BaseDocTemplate):
    def __init__(
        self,
        filename: str,
        *,
        header_label: str,
        logo_path: Path | None,
        **kwargs,
    ):
        super().__init__(filename, **kwargs)
        self.header_label = header_label
        self.logo_path = logo_path
        self.current_chapter = "Reading Guide 阅读导引"
        self._bookmark_counter = 0
        self.section_starts: dict[str, int] = {}

    def beforeDocument(self) -> None:
        super().beforeDocument()
        self.current_chapter = "Reading Guide 阅读导引"
        self._bookmark_counter = 0
        self.section_starts = {}

    def handle_flowable(self, flowables: list[Flowable]) -> None:
        # During layout, self.page is the page currently being filled, so it is
        # sufficient to determine the duplex side before final build.
        if flowables and isinstance(flowables[0], SheetParityBreak):
            flowables.pop(0)
            if self.page % 2 == 1:
                self.handle_pageBreak()
            return
        super().handle_flowable(flowables)

    def afterFlowable(self, flowable: Flowable) -> None:
        chapter = getattr(flowable, "_chapter_title", None)
        if chapter:
            self.current_chapter = chapter
        section = getattr(flowable, "_section_key", None)
        if section:
            self.section_starts.setdefault(section, self.page)
        level = getattr(flowable, "_toc_level", None)
        if level is None:
            return
        text = getattr(flowable, "_toc_text", "")
        if not text:
            return
        self._bookmark_counter += 1
        key = f"section-{self._bookmark_counter}"
        self.canv.bookmarkPage(key)
        self.canv.addOutlineEntry(text, key, level=level, closed=(level == 0))
        self.notify("TOCEntry", (level, text, self.page, key))


def cover_background(canvas: Canvas, doc: BaseDocTemplate) -> None:
    canvas.saveState()
    canvas.setFillColor(BLACK)
    canvas.rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, fill=1, stroke=0)
    logo = getattr(doc, "logo_path", None)
    if logo and logo.exists():
        canvas.drawImage(
            str(logo),
            113 * mm,
            139 * mm,
            width=72 * mm,
            height=82 * mm,
            preserveAspectRatio=True,
            anchor="c",
            mask="auto",
        )
    canvas.setStrokeColor(colors.HexColor("#4A4E53"))
    canvas.setLineWidth(0.7)
    canvas.line(20 * mm, 22 * mm, PAGE_WIDTH - 20 * mm, 22 * mm)
    canvas.restoreState()


def content_header_footer(canvas: Canvas, doc: BookDocTemplate) -> None:
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.setLineWidth(0.45)
    canvas.line(20 * mm, PAGE_HEIGHT - 14 * mm, PAGE_WIDTH - 20 * mm, PAGE_HEIGHT - 14 * mm)
    canvas.setFont("BookSans", 7.2)
    canvas.setFillColor(MUTED)
    canvas.drawString(20 * mm, PAGE_HEIGHT - 10.5 * mm, doc.header_label)
    chapter = doc.current_chapter
    if len(chapter) > 48:
        chapter = chapter[:47] + "…"
    canvas.drawRightString(PAGE_WIDTH - 20 * mm, PAGE_HEIGHT - 10.5 * mm, chapter)
    canvas.line(20 * mm, 14 * mm, PAGE_WIDTH - 20 * mm, 14 * mm)
    canvas.setFont("BookSans", 8)
    canvas.drawCentredString(PAGE_WIDTH / 2, 9.2 * mm, str(doc.page))
    canvas.restoreState()


def make_toc() -> TableOfContents:
    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle(
            "TOC0",
            fontName="BookSansBold",
            fontSize=10.3,
            leading=16,
            textColor=BLACK,
            leftIndent=0,
            firstLineIndent=0,
            spaceBefore=2.5 * mm,
        ),
        ParagraphStyle(
            "TOC1",
            fontName="BookSans",
            fontSize=8.6,
            leading=13,
            textColor=INK,
            leftIndent=8 * mm,
            firstLineIndent=0,
            spaceBefore=1 * mm,
        ),
    ]
    toc.dotsMinLevel = 0
    return toc


def chapter_opener(
    english_title: str,
    chinese_title: str,
    kicker: str,
    english_description: str,
    chinese_description: str,
    styles: dict[str, ParagraphStyle],
    source_url: str | None = None,
    version: str = "",
    commit: str = "",
    section_key: str = "",
) -> list[Flowable]:
    # A monolingual chapter has no second-language title or reserved blank line.
    title_text = inline_markup(english_title)
    toc_text = plain_text(english_title)
    if chinese_title:
        title_text = f"{title_text}<br/>{inline_markup(chinese_title)}"
        toc_text = f"{toc_text}  {plain_text(chinese_title)}"
    title = Paragraph(title_text, styles["chapter-title"])
    title._toc_level = 0
    title._toc_text = toc_text
    title._chapter_title = toc_text.replace("  ", " ")
    title._section_key = section_key
    flowables: list[Flowable] = [
        Paragraph(kicker, styles["chapter-kicker"]),
        title,
    ]
    if english_description:
        flowables.append(
            Paragraph(inline_markup(english_description), styles["chapter-en"])
        )
    if chinese_description:
        flowables.append(
            Paragraph(inline_markup(chinese_description), styles["chapter-zh"])
        )
    if source_url:
        source_meta = " · ".join(
            part for part in (f"v{version}" if version else "", commit[:8]) if part
        )
        source_markup = (
            f'<a href="{html.escape(source_url, quote=True)}" color="#24272B">'
            f"<u>Source 原文</u></a>"
            f"{' · ' + source_meta if source_meta else ''}"
        )
        flowables.append(Paragraph(source_markup, styles["source"]))
    flowables.append(
        HRFlowable(
            width="100%",
            thickness=0.7,
            color=BLACK,
            spaceBefore=1 * mm,
            spaceAfter=7 * mm,
        )
    )
    return flowables


def strip_leading_h1(
    english: list[Block], chinese: list[Block] | None
) -> tuple[list[Block], list[Block] | None]:
    if not english or english[0].kind != "heading" or english[0].level != 1:
        return english, chinese
    if chinese is None:
        return english[1:], None
    if chinese and chinese[0].kind == "heading" and chinese[0].level == 1:
        return english[1:], chinese[1:]
    return english, chinese


def discover_reference_files(source_path: Path) -> list[Path] | None:
    """List sibling Markdown references when source is SKILL.md.

    The standard `skills/*/SKILL.md` layout proves ownership of sibling
    Markdown. Other source names cannot establish ownership, so return null and
    require the caller to confirm reference completeness.
    """
    if source_path.name.lower() != "skill.md":
        return None
    skill_dir = source_path.parent
    resolved_source = source_path.resolve()
    return sorted(
        path.resolve()
        for path in skill_dir.rglob("*.md")
        if path.resolve() != resolved_source
    )


def reference_entries(skill: dict) -> list[dict]:
    references = skill.get("references", [])
    if not isinstance(references, list):
        raise ValueError(f"{skill['name']}: references must be an array")
    return references


def load_reference(
    project_dir: Path,
    skill: dict,
    reference: dict,
    commit: str,
    monolingual: bool = False,
) -> tuple[str, str, list[Block], list[Block] | None]:
    required = ("source", "source_url") if monolingual else (
        "source",
        "translation",
        "source_url",
    )
    for key in required:
        if not reference.get(key):
            raise ValueError(
                f"{skill['name']} reference is missing required field: {key}"
            )
    source_path = project_path(project_dir, reference["source"])
    translation_path = (
        None if monolingual else project_path(project_dir, reference["translation"])
    )
    if not source_path.exists() or (
        translation_path is not None and not translation_path.exists()
    ):
        raise FileNotFoundError(
            f"{skill['name']} reference {reference['source']} is missing "
            "source or translation"
        )
    if f"/blob/{commit}/" not in reference["source_url"]:
        raise ValueError(
            f"{skill['name']} reference {source_path.name}: source_url must use "
            f"pinned commit {commit} in a /blob/<commit>/ path"
        )
    validate_override(
        project_dir, reference, f"{skill['name']} / {source_path.name}"
    )
    _, translation_meta, source_blocks, translation_blocks = load_pair(
        content_path(project_dir, reference), translation_path
    )
    has_h1 = (
        bool(source_blocks)
        and source_blocks[0].kind == "heading"
        and source_blocks[0].level == 1
    )
    title_en = reference.get("title_en") or (
        source_blocks[0].text if has_h1 else source_path.name
    )
    if translation_blocks is None:
        title_zh = ""
    else:
        title_zh = translation_meta.get("zh_title") or (
            translation_blocks[0].text if has_h1 else title_en
        )
    source_blocks, translation_blocks = strip_leading_h1(
        source_blocks, translation_blocks
    )
    return title_en, title_zh, source_blocks, translation_blocks


def reference_opener(
    file_name: str,
    english_title: str,
    chinese_title: str,
    source_url: str,
    styles: dict[str, ParagraphStyle],
) -> list[Flowable]:
    title_text = inline_markup(english_title)
    toc_text = plain_text(english_title)
    if chinese_title and chinese_title != english_title:
        title_text = f"{title_text}　{inline_markup(chinese_title)}"
        toc_text = f"{toc_text}  {plain_text(chinese_title)}"
    title = Paragraph(title_text, styles["reference-title"])
    title._toc_level = 1
    title._toc_text = f"{toc_text} ({file_name})"
    return [
        HRFlowable(
            width="100%",
            thickness=0.7,
            color=BLACK,
            spaceBefore=7 * mm,
            spaceAfter=0,
        ),
        Paragraph(
            f"REFERENCE 参考文档 · {html.escape(file_name)}",
            styles["reference-kicker"],
        ),
        title,
        Paragraph(
            f'<a href="{html.escape(source_url, quote=True)}" color="#24272B">'
            f"<u>Source 原文</u></a>",
            styles["source"],
        ),
    ]


def validate_inputs(project_dir: Path, config: dict) -> list[str]:
    results: list[str] = []
    monolingual = bool(config.get("monolingual"))
    verb = "read" if monolingual else "paired"
    skill_required = ("name", "title_en", "source", "source_url") if monolingual else (
        "name",
        "title_en",
        "source",
        "translation",
        "source_url",
    )
    for skill in config["skills"]:
        for key in skill_required:
            if not skill.get(key):
                raise ValueError(
                    f"Skill configuration is missing required field: {key}"
                )
        if monolingual and skill.get("translation"):
            raise ValueError(
                f"{skill['name']}: a monolingual project must not configure "
                "translation. Remove root monolingual and use bilingual mode "
                "for paired content."
            )
        source_path = project_path(project_dir, skill["source"])
        translation_path = (
            None if monolingual else project_path(project_dir, skill["translation"])
        )
        if not source_path.exists() or (
            translation_path is not None and not translation_path.exists()
        ):
            raise FileNotFoundError(
                f"{skill['name']} is missing a source or translation file"
            )
        if f"/blob/{config['commit']}/" not in skill["source_url"]:
            raise ValueError(
                f"{skill['name']}: source_url must use pinned commit "
                f"{config['commit']} in a /blob/<commit>/ path"
            )
        override_note = validate_override(project_dir, skill, skill["name"])
        _, _, source_blocks, translation_blocks = load_pair(
            content_path(project_dir, skill), translation_path
        )
        results.append(
            f"{skill['name']}: {verb} {len(source_blocks)} content blocks"
        )
        if override_note:
            results.append(override_note)

        references = reference_entries(skill)
        registered = {
            project_path(project_dir, reference["source"])
            for reference in references
            if reference.get("source")
        }
        skill_dir = source_path.parent
        skipped = {
            (skill_dir / name).resolve() for name in skill.get("skip_references", [])
        }
        discovered = discover_reference_files(source_path)
        if discovered is None:
            results.append(
                f"{skill['name']}: source is not SKILL.md; automatic reference "
                "discovery skipped. Confirm references manually."
            )
        else:
            unregistered = [
                path
                for path in discovered
                if path not in registered and path not in skipped
            ]
            if unregistered:
                listing = ", ".join(
                    str(path.relative_to(skill_dir)) for path in unregistered
                )
                raise ValueError(
                    f"{skill['name']}: unregistered skill reference files: "
                    f"{listing}. Add every Markdown file to book.json references, "
                    "including translations in bilingual mode, or explicitly "
                    "list non-body files in skip_references."
                )
        for reference in references:
            _, _, reference_blocks, _ = load_reference(
                project_dir, skill, reference, config["commit"], monolingual
            )
            reference_name = project_path(project_dir, reference["source"]).name
            label = f"{skill['name']} / {reference_name}"
            results.append(f"{label}: {verb} {len(reference_blocks)} content blocks")
            override_note = validate_override(project_dir, reference, label)
            if override_note:
                results.append(override_note)
        for name in skill.get("skip_references", []):
            results.append(f"{skill['name']}: explicitly skipped reference {name}")
    for label in ("front", "back"):
        section = config[label]
        if not section.get("en"):
            raise ValueError(
                f"book.json {label} must contain "
                f"{'file' if monolingual else 'en and zh'}"
            )
        if not monolingual and not section.get("zh"):
            raise ValueError(f"book.json {label} must contain en and zh")
        _, _, source_blocks, translation_blocks = load_pair(
            project_path(project_dir, section["en"]),
            None if monolingual else project_path(project_dir, section["zh"]),
        )
        if not source_blocks or source_blocks[0].kind != "heading":
            raise ValueError(f"{label} source file must begin with H1")
        if translation_blocks is not None and (
            not translation_blocks or translation_blocks[0].kind != "heading"
        ):
            raise ValueError(f"{label} translation file must begin with H1")
        results.append(f"{label}: {verb} {len(source_blocks)} content blocks")
    return results


def make_doc(
    project_dir: Path, output: Path, config: dict, subject: str, with_cover: bool
) -> BookDocTemplate:
    monolingual = bool(config.get("monolingual"))
    title_en = config["title_en"]
    original_author = config.get("original_author", "Original authors")
    translator = str(config.get("translator", "")).strip()
    if translator:
        role = "编排" if monolingual else "中文翻译与编排"
        author = f"{original_author}（原文）· {translator}（{role}）"
    else:
        author = f"{original_author}（原文）"
    logo_path = (
        project_path(project_dir, config["logo"]) if config.get("logo") else None
    )

    doc = BookDocTemplate(
        str(output),
        header_label=config.get(
            "header_label",
            f"{title_en.upper()} · "
            + ("LEARNING EDITION" if monolingual else "BILINGUAL LEARNING EDITION"),
        ),
        logo_path=logo_path,
        pagesize=A4,
        leftMargin=20 * mm,
        rightMargin=20 * mm,
        topMargin=21 * mm,
        bottomMargin=20 * mm,
        title=f"{title_en} {config['title_zh']}".strip(),
        author=author,
        subject=subject,
        creator="smart:github-skills-pdf",
    )

    cover_frame = Frame(
        20 * mm,
        20 * mm,
        CONTENT_WIDTH,
        PAGE_HEIGHT - 40 * mm,
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
        id="cover-frame",
    )
    content_frame = Frame(
        20 * mm,
        19 * mm,
        CONTENT_WIDTH,
        PAGE_HEIGHT - 40 * mm,
        leftPadding=0,
        rightPadding=0,
        topPadding=0,
        bottomPadding=0,
        id="content-frame",
    )
    # The first template lays out page one: the cover for a full edition, a
    # content page for an update pack.
    templates = [
        PageTemplate(
            id="Content",
            frames=[content_frame],
            onPageEnd=content_header_footer,
        ),
        PageTemplate(id="Notes", frames=[content_frame]),
    ]
    if with_cover:
        templates.insert(
            0, PageTemplate(id="Cover", frames=[cover_frame], onPage=cover_background)
        )
    doc.addPageTemplates(templates)
    return doc


def skill_chapter(
    project_dir: Path,
    config: dict,
    skill: dict,
    chapter_number: int,
    styles: dict[str, ParagraphStyle],
) -> list[Flowable]:
    """Lay out one skill chapter and its references."""
    monolingual = bool(config.get("monolingual"))
    version = str(config["version"])
    commit = str(config["commit"])
    english_title = skill["title_en"]
    set_link_base_url(skill["source_url"])
    translation_path = (
        None if monolingual else project_path(project_dir, skill["translation"])
    )
    source_meta, translation_meta, source_blocks, translation_blocks = load_pair(
        content_path(project_dir, skill), translation_path
    )
    source_blocks, translation_blocks = strip_leading_h1(
        source_blocks, translation_blocks
    )
    chinese_title = (
        "" if monolingual else translation_meta.get("zh_title", english_title)
    )
    story = chapter_opener(
        english_title,
        chinese_title,
        f"CHAPTER {chapter_number:02d} · SKILL",
        source_meta.get("description", ""),
        translation_meta.get("description", ""),
        styles,
        skill["source_url"],
        version,
        commit,
        skill["name"],
    )
    story.extend(pair_flowables(source_blocks, translation_blocks, styles))
    for reference in reference_entries(skill):
        set_link_base_url(reference["source_url"])
        (
            reference_title_en,
            reference_title_zh,
            reference_en,
            reference_zh,
        ) = load_reference(project_dir, skill, reference, commit, monolingual)
        story.append(CondPageBreak(70 * mm))
        story.extend(
            reference_opener(
                project_path(project_dir, reference["source"]).name,
                reference_title_en,
                reference_title_zh,
                reference["source_url"],
                styles,
            )
        )
        story.extend(pair_flowables(reference_en, reference_zh, styles))
    return story


def skill_fingerprint(project_dir: Path, skill: dict) -> str:
    """Hash the upstream text one chapter renders.

    Only pinned source content and the English title count. Commit-bearing
    source links and translations stay out, so moving to a new commit or
    retranslating an unchanged skill never forces a reprint.
    """
    source_dir = project_path(project_dir, skill["source"]).parent
    parts = [skill["title_en"]]
    for entry in [skill, *reference_entries(skill)]:
        source = project_path(project_dir, entry["source"])
        try:
            name = str(source.relative_to(source_dir))
        except ValueError:
            name = source.name
        text = content_path(project_dir, entry).read_text(encoding="utf-8")
        parts.extend([name, text.replace("\r\n", "\n")])
    payload = json.dumps(parts, ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def section_ranges(starts: dict[str, int], last_page: int) -> dict[str, list[int]]:
    """Turn section start pages into inclusive page ranges.

    A section runs until the next one starts, so a blank back belongs to the
    chapter it follows.
    """
    ordered = sorted(starts.items(), key=lambda item: item[1])
    ranges: dict[str, list[int]] = {}
    for index, (key, start) in enumerate(ordered):
        end = ordered[index + 1][1] - 1 if index + 1 < len(ordered) else last_page
        ranges[key] = [start, end]
    return ranges


def edition_record(kind: str, output: Path, config: dict) -> dict:
    return {
        "kind": kind,
        "pdf": output.name,
        "version": str(config["version"]),
        "commit": str(config["commit"]),
        "build_date": str(config["build_date"]),
    }


def printed_record(
    config: dict,
    skill: dict,
    chapter: int,
    fingerprint: str,
    output: Path,
    pages: list[int],
) -> dict:
    return {
        "chapter": chapter,
        "title": skill["title_en"],
        "fingerprint": fingerprint,
        "version": str(config["version"]),
        "commit": str(config["commit"]),
        "pdf": output.name,
        "pages": pages,
    }


def read_ledger(project_dir: Path) -> dict:
    path = project_dir / LEDGER_FILE
    if not path.exists():
        raise FileNotFoundError(
            f"Missing {LEDGER_FILE}: no printed edition is recorded. Build the "
            "full edition first; for an edition printed before ledgers existed, "
            "rebuild it once at its printed commit to record it."
        )
    return json.loads(path.read_text(encoding="utf-8"))


def write_ledger(project_dir: Path, ledger: dict) -> None:
    path = project_dir / LEDGER_FILE
    path.write_text(
        json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Recorded print ledger: {path}")


def plan_update(
    project_dir: Path, config: dict, ledger: dict
) -> tuple[list[tuple[str, dict, int, str]], list[str]]:
    """Compare the project with the printed edition.

    Returns changed chapters as (kind, skill, chapter, fingerprint) in book
    order and withdrawn skill names in chapter order. Printed chapters keep
    their numbers; new skills continue after the highest printed chapter.
    """
    printed = ledger.get("skills", {})
    next_chapter = max((entry["chapter"] for entry in printed.values()), default=0) + 1
    changes: list[tuple[str, dict, int, str]] = []
    for skill in config["skills"]:
        fingerprint = skill_fingerprint(project_dir, skill)
        previous = printed.get(skill["name"])
        if previous is None:
            changes.append(("new", skill, next_chapter, fingerprint))
            next_chapter += 1
        elif previous["fingerprint"] != fingerprint:
            changes.append(("updated", skill, previous["chapter"], fingerprint))
    current = {skill["name"] for skill in config["skills"]}
    withdrawn = sorted(
        (name for name in printed if name not in current),
        key=lambda name: printed[name]["chapter"],
    )
    return changes, withdrawn


def printed_pages(entry: dict) -> str:
    first, last = entry["pages"]
    return f"{entry['pdf']} p.{first}-{last}"


def describe_plan(
    changes: list[tuple[str, dict, int, str]], withdrawn: list[str], ledger: dict
) -> list[str]:
    printed = ledger.get("skills", {})
    lines = []
    for kind, skill, chapter, _ in changes:
        line = f"update: {kind} chapter {chapter:02d} {skill['name']}"
        if kind == "updated":
            line += f" (replaces {printed_pages(printed[skill['name']])})"
        lines.append(line)
    for name in withdrawn:
        entry = printed[name]
        lines.append(
            f"update: withdrawn chapter {entry['chapter']:02d} {name} "
            f"(remove {printed_pages(entry)})"
        )
    if not lines:
        lines.append(
            "update: no chapter changes since the printed edition; nothing to print"
        )
    return lines


def update_sheet(
    config: dict,
    ledger: dict,
    changes: list[tuple[str, dict, int, str]],
    withdrawn: list[str],
    styles: dict[str, ParagraphStyle],
) -> list[Flowable]:
    """Lay out the first page of an update pack: what to replace and where."""
    previous = ledger["editions"][-1]
    printed = ledger.get("skills", {})
    version = str(config["version"])
    title = Paragraph(
        f"{inline_markup(config['title_en'])} "
        f"v{inline_markup(previous['version'])} → v{inline_markup(version)}",
        styles["chapter-title"],
    )
    title._toc_level = 0
    title._toc_text = "Update 更新说明"
    title._chapter_title = "Update 更新说明"
    title._section_key = "__update__"
    actions = {
        "updated": "Updated 更新 · replace",
        "new": "New 新增 · insert",
    }
    rows = [("Chapter 章节", "Skill 技能", "Change 变更", "Printed 原页码")]
    for kind, skill, chapter, _ in changes:
        entry = printed.get(skill["name"])
        rows.append(
            (
                f"{chapter:02d}",
                skill["title_en"],
                actions[kind],
                printed_pages(entry) if entry else "-",
            )
        )
    for name in withdrawn:
        entry = printed[name]
        rows.append(
            (
                f"{entry['chapter']:02d}",
                entry.get("title", name),
                "Withdrawn 撤除 · remove",
                printed_pages(entry),
            )
        )
    story: list[Flowable] = [
        Paragraph("UPDATE · 更新说明", styles["chapter-kicker"]),
        title,
        Paragraph(
            f"Printed edition v{inline_markup(previous['version'])} · "
            f"{previous['commit'][:8]} → this pack v{inline_markup(version)} · "
            f"{config['commit'][:8]}. Only changed and new chapters follow, each "
            "starting on a new sheet; unchanged chapters, the reading guide, the "
            "contents, and the appendix stay as printed.",
            styles["chapter-en"],
        ),
    ]
    if not config.get("monolingual"):
        story.append(
            Paragraph(
                "更新说明：仅收录有变化和新增的章节，每章从新纸开始；"
                "未变章节、阅读导引、目录与附录沿用已印版本。",
                styles["chapter-zh"],
            )
        )
    story.extend(
        [
            HRFlowable(
                width="100%",
                thickness=0.7,
                color=BLACK,
                spaceBefore=1 * mm,
                spaceAfter=7 * mm,
            ),
            table_flowable(tuple(rows), styles),
        ]
    )
    return story


def next_sheet_front() -> list[Flowable]:
    """Start the next section on a sheet front; a blank back fills the gap."""
    return [
        NextPageTemplate("Notes"),
        SheetParityBreak(),
        NextPageTemplate("Content"),
        PageBreak(),
    ]


def build(project_dir: Path, output: Path, config: dict) -> None:
    register_fonts()
    styles = build_styles()
    validate_inputs(project_dir, config)
    output.parent.mkdir(parents=True, exist_ok=True)

    monolingual = bool(config.get("monolingual"))
    title_en = config["title_en"]
    title_zh = config["title_zh"]
    version = str(config["version"])
    commit = str(config["commit"])
    build_date = str(config["build_date"])
    fingerprints = {
        skill["name"]: skill_fingerprint(project_dir, skill)
        for skill in config["skills"]
    }

    doc = make_doc(
        project_dir,
        output,
        config,
        f"{title_en} {version} 的 {len(config['skills'])} 个正式技能"
        + ("学习版" if monolingual else "英中逐块对照学习版"),
        with_cover=True,
    )

    story: list[Flowable] = [
        Spacer(1, 53 * mm),
        Paragraph(inline_markup(config["cover_label"]), styles["cover-label"]),
        Paragraph(
            f"{inline_markup(title_en)}<br/>{inline_markup(title_zh)}"
            if title_zh
            else inline_markup(title_en),
            styles["cover-title"],
        ),
        Paragraph(
            inline_markup(config["cover_subtitle"]).replace("\n", "<br/>"),
            styles["cover-subtitle"],
        ),
        Paragraph(
            f"非官方学习版 · v{inline_markup(version)} · "
            f"固定提交 {inline_markup(commit[:8])}<br/>"
            f"编译日期 {inline_markup(build_date)}",
            styles["cover-meta"],
        ),
        NextPageTemplate("Content"),
        PageBreak(),
        Paragraph("Contents 目录", styles["toc-title"]),
        Paragraph(
            f"目录与 PDF 书签包含阅读导引、{len(config['skills'])} 个技能章节、"
            "主要小节和附录。",
            styles["small"],
        ),
        Spacer(1, 5 * mm),
        make_toc(),
        PageBreak(),
    ]

    front = config["front"]
    set_link_base_url(config.get("repo_url", ""))
    _, _, front_en, front_zh = load_pair(
        project_path(project_dir, front["en"]),
        None if monolingual else project_path(project_dir, front["zh"]),
    )
    front_title_en = front_en[0].text
    front_title_zh = "" if front_zh is None else front_zh[0].text
    front_en, front_zh = strip_leading_h1(front_en, front_zh)
    story.extend(
        chapter_opener(
            front_title_en,
            front_title_zh,
            front.get("kicker", "START HERE · 从这里开始"),
            front.get("description_en", ""),
            front.get("description_zh", ""),
            styles,
        )
    )
    story.extend(pair_flowables(front_en, front_zh, styles))

    # Every chapter and the appendix start on a sheet front, so an update pack
    # can replace a chapter's sheets without touching its neighbours.
    for chapter_number, skill in enumerate(config["skills"], start=1):
        story.extend(next_sheet_front())
        story.extend(skill_chapter(project_dir, config, skill, chapter_number, styles))
    story.extend(next_sheet_front())

    back = config["back"]
    set_link_base_url(config.get("repo_url", ""))
    _, _, back_en, back_zh = load_pair(
        project_path(project_dir, back["en"]),
        None if monolingual else project_path(project_dir, back["zh"]),
    )
    back_title_en = back_en[0].text
    back_title_zh = "" if back_zh is None else back_zh[0].text
    back_en, back_zh = strip_leading_h1(back_en, back_zh)
    story.extend(
        chapter_opener(
            back_title_en,
            back_title_zh,
            back.get("kicker", "REFERENCE · 参考"),
            back.get("description_en", ""),
            back.get("description_zh", ""),
            styles,
            section_key="__back__",
        )
    )
    story.extend(pair_flowables(back_en, back_zh, styles))

    doc.multiBuild(story)
    print(output)

    ranges = section_ranges(doc.section_starts, doc.page)
    write_ledger(
        project_dir,
        {
            "title": title_en,
            "editions": [edition_record("full", output, config)],
            "skills": {
                skill["name"]: printed_record(
                    config,
                    skill,
                    chapter_number,
                    fingerprints[skill["name"]],
                    output,
                    ranges[skill["name"]],
                )
                for chapter_number, skill in enumerate(config["skills"], start=1)
            },
        },
    )


def build_update(project_dir: Path, output: Path, config: dict) -> None:
    """Print only chapters that differ from the printed edition."""
    ledger = read_ledger(project_dir)
    register_fonts()
    styles = build_styles()
    validate_inputs(project_dir, config)
    changes, withdrawn = plan_update(project_dir, config, ledger)
    for line in describe_plan(changes, withdrawn, ledger):
        print(line)
    if not changes and not withdrawn:
        return
    output.parent.mkdir(parents=True, exist_ok=True)

    previous = ledger["editions"][-1]
    doc = make_doc(
        project_dir,
        output,
        config,
        f"{config['title_en']} v{previous['version']} → v{config['version']} 更新",
        with_cover=False,
    )
    story = update_sheet(config, ledger, changes, withdrawn, styles)
    for kind, skill, chapter, _ in changes:
        story.extend(next_sheet_front())
        story.extend(skill_chapter(project_dir, config, skill, chapter, styles))

    doc.multiBuild(story)
    print(output)

    ranges = section_ranges(doc.section_starts, doc.page)
    for kind, skill, chapter, fingerprint in changes:
        ledger["skills"][skill["name"]] = printed_record(
            config, skill, chapter, fingerprint, output, ranges[skill["name"]]
        )
    for name in withdrawn:
        del ledger["skills"][name]
    ledger["editions"].append(edition_record("update", output, config))
    write_ledger(project_dir, ledger)


def main() -> None:
    parser = BookArgumentParser(
        description="Build a screenshot-faithful English-Chinese Skills PDF"
    )
    parser.add_argument("project_dir", help="project directory containing book.json")
    parser.add_argument(
        "--output",
        help="output PDF path; defaults to book.json output or a generated name",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="validate source/translation block pairing without generating a PDF",
    )
    parser.add_argument(
        "--update",
        action="store_true",
        help=f"print only chapters changed since the edition in {LEDGER_FILE}; "
        "with --check, list the planned changes",
    )
    args = parser.parse_args()
    try:
        project_dir = Path(args.project_dir).expanduser().resolve()
        config = load_config(project_dir)
        if args.output:
            output = Path(args.output).expanduser().resolve()
        else:
            output = project_path(
                project_dir,
                config.get(
                    "output", f"{config['title_en']}-bilingual-study-handbook.pdf"
                ),
            )
            if args.update:
                output = output.with_name(
                    f"{output.stem}-update-{config['version']}{output.suffix}"
                )
        if args.check:
            if args.update:
                # Plan from sources first: it names the skills to translate.
                ledger = read_ledger(project_dir)
                changes, withdrawn = plan_update(project_dir, config, ledger)
                for line in describe_plan(changes, withdrawn, ledger):
                    print(line)
            for result in validate_inputs(project_dir, config):
                print(result)
            return
        if args.update:
            build_update(project_dir, output, config)
        else:
            build(project_dir, output, config)
    except Exception as error:
        print(f"Error: {error}", file=sys.stderr)
        raise SystemExit(1) from None


if __name__ == "__main__":
    main()
