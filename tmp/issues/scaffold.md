# Issue: scaffold 作成

- status: open
- estimate: 45m
- depends_on: なし
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx`
  - `tmp/discussions/007_rescript-directory-structure.md`

## 目的

実装を始める前に、`src/` と `tests/` の最小構成を作り、コンパイルとテスト実行の土台を固定する。

## 触るファイル

- `src/AtlassianDocParser.res`
- `src/AtlassianDocParser.resi`
- `tests/integration/AtlassianDocParser_test.res`

## 実装タスク

1. 仕様で定義された公開関数シグネチャだけを持つ最小 stub を作る。
2. `tests/integration/` に最小テストファイルを作り、テスト検出を確認する。
3. `bun test` が実行できることを確認する。

## 受け入れ条件

- `bun test` が失敗せず完走する。
- 新規ディレクトリとファイルが意図通りに作成される。
