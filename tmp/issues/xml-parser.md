# Issue: XmlParser 薄ラッパー実装

- status: open
- estimate: 30m
- depends_on: htmlparser2-ffi.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#xmlパース戦略`
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#モジュール責務`

## 目的

XML 文字列を htmlparser2 の DOM ツリーに変換する薄いラッパーモジュールを作る。パース不能時に例外を送出する責務を持つ。

## 背景

正本のモジュール構成では `XmlParser.res` が `Bindings/Htmlparser2.res` と `ConfluenceInputXml.res` の間に位置する。

```
XmlParser.res          ← この issue で作る
  └── Bindings/Htmlparser2.res   ← htmlparser2-ffi issue で作成済み
ConfluenceInputXml.res ← 後続 issue
  └── XmlParser.res
```

htmlparser2 の FFI を直接呼ぶのではなく、このラッパーを経由することで:

- テスト時にパース層を差し替え・モック可能にする
- パースエラーの発生箇所を 1 モジュールに局所化する

## 触るファイル

- `src/XmlParser.res`
- `tests/unit/XmlParser_test.res`

## 実装タスク

1. `parse` 関数を定義し、内部で `Htmlparser2.parseDocument(input, {"xmlMode": true})` を呼ぶ。
2. パースエラー時の例外処理を確認する（htmlparser2 は寛容パーサーのため、空文字列等の境界ケースを検証）。
3. 正常系と境界ケースの unit test を作る。

## ReScript コード例

```rescript
// src/XmlParser.res

// htmlparser2 の DOM ツリーを返す薄ラッパー
let parse = (input: string): Htmlparser2.document => {
  Htmlparser2.parseDocument(input, {"xmlMode": true})
}
```

```rescript
// tests/unit/XmlParser_test.res
open Bun.Test

describe("XmlParser", () => {
  test("parses simple XML", () => {
    let doc = XmlParser.parse("<p>hello</p>")
    // children が存在することを確認
    expect(Array.length(doc.children) > 0)->toBe(true)
  })

  test("parses empty string without throwing", () => {
    let doc = XmlParser.parse("")
    expect(Array.length(doc.children))->toBe(0)
  })
})
```

## 受け入れ条件

- `XmlParser.parse` が unit test で正常動作する。
- 空文字列入力が例外にならず空 document を返す。
