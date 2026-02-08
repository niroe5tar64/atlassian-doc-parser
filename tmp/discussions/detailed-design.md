# atlassian-doc-parser 詳細設計

- **status**: approved（レビュー完了）
- **date**: 2026-02-07
- **phase**: Phase 2（parser 詳細設計）

---

## 引き継ぎ情報

### 本セッションで実施した内容

1. `tmp/development-plan.md` の Phase 2 チェックリスト全項目を対象に詳細設計ドキュメントを作成
2. 既存ディスカッション（`tmp/atlassian-doc-parser/discussions/001〜006`）の決定事項を前提として詳細化
3. Confluence Storage Format の XML 構造を調査（[公式ドキュメント](https://confluence.atlassian.com/doc/confluence-storage-format-790796544.html)参照）

### 本セッションで決定した事項

| 項目 | 決定 | 根拠 |
|------|------|------|
| ConvertError の ReScript 表現 | 内部は `exception`、公開 API の boundary で JS Error に変換して re-throw（案D） | 再帰的木走査での早期脱出に exception が最適。JS 側には proper な Error（`.name`/`.code`/`.stack`）を提供。**確定** |
| XML パースライブラリ | htmlparser2 のみ（domutils 不使用） | バンドルサイズ最小・フラグメント対応・エラー耐性。domutils は DOM 探索用ユーティリティでありオーバースペック。ノードのプロパティ直接アクセスで十分。**確定** |
| 内部リンクの href | `confluence-internal://` スキームで Link ノード出力（warning なし） | パーサーは URL 解決せず消費者が解決。ri:attachment と同じパターン。**確定** |
| 添付画像の出力形式 | `confluence-attachment://` スキームで Image ノード出力（warning なし） | `confluence-internal://` と同パターン。パーサーはデータを完全に抽出し、URL 解決は消費者の責務。**確定** |
| IR の block/inline 分離 | listItem は `array<blockNode>`、tableCell は `array<inlineNode>` で維持。Image は inlineNode のみ | Markdown の構造的制約に忠実。テーブルセル内ブロック要素は IrBuilder で段階的インライン化。Image はブロック位置では Paragraph ラップで対応（出力に差なし）。**確定** |
| テーブルセル内ブロック要素 | IrBuilder で段階的にインライン化。`<p>` アンラップ、複数 `<p>` / リスト等は `<br>` で結合 | GFM テーブルはブロック要素非対応。`<br>` HTML タグは主要レンダラー（GitHub, VS Code）で対応済み。リストは `- Item<br>- Item` 形式で構造を保持。**確定** |
| HardBreak の削除 | IR から `HardBreak` を削除し `LineBreak` のみに統一 | HardBreak は対応する入力要素も出力形式も未定義。`<br />` → `LineBreak` で十分。**確定** |
| ネストリストのインデント幅 | マーカー幅ベース（`- ` → 2、`N. ` → digits(N)+2） | CommonMark/GFM 準拠。2 スペース固定では ordered list のネストが GitHub で正しく表示されない。**確定** |

### 次のアクション

1. **本ドキュメントのレビュー** → 下記「レビューチェックリスト」の全項目を確認
2. レビュー完了後、`development-plan.md` の Phase 2 チェックリストを更新
3. Phase 2 完了条件（型レベルの定義完了、fixture 確定、設計だけで実装着手可能）の充足を判断
4. Phase 3a（リポジトリ作成 + 実装）へ移行

### 関連ファイル一覧

| ファイル | 内容 |
|---------|------|
| `tmp/development-plan.md` | 全体開発計画（Phase 2 チェックリスト） |
| `tmp/atlassian-doc-parser/discussions/001〜006` | 基本設計ディスカッション（全 closed） |
| `tmp/confluence-mirror/discussions/014_carryover-open-items.md` | 持ち越し課題一覧 |
| `tmp/confluence-mirror/03_specifications.mdx` | 基本設計（技術仕様） |
| `tmp/confluence-mirror/02_requirements.mdx` | 要件定義 |

---

## レビューチェックリスト

以下の項目を確認し、承認 or 修正指示をお願いします。

### 設計判断（要承認）

- [x] **XML パースライブラリ: htmlparser2 のみ採用（domutils 不使用）**（セクション 3）→ **承認済み**
  - htmlparser2 の `parseDocument()` で DOM ツリー構築、ノードの `.type/.name/.attribs/.children/.data` に直接アクセス
  - domutils は DOM 探索用ユーティリティでありオーバースペック。バンドルサイズ・設計スコープを抑えるため不使用
  - ストリーミング方式は不採用（ネスト構造の変換に状態機械が必要になり複雑化するため）
- [x] **内部リンク（ac:link）に `confluence-internal://` スキームを使用**（セクション 4.6b）→ **承認済み**
  - `Link` ノードとして出力。`confluence-internal://{spaceKey}/{encodedTitle}` 形式
  - warning なし・stats 影響なし・strict モード影響なし（ri:attachment と同パターン）
  - 消費者（confluence-mirror）が GAS 配信時にリンク解決（同カテゴリ → 相対リンク / その他 → unsupported）
- [x] **添付画像（ri:attachment）に `confluence-attachment://` スキームを使用**（セクション 4.7b）→ **承認済み**
  - `confluence-internal://` と同パターン。warning なし・stats 影響なし・strict 例外なし
  - パーサーがデータを完全に抽出し、URL 解決は消費者の責務
- [x] **`<u>`, `<sub>`, `<sup>` はテキスト内容のみ出力（warning なし）**（セクション 4.8）→ **承認済み**
  - 標準 Markdown で表現不可（下線・下付き・上付きに対応する構文がない）
  - 重要度: Low（装飾は失われるが文意は保持される）
  - `UnsupportedInline` / HTML コメント挿入は過剰（読者へのノイズになるだけで実益がない）
  - `<sub>` / `<sup>` は将来的に Pandoc-style（`~`, `^`）での出力を検討可能だが、ターゲット Markdown が限定されるため現フェーズでは非対応
- [x] **`<del>` / `<s>` は GFM `~~text~~` で出力**（セクション 4.8）→ **承認済み**
  - 重要度: Medium（取り消し線は「この部分は無効」という意味論的マークアップであり、純粋な見た目装飾とは質が異なる）
  - GFM 拡張依存だが、GitHub / VS Code プレビュー等の主要レンダラーで対応済み
  - 実装コストは極めて低い（`Strong` と同等パターンの `Strikethrough(children)` IR ノード → `~~` ラップ）
- [x] **添付画像は strict モードでも例外にしない**（セクション 6）→ **承認済み**
  - `confluence-attachment://` スキーム方式のため ATTACHMENT_REF カテゴリ自体が不要に

### 型定義・構造（要確認）

- [x] **ConvertError を ReScript exception + JS boundary wrapper で定義（案D）**（セクション 1）→ **承認済み**
  - 内部: ReScript `exception ConvertError(...)` で再帰走査からの早期脱出に使用
  - 公開 API boundary: catch → JS `Error`（`.name = 'ConvertError'`, `.code`, `.stack`）に変換して re-throw
  - Result 型（案C）は再帰的木走査の全階層でエラー伝播が必要になり煩雑。エラーの性質（即座に中断）に exception が適合
  - JS 側の判別: `e.name === 'ConvertError'` + `e.code`。`instanceof ConvertError` は不要（消費者は自前コードのみ）
  - npm 公開時に `class ConvertError extends Error` へ昇格可能（現時点では YAGNI）
- [x] **IR の blockNode / inlineNode 分離構造**（セクション 2）→ **承認済み**
  - listItem が `array<blockNode>` を含む（ネストリスト対応）→ 妥当。Markdown の構造的制約に忠実
  - tableCell は `array<inlineNode>` のみ含む → 妥当。セル内ブロック要素は IrBuilder で段階的にインライン化（セクション 4.4 に処理方針追記）
  - Image は inlineNode に分類 → 現状維持。ブロック位置の画像は Paragraph ラップで対応。Markdown 出力に差がないため型を分ける実益なし
- [x] **IR に HardBreak と LineBreak を両方持つ必要があるか**（セクション 2）→ **LineBreak のみに統一**
  - HardBreak は対応する入力要素（Confluence 側）も出力形式（Markdown 側）も未定義であり、用途がない
  - `<br />` → `LineBreak` → 末尾 2 スペース + 改行（テーブルセル内では `<br>` HTML タグ）で十分

### テスト・fixture（要確認）

- [x] **テストケース一覧の網羅性**（セクション 7）→ **レビューで B25〜B30 / C13〜C17 を追加して承認**
  - IrBuilder: B01〜B30（30 ケース）— B25〜B30 はレビューで追加（del/s, u/sub/sup, テーブルセル内ブロック, ネストインライン, strict モード）
  - MarkdownRenderer: C01〜C17（17 ケース）— C13〜C17 はレビューで追加（Strikethrough, HorizontalRule, LineBreak, Table ヘッダーなし, UnsupportedInline）
  - Diagnostics: D01〜D04（4 ケース）
- [x] **初期 fixture 3 件の入力 XML と期待出力**（セクション 8）→ **レビューで em/code/br, 言語なしコードブロック, hr/del/sup/添付画像を追加。インデント幅をマーカー幅ベースに変更して承認**
  - Fixture 01: basic（見出し、段落、strong、em、外部リンク、インラインコード、改行、箇条書きリスト）
  - Fixture 02: complex_table_code（テーブル、コードブロック（言語付/なし）、インラインコード）
  - Fixture 03: mixed_unsupported（ネストリスト、画像（外部/添付）、内部リンク、del、sup、水平線、未対応マクロ）

### 全体確認

- [x] **モジュール構成と責務分担に問題がないか**（セクション 5）→ **承認済み**
  - 責務分離が明確で依存方向も一方向（循環なし）
  - Diagnostics の Ref ベース可変コンテナは再帰走査の実装簡潔化のため実利的に妥当
  - XmlParser の薄いラッパーはテスタビリティのためモジュール分離を維持
  - FFI バインディングの `Nullable.t` 等は Phase 3a で実際の ReScript バージョンに合わせて調整
- [x] **warning コード体系に過不足がないか**（セクション 6）→ **承認済み**
  - 5 カテゴリ（UNSUPPORTED_ELEMENT / UNSUPPORTED_MACRO / UNSUPPORTED_INLINE / CONVERSION_ERROR / INVALID_STRUCTURE）は MVP に対して必要十分
  - stats 連動・strict モード連動の一貫性あり
  - CONVERSION_ERROR と「空セル埋め」の stats 連動の細部は Phase 3a 実装時に判断
- [x] **未決事項の対応タイミングは妥当か**（セクション 9）→ **承認済み**
  - 全項目のタイミングが妥当。#2（Markdown エスケープ）と #5（空白正規化）は Phase 3a 実装の早い段階で方針確定すべき
- [x] **本ドキュメントの内容で Phase 3a の実装に着手できるか**（Phase 2 完了条件）→ **充足確認済み**
  - 公開 API 型・IR 型・変換ルール・モジュール構成・warning 体系・テストケース・fixture が全て定義済み
  - 未決事項は全て Phase 3a 実装時判断で可（ブロッカーなし）

---

## 前提（決定済み事項）

以下はディスカッション 001〜006 で確定済み。本ドキュメントはこれらを前提として詳細化する。

| 項目 | 決定内容 | 参照 |
|------|----------|------|
| 公開 API | `ConvertResult`（markdown + warnings + stats） | 002 |
| アーキテクチャ | XML → IR → Markdown の 2 段階変換 | 003 |
| 未対応要素 | プレースホルダー（Markdown コメント）+ warnings | 004 |
| エラーハンドリング | Best Effort（default）/ Strict モード | 006 |
| テスト戦略 | fixture ベース Unit テスト、初期 3 件 | 005 |
| パッケージ運用 | `0.x` 系、初期は `file:` ローカル参照 | 005 |

---

## 1. 公開 API 型定義（ReScript）

### ConvertOptions / ConvertResult

```rescript
// === Public API Types ===

type convertStats = {
  unsupportedNodeCount: int,
  macroCount: int,
}

type convertOptions = {
  strict?: bool, // default: false
}

type convertResult = {
  markdown: string,
  warnings: array<string>,
  stats?: convertStats,
}
```

### ConvertError

**方式: Exception + JS boundary wrapper（案D）**

ReScript 内部では `exception` として定義し、公開 API のエントリポイント（boundary）で JS の `Error` オブジェクトに変換して re-throw する。

#### 設計判断の根拠

| 検討案 | 概要 | 採否 | 理由 |
|--------|------|------|------|
| 案A: ReScript exception のまま | 内部 exception をそのまま JS に露出 | 不採用 | ReScript exception は `Error` のサブクラスにならず、`instanceof Error` が false、`.stack` なし。JS 側で型安全な判別不可 |
| 案B: JS Error を直接 throw | `Js.Exn.raiseError` 等で JS Error を投げる | 不採用 | ReScript 側でパターンマッチ不可。code フィールドの付与に工夫が要る |
| 案C: Result 型 + boundary wrapper | 内部は `result` 型、boundary で throw に変換 | 不採用 | 再帰的木走査の全階層で `Result.map`/`Result.flatMap` によるエラー伝播が必要になり、コードが著しく煩雑化。ConvertError は「即座に中断」する性質であり、値として合成する必要がない |
| **案D: Exception + boundary wrapper** | 内部は exception、boundary で JS Error に変換 | **採用** | ReScript 側はパターンマッチ + 早期脱出。JS 側は proper な Error（`.name`/`.code`/`.stack`）。boundary は公開 API 1 箇所のみで実装コスト極小 |

#### ReScript 内部定義

```rescript
type convertErrorCode =
  | InvalidXml
  | StrictModeViolation
  | InternalError

exception ConvertError({code: convertErrorCode, message: string})
```

#### JS boundary wrapper

公開エントリポイント（`AtlassianDocParser.res`）で ReScript exception を catch し、JS の `Error` に変換して re-throw する。

```rescript
// JS Error を throw するヘルパー
let throwJsConvertError: (string, string) => 'a = %raw(`
  function(code, message) {
    var e = new Error(message);
    e.name = 'ConvertError';
    e.code = code;
    throw e;
  }
`)

let convertErrorCodeToString = code =>
  switch code {
  | InvalidXml => "InvalidXml"
  | StrictModeViolation => "StrictModeViolation"
  | InternalError => "InternalError"
  }
```

#### JS 出力時のマッピング

| ReScript（内部） | JS Error プロパティ |
|-------------------|-------------------|
| `InvalidXml` | `e.name === "ConvertError"`, `e.code === "InvalidXml"` |
| `StrictModeViolation` | `e.name === "ConvertError"`, `e.code === "StrictModeViolation"` |
| `InternalError` | `e.name === "ConvertError"`, `e.code === "InternalError"` |

#### JS 消費者（confluence-mirror）での使用例

```typescript
try {
  const result = convertConfluenceStorageToMarkdown(xml);
} catch (e) {
  if (e instanceof Error && e.name === 'ConvertError') {
    const code = (e as { code: string }).code;
    switch (code) {
      case 'InvalidXml':           // XML パース失敗
      case 'StrictModeViolation':  // strict モード違反
      case 'InternalError':        // 内部エラー
    }
  }
}
```

> **`instanceof ConvertError` について**: 現時点では plain `Error` + `.name`/`.code` 方式（D-1）を採用。消費者が自前コード（confluence-mirror）のみのため `instanceof` による判別は不要。将来 npm 公開する場合は `class ConvertError extends Error` を別途定義する方式（D-2）に昇格可能。

### エントリポイント

```rescript
// AtlassianDocParser.res

let convertConfluenceStorageToMarkdown: (
  string,
  ~options: convertOptions=?,
) => convertResult
```

---

## 2. IR（中間表現）型定義

### 設計方針

- ブロックレベルとインラインレベルを型で分離する
- ReScript の variant type で表現し、パターンマッチで網羅的に処理する
- Confluence 固有の構造はパース時に正規化し、IR は Markdown に近い汎用構造とする

### 型定義

```rescript
// === IR Types ===

// インラインノード
type rec inlineNode =
  | Text(string)
  | Strong(array<inlineNode>)
  | Emphasis(array<inlineNode>)
  | Strikethrough(array<inlineNode>)
  | InlineCode(string)
  | Link({href: string, children: array<inlineNode>})
  | Image({src: string, alt: option<string>})
  | LineBreak
  | UnsupportedInline(string) // summary 文字列

// リストアイテム（ブロックを含む：ネストリスト対応）
type rec listItem = {children: array<blockNode>}

// テーブルセル（インラインのみ）
and tableCell = {children: array<inlineNode>}

// ブロックレベルノード
and blockNode =
  | Heading({level: int, children: array<inlineNode>})
  | Paragraph(array<inlineNode>)
  | BulletList(array<listItem>)
  | OrderedList(array<listItem>)
  | Table({headers: option<array<tableCell>>, rows: array<array<tableCell>>})
  | CodeBlock({language: option<string>, content: string})
  | HorizontalRule
  | Unsupported(string) // summary 文字列

// ドキュメント（トップレベル）
type document = {children: array<blockNode>}
```

### IR ノード → Confluence 要素の対応

| IR ノード | Confluence Storage Format | Markdown 出力 |
|-----------|--------------------------|---------------|
| `Heading({level, children})` | `<h1>`〜`<h6>` | `#`〜`######` |
| `Paragraph(children)` | `<p>` | テキスト + 空行 |
| `BulletList(items)` | `<ul><li>` | `- item` |
| `OrderedList(items)` | `<ol><li>` | `1. item` |
| `Table({headers, rows})` | `<table><tbody><tr><th>/<td>` | GFM テーブル |
| `CodeBlock({language, content})` | `<ac:structured-macro ac:name="code">` | `` ```lang `` |
| `HorizontalRule` | `<hr />` | `---` |
| `Text(s)` | テキストノード | そのまま |
| `Strong(children)` | `<strong>` / `<b>` | `**text**` |
| `Emphasis(children)` | `<em>` / `<i>` | `*text*` |
| `InlineCode(s)` | `<code>` | `` `text` `` |
| `Link({href, children})` | `<a href>` / `<ac:link>` | `[text](href)` |
| `Image({src, alt})` | `<ac:image>` | `![alt](src)` |
| `LineBreak` | `<br />` | 末尾 2 スペース + 改行 |
| `Unsupported(summary)` | 未対応要素全般 | `<!-- unsupported: {summary} -->` |
| `UnsupportedInline(summary)` | 未対応インライン要素 | `<!-- unsupported: {summary} -->` |

---

## 3. XML パース戦略

### 入力の性質

Confluence Storage Format は以下の特性を持つ:

1. **XML フラグメント**: ルート要素を持たない（複数のトップレベル要素が並ぶ）
2. **XHTML ベース**: `<p>`, `<h1>`, `<table>` 等の標準 HTML タグを使用
3. **カスタム名前空間**: `ac:`（Atlassian Confluence）と `ri:`（Resource Identifier）プレフィックスを使用
4. **CDATA セクション**: コードブロック等で `<![CDATA[...]]>` を使用

```xml
<!-- 実際の入力例（ルート要素なし） -->
<h1>Title</h1>
<p>Text with <strong>bold</strong></p>
<ac:structured-macro ac:name="code" ac:schema-version="1">
  <ac:parameter ac:name="language">javascript</ac:parameter>
  <ac:plain-text-body><![CDATA[console.log("hello");]]></ac:plain-text-body>
</ac:structured-macro>
```

### ライブラリ選定

**採用: htmlparser2 のみ**（domutils は不使用）

| 評価軸 | htmlparser2 | @xmldom/xmldom | fast-xml-parser |
|--------|-------------|----------------|-----------------|
| バンドルサイズ | ~30KB | ~160KB | ~100KB |
| フラグメント対応 | ネイティブ対応 | ラッパー必要 | ラッパー必要 |
| 名前空間処理 | xmlMode でプレフィックス保持 | W3C 準拠 | 対応 |
| CDATA 対応 | 対応 | 対応 | 対応 |
| エラー耐性 | 高（寛容パーサー） | 中（XML 準拠） | 中 |
| GAS 互換性 | 問題なし（Pure JS） | 問題なし（Pure JS） | 問題なし（Pure JS） |

**選定理由**:
1. **バンドルサイズ最小**: GAS デプロイサイズ制約への影響を最小化
2. **フラグメント対応**: Confluence Storage Format はルート要素を持たないため、ラッパー不要で解析可能
3. **エラー耐性**: Confluence のコンテンツが稀に不正な構造を含む場合でも、部分的に解析を継続できる

**domutils を不使用とする理由**:
- domutils は HTML/XML の DOM 探索・分析用のユーティリティライブラリ
- 本パーサーの目的はパース結果を入力順に処理して Markdown に「変換」することであり、DOM を「探索・分析」することではない
- `parseDocument()` が返すノードは `.type` / `.name` / `.attribs` / `.children` / `.data` プロパティを直接持っており、domutils なしでアクセス可能
- バンドルサイズ・メモリ使用量・実装スコープを不要に増やさない

**ストリーミング方式を不採用とする理由**:
- Confluence Storage Format は `ac:link`, `ac:structured-macro`, `table` など「子要素を見ないと変換方針が確定しない構造」が多い
- ストリーミングでは状態機械＋部分バッファが必要になり、実質的に DOM を自前で再構築することになる
- ページサイズは通常小さく、DOM 構築によるメモリ・性能面のデメリットは無視できる

### パース手順

```
入力 (string)
  │
  ▼
htmlparser2.parseDocument(input, { xmlMode: true })
  │
  ▼
DOM ツリー（ノードの .type/.name/.attribs/.children/.data に直接アクセス）
  │
  ▼
IrBuilder が再帰的に走査して IR を構築
```

### ReScript FFI バインディング

```rescript
// bindings/Htmlparser2.res

// htmlparser2 の DOM ノード型
// parseDocument() が返すノードのプロパティに直接アクセスする
// domutils は使用しない

type rec node = {
  @as("type") type_: string,   // "tag" | "text" | "comment" | "cdata" | ...
  name: Nullable.t<string>,     // タグ名（type="tag" の場合のみ）
  attribs: Nullable.t<Dict.t<string>>, // 属性（type="tag" の場合のみ）
  children: Nullable.t<array<node>>,   // 子ノード（type="tag" の場合のみ）
  data: Nullable.t<string>,     // テキスト内容（type="text"/"cdata" の場合のみ）
}

type document = {children: array<node>}

@module("htmlparser2")
external parseDocument: (string, {"xmlMode": bool}) => document = "parseDocument"
```

> **Note**: 上記は概略。実装時に htmlparser2 の実際の型に合わせて調整する。
> `xmlMode: true` では `ac:link`, `ri:page` 等のプレフィックス付きタグ名・属性名がそのまま保持される。

---

## 4. 要素ごとの変換ルール（MVP 対象）

### 4.1 見出し（h1〜h6）

**入力**:
```xml
<h1>Getting Started</h1>
<h2>Sub <em>heading</em></h2>
```

**変換ルール**:
- `<h1>`〜`<h6>` → `Heading({level: 1..6, children})`
- 子要素はインラインノードとして再帰処理
- level が 1〜6 の範囲外の場合は 6 にクランプ

**出力**:
```markdown
# Getting Started

## Sub *heading*
```

### 4.2 段落

**入力**:
```xml
<p>This is a paragraph with <strong>bold</strong> text.</p>
```

**変換ルール**:
- `<p>` → `Paragraph(children)`
- 子要素はインラインノードとして再帰処理
- 空の `<p>` は空行として出力

**出力**:
```markdown
This is a paragraph with **bold** text.
```

### 4.3 リスト（ul / ol）

**入力**:
```xml
<ul>
  <li>Item 1</li>
  <li>Item 2
    <ul>
      <li>Nested item</li>
    </ul>
  </li>
</ul>

<ol>
  <li>First
    <ul>
      <li>Sub item</li>
    </ul>
  </li>
  <li>Second</li>
</ol>
```

**変換ルール**:
- `<ul>` → `BulletList(items)`, `<ol>` → `OrderedList(items)`
- `<li>` → `listItem`。子要素にブロック要素（ネストリスト含む）がある場合はブロックとして処理
- `<li>` 直下のテキスト/インライン要素は暗黙の `Paragraph` として扱う
- ネストインデントはリストマーカー幅に合わせる（CommonMark 準拠: `- ` → 2、`N. ` → digits(N)+2。例: `1. ` → 3）

**出力**:
```markdown
- Item 1
- Item 2
  - Nested item

1. First
   - Sub item
2. Second
```

### 4.4 テーブル

**入力**:
```xml
<table>
  <tbody>
    <tr>
      <th>Header 1</th>
      <th>Header 2</th>
    </tr>
    <tr>
      <td>Cell 1</td>
      <td>Cell 2</td>
    </tr>
  </tbody>
</table>
```

**変換ルール**:
- `<th>` を含む最初の `<tr>` → `headers`
- 残りの `<tr>` → `rows`
- セル内はインラインノードとして処理
- `<thead>` が存在する場合はそれをヘッダー行とする
- ヘッダー行がない場合は区切り行のみ出力（GFM テーブル仕様に準拠）
- 列数が行間で不揃いの場合は最大列数に合わせて空セルで埋める

**セル内ブロック要素の処理（IrBuilder の責務）**:

Confluence はテーブルセル内容を `<p>` で包むのがデフォルト。また `<ul>` 等のブロック要素がセル内に出現することもある。IR の `tableCell` は `array<inlineNode>` のため、IrBuilder が以下のルールで段階的にインライン化する:

| セル内の要素 | 処理 | warning |
|---|---|---|
| `<p>` × 1 | アンラップして children をそのまま使う | なし |
| `<p>` × 複数 | 各 `<p>` の children を `<br>` で結合 | なし |
| `<ul>` / `<ol>` | `- Item A<br>- Item B` 形式に平坦化 | あり |
| コードブロック等 | テキスト内容を抽出 | あり |
| その他ブロック要素 | テキスト抽出 or `UnsupportedInline` | あり |

> **`<br>` HTML タグについて**: GFM テーブルは Markdown 構文としての改行（末尾 2 スペース + `\n`）は非対応だが、HTML `<br>` タグは主要レンダラー（GitHub, VS Code プレビュー）で改行として描画される。セル内の `<br />` 要素および上記インライン化で生成する改行は、いずれも Markdown 出力で `<br>` HTML タグとして出力する。

**出力**:
```markdown
| Header 1 | Header 2 |
| --- | --- |
| Cell 1 | Cell 2 |
```

### 4.5 コードブロック

**入力**:
```xml
<ac:structured-macro ac:name="code" ac:schema-version="1">
  <ac:parameter ac:name="language">javascript</ac:parameter>
  <ac:plain-text-body><![CDATA[const x = 1;
console.log(x);]]></ac:plain-text-body>
</ac:structured-macro>
```

**変換ルール**:
- `ac:structured-macro[name="code"]` → `CodeBlock`
- `ac:parameter[name="language"]` → `language`（任意）
- `ac:plain-text-body` の CDATA 内容 → `content`
- language パラメータがない場合は info string なし
- `<pre>` 単体もコードブロックとして扱う（language なし）

**出力**:
````markdown
```javascript
const x = 1;
console.log(x);
```
````

### 4.6 リンク

#### 4.6a 外部リンク

**入力**:
```xml
<a href="https://example.com">Link Text</a>
```

**変換ルール**:
- `<a href="...">` → `Link({href, children})`
- 子要素はインラインノードとして再帰処理

**出力**:
```markdown
[Link Text](https://example.com)
```

#### 4.6b 内部リンク（Confluence ページ間リンク）

**入力**:
```xml
<ac:link>
  <ri:page ri:content-title="Target Page" ri:space-key="PROJ" />
  <ac:plain-text-link-body><![CDATA[Link Text]]></ac:plain-text-link-body>
</ac:link>
```

**変換ルール**:
- `ac:link` + `ri:page` → `Link({href: "confluence-internal://{spaceKey}/{encodedTitle}", children})`
- `href` には `confluence-internal://` スキームを使用:
  - スペースキーあり: `confluence-internal://PROJ/Target%20Page`
  - スペースキーなし: `confluence-internal:///Target%20Page`
  - ページタイトルは URI エンコード
- リンクテキスト: `ac:plain-text-link-body` または `ac:link-body` の内容。なければ `ri:content-title` をテキストとする
- **warning なし**: `confluence-internal://` スキーム自体がリンク解決要のシグナルとなるため
- **stats 影響なし**: `unsupportedNodeCount` はインクリメントしない
- **strict モード影響なし**: パースは正常に成功しており、URL 解決は消費者の責務

> **設計判断**: 内部リンクは「未対応要素」ではなく、「パーサーがデータを完全に抽出できるが URL 解決は消費者の責務」という位置づけ。添付画像の `confluence-attachment://`（セクション 4.7b）と同じパターン。消費者（confluence-mirror）が GAS 配信時に同カテゴリ内リンクを相対パスに解決し、解決不可のリンクは unsupported として出力する。

**出力**:
```markdown
[Link Text](confluence-internal://PROJ/Target%20Page)
```

### 4.7 画像

#### 4.7a 外部画像（URL 参照）

**入力**:
```xml
<ac:image>
  <ri:url ri:value="https://example.com/image.png" />
</ac:image>

<ac:image ac:alt="Logo">
  <ri:url ri:value="https://example.com/logo.png" />
</ac:image>
```

**変換ルール**:
- `ac:image` + `ri:url` → `Image({src: ri:value, alt})`
- `ac:alt` 属性があれば `alt` に設定

**出力**:
```markdown
![](https://example.com/image.png)

![Logo](https://example.com/logo.png)
```

#### 4.7b 添付画像（ri:attachment）

**入力**:
```xml
<ac:image>
  <ri:attachment ri:filename="diagram.png" />
</ac:image>

<ac:image ac:alt="Architecture">
  <ri:attachment ri:filename="arch.png" />
</ac:image>
```

**変換ルール**:
- `ac:image` + `ri:attachment` → `Image({src: "confluence-attachment://{filename}", alt})`
- `src` には `confluence-attachment://` スキームを使用:
  - `confluence-attachment://diagram.png`
  - ファイル名はそのまま使用（エンコード不要：Confluence のファイル名は URI-safe）
- `ac:alt` 属性があれば `alt` に設定
- **warning なし**: `confluence-attachment://` スキーム自体が解決要のシグナルとなるため
- **stats 影響なし**: `unsupportedNodeCount` はインクリメントしない
- **strict モード影響なし**: パースは正常に成功しており、URL 解決は消費者の責務

> **設計判断**: `confluence-internal://`（内部リンク、セクション 4.6b）と同じパターン。パーサーはデータを完全に抽出できるが、完全 URL の構築は消費者の責務。消費者（confluence-mirror）が添付ファイル同期に対応した時点で URL を解決する。

**出力**:
```markdown
![](confluence-attachment://diagram.png)

![Architecture](confluence-attachment://arch.png)
```

### 4.8 テキスト装飾（インライン）

**入力**:
```xml
<strong>bold</strong>
<b>also bold</b>
<em>italic</em>
<i>also italic</i>
<code>inline code</code>
<u>underline</u>
<del>strikethrough</del>
<sub>subscript</sub>
<sup>superscript</sup>
```

**変換ルール**:

| HTML 要素 | IR ノード | Markdown | 備考 |
|-----------|----------|----------|------|
| `<strong>` / `<b>` | `Strong(children)` | `**text**` | |
| `<em>` / `<i>` | `Emphasis(children)` | `*text*` | |
| `<code>` | `InlineCode(s)` | `` `text` `` | |
| `<u>` | transparent（子要素をそのまま返す） | `text` | Markdown に下線なし。装飾は失われるが文意は保持 |
| `<del>` / `<s>` | `Strikethrough(children)` | `~~text~~` | GFM 拡張。意味論的マークアップのため対応 |
| `<sub>` | transparent（子要素をそのまま返す） | `text` | Markdown 非対応。将来 Pandoc-style `~text~` を検討可能 |
| `<sup>` | transparent（子要素をそのまま返す） | `text` | Markdown 非対応。将来 Pandoc-style `^text^` を検討可能 |

> **`<u>`, `<sub>`, `<sup>`**: 標準 Markdown で表現できないため、テキスト内容のみ出力する（transparent 扱い：子要素をそのまま親に返す）。装飾は失われるが文意は保持されるため、warning は出さない。`<sub>` / `<sup>` は将来的に Pandoc-style（`~`, `^`）での出力を検討可能だが、ターゲット Markdown が限定されるため現フェーズでは非対応とする。
>
> **`<del>` / `<s>`**: GFM `~~text~~` で出力する。取り消し線は「この部分は無効」という意味論的マークアップであり、`<u>` 等の純粋な見た目装飾とは質が異なるため MVP スコープに含める。GFM 拡張依存だが主要レンダラーで対応済み。

### 4.9 改行・水平線

| 入力 | IR | 出力 |
|------|-----|------|
| `<br />` | `LineBreak` | 末尾 2 スペース + `\n`（テーブルセル内では `<br>` HTML タグ） |
| `<hr />` | `HorizontalRule` | `---` |

### 4.10 未対応要素の処理

#### マクロ（ac:structured-macro）

MVP で対応するマクロは `code` のみ。その他は `Unsupported` ノードを生成する。

**入力**:
```xml
<ac:structured-macro ac:name="toc" ac:schema-version="1" />

<ac:structured-macro ac:name="expand" ac:schema-version="1">
  <ac:parameter ac:name="title">Details</ac:parameter>
  <ac:rich-text-body>
    <p>Hidden content.</p>
  </ac:rich-text-body>
</ac:structured-macro>
```

**変換ルール**:
- `ac:structured-macro[name != "code"]` → `Unsupported("ac:structured-macro name=\"{name}\"")`
- warning を記録
- `stats.macroCount` をインクリメント

**出力**:
```markdown
<!-- unsupported: ac:structured-macro name="toc" -->

<!-- unsupported: ac:structured-macro name="expand" -->
```

#### その他の未対応要素

- `ac:task-list`, `ac:emoticon`, `ac:placeholder` 等 → `Unsupported` / `UnsupportedInline`
- `ri:*` が単独で出現した場合（通常は `ac:link` / `ac:image` 配下）→ `UnsupportedInline`

---

## 5. ReScript モジュール構成

### ディレクトリ構造

```
atlassian-doc-parser/
├── src/
│   ├── AtlassianDocParser.res     # 公開 API（エントリポイント）
│   ├── Types.res                   # 公開型 + IR 型定義
│   ├── XmlParser.res               # XML 文字列 → DOM ツリー
│   ├── IrBuilder.res               # DOM ツリー → IR 変換
│   ├── MarkdownRenderer.res        # IR → Markdown 文字列
│   ├── Diagnostics.res             # warning 収集・stats 計算
│   └── Bindings/
│       └── Htmlparser2.res         # htmlparser2 FFI バインディング
├── test/
│   ├── fixtures/
│   │   ├── 01_basic/
│   │   │   ├── input.xml
│   │   │   └── expected.md
│   │   ├── 02_complex_table_code/
│   │   │   ├── input.xml
│   │   │   └── expected.md
│   │   └── 03_mixed_unsupported/
│   │       ├── input.xml
│   │       └── expected.md
│   ├── AtlassianDocParser_test.res  # E2E テスト（fixture ベース）
│   ├── IrBuilder_test.res           # XML → IR の Unit テスト
│   └── MarkdownRenderer_test.res    # IR → Markdown の Unit テスト
├── rescript.json
├── package.json
├── biome.json                      # JS 出力のリント用
└── README.md
```

### モジュール責務

#### AtlassianDocParser（公開 API）

- **責務**: パイプラインのオーケストレーション
- **入力**: XML 文字列 + ConvertOptions
- **出力**: ConvertResult
- **処理**: XmlParser → IrBuilder → MarkdownRenderer → Diagnostics 集約

```rescript
// AtlassianDocParser.res（擬似コード）
let convertConfluenceStorageToMarkdown = (input, ~options=?) => {
  try {
    let strict = options->Option.mapOr(false, o => o.strict->Option.getOr(false))
    let diagnostics = Diagnostics.create()

    // 1. XML パース
    let dom = try {
      XmlParser.parse(input)
    } catch {
    | exn => raise(ConvertError({code: InvalidXml, message: Exn.message(exn)}))
    }

    // 2. IR 構築（strict 違反時は ConvertError を raise）
    let document = IrBuilder.build(dom, diagnostics, ~strict)

    // 3. Markdown レンダリング
    let markdown = MarkdownRenderer.render(document)

    // 4. 結果組み立て
    {
      markdown,
      warnings: Diagnostics.getWarnings(diagnostics),
      stats: Diagnostics.getStats(diagnostics),
    }
  } catch {
  // 5. Boundary: ReScript exception → JS Error に変換して re-throw
  | ConvertError({code, message}) =>
    throwJsConvertError(convertErrorCodeToString(code), message)
  }
}
```

#### Types（型定義）

- **責務**: 全モジュールで共有する型の定義
- **内容**: ConvertOptions, ConvertResult, ConvertError, IR 型（blockNode, inlineNode 等）
- **依存**: なし（他モジュールはすべて Types に依存）

#### XmlParser（XML パース）

- **責務**: XML 文字列を htmlparser2 の DOM ツリーに変換
- **入力**: string
- **出力**: htmlparser2 の DOM ノード
- **エラー**: パース不能な場合は例外（呼び出し元で ConvertError に変換）

#### IrBuilder（IR 構築）

- **責務**: DOM ツリーを再帰的に走査し、IR ノードを構築
- **入力**: DOM ノード + Diagnostics コンテキスト + strict フラグ
- **出力**: Types.document
- **処理詳細**:
  - 要素名（tagName）でパターンマッチしてディスパッチ
  - 未対応要素は `Unsupported` / `UnsupportedInline` を生成し、Diagnostics に記録
  - strict モードでは warning 相当の事象で ConvertError を raise

#### MarkdownRenderer（Markdown 生成）

- **責務**: IR を Markdown 文字列に変換する純粋関数
- **入力**: Types.document
- **出力**: string
- **特性**: 副作用なし。IR の構造のみに依存する

#### Diagnostics（診断情報）

- **責務**: warning メッセージの収集と stats の計算
- **インターフェース**:
  ```rescript
  type t

  let create: unit => t
  let addWarning: (t, string) => unit
  let incrementUnsupported: t => unit
  let incrementMacro: t => unit
  let getWarnings: t => array<string>
  let getStats: t => option<convertStats>
  ```
- **実装**: Ref ベースの可変コンテナ（変換パイプライン内で 1 インスタンスを共有）

### モジュール依存グラフ

```
AtlassianDocParser
  ├── Types
  ├── XmlParser
  │     └── Bindings/Htmlparser2  ※ domutils 不使用、ノードプロパティ直接アクセス
  ├── IrBuilder
  │     ├── Types
  │     └── Diagnostics
  ├── MarkdownRenderer
  │     └── Types
  └── Diagnostics
        └── Types
```

---

## 6. Warning コード体系

### 方針

- `warnings: array<string>` は人間可読の診断メッセージを格納する
- 機械処理しやすいよう、一貫したプレフィックスパターンを採用する
- フォーマット: `[CATEGORY] description`

### カテゴリ一覧（MVP）

| カテゴリ | 説明 | 例 |
|----------|------|-----|
| `UNSUPPORTED_ELEMENT` | MVP 対象外のブロック要素 | `[UNSUPPORTED_ELEMENT] ac:task-list` |
| `UNSUPPORTED_MACRO` | MVP 対象外のマクロ | `[UNSUPPORTED_MACRO] toc` |
| `UNSUPPORTED_INLINE` | MVP 対象外のインライン要素 | `[UNSUPPORTED_INLINE] ac:emoticon` |
| `CONVERSION_ERROR` | 既知要素の変換失敗 | `[CONVERSION_ERROR] table: inconsistent column count` |
| `INVALID_STRUCTURE` | 要素の構造が想定外 | `[INVALID_STRUCTURE] li without parent ul/ol` |

### stats との連動

| 事象 | stats 更新 |
|------|-----------|
| `UNSUPPORTED_ELEMENT` | `unsupportedNodeCount++` |
| `UNSUPPORTED_MACRO` | `unsupportedNodeCount++`, `macroCount++` |
| `UNSUPPORTED_INLINE` | `unsupportedNodeCount++` |
| `CONVERSION_ERROR` | `unsupportedNodeCount++` |
| `INVALID_STRUCTURE` | 更新なし（Best Effort で継続） |

### Strict モードとの連動

| 事象 | strict=false | strict=true |
|------|-------------|-------------|
| `UNSUPPORTED_ELEMENT` | warning + プレースホルダー | `ConvertError(StrictModeViolation)` |
| `UNSUPPORTED_MACRO` | warning + プレースホルダー | `ConvertError(StrictModeViolation)` |
| `UNSUPPORTED_INLINE` | warning + プレースホルダー | `ConvertError(StrictModeViolation)` |
| `CONVERSION_ERROR` | warning + プレースホルダー | `ConvertError(StrictModeViolation)` |
| `INVALID_STRUCTURE` | warning + Best Effort 処理 | `ConvertError(StrictModeViolation)` |

> `ac:link`（内部リンク）と `ri:attachment`（添付画像）は上記テーブルに含まれない。それぞれ `confluence-internal://` / `confluence-attachment://` スキーム付きのノードとして正常に出力されるため、warning・stats・strict モードのいずれにも影響しない（セクション 4.6b, 4.7b 参照）。

---

## 7. テスト設計

### テスト構成

| テスト種別 | 対象モジュール | テスト方針 |
|-----------|--------------|-----------|
| Golden Test | AtlassianDocParser（E2E） | fixture の input.xml → expected.md の一致検証 |
| Unit Test | IrBuilder | 要素別に XML フラグメント → IR ノードを検証 |
| Unit Test | MarkdownRenderer | IR ノード → Markdown 文字列を検証 |
| Unit Test | Diagnostics | warning/stats の収集を検証 |

### テストケース一覧

#### A. Golden Test（fixture ベース E2E）

| # | fixture | 含む要素 | 検証観点 |
|---|---------|---------|---------|
| 01 | basic | h1, h2, p, strong, em, a(外部), code(inline), br, ul | 基本要素の正常変換 |
| 02 | complex_table_code | h1, h2, p, table(th/td), code block(language付/なし), inline code | 複合要素の変換 |
| 03 | mixed_unsupported | h1, h2, p, em, ol(ネスト), ac:image(外部/添付), ac:link(内部), del, sup(transparent), hr, 未対応マクロ(toc, expand) | 混合コンテンツ + unsupported + warnings |

#### B. IrBuilder Unit Test

| # | テスト対象 | 入力 | 期待 IR | 区分 |
|---|-----------|------|---------|------|
| B01 | 見出し h1 | `<h1>Title</h1>` | `Heading({level:1, children:[Text("Title")]})` | 正常 |
| B02 | 見出し h6 | `<h6>Sub</h6>` | `Heading({level:6, children:[Text("Sub")]})` | 正常 |
| B03 | 見出し + インライン | `<h2>A <strong>B</strong></h2>` | `Heading({level:2, children:[Text("A "), Strong([Text("B")])]})` | 正常 |
| B04 | 段落 | `<p>Text</p>` | `Paragraph([Text("Text")])` | 正常 |
| B05 | 空段落 | `<p></p>` | `Paragraph([])` | エッジ |
| B06 | 箇条書きリスト | `<ul><li>A</li><li>B</li></ul>` | `BulletList([{children:[Paragraph([Text("A")])]}, ...])` | 正常 |
| B07 | 番号付きリスト | `<ol><li>A</li></ol>` | `OrderedList([...])` | 正常 |
| B08 | ネストリスト | `<ul><li>A<ul><li>B</li></ul></li></ul>` | ネスト構造の検証 | 正常 |
| B09 | テーブル（ヘッダー付） | `<table><tbody><tr><th>H</th></tr><tr><td>C</td></tr></tbody></table>` | `Table({headers: Some([...]), rows: [...]})` | 正常 |
| B10 | テーブル（ヘッダーなし） | `<table><tbody><tr><td>C</td></tr></tbody></table>` | `Table({headers: None, rows: [...]})` | エッジ |
| B11 | コードブロック | `<ac:structured-macro ac:name="code">...` | `CodeBlock({language: Some("js"), content: "..."})` | 正常 |
| B12 | コードブロック（言語なし） | `<ac:structured-macro ac:name="code"><ac:plain-text-body>...` | `CodeBlock({language: None, content: "..."})` | エッジ |
| B13 | 外部リンク | `<a href="url">text</a>` | `Link({href: "url", children: [Text("text")]})` | 正常 |
| B14 | 内部リンク | `<ac:link><ri:page ri:content-title="Target Page" ri:space-key="PROJ"/>...` | `Link({href: "confluence-internal://PROJ/Target%20Page", children: [...]})` | 正常 |
| B15 | 内部リンク（スペースキー・リンクテキストなし） | `<ac:link><ri:page ri:content-title="Page"/></ac:link>` | `Link({href: "confluence-internal:///Page", children: [Text("Page")]})` | エッジ |
| B16 | 外部画像 | `<ac:image><ri:url ri:value="url"/></ac:image>` | `Image({src: "url", alt: None})` | 正常 |
| B17 | 添付画像 | `<ac:image><ri:attachment ri:filename="f.png"/></ac:image>` | `Image({src: "confluence-attachment://f.png", alt: None})` | 正常 |
| B18 | strong | `<strong>B</strong>` | `Strong([Text("B")])` | 正常 |
| B19 | em | `<em>I</em>` | `Emphasis([Text("I")])` | 正常 |
| B20 | inline code | `<code>c</code>` | `InlineCode("c")` | 正常 |
| B21 | 未対応マクロ | `<ac:structured-macro ac:name="toc"/>` | `Unsupported(...)` + warning | 異常 |
| B22 | 未対応要素 | `<ac:task-list>...` | `Unsupported(...)` + warning | 異常 |
| B23 | br | `<br />` | `LineBreak` | 正常 |
| B24 | hr | `<hr />` | `HorizontalRule` | 正常 |
| B25 | del（取り消し線） | `<del>old</del>` | `Strikethrough([Text("old")])` | 正常 |
| B26 | u（下線→テキストのみ） | `<u>underlined</u>` | `Text("underlined")` | 正常 |
| B27 | sub / sup（テキストのみ） | `<sub>2</sub>` / `<sup>2</sup>` | `Text("2")` | 正常 |
| B28 | テーブルセル内ブロック要素 | `<td><p>A</p><p>B</p></td>` | セル inlineNode が `[Text("A"), LineBreak, Text("B")]` に平坦化 | 正常 |
| B29 | ネストインライン装飾 | `<strong><em>text</em></strong>` | `Strong([Emphasis([Text("text")])])` | 正常 |
| B30 | strict モード違反 | 未対応要素 + `strict: true` | `ConvertError(StrictModeViolation)` が raise | 異常 |

#### C. MarkdownRenderer Unit Test

| # | 入力 IR | 期待出力 | 区分 |
|---|---------|---------|------|
| C01 | `Heading({level:1, children:[Text("T")]})` | `# T` | 正常 |
| C02 | `Paragraph([Text("A"), Strong([Text("B")])])` | `A **B**` | 正常 |
| C03 | `BulletList` 2 アイテム | `- A\n- B` | 正常 |
| C04 | `OrderedList` 2 アイテム | `1. A\n2. B` | 正常 |
| C05 | ネスト `BulletList` | `- A\n  - B` | 正常 |
| C06 | `Table` ヘッダー + 1 行 | GFM テーブル文字列 | 正常 |
| C07 | `CodeBlock({language: Some("js"), ...})` | `` ```js\n...\n``` `` | 正常 |
| C08 | `CodeBlock({language: None, ...})` | `` ```\n...\n``` `` | エッジ |
| C09 | `Link({href, children})` | `[text](href)` | 正常 |
| C10 | `Image({src, alt: Some("A")})` | `![A](src)` | 正常 |
| C11 | `Unsupported("macro")` | `<!-- unsupported: macro -->` | 正常 |
| C12 | 複数ブロック連結 | ブロック間に空行挿入 | 正常 |
| C13 | `Strikethrough([Text("old")])` | `~~old~~` | 正常 |
| C14 | `HorizontalRule` | `---` | 正常 |
| C15 | `Paragraph([Text("A"), LineBreak, Text("B")])` | `A  \nB`（末尾 2 スペース + 改行） | 正常 |
| C16 | `Table` ヘッダーなし + 1 行 | GFM テーブル（ヘッダー行は空セル） | エッジ |
| C17 | `UnsupportedInline("emoticon")` | `<!-- unsupported inline: emoticon -->` | 正常 |

#### D. Diagnostics Unit Test

| # | 操作 | 期待結果 |
|---|------|---------|
| D01 | addWarning × 2 → getWarnings | 2 件の warning 配列 |
| D02 | incrementUnsupported × 3 → getStats | `unsupportedNodeCount: 3` |
| D03 | incrementMacro × 1 → getStats | `macroCount: 1` |
| D04 | 何も追加しない → getStats | `None` |

---

## 8. 初期 Fixture（3 件）

### Fixture 01: basic（代表ケース）

#### input.xml

```xml
<h1>Getting Started</h1>
<p>Welcome to the <strong>project documentation</strong>.</p>
<p>See <a href="https://example.com/guide">the guide</a> for <em>more</em> information.</p>
<p>Use the <code>sync</code> command to start.<br />It runs in the background.</p>
<h2>Features</h2>
<ul>
  <li>Fast synchronization</li>
  <li>Automatic conversion</li>
  <li>Offline access</li>
</ul>
```

#### expected.md

```markdown
# Getting Started

Welcome to the **project documentation**.

See [the guide](https://example.com/guide) for *more* information.

Use the `sync` command to start.  
It runs in the background.

## Features

- Fast synchronization
- Automatic conversion
- Offline access
```

#### 期待 warnings

```json
[]
```

---

### Fixture 02: complex_table_code（テーブル + コードブロック）

#### input.xml

```xml
<h1>API Reference</h1>
<p>This section describes the available endpoints.</p>
<table>
  <tbody>
    <tr>
      <th>Method</th>
      <th>Path</th>
      <th>Description</th>
    </tr>
    <tr>
      <td>GET</td>
      <td><code>/api/users</code></td>
      <td>List all users</td>
    </tr>
    <tr>
      <td>POST</td>
      <td><code>/api/users</code></td>
      <td>Create a new user</td>
    </tr>
  </tbody>
</table>
<h2>Example</h2>
<ac:structured-macro ac:name="code" ac:schema-version="1">
  <ac:parameter ac:name="language">javascript</ac:parameter>
  <ac:plain-text-body><![CDATA[const response = await fetch('/api/users');
const data = await response.json();
console.log(data);]]></ac:plain-text-body>
</ac:structured-macro>
<p>Raw output:</p>
<ac:structured-macro ac:name="code" ac:schema-version="1">
  <ac:plain-text-body><![CDATA[{ "users": [...] }]]></ac:plain-text-body>
</ac:structured-macro>
```

#### expected.md

```markdown
# API Reference

This section describes the available endpoints.

| Method | Path | Description |
| --- | --- | --- |
| GET | `/api/users` | List all users |
| POST | `/api/users` | Create a new user |

## Example

```javascript
const response = await fetch('/api/users');
const data = await response.json();
console.log(data);
```

Raw output:

```
{ "users": [...] }
```
```

#### 期待 warnings

```json
[]
```

---

### Fixture 03: mixed_unsupported（混合コンテンツ + 未対応要素）

#### input.xml

```xml
<h1>Project Overview</h1>
<p>This is the overview page for <em>Project X</em>.</p>
<ac:image>
  <ri:url ri:value="https://example.com/logo.png" />
</ac:image>
<h2>Tasks</h2>
<ol>
  <li>Design phase
    <ul>
      <li>Create wireframes</li>
      <li>Review with team</li>
    </ul>
  </li>
  <li>Implementation phase</li>
</ol>
<hr />
<h2>Related Pages</h2>
<p>See also: <ac:link><ri:page ri:content-title="Architecture Guide" ri:space-key="PROJ" /><ac:plain-text-link-body><![CDATA[Architecture Guide]]></ac:plain-text-link-body></ac:link></p>
<p>The <del>old API</del> has been replaced. See notes<sup>1</sup> below.</p>
<ac:image ac:alt="Diagram">
  <ri:attachment ri:filename="architecture.png" />
</ac:image>
<ac:structured-macro ac:name="toc" ac:schema-version="1" />
<ac:structured-macro ac:name="expand" ac:schema-version="1">
  <ac:parameter ac:name="title">Additional Notes</ac:parameter>
  <ac:rich-text-body>
    <p>Some hidden content.</p>
  </ac:rich-text-body>
</ac:structured-macro>
```

#### expected.md

```markdown
# Project Overview

This is the overview page for *Project X*.

![](https://example.com/logo.png)

## Tasks

1. Design phase
   - Create wireframes
   - Review with team
2. Implementation phase

---

## Related Pages

See also: [Architecture Guide](confluence-internal://PROJ/Architecture%20Guide)

The ~~old API~~ has been replaced. See notes1 below.

![Diagram](confluence-attachment://architecture.png)

<!-- unsupported: ac:structured-macro name="toc" -->

<!-- unsupported: ac:structured-macro name="expand" -->
```

#### 期待 warnings

```json
[
  "[UNSUPPORTED_MACRO] toc",
  "[UNSUPPORTED_MACRO] expand"
]
```

#### 期待 stats

```json
{
  "unsupportedNodeCount": 2,
  "macroCount": 2
}
```

---

## 9. 未決事項・Phase 3a への申し送り

| # | 項目 | 現状 | 対応タイミング |
|---|------|------|-------------|
| 1 | htmlparser2 の FFI バインディング詳細 | 概略定義のみ | Phase 3a 実装時 |
| 2 | Markdown エスケープ処理 | 未定義（`|` や `*` のエスケープ） | Phase 3a 実装時 |
| 3 | ~~`<del>` / `<s>` の取り込み有無~~ | **解決済み**: GFM `~~text~~` で MVP スコープに含める（セクション 4.8 レビューで承認） | — |
| 4 | `<pre>` 単体の扱い | CodeBlock（language なし）として処理予定 | Phase 3a 実装時に確認 |
| 5 | 空白・改行の正規化ルール | XML の空白処理（連続空白の圧縮等） | Phase 3a 実装時 |
| 6 | 内部リンク解決（confluence-mirror 側） | GAS 配信時に `confluence-internal://` スキームを解決する処理。同カテゴリ内 → 相対リンク、その他 → unsupported | Phase 3b 詳細設計時 |
| 7 | 添付画像解決（confluence-mirror 側） | `confluence-attachment://` スキームの解決処理。添付ファイル同期（持ち越し課題 C3）対応時にパス書き換え。MVP では未解決のまま出力 | Phase 3b 詳細設計時（添付ファイル同期は MVP 後） |
