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

- [ ] Port `com.jcward.workers.JPEGEncoder` / `BitString` or provide an exact
  equivalent for drawing uploads: support `encode()`, `encodeNonNative()`,
  `encodeAsync()` with one outstanding job guard, optional output `ByteArray`,
  native `BitmapData.encode()` fallback detection, Flash quality scaling,
  JFIF/DQT/DHT/SOF/SOS marker output, bit stuffing/alignment, and 8x8 RGB to YUV
  macroblock processing.
- [ ] Preserve `ColorChoices.as` / `ColorPicker.as` swatch behavior exactly:
  initialize recent colors to Flash's alternating `0x888888` / `0x555555`
  values, draw the 22-column by 12-row palette in the same x/y orientation as
  Flash, keep the suggested colors and RGB cube layout, support `direction`
  left/right popup placement, dispatch `Event.CHANGE` only on changed colors, and
  emit `Event.OPEN` / `Event.CLOSE` around popup lifecycle.
- [ ] Port the full `ColorPickerPopup.as` HSV picker: authored popup art,
  OK/cancel behavior, restricted hex text box with `#`/`0x` parsing, current and
  preview outlines, hue slider, saturation/brightness spectrum, preview box,
  stage-edge clamping, mouse-hide drag behavior, and recent-color update on
  close.
- [ ] Port `CursorEyedropper.as` for the color picker: install the authored
  eyedropper custom cursor, pause/restore any previous `CustomCursor`, maintain
  popup/exclusion hit testing, sample the stage bitmap under the cursor without
  including the cursor graphic, dispatch preview `CHANGE` and final `COMPLETE`,
  and dispose the sampling `BitmapData` on removal.
- [ ] Preserve `AESPad.as` / `Encryptor.as` compatibility for PR2 encrypted
  fields: zero-pad by writing NUL UTF bytes until the block boundary, keep the
  Flash `unpad()` behavior used by the original decrypt path, expose the
  Base64-string `setKey()` / `setIV()` / `encrypt()` / `decrypt()` wrapper, and
  keep cleanup semantics for callers that use `com.jiggmin.data.Encryptor`
  instead of the narrow `PR2Encryptor` helpers.
- [ ] Port `ColorUtil.as` as a shared utility with Flash's exact HSB/RGB/hex
  math and rounding: `hsbToRGB`, `rgbToHSB`, `rgbToHex24`, `hex24ToRGB`,
  `argbToHex32`, `hex32ToARGB`, `hex24ToHSB`, `hsbToHex24`, and uppercase
  six-digit `decimalToHex()` should match the AS3 results.
- [ ] Preserve `CommandHandler.as` incoming socket validation and default command
  side effects: buffer EOL-delimited frames, recompute the first-three-character
  MD5 hash with `CommAuth.getToken(server_id)`, reject replayed/out-of-order
  `sendNum`s, handle `resend`, and register the built-in `message`, `setRank`,
  `setGroup`, `startGame`, `pmNotify`, user-role, captcha, tournament,
  `guildChange`, `setServerOwner`, and `wearingHat` commands.
- [ ] Port the full `Data.as` helper surface where UI/protocol code still uses
  it: exact random swear replacements, `parseLinks()` rich-format conversion
  for user/url/level/guild/invite/discord/color/bold/italic/underline/size tags,
  date/time locale formatting, `hash()`, `aOrAn`, `ucfirst`, `formatNumber`,
  `formatTime`, `padString`, `urlify`, `pythag`, `numLimit`, `scaleToFit`,
  `rotatePoint`, `getExpBounds`, and `randomString`.
- [ ] Port `EpicFlash.as` for epic color-cycling display objects: allow items to
  be registered, start/stop a repeating random `ColorTransform.color` tick at the
  configured delay, update delay while active, report emptiness, and clear item
  references on removal.
- [ ] Preserve `HTMLNameMaker.as` link handling beyond basic user/guild/level/url
  links: support invite and Discord verification events, use Flash's group color
  and special-user rules for parsed group strings, keep `encodeURI`-style URL
  handling, and unregister every listened text field on removal.
