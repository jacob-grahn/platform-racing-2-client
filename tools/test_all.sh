#!/usr/bin/env bash
set -uo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ARTIFACT_DIR="$ROOT/test/output/test-all"
mkdir -p "$ARTIFACT_DIR"
cd "$ROOT"

run_step() {
  local name="$1"
  shift
  local log="$ARTIFACT_DIR/$name.log"

  echo "==> $name"
  if "$@" 2>&1 | tee "$log"; then
    return 0
  fi

  local status=${PIPESTATUS[0]}
  echo "FAILED: $name (exit $status); log: ${log#$ROOT/}" >&2
  exit "$status"
}

run_step deterministic haxe test/deterministic.hxml
run_step protocol haxe test/protocol.hxml
run_step html5-build haxelib run openfl build html5

for case in default colors mixed-parts tricky-parts; do
  run_step "character-$case" \
    python3 tools/openfl_driver.py sequence "test/sequences/openfl/character-$case.json"
done

echo "All tests passed. Logs: ${ARTIFACT_DIR#$ROOT/}"
