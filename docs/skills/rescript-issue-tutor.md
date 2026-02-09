# rescript-issue-tutor (Codex Skill)

`tmp/issues` を教材にして、ReScript初心者が issue 駆動で実装→テストまで完走するための伴走スキル。

## 保存場所（このリポジトリ内）

- `codex/skills/rescript-issue-tutor/`

## インストール（ローカルの Codex に登録）

Codex は通常 `~/.codex/skills/` 配下のスキルを参照します。

### 推奨: symlink でこのリポジトリをそのまま参照

```bash
mkdir -p ~/.codex/skills
ln -snf "$(pwd)/codex/skills/rescript-issue-tutor" ~/.codex/skills/rescript-issue-tutor
```

### 代替: コピーして登録

```bash
mkdir -p ~/.codex/skills
cp -a "$(pwd)/codex/skills/rescript-issue-tutor" ~/.codex/skills/
```

## 使い方（基本）

- スキルを呼ぶ: `$rescript-issue-tutor`
- 進める対象: `tmp/issues/README.md` の依存順

おすすめの運用（ヒント中心）:
1. 次の issue を選ぶ（依存順）
2. 小さく実装
3. テスト追加
4. `npx rescript && bun test` で green

## 便利スクリプト

### 次の issue を提案

```bash
codex/skills/rescript-issue-tutor/scripts/list_tmp_issues.sh --next
```

### 学習ログ（1日分の記録を Markdown に残す）

出力先: `tmp/memo/learning-logs/YYYY-MM-DD.md`

通常は **ログを有効化したら、以後の記録（add）はAgentが自動実行** する運用を想定しています。
（手動で追記したい場合のみ、下のコマンドを直接叩いてください）

```bash
# セッション開始
codex/skills/rescript-issue-tutor/scripts/learning_log.sh init \
  --issue tmp/issues/scaffold.md --timebox 60 --mode hints

# Q&A を記録
codex/skills/rescript-issue-tutor/scripts/learning_log.sh add \
  --type qa --q "質問" --a "回答"

# 詰まり→解決を記録
codex/skills/rescript-issue-tutor/scripts/learning_log.sh add \
  --type stuck --title "状況" --text "エラー/原因/修正"

# まとめ生成
codex/skills/rescript-issue-tutor/scripts/learning_log.sh close
```
