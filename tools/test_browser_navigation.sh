#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

haxelib run openfl build html5
python3 tools/openfl_driver.py \
  --metrics-out test/output/browser-navigation-metrics.json \
  sequence test/sequences/openfl/navigation.json
