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

Optional native desktop target for faster local debugging:

```sh
haxelib run openfl test mac
```

`openfl ...` also works if you install the optional OpenFL command shim, but
`haxelib run openfl ...` works with the repo-local haxelib setup.

The initial skeleton uses the Flash/XFL constants confirmed in the source:

- Stage: 550x400
- Frame rate: 27 FPS
- XFL source of truth: `flash/platform-racing-2-xfl/`

Generated build output is written under `export/`.
