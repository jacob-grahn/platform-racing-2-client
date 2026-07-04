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

## Follow-up Port Gaps

### Shared Infrastructure

- [ ] Complete `UploadingPopup.as` Flash compatibility: accept Flash-style
  `URLRequest`/`URLVariables`, data mode, display text, and auto-error-message
  flag while preserving the existing string/map constructor.
- [ ] Add a `SuperLoader` compatibility layer for popup/list loaders: expose raw
  `data`, parsed JSON, progress events, success/error event names, cancellation,
  and listener cleanup so late async responses cannot mutate removed views.
- [ ] Add shared account/guild state helpers for account-change flows: update
  `LobbySession` guild/email/token fields, dispatch account-change listeners,
  and centralize remember-me gating/copy used by account dialogs.
- [ ] Complete `EmblemLoader` local upload infrastructure: browse local images,
  load/fit them to the 100x50 canvas, JPEG90 encode, POST to
  `emblem_upload.php`, expose begin/finish events, and preserve cleanup.
- [ ] Port the authored `GuildNameGraphic` helper: emblem surface, hand cursor,
  GuildPopup click routing, `makeWidth`, bold/wide modes, and cleanup.
- [ ] Provide a reusable `SelectableButton` hover/selected wrapper for popup
  rows and menus that still use ad hoc hover state.
- [ ] Add popup stacking/anchoring helpers for Options/account submenus so
  account and guild buttons stack at Flash positions without duplicating layout
  math.
- [ ] Add shared stage-focus reset hooks for Flash controls: `PageNavigation`
  links, combo close events, `GameSound` combo close, and account/dialog close
  paths should return focus like Flash.
- [ ] Add a reusable async-removal guard for list loaders and popups so HTTP
  callbacks unregister or no-op after teardown.
- [ ] Add a reusable editor tool cursor/lifecycle helper for authored cursor
  graphics, zoom-scaled cursor sizing, hidden system mouse, stage listeners, and
  Cmd/Ctrl temporary tool swaps.

### Lobby Dialogs And Account Workflows

- [ ] Complete `GuildPopup.as` emblem display: render the loaded guild emblem
  image/placeholder with the authored sizing and remove loaders on close.
- [ ] Complete `GuildPopup.as` admin delete behavior: wire `delete_bt`,
  preserve trial-mod restrictions, confirm/delete via `guild_delete.php`, update
  account state when deleting the current guild, and clean up listeners/loaders.
- [ ] Complete `GuildPopup.as` lifecycle cleanup: member rows, scrollbars,
  keyboard listeners, edit/delete bindings, and async guild-info callbacks must
  be fully detached on removal.
- [ ] Port read-only `ItemMenu.as` for level-info hovers: parse Flash item
  strings (`all`, blank, numeric and named backtick entries) and disable every
  checkbox.
- [ ] Port read-only `HatsMenu.as` for level-info hovers: parse disallowed hats,
  disable every checkbox, and force artifact hat unavailable for old Hat Attack
  levels.
- [ ] Complete `LevelInfoPopup.as` data load: fetch `level_data.php` on
  construction and store live/pass/user/time/gravity/items/song/mode/cowboy/
  bad-hat fields with Flash defaults and failure behavior.
- [ ] Complete `LevelInfoPopup.as` hover menus: show the Flash item, hat, part,
  stat, song, mode, password, gravity, time, and user hover popups and close
  mutually exclusive part/level/guild popups.
- [ ] Complete `LevelInfoPopup.as` action buttons: share message text, rating/
  report/moderation actions, delayed action-button tooltips, and cleanup.
- [ ] Complete `LevelInfoPopup.as` play routing: route play through
  `LobbyRight.lookupLevel`, preserve pass/live checks, and close pending popups.
- [ ] Port `LogoutPassPopup.as`: authored password dialog, required password
  validation, AES `{user_name,user_pass}` payload with `Env.LOGIN_KEY` /
  `Env.LOGIN_IV`, POST `i` to `logout.php`, `"Logging out..."` upload state, and
  server password-error handling.
- [ ] Port `SetEmailPopup.as`: authored email confirmation dialog, Enter-key
  submit, required-field/mismatch validation, AES `{email,pass}` payload using
  `Env.ACCOUNT_CHANGE_KEY`/`Env.ACCOUNT_CHANGE_IV`, and POST `data` to
  `account_change_email.php`.
- [ ] Port `TransferGuildPopup.as`: authored email/password/new-owner dialog,
  Enter-key submit, required-field validation, encrypted payload including
  `Main.loggedInAs`, POST `data` to `guild_transfer.php`, and account/guild
  state updates on success.
