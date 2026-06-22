# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, 27 FPS timing, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

## Parity Rules

- Treat `flash/**/*.as` and `flash/platform-racing-2-xfl/` as the behavioral and
  visual specification. Do not silently simplify a workflow because the happy
  path works.
- Keep browser transport adaptations behind narrow wrappers. WebSocket and
  same-origin HTTP proxy requirements may differ from Flash; commands,
  responses, state transitions, and visible behavior should not.
- Every ported feature needs deterministic state/protocol coverage and, when it
  is visible, a representative Flash/OpenFL screenshot comparison.
- Temporary drawings, record-only actions, harness redirects, hard-coded data,
  and unsupported buttons are parity gaps and must remain listed here.
- A task is complete only when the real user flow works. Rendering the art or
  recording the requested action is not completion.

## Current Priority: Real Login-to-Race Flow

The next milestone is one uninterrupted real-server session: login, lobby,
select/join a level, race with remote players, finish, and return to the lobby.
The persistent `LobbySocket` must survive every page transition as Flash's
`Main.socket` did. Login and session establishment are complete (see README);
level entry, race sync, and the in-game shell remain.

- [ ] Replace the campaign-harness redirect with the real level-entry protocol.
  - Port slot selection, `CourseMenu`, access checks, password/private flows,
    spectating, room commands, loading/cancel/error states, and game-page
    transition from `flash/level_browser`, `flash/page/GamePage.as`, and
    `flash/gameplay/Game.as`. In-place level loading via `confirm_slot`/
    `startGame` already works (see README); the remaining work is the full
    `CourseMenu`/access/spectate protocol around it.
- [ ] Port multiplayer race synchronization.
  - Implement local update emission, remote character creation/interpolation,
    player join/leave, positions, rotations, stats, hats, items/effects, block
    changes, countdown/start, timer, finish order, spectating, and disconnect.
  - Verify command names, field order, delimiters, update cadence, and rounding
    against the AS3 client and captured server traffic.
- [ ] Port the complete in-game shell and race lifecycle.
  - Implement `Course`, `GamePage`, countdown, race chat, minimap, stats, item
    display, hearts, drawing info, music selection, quit flow, finish page,
    experience gain, prizes, artifact/special-event behavior, and return to
    lobby.
  - Export or wire the authored `FinishedPageGraphic`, `ExpGainGraphic`,
    `DrawingInfoGraphic`, `StatsDisplayGraphic`, `RaceChatGraphic`,
    `MiniMapGraphic`, `MiniMapDot`, `PrizePopupGraphic`, `QuitButtonGraphic`, and
    `MusicSelectionGraphic`; no generic HUD substitutes in parity captures.

Acceptance: an account and a guest can each enter a real race over WebSocket,
see synchronized remote players, finish or quit, and return to the lobby without
a page reload. A deterministic transcript test verifies the full command/state
sequence and screenshots cover level entry, countdown, racing, and finish.

## Gameplay Fidelity

Character-part registration, the `LocalCharacter` physics audit, and real level
decoding/rendering are complete (see README).

- [ ] Port gameplay behavior not represented by the local harness: hats and hat
  powers, eggs/hearts, cowboy mode, artifact/special events, prizes, experience,
  rank progression, race modes, captcha, and server-authoritative interactions.

Acceptance: scripted input and server transcripts produce matching Flash debug
state at agreed checkpoints, and representative race screenshots stay within
documented image-diff thresholds.

## Lobby and Account Completion

The lobby shell and tabs exist, but a number of interactions are currently
record-only or fixture-driven. Audit every reachable control against the AS3;
do not infer completion from the presence of a tab or exported symbol. The
external-link, Options, and Credits popups are already functional (see README).

- [ ] Replace `LobbyPopups.lastRequest` stand-ins with functional player,
  guest-player, guild, level-info/report, admin/moderation, and social-action
  popups, including their network requests and refresh behavior.