- [ ] Port the full `Objects.as` `getFromCode()` editor/display mapping:
  tree/rock/spire/building stamps, all block display classes, BG1-BG7 graphics,
  and `TextObjectGraphic().textBox` should resolve from the same numeric codes as
  Flash instead of relying only on gameplay block constants or placeholder assets.
- [ ] Preserve `PR2Socket.as` lifecycle behavior in `LobbySocket`: start the
  Flash ping interval after connect, handle `receivePing` server-time sync, send
  `close`` before disconnecting, reset command send counters, clear cached
  campaign/server role/unread state, and show the Flash disconnect/error popups.
- [ ] Complete `Random.as` public API compatibility: expose `seed`, `nextInt()`,
  `nextMax()`, `nextNumber()`, and `nextBytes()` with the same range checks and
  byte writes as Flash, in addition to the already-ported deterministic
  `nextMinMax()` sequence.
- [ ] Port `SWFStats.as` frame-rate watchdog behavior: sample one-second timing
  deltas, average 30 samples, and force the stage frame rate back to 27 when the
  Flash client would detect lag/speed changes.
- [ ] Preserve `SavedAccounts.as` persistence identity exactly: use
  `pr2hub_dev_logged_in` on dev hosts and `pr2hub_logged_in` elsewhere, keep the
  stored accounts array shape, trim/case-fold names, update tokens in place, move
  recent accounts first, and support delete by `"name"` or `"token"` mode.
- [ ] Preserve `SecureData.as` / `SecureStore.as` obfuscated storage behavior:
  number/bool values should be stored as hidden value-plus-key pairs, string
  storage should support `initEncryptor(keyName, salt)` with random AES key/IV,
  encrypted salt validation, remove semantics, and Flash-compatible getters.
- [ ] Preserve full `Settings.as` per-user SharedObject behavior: initialize
  `pr2_{sanitizedName}` stores, mirror cookie values into static settings and
  session `dataArr`, support partial control/stat updates, keep defaults for
  presets/disabled songs/art/filter/test-hat, and no-op safely when cookies are
  blocked or no user is initialized.
- [ ] Port `Time.as` server clock helper and wire it to socket pings so lobby and
  listing code can use Flash's offset timestamp/day calculations instead of
  local `Date.now()` where server time was authoritative.
- [ ] Port `AdminMenu.as` moderator promotion controls for player popups:
  temporary/trial/permanent promotion confirmations should send
  `promote_to_moderator``name``mode`, demotion should send
  `demote_moderator``name`, and the target popup should fade out after action.
- [ ] Provide a reusable `AutoDismissPopup.as` equivalent for popup menus: arm the
  stage mouse-down listener after the Flash 25ms delay, dismiss only on outside
  clicks using hit-test semantics, and remove the stage listener/timeout on
  cleanup instead of duplicating partial behavior per popup.
- [ ] Preserve `BanMenu.as` exact moderation payloads: include the current chat
  record except in mod/admin rooms, escape the target name in confirmation copy,
  keep trial-mod duration/scope restrictions, and cleanly detach upload success
  and error listeners on removal.
- [ ] Port `ChangePasswordPopup.as`: authored three-field dialog, Enter-key submit,
  password mismatch/current-password validation, AES-encrypted JSON payload using
  `Env.LOGIN_KEY`/`Env.LOGIN_IV`, POST to `change_password.php`, and Flash
  uploading/fade-out behavior.
- [ ] Port `CreateGuildPopup.as` and its edit flow: load guild info for edits,
  display/upload/delete emblems through `EmblemLoader`, post create/edit fields
  to the Flash endpoints, update `Main` guild account state on owner edits, and
  gate transfer behind remember-me.
- [ ] Port `DiscordVerificationPopup.as`: POST the verification code and trimmed
  logged-in PR2 name to `https://jiggmin2.com/discord/verify_pr2.php` through the
  Flash uploading popup and show the `"Verifying..."` progress text.
