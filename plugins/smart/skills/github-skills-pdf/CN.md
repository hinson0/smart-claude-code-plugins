---
name: github-skills-pdf
description: 将固定版本的 GitHub skills 仓库制作为经验证的 A4 手册，英文原文在上、简体中文译文在下。
disable-model-invocation: true
argument-hint: "<仓库或 URL> [full=true] —— 已打印过的版本之后只打印有变化的章节，除非 full=true"
---

# GitHub Skills PDF

将固定版本的仓库制作为可复现的 A4 手册。

1. 使用宿主 GitHub 能力读取仓库；需要完整目录树时再 clone。记录仓库、默认分支、完整 commit、版本依据、许可证和构建日期。缺少源码或元数据时明确报告，不猜测。
2. 结合 manifest、README 命令和 `skills/*/SKILL.md` 找全正式 skill，排除示例、fixture 和废弃技能。列全各 skill 目录的 Markdown：正文材料放入 `references`，其余登记到 `skip_references` 并说明理由。
3. 阅读源文件判定模式：英文源文下方逐块配简体中文译文；中文或其他非英文单语源文使用 `monolingual: true`，不重复翻译。
4. 该仓库已有保留的构建项目时复用它，不知道路径就询问用户；否则在本 skill 目录外创建项目。阅读 [book-format.md](references/book-format.md)，了解 `book.json`、导言/附录、依赖和更新包；`translator` 填实际完成翻译与编排的人或工具。双语模式再阅读 [translation-guide.md](references/translation-guide.md)，翻译全部收录的 skill 和参考文档；增量更新时只翻译 `--check --update` 列出的章节，其余译文保持不动。若委派翻译，同一 skill 及其参考文档交给同一人，完成后亲自重读译文。
5. 从本 skill 实际路径运行构建器；配对失败时修正译文，不降低校验强度：

   ```bash
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --check
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --output <output.pdf>
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --check --update
   python3 <this-skill-directory>/scripts/build_bilingual_skills_pdf.py <project-dir> --update
   ```

   项目已有 `print-ledger.json` 且调用未带 `full=true` 时，按 book-format.md 用 `--update` 生成更新包：只含更新和新增的章节，首页的更新说明列出已印版本中要替换、插入或撤除的页码。构建器提示 "nothing to print" 时到此为止。账本出现之前就已打印的版本，先在其打印时的 commit 上重建一次，记下账本。`--check` 报告固定源码中有未结束的代码块时，按 book-format.md 登记只改围栏行、并写明理由的 `source_override`，不修改固定源码。使用构建器的 A4 版式、英上中下顺序、章内参考文档、固定源码链接、目录、书签和页眉页码。有截图时遵循其字号、间距、分隔线和代码底色。
6. 检查 PDF 元数据、页数、书签、链接和文本；用 `pdftoppm -png -r 144 <output.pdf> <render-dir>/page` 渲染全部页面。核对全部 skill、收录的参考文档和源码链接，检查页面有无越界、截断、孤立标题、意外空白或占位符。确认渲染页数与 PDF 页数一致，指定样式已体现。
7. 交付前说明跳过或失败的验证。返回 PDF 链接、页数、skill 数量、固定版本及验证结果；更新包还要列出更新说明中的替换、插入、撤除清单。保留构建项目以便复现，临时渲染图另存。