- [ ] Complete `OptionsPopup.as` account buttons: show/stack change-email and
  guild create/edit/transfer buttons based on login/guild/owner state and open
  the authored dialogs.
- [ ] Complete `OptionsPopup.as` guild leave flow: show `guildLeave_bt` for
  non-owner guild members, confirm, POST `guild_leave.php`, update guild session
  fields, and dispatch account-change.
- [ ] Preserve `OptionsPopup.as` remaining side effects: account/guild hover
  tooltips, jump-sound playback on sound slider release, and cleanup of stacked
  submenus.
- [ ] Preserve `OptionsArtQualityMenu.as` as an auto-dismiss singleton anchored
  to the art button, including the 25ms outside-click arm delay and persistence
  of lossless quality.
- [ ] Preserve `OptionsSongsMenu.as` as an auto-dismiss singleton anchored to the
  music button, including `y -= 45`, numeric disabled-song persistence, and skip
  of unavailable songs 9 and 16.
- [ ] Preserve `PMRFCodesPopup.as` reference links: render clickable PR2 Hub
  URL/text links, Jiggmin username, Newbieland 2 level link, and PR2 Staff guild
  link through `HTMLNameMaker`, with link listeners cleaned up on removal.
- [ ] Complete `PlayerPopup.as` server-owner/rank details: show `Server Owner`
  when the profile user owns the current server and display the real `ExpGain`
  rank supplement.
- [ ] Complete `PlayerPopup.as` guild rendering: replace the text-only guild box
  with the authored linked `GuildName` emblem clip and close guild popups when
  switching popup contexts.
- [ ] Complete `PlayerPopup.as` delayed popups: keep delayed Send PM hover and
  close guild/part/level popups when viewing a user's levels.

### Login, Lobby, And Social Lists

- [ ] Preserve `Lobby.as` temporary-moderator flows: non-guild temp moderators
  should get Flash confirmation/message flows before logout or level-editor
  entry, and level-editor entry should log them out as Flash does.
- [ ] Preserve `Lobby.as` logout flow: non-remembered users POST `/logout.php`
  before clearing user data/closing the socket; remembered users skip the POST.
- [ ] Preserve `Lobby.as` bottom-button effects: Kongregate button hover shows
  and removes the `"Kong Hat"` popup, Noodle Town volume is applied, and lobby
  entry/removal keeps stage quality side effects aligned with Flash.
- [ ] Preserve `LobbyLeft.as` PM notification lifecycle: attach the unread
  container to the PM tab for member lobbies and unregister commands/containers
  on pane teardown.
- [ ] Preserve `CheckServers.as` activation lifecycle: `activate()` starts the
  60-second reload interval and immediately loads `/files/server_status_2.txt`;
  `deactivate()`/`removeBox()` clears interval and target state.
- [ ] Preserve `CheckServers.as` combo behavior: show `Loading...` and
  `No servers found. :(` prompts with enabled-state changes, reuse cached
  servers when possible, and avoid duplicate server ids.
- [ ] Preserve `CheckServers.as` server selection rules: public/guild/private/
  beta sorting and default selection should match Flash.
- [ ] Preserve remaining `CommAuth.as` compatibility: initialize the two
  `SecureStore` encrypted communication tokens instead of using direct
  constants internally.
- [ ] Port `ArtifactHint.as` loading/parsing: `/hint`, `/lotw`, and `/arti`
  should load `/files/level_of_the_week.json` and parse current, first-finder,
  bubbles-winner, and scheduled fields.
- [ ] Port `ArtifactHint.as` chat output: build Fred the G. Cactus messages with
  Flash `makeLevel`/`makeName` links and scheduled
  `Data.getDateTimeStr(..., ["long", "short"])`, then clean up with the chat
  room.
- [ ] Preserve `LoggingInPopup.as` encrypted login payload details: include
  `award_kong`, reset `awardKongNextLogin` after send, and delete reset
  remembered tokens on login error.
- [ ] Preserve `LoggingInPopup.as` post-login state: combine HTTP/socket success
  before entering the lobby, apply `lastAuthTime`, unread notification
  `lastRead`/`lastRecv`, favorites, guild/emblem/email/token fields, per-user
  `Settings.init`, `Presets.load`, and clear user/socket state on close/error.
- [ ] Preserve `social.PlayersTabList` sorting lifecycle: new user rows should
  set `updateSort` and sort on Flash's 500ms interval, not immediately per row.
