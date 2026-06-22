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
`Main.socket` did.

- [ ] Finish login and session establishment.
  - Handle `loginSuccessful` and all login failure/socket-close commands, apply
    returned account/server state, transfer the live socket to normal command
    routing, and enter `LobbyPage` for both account and guest login.
  - Port remembered-account selection/deletion, secure credential persistence,
    forgot-password, account-creation follow-up, server refresh/selection, and
    exact cancel/retry/error behavior from `flash/menu`.
  - Replace status text and click-to-cycle stand-ins with the authored popup and
    component behavior; cover guest, member, bad credentials, full/down server,
    disconnect, reconnect, and canceled login.
- [ ] Replace the campaign-harness redirect with the real level-entry protocol.
  - Port slot selection, `CourseMenu`, access checks, password/private flows,
    spectating, room commands, loading/cancel/error states, and game-page
    transition from `flash/level_browser`, `flash/page/GamePage.as`, and
    `flash/gameplay/Game.as`.
  - Load the level selected by the server without reloading the browser or
    opening `?screen=campaign`; preserve the live socket and lobby state.
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

- [x] Correct character-part vertical registration. Against
  `test/baselines/flash/08_standing.jpg`, normalized to the feet line, feet match
  but body is about 7 px and head about 11 px too high. Sizes already match, so
  fix registration/spacing without rescaling the parts. Recheck default,
  recolored, mixed, and tricky outfits in standing, running, crouching, jumping,
  swimming, frozen, and bumped states.
- [ ] Audit the harness physics against `character/LocalCharacter.as` rather than treating existing mechanic fixtures as final parity.
  Compare acceleration, deceleration, stat formulas, jump/crouch, water, ice,
  rotation, collision ordering, corner resolution, moving blocks, item timing,
  hurt/freeze recovery, and finish detection.
- [ ] Port gameplay behavior not represented by the local harness: hats and hat
  powers, eggs/hearts, cowboy mode, artifact/special events, prizes, experience,
  rank progression, race modes, captcha, and server-authoritative interactions.
- [ ] Validate real level decoding/rendering across read modes and representative
  legacy levels, including malformed or old payloads, all background effects,
  drawing/text ordering, stamps, block options, rotations, and object limits.

Acceptance: scripted input and server transcripts produce matching Flash debug
state at agreed checkpoints, and representative race screenshots stay within
documented image-diff thresholds.

## Lobby and Account Completion

The lobby shell and tabs exist, but a number of interactions are currently
record-only or fixture-driven. Audit every reachable control against the AS3;
do not infer completion from the presence of a tab or exported symbol.

- [ ] Replace `LobbyPopups.lastRequest` stand-ins with functional player,
  guest-player, guild, level-info/report, external-link, admin/moderation, and
  social-action popups, including their network requests and refresh behavior.
- [ ] Implement the bottom-strip destinations: options (quality, controls,
  songs), store/vault and quantity/purchase flows, credits, and level editor.
  Preserve guest/member visibility and logout side effects.
  - Credits: `pr2.lobby.dialogs.CreditsPopup` now opens from the bottom strip and
    renders the authored `CreditsPopupGraphic` with a working close button
    (`?screen=popup&popup=credits`). Remaining parity gaps vs `menu/CreditsPopup.as`:
    the committed XFL symbol no longer exports `versionBox`/`buildBox` or the
    `art_nav_bts`/`music_nav_bt` page-navigation links, and `PR2MovieClip` skips
    `visible:false` layers, so only the authored-visible credit pages (`artPg3`,
    `musicPg2`) instantiate — the earlier art/music pages and the version/build
    display are unreachable without a re-exported symbol (or runtime support for
    instantiating hidden layers) plus the older nav instances.
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

## Audio

- [ ] Inventory and extract every music and sound asset referenced by
  `flash/sounds`, `flash/ui/GameSound.as`, gameplay, menus, and timelines while
  preserving loop points, volume, and linkage identity.