- [ ] Port `GuildJoinPopup.as`: POST `guild_id` to `guild_join.php`, show the
  `"Joining guild..."` upload state, and on success update the current guild id,
  emblem, name, and owner flag before dispatching the usual account-state change.
- [ ] Complete `GuildPopup.as` guild management behavior: load and display the
  emblem image, wire moderator edit and admin delete buttons, confirm/delete via
  `guild_delete.php`, open `CreateGuildPopup` for edits, preserve trial-mod
  restrictions, and clean up loaders/member rows/keyboard listeners exactly.
- [ ] Port the read-only `ItemMenu.as` and `HatsMenu.as` used by level-info
  hovers: parse Flash item strings (`all`, blank, numeric and named backtick
  entries), disable every checkbox, parse disallowed hats, and force artifact hat
  unavailable for old Hat Attack levels.
- [ ] Complete `LevelInfoPopup.as` data-load and hover/action behavior: fetch
  `level_data.php` on construction, store live/pass/user/time/gravity/items/song/
  mode/cowboy/bad-hat fields, show every Flash hover tooltip/menu, handle share
  message text, close part popups and route play through `LobbyRight.lookupLevel`,
  and preserve delayed action-button tooltips.
- [ ] Port `LogoutPassPopup.as` legacy logout-password flow: require a password,
  encrypt `{user_name,user_pass}` with `Env.LOGIN_KEY`/`Env.LOGIN_IV`, POST
  `i` to `logout.php`, show `"Logging out..."`, and clear user data unless the
  server returns password error type.
- [ ] Complete `OptionsPopup.as` account/guild buttons and side effects: show and
  stack change-password, change-email, guild leave/create/edit/transfer buttons
  based on login/guild/owner state, wire `guild_leave.php` and account-change
  updates, and preserve hover tooltips plus jump-sound playback on sound slider
  release.
- [ ] Preserve `OptionsArtQualityMenu.as` and `OptionsSongsMenu.as` as
  auto-dismiss singleton popups anchored to their buttons, including the Flash
  25ms outside-click arm delay, `y -= 45` music offset, disabled-song persistence
  as numeric ids, and skip of unavailable songs 9 and 16.
- [ ] Preserve `PMRFCodesPopup.as` link examples through `HTMLNameMaker`: the
  reference popup should render clickable PR2 Hub URL/text links, a clickable
  Jiggmin username, Newbieland 2 level link, and PR2 Staff guild link with link
  listeners cleaned up on removal.
- [ ] Complete `PlayerPopup.as` parity details: wire `AdminMenu` for admins,
  show `Server Owner` when the profile user owns the server, use the authored
  `GuildName` emblem/link clip, display the real `ExpGain` rank supplement, keep
  delayed Send PM hover, and close guild/part/level popups when viewing a user's
  levels.
- [ ] Port `SetEmailPopup.as`: authored email confirmation dialog, Enter-key
  submit, required-field/mismatch validation, AES-encrypted `{email,pass}` payload
  using `Env.ACCOUNT_CHANGE_KEY`/`Env.ACCOUNT_CHANGE_IV`, and POST `data` to
  `account_change_email.php`.
- [ ] Port `TransferGuildPopup.as`: authored email/password/new-owner dialog,
  Enter-key submit, required-field validation, encrypted payload including
  `Main.loggedInAs`, and POST `data` to `guild_transfer.php`.
- [ ] Preserve `UploadingPopup.as` compatibility surface: accept a Flash-style
  `URLRequest`, data mode, display text, and auto-error-message flag; expose raw
  `data`, parsedData, progress updates, `Event.COMPLETE`, SuperLoader success/error
  events, close button behavior, and listener cleanup matching the Flash popup.
- [ ] Preserve editor brush/eraser tool quirks from `Brush.as` and `Eraser.as`:
  custom cursor sizing with zoom, draw only outside menus on drawable/editor/grid
  targets, restart strokes every 10 seconds or after 400px travel, stop when the
  drawable layer is busy, rasterize draw strokes, and call erase mode cleanup for
  eraser strokes.