- [ ] Preserve `PlayersTabUserListDataLoader` and `Guilds` removal safety:
  unregister or guard async callbacks so late HTTP responses cannot mutate
  removed list art.

### Level Browser And Listings

- [ ] Preserve `Campaign.as` initial page selection from
  `Main.server.server_id` and `Main.lastAuthTime.getDay()`.
- [ ] Preserve `Campaign.as` cached campaign info: reuse
  `Memory.memory["campaignInfo" + page]`, delay `showCourses` by 250ms, and use
  the Flash vertical six-page `PageNavigation` at `(328, 26)`.
- [ ] Preserve `LevelListing.as` delayed show behavior while
  `SecureData.userRank` is still negative.
- [ ] Preserve `LevelListing.as` page state: initialize the global/current page
  before any slot can emit `fill_slot` and keep all access-cover/slot cleanup
  side effects.
- [ ] Preserve `LevelItem.as` info hover copy: include Flash's `Updated:` line
  and exact formatting in level-info hovers.
- [ ] Preserve `LevelItem.as` favorite hover/action flow: 500ms add/remove
  favorite hovers and upload cleanup.
- [ ] Preserve `LevelItem.as` password check flow: pass controls stay disabled
  with `"checking..."` until response/error re-enables them.
- [ ] Preserve `Search.as` focus quirks: combo `CLOSE` and Enter-search should
  return focus to the stage.
- [ ] Preserve `Search.as` request quirks: blank searches do not show loading,
  and ID searches initialized on page > 1 reset to page 1 without sending the
  skipped request.

### Level Editor

- [ ] Preserve level-editor sidebar container layout: custom scroll bar, mask,
  30px column, 10px gaps, and authored `SidebarEntry` hover titles/descriptions.
- [ ] Replace generic sidebar entry buttons with authored block/settings/stamp/
  tool/background graphics and exact tooltip copy.
- [ ] Port background sidebar BG1-BG7 behavior: set both editor background color
  and art background code.
- [ ] Port `BackgroundColorPickerButton.as`: use the Flash left-opening picker,
  live commit behavior, and stage-focus update on close.
- [ ] Preserve `MenuButton.as` behavior: transparent 30x30 hit square, hover
  state, and sidebar switching semantics.
- [ ] Preserve `BrushButton.as` behavior: switch to tools sidebar and focus the
  current drawing layer.
- [ ] Preserve `Landscape.as` behavior: switch back to stamps and focus the
  current object layer.
- [ ] Preserve editor `ItemMenu.as` side effects: changing allowed items updates
  `GamePage.course.allowedItems` semantics.
- [ ] Refresh every item block after editor allowed-items changes by calling the
  authored `updateGameItems()` display behavior immediately.
- [ ] Preserve `ModeMenu.as` dropdown auto-dismiss: do not dismiss while the
  ComboBox list is open, commit on close/change, and return stage focus on
  removal.
- [ ] Preserve brush/eraser cursor and target gating: cursor sizing follows zoom,
  drawing only starts outside menus on drawable/editor/grid targets, and drawing
  stops while the drawable layer is busy.
- [ ] Preserve brush stroke segmentation: restart strokes every 10 seconds or
  after 400px travel, rasterize draw strokes, and call erase mode cleanup for
  eraser strokes.
- [ ] Preserve object/stamp placement cancellation and cursor scaling from
  `ObjectPlacer.as`: menu/object-layer clicks cancel placement and stamp drops
  center on authored display bounds.
- [ ] Preserve block-object placement quirks: avoid existing blocks and allow
  drag placement outside the object layer.
- [ ] Preserve `ObjectDeleter.as`: deletion continues while dragging and uses
  the Flash temporary-delete tool lifecycle.
- [ ] Preserve `TextTool.as` cursor/drop behavior: authored
  `TextToolCursorGraphic`, hidden system mouse, `(-5, -16)` drop offset, object
  layer conversion, immediate edit selection, and tool removal after placement.
- [ ] Preserve `DrawObject.as` authored handles: `DeleteButton`, `ResizeButton`,
  and selection outline around real display dimensions.
- [ ] Preserve `DrawObject.as` drag/resize behavior: stage move/up listeners,
  alpha/swap-to-front, zoom-scaled handles, Flash move/delete/resize action
  recording, and undo/current-object cleanup.
- [ ] Preserve `BlockObject.as` interactions: snap block drags to the 30px grid,
  keep start blocks non-overwritable and non-deleteable, and scale option/delete
  controls against parent zoom.
