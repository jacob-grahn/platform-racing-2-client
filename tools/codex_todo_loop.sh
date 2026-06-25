#!/usr/bin/env bash
set -euo pipefail

max_runs="${MAX_RUNS:-0}"
last_output="${LAST_OUTPUT:-/tmp/codex-todo-loop-last.txt}"

prompt='Read README.md and TODO.md. Pick exactly one incomplete TODO item. Either implement it fully, or break the TODO item into subtasks and implement one subtask fully. Run the relevant tests. Update TODO.md. Stop after one item. If there are no actionable TODO items left, reply exactly DONE and make no changes. If you made a change, reply with only a short git commit message, 72 characters or fewer, with no bullet, code fence, or explanation.'

run_count=0

while true; do
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Working tree is dirty before starting; stop." >&2
    git status --short >&2
    exit 1
  fi

  if [[ "$max_runs" != "0" && "$run_count" -ge "$max_runs" ]]; then
    echo "Reached MAX_RUNS=$max_runs; stop."
    exit 0
  fi

  run_count=$((run_count + 1))
  echo "Starting Codex TODO run $run_count..."

  codex -a never exec \
    --sandbox workspace-write \
    --ephemeral \
    "$prompt" \
    -o "$last_output"

  if grep -q "DONE" "$last_output" && git diff --quiet && git diff --cached --quiet; then
    echo "Codex reported DONE and made no changes."
    exit 0
  fi

  if git diff --quiet && git diff --cached --quiet; then
    echo "Codex made no changes; stop. Last output:" >&2
    cat "$last_output" >&2
    exit 1
  fi

  git add -A
  commit_message="$(tr -d '\r' < "$last_output" | sed '/^[[:space:]]*$/d' | tail -n 1)"

  if [[ -z "$commit_message" || "$commit_message" == "DONE" ]]; then
    echo "Codex changed files but did not provide a commit message; stop. Last output:" >&2
    cat "$last_output" >&2
    exit 1
  fi

  git commit -m "$commit_message"
done
