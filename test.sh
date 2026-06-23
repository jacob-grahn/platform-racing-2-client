#!/usr/bin/env bash
# Run a Haxe test suite with stderr merged into stdout.
#
# Haxe `trace` (the pass/fail output) writes to stderr, so without 2>&1 a run
# looks silent. This wrapper merges the streams and forwards the suite's exit
# code.
#
# Usage:
#   ./test.sh                # runs test/deterministic.hxml (default)
#   ./test.sh protocol       # runs test/protocol.hxml
#   ./test.sh real-server    # runs test/real-server.hxml
set -euo pipefail

cd "$(dirname "$0")"

suite="${1:-deterministic}"
hxml="test/${suite}.hxml"

if [ ! -f "$hxml" ]; then
	echo "No such suite: $hxml" >&2
	exit 1
fi

haxe "$hxml" 2>&1
