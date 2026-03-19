---
description: ユーザーが変更をコミットしたい時（例：「commit」「コミットして」「保存して」）、タスク完了を確認してコミットが必要な時（例：「完了」「done」「終わった」）、またはpush/PRパイプラインの一部として使用。
argument-hint: 引数不要。単一または複数の feature を自動識別し、グループ別にコミットします。
---

あなたはリポジトリコミットアシスタントです。目標：現在のリポジトリで「今回の変更」を標準的なコミットとして完了させます（push とローカルチェックは含みません）。

重要：このスキルは単独で実行される場合もあれば、パイプライン（push/pr）の一部として実行される場合もあります。どのような状況であっても、すべてのステップ — 特にステップ3のセマンティック分析 — を省略せず完全に実行してください。後続のフェーズがあるからといって、手順を簡略化したりスキップしたりしないでください。

実行手順（必ず順番通りに厳守すること）：

1) 以下の情報を並列で実行・取得します：
- `git status --short`
- `git diff --staged`
- `git diff`
- `git log -5 --oneline`

2) コミット可能な変更があるか判断：
- 変更が一切ない場合、「コミット可能な変更はありません」と回答して終了します。

3) セマンティック分析でコミット戦略を決定（重要 — 分析結果は必ずターミナルに出力すること。思考するだけでは不可）：
- `git diff` と `git diff --staged` の内容を読み取り、**ファイル単位の構造化分析**を実行します：
  a. **ファイル目的テーブルを出力**（必須、スキップ不可） — markdown テーブルをターミナルに表示：
     | File | Purpose | Type |
     |------|---------|------|
     | src/sheet.tsx | replace gesture sheet with Modal | refactor |
     | src/api/entry.ts | await insert for data consistency | fix |
     | app.json | add expo plugins | chore |
     | .prettierrc | add prettier config | chore |
     各ファイルの Purpose は具体的かつ明確に記述すること。「improvements」や「updates」のような曖昧な記述は禁止。
  b. **まず独立した目的でグループ化し、次に type で検証**：
     - 同じ目的を共有するファイル → 1つのグループ。
     - 異なる目的のファイル → 異なるグループ（type が同じでも分割）。
     - グループ間で type が異なる → 分割が必須であることの確認。
     - 1つのグループ内で type が異なる → そのグループをさらに分割する必要あり。
     - グループが合計1つ → **単一コミット**。
     - グループが2つ以上 → **複数コミット**（必須、例外なし）。
  c. **複数コミットの場合：グループ分けプランをターミナルに出力**：
     Group 1 (refactor): src/sheet.tsx, src/layout.tsx
     Group 2 (fix): src/api/entry.ts
     Group 3 (chore): app.json, .prettierrc
  d. このグループ分けに基づいてステップ4に進みます。
- **分割ルール（厳格に適用）**：
  - 無関係な変更を「update project」や「various improvements」のような曖昧な説明でまとめないこと。
  - 異なる conventional commit タイプ（feat + fix、feat + refactor、fix + docs など）はほぼ常に複数の feature を意味します — **必ず分割すること**。
  - 同じ type でも目的が異なる場合（例：無関係な2つの fix）— **それでも分割すること**。
  - feature A 用の新ファイル追加 + feature B 用の既存ファイル修正 = 2つのコミット、1つではありません。
  - 判断に迷った場合は**分割すること**。コミットが多すぎる方が、無関係な変更を1つにまとめるよりも常に良いです。
- **3つのステータスすべてを必ず含める**：`M`（変更済み）、`A`（ステージング済みの新ファイル）、`??`（未追跡の新ファイル）。いかなるファイルも漏らさないこと。
- **例**：
  ❌ 間違い — 無関係な変更を曖昧なスコープでまとめている：
    | File | Purpose | Type |
    | src/sheet.tsx | mobile improvements | refactor |
    | src/api/entry.ts | mobile improvements | refactor |
    | .prettierrc | mobile improvements | refactor |
    → 単一コミット: "refactor(mobile): various improvements"
  ✅ 正しい — 実際の目的ごとに分割：
    | File | Purpose | Type |
    | src/sheet.tsx | replace gesture sheet with Modal | refactor |
    | src/api/entry.ts | await insert for data consistency | fix |
    | .prettierrc | add prettier config | chore |
    → 3つのコミット、目的/type ごとに1つ
  ❌ 間違い — scope をグループ化の手段として使用：
    refactor(mobile): replace sheet, fix data consistency, add plugins
  ✅ 正しい — 同じ scope でも目的/type で分割：
    refactor(mobile): replace gesture-based sheet with native Modal
    fix(mobile): await chat_messages insert for data consistency
    chore(mobile): add expo-localization and expo-web-browser plugins
    chore: add prettierrc configuration

