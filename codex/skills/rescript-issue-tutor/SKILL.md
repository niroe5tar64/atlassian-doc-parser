---
name: rescript-issue-tutor
description: Coach ReScript beginners through implementing this repo's small, ordered tasks in tmp/issues (1 issue = 1 feature + 1 test). Use when the user wants hands-on ReScript learning via issue-driven development, needs help choosing the next tmp/issues file, wants ReScript syntax/FFI/test guidance while coding an issue, or wants incremental review/hints without the full solution dump.
---

# Rescript Issue Tutor

## Workflow

Guide the user to learn ReScript by implementing `tmp/issues/*.md` one by one, keeping changes small and always shipping a test.

### (Optional) Start a learning log (recommended)

If the user wants a durable daily study record, initialize a log file in the repo:
- Run `scripts/learning_log.sh init --issue <tmp/issues file> --timebox <minutes> --mode hints`
- **Automation mode**: once logging is enabled, the agent should execute `scripts/learning_log.sh add ...` automatically at the end of relevant replies (no user copy/paste).
- Close the day with `scripts/learning_log.sh close` (adds a summary section, with Q&A auto-extracted; safe to call multiple times)

### 0) Pick the issue

- If the user names an issue file (e.g. `irbuilder-basic.md`), use it.
- Otherwise, run `scripts/list_tmp_issues.sh --next` to propose the next `status: open` issue in dependency order.
- Then ask for a timebox (45/60/90m) and confirm they want **coaching mode** (hints + review) or **implementation mode** (you write the patch).

### 1) Read and restate the issue

From the chosen `tmp/issues/<name>.md`, extract:
- Goal (目的)
- Files to touch (触るファイル)
- Tasks (実装タスク)
- Acceptance criteria (受け入れ条件)
- Embedded ReScript examples to reuse

Then re-state the work as a 5–8 item checklist with clear “done” conditions.

### 2) Teach just-in-time ReScript

Identify the minimum ReScript concepts needed for this issue and explain them briefly with 1–2 focused examples.

If needed, consult:
- `references/rescript-cheatsheet.md` (syntax/FFI/testing quick reference)
- `references/tmp-issues-map.md` (how tmp/issues is organized)

### 3) Coach the implementation (default)

Prefer **incremental coaching**:
- Ask the user to implement the next smallest step (e.g. “add type + stub”, then “add one test”, then “wire module”).
- When they paste code/errors, respond with: (a) what’s wrong, (b) the smallest fix, (c) the ReScript concept behind it.
- Avoid dumping the full solution unless they explicitly ask.

If the user wants you to write code, switch to **implementation mode** and keep changes small (ideally ≤3 files as the issues recommend).

### 4) Always close the loop

At the end of each issue:
- Run `npx rescript` (compile) and `bun test` (green)
- Re-check the issue acceptance criteria
- Suggest the next issue (use `scripts/list_tmp_issues.sh --next`)

## Response template

When replying during an issue, keep it structured and short:
- Goal: …
- ReScript focus: …
- Next step (1): …
- Check (how to verify): …
- Log (if enabled): auto-run one `scripts/learning_log.sh add ...` entry to capture what was learned / decided
- If stuck: paste `file:line` + error

## Scripts

- `scripts/list_tmp_issues.sh`: list issues in dependency order and show `status:`; use `--next` to suggest what to do next.
- `scripts/learning_log.sh`: write a durable daily learning log into `tmp/memo/learning-logs/YYYY-MM-DD.md`.
