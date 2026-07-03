# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

## Parity Rules

- Treat `flash/**/*.as` and `flash/platform-racing-2-xfl/` as the behavioral and
  visual specification. Do not silently simplify a workflow because the happy
  path works.
- Temporary drawings, record-only actions, harness redirects, hard-coded data,
  and unsupported buttons are parity gaps and must remain listed here.
- A task is complete only when the real user flow works. Rendering the art or
  recording the requested action is not completion.
- Run only the related test cases for your change, the full suite is a bit slow


## Bugs

- [x] Player is moving far away during the 321 countdown, then moves back when it is done
- [x] held items are not visible on the player
- [x] erase lines seem to not work in the level art layers
- [x] push blocks don't work right when the map is rotated
- [x] character dissapears during the rotation animation after hitting a rotate block, and re appears when the rotation animation is done
- [x] blocks can be seen spawning in on the left edge of the screen when running to the left

## Level Editor and Level Management

The lobby-to-editor handoff (permanent-moderator flag, page change, lobby socket
close) is wired; the editor itself is unported.

Port the editor itself, one piece at a time:

- [ ] Port the `LevelEditor`/`LevelEditorMenu` shell and layout.
  - [x] Mount a real `LevelEditor` page from the lobby editor button, create the
    authored `LevelEditorMenuGraphic`, preserve mod/reports mode, guest save/load
    disabling, overlay ordering, and editor singleton cleanup.
- [ ] Port the editor sidebars.
  - [x] Mount the five editor sidebars and wire menu/layer buttons to switch the
    active sidebar.
- [ ] Port the editor tools.
  - [x] Wire editor sidebar entry clicks into a selected-tool state so later
    placement/drawing tools can use the active sidebar item.
- [ ] Port drawing/text/stamp placement.
  - [x] Port stamp object placement onto the active art layer, including
    Flash-style centered coordinate rounding and layer-scale conversion.
  - [x] Port brush drawing/erasing.
  - [x] Port text placement/editing.
    - [x] Port initial text placement on the active art layer, including Flash
      cursor offsets, layer-scale conversion, editable input, and `u`/`y`
      action recording.
    - [x] Port selecting existing text objects for re-editing.
    - [x] Port text color changes, empty-text deletion, and resize/move
      integration.
      - [x] Port empty-text deletion after editing.
      - [x] Port text color changes.
      - [x] Port resize/move integration.
        - [x] Record text object move/resize mutations with Flash `m`/`r`
          action encoding and rounding.
        - [x] Wire text object drag and resize handle interactions.
          - [x] Wire text object drag interactions with Flash rounding and `m`
            action recording.
          - [x] Wire text object resize handle interactions.
- [ ] Port block options.
  - [x] Port Flash-compatible block option string normalization for item,
    teleport, happy/sad stat, and custom-stat blocks.
  - [x] Port block placement/selection enough to attach option buttons to
    placed option-capable blocks.
  - [x] Port the authored item, teleport, stat, and custom-stat option popups
    and commit their values through the normalized editor option strings.
    - [x] Port the authored happy/sad stat option popup and commit-on-close
      behavior.
    - [x] Port the authored item option popup.
    - [x] Port the authored teleport option popup.
    - [x] Port the authored custom-stat option popup.
- [ ] Port selection/deletion.
  - [x] Port placed-block deletion through the blocks sidebar delete tool.
  - [x] Port placed-stamp deletion through the stamps sidebar delete tool.
- [x] Port undo-equivalent behavior.
  - [x] Port undo for object-layer text add/edit/delete/move/resize actions.
  - [x] Port redo for object-layer text actions.
  - [x] Port undo/redo for block and draw layers.
    - [x] Port undo/redo for draw layers.
    - [x] Port undo/redo for block layers.
- [x] Port camera/zoom.
  - [x] Wire the authored editor zoom combo box so it scales the editable
    world and updates stage-to-world placement coordinates.
  - [x] Port keyboard camera panning and Flash scroll clamping.
