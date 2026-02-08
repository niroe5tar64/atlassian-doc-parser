# Issue 04: htmlparser2 FFI 追加

- status: open
- estimate: 75m
- depends_on: 01
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#xmlパース戦略`

## 目的

`htmlparser2.parseDocument` を ReScript から呼び出せる最小 FFI バインディングを作る。

## 触るファイル

- `src/Bindings/Htmlparser2.res`
- `tests/unit/Htmlparser2Binding_test.res`

## 実装タスク

1. raw node 型（`Nullable.t` を含む）を定義する。
2. `parseDocument(input, {xmlMode: true})` を呼ぶ外部関数を定義する。
3. 最小 XML 文字列が parse できる smoke test を作る。

## 受け入れ条件

- `parseDocument` 呼び出しが unit test で成功する。
- `xmlMode: true` でプレフィックス付きタグ名が保持される。
