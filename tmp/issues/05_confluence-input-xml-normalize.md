# Issue 05: ConfluenceInputXml 正規化

- status: open
- estimate: 90m
- depends_on: 04
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#ffi境界の型ルール固定`

## 目的

FFI の `Nullable.t` を境界で閉じ込め、`option + variant` の正規化済みノードへ変換する。

## 触るファイル

- `src/ConfluenceInputXml.res`
- `tests/unit/ConfluenceInputXml_test.res`

## 実装タスク

1. `nodeType` variant（`Tag | Text | Cdata | Comment | Other(string)`）を定義する。
2. raw node を正規化 node へ変換する関数を実装する。
3. `children=null` を `[]` にする規約を実装する。
4. 未知 type が `Other(string)` に落ちることをテストする。

## 受け入れ条件

- IrBuilder 以降で `Nullable.t` を使わずに済む。
- 正規化テストが通る。
