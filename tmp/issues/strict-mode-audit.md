# Issue: strict モード総点検

- status: open
- estimate: 60m
- depends_on: atlassian-parser-integration.md, fixture-integration-pairing.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#変換マトリクス固定`

## 目的

warning category ごとに strict=true の失敗挙動を検証し、契約の抜け漏れをなくす。

## 触るファイル

- `tests/integration/AtlassianStrictMode_test.res`
- `tests/fixtures/`（strict 用 fixture を必要分追加）

## 実装タスク

1. `UNSUPPORTED_ELEMENT` 用 strict ケースを追加する。
2. `UNSUPPORTED_MACRO` 用 strict ケースを追加する。
3. `UNSUPPORTED_INLINE` 用 strict ケースを追加する。
4. `INVALID_STRUCTURE` / `CONVERSION_ERROR` の strict ケースを追加する。

## ReScript コード例

### 例外テストのパターン（Bun Test）

```rescript
// tests/integration/AtlassianStrictMode_test.res

// 例外を throw する関数のテスト: expect に「関数」を渡して toThrow で検証
// Bun Test の toThrow バインディング
type expectResult
@val external expect: 'a => expectResult = "expect"
@send external toThrow: expectResult => unit = "toThrow"

describe("Strict Mode", () => {
  // ヘルパー: strict=true で変換を実行する関数を返す
  let convertStrict = (xml: string) => {
    () => AtlassianDocParser.convertConfluenceStorageToMarkdown(
      xml,
      ~options={strict: ?Some(true)},
    )
  }

  // ヘルパー: strict=false で変換（正常終了するはず）
  let convertLenient = (xml: string) => {
    AtlassianDocParser.convertConfluenceStorageToMarkdown(xml)
  }
})
```

### category ごとのテストケース

```rescript
  // --- UNSUPPORTED_ELEMENT ---
  test("strict: UNSUPPORTED_ELEMENT throws", () => {
    expect(convertStrict("<ac:task-list><ac:task>todo</ac:task></ac:task-list>"))->toThrow
  })
  test("lenient: UNSUPPORTED_ELEMENT warns and continues", () => {
    let result = convertLenient("<ac:task-list><ac:task>todo</ac:task></ac:task-list>")
    expect(Array.length(result.warnings) > 0)->toBe(true)
    expect(result.markdown->String.includes("unsupported"))->toBe(true)
  })

  // --- UNSUPPORTED_MACRO ---
  test("strict: UNSUPPORTED_MACRO throws", () => {
    expect(convertStrict(`<ac:structured-macro ac:name="toc" />`))->toThrow
  })
  test("lenient: UNSUPPORTED_MACRO warns", () => {
    let result = convertLenient(`<ac:structured-macro ac:name="toc" />`)
    expect(result.warnings[0]->Option.getOr("")->String.includes("UNSUPPORTED_MACRO"))->toBe(true)
  })

  // --- UNSUPPORTED_INLINE ---
  test("strict: UNSUPPORTED_INLINE throws", () => {
    expect(convertStrict("<p><ac:emoticon ac:name=\"smile\" /></p>"))->toThrow
  })

  // --- INVALID_STRUCTURE ---
  test("strict: INVALID_STRUCTURE throws", () => {
    // 列数不揃いテーブル等
    expect(convertStrict("<table><tbody><tr><td>A</td><td>B</td></tr><tr><td>C</td></tr></tbody></table>"))->toThrow
  })
```

### strict=true と strict=false の対比テスト

```rescript
  // 同じ入力に対して strict の ON/OFF を比較するパターン
  test("same input: strict throws, lenient succeeds", () => {
    let xml = `<ac:structured-macro ac:name="expand"><ac:rich-text-body><p>hidden</p></ac:rich-text-body></ac:structured-macro>`

    // strict=false: 成功し、warning がある
    let result = convertLenient(xml)
    expect(result.markdown->String.includes("unsupported"))->toBe(true)
    expect(Array.length(result.warnings))->toBe(1)

    // strict=true: 例外になる
    expect(convertStrict(xml))->toThrow
  })
```

### JS 側の Error プロパティ検証（オプショナル）

```rescript
  // 例外の name と code を検証したい場合は try/catch で捕まえる
  test("ConvertError has correct name and code", () => {
    try {
      let _ = AtlassianDocParser.convertConfluenceStorageToMarkdown(
        `<ac:structured-macro ac:name="toc" />`,
        ~options={strict: ?Some(true)},
      )
      expect(true)->toBe(false)  // ここに来たら失敗
    } catch {
    | exn => {
        // ReScript の Exn モジュールで JS Error のプロパティにアクセス
        let jsExn = exn->Exn.asJsExn
        let name = jsExn->Option.flatMap(Exn.name)
        expect(name)->toBe(Some("ConvertError"))
      }
    }
  })
```

## 受け入れ条件

- 各 category で strict=true が `StrictModeViolation` になる。
- strict=false は warning 記録で継続する比較テストがある。
