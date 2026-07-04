#!/usr/bin/env bash
# Run the deterministic suite split across four Haxe interpreter processes.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACT_DIR="$ROOT/test/output/deterministic-parallel"
mkdir -p "$ARTIFACT_DIR"

cd "$ROOT"

pids=()
for shard in 1 2 3 4; do
	haxe "test/deterministic-shard${shard}.hxml" >"$ARTIFACT_DIR/shard${shard}.log" 2>&1 &
	pids+=("$!")
done

status=0
for i in "${!pids[@]}"; do
	shard=$((i + 1))
	if ! wait "${pids[$i]}"; then
		echo "deterministic shard ${shard} failed: test/output/deterministic-parallel/shard${shard}.log" >&2
		status=1
	fi
done

if [ "$status" -eq 0 ]; then
	echo "Deterministic shards passed. Logs: test/output/deterministic-parallel/"
fi

exit "$status"
