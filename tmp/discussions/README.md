# Discussions - atlassian-doc-parser

`atlassian-doc-parser` の仕様検討ログ。

## このディレクトリの目的

- パーサー自体の仕様・設計・品質基準を議論して決める
- 決定事項を時系列で記録し、実装時の判断根拠を残す

## スコープ

- 対象: Confluence Storage XML → Markdown 変換
- 対象外: `confluence-mirror` 側の API 契約、GAS 運用、CLI UX

## 関連ディスカッション

- 横断の持ち越し課題: [`tmp/confluence-mirror/discussions/014_carryover-open-items.md`](../../confluence-mirror/discussions/014_carryover-open-items.md)

## `atlassian-doc-parser` と `confluence-mirror` の関係

### 役割分担

- `atlassian-doc-parser`
  - 変換ライブラリ（入力: Confluence本文、出力: Markdown + warning）
  - 変換ルール・未対応要素ポリシー・変換テストを管理
- `confluence-mirror`（Confluence Local Sync の実装リポジトリ）
  - Confluence API 取得、認証、保存、同期制御を担当
  - `atlassian-doc-parser` を依存ライブラリとして利用

### データフロー（要約）

1. `confluence-mirror` が Confluence から Storage Format を取得
2. `confluence-mirror` が `atlassian-doc-parser` を呼び出して Markdown へ変換
3. `confluence-mirror` が変換結果を Google Drive / ローカルへ保存

### 依存方向

- 一方向依存: `confluence-mirror` → `atlassian-doc-parser`
- `atlassian-doc-parser` は `confluence-mirror` に依存しない

> 注: 設定ファイル名（`.confluence-sync.json`, `~/.confluence-sync/`）では、歴史的に `confluence-sync` プレフィックスを使用する。

## ディスカッションの進め方

### 基本ルール

- 各トピックは個別ファイルに記録する
- ファイル名は `NNN_トピック名.md` 形式
- 結論が出たら `status: closed` に変更し、実装に反映する
- 未解決の論点は `status: open` のまま残す

### 1. 論点の提示フォーマット

論点を開始する際は以下を明示する:

| 項目 | 説明 |
|------|------|
| **ゴール** | この論点で決めたいこと（1文） |
| **制約** | 技術的・設計的な前提条件 |
| **期待するアウトプット** | 例: 代替案3つ / リスク一覧 / 決定事項 |

### 2. 短サイクルで収束

- 1論点につき **2〜3往復** で決着を目指す
- 往復: 提案 → 取捨選択 → 再提案（必要なら）→ 決定
- 決着しない場合は「未決事項」として明示し、次に進む

### 3. 決定ログのフォーマット

各論点の結論は以下の形式で記録:

| 項目 | 内容 |
|------|------|
| **決定** | 採用した方針（1〜2文） |
| **理由** | なぜその方針か（箇条書き） |
| **未決/リスク** | 残課題があれば記載 |
| **ステータス** | 決定済み / 未決 / スコープ外 |

## インデックス

| # | トピック | ステータス | ファイル |
|---|---------|-----------|---------|
| 001 | atlassian-doc-parser 仕様策定（MVP） | closed | [001_atlassian-doc-parser-spec.md](./001_atlassian-doc-parser-spec.md) |
| 002 | 公開 API の形（ConvertResult 採用） | closed | [002_public-api-shape.md](./002_public-api-shape.md) |
| 003 | 変換アーキテクチャ（XML -> IR -> Markdown） | closed | [003_xml-ir-markdown-architecture.md](./003_xml-ir-markdown-architecture.md) |
| 004 | 未対応要素の扱い（プレースホルダー + warnings） | closed | [004_unsupported-elements-policy.md](./004_unsupported-elements-policy.md) |
| 005 | MVP 未決事項（決定反映） | closed | [005_mvp-open-items.md](./005_mvp-open-items.md) |
| 006 | エラーハンドリング方針（Best Effort / Strict） | closed | [006_error-handling-policy.md](./006_error-handling-policy.md) |
