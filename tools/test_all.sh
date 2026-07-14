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

run_step deterministic env PR2_TEST_MODE=full PR2_TEST_GROUPS= haxe test/deterministic.hxml
run_step protocol haxe test/protocol.hxml
run_step html5-build haxelib run openfl build html5
run_step browser-navigation \
  python3 tools/openfl_driver.py \
    --metrics-out test/output/browser-navigation-metrics.json \
    sequence test/sequences/openfl/navigation.json
run_step lobby-interactions \
  python3 tools/openfl_driver.py sequence test/sequences/openfl/lobby-flow.json
run_step lobby-flatten-capture \
  python3 tools/openfl_driver.py --query 'screen=lobby&user=Tester' --delay 6 \
    shot test/output/lobby.png
run_step lobby-flatten-parity \
  python3 tools/compare_screenshots.py \
    test/baselines/openfl/lobby.png test/output/lobby.png \
    --diff test/output/lobby-diff.png \
    --metrics test/output/lobby-metrics.json \
    --threshold-percent 2 --threshold-rms 1.0

echo "All tests passed. Logs: ${ARTIFACT_DIR#$ROOT/}"
