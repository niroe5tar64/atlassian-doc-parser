# 007: ReScript ディレクトリ構成（このプロジェクトへの適用）

- **status**: closed
- **date**: 2026-02-08
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: ReScript パーサー実装に向けた構成設計

## 背景

このリポジトリは `rescript.json` / `package.json` はあるが、`src/` と `tests/` はまだ空。
一方で、既存の決定事項として以下は確定している:

1. 公開 API は `ConvertResult` を返す（`002`）
2. 変換アーキテクチャは `XML -> IR -> Markdown`（`003`）
3. エラーハンドリングは `strict` 切り替え（`006`）

## 決定

Option A（公開 API と内部実装を分離し、責務単位で配置）を採用する。
また、内部モジュール命名は `AtlassianXxx` ではなく、ドメイン単位で `ConfluenceXxx` / `JiraXxx` を基本とする。

```text
src/
  AtlassianDocParser.res
  AtlassianDocParser.resi
  ConfluenceTypes.res

  confluence/
    ConfluenceInputXml.res
    ConfluenceInputPosition.res
    ConfluenceInputError.res
    ConfluenceIrNode.res
    ConfluenceIrBuilder.res
    ConfluenceMarkdownRenderer.res
    ConfluenceMarkdownWriter.res
    ConfluencePipelineConvert.res
    ConfluencePipelineDiagnostics.res

tests/
  unit/
    ConfluenceInputXml_test.res
    ConfluenceIrBuilder_test.res
    ConfluenceMarkdownRenderer_test.res
  integration/
    AtlassianDocParser_test.res
    AtlassianStrictMode_test.res
  fixtures/
    xml/
      basic.xml
      complex-table.xml
      nested-macro.xml
    md/
      basic.md
      complex-table.md
      nested-macro.md
```

## 命名規約（確定）

1. 公開エントリは `AtlassianDocParser.res(.resi)` を維持する（`package.json` の `main` と公開 API 契約を優先）
2. Confluence 固有の実装は `ConfluenceXxx.res` とする
3. Jira 対応を追加する場合は `JiraXxx.res` を新設する
4. 真に共通化できる層のみ `AtlassianXxx.res` もしくは `CommonXxx.res` を許可する

## テスト配置と命名（確定）

1. テストは `src/` と `tests/` を分離する（今回は co-location を採用しない）
2. テストモジュール名は `*_test.res` を採用する
3. `*.test.res` / `*.spec.res` は採用しない（ReScript のモジュール参照上、運用上の混乱を招きやすいため）

## 理由（決定別）

### 1. Option A（責務単位ディレクトリ）を採用した理由

1. `XML -> IR -> Markdown` の責務境界を実装構造に直接対応づけられる
2. 実装が増えても、変更影響範囲をレイヤー単位で追いやすい

### 2. `ConfluenceXxx` / `JiraXxx` 命名を採用した理由

1. `AtlassianXxx` 一律より、将来の Jira 拡張時にドメイン境界を明確化できる
2. Confluence 固有実装と将来の共通層を区別しやすくなる

### 3. 公開エントリのみ `AtlassianDocParser` を維持する理由

1. `package.json` の `main` と既存公開 API 契約の互換性を優先できる
2. 外部利用者向けの import パスを不用意に揺らさずに済む

### 4. `src/` と `tests/` を分離する理由

1. 配布対象と検証コードの境界を明確に保てる
2. fixture 共有と integration テスト運用を一箇所で管理しやすい

### 5. テスト命名を `*_test.res` にする理由

1. ReScript のモジュール参照と相性が良く、運用上の混乱を避けやすい
2. `*.test.res` / `*.spec.res` より、既存 ReScript プロジェクトの慣習に合わせやすい

## 未決/リスク

- Jira 実装開始時に、共通化対象（`Atlassian` / `Common`）の切り出し境界を再評価する必要がある

## ステータス

決定済み
