# Level Editor E2E Progress

## Goal

Headless browser coverage for: log in, enter the level editor, select a normal
block, draw a floor under the start position, switch to art mode, draw a square,
place a stamp, save, clear, reload, and verify the floor, drawn art, and stamp.

## Progress

- Created this tracker.
- Moved the level editor implementation from `pr2.page` toward the original
  source layout under `haxe/src/pr2/levelEditor`.
- Found the Haxe editor is already substantial, but the browser scenario still
  needs deterministic hooks/assertions for save, clear, load, blocks, art, and
  stamps.
- Added browser-only hooks for deterministic lobby-to-editor entry and an editor
  save/clear/load scenario.
- Added `test/sequences/openfl/level-editor-save-load.json`.
- Built the HTML5 target and ran the new headless sequence successfully.
- Added `test/sequences/openfl/level-editor-live-clicks.json` as a full e2e
  using real browser clicks and the real PR2Hub endpoints through the local dev
  proxy.
- Fixed the editor package location under `haxe/src/pr2/levelEditor`.
- Fixed editor camera/grid behavior so the grid is centered on the visible
  editor viewport instead of drawing around world origin.
- Fixed stamp palette rendering by using exported stamp bitmap assets for stamp
  object previews.
- Fixed real empty-background editor clicks by listening for editor input at the
  stage and by narrowing menu hit testing to actual visible menu shapes.
- The live click e2e now passes through login, level editor entry, floor
  placement, brush art, stamp placement, save, clear, load, and loaded-state
  verification. Latest passing screenshot:
  `test/output/level-editor-live/07-loaded.png`.

## Bugs / Findings

- The editor code was living in `haxe/src/pr2/page/LevelEditor.hx`; this made it
  harder to compare to the original Flash `levelEditor` source package.
- Existing headless sequence actions can click/type and read body attributes,
  but they did not have editor-specific assertions. Added `level-editor-e2e` to
  cover this scenario.
- Editor menu hit testing previously used the menu's broad display bounds,
  causing real clicks in the playfield near the menu to be treated as menu
  clicks.
- Empty editor-space mouse events reached the OpenFL stage but not always the
  editor display tree, so real browser clicks did not mutate level state until
  editor input was handled from the active stage.
- Stamp buttons were blank because stamp codes were looked up as generated
  movieclips; the exported stamp PNGs are now used where available.

## TODO

- Add this sequence to a broader CI/test-all gate once the team decides where
  browser editor coverage belongs.
- Decide whether the browser state diagnostics in the live e2e output should
  remain verbose or be reduced after this workflow stabilizes.
