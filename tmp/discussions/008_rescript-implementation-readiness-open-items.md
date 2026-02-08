# 008: ReScript 実装前の追加論点（未経験者が詰まりやすい箇所）

- **status**: closed
- **date**: 2026-02-08
- **decided**: 2026-02-09
- **participants**: ユーザー, Codex (GPT-5), Claude Opus 4.6
- **origin**: 実装着手前の追加論点洗い出し

## 背景

既存の論点（001〜007）と詳細設計で、MVP 方針と実装骨格は確定している。
一方で、ReScript 未経験者が実装開始時にハマりやすい運用・境界条件がいくつか残っている。

## ゴール

実装フェーズで手戻りや混乱を起こしやすい論点を先に明示し、短サイクルで決定できる状態にする。

---

## 決定事項

### 1. テスト実行契約の統一

**決定: Bun Test を採用**

- **テストランナー**: Bun 内蔵テストランナー（`bun test`）
- **テスト実行コマンド**: `bun test`（CI/ローカル共通）
- **テスト命名規約**: `*_test.res`（007 で確定済み）
- **rescript.json の suffix**: `.res.mjs` → **`.js`** に変更
  - `*_test.res` → `*_test.js` にコンパイルされ、Bun Test のデフォルトパターン `*_test.{js}` で自動検出される
- **vitest**: devDependencies から削除
- **package.json の test script**: `"test": "bun test"` に変更

**選定理由**:
1. vitest はセットアップ時の先読みで入れたものであり、必須ではない
2. bun は既にパッケージマネージャとして採用済みで、テストランナーも統一するのが自然
3. 追加依存ゼロで最も薄い構成
4. suffix を `.js` に変更することで、Bun Test のデフォルト検出パターンと完全に一致（実機検証済み）
5. `CLAUDECODE=1` 環境変数で AI エージェント向け出力最適化に対応

**実機検証結果**:
- `.res.mjs` suffix: Bun Test のデフォルトパターン `**{.test,.spec,_test_,_spec_}.{js,ts,jsx,tsx}` に合致しない（拡張子 `.mjs` が対象外）
- `.js` suffix + `*_test` 命名: Bun Test で自動検出されることを確認済み

### 2. ドキュメント間の構成ズレ

**決定: 007 + rescript.json を canonical（正）とする**

- **ディレクトリ名**: `tests/`（複数形。`rescript.json` と一致）
- **モジュール命名**: `ConfluenceXxx`（007 で確定済み）
- **テスト構造**: `tests/unit/` + `tests/integration/`（007 で確定済み）
- **fixture 構造**: ケース単位のディレクトリ構成を採用
  ```
  tests/fixtures/
    01_basic/
      input.xml
      expected.md
    02_complex_table_code/
      input.xml
      expected.md
  ```
- `detailed-design.md` のディレクトリ構造セクション（`test/` 表記、`Types.res`/`XmlParser.res` 命名）は 007 より前の概略であり、実装は 007 の構成に従う
- ドキュメントの同期は実装完了後にまとめて行う

### 3. Markdown エスケープ規則

**決定: Text ノード出力時にバックスラッシュエスケープ**

| コンテキスト | エスケープ対象 | 方法 |
|-------------|-------------|------|
| Text ノード（通常位置） | `\` `*` `_` `[` `]` `` ` `` `<` `>` | バックスラッシュ |
| Text ノード（テーブルセル内） | 上記 + `\|` | バックスラッシュ |
| InlineCode / CodeBlock | なし | リテラル出力 |
| Link/Image URL | なし | そのまま出力 |
| MarkdownRenderer が意図的に出力する HTML（`<br>` 等） | なし | そのまま出力 |

**実装場所**: MarkdownRenderer の Text ノード出力時。コンテキスト引数でテーブルセル内かどうかを判別する。

**エスケープしない文字とその理由**:
- `#`: 行頭でなければ意味を持たない。Text ノードは Heading 内のインライン位置にあり、`#` マーカーは MarkdownRenderer が制御する
- `-`, `+`: 行頭でのみリスト項目として解釈。インライン位置では安全
- `!`: `![` の組み合わせでのみ意味を持つが、`[` をエスケープ済みなので安全