- [ ] Preserve editor object placement/deletion quirks from `ObjectPlacer.as`,
  `BlockObjectPlacer.as`, and `ObjectDeleter.as`: cursor graphics/scaling should
  follow editor and layer zoom, menu/object-layer clicks cancel placement, stamps
  center on their authored display bounds, block-object placement should avoid
  existing blocks and allow drag placement outside the object layer, and deletion
  should continue while dragging.
- [ ] Preserve `TextTool.as` placement behavior: use the authored
  `TextToolCursorGraphic`, hide the system mouse while active, offset drops by
  `(-5, -16)` before converting to the object layer, select/start-edit the new
  text object immediately, and remove the cursor tool after placement.
- [ ] Preserve level-editor sidebars as authored Flash UI: `SideBar` should use
  the custom scroll bar, mask, 30px column, 10px gaps, and `SidebarEntry` hover
  titles/descriptions; block/settings/stamp/tool/background entries should use
  their authored button graphics and exact tooltip copy instead of generic text
  boxes.
- [ ] Port background sidebar button behavior from `Backgrounds.as`,
  `BackgroundButton.as`, and `BackgroundColorPickerButton.as`: BG1-BG7 entries
  should set both the editor background color and art background code, and the
  color picker should use the Flash left-opening picker and update stage focus
  on close.
- [ ] Preserve `MenuButton.as`, `BrushButton.as`, and `Landscape.as` editor
  button behavior: menu buttons need the transparent 30x30 hit square, brush
  should switch to the tools sidebar and focus the current drawing layer, and
  landscape should switch back to stamps and focus the current object layer.
- [ ] Preserve `ItemMenu.as` editor side effects: when allowed items are changed,
  update `GamePage.course.allowedItems` semantics and refresh every item block's
  authored `updateGameItems()` display so existing item blocks reflect the new
  allowed item list immediately.
- [ ] Preserve `ModeMenu.as` dropdown auto-dismiss behavior: track ComboBox
  open/close state so outside clicks do not dismiss the popup while the dropdown
  list is open, commit on close/change, and return stage focus on removal.
- [ ] Port `ArrowEffect.as`: create the `Arrow2Graphic` feedback effect at the
  activation point, scale it to 0.25, schedule removal after 15 frames, and on
  each frame apply Flash's upward acceleration/fade (`velY -= 0.1`, `y -= velY`,
  `alpha -= 0.06`).
- [ ] Preserve `BlockPiece.as` physics defaults exactly: fragment effects should
  use Flash's constructor parameters (`gravity=1`, `friction=0.95`,
  `fadeRate=0.01`, spread/start arguments), random rotation/velocity math, and
  fade-until-alpha-zero removal unless a caller explicitly overrides them.
- [ ] Port the shared `Effect.as`, `PhysicsEffect.as`, and `ShotEffect.as`
  semantics for runtime effects: add effects to `EffectBackground.instance`,
  schedule removal by Flash frame-to-time conversion, preserve rotated physics
  collision probes, local-player hit boxes/crouch handling, shot life/collision
  ordering, inactive-block hit opt-in, player hit/recoil behavior, and cleanup of
  enter-frame listeners/course references.
- [ ] Preserve `Egg.as` visual randomization: spawned egg minions should apply
  Flash's random color transforms to the nested character color clips and egg
  base/dots, including colorMC/colorMC2 frame stops/visibility, in addition to
  the already-ported seeded movement/attack lifecycle.
- [ ] Port concrete `Slash.as`, `StarEffect.as`, and `Sting.as` runtime effects:
  slash should play `SlashAnimation`, hit the six Flash probe points against
  blocks/local player, and play `SwishSound`; star should mount `PointyStar` for
  15 frames; sting should follow its owner, remove the unused side by direction,
  fade by 0.05 per frame, and play `StingSound` at the owner's position.
