# Issue: IrBuilder（heading/paragraph/text）

- status: open
- estimate: 90m
- depends_on: types-res.md, diagnostics-minimal.md, confluence-input-xml-normalize.md
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

## ReScript コード例

### 要素名でパターンマッチして IR に変換する

```rescript
// src/IrBuilder.res
// xmlNode を受け取り、タグ名に応じた IR ノードを構築する再帰関数

// ブロックレベルノードの変換
let rec buildBlock = (
  node: ConfluenceInputXml.xmlNode,
  diag: Diagnostics.t,
  ~strict: bool,
): Types.blockNode => {
  switch (node.nodeType, node.name) {
  // <h1> ~ <h6>
  | (Tag, Some("h1")) => Heading({level: 1, children: buildInlineChildren(node, diag, ~strict)})
  | (Tag, Some("h2")) => Heading({level: 2, children: buildInlineChildren(node, diag, ~strict)})
  // ... h3~h6 も同様

  // <p>
  | (Tag, Some("p")) => Paragraph(buildInlineChildren(node, diag, ~strict))

  // 未対応要素: Unsupported ノード + warning を記録
  | (Tag, Some(name)) => {
      Diagnostics.addWarning(diag, `[UNSUPPORTED_ELEMENT] ${name}`)
      Diagnostics.incrementUnsupported(diag)
      if strict {
        raise(Types.ConvertError({code: StrictModeViolation, message: `Unsupported element: ${name}`}))
      }
      Unsupported(name)
    }
  | _ => Unsupported("unknown")
  }
}

// インライン子要素をまとめて変換するヘルパー
and buildInlineChildren = (
  node: ConfluenceInputXml.xmlNode,
  diag: Diagnostics.t,
  ~strict: bool,
): array<Types.inlineNode> => {
  node.children->Array.map(child => buildInline(child, diag, ~strict))
}

// インラインノードの変換
and buildInline = (
  node: ConfluenceInputXml.xmlNode,
  diag: Diagnostics.t,
  ~strict: bool,
): Types.inlineNode => {
  switch (node.nodeType, node.name) {
  | (Text, _) => {
      // テキスト空白正規化: 連続空白を圧縮し、前後を trim
      let text = node.data->Option.getOr("")
      Text(normalizeWhitespace(text))
    }
  | _ => Text("")
  }
}
```

### 空白正規化

```rescript
// 連続する空白文字（スペース、タブ、改行）を単一スペースに圧縮し、前後を trim
let normalizeWhitespace = (text: string): string => {
  text
  ->String.replaceRegExp(%re("/\s+/g"), " ")  // %re("/.../") は正規表現リテラル
  ->String.trim
}
```

### テスト例

```rescript
describe("IrBuilder", () => {
  // テストヘルパー: XML 文字列 → IR document を一発で取得
  let buildFromXml = (xml: string): Types.document => {
    let doc = XmlParser.parse(xml)
    let nodes = ConfluenceInputXml.fromDom(doc)
    let diag = Diagnostics.create()
    IrBuilder.build(nodes, diag, ~strict=false)
  }

  test("B01: heading h1", () => {
    let doc = buildFromXml("<h1>Title</h1>")
    let first = doc.children[0]
    switch first {
    | Some(Heading({level: 1, children: [Text("Title")]})) =>
      expect(true)->toBe(true)
    | _ => expect(true)->toBe(false)
    }
  })

  test("B04: paragraph", () => {
    let doc = buildFromXml("<p>Text</p>")
    switch doc.children[0] {
    | Some(Paragraph([Text("Text")])) => expect(true)->toBe(true)
    | _ => expect(true)->toBe(false)
    }
  })
})
```

### 補足: `and` キーワード

`and` は相互再帰する関数や型を定義するキーワード。`buildBlock` と `buildInline` が互いを呼ぶ場合に必要。

## 受け入れ条件

- heading/paragraph/text の unit test が通る。
- 空白正規化の固定例が再現できる。
