# Learning log format (durable daily notes)

The log is written into the repo as:
- `tmp/memo/learning-logs/YYYY-MM-DD.md`

## What to log (capture everything that matters)

- Goals for the timebox (1–3 bullets)
- Commands run and outcomes (`npx rescript`, `bun test`, etc.)
- Compiler/test errors (exact messages)
- “Stuck” points and the minimal fix
- Questions and answers (Q/A pairs)
- ReScript concepts learned (1–5 bullets)
- Next action for the next session

## Recommended practice during coaching

- Every time you resolve a question: add a `qa` entry.
- Every time you unblock an error: add a `stuck` entry with the error + fix.
- At the end: run `close` to create a “まとめ” section and fill the bullets.

## Script usage

Initialize:

```bash
scripts/learning_log.sh init --issue tmp/issues/scaffold.md --timebox 60 --mode hints
```

Add entries:

```bash
scripts/learning_log.sh add --type qa --q "What is .resi?" --a ".d.ts のような公開API宣言"
scripts/learning_log.sh add --type stuck --title "Unbound module" --text "原因: ... / 修正: ..."
scripts/learning_log.sh add --type cmd --title "compile+test" --text "npx rescript && bun test"
```

Close the day:

```bash
scripts/learning_log.sh close
```

