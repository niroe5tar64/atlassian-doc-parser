# Issues - atlassian-doc-parser

ReScript 初心者でも順番に実装を進められるように、MVP 実装を最小単位に分解した issue 一覧。

## 運用ルール

- 1 issue = 1 機能 + 1 テスト
- 作業時間の目安は 45〜90 分
- 変更ファイルは原則 3 ファイル以内（例外は table / integration）
- 完了時は `bun test` を実行して green を確認する

## 一覧（依存順）

| # | title | depends_on |
|---|---|---|
| 01 | scaffold 作成 | なし |
| 02 | Types.res 実装 | 01 |
| 03 | Diagnostics 最小実装 | 02 |
| 04 | htmlparser2 FFI 追加 | 01 |
| 05 | ConfluenceInputXml 正規化 | 04 |
| 06 | IrBuilder: heading/paragraph/text | 02,03,05 |
| 07 | IrBuilder: 装飾系（strong/em/code/del） | 06 |
| 08 | IrBuilder: link/image | 06 |
| 09 | IrBuilder: list | 06 |
| 10 | IrBuilder: table | 06,03 |
| 11 | MarkdownRenderer: text escape | 02 |
| 12 | MarkdownRenderer: list/table/code fence | 11 |
| 13 | AtlassianDocParser 統合 + Error boundary | 03,10,12 |
| 14 | fixture 統合テスト（自動ペアリング） | 13 |
| 15 | strict モード総点検 | 13,14 |

## 参照仕様

- 正本: `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx`
- 背景: `docs/niro-knowledge-base/atlassian-doc-parser/01_background.mdx`
- 構成決定: `tmp/discussions/007_rescript-directory-structure.md`