- [ ] Port `CourseTimer.as`: use `TimerGraphic`, server-synchronized
  `Main.socket.getMS()` timing, countdown/racing modes, `addTime()`, red
  under-30-second display, under-10-second pulse animation, pause/resume interval
  behavior, and `Course.outOfTimeHandler()` callback.
- [ ] Complete `DrawingInfo.as` finish-times behavior: register/unregister
  `finishTimes`, render up to four results with drawing spinners, objective
  counts, forfeits/gone suffixes, local-player star and `"Timing for Nerds"`
  hover, and submit Kongregate stats for the Flash campaign course ids.
- [ ] Complete `Course.as` race-shell parity around rotation/camera/HUD:
  preserve background attachment order, per-layer scale/position/color updates,
  90-degree rotate animation with cache toggling and stage quality changes,
  spectate/key-scroll switching, countdown ready/go sounds, timer integration,
  and cleanup of every HUD/background/player command listener.
- [ ] Preserve `FinishedPage.as` / `Game.as` completion lifecycle details:
  closing the finish popup should clear the owning game/page `finishedPage`
  reference, EXP gain should submit the Flash Kongregate `"Exp Gained at Once"`
  stat when that API is present, return-to-lobby should only emit/change pages
  while the socket is connected, and game removal should close any active
  `PlaceArtifact` popup plus Lux/prize/hat-countdown state exactly like Flash.
- [ ] Preserve `RaceChat.as` `/level` command behavior: pressing Enter with
  trimmed input `/level` during a live course should open `LevelInfoPopup` for
  the current course id instead of sending a chat packet, while keeping the
  Flash focus/clear behavior.
- [ ] Complete `TestCourse.as` editor-test parity: mount the authored
  `TestCourseGraphic` in the Flash holder positions, keep stage focus on every
  frame, support click-to-teleport with `TeleportPop` effects, reset
  `TeleportBlock` globals/background rotations/timer/effect/background/minimap
  state on restart, restore saved test stats and hat picker state, spawn egg-mode
  test eggs, and keep back/restart cleanup identical to Flash.
- [ ] Port the concrete `items.Item` / `Items.getFromCode()` runtime surface:
  instantiate per-item classes instead of only integer switches, preserve
  `SecureData`-backed uses/reload timing and release-before-fire gating, and
  have local item use emit/mount Flash `add_effect` payloads for laser, mine,
  lightning, teleport, sword, and ice wave with the same weapon effect positions,
  rotations, recoil, sounds, ammo updates, and item clearing semantics.
- [ ] Preserve concrete item subclass side effects from batch 28: Jet Pack should
  call `beginJet()`/`endJet()` on key transitions and refill fuel on
  replenishment, Speed Burst should double stats once, start/end sparkles, reset
  stats on removal, and expire via `setItem(0)`, Laser/Sword/IceWave should play
  authored weapon timelines, Mine should use `MineAppear`, Teleport should spawn
  two local `TeleportPop` effects, Lightning should mount local `Zap`, and Super
  Jump should play `SuperJumpSound` only when not crouching.
- [ ] Preserve `DrawObject.as` / `BlockObject.as` editor-object interactions:
  use authored `DeleteButton`, `ResizeButton`, and `BlockOptionsButton` handles,
  drag with stage move/up listeners and alpha/swap-to-front behavior, record
  Flash move/delete/resize actions, snap block drags to the 30px grid, keep start
  blocks non-overwritable and non-deleteable, scale handles against nested parent
  zoom, draw the white selection outline around the real display dimensions, and
  remove objects from the editor undo/current-object registries on cleanup.
- [ ] Preserve level-editor list-row hover parity: `GetLevelsPopupItem` should
  include Flash's `Updated:` line, `Data.formatNumber()` formatting, full
  `Modes.getFullName()` names such as `"Alien Eggs"`, escaped multiline note
  HTML, and `info.width -= 3; info.x = 550 - info.width`; reported-level rows
  should keep the same creator/version/note/reporter/reason formatting and
  cleanup.
