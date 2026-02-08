# 005: MVP 未決事項（決定反映）

- **status**: closed
- **date**: 2026-02-07
- **participants**: ユーザー, Codex (GPT-5)
- **origin**: [001_atlassian-doc-parser-spec.md](./001_atlassian-doc-parser-spec.md) の論点 4-6

## 目的

次ラウンドで判断した未決事項の決定内容を、参照しやすい形で記録する。

## 解決済み事項

### 論点 4: エラーハンドリング方針（決定済み）

**決定**:
- `ConvertOptions.strict?: boolean` を MVP から公開（default: `false`）
- `strict=false` は Best Effort（未対応要素とノード単位変換失敗を warning 化して継続）
- `strict=true` は Fail Fast（warning 相当も含めて例外）
- 例外時は `ConvertResult` を返さず `ConvertError` を throw

**ステータス**: 決定済み（詳細: [006_error-handling-policy.md](./006_error-handling-policy.md)）

---

### 論点 5: MVP テスト基準（決定済み）

**ゴール**: MVP リリース時の最低限の品質基準を決める

**制約**: 開発効率と品質のバランス

**期待するアウトプット**: テスト戦略、合格ライン確定

**決定**:
1. parser の責務は XML 入力から規定出力への変換に限定し、テスト主軸は Unit テストとする
2. parser は参照透過な関数群として扱い、Unit テストではモックを使わない
3. 初期 fixture は 3 件（代表ケース 1 件 + 複雑ケース 2 件）を採用する
4. fixture の具体 XML/期待出力は実装時に確定する
5. 不具合が発生した入力は fixture へ都度追加し、回帰防止とする
6. CI は `push` / `pull_request` で `bun test` を 1 コマンド実行する
7. GAS/CLI を含むシステム全体 E2E は本スコープ外とする

**理由**:
1. parser と同期制御の責務を分離できる
2. 参照透過ロジックは実入力ベースの Unit テストで十分検証しやすい
3. MVP では最小 fixture でコストを抑えつつ退行検知を担保できる
4. CI で `bun test` を固定実行することで実行漏れを防止できる

**未決/リスク**:
1. 初期 3 fixture の具体データは実装時に最終確定する

**ステータス**: 決定済み

---

### 論点 6: パッケージ運用方針（決定済み）

**ゴール**: リリース・バージョニング・依存方針を決める

**制約**: MVP 段階での素早い反復が必要

**期待するアウトプット**: 初期配布方法、バージョニング戦略確定

**決定**:
1. 開発初期〜MVP は `file:../atlassian-doc-parser` のローカル参照を継続する
2. バージョニングは `0.x` 系で運用し、破壊的変更は minor で明示する
3. npm 公開後の `confluence-mirror` 側依存は `~0.x.y` とし、patch のみ自動追従する
4. npm public 公開開始は以下 4 条件を満たした時点とする
   - 初期 fixture 3 件 + 回帰 fixture が CI（`bun test`）で green
   - 公開 API の互換性方針を README に明記
   - `confluence-mirror` との統合検証を 1 回以上完了
   - 初版 `CHANGELOG` を作成

**理由**:
1. MVP 段階ではローカル参照が最も反復速度を出しやすい
2. `0.x` 運用で仕様進化を許容しつつ、破壊的変更を管理できる
3. 依存レンジを `~` に固定して破壊的更新の巻き込みを避けられる
4. 公開条件を明文化すると運用判断がぶれにくい

**未決/リスク**:
1. `1.0.0` 移行条件は MVP 後に別途定義が必要

**ステータス**: 決定済み

---

## 完了条件

- 論点 6 の決定を `001_atlassian-doc-parser-spec.md` に反映済み
- パーサーリポジトリ名称の残存記述を統一済み
