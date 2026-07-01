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
- [ ] Port block options.
- [ ] Port selection/deletion.
- [ ] Port undo-equivalent behavior.
- [ ] Port camera/zoom.
- [ ] Port editor settings.
- [ ] Port the hats/items/music menus.
- [ ] Port the test-course transition.

Then the level-management flows, one at a time:

- [ ] Port the load flow with its validation, access rules, popups, server
  format, loading/errors, and return navigation.
- [ ] Port the save flow with the same coverage.
- [ ] Port the upload flow with the same coverage.
- [ ] Port the delete flow with the same coverage.
- [ ] Port the report-management flow with the same coverage.

Acceptance: a user can load, edit, test, save, and reopen a real level with the
same serialized meaning and visible result as Flash.
