# Issues - atlassian-doc-parser

ReScript 初心者でも順番に実装を進められるように、MVP 実装を最小単位に分解した issue 一覧。

## 運用ルール

- 1 issue = 1 機能 + 1 テスト
- 作業時間の目安は 45〜90 分
- 変更ファイルは原則 3 ファイル以内（例外は table / integration）
- 完了時は `bun test` を実行して green を確認する
- issue ファイル名は連番なしの `topic-name.md`（kebab-case）形式
- 着手順・依存順は本ファイルの一覧表（行順）で管理する

## 一覧（依存順）

| title | depends_on | file | jump |
|---|---|---|---|
| scaffold 作成 | なし | `scaffold.md` | [Open](./scaffold.md) |
| Types.res 実装 | `scaffold.md` | `types-res.md` | [Open](./types-res.md) |
| Diagnostics 最小実装 | `types-res.md` | `diagnostics-minimal.md` | [Open](./diagnostics-minimal.md) |
| htmlparser2 FFI 追加 | `scaffold.md` | `htmlparser2-ffi.md` | [Open](./htmlparser2-ffi.md) |
| XmlParser 薄ラッパー実装 | `htmlparser2-ffi.md` | `xml-parser.md` | [Open](./xml-parser.md) |
| ConfluenceInputXml 正規化 | `xml-parser.md` | `confluence-input-xml-normalize.md` | [Open](./confluence-input-xml-normalize.md) |
| IrBuilder: heading/paragraph/text | `types-res.md`, `diagnostics-minimal.md`, `confluence-input-xml-normalize.md` | `irbuilder-basic.md` | [Open](./irbuilder-basic.md) |
| IrBuilder: 装飾系（strong/em/code/del） | `irbuilder-basic.md` | `irbuilder-inline-style.md` | [Open](./irbuilder-inline-style.md) |
| IrBuilder: link/image | `irbuilder-basic.md` | `irbuilder-link-image.md` | [Open](./irbuilder-link-image.md) |
| IrBuilder: list | `irbuilder-basic.md` | `irbuilder-list.md` | [Open](./irbuilder-list.md) |
| IrBuilder: table | `irbuilder-basic.md`, `diagnostics-minimal.md` | `irbuilder-table.md` | [Open](./irbuilder-table.md) |
| MarkdownRenderer: text escape | `types-res.md` | `markdownrenderer-escape.md` | [Open](./markdownrenderer-escape.md) |
| MarkdownRenderer: list/table/code fence | `markdownrenderer-escape.md` | `markdownrenderer-structures.md` | [Open](./markdownrenderer-structures.md) |
| AtlassianDocParser 統合 + Error boundary | `diagnostics-minimal.md`, `irbuilder-table.md`, `markdownrenderer-structures.md` | `atlassian-parser-integration.md` | [Open](./atlassian-parser-integration.md) |
| fixture 統合テスト（自動ペアリング） | `atlassian-parser-integration.md` | `fixture-integration-pairing.md` | [Open](./fixture-integration-pairing.md) |
| strict モード総点検 | `atlassian-parser-integration.md`, `fixture-integration-pairing.md` | `strict-mode-audit.md` | [Open](./strict-mode-audit.md) |

## 参照仕様

- 正本: `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx`
- 背景: `docs/niro-knowledge-base/atlassian-doc-parser/01_background.mdx`
- 構成決定: `tmp/discussions/007_rescript-directory-structure.md`