- [ ] Complete `LevelEditorMenu.as` parity: bind `newButton` and `exitButton`,
  show Flash confirmation prompts for clearing/exiting, route exit through
  `ConnectingPopup`, disable save/load for guests and save in reports mode,
  choose `ChooseLevelsModePopup` only when level reports are allowed, prevent
  test-course launch while drawing, update sidebars/focused layers/undo-redo
  exactly like Flash, and keep zoom changes synced to the tools sidebar.
- [ ] Preserve `TextObject.as` editing behavior: use authored `EditTextButton`
  plus `ColorPicker`, keep the display field hidden while editing, only delete on
  Backspace/Delete when not editing or the edit field is empty, record
  `recordChangeText()` on deselect, keep `lastColor`, exact escape/parse
  replacement order, max 500 chars, min edit width 100, blank-text deletion, and
  scale/position the edit/color/resize controls with the same parent-zoom math as
  `DrawObject`.
- [ ] Preserve `Campaign.as` listing behavior: derive the initial page from
  `Main.server.server_id` and `Main.lastAuthTime.getDay()`, cache and reuse
  `Memory.memory["campaignInfo" + page]` with the 250ms delayed `showCourses`,
  and replace the normal navigation with the Flash vertical six-page
  `PageNavigation` at `(328, 26)`.
- [ ] Preserve `LevelListing.as` / `LevelItem.as` listing details: delay
  `showCourses()` while `SecureData.userRank` is still negative, initialize the
  global/current page number before any slot can emit `fill_slot`, include the
  Flash `Updated:` line in level info hovers, add the 500ms add/remove-favorite
  hover popups, keep pass-check controls disabled with `"checking..."` until the
  response/error path re-enables them, and preserve all access-cover/slot cleanup
  side effects.
- [ ] Preserve `Search.as` focus and request quirks: combo `CLOSE` events should
  return focus to the stage, pressing Enter should also focus the stage before
  running the search, blank searches should not show loading, and ID searches
  initialized on page > 1 should reset to page 1 without sending the skipped
  request.
- [ ] Preserve `Lobby.as` bottom-button/session behavior: temporary moderators
  on non-guild servers should get the Flash confirmation/message flows before
  logout or level-editor entry, logout should POST `/logout.php` when the user is
  not remembered before clearing user data and closing the socket, the
  level-editor route should log out temp moderators as Flash does, the
  Kongregate button should show/remove the `"Kong Hat"` hover popup, and lobby
  entry/removal should keep the Noodle Town volume and stage quality side effects
  aligned with Flash.
- [ ] Preserve `LobbyLeft.as` notification lifecycle: member lobbies should attach
  the PM unread notification container to the PM tab and remove/unregister any
  Haxe-side PM notification command or container on pane teardown so stale lobby
  tabs cannot receive notifications.
- [ ] Preserve `CheckServers.as` as a login-screen service, not only a pure parser:
  `activate()` should start the 60-second reload interval and immediately load
  `/files/server_status_2.txt`, `deactivate()`/`removeBox()` should clear the
  interval/target, target combo boxes should show `Loading...` and
  `No servers found. :(` prompts with enabled-state changes, reload should reuse
  cached servers when possible, and `selectServer()` should append/update server
  items without duplicating ids while preserving Flash's guild/public/beta
  selection rules.
- [ ] Preserve `CommAuth.as` compatibility: initialize the two `SecureStore`
  encrypted communication tokens and expose `getToken(num)` with Flash's
  server-10 special case, even if the Haxe socket protocol also keeps constants
  internally.
- [ ] Port `ArtifactHint.as` exactly: `/hint`, `/lotw`, and `/arti` should load
  `/files/level_of_the_week.json`, parse current/first-finder/bubbles-winner/
  scheduled fields, build Fred the G. Cactus messages with Flash `makeLevel` and
  `makeName` links, include scheduled `Data.getDateTimeStr(..., ["long",
  "short"])`, and clean up the loader with the chat room.