- [x] Port editor settings.
  - [x] Port editor level-setting state setters and exported level variables
    for song, gravity, time, rank, password, items, hats, mode, cowboy chance,
    and background color.
  - [x] Wire the background color picker sidebar entry to update and export the
    editor background color.
  - [x] Wire the rank, gravity, time, cowboy-chance, and password value popups
    to commit through the editor setting setters.
  - [x] Wire the authored game-mode popup to commit through the editor setting
    setter.
- [x] Port the hats/items/music menus.
  - [x] Port the editor item settings menu.
  - [x] Port the editor hats settings menu.
  - [x] Port the editor music settings menu.
- [x] Port the test-course transition.
  - [x] Wire the editor test button into an in-memory `TestCourse` page that
    plays the current serialized editor data and supports authored back/restart
    controls.
  - [x] Port the test-course stat picker and hat picker parity controls.
    - [x] Port the test-course stat picker, saved test-stat loading, live
      character stat updates, saved stat persistence, and restart restoration.
    - [x] Port the test-course hat picker.

Then the level-management flows, one at a time:

- [ ] Port the load flow with its validation, access rules, popups, server
  format, loading/errors, and return navigation.
  - [x] Port the authored My Levels list popup request, listing render, and
    selected `level_id`/`version` load handoff.
  - [x] Port strict editor-load response validation and the editor variable /
    reports-mode handoff.
- [ ] Port the save flow with the same coverage.
  - [x] Port the authored save dialog, including title/note population and
    counters, empty-title validation, publish/to-newest checkbox behavior, and
    the upload-popup launch handoff.
  - [x] Port `UploadingLevelPopup` request hashing, `upload_level.php` fields,
    drawing retry wait, banned-user override, overwrite confirmation, and
    save-result/error handling.
    - [x] Port request hashing and `upload_level.php` field construction.
    - [x] Port drawing retry wait.
    - [x] Port banned-user override.
    - [x] Port overwrite confirmation.
    - [x] Port save-result/error handling.
- [ ] Port the upload flow with the same coverage.
  - [x] Surface moderator unpublish/restrict upload errors from the authored
    moderation popup.
- [x] Port the delete flow with the same coverage.
- [x] Port the report-management flow with the same coverage.
  - [x] Port the moderator load-mode chooser and reported-levels list/load
    handoff into reports mode.
  - [x] Port the authored report handling popup with archive and social-ban
    flows.

Acceptance: a user can load, edit, test, save, and reopen a real level with the
same serialized meaning and visible result as Flash.

## Refactoring / Tech Debt

- [ ] (Low priority / maybe won't-do) Reconsider whether `ServerLevelRenderer`'s
  asset-path lookups (`blockAssetPath`/`artBackgroundAssetPath`/`stampAssetPath`/
  `fallbackFill`) should become `static final Map` tables. Assessed and deferred:
  the conversion is lateral — the switches are already table-shaped and readable,
  `blockAssetPath` uses OR-patterns + symbolic `ObjectCodes` constants + comments
  that a flat Map would lose, and `fallbackFill` is a 2-branch default. No
  correctness/perf/clarity win, and retyping ~40 entries carries typo risk that
  the tests don't fully cover. Only worth doing if these tables ever need to be
  generated or shared with another consumer.
- [x] Extract race sound handling out of `Course` into a `RaceSounds` helper (the
  `*_SOUND` path constants plus `playWorldJumpSound`/`playCharacterSound`/
  block-bump/item/stat-block cues).
- [ ] Collapse `Character`'s four-slot hat handling (`hat1`..`hat4` /
  `hat1Color`..`hat4Color` / `hat1Color2`..`hat4Color2`) into an array so the
  repeated switch-on-slot logic in `setHats`/`getHighestHat`/`setHatColors`
  disappears. Deferred: these are `public var` fields that mirror the Flash
  `Character` shape and are asserted directly by `CharacterBaseTest`,
  `LocalCharacterTest`, `RemoteCharacterConsumeTest`, and
  `CharacterLifecycleTest`. A clean conversion has to change the public API and
  rewrite those assertions at the same time, so it needs deliberate design (e.g.
  array-backed `hatN` property accessors to keep the public surface, or a
  coordinated update of the tests) rather than a mechanical edit. The same
  discrete-slot pattern also drives `CharacterDisplay.renderAtlasParts`; solve
  both together.