- [ ] Implement the remaining bottom-strip destinations: store/vault and
  quantity/purchase flows, and the level editor. Preserve guest/member
  visibility and logout side effects.
- [ ] Verify every Chat, PMs, Players, Account, Campaign, listing, Favorites, and
  Search operation against real HTTP/socket responses. Cover paging, stale and
  out-of-order responses, loading/error/empty states, permissions, unread
  updates, room changes, link handling, and state restoration after a race.
- [ ] Complete account/profile workflows: password/email changes, outfit and
  loadout persistence, part information, guild actions, friend/follow/ignore,
  moderation controls, rank tokens, hotkeys, and server-driven refreshes.
- [ ] Replace any remaining synthetic lobby visuals/data with authored symbols
  and exact Flash typography, masks, scroll behavior, hover/focus states, and
  stacking. Add focused baselines for every popup and non-empty/error state,
  not only the current shell/tab fixtures.

Acceptance: every lobby control performs its original operation against the
real services, all role/guest variants are covered, and no reachable action is
implemented only as a test marker.

## Level Editor and Level Management

- [ ] Port `LevelEditor`, `LevelEditorMenu`, sidebars, tools, drawing/text/stamp
  placement, block options, selection/deletion, undo-equivalent behavior,
  camera/zoom, settings, hats/items/music menus, and test-course transition.
- [ ] Port load/save/upload/delete/report-management flows and their validation,
  access rules, popups, server formats, loading/errors, and return navigation.
- [ ] Round-trip representative original level payloads without semantic drift;
  compare editor and test-course screenshots with Flash at the same camera and
  selected-tool state.

Acceptance: a user can load, edit, test, save, and reopen a real level with the
same serialized meaning and visible result as Flash.

## Runtime and Visual Coverage

Static-text fidelity, authored-symbol fallback removal, and the `FlattenPolicy`
`cacheAsBitmap` optimization are complete (see README).

- [ ] Audit generated timelines against Flash for masks, filters, blend modes,
  color transforms, nested frame scripts, sound frames, dynamic text/font
  embedding, buttons, nine-slice scaling, and unload/disposal behavior. Add a
  reduced fixture for every runtime fix.
- [ ] Establish per-screen screenshot thresholds and compare at exact 550x400
  stage size for default, hover, pressed, focused, disabled, loading, populated,
  empty, and error states. Keep visual metrics alongside baselines so “looks
  close” is not the acceptance criterion.
- [ ] Audit cleanup across repeated login/lobby/race/editor transitions: event
  listeners, timers, sockets, bitmap data, audio, and display-list references
  must not leak or duplicate behavior.

## Test and Release Matrix

- [ ] Verify Chrome, Firefox, and Safari keyboard/focus, rendering, WebSocket,
  audio, storage, and lifecycle behavior. Profile long sessions only after
  behavior is correct, then optimize without changing parity.
- [ ] Prepare the browser release path: production proxy/WebSocket configuration,
  HTTPS, cache/version strategy, preload/error handling, diagnostics, and a
  public test build.
- [ ] After browser parity, port touch controls and package Android/iOS. Mobile
  layout adaptations must not alter the canonical 550x400 game coordinates or
  browser behavior.

## Final 1:1 Audit

- [ ] Build a source-class coverage inventory mapping every first-party AS3
  class and linkage to its Haxe implementation, deliberate platform adapter, or
  verified unreachable/dead status. An exported asset alone does not count as a
  class port.
- [ ] Walk every original user flow and role: guest, member, moderator/admin
  where testable, login failures, lobby/social/account/store, level browsing,
  racing/spectating, editor/management, disconnect/reconnect, and logout.
- [ ] Document only unavoidable browser differences, with evidence that each is
  platform-required rather than an implementation shortcut.

The port is complete when no reachable behavior is a placeholder or harness
redirect, the coverage inventory has no unexplained gaps, and deterministic,
protocol, audio, and visual comparisons demonstrate parity with the Flash
client.
</content>
</invoke>
