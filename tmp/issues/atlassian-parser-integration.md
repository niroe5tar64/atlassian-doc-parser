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

## ReScript コード例

### パイプライン統合（正本のモジュール責務に対応）

```rescript
// src/AtlassianDocParser.res

let convertConfluenceStorageToMarkdown = (
  input: string,
  ~options: convertOptions=?,
) => {
  try {
    // options からフラグを取り出す（Option のネスト展開）
    let strict = options
      ->Option.flatMap(o => o.strict)  // option<convertOptions> → option<bool>
      ->Option.getOr(false)            // None なら false

    let diagnostics = Diagnostics.create()

    // 1. XML パース（XmlParser → htmlparser2 DOM）
    let dom = try {
      XmlParser.parse(input)
    } catch {
    | exn => {
        let msg = exn->Exn.asJsExn->Option.flatMap(Exn.message)->Option.getOr("Unknown parse error")
        raise(ConvertError({code: InvalidXml, message: msg}))
      }
    }

    // 2. DOM 正規化（Nullable.t → option）
    let normalized = ConfluenceInputXml.fromDom(dom)

    // 3. IR 構築
    let document = IrBuilder.build(normalized, diagnostics, ~strict)

    // 4. Markdown レンダリング
    let markdown = MarkdownRenderer.render(document)

    // 5. 結果組み立て
    {
      markdown,
      warnings: Diagnostics.getWarnings(diagnostics),
      stats: ?Diagnostics.getStats(diagnostics),  // ? は optional フィールドへの代入
    }
  } catch {
  // 6. Boundary: ReScript exception → JS Error
  | ConvertError({code, message}) =>
    throwJsConvertError(convertErrorCodeToString(code), message)
  | exn => {
      let msg = exn->Exn.asJsExn->Option.flatMap(Exn.message)->Option.getOr("Internal error")
      throwJsConvertError("InternalError", msg)
    }
  }
}
```

### %raw で JS を直接書く（boundary ヘルパー）

```rescript
// %raw は JS コードをそのまま埋め込む仕組み。FFI で表現しにくい処理に使う。
// ここでは JS の Error オブジェクトを構築して throw する。
let throwJsConvertError: (string, string) => 'a = %raw(`
  function(code, message) {
    var e = new Error(message);
    e.name = 'ConvertError';
    e.code = code;
    throw e;
  }
`)

let convertErrorCodeToString = (code: convertErrorCode): string =>
  switch code {
  | InvalidXml => "InvalidXml"
  | StrictModeViolation => "StrictModeViolation"
  | InternalError => "InternalError"
  }
```

### テスト例

```rescript
describe("AtlassianDocParser", () => {
  test("converts simple XML to markdown", () => {
    let result = AtlassianDocParser.convertConfluenceStorageToMarkdown("<h1>Title</h1>")
    expect(result.markdown)->toBe("# Title")
    expect(Array.length(result.warnings))->toBe(0)
  })

  test("returns warnings for unsupported macros", () => {
    let xml = `<ac:structured-macro ac:name="toc" />`
    let result = AtlassianDocParser.convertConfluenceStorageToMarkdown(xml)
    expect(Array.length(result.warnings) > 0)->toBe(true)
  })

  test("strict mode throws ConvertError", () => {
    let xml = `<ac:structured-macro ac:name="toc" />`
    // 例外テスト: expect の中で関数を渡し、toThrow で検証
    expect(() => {
      AtlassianDocParser.convertConfluenceStorageToMarkdown(xml, ~options={strict: ?Some(true)})
    })->toThrow
  })
})
```

## 受け入れ条件

- 成功時に `markdown/warnings/stats` が返る。
- strict違反時に JS 側で `name` と `code` が判定できる。
