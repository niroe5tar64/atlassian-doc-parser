# Issue: AtlassianDocParser 統合 + Error boundary

- status: open
- estimate: 90m
- depends_on: diagnostics-minimal.md, irbuilder-table.md, markdownrenderer-structures.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#公開api`
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#converterror`

## 目的

`XmlParser -> IrBuilder -> MarkdownRenderer -> Diagnostics` を公開APIで統合し、ConvertError を JS Error に変換する。

## 触るファイル

- `src/AtlassianDocParser.res`
- `src/AtlassianDocParser.resi`
- `tests/integration/AtlassianDocParser_test.res`

## 実装タスク

1. `convertConfluenceStorageToMarkdown` の本体を実装する。
2. options.strict の default `false` を実装する。
3. internal exception を catch して JS Error（`name=ConvertError`, `code`）に変換する。
4. integration test で成功系と失敗系を確認する。

## 受け入れ条件

- 成功時に `markdown/warnings/stats` が返る。
- strict違反時に JS 側で `name` と `code` が判定できる。
