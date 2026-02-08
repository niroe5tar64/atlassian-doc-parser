# Issue 06: IrBuilder（heading/paragraph/text）

- status: open
- estimate: 90m
- depends_on: 02,03,05
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#変換マトリクス固定`
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#irbuilderの空白正規化ルール`

## 目的

IR 変換の最小縦スライスとして、見出し・段落・テキストと空白正規化を実装する。

## 触るファイル

- `src/IrBuilder.res`
- `tests/unit/IrBuilder_test.res`

## 実装タスク

1. `<h1>.. <h6>` を `Heading` へ変換する。
2. `<p>` を `Paragraph` へ変換する。
3. テキスト空白正規化（連続空白圧縮・trim）を実装する。
4. 未対応要素を `Unsupported` + warning にする土台を作る。

## 受け入れ条件

- heading/paragraph/text の unit test が通る。
- 空白正規化の固定例が再現できる。
