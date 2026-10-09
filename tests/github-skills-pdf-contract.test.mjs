import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { writeFileSync } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const ROOT = new URL("../", import.meta.url);

async function read(path) {
  return readFile(new URL(path, ROOT), "utf8");
}

async function readJson(path) {
  return JSON.parse(await read(path));
}

/** Return the one-based page numbers of blank PDF pages. */
function blankPageNumbers(pdf) {
  const out = spawnSync(
    "python3",
    [
      "-c",
      "from pypdf import PdfReader\nimport sys\n" +
        "print(','.join(str(i) for i, p in enumerate(PdfReader(sys.argv[1]).pages, 1)" +
        " if not p.extract_text().strip()))",
      pdf,
    ],
    { encoding: "utf8" },
  ).stdout.trim();
  return out ? out.split(",").map(Number) : [];
}

/** Return the one-based page numbers where a skill chapter opens. */
function chapterStartPages(pdf) {
  const out = spawnSync(
    "python3",
    [
      "-c",
      "from pypdf import PdfReader\nimport sys\n" +
        "print(','.join(str(i) for i, p in enumerate(PdfReader(sys.argv[1]).pages, 1)" +
        " if 'CHAPTER ' in p.extract_text()))",
      pdf,
    ],
    { encoding: "utf8" },
  ).stdout.trim();
  return out ? out.split(",").map(Number) : [];
}

/** Assert blanks only fill sheet backs and every chapter opens on a front. */
function assertChaptersOnFronts(pdf, chapterCount) {
  const starts = chapterStartPages(pdf);
  assert.equal(starts.length, chapterCount, `${pdf} chapter openers`);
  for (const page of starts) {
    assert.equal(page % 2, 1, `chapter on page ${page} must open on a sheet front`);
  }
}

/** Split page numbers into consecutive runs. */
function consecutiveRuns(pages) {
  const runs = [];
  for (const p of pages) {
    const last = runs[runs.length - 1];
    if (last && p === last[last.length - 1] + 1) last.push(p);
    else runs.push([p]);
  }
  return runs;
}