- [ ] Preserve `TextObject.as` edit controls: authored `EditTextButton`,
  `ColorPicker`, hidden display field while editing, max 500 chars, min edit
  width 100, and zoom-scaled edit/color/resize controls.
- [ ] Preserve `TextObject.as` edit semantics: Backspace/Delete only delete when
  not editing or the edit field is empty, blank text deletes, `lastColor` is
  kept, `recordChangeText()` fires on deselect, and escape/parse replacement
  order matches Flash.
- [ ] Preserve level-editor owned-list row hovers: `GetLevelsPopupItem` should
  include Flash's `Updated:` line, `Data.formatNumber()`, full mode names such
  as `"Alien Eggs"`, escaped multiline note HTML, and
  `info.width -= 3; info.x = 550 - info.width`.
- [ ] Preserve reported-level row hovers: creator/version/note/reporter/reason
  formatting and cleanup should match Flash.
- [ ] Complete `LevelEditorMenu.as` new/exit buttons: bind `newButton` and
  `exitButton`, show Flash confirmation prompts, and route exit through
  `ConnectingPopup`.
- [ ] Complete `LevelEditorMenu.as` save/load/report gating: disable save/load
  for guests and save in reports mode, choose `ChooseLevelsModePopup` only when
  reports are allowed, and prevent test-course launch while drawing.
- [ ] Complete `LevelEditorMenu.as` tool state: update sidebars/focused layers/
  undo-redo exactly like Flash and keep zoom changes synced to the tools sidebar.
- [ ] Complete `TestCourse.as` mounting/focus: authored `TestCourseGraphic`
  holder positions and stage focus on every frame.
- [ ] Complete `TestCourse.as` teleport/restart behavior: click-to-teleport with
  `TeleportPop`, reset `TeleportBlock` globals/background rotations/timer/effect/
  background/minimap state on restart.
- [ ] Complete `TestCourse.as` saved state and cleanup: restore saved test stats
  and hat picker state, spawn egg-mode test eggs, and keep back/restart cleanup
  identical to Flash.

### Gameplay, Effects, And Items

- [ ] Port shared `Effect.as` mounting/removal: add effects to
  `EffectBackground.instance`, schedule removal by Flash frame-to-time
  conversion, and clean up enter-frame listeners/course references.
- [ ] Port `PhysicsEffect.as` collision semantics: rotated collision probes,
  gravity/friction, local-player hit boxes/crouch handling, and inactive-block
  opt-in.
- [ ] Port `ShotEffect.as` semantics: shot life/collision ordering, player
  hit/recoil behavior, and cleanup.
- [ ] Port `ArrowEffect.as`: `Arrow2Graphic`, scale 0.25, 15-frame lifetime,
  upward acceleration/fade (`velY -= 0.1`, `y -= velY`, `alpha -= 0.06`).
- [ ] Preserve `BlockPiece.as` defaults: `gravity=1`, `friction=0.95`,
  `fadeRate=0.01`, spread/start args, random rotation/velocity math, and
  fade-until-alpha-zero removal.
- [ ] Preserve `Egg.as` visual randomization: random color transforms for nested
  character color clips and egg base/dots, including colorMC/colorMC2 frame
  stops/visibility.
- [ ] Port `Slash.as`: play `SlashAnimation`, probe the six Flash hit points
  against blocks/local player, and play `SwishSound`.
- [ ] Port `StarEffect.as`: mount `PointyStar` and remove after 15 frames.
- [ ] Port `Sting.as`: follow owner, remove unused side by direction, fade by
  0.05 per frame, and play `StingSound` at owner position.
- [ ] Port `CourseTimer.as` display/timing: `TimerGraphic`,
  server-synchronized `Main.socket.getMS()`, countdown/racing modes, and
  `addTime()`.
- [ ] Port `CourseTimer.as` urgency/pause behavior: red under 30 seconds,
  under-10-second pulse, pause/resume interval behavior, and
  `Course.outOfTimeHandler()`.
- [ ] Complete `DrawingInfo.as` finish-time registration: register/unregister
  `finishTimes` and render up to four results with drawing spinners.
- [ ] Complete `DrawingInfo.as` result details: objective counts, forfeits/gone
  suffixes, local-player star, `"Timing for Nerds"` hover, and Flash campaign
  Kongregate stats.
- [ ] Preserve `Course.as` background/layer rendering: background attachment
  order and per-layer scale/position/color updates.
- [ ] Preserve `Course.as` rotation/camera behavior: 90-degree rotate animation,
  cache toggling, stage quality changes, spectate/key-scroll switching.