- [ ] Preserve `LoggingInPopup.as` post-login side effects: encrypted `/login.php`
  payload should include `award_kong`, reset `awardKongNextLogin` after send,
  combine HTTP and socket success before entering the lobby, apply `lastAuthTime`,
  unread notification `lastRead`/`lastRecv`, favorites, guild/emblem/email/token
  fields, delete reset remembered tokens on error, call per-user `Settings.init`
  and `Presets.load`, and clear user/socket state on close/error like Flash.
- [ ] Complete `AccountInfo.as` customization parity: render the guild with the
  authored linked `GuildName` clip/emblem, support `SET_MANUAL_PART` /
  `partToSet` updates from part-info popups, show the delayed Loadouts hover at
  the Flash offset, block number hotkeys while `CourseMenu` is open or selectable
  text has focus, preserve the confirm/apply flow for presets, and dispatch
  level-access retests after rank/current-hat changes.
- [ ] Port the `player_profile.PartInfo` catalog flow: info-button hover should
  appear after Flash's 500ms delay/offset and clicks should open
  `PartInfoPopup`, populate `Parts.getPartArray()` in the authored store popup
  with `PartInfoListing` rows, preserve owned/epic/EE state, EpicFlash effects,
  Djinn/Fred/artifact/cheese special rendering, dynamic obtain links, singleton
  popup fade-outs, and `PartPopup` Equip dispatch through `SET_MANUAL_PART`.
- [ ] Preserve `PresetListing.as` / `RandomizeStyleButton.as` UI details: loadout
  thumbnails should mask second colors through `PartSelector.isPartEpic()` before
  preview render, and the randomize button should keep the Flash
  `HoverDelayPopup` title/body and delayed hover behavior rather than only being
  a clickable graphic.
- [ ] Preserve Vault/store visual and confirmation parity from
  `shop.StorePopup` / `StoreListing`: use the authored `CustomScrollBar`, format
  coin totals with `Data.formatNumber`, start `EpicFlash` for flashing sale title
  and sale listing titles, render the three random colored characters for the
  `epic_everything` listing, keep price/coin/sale box sizing/removal identical,
  include the PR2 Terms of Use link in purchase confirmations, and mirror Flash's
  cleanup of loaders/listeners on close.
- [ ] Preserve `social.PlayersTabList` / loader lifecycle quirks: new user rows
  should set an `updateSort` flag and sort on Flash's 500ms interval, not
  immediately on every row, and `PlayersTabUserListDataLoader` / `Guilds` should
  guard or unregister async callbacks on removal so late HTTP responses cannot
  mutate torn-down list art.
- [ ] Port `ui.CustomCursor` runtime behavior for editor tools and eyedropper:
  maintain the singleton `stageRef` cursor instance, hide/show the OS cursor,
  track mouse/touch move/down/up/focus events, pause vs dispose non-disposable
  cursors, apply centered cursor graphics, and preserve the Cmd/Ctrl temporary
  `ObjectDeleter` swap/restore through `Memory.memory` while excluding text,
  brush, and eyedropper cursors.
- [ ] Preserve remaining `ui` helper parity from batch 37: port `EmblemLoader`
  image browse/load/fit-to-canvas/JPEG90 upload events, replace text-only guild
  names with the authored `GuildNameGraphic` helper (including `makeWidth`,
  bold/wide modes, hand cursor, GuildPopup click, and emblem surface), provide a
  reusable `SelectableButton` hover/selected wrapper for popup rows, and restore
  `PageNavigation`'s stage-focus reset after link clicks plus `GameSound`'s
  focus reset on combo close.
- [ ] Restore `StatSlider.as` press-and-save behavior: increment/decrement
  buttons should use Flash's mouse-down hold acceleration (8/sec for 0-2s,
  16/sec for 2-4s, 32/sec after 4s), stop on bounds/no remaining points, and
  persist level-editor test stats only through the original mouse-up /
  `SliderEvent.THUMB_RELEASE` / `updateSavedLEStats` paths with the `inLE()`
  guard.
