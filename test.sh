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
#   ./test.sh protocol       # runs test/protocol.hxml
#   ./test.sh real-server    # runs test/real-server.hxml
set -euo pipefail

cd "$(dirname "$0")"

suite="deterministic"
suite_was_set=false
full_suite=false
groups=""

add_group() {
	if [[ -z "$groups" ]]; then
		groups="$1"
	else
		groups="$groups,$1"
	fi
}

usage() {
	echo "Usage: $0 [deterministic|protocol|real-server] [--full] [domain flags]"
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

# These generated inventories are also architectural boundaries: existing
# Flash-presentation adapters may shrink, but production code cannot add a new
# PR2MovieClip/Fl*/generated-timeline dependency unnoticed.
python3 tools/generate_deflash_symbol_inventory.py --check
python3 tools/audit_deflash_boundaries.py --check
python3 tools/check_no_compat_runtime.py --source-only
python3 tools/generate_native_assets.py --check
python3 tools/generate_svg_packs.py --check
python3 tools/validate_character_lottie.py --xfl-parity
python3 tools/generate_effect_lottie.py --check
python3 tools/compose_static_xfl_symbol_svg.py --symbol Parts/Hats/Jellyfish/jellyfishSting --out art/svg/effects/sting_ray.svg --check
python3 tools/compose_static_xfl_symbol_svg.py --symbol MovieClips/lightningStrike --out art/svg/effects/lightning_strike.svg --check
python3 tools/compose_static_xfl_symbol_svg.py --symbol "Graphics/Symbol 1015" --out art/svg/effects/lightning_flash.svg --check
python3 tools/extract_xfl_bitmaps.py --check

if [[ -n "$groups" ]]; then
	full_suite=true
fi

hxml="test/${suite}.hxml"

if [ ! -f "$hxml" ]; then
	echo "No such suite: $hxml" >&2
	exit 1
fi

if [[ "$full_suite" == true ]]; then
	PR2_TEST_MODE=full PR2_TEST_GROUPS="$groups" haxe "$hxml" 2>&1
else
	PR2_TEST_MODE=smoke PR2_TEST_GROUPS= haxe "$hxml" 2>&1
fi
