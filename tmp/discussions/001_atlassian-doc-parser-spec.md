# 001: atlassian-doc-parser 仕様策定（MVP）

- **status**: closed
- **date**: 2026-02-06
- **participants**: ユーザー, Codex (GPT-5)

## 背景

`002_tech-stack.md` で、パーサーを別リポジトリ（`atlassian-doc-parser`）として分離する方針は決定済み。
当初、以下は未確定だった:

- npm パッケージとしての公開 API 形状
- HTML/XML（Confluence Storage Format）から Markdown への変換方針
- 変換不能要素の扱い
- テスト戦略と品質基準

本ディスカッションで、MVP 実装に必要な仕様・設計を固定した。

## 関連詳細ログ

- 論点 1 詳細: [002_public-api-shape.md](./002_public-api-shape.md)
- 論点 2 詳細: [003_xml-ir-markdown-architecture.md](./003_xml-ir-markdown-architecture.md)
- 論点 3 詳細: [004_unsupported-elements-policy.md](./004_unsupported-elements-policy.md)
- 論点 4 詳細: [006_error-handling-policy.md](./006_error-handling-policy.md)
- 論点 5-6 詳細: [005_mvp-open-items.md](./005_mvp-open-items.md)

## 論点定義

| 項目 | 内容 |
|------|------|
| **ゴール** | `atlassian-doc-parser` の MVP 実装に必要な API/設計/品質基準を決める |
| **制約** | Confluence Local Sync から利用する前提、GAS 連携時のデバッグ容易性、MVP は基本要素優先 |
| **期待するアウトプット** | API シグネチャ、未対応要素のポリシー、テスト方針、リリース運用方針 |

## 非ゴール（この論点では決めない）

- Jira Wiki / ADF 対応の詳細仕様
- 変換品質の最適化（MVP 後の改善項目）
- OSS 公開時のドキュメント整備詳細

### 論点 0: 記述先ディレクトリ

**決定**: 記述先は `tmp/atlassian-doc-parser/discussions/` とし、ファイル命名は `001_*.md` 形式とする。旧ファイル `tmp/confluence-mirror/discussions/013_atlassian-doc-parser-spec.md` は本ファイルに移動済み。

**理由**:
- パーサー専用トピックを Confluence Local Sync 本体の議論から分離するため
- 今後の parser リポジトリ独立時に移管しやすくするため

**ステータス**: 決定済み

### 論点 1: 公開 API の形

**ゴール**: npm パッケージのエントリポイント API シグネチャを決める

**制約**: Confluence Local Sync 側で運用・観測に使いやすいこと、MVP は基本形状のみ

**期待するアウトプット**: API シグネチャ、戻り値の形

**代替案**:
- **Option A**: 最小 API（文字列 in / 文字列 out）
  ```ts
  convertConfluenceStorageToMarkdown(input: string, options?: ConvertOptions): string
  ```
  メリット: 呼び出し側実装が最小
  デメリット: 変換警告（未対応要素など）を返せない

- **Option B**: 結果オブジェクトを返す
  ```ts
  type ConvertResult = {
    markdown: string
    warnings: string[]
    stats?: {
      unsupportedNodeCount: number
      macroCount: number
    }
  }

  convertConfluenceStorageToMarkdown(
    input: string,
    options?: ConvertOptions
  ): ConvertResult
  ```
  メリット: GAS 側ログ出力・運用観測がしやすい
  デメリット: 呼び出し側で `result.markdown` の取り回しが必要

**決定**: Option B（`ConvertResult` を返す）

**理由**:
- MVP 段階でも「未変換要素がどれだけあったか」は運用上の重要指標になるため
- 将来の拡張性も良好

**未決/リスク**: Option A 相当の `string` 専用ラッパーは必要になったタイミングで追加検討する

**ステータス**: 決定済み

### 論点 2: 変換アーキテクチャ

**ゴール**: XML/HTML から Markdown への変換フローを決める

**制約**: MVP は基本要素のみ対応、拡張性・テスト容易性のバランス

**期待するアウトプット**: アーキテクチャの決定、中間表現の形式

**代替案**:
- **Option A**: 直接変換（XML ノード列 → Markdown）
  メリット: 実装は速い
  デメリット: ルール追加時に分岐が肥大化しやすい

- **Option B**: 2段階変換（XML ノード列 → 中間表現（IR）→ Markdown）
  メリット: 拡張しやすくテストしやすい
  デメリット: MVP 初期の実装コストはやや増える

**決定**: Option B（`XML -> IR -> Markdown` の 2段階変換）、MVP は中間表現を最小ノードに限定（見出し・段落・リスト・テーブル・コード・リンク・画像）

**理由**:
- 拡張性と テスト容易性が重要
- MVP 初期のコスト増は長期的には回収できる

**未決/リスク**:
- Confluence API は XML/HTML の両レスポンスを取り得るが、MVP の主系は XML 入力を正規化して IR に落とす
- HTML レスポンス対応が必要な場合も、最終的には同一 IR に集約するアダプタ層で吸収する

**ステータス**: 決定済み

### 論点 3: 未対応要素の扱い

**ゴール**: Confluence Storage Format の未対応要素をどのように扱うか決める

