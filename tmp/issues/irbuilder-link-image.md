# Issue: IrBuilder（link/image）

- status: open
- estimate: 90m
- depends_on: irbuilder-basic.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#変換マトリクス固定`

## 目的

外部リンク、内部リンク、外部画像、添付画像を仕様どおりに変換する。

## 触るファイル

- `src/IrBuilder.res`
- `tests/unit/IrBuilder_test.res`

## 実装タスク

1. `<a href>` -> `Link` を実装する。
2. `ac:link + ri:page` -> `confluence-internal://...` を実装する。
3. `ac:image + ri:url` -> `Image(url)` を実装する。
4. `ac:image + ri:attachment` -> `confluence-attachment://...` を実装する。

## ReScript コード例

### Dict.t から属性を取得する

```rescript
// ConfluenceInputXml.xmlNode の attribs は option<Dict.t<string>>
// Dict.get で属性値を取り出す（option<string> を返す）

let getAttr = (node: ConfluenceInputXml.xmlNode, key: string): option<string> => {
  node.attribs->Option.flatMap(attrs => attrs->Dict.get(key))
}

// 使い方:
let href = getAttr(node, "href")           // <a href="...">
let macroName = getAttr(node, "ac:name")   // <ac:structured-macro ac:name="code">
```

### 外部リンク: `<a href>` → Link

```rescript
| (Tag, Some("a")) => {
    let href = getAttr(node, "href")->Option.getOr("")
    Link({href, children: buildInlineChildren(node, diag, ~strict)})
  }
```

### 内部リンク: `ac:link` + `ri:page` → confluence-internal://

```rescript
| (Tag, Some("ac:link")) => {
    // 子要素から ri:page を探す
    let riPage = node.children->Array.find(c =>
      c.nodeType == Tag && c.name == Some("ri:page")
    )
    // spaceKey と title を抽出
    let spaceKey = riPage->Option.flatMap(p => getAttr(p, "ri:space-key"))
    let title = riPage->Option.flatMap(p => getAttr(p, "ri:content-title"))

    let href = switch (spaceKey, title) {
    | (Some(sk), Some(t)) => `confluence-internal://${sk}/${encodeURIComponent(t)}`
    | (None, Some(t)) => `confluence-internal:///${encodeURIComponent(t)}`
    | _ => "confluence-internal://"
    }

    // リンクテキスト: ac:plain-text-link-body の CDATA、なければ title
    let linkText = extractLinkText(node)->Option.getOr(title->Option.getOr(""))
    Link({href, children: [Text(linkText)]})
  }
```

### encodeURIComponent を FFI で呼ぶ

```rescript
// グローバル関数の FFI は @val で宣言
@val external encodeURIComponent: string => string = "encodeURIComponent"

// 使い方: encodeURIComponent("Target Page") => "Target%20Page"
```

### テスト例

```rescript
test("B14: internal link with spaceKey", () => {
  let xml = `<ac:link><ri:page ri:content-title="Target Page" ri:space-key="PROJ" /><ac:plain-text-link-body><![CDATA[Link Text]]></ac:plain-text-link-body></ac:link>`
  let doc = buildFromXml(`<p>${xml}</p>`)
  switch doc.children[0] {
  | Some(Paragraph([Link({href, children: [Text("Link Text")]})])) =>
    expect(href)->toBe("confluence-internal://PROJ/Target%20Page")
  | _ => expect(true)->toBe(false)
  }
})
```

## 受け入れ条件

- link/image の4パターンが unit test で通る。
- これらは warning を出さない。
