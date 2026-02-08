# Issue: htmlparser2 FFI 追加

- status: open
- estimate: 75m
- depends_on: scaffold.md
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

## ReScript コード例

### @module で npm パッケージの関数をバインドする

```rescript
// src/Bindings/Htmlparser2.res
// ReScript の FFI: JS のライブラリを型付きで呼ぶ仕組み

// htmlparser2 の DOM ノード型を定義
// rec: 型が自分自身を参照する（children が node の配列）
type rec node = {
  @as("type") type_: string,              // JS の予約語 "type" を ReScript では type_ で受ける
  name: Nullable.t<string>,               // JS の null | string を表現
  attribs: Nullable.t<Dict.t<string>>,    // null | { [key: string]: string }
  children: Nullable.t<array<node>>,      // null | node[]
  data: Nullable.t<string>,               // null | string（テキスト/CDATA の内容）
}

// parseDocument の返り値
type document = {children: array<node>}

// @module("パッケージ名") external 関数名: 型 = "JS側の関数名"
@module("htmlparser2")
external parseDocument: (string, {"xmlMode": bool}) => document = "parseDocument"
```

### Nullable.t の基本

```rescript
// Nullable.t<'a> は JS の null | undefined | 'a を表現する型

// JS から返ってきた Nullable 値を option に変換:
let maybeName: Nullable.t<string> = node.name
let nameOpt: option<string> = maybeName->Nullable.toOption

// パターンマッチで使う場合:
switch node.name->Nullable.toOption {
| Some(name) => Console.log(name)
| None => Console.log("no name")
}
```

### テスト例

```rescript
// tests/unit/Htmlparser2Binding_test.res

describe("Htmlparser2", () => {
  test("parseDocument returns children", () => {
    let doc = Htmlparser2.parseDocument("<p>hello</p>", {"xmlMode": true})
    expect(Array.length(doc.children) > 0)->toBe(true)
  })

  test("xmlMode preserves ac: prefix", () => {
    let doc = Htmlparser2.parseDocument(`<ac:link />`, {"xmlMode": true})
    let first = doc.children[0]  // array の index アクセス: option<node> を返す
    switch first {
    | Some(node) => expect(node.name->Nullable.toOption)->toBe(Some("ac:link"))
    | None => expect(true)->toBe(false) // fail: should have a child
    }
  })
})
```

## 受け入れ条件

- `parseDocument` 呼び出しが unit test で成功する。
- `xmlMode: true` でプレフィックス付きタグ名が保持される。