- [ ] Preserve `Course.as` HUD/command cleanup: countdown ready/go sounds, timer
  integration, HUD/background/player command listeners, and teardown.
- [ ] Preserve `FinishedPage.as` close lifecycle: closing clears the owning
  game/page `finishedPage` reference.
- [ ] Preserve `FinishedPage.as` EXP stat submission: submit Kongregate
  `"Exp Gained at Once"` when that API is present.
- [ ] Preserve `Game.as` return/removal lifecycle: return-to-lobby only while
  socket connected, and removal closes active `PlaceArtifact`, Lux, prize, and
  hat-countdown state like Flash.
- [ ] Preserve `RaceChat.as` `/level` command: trimmed `/level` during a live
  course opens `LevelInfoPopup` for the current course instead of sending chat,
  while keeping Flash focus/clear behavior.
- [ ] Port the concrete `items.Item` / `Items.getFromCode()` runtime surface:
  instantiate per-item classes instead of only integer switches.
- [ ] Preserve item use/reload gating: `SecureData`-backed uses/reload timing and
  release-before-fire semantics.
- [ ] Preserve weapon item effect payloads: local laser, mine, lightning,
  teleport, sword, and ice wave emit/mount Flash `add_effect` payloads with the
  same positions, rotations, recoil, sounds, ammo updates, and item clearing.
- [ ] Preserve movement item side effects: Jet Pack `beginJet()`/`endJet()` on
  key transitions/refill, Speed Burst stat doubling/sparkles/reset/expiry, and
  Super Jump sound only when not crouching.
- [ ] Preserve concrete item visuals: Laser/Sword/IceWave timelines, Mine
  `MineAppear`, Teleport's two local `TeleportPop` effects, and Lightning's
  local `Zap`.

### Player Profile, Store, And UI Polish

- [ ] Complete `AccountInfo.as` guild rendering with authored linked
  `GuildName` clip/emblem.
- [ ] Complete `AccountInfo.as` manual part updates: support `SET_MANUAL_PART` /
  `partToSet` updates from part-info popups and dispatch level-access retests
  after rank/current-hat changes.
- [ ] Complete `AccountInfo.as` loadout/keyboard behavior: delayed Loadouts
  hover at the Flash offset, number hotkeys blocked while `CourseMenu` is open
  or selectable text has focus, and confirm/apply flow for presets.
- [ ] Port `player_profile.PartInfo` hover/popup entry: 500ms delayed hover at
  Flash offset and clicks open singleton `PartInfoPopup`.
- [ ] Port store `Parts.getPartArray()` catalog rows: authored `PartInfoListing`
  rows with owned/epic/EE state.
- [ ] Preserve special part rendering/obtain links: EpicFlash effects, Djinn/
  Fred/artifact/cheese special rendering, dynamic obtain links, singleton
  fade-outs, and `PartPopup` Equip dispatch through `SET_MANUAL_PART`.
- [ ] Preserve `PresetListing.as` thumbnails: mask second colors through
  `PartSelector.isPartEpic()` before preview render.
- [ ] Preserve `RandomizeStyleButton.as`: Flash `HoverDelayPopup` title/body and
  delayed hover behavior, not only clickable graphic behavior.
- [ ] Preserve Vault/store scrolling and totals: authored `CustomScrollBar`,
  `Data.formatNumber` coin totals, and cleanup of loaders/listeners on close.
- [ ] Preserve Vault/store sale visuals: `EpicFlash` for sale title and sale
  listing titles, and three random colored characters for `epic_everything`.
- [ ] Preserve Vault/store purchase confirmations: price/coin/sale box sizing
  and removal, PR2 Terms of Use link, upload states, and error/success handling.
- [ ] Preserve remaining `ui.CustomCursor` runtime behavior: forward touch events
  and expose Flash cursor identity hooks used by editor tools.
- [ ] Preserve `ui.CustomCursor` temporary delete behavior: Cmd/Ctrl temporary
  `ObjectDeleter` swap/restore through `Memory.memory`, excluding text, brush,
  and eyedropper cursors.
- [ ] Restore `StatSlider.as` hold acceleration: increment/decrement buttons use
  Flash's 8/sec for 0-2s, 16/sec for 2-4s, 32/sec after 4s, and stop on
  bounds/no remaining points.
- [ ] Restore `StatSlider.as` save paths: persist level-editor test stats only
  through mouse-up / `SliderEvent.THUMB_RELEASE` / `updateSavedLEStats` with the
  `inLE()` guard.