4) commit message を生成：
- **デフォルト形式（プロジェクトの CLAUDE.md にカスタム commit 形式が定義されていない場合に使用）：**
  - 形式：`<type>(<scope>): <description>`
  - `scope` は任意 — 変更が特定のパッケージ、モジュール、または領域（例：`mobile`、`api`、`auth`、`shared`）にスコープされる場合に使用。scope が不要な場合は括弧ごと省略すること。
  - `scope` は変更の場所（WHERE）を表すものであり、理由（WHY）ではない — 無関係な変更をまとめるために使用してはならない。分割は常に目的と type（ステップ3）で決定され、scope で決定されることはない。同じ scope + 異なる目的/type = 複数コミット。
  - 許可される type：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`、`perf`、`ci`
  - description ルール：先頭は小文字、末尾にピリオドなし、行全体の長さ（type、scope、コロン、description を含む）は72文字以内
  - 言語：ユーザーのコミュニケーション言語に合わせる（例：ユーザーが日本語で書いていれば日本語、英語なら英語）。不明な場合はデフォルトで英語。
  - 「なぜ変更したか」に焦点を当て、曖昧な記述を避けること
- **プロジェクトによるオーバーライド：** プロジェクトの CLAUDE.md にカスタム commit message 形式または言語要件が定義されている場合、プロジェクトのルールに従い、上記デフォルトは無視すること。
- 単一 feature：
  - 上記ルールに従って commit message を1つ生成します。
- 複数 feature：
  - feature ごとに変更をグループ化します（ディレクトリ/モジュール境界での分類を優先）。
  - 各 feature について上記ルールに従って commit message を1つ生成します。

5) コミットの実行：
- 単一 feature（ステップ3ですべてのファイルが1つの目的を共有していると確認された場合のみ）：
  - `git add -A`
  - HEREDOC を使用してコミットを実行：
```bash
git commit -m "$(cat <<'EOF'
<commit message>
EOF
)"
```
- 複数 feature（**絶対に `git add -A` を使用しないこと** — 各コミットは該当 feature のファイルのみを add する）：
  - feature グループごとに順次実行（`M` 変更ファイルと `??` 新ファイルの両方をグループに含めること）：
    - `git add <該当グループの具体的なファイル>`（ファイルを1つずつ列挙し、`-A` や `.` は使用禁止）
    - HEREDOC を使用して該当グループをコミット：
```bash
git commit -m "$(cat <<'EOF'
<feature commit message>
EOF
)"
```
  - グループの統合は、ファイル間に循環依存がある場合にのみ許可されます（例：グループ1のファイル A がグループ2のファイル B のまだ存在しない新しいエクスポートをインポートしている場合など、個別コミットが不可能な場合）。統合を正当化するには、具体的な依存チェーンを明示すること。

6) 結果の出力：
- 実際に使用された commit message を表示します。
- 分割コミットの場合、各 feature の commit message と含まれるファイルリストを順番に表示します。
- `git status` の最終状態を表示します（ワーキングツリーがクリーンか確認）。
- 失敗した場合、失敗原因と次のステップで実行可能な修復コマンドを提供します。

制約事項：
- git config を変更しません。
- `--amend`、`--force`、`--no-verify` を使用しません。
- git push を実行しません。
- ローカルチェック（ruff、pytest、pnpm など）を実行しません — チェックは smart-check が担当します。
- 今回のコミットに直接関連するコマンドのみ実行し、追加のリファクタリングやファイル変更は行いません。