**制約**: 情報欠落を防ぐこと、運用上の観測可能性

**期待するアウトプット**: ポリシー決定、出力フォーマット

**代替案**:
- **Option A**: 無視（出力しない）
  メリット: シンプル
  デメリット: データ欠落に気づきにくい

- **Option B**: プレースホルダー化して残す
  例:
  ```md
  <!-- unsupported: ac:structured-macro name="toc" -->
  ```
  メリット: 情報欠落に気づける
  デメリット: 出力が多少ノイジーになる

**決定**: Option B（未対応要素は Markdown コメントとして残す）、`warnings` にも同じ事象を記録

**理由**:
- 情報欠落の見落としを防ぐため
- 機械処理と人間可読の両方を担保
- 段階的な対応優先度付けに使える

**未決/リスク**: なし

**ステータス**: 決定済み

### 論点 4: エラーハンドリング方針

**ゴール**: 不正な入力や変換エラー時の動作を決める

**制約**: 同期の継続性と完全性のバランス

**期待するアウトプット**: デフォルト動作と例外モードの決定

**代替案**:
- **Option A**: 例外を投げる（Fail Fast）
  メリット: 呼び出し側で明確に失敗を扱える
  デメリット: 一部壊れたページでも全体失敗になりやすい

- **Option B**: Best Effort（可能な範囲で変換し warning）
  メリット: 同期継続しやすい
  デメリット: 完全性は下がる

**決定**:
- `ConvertOptions.strict?: boolean` を MVP から公開する（default: `false`）
- default（`strict=false`）は Best Effort:
  - 未対応要素は warning + プレースホルダーで継続
  - ノード単位の変換失敗は warning + プレースホルダーで継続
  - 入力全体を解釈できないエラー（不正 XML など）と内部エラーは例外
- `strict=true` は Fail Fast:
  - warning 対象の事象も含めて即例外とする
- 例外経路では `ConvertResult` を返さず `ConvertError` を throw する

**理由**:
- 本番同期では停止より継続を優先できる
- 開発・テストでは厳格モードで品質問題を早期検知できる
- 「warning で継続する境界」と「例外にする境界」を API 契約として明示できる

**未決/リスク**:
- warning/エラーコードの粒度（分類の細かさ）は実装時に調整余地あり

**ステータス**: 決定済み

---

### 論点 5: MVP テスト戦略

**ゴール**: MVP リリース時の最低限の品質基準を決める

**制約**: 開発効率と品質のバランス

**期待するアウトプット**: テスト戦略、合格ライン

**決定**:
- `atlassian-doc-parser` の責務は「Confluence 仕様に則った XML 入力を規定出力へ変換すること」に限定し、テスト主軸は Unit テストとする
- parser は参照透過な関数群として扱い、Unit テストではモックを使わず実入力で検証する
- 固定 fixture は初期 3 件（代表ケース 1 件 + 複雑ケース 2 件）を用意する
- fixture の具体的な入力 XML と期待出力は実装時に確定する
- 不具合が発生した入力は都度 fixture 追加し、回帰防止を継続する
- CI は `push` / `pull_request` で `bun test` を 1 コマンド実行する
- GAS/CLI を含むシステム全体 E2E は本論点のスコープ外とする

**理由**:
- parser と同期制御（GAS/CLI）を分離して責務境界を明確にするため
- 参照透過な変換ロジックはモックより実入力ベースの Unit テストが有効なため
- MVP ではテスト初期コストを抑えつつ、fixture で退行検知の最低ラインを確保できるため
- CI で `bun test` を自動実行し、手動実行漏れを防止するため

**未決/リスク**:
- 初期 3 fixture の具体 XML は実装時に最終確定する

**ステータス**: 決定済み

---

### 論点 6: パッケージ運用方針

**ゴール**: リリース・バージョニング・依存方針を決める

**制約**: MVP 段階での素早い反復が必要

**期待するアウトプット**: 初期配布方法、バージョニング戦略

**決定**:
- 開発初期〜MVP は `file:../atlassian-doc-parser` でローカル参照を継続する
- バージョニングは `0.x` 系で運用し、破壊的変更は `minor` で明示する
- npm 公開後に `confluence-mirror` 側から参照する際は `~0.x.y` を使用し、`patch` のみ自動追従する
- npm public 公開の開始条件を次で固定する:
  1. 初期 fixture 3 件 + 既知不具合の回帰 fixture が CI（`bun test`）で常時 green
  2. 公開 API（`convertConfluenceStorageToMarkdown`, `ConvertResult`, `ConvertOptions`）の互換性方針を README に明記
  3. `confluence-mirror` との統合検証を 1 回以上完了
  4. 初版 `CHANGELOG` を用意

**理由**:
- ローカル参照を維持すると MVP の実装反復が最速になる
- `0.x` と `~0.x.y` を組み合わせると、破壊的変更の混入を防ぎつつ修正取り込みを自動化できる
- 公開開始条件を先に固定することで、タイミング判断の主観差を減らせる

**未決/リスク**:
- `1.0.0` へ移行する厳密条件（API 固定範囲、サポート方針）は MVP 後に別論点で定義する

**ステータス**: 決定済み
