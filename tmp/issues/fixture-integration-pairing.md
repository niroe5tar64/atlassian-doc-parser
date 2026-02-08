# Issue: fixture 統合テスト（自動ペアリング）

- status: open
- estimate: 75m
- depends_on: atlassian-parser-integration.md
- references:
  - `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx#テスト契約固定`

## 目的

`tests/fixtures/*` を自動走査し、`input.xml` と `expected.md` のペアで統合テストを回す。

## 触るファイル

- `tests/integration/AtlassianDocParser_test.res`
- `tests/fixtures/`（必要な fixture の追加/整理）

## 実装タスク

1. `tests/fixtures/*/input.xml` を列挙する。
2. 同ディレクトリの `expected.md` が存在しない場合は明示的に失敗させる。
3. 各 fixture を parser に通して golden compare する。
4. 初期3 fixture（basic / complex_table_code / mixed_unsupported）を揃える。

## ReScript コード例

### Node.js fs をバインドして fixture を読み込む

```rescript
// テストファイル内で Node.js API を FFI バインディング

// readdirSync: ディレクトリ内のエントリ一覧を取得
@module("node:fs") external readdirSync: string => array<string> = "readdirSync"
@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"
@module("node:fs") external existsSync: string => bool = "existsSync"
```

### fixture の自動ペアリング

```rescript
// tests/integration/AtlassianDocParser_test.res

let fixturesDir = "tests/fixtures"

// fixture ディレクトリを走査して (ディレクトリ名, input.xml, expected.md) のペアを作る
let discoverFixtures = (): array<(string, string, string)> => {
  readdirSync(fixturesDir)
  ->Array.filterMap(entry => {
      let dir = `${fixturesDir}/${entry}`
      let inputPath = `${dir}/input.xml`
      let expectedPath = `${dir}/expected.md`

      if existsSync(inputPath) {
        Some((entry, inputPath, expectedPath))
      } else {
        None  // input.xml がないディレクトリは無視
      }
    })
}

// 各 fixture について動的にテストを生成
let fixtures = discoverFixtures()

describe("Golden Tests", () => {
  fixtures->Array.forEach(((name, inputPath, expectedPath)) => {
    test(`fixture: ${name}`, () => {
      // expected.md がない場合は明示的に失敗
      if !existsSync(expectedPath) {
        // Bun Test では expect().toBe() で意図的に失敗させる
        expect(`missing expected.md for ${name}`)->toBe("")
      } else {
        let inputXml = readFileSync(inputPath, "utf-8")
        let expectedMd = readFileSync(expectedPath, "utf-8")

        let result = AtlassianDocParser.convertConfluenceStorageToMarkdown(inputXml)
        expect(result.markdown)->toBe(String.trim(expectedMd))
      }
    })
  })
})
```

### fixture ディレクトリ構成（正本より）

```
tests/fixtures/
  01_basic/
    input.xml          # 入力 XML
    expected.md        # 期待 Markdown 出力
  02_complex_table_code/
    input.xml
    expected.md
  03_mixed_unsupported/
    input.xml
    expected.md
    warnings.json      # 任意: 期待 warnings
    stats.json         # 任意: 期待 stats
```

### warnings/stats の検証（オプショナル）

```rescript
// warnings.json / stats.json が存在すれば追加検証
let warningsPath = `${dir}/warnings.json`
if existsSync(warningsPath) {
  let expectedWarnings = JSON.parseExn(readFileSync(warningsPath, "utf-8"))
  expect(result.warnings)->toEqual(expectedWarnings)
}
```

## 受け入れ条件

- fixture の silent skip が起きない。
- 3ケース以上で integration test が通る。
