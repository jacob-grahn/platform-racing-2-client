# Platform Racing 2 Haxe/OpenFL Port

This directory contains the Haxe source for the OpenFL port. The root `project.xml`
is the OpenFL project file.

## Prerequisites

- Haxe
- OpenFL and Lime via `haxelib`

Typical setup:

```sh
haxelib install lime
haxelib install openfl
haxelib run lime setup
```

## Build And Run

From the repository root:

```sh
haxelib run openfl test html5
```

OpenFL can also generate an optional native desktop target for faster local
debugging and screenshot comparison:

```sh
haxelib run openfl display mac
MACOSX_VER=26.5 haxelib run openfl test mac
```

`display mac` verifies the OpenFL/Haxe target setup without invoking the native
compiler. `test mac` and `build mac` require a working local Xcode command-line
toolchain. On Xcode versions that expose a minor macOS SDK such as
`macosx26.5`, pass the exact SDK suffix through `MACOSX_VER`; otherwise hxcpp
may request `macosx26` and fail before compiling project code:

```text
xcodebuild: error: SDK "macosx26" cannot be located.
xcrun: error: unable to find utility "clang++", not a developer tool or in PATH
```

Use `xcodebuild -showsdks` to see the installed macOS SDK suffix. The browser
target remains the required development path.

`openfl ...` also works if you install the optional OpenFL command shim, but
`haxelib run openfl ...` works with the repo-local haxelib setup.

The initial skeleton uses the Flash/XFL constants confirmed in the source:

- Stage: 550x400
- Frame rate: 27 FPS
- XFL source of truth: `flash/platform-racing-2-xfl/`

Generated build output is written under `export/`.

## XFL Metadata

The first asset-pipeline helper extracts deterministic JSON metadata from the
Adobe-free XFL source:

```sh
python3 tools/xfl_metadata.py --summary
```

Use the full output without `--summary` when a later pipeline step needs the
library folders, media records, symbol includes, linkage class list, display
instances, and vector shape metadata. `DOMShape` entries include fill styles,
stroke styles, raw edge/cubic command streams, and approximate numeric bounds
for later rendering work.

## Generated Asset Catalog

Generate the first native Haxe asset graph catalog from the XFL metadata:

```sh
python3 tools/generate_haxe_assets.py
```

This writes deterministic source under `haxe/src/pr2/generated/assets/`. The
generated catalog includes media records, linkage classes, symbols, timelines,
layers, frames, labels, display instances, transforms, color transforms, and
shape summary bounds/counts. Raw vector fill/stroke/edge streams are still
available from `tools/xfl_metadata.py`; they are intentionally deferred until
the vector rendering milestone.

To compile-check the generated package directly:

```sh
haxe -cp haxe/src --macro 'include("pr2.generated.assets")' --no-output
```
