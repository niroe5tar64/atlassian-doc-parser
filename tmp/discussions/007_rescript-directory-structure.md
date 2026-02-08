# 007: ReScript ディレクトリ構成（canonical 同期版）

- **status**: closed
- **date**: 2026-02-08
- **updated**: 2026-02-09
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: ReScript パーサー実装に向けた構成設計

## 背景

2026-02-08 時点では、`ConfluenceXxx` 命名と `confluence/` 配下への分割案を検討した。
その後、2026-02-09 に `docs/niro-knowledge-base/atlassian-doc-parser/02_design.mdx` が正本として確定したため、本ファイルは正本準拠へ同期する。

## 決定

モジュール構成・命名・テスト配置は、正本 `02_design.mdx` の「モジュール構成」に統一する。

```text
atlassian-doc-parser/
├── src/
│   ├── AtlassianDocParser.res     # 公開 API（エントリポイント）
│   ├── Types.res                   # 公開型 + IR 型定義
│   ├── XmlParser.res               # XML 文字列 → DOM ツリー
│   ├── ConfluenceInputXml.res      # DOM 正規化（Nullable.t → option）
│   ├── IrBuilder.res               # DOM ツリー → IR 変換
│   ├── MarkdownRenderer.res        # IR → Markdown 文字列
│   ├── Diagnostics.res             # warning 収集・stats 計算
│   └── Bindings/
│       └── Htmlparser2.res         # htmlparser2 FFI バインディング
├── tests/
│   ├── fixtures/
│   ├── integration/
│   │   └── AtlassianDocParser_test.res
│   └── unit/
│       ├── IrBuilder_test.res
│       ├── MarkdownRenderer_test.res
│       └── Diagnostics_test.res
├── rescript.json
├── package.json
└── biome.json
```

## 命名規約（確定）

1. 公開エントリは `AtlassianDocParser.res` を維持する
2. 共有型は `Types.res` に集約する
3. 変換パイプラインは責務名ベース（`XmlParser`, `IrBuilder`, `MarkdownRenderer`, `Diagnostics`）で命名する
4. FFI 境界正規化は `ConfluenceInputXml.res` に集約する

## テスト配置と命名（確定）

1. テストは `tests/` 配下に分離する
2. テストモジュール名は `*_test.res` を採用する
3. テスト配置は `tests/unit/` と `tests/integration/` に固定する
4. fixture は `tests/fixtures/<NN>_<slug>/input.xml` と `expected.md` を必須ペアとする

## 旧案の扱い

以下は正本確定に伴い撤回済み:

- `ConfluenceXxx` / `JiraXxx` を中心とした命名規約
- `src/confluence/` 配下への分割を前提にした構成
- `fixtures/xml/*.xml` と `fixtures/md/*.md` の分離ペアリング

## ステータス

決定済み
