# 双语项目格式

## 目录

项目目录由调用工作流创建，建议结构：

```text
book/
├── book.json
├── print-ledger.json   # 由构建器写入
├── FRONT_EN.md
├── FRONT_ZH.md
├── BACK_EN.md
├── BACK_ZH.md
├── translation/
│   ├── <skill>.md
│   └── <skill>-<参考文档>.md
└── source/
    └── <clone 或指向 clone 的路径>
```

参考文档译文建议命名为 `<skill>-<原文件名小写>.md`，便于一眼看出归属。

`book.json` 中的文件路径相对项目目录解析。source 文件也可以位于项目目录外，但配置
中仍应使用稳定、明确的路径。

## book.json

```json
{
  "title_en": "Ponytail",
  "title_zh": "双语学习手册",
  "version": "4.8.4",
  "commit": "16f29800fd2681bdf24f3eb4ccffe38be3baec6b",
  "build_date": "2026-07-30",
  "original_author": "DietrichGebert",
  "output": "ponytail-双语学习手册.pdf",
  "logo": "source/assets/logo-dark.png",
  "cover_label": "THE LAZY SENIOR DEV, IN TWO LANGUAGES",
  "cover_subtitle": "6 个正式技能 · 英文原文在上 · 简体中文翻译在下",
  "header_label": "PONYTAIL · BILINGUAL LEARNING EDITION",
  "front": {
    "en": "FRONT_EN.md",
    "zh": "FRONT_ZH.md",
    "kicker": "START HERE · 从这里开始",
    "description_en": "How to read and verify this edition.",
    "description_zh": "了解本版的阅读方法和版本范围。"
  },
  "back": {
    "en": "BACK_EN.md",
    "zh": "BACK_ZH.md",
    "kicker": "REFERENCE · 参考",
    "description_en": "Source links and license.",
    "description_zh": "源码链接与许可证。"
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

必填字段：

- 根：`title_en`、`title_zh`、`version`、完整 `commit`、非空 `skills`、
  `front`、`back`；
- 每个 skill：`name`、`title_en`、`source`、`translation`、`source_url`；
- `source_url` 必须包含根级完整 commit；
- `front` 与 `back`：`en`、`zh`。

`build_date` 缺省时使用当天日期。`logo` 可省略；没有 logo 时生成纯黑封面。
`repo_url` 可选，用于解析导言和附录中的相对链接。`original_author` 与 `translator`
写入 PDF 作者元数据；`translator` 填实际完成翻译与编排的人或工具，省略时只署原作者。

## 单语项目

源仓库本身就是单一语种时（例如 skills 直接用中文写成），没有原文/译文之分，也就无从
逐块对照。根级写 `"monolingual": true` 进入单语模式：正文只排一路，其余的目录、PDF
书签、页眉页码、固定源码链接与参考文档收录全部照旧。

单语项目改用与语种无关的中性字段名，不必再写 `_en`/`_zh` 后缀：

```json
{
  "monolingual": true,
  "title": "GitHub 协作 Skill 手册",
  "version": "1.0.0",
  "commit": "0123456789abcdef0123456789abcdef01234567",
  "front": { "file": "front.md", "description": "通读一遍再动手。" },
  "back": { "file": "back.md" },
  "skills": [
    {
      "name": "github-issue-triage",
      "title": "GitHub Issue Triage",
      "source": "source/github-issue-triage/SKILL.md",
      "source_url": "https://github.com/example/skills/blob/0123456789abcdef0123456789abcdef01234567/github-issue-triage/SKILL.md",
      "references": [
        {
          "title": "查重规则",
          "source": "source/github-issue-triage/DEDUPE.md",
          "source_url": "https://github.com/example/skills/blob/0123456789abcdef0123456789abcdef01234567/github-issue-triage/DEDUPE.md"
        }
      ]
    }
  ]
}
```

单语与双语的差别只在这几处：

- `title` 代替 `title_en` + `title_zh`；`title_zh` 不再必填；
- `front`/`back` 用 `file` 与 `description` 代替 `en`/`zh` 与 `description_en`/`description_zh`；
- 每个 skill 和每个参考文档用 `title` 代替 `title_en`，并且**不写** `translation`；
- 章标题、小节标题只排一行，正文只排一路。

`translation` 与 `monolingual` 同时出现会直接报错，而不是默默忽略其中一个——两者
并存说明配置意图自相矛盾，静默处理只会让人以为译文已经排进书里。

中性字段名只在单语模式下归一化。双语项目仍须写 `title_en`/`title_zh` 与 `en`/`zh`。

## 参考文档

许多 skill 把格式说明、模板和深入材料拆到 `SKILL.md` 同目录的独立 Markdown，并在
正文中用 `@FILE.md` 或相对链接引用。这些文件和 `SKILL.md` 一样是该 skill 的正文，
在书里作为章内小节接在正文之后。

每项 `references` 必填 `source`、`translation`、`source_url`（同样要求固定 commit）。
`title_en` 可省略，缺省取原文首个 H1；中文标题取译文 front matter 的 `zh_title`，
缺省取译文首个 H1。

构建脚本会扫描每个 `source` 所在目录下的全部 Markdown。凡是既不在 `references`
也不在 `skip_references` 里的文件，`--check` 和构建都会失败并列出文件名。这道反向
校验是有意为之：漏收参考文档不会体现在成品的任何显性错误上，只会让书里的引用悄悄
断链，所以必须在构建期变成硬失败，而不依赖编排时记得。

反向校验只在 `source` 指向 `SKILL.md` 时进行——`skills/*/SKILL.md` 的布局保证一个
目录只承载一个 skill，同目录的其他 Markdown 才必然属于它。`source` 用别的文件名时
无法这样推断，脚本会在 `--check` 输出中提示已跳过自动核对，此时需自行确认收录完整。

`skip_references` 用相对该 skill 目录的路径显式豁免确实不属于正文的文件，例如：

```json
"skip_references": ["CHANGELOG.md"]
```

被豁免的文件会在 `--check` 输出中逐条打印，不会静默跳过。

## 纸张正面

双面打印时奇数页是纸的正面。每个 skill 章节和附录都从正面开始：前一部分停在正面时，
构建器补一页不含页眉、页码或边框的空白纸背。因此每章都占整张纸，更新包可以按章替换。

## 打印账本与更新包

每次完整构建都会在项目目录写入 `print-ledger.json`。它按 skill 记录章节号、所渲染
原文的指纹、版本与 commit，以及印在哪份 PDF 的哪几页。指纹覆盖英文标题、原文、参考
文档和 override，不含源码链接和译文，因此换到新 commit 或润色译文都不会触发重印。

跟进上游新 commit 时，在同一项目中更新 `book.json`（版本、commit、各 `source_url`
和 skill 列表），然后：

1. 运行 `--check --update`。它在校验前逐行列出更新、新增和撤除的章节；只翻译更新和
   新增的章节。
2. 运行 `--update`。更新包首页是更新说明，列出每章的
   处理方式（替换、插入、撤除）和已印页码，之后是更新和新增的章节，每章都占整张纸。
   已印章节保留原章节号；新 skill 接在已印最大章节号之后。
3. 构建器把更新包并入账本，下次更新会与纸面上的全部内容比较。没有变化时提示
   "nothing to print"，不生成 PDF。

默认输出名为 `<output 主名>-update-<version>.pdf`。更新包不含阅读导引、目录和附录。
完整构建会重新开始账本。

账本出现之前就已打印的版本，先在其打印时的 commit 上重建一次，记下账本。

## 源文件代码块写错时

代码块按 CommonMark 解析：结束行必须用与开头相同的字符、长度不短于开头，且不带
语言标记。因此四个反引号的代码块里可以嵌套三个反引号的代码块，嵌套的
`` ```ts `` 行也不会提前结束外层的 `` ```markdown ``。

固定版本的上游文件按此规则留下未结束的代码块时，`--check` 会失败并指出文件和开头
行号。不要修改固定源码；把该文件复制进项目，只修代码块的围栏行（例如把外层围栏
加长为四个反引号），再登记到对应的 skill 或参考文档条目：

```json
"source_override": "overrides/triage-out-of-scope.md",
"override_reason": "Upstream nests a ```ts fence inside ```markdown with equal-length fences."
```

构建器排版时使用修正副本，但参考文档核对、文件名和固定源码链接仍以 `source` 为准。
修正副本必须与原文行数相同，且只能在代码块围栏行上有差异，其他任何差异都会报错。
`--check` 会逐条打印修正副本、改动的行号与理由。

## 导言与附录

导言和附录的英中 Markdown 也必须逐块同构，并以对应的 H1 开头。

导言至少说明：

- 本书收录范围；
- 推荐阅读顺序；
- 英上中下版式；
- 安装或使用方法；
- 固定版本与 commit。

附录至少包含：

- skills 速览；
- 固定源码链接说明；
- 原始许可证正文及中文翻译。

## 依赖

构建脚本使用 Python 3 和 ReportLab，并按平台查找中文字体：

- macOS：STHeiti、Arial Unicode；
- Linux：Noto Sans CJK 或文泉驿正黑；
- Windows：微软雅黑或 Arial Unicode。

验收使用 Poppler、pypdf、pdfplumber 和 Pillow。缺少依赖或中文字体时先使用宿主提供
的工作区依赖加载能力；仍缺失则明确报告，不跳过验证。
