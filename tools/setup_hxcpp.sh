#!/bin/sh

set -eu

# hxcpp 4.3.2 from Haxelib produces Android binaries that can fail at startup
# with a missing __atomic_compare_exchange_4 symbol. Haxelib has not published
# the newer 4.3.x releases, so install the exact official GitHub tag locally.
HXCPP_TAG=v4.3.146

haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp.git "$HXCPP_TAG"

# Git/source installations do not include the generated command-line tool.
cd .haxelib/hxcpp/git/tools/hxcpp
haxe compile.hxml
