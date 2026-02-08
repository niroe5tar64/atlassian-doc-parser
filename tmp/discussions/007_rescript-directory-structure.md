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

## セカンドオピニオン（2026-02-09, Claude Opus 4.6）

全体方針（責務単位ディレクトリ、`ConfluenceXxx` 命名、`src/` / `tests/` 分離、`*_test.res` 命名）はいずれも妥当。以下は実装着手前に確認しておきたい疑問点。

### Q1: `ConfluenceTypes.res` の配置と責務

`ConfluenceTypes.res` だけが `src/` 直下にあり、他の Confluence 実装は `confluence/` 配下にある。

- このモジュールに置く型は何か？（公開 API 型？ Confluence 固有の内部型？）
- **Confluence 固有の内部型**なら `confluence/` に移すほうが命名規約と一貫する
- **公開 API の型**（`ConvertResult`, `ConvertOptions` 等）なら `AtlassianDocParser.resi` に含めるか、`AtlassianTypes.res` のように名前を変えるほうが意図が伝わる

→ 実装着手時に、このモジュールの責務を明確にしてから配置を確定する。

### Q2: `ConfluenceMarkdownRenderer` と `ConfluenceMarkdownWriter` の分離は MVP で必要か

2モジュールに分ける想定の責務境界:
- **Renderer**: IR ノードツリーを走査して Markdown 構造を決定する
- **Writer**: インデント管理・改行制御など、文字列組み立てのユーティリティ

ただし MVP 段階では Markdown 出力の複雑度が低い可能性がある。最初は 1モジュール（`ConfluenceMarkdownRenderer`）で始め、文字列組み立てロジックが肥大化した時点で Writer を分離する方針も検討に値する。

→ 実装時の判断に委ねる。初期は統合して始めても良い。

### Q3: `namespace: true` によるモジュール参照の冗長性

`rescript.json` に `"namespace": true` が設定されているため、すべてのモジュールは外部から `AtlassianDocParser.ConfluenceInputXml` のように参照される。

- パッケージ内部では `ConfluenceInputXml` で直接参照できるので、内部コードでは問題にならない
- ただし、ReScript のエラーメッセージやコンパイル出力には namespace 付きのフルパスが表示される場合がある
- 実装開始後、モジュール名が長すぎて可読性に影響しないか確認する

→ 実装中に不都合が出たら `module C = ConfluenceInputXml` 等のエイリアスで対処可能。深刻な問題にはならないはず。

### Q4: fixture ファイルのペアリング規約

```
fixtures/xml/basic.xml  <->  fixtures/md/basic.md
```

Golden test でファイル名の一致が暗黙の規約になっている。

- fixture 追加時にペアの片方だけ追加してテストが壊れる（または無視される）リスクがある
- テストランナー側で `xml/` を走査し、同名の `md/` ファイルを自動ペアリングする仕組みを早期に入れると、fixture 追加のたびにテストコードを書き足す手間が省ける

→ テスト実装時に、自動ペアリングの仕組みを検討する。

### Q5: `AtlassianStrictMode_test.res` を独立モジュールにする必要性

strict モードのテストが `AtlassianDocParser_test.res` と別モジュールになっている。

- strict モードは公開 API の `options` 経由で切り替える機能（`006`）なので、`AtlassianDocParser_test.res` 内の describe ブロックとして収容できる可能性がある
- ただし、strict モードのテストケースが多くなる見込みがあれば分離は妥当

→ テスト実装時に、ボリュームを見て判断する。

## ステータス

決定済み
