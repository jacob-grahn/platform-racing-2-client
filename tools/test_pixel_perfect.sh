#!/usr/bin/env bash
# End-to-end pixel-perfect parity run. The shared sequence drives identical
# level selection and gameplay input through Flash and OpenFL.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SEQ="test/sequences/parity/pixel-perfect.json"
TARGET="${1:-flash}"
FLASH_TRACE="test/output/pixel-perfect-flash/physics.log"
HAXE_TRACE="test/output/pixel-perfect-openfl/physics.log"

mkdir -p test/output

case "$TARGET" in
  flash)
    APP="${2:-flash/platform-racing-2.app}"
    FINAL="test/output/pixel-perfect-flash/10-complete.png"
    TRACE="$FLASH_TRACE"
    python3 tools/dmjv_trace_server.py --out "$TRACE" &
    TRACE_PID=$!
    trap 'kill "$TRACE_PID" 2>/dev/null || true' EXIT
    python3 -c 'import time; time.sleep(0.5)'
    echo "==> [flash] Running pixel-perfect sequence against $APP..."
    python3 tools/pr2driver.py --app "$APP" sequence "$SEQ"
    ;;
  port|openfl)
    FINAL="test/output/pixel-perfect-openfl/10-complete.png"
    PROXY_PORT="${PR2_PROXY_PORT:-8123}"
    python3 tools/dev_proxy.py --port "$PROXY_PORT" &
    PROXY_PID=$!
    trap 'kill "$PROXY_PID" 2>/dev/null || true' EXIT
    python3 -c 'import time; time.sleep(1.5)'
    GPU_FLAG="--gpu"
    [ "${PR2_GPU:-1}" = "0" ] && GPU_FLAG=""
    echo "==> [port] Running pixel-perfect sequence against OpenFL..."
    python3 tools/openfl_driver.py --base-url "http://localhost:$PROXY_PORT/index.html?apiHost=/api" $GPU_FLAG sequence "$SEQ"
    ;;
  compare)
    python3 tools/compare_physics_traces.py "$FLASH_TRACE" "$HAXE_TRACE"
    exit $?
    ;;
  both)
    "$0" flash "${2:-flash/platform-racing-2.app}"
    "$0" port
    "$0" compare
    exit $?
    ;;
  *)
    echo "Unknown target '$TARGET' (expected: flash | port | compare | both)" >&2
    exit 2
    ;;
esac

echo "==> Checking for Race Complete! popup with EXP gain..."
python3 tools/check_race_complete.py "$FINAL"
