# Issue: ConfluenceInputXml 正規化

- status: open
- estimate: 90m
- depends_on: xml-parser.md
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

## ReScript コード例

### 正規化後の型を定義する

```rescript
// src/ConfluenceInputXml.res

// htmlparser2 の文字列 type_ を variant に変換
type nodeType = Tag | Text | Cdata | Comment | Other(string)

// 正規化済みノード: Nullable.t が一切ない
type rec xmlNode = {
  nodeType: nodeType,
  name: option<string>,
  attribs: option<Dict.t<string>>,
  children: array<xmlNode>,     // null は [] に正規化済み
  data: option<string>,
}
```

### 文字列を variant に変換するパターンマッチ

```rescript
// 文字列のパターンマッチ: switch で完全一致判定
let parseNodeType = (typeStr: string): nodeType => {
  switch typeStr {
  | "tag" => Tag
  | "text" => Text
  | "cdata" => Cdata
  | "comment" => Comment
  | other => Other(other)   // 未知の type は文字列ごと保持
  }
}
```

### Nullable.t -> option への正規化関数

```rescript
// 再帰関数には rec キーワードが必要
let rec normalizeNode = (raw: Htmlparser2.node): xmlNode => {
  // Nullable.t<array<node>> → array<xmlNode>
  // null の場合は空配列にする
  let children = switch raw.children->Nullable.toOption {
  | Some(kids) => kids->Array.map(normalizeNode)  // 子ノードも再帰的に正規化
  | None => []
  }

  {
    nodeType: parseNodeType(raw.type_),
    name: raw.name->Nullable.toOption,
    attribs: raw.attribs->Nullable.toOption,
    children,
    data: raw.data->Nullable.toOption,
  }
}

// DOM のトップレベルを正規化する公開関数
let fromDom = (doc: Htmlparser2.document): array<xmlNode> => {
  doc.children->Array.map(normalizeNode)
}
```

### テスト例

```rescript
describe("ConfluenceInputXml", () => {
  test("normalizes tag node", () => {
    let doc = XmlParser.parse("<p>hello</p>")
    let nodes = ConfluenceInputXml.fromDom(doc)
    let first = nodes[0]
    switch first {
    | Some({nodeType: Tag, name: Some("p")}) => expect(true)->toBe(true)
    | _ => expect(true)->toBe(false)
    }
  })

  test("unknown type becomes Other", () => {
    let nodeType = ConfluenceInputXml.parseNodeType("directive")
    expect(nodeType)->toEqual(Other("directive"))
  })
})
```

## 受け入れ条件

- IrBuilder 以降で `Nullable.t` を使わずに済む。
- 正規化テストが通る。
