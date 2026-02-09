# Skills (Codex)

このリポジトリで使う Codex Skill を Git 管理するための案内。

## 置き場所

- スキル本体: `codex/skills/<skill-name>/`
- 使い方ドキュメント: `docs/skills/<skill-name>.md`

## インストール（ローカルの Codex に登録）

Codex は通常 `~/.codex/skills/` 配下のスキルを参照します。

### 推奨: symlink（このリポジトリをそのまま参照）

```bash
mkdir -p ~/.codex/skills
ln -snf "$(pwd)/codex/skills/rescript-issue-tutor" ~/.codex/skills/rescript-issue-tutor
```

### 代替: copy（スナップショットを登録）

```bash
mkdir -p ~/.codex/skills
cp -a "$(pwd)/codex/skills/rescript-issue-tutor" ~/.codex/skills/
```

## スキル一覧

- `rescript-issue-tutor`: `tmp/issues` を教材にして ReScript を伴走学習する  
  - docs: `docs/skills/rescript-issue-tutor.md`
  - skill: `codex/skills/rescript-issue-tutor/`

## 追加・更新のルール

- 1 skill = 1 フォルダ（`codex/skills/<name>/`）
- 必須: `SKILL.md`（YAML frontmatter の `name`/`description` を含む）
- 可能なら `agents/openai.yaml` も同梱（UI用メタデータ）
- スクリプトは `scripts/`、参照資料は `references/` に分ける

