#!/usr/bin/env bash
# End-to-end feature/physics-parity test: drive the SAME sequence
# (test/sequences/parity/dont-move-jv.json) through the full flow
# (preloader -> intro -> login -> favorites -> "Don't Move JV" -> Play ->
# idle with timing headroom -> Race Complete!) and assert the popup opened with EXP gain.
#
# Usage:
#   tools/test_dont_move_jv.sh flash [path-to-app]   # original Flash projector (default)
#   tools/test_dont_move_jv.sh port                  # OpenFL HTML5 port
#
# Both targets do an identical fresh typed login (haxe-port-test/haxe-port-test): the sequence
# clears any remembered session via the "-" button so both clients reach the same
# name/pass form, with no per-client branching.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SEQ="test/sequences/parity/dont-move-jv.json"
TARGET="${1:-flash}"

mkdir -p test/output

case "$TARGET" in
  flash)
    APP="${2:-flash/platform-racing-2.app}"
    FINAL="test/output/dmjv-flash/10-complete.png"
    echo "==> [flash] Running Don't Move JV parity sequence against $APP (~2.5 min)..."
    python3 tools/pr2driver.py --app "$APP" sequence "$SEQ"
    ;;
  port|openfl)
    FINAL="test/output/dmjv-openfl/10-complete.png"
    PROXY_PORT="${PR2_PROXY_PORT:-8123}"
    echo "==> [port] Starting dev proxy on :$PROXY_PORT (serves build + proxies /api -> pr2hub.com for CORS)..."
    python3 tools/dev_proxy.py --port "$PROXY_PORT" &
    PROXY_PID=$!
    trap 'kill "$PROXY_PID" 2>/dev/null || true' EXIT
    # Give the proxy a moment to bind before the browser navigates.
    python3 -c 'import time; time.sleep(1.5)'
    # Real GPU for the e2e physics run: framerate steadiness matters more here than
    # pixel-identical rendering (set PR2_GPU=0 to fall back to software rendering).
    GPU_FLAG="--gpu"
    [ "${PR2_GPU:-1}" = "0" ] && GPU_FLAG=""
    echo "==> [port] Running Don't Move JV parity sequence against the OpenFL HTML5 build via proxy (~2.5 min)..."
    python3 tools/openfl_driver.py --base-url "http://localhost:$PROXY_PORT/index.html?apiHost=/api" $GPU_FLAG sequence "$SEQ"
    ;;
  *)
    echo "Unknown target '$TARGET' (expected: flash | port)" >&2
    exit 2
    ;;
esac

echo "==> Checking for Race Complete! popup with EXP gain..."
python3 tools/check_race_complete.py "$FINAL"