- [ ] Port `SoundEffects`, music selection, mute/options persistence, overlapping
  effect rules, page/race transitions, and stop/fade behavior.
- [ ] Add the smallest browser-unlock layer needed for autoplay policy while
  preserving Flash behavior after the first user gesture; verify timing in
  intro, lobby, gameplay, items, and finish flow.

## Runtime and Visual Coverage

- [ ] Audit generated timelines against Flash for masks, filters, blend modes,
  color transforms, nested frame scripts, sound frames, dynamic text/font
  embedding, buttons, nine-slice scaling, and unload/disposal behavior. Add a
  reduced fixture for every runtime fix.
- [x] Static-text attribute fidelity in `PR2MovieClip.createStaticText`.
  `createStaticText` now parses `textAttrs.fillColor` (e.g. the credits'
  `#254489`) into the format color instead of hardcoding `0x000000`, applies
  `letterSpacing`, maps `lineSpacing` to `TextFormat.leading`, and honors
  `leftMargin`/`rightMargin`; `alignment`, `size`, and `lineHeight` were already
  handled. Covered by a deterministic reduced fixture in
  `PR2MovieClipRuntimeTest.testStaticTextHonorsAuthoredAttributes` (styled vs.
  plain static text) and a `compare_symbol_render` case `credits-art-pg1`
  (symbol `UI/Popups (outside levels)/Credits/artPg1`, reference
  `vector-art/png/menus/credits_art_pg1@4x.png`, exported via the committed
  `generate_other_assets_jsfl.py` pipeline). The render confirms blue
  `#254489` labels and black `by`. Its `rmsDelta` remains comparatively high
  because OpenFL's DejaVu substitution and browser text rasterization differ
  from Animate's Verdana export; the threshold locks in the current appearance.
- [x] Preserve static-text `left` offsets when applying authored transforms.
  XFL stores a text field's local layout offset separately from its element
  matrix. `createStaticText` previously assigned that offset to `TextField.x`,
  after which `applyElementProperties` replaced the complete transform matrix
  and discarded it. In the credits popup this moved every `by` field about 65
  pixels left into the preceding label; it was not Verdana/DejaVu metric drift.
  Static text now composes the local offset as `matrix * translate(left, 0)`,
  including scaled or rotated matrices, with a reduced regression fixture in
  `PR2MovieClipRuntimeTest.testStaticTextHonorsAuthoredAttributes`. Font metrics
  and kerning may still produce small visual differences and should only be
  adjusted when a focused comparison demonstrates a remaining discrepancy.
- [ ] Remove authored-symbol fallbacks from reachable screens. Expand the asset
  manifest only as screens are ported, commit generated output, and keep normal
  builds independent of Adobe Animate.
- [ ] Establish per-screen screenshot thresholds and compare at exact 550x400
  stage size for default, hover, pressed, focused, disabled, loading, populated,
  empty, and error states. Keep visual metrics alongside baselines so “looks
  close” is not the acceptance criterion.
- [ ] Audit cleanup across repeated login/lobby/race/editor transitions: event
  listeners, timers, sockets, bitmap data, audio, and display-list references
  must not leak or duplicate behavior.
- [x] Flatten static `PR2MovieClip` subtrees with `cacheAsBitmap` to cut the
  lobby's per-frame GPU compositing cost. `FlattenPolicy` caches only top-level
  subtrees proven temporally static and free of mask/filter/blend risks, so
  animated or stateful content requires no invalidation and remains uncached.
  The policy is enabled by default and improved measured GPU Chrome performance
  from 18.7fps to the 60fps vsync cap. Deterministic analyzer/safety tests and
  the full verification gate cover lobby interaction and the locked 550x400
  post-flatten screenshot (maximum observed delta 2/255).

## Test and Release Matrix

- [ ] Add recorded/offline fixtures for all HTTP and socket workflows so CI does
  not depend on production PR2 services; keep separate opt-in real-server smoke
  tests that cannot mutate accounts or levels unexpectedly.
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