test("Smart publishes the GitHub Skills bilingual PDF contract", async () => {
  const [
    codexPlugin,
    claudePlugin,
    skill,
    openaiMetadata,
    builder,
    bookFormat,
    translationGuide,
  ] = await Promise.all([
    readJson("plugins/smart/.codex-plugin/plugin.json"),
    readJson("plugins/smart/.claude-plugin/plugin.json"),
    read("plugins/smart/skills/github-skills-pdf/SKILL.md"),
    read("plugins/smart/skills/github-skills-pdf/agents/openai.yaml"),
    read(
      "plugins/smart/skills/github-skills-pdf/scripts/build_bilingual_skills_pdf.py",
    ),
    read("plugins/smart/skills/github-skills-pdf/references/book-format.md"),
    read(
      "plugins/smart/skills/github-skills-pdf/references/translation-guide.md",
    ),
  ]);

  assert.equal(codexPlugin.name, "smart");
  assert.equal(claudePlugin.name, "smart");
  assert.equal(codexPlugin.version, claudePlugin.version);
  assert.equal(codexPlugin.skills, "./skills/");
  assert.match(
    codexPlugin.interface.defaultPrompt.join("\n"),
    /\$smart:github-skills-pdf/,
  );

  assert.match(
    skill,
    /^---\nname: github-skills-pdf\ndescription: .+\ndisable-model-invocation: true\nargument-hint: .+\n---\n/,
  );
  const argumentHint = skill.match(/\nargument-hint: (.+)\n/)?.[1];
  assert.ok(argumentHint, "argument-hint must be present");
  assert.match(argumentHint, /full=true/);
  assert.doesNotMatch(argumentHint, /is_note|--notes/);
  for (const contract of [
    "GitHub",
    "full commit",
    "skills/\\*/SKILL.md",
    "English source",
    "Simplified Chinese translation",
    "book-format.md",
    "translation-guide.md",
    "--check",
    "pdftoppm",
    "every official skill",
    "fixed source link",
    "unexpected blanks",
    "clipping",
    "orphan headings",
    "skipped or failed validation",
    "--update",
    "print-ledger.json",
  ]) {
    assert.match(skill, new RegExp(contract));
  }
  assert.doesNotMatch(skill, /## Invocation/);

  assert.match(openaiMetadata, /display_name: "smart:github-skills-pdf"/);
  assert.match(
    openaiMetadata,
    /default_prompt: ".*\$smart:github-skills-pdf.*"/,
  );
  assert.doesNotMatch(openaiMetadata, /is_note/);

  for (const artifact of [skill, openaiMetadata, builder, bookFormat, translationGuide]) {
    assert.doesNotMatch(artifact, /\/Users\//);
    assert.doesNotMatch(artifact, /\[TODO:/);
  }

  for (const contract of [
    "book.json",
    "source_url",
    "40-character Git commit SHA",
    "/blob/",
    "validate_pair",
    "TableOfContents",
    "CondPageBreak",
    "SheetParityBreak",
    "source_override",
    "print-ledger.json",
    "--update",
    "/usr/share/fonts/",
    "C:/Windows/Fonts/",
  ]) {
    assert.match(builder, new RegExp(contract));
  }
  assert.match(bookFormat, /source_url.*full 40-character `commit`/s);
  assert.match(translationGuide, /headings have identical counts, order, and levels/);
  assert.match(translationGuide, /tables have identical row and column shapes/);

  for (const runtimeSource of [skill, openaiMetadata, bookFormat, translationGuide]) {
    assert.doesNotMatch(runtimeSource, /[\p{Script=Han}]/u);
  }
  const executableHan = builder
    .split("\n")
    .filter((line) => /[\p{Script=Han}]/u.test(line));
  assert.ok(executableHan.length > 0, "bilingual PDF labels must remain present");
  assert.ok(
    executableHan.every((line) =>
      /正式技能|更新|新增|撤除|章节|英文原文|简体中文翻译|阅读导引|Source 原文|REFERENCE 参考文档|原文|编排|中文翻译与编排|学习版|英中逐块对照学习版|非官方学习版|固定提交|编译日期|Contents 目录|目录与 PDF 书签|主要小节和附录|从这里开始|REFERENCE · 参考/.test(line)
    ),
    `unexpected Chinese executable message or comment:\n${executableHan.join("\n")}`,
  );
});

test("每个 skill 章节都从纸的正面开始，空白页只补齐纸背", async () => {
  const skillDirectory = fileURLToPath(
    new URL("../plugins/smart/skills/github-skills-pdf/", import.meta.url),
  );
  const script = join(skillDirectory, "scripts/build_bilingual_skills_pdf.py");
  const project = await mkdtemp(join(tmpdir(), "github-skills-pdf-fronts-"));
  const commit = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
  const book = {
    title_en: "Fixture",
    title_zh: "测试",
    version: "1.0.0",
    commit,
    skills: [
      {
        name: "demo",
        title_en: "Demo",
        source: "skill-en.md",
        translation: "skill-zh.md",
        source_url: `https://github.com/example/repo/blob/${commit}/skills/demo/SKILL.md`,
      },
      {
        name: "demo-two",
        title_en: "Demo Two",
        source: "skill-two-en.md",
        translation: "skill-two-zh.md",
        source_url: `https://github.com/example/repo/blob/${commit}/skills/demo-two/SKILL.md`,
      },
    ],
    front: { en: "front-en.md", zh: "front-zh.md" },
    back: { en: "back-en.md", zh: "back-zh.md" },
  };
  try {
    await Promise.all([
      writeFile(join(project, "front-en.md"), "# Front\n\nIntro.\n"),
      writeFile(join(project, "front-zh.md"), "# 导言\n\n简介。\n"),
      writeFile(join(project, "skill-en.md"), "# Demo\n\nBody.\n"),
      writeFile(join(project, "skill-zh.md"), "# 演示\n\n正文。\n"),
      writeFile(join(project, "skill-two-en.md"), "# Demo Two\n\nMore body.\n"),
      writeFile(join(project, "skill-two-zh.md"), "# 演示二\n\n更多正文。\n"),
      writeFile(join(project, "back-en.md"), "# Back\n\nReference.\n"),
      writeFile(join(project, "back-zh.md"), "# 附录\n\n参考。\n"),
    ]);
    await writeFile(join(project, "book.json"), JSON.stringify(book));
    const plain = join(project, "plain.pdf");
    const plainResult = spawnSync("python3", [script, project, "--output", plain], {
      encoding: "utf8",
    });
    assert.equal(plainResult.status, 0, plainResult.stderr);
    // 双面打印时奇数页是纸的正面；每章从正面开始，更新包才能整章替换而不牵连邻章
    const plainBlanks = blankPageNumbers(plain);
    for (const run of consecutiveRuns(plainBlanks)) {
      assert.equal(run.length, 1, `空白页 ${run} 不应连续出现`);
      assert.equal(run[0] % 2, 0, `空白页 ${run[0]} 应在纸背`);
    }
    assertChaptersOnFronts(plain, book.skills.length);
  } finally {
    await rm(project, { recursive: true, force: true });
  }
});

test("构建器收录 skill 目录的参考文档并拒绝漏收", async () => {
  const skillDirectory = fileURLToPath(
    new URL("../plugins/smart/skills/github-skills-pdf/", import.meta.url),
  );
  const script = join(skillDirectory, "scripts/build_bilingual_skills_pdf.py");
  const project = await mkdtemp(join(tmpdir(), "github-skills-pdf-refs-"));
  const commit = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
  const blob = `https://github.com/example/repo/blob/${commit}/skills/demo`;
  const check = (book) => {
    writeFileSync(join(project, "book.json"), JSON.stringify(book));
    return spawnSync("python3", [script, project, "--check"], {
      encoding: "utf8",
    });
  };
  const skill = {
    name: "demo",
    title_en: "Demo",
    source: "demo/SKILL.md",
    translation: "demo-zh.md",
    source_url: `${blob}/SKILL.md`,
  };
  const book = {
    title_en: "Fixture",
    title_zh: "测试",
    version: "1.0.0",
    commit,
    skills: [skill],
    front: { en: "front-en.md", zh: "front-zh.md" },
    back: { en: "back-en.md", zh: "back-zh.md" },
  };
  try {
    await mkdir(join(project, "demo"), { recursive: true });
    await Promise.all([
      writeFile(join(project, "front-en.md"), "# Front\n\nIntro.\n"),
      writeFile(join(project, "front-zh.md"), "# 导言\n\n简介。\n"),
      writeFile(join(project, "back-en.md"), "# Back\n\nReference.\n"),
      writeFile(join(project, "back-zh.md"), "# 附录\n\n参考。\n"),
      // 正文用相对链接指向参考文档，正是这类引用在漏收时会断链
      writeFile(
        join(project, "demo", "SKILL.md"),
        "# Demo\n\nUse [FORMAT.md](./FORMAT.md).\n",
      ),
      writeFile(join(project, "demo-zh.md"), "# 演示\n\n使用 [FORMAT.md](./FORMAT.md)。\n"),
      writeFile(join(project, "demo", "FORMAT.md"), "# Format\n\nRules.\n"),
      writeFile(join(project, "format-zh.md"), "# 格式\n\n规则。\n"),
    ]);

    // 只登记 SKILL.md 时，同目录的参考文档必须被指名报错
    const missing = check(book);
    assert.equal(missing.status, 1, missing.stdout);
    assert.match(missing.stderr, /FORMAT\.md/);
    assert.match(missing.stderr, /references/);

    // 登记后校验通过，且构建产出包含参考文档标题与其固定源码链接
    skill.references = [
      {
        source: "demo/FORMAT.md",
        translation: "format-zh.md",
        source_url: `${blob}/FORMAT.md`,
      },
    ];
    const registered = check(book);
    assert.equal(registered.status, 0, registered.stderr);
    assert.match(registered.stdout, /FORMAT\.md: paired/);

    const output = join(project, "out.pdf");
    const built = spawnSync("python3", [script, project, "--output", output], {
      encoding: "utf8",
    });
    assert.equal(built.status, 0, built.stderr);
    const inspect = spawnSync(
      "python3",
      [
        "-c",
        "from pypdf import PdfReader; import sys\n" +
          "r = PdfReader(sys.argv[1])\n" +
          "print('\\n'.join(p.extract_text() for p in r.pages))\n" +
          "print('\\n'.join(a.get_object()['/A']['/URI'] for p in r.pages for a in (p.get('/Annots') or []) if '/URI' in a.get_object().get('/A', {})))",
        output,
      ],
      { encoding: "utf8" },
    );
    assert.equal(inspect.status, 0, inspect.stderr);
    assert.match(inspect.stdout, /REFERENCE 参考文档 · FORMAT\.md/);
    // 正文里的相对链接补全为固定 commit 的源码地址，而不是原样的 ./FORMAT.md
    assert.match(inspect.stdout, new RegExp(`${blob}/FORMAT\\.md`));

    // 显式豁免同样放行，并在输出中留痕
    delete skill.references;
    skill.skip_references = ["FORMAT.md"];
    const skipped = check(book);
    assert.equal(skipped.status, 0, skipped.stderr);
    assert.match(skipped.stdout, /explicitly skipped reference FORMAT\.md/);
  } finally {
    await rm(project, { recursive: true, force: true });
  }
});

test("构建器支持单语项目", async () => {
  const skillDirectory = fileURLToPath(
    new URL("../plugins/smart/skills/github-skills-pdf/", import.meta.url),
  );
  const script = join(skillDirectory, "scripts/build_bilingual_skills_pdf.py");
  const project = await mkdtemp(join(tmpdir(), "github-skills-pdf-mono-"));
  const commit = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
  const blob = `https://github.com/example/repo/blob/${commit}/skills`;
  const run = (book, args = []) => {
    writeFileSync(join(project, "book.json"), JSON.stringify(book));
    return spawnSync("python3", [script, project, ...args], { encoding: "utf8" });
  };
  // 源文件本身就是中文，没有、也不需要对照译文
  const book = {
    monolingual: true,
    title: "协作 Skill 手册",
    version: "1.0.0",
    commit,
    front: { file: "front.md", description: "通读一遍再动手。" },
    back: { file: "back.md" },
    skills: [
      {
        name: "one",
        title: "第一个 Skill",
        source: "one/SKILL.md",
        source_url: `${blob}/one/SKILL.md`,
      },
      {
        name: "two",
        title: "第二个 Skill",
        source: "two/SKILL.md",
        source_url: `${blob}/two/SKILL.md`,
      },
    ],
  };
  try {
    await Promise.all([
      mkdir(join(project, "one"), { recursive: true }),
      mkdir(join(project, "two"), { recursive: true }),
    ]);
    await Promise.all([
      writeFile(join(project, "front.md"), "# 导读\n\n先读这里。\n"),
      writeFile(join(project, "back.md"), "# 附录\n\n源码链接。\n"),
      writeFile(
        join(project, "one", "SKILL.md"),
        "# 第一个 Skill\n\n正文一。\n\n## 小节\n\n- 条目一\n- 条目二\n",
      ),
      writeFile(join(project, "two", "SKILL.md"), "# 第二个 Skill\n\n正文二。\n"),
    ]);

    const checked = run(book, ["--check"]);
    assert.equal(checked.status, 0, checked.stderr);
    // 单语只读原文，不存在配对一说
    assert.match(checked.stdout, /one: read \d+ content blocks/);
    assert.doesNotMatch(checked.stdout, /paired/);

    const plain = join(project, "plain.pdf");
    assert.equal(run(book, ["--output", plain]).status, 0);

    const inspect = (pdf, expr) =>
      spawnSync("python3", ["-c", `import sys\n${expr}`, pdf], {
        encoding: "utf8",
      }).stdout.trim();
    assert.ok(blankPageNumbers(plain).every((page) => page % 2 === 0));
    assertChaptersOnFronts(plain, book.skills.length);
    // 单语书不应残留双语的封面/页眉措辞
    const text =
      "from pypdf import PdfReader\n" +
      "print(''.join(p.extract_text() for p in PdfReader(sys.argv[1]).pages))";
    assert.doesNotMatch(inspect(plain, text), /BILINGUAL/);

    // 配了 translation 就是自相矛盾，必须明确报错而不是默默忽略
    const contradictory = structuredClone(book);
    contradictory.skills[0].translation = "one-zh.md";
    const rejected = run(contradictory, ["--check"]);
    assert.equal(rejected.status, 1);
    assert.match(rejected.stderr, /monolingual project must not configure translation/);

    // 中性别名（title / front.file）只在单语模式下归一化，双语仍须写 _en/_zh
    const aliasOnly = structuredClone(book);
    delete aliasOnly.monolingual;
    aliasOnly.title_en = "Handbook";
    aliasOnly.title_zh = "手册";
    const unnormalized = run(aliasOnly, ["--check"]);
    assert.equal(unnormalized.status, 1);
    assert.match(unnormalized.stderr, /missing required field: title_en/);

    // 双语项目缺 translation 仍要报错（未被单语模式放宽）
    const bilingual = structuredClone(aliasOnly);
    bilingual.front = { en: "front.md", zh: "front.md" };
    bilingual.back = { en: "back.md", zh: "back.md" };
    bilingual.skills = bilingual.skills.map((s) => ({ ...s, title_en: s.title }));
    const missing = run(bilingual, ["--check"]);
    assert.equal(missing.status, 1);
    assert.match(missing.stderr, /translation/);
  } finally {
    await rm(project, { recursive: true, force: true });
  }
});

test("builder runs from the skill directory and rejects a moving ref", async () => {
  const skillDirectory = fileURLToPath(
    new URL("../plugins/smart/skills/github-skills-pdf/", import.meta.url),
  );
  const script = join(
    skillDirectory,
    "scripts/build_bilingual_skills_pdf.py",
  );
  const help = spawnSync(
    "python3",
    ["scripts/build_bilingual_skills_pdf.py", "--help"],
    { cwd: skillDirectory, encoding: "utf8" },
  );
  assert.equal(help.status, 0, help.stderr);
  assert.match(help.stdout, /usage:/);
  assert.match(help.stdout, /project directory containing book\.json/);
  assert.match(help.stdout, /--update/);
  assert.doesNotMatch(help.stdout, /--is-note|--notes/);

  const project = await mkdtemp(join(tmpdir(), "github-skills-pdf-"));
  try {
    await writeFile(
      join(project, "book.json"),
      JSON.stringify({
        title_en: "Fixture",
        title_zh: "测试",
        version: "1.0.0",
        commit: "main",
        skills: [{}],
        front: { en: "front-en.md", zh: "front-zh.md" },
        back: { en: "back-en.md", zh: "back-zh.md" },
      }),
    );
    const invalid = spawnSync(
      "python3",
      [script, project, "--check"],
      { encoding: "utf8" },
    );
    assert.equal(invalid.status, 1);
    assert.match(invalid.stderr, /40-character Git commit SHA/);
  } finally {
    await rm(project, { recursive: true, force: true });
  }
});

/** Run Python against the builder module and return its stdout. */
function withBuilder(code) {
  const script = fileURLToPath(
    new URL(
      "../plugins/smart/skills/github-skills-pdf/scripts/build_bilingual_skills_pdf.py",
      import.meta.url,
    ),
  );
  const result = spawnSync(
    "python3",
    [
      "-c",
      "import importlib.util, sys\n" +
        "spec = importlib.util.spec_from_file_location('builder', sys.argv[1])\n" +
        "b = importlib.util.module_from_spec(spec)\n" +
        "sys.modules['builder'] = b\n" +
        "spec.loader.exec_module(b)\n" +
        code,
      script,
    ],
    { encoding: "utf8" },
  );
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trim();
}

test("代码块按 CommonMark 规则结束，未结束时指出行号", () => {
  const parsed = JSON.parse(
    withBuilder(
      "import json\n" +
        "nested = '````markdown\\n# Doc\\n```ts\\nconst a = 1;\\n```\\n````\\n\\nAfter.\\n'\n" +
        "info = '```markdown\\nText\\n```ts\\ncode\\n```\\n\\nAfter.\\n'\n" +
        "out = {}\n" +
        "for key, md in (('nested', nested), ('info', info)):\n" +
        "    out[key] = [(x.kind, x.language, x.text) for x in b.parse_blocks(md)]\n" +
        "try:\n" +
        "    b.parse_blocks('Intro.\\n\\n```\\nnever closed\\n')\n" +
        "except ValueError as e:\n" +
        "    out['error'] = str(e)\n" +
        "print(json.dumps(out))",
    ),
  );
  // 四个反引号的外层把三个反引号的内层整个包住
  assert.deepEqual(parsed.nested[0], [
    "code",
    "markdown",
    "# Doc\n```ts\nconst a = 1;\n```",
  ]);
  assert.deepEqual(parsed.nested[1], ["paragraph", "", "After."]);
  // 带语言标记的 ```ts 不能结束外层代码块
  assert.deepEqual(parsed.info[0], ["code", "markdown", "Text\n```ts\ncode"]);
  assert.match(parsed.error, /line 3/);
  assert.match(parsed.error, /source_override/);
});

test("只改围栏行的 source_override 可以通过，并在 --check 中留痕", async () => {
  const skillDirectory = fileURLToPath(
    new URL("../plugins/smart/skills/github-skills-pdf/", import.meta.url),
  );
  const script = join(skillDirectory, "scripts/build_bilingual_skills_pdf.py");
  const project = await mkdtemp(join(tmpdir(), "github-skills-pdf-override-"));
  const commit = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b";
  // 上游把 ```ts 嵌在等长的 ```markdown 里，按 CommonMark 文末会剩一个未结束的代码块
  const broken =
    "# Demo\n\n```markdown\n# Example\n\n```ts\nconst a = 1;\n```\n\nTail.\n```\n";
  const repaired =
    "# Demo\n\n````markdown\n# Example\n\n```ts\nconst a = 1;\n```\n\nTail.\n````\n";
  const skill = {
    name: "demo",
    title_en: "Demo",
    source: "demo/SKILL.md",
    translation: "demo-zh.md",
    source_url: `https://github.com/example/repo/blob/${commit}/skills/demo/SKILL.md`,
  };
  const book = {
    title_en: "Fixture",
    title_zh: "测试",
    version: "1.0.0",
    commit,
    translator: "Test Translator",
    skills: [skill],
    front: { en: "front-en.md", zh: "front-zh.md" },
    back: { en: "back-en.md", zh: "back-zh.md" },
  };
  const run = (args) => {
    writeFileSync(join(project, "book.json"), JSON.stringify(book));
    return spawnSync("python3", [script, project, ...args], { encoding: "utf8" });
  };
  try {
    await mkdir(join(project, "demo"), { recursive: true });
    await mkdir(join(project, "overrides"), { recursive: true });
    await Promise.all([
      writeFile(join(project, "front-en.md"), "# Front\n\nIntro.\n"),
      writeFile(join(project, "front-zh.md"), "# 导言\n\n简介。\n"),
      writeFile(join(project, "back-en.md"), "# Back\n\nReference.\n"),
      writeFile(join(project, "back-zh.md"), "# 附录\n\n参考。\n"),
      writeFile(join(project, "demo", "SKILL.md"), broken),
      writeFile(join(project, "overrides", "demo.md"), repaired),
      writeFile(join(project, "demo-zh.md"), repaired.replace("# Demo", "# 演示")),
    ]);

    // 未登记修正副本时，错误指向源文件与开头行号
    const unclosed = run(["--check"]);
    assert.equal(unclosed.status, 1);
    assert.match(unclosed.stderr, /SKILL\.md: fenced code block opened at line 11/);

    // 只登记副本不写理由，不放行
    skill.source_override = "overrides/demo.md";
    const noReason = run(["--check"]);
    assert.equal(noReason.status, 1);
    assert.match(noReason.stderr, /override_reason/);

    // 写明理由后通过，并打印改动的围栏行
    skill.override_reason = "Upstream nests equal-length fences.";
    const checked = run(["--check"]);
    assert.equal(checked.status, 0, checked.stderr);
    assert.match(checked.stdout, /demo: paired 2 content blocks/);
    assert.match(
      checked.stdout,
      /source override overrides\/demo\.md replaces demo\/SKILL\.md \(fence lines changed: 3, 11\); reason: Upstream/,
    );

    // 构建产物的作者取 translator，不再写死其他工具名
    const output = join(project, "out.pdf");
    const built = run(["--output", output]);
    assert.equal(built.status, 0, built.stderr);
    const meta = spawnSync(
      "python3",
      [
        "-c",
        "from pypdf import PdfReader; import sys, json\n" +
          "m = PdfReader(sys.argv[1]).metadata\n" +
          "print(json.dumps({'author': m.author, 'creator': m.creator}))",
        output,
      ],
      { encoding: "utf8" },
    );
    const { author, creator } = JSON.parse(meta.stdout);
    assert.match(author, /Test Translator/);
    assert.doesNotMatch(author, /Codex/);
    assert.equal(creator, "smart:github-skills-pdf");

    // 修正副本改了围栏以外的内容，一律拒绝
    await writeFile(
      join(project, "overrides", "demo.md"),
      repaired.replace("Tail.", "Changed."),
    );
    const tampered = run(["--check"]);
    assert.equal(tampered.status, 1);
    assert.match(tampered.stderr, /only code fence lines; line 10 differs/);
  } finally {
    await rm(project, { recursive: true, force: true });
  }
});

test("排版：代码块不重叠、堆叠标题随正文、下划线强调", () => {
  const out = JSON.parse(
    withBuilder(
      "import json\n" +
        "b.register_fonts()\n" +
        "styles = b.build_styles()\n" +
        "code = styles['code']\n" +
        "top, _, bottom, _ = code.borderPadding\n" +
        "blocks = [b.Block(kind='heading', text='Examples', level=2),\n" +
        "          b.Block(kind='heading', text='Good', level=3),\n" +
        "          b.Block(kind='paragraph', text='Body.')]\n" +
        "flow = b.pair_flowables(blocks, None, styles)\n" +
        "print(json.dumps({\n" +
        "  'gap': max(code.spaceAfter, code.spaceBefore),\n" +
        "  'padding': top + bottom,\n" +
        "  'top_level': [type(f).__name__ for f in flow],\n" +
        "  'italic': b.inline_markup('_Use when_ needed'),\n" +
        "  'snake': b.inline_markup('set skip_references or __init__'),\n" +
        "  'cjk': b.inline_markup('_适用于_会话'),\n" +
        "}))",
    ),
  );
  // 相邻代码块的间距必须盖过两侧背景的内边距，否则后一块会盖住前一块最后一行
  assert.ok(out.gap > out.padding, `间距 ${out.gap} 应大于内边距 ${out.padding}`);
  // H2 紧跟 H3 时，两个标题都和正文绑在同一个 KeepTogether 里，不会单独留在页底
  assert.deepEqual(out.top_level, ["CondPageBreak", "KeepTogether"]);
  assert.match(out.italic, /<i>Use when<\/i>/);
  assert.doesNotMatch(out.snake, /<i>/);
  // 与 GitHub 一致：紧贴汉字的下划线不构成强调
  assert.doesNotMatch(out.cjk, /<i>/);
});

test("增量更新只打印有变化的章节，并按账本记录已印内容", async () => {
  const skillDirectory = fileURLToPath(
    new URL("../plugins/smart/skills/github-skills-pdf/", import.meta.url),
  );
  const script = join(skillDirectory, "scripts/build_bilingual_skills_pdf.py");
  const project = await mkdtemp(join(tmpdir(), "github-skills-pdf-update-"));
  const oldCommit = "1111111111111111111111111111111111111111";
  const newCommit = "2222222222222222222222222222222222222222";
  const skillEntry = (name, commit) => ({
    name,
    title_en: `Skill ${name}`,
    source: `${name}-en.md`,
    translation: `${name}-zh.md`,
    source_url: `https://github.com/example/repo/blob/${commit}/skills/${name}/SKILL.md`,
  });
  const writeBook = (version, commit, names) =>
    writeFile(
      join(project, "book.json"),
      JSON.stringify({
        title_en: "Fixture",
        title_zh: "测试",
        version,
        commit,
        output: "book.pdf",
        skills: names.map((name) => skillEntry(name, commit)),
        front: { en: "front-en.md", zh: "front-zh.md" },
        back: { en: "back-en.md", zh: "back-zh.md" },
      }),
    );
  const run = (...args) =>
    spawnSync("python3", [script, project, ...args], { encoding: "utf8" });
  const ledger = async () =>
    JSON.parse(await readFile(join(project, "print-ledger.json"), "utf8"));
  const pdfText = (pdf) =>
    spawnSync(
      "python3",
      [
        "-c",
        "from pypdf import PdfReader; import sys\n" +
          "print('\\f'.join(p.extract_text() for p in PdfReader(sys.argv[1]).pages))",
        pdf,
      ],
      { encoding: "utf8" },
    ).stdout;
  try {
    await Promise.all([
      writeFile(join(project, "front-en.md"), "# Front\n\nIntro.\n"),
      writeFile(join(project, "front-zh.md"), "# 导言\n\n简介。\n"),
      writeFile(join(project, "back-en.md"), "# Back\n\nReference.\n"),
      writeFile(join(project, "back-zh.md"), "# 附录\n\n参考。\n"),
      ...["a", "b", "c", "d"].flatMap((name) => [
        writeFile(join(project, `${name}-en.md`), `# Skill ${name}\n\nBody ${name}.\n`),
        writeFile(join(project, `${name}-zh.md`), `# 技能 ${name}\n\n正文 ${name}。\n`),
      ]),
    ]);
    await writeBook("1.3.0", oldCommit, ["a", "b", "c"]);

    // 没有已印版本时，增量无从比较，必须明确报错
    const orphan = run("--update");
    assert.equal(orphan.status, 1);
    assert.match(orphan.stderr, /print-ledger\.json/);

    const full = run();
    assert.equal(full.status, 0, full.stderr);
    const printed = await ledger();
    assert.deepEqual(Object.keys(printed.skills), ["a", "b", "c"]);
    assert.deepEqual(
      Object.values(printed.skills).map((entry) => entry.chapter),
      [1, 2, 3],
    );
    for (const entry of Object.values(printed.skills)) {
      assert.equal(entry.pdf, "book.pdf");
      assert.equal(entry.pages[0] % 2, 1, "已印章节应从纸的正面开始");
    }

    // v1.4：b 原文改动，c 撤除，d 新增；a 只润色译文、换了固定提交，不应重印
    await Promise.all([
      writeFile(join(project, "b-en.md"), "# Skill b\n\nBody b, revised.\n"),
      writeFile(join(project, "b-zh.md"), "# 技能 b\n\n正文 b，已修订。\n"),
      writeFile(join(project, "a-zh.md"), "# 技能 a\n\n正文 a（润色）。\n"),
    ]);
    await writeBook("1.4.0", newCommit, ["a", "b", "d"]);

    const planned = run("--check", "--update");
    assert.equal(planned.status, 0, planned.stderr);
    assert.match(planned.stdout, /update: updated chapter 02 b \(replaces book\.pdf p\.\d+-\d+\)/);
    assert.match(planned.stdout, /update: new chapter 04 d/);
    assert.match(planned.stdout, /update: withdrawn chapter 03 c \(remove book\.pdf p\.\d+-\d+\)/);
    assert.doesNotMatch(planned.stdout, /chapter 01 a/);

    const update = run("--update");
    assert.equal(update.status, 0, update.stderr);
    const pack = join(project, "book-update-1.4.0.pdf");
    const pages = pdfText(pack).split("\f");
    assert.match(pages[0], /UPDATE/);
    assert.match(pages[0], /v1\.3\.0 → v1\.4\.0/);
    assert.match(pages[0], /Withdrawn/);
    assert.match(pdfText(pack), /CHAPTER 02 · SKILL/);
    assert.match(pdfText(pack), /CHAPTER 04 · SKILL/);
    assert.doesNotMatch(pdfText(pack), /CHAPTER 01|CHAPTER 03/);
    assertChaptersOnFronts(pack, 2);

    const merged = await ledger();
    assert.deepEqual(Object.keys(merged.skills).sort(), ["a", "b", "d"]);
    assert.equal(merged.skills.a.pdf, "book.pdf");
    assert.equal(merged.skills.a.version, "1.3.0");
    assert.equal(merged.skills.b.pdf, "book-update-1.4.0.pdf");
    assert.equal(merged.skills.b.version, "1.4.0");
    assert.equal(merged.skills.d.chapter, 4);
    assert.deepEqual(
      merged.editions.map((edition) => edition.kind),
      ["full", "update"],
    );

    // 再次运行时已无变化：不生成 PDF，账本不变
    await rm(pack);
    const again = run("--update");
    assert.equal(again.status, 0, again.stderr);
    assert.match(again.stdout, /nothing to print/);
    await assert.rejects(readFile(pack));
    assert.deepEqual(await ledger(), merged);
  } finally {
    await rm(project, { recursive: true, force: true });
  }
});
