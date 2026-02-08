# 003: 変換アーキテクチャ（XML -> IR -> Markdown）

- **status**: closed
- **date**: 2026-02-07
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: [001_atlassian-doc-parser-spec.md](./001_atlassian-doc-parser-spec.md) の論点 2

## 背景

MVP でも parser の初期設計は将来の保守性を左右する。
また、Confluence API は XML / HTML の両レスポンスを返し得るが、本仕様で固定した主系は「XML を IR 経由で Markdown に変換する」流れ。

## ゴール

変換パイプラインの責務分離を定義し、拡張時に破綻しにくい構成を確定する。

## 選択肢

### Option A: 直接変換（XML ノード列 -> Markdown）

- メリット: 初期実装が速い
- デメリット: 変換ルール追加時に分岐が集中しやすい

### Option B: 2段階変換（XML ノード列 -> IR -> Markdown）

- メリット: 解析層と描画層を分離できる
- メリット: ユニットテストを層ごとに書ける
- デメリット: MVP 初期コストは増える

## 決定

Option B（`XML -> IR -> Markdown`）を採用。HTML DOM を直接 Markdown に変換する設計は採らない。

## 理由

1. ルール追加時の影響範囲を限定できる
2. XML 解析と Markdown 出力を個別にテストできる
3. 将来の入力差分（XML/HTML）を入力アダプタで吸収しやすい

## 未決/リスク

Confluence API は XML/HTML の両レスポンスを返し得るが、MVP の主系は XML 入力を正規化して IR に落とす。HTML レスポンス対応が必要になった場合も、最終的には同一 IR に集約するアダプタ層で吸収する（直変換は採らない）。

## ステータス

決定済み

---

## MVP アーキテクチャ（確定）

1. XML パーサー層  
Confluence Storage XML を解析し、ノード列を取得する。

2. IR ビルダー層  
XML ノード列を、変換に必要な最小 IR ノードへ正規化する。

3. Markdown レンダラー層  
IR を Markdown 文字列へ変換する。

4. 診断集約層  
未対応要素・警告・統計値を `warnings` / `stats` に集約する。

## MVP の IR 最小ノード集合

- 見出し
- 段落
- リスト（順序あり / なし）
- テーブル
- コードブロック / インラインコード
- リンク
- 画像
- 強調（em / strong）

## HTML レスポンスが来た場合の扱い

- MVP の主系は XML 入力
- HTML レスポンス対応が必要になった場合も、最終的に同一 IR に集約する
- つまり「HTML DOM -> Markdown 直変換」は採らず、入力差はアダプタ層で吸収する

## テスト観点（論点 5 と接続）

- XML -> IR の層テスト
- IR -> Markdown の層テスト
- `input.xml -> expected.md` の Golden Test
- 未対応要素が `warnings` に記録されることの検証