### 4. 空白・改行の正規化ルール

**決定: IrBuilder で HTML 相当の空白正規化を実施**

| ルール | 処理 | 理由 |
|--------|------|------|
| 要素間のホワイトスペースのみのテキストノード | **無視する** | XML のインデント/改行でありコンテンツではない |
| テキストノード内の連続空白 | **単一スペースに圧縮** | HTML と同じ正規化（Confluence は XHTML ベース） |
| テキストノードの先頭・末尾の空白 | **trim する** | ただし前後にインライン要素がある場合はスペース 1 つを維持 |
| CDATA 内 | **そのまま保持** | コードブロックのコンテンツであり空白は意味を持つ |
| `<br />` 要素 | LineBreak ノードに変換 | 設計確定済み |
| 段落間の空行 | MarkdownRenderer が挿入 | IR レベルでは制御しない |

**具体例**:
```
<p>Hello   world</p>        → Text("Hello world")     連続空白を圧縮
<p>\n  Hello\n</p>           → Text("Hello")           前後の改行+空白を trim
<p>Hello <strong>bold</strong> text</p>
  → Text("Hello "), Strong([Text("bold")]), Text(" text")   インライン境界の空白は維持
<![CDATA[  code  ]]>         → "  code  "               そのまま保持
```

### 5. htmlparser2 FFI 境界の型方針

**決定: ConfluenceInputXml で Nullable.t → option に即座正規化**

**層の構造**:
```
Htmlparser2.res (FFI バインディング)
  └─ 生の Nullable.t を持つ node 型を定義
  └─ parseDocument() を外部関数として宣言

ConfluenceInputXml.res (FFI 境界の正規化レイヤー)
  └─ Htmlparser2.node → 正規化済み xmlNode 型に変換
  └─ Nullable.t → option に一括変換
  └─ type_ 文字列 → nodeType variant に変換
  └─ children: Nullable.t<array<node>> → array<xmlNode>（空配列で正規化）

IrBuilder.res 以降
  └─ option と variant のみ使用。Nullable.t は一切出現しない
```

**正規化後の型**:
```rescript
type nodeType = Tag | Text | Cdata | Comment | Other(string)

type rec xmlNode = {
  nodeType: nodeType,
  name: option<string>,
  attribs: option<Dict.t<string>>,
  children: array<xmlNode>,
  data: option<string>,
}
```

**効果**:
- `Nullable.t` が FFI 層（Htmlparser2.res + ConfluenceInputXml.res）に完全に閉じ込められる
- IrBuilder 以降は ReScript ネイティブの `option` とパターンマッチのみで実装できる
- 007 Q1（`ConfluenceTypes.res` の配置）も解決: 正規化済み型は `ConfluenceInputXml.res` に配置

### 6. exception と JS Error の boundary 運用規約

**決定: detailed-design.md で確定済み（追加決定不要）**

- **ConvertError を生成してよいモジュール**: 全内部モジュール（IrBuilder, XmlParser 等）
- **catch して JS Error に変換する唯一の場所**: `AtlassianDocParser.res`（公開 API エントリポイント）
- **それ以外の層**: 例外をそのまま上に伝播（catch しない、変換しない）

---

## 設定ファイルへの反映事項

論点 1 の決定に伴い、以下の設定変更が必要:

1. **rescript.json**: `"suffix": ".res.mjs"` → `"suffix": ".js"`
2. **package.json**: `"test": "vitest run"` → `"test": "bun test"`
3. **package.json**: devDependencies から `vitest` を削除
4. **.gitignore**: ReScript ビルド成果物のパターンを suffix 変更に合わせて更新

---

## Phase 3a 実装着手の完了条件

以下がすべて満たされた状態で、迷わず実装に入れる:

1. [x] 6 論点すべてが決定済み
2. [ ] 設定ファイル（rescript.json, package.json）が決定内容に合わせて更新済み
3. [ ] `bun test` でテストが検出・実行されることを smoke test で確認済み
4. [ ] 007 のディレクトリ構成に沿った空のファイル/ディレクトリが作成済み（scaffold）

## ステータス

決定済み
