#!/usr/bin/env bash
# Run a Haxe test suite with stderr merged into stdout.
#
# Haxe `trace` (the pass/fail output) writes to stderr, so without 2>&1 a run
# looks silent. This wrapper merges the streams and forwards the suite's exit
# code.
#
# Usage:
#   ./test.sh                # runs one representative test from every deterministic suite
#   ./test.sh --full         # runs the full deterministic suite
#   ./test.sh --physics      # runs every physics test
#   ./test.sh --lobby --items # runs the union of the lobby and item tests
#   ./test.sh --timings      # includes per-test TEST_TIME logging
#   ./test.sh protocol       # runs test/protocol.hxml
#   ./test.sh real-server    # runs test/real-server.hxml
set -euo pipefail

cd "$(dirname "$0")"

suite="deterministic"
suite_was_set=false
full_suite=false
groups=""
timings=false

add_group() {
	if [[ -z "$groups" ]]; then
		groups="$1"
	else
		groups="$groups,$1"
	fi
}

usage() {
	echo "Usage: $0 [deterministic|protocol|real-server] [--full] [--timings] [domain flags]"
	echo "Domain flags:"
	echo "  --audio --blocks --character --crypto --data --effects --gameplay"
	echo "  --items --level-editor --level-rendering --lobby --network --physics"
	echo "  --runtime --ui"
}

for arg in "$@"; do
	case "$arg" in
		deterministic|protocol|real-server)
			if [[ "$suite_was_set" == true ]]; then
				echo "Only one suite may be selected" >&2
				exit 1
			fi
			suite="$arg"
			suite_was_set=true
			;;
		--full)
			full_suite=true
			;;
		--timings)
			timings=true
			;;
		--audio|--blocks|--character|--crypto|--data|--effects|--gameplay|--items|--level-editor|--level-rendering|--lobby|--network|--physics|--runtime|--ui)
			add_group "${arg#--}"
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $arg" >&2
			usage >&2
			exit 1
			;;
	esac
done

if [[ "$suite" != "deterministic" && ( "$full_suite" == true || -n "$groups" ) ]]; then
	echo "--full and domain flags are only supported for the deterministic suite" >&2
	exit 1
fi

if [[ "$full_suite" == true && -n "$groups" ]]; then
	echo "--full cannot be combined with domain flags" >&2
	exit 1
fi

# Keep the production/runtime architectural boundaries enforced independently
# of the documentation-only symbol inventory.
python3 tools/audit_deflash_boundaries.py --check
python3 tools/check_no_compat_runtime.py --source-only
python3 tools/check_enter_frame_clock.py
python3 tools/check_presentation_allocations.py
python3 tools/check_rotation_coordinate_boundaries.py
python3 tools/generate_native_assets.py --check
python3 tools/generate_svg_packs.py --check
python3 tools/validate_character_lottie.py
python3 tools/audit_hairlines.py

if [[ -n "$groups" ]]; then
	full_suite=true
fi

hxml="test/${suite}.hxml"

if [ ! -f "$hxml" ]; then
	echo "No such suite: $hxml" >&2
	exit 1
fi

if [[ "$full_suite" == true ]]; then
	PR2_TEST_MODE=full PR2_TEST_GROUPS="$groups" PR2_TEST_TIMINGS="$timings" haxe "$hxml" 2>&1
else
	PR2_TEST_MODE=smoke PR2_TEST_GROUPS= PR2_TEST_TIMINGS="$timings" haxe "$hxml" 2>&1
fi
