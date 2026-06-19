# Platform Racing 2 Haxe/OpenFL Port TODO

Working roadmap for porting the original Flash Platform Racing 2 client to a
Haxe/OpenFL browser build. The end goal is a faithful reproduction of the
original game — matching gameplay/physics timing, level and character behavior,
and visuals — not a loose remake. Keep this file focused on what moves the port
forward; command references belong in `README.md`, and asset-pipeline details in
`docs/vector-art-export-plan.md`.

## fl UI Components

Port of the Adobe `fl.controls.*` components placed in the original assets. These
render through `PR2MovieClip.createComponent`; until ported, instances fall back
to inert placeholders (a grey box or a non-interactive drawing). Follow the
`FlButton` pattern: real skin symbols, 9-slice to size, swap per state, plus the
properties/events the source actually drives.

- [x] **Button** (`fl.controls.Button`, 129 instances) — `pr2.runtime.FlButton`,
      covered by `FlButtonTest`.
- [x] **CheckBox** (`fl.controls.CheckBox`, 58 instances) — `pr2.runtime.FlCheckBox`:
      real `CheckBox_*Icon` skins swapped per state, `selected`/`label`/`enabled`
      get/set, click toggle, silent programmatic set, `CHANGE` on user click.
- [x] **ComboBox** (`fl.controls.ComboBox`, 17 instances) — `pr2.runtime.FlComboBox`:
      `ComboBox_*Skin` background, `FlDataProvider` (`addItem`/`removeAll`/`length`),
      `prompt`, `selectedIndex`/`selectedItem`, open/close list, `CHANGE` on pick.
- [x] **TextInput** (`fl.controls.TextInput`, 34 instances) — `pr2.runtime.FlTextInput`:
      inner editable `TextField` over the nine-sliced `TextInput_*Skin`, with
      `text`/`editable`/`displayAsPassword`/`restrict`/`maxChars` and re-broadcast `CHANGE`.
- [x] **TextArea** (`fl.controls.TextArea`, 8 instances) — `pr2.runtime.FlTextArea`:
      multiline `TextField` over `TextArea_upSkin` plus an attached `FlUIScrollBar`;
      `text`/`htmlText`/`append`/`editable`.
- [x] **Slider** (`fl.controls.Slider`, 6 instances) — `pr2.runtime.FlSlider`:
      `SliderTrack`/`SliderThumb` skins, drag + track-click, `value`/`minimum`/
      `maximum`/`snapInterval`, `FlSliderEvent` (CHANGE == `Event.CHANGE`, THUMB_*).
- [x] **List** (`fl.controls.List`, 1 instance) — `pr2.runtime.FlList`: `List_skin`
      border, `FlDataProvider` rows with selection highlight + overflow scrollbar,
      `selectedIndex`/`selectedItem`, `CHANGE`. (Lobby listing stays custom-ported.)
- [x] **UIScrollBar** (`fl.controls.UIScrollBar`, 1 instance) — `pr2.runtime.FlUIScrollBar`:
      `ScrollTrack`/`ScrollThumb`/`ScrollArrow*` skins, draggable thumb + arrow steps,
      `scrollTarget`/`setScrollProperties`/`scrollPosition`, `SCROLL`. Drives FlTextArea.

All seven render through `PR2MovieClip.createComponent`, share the `FlSkin`
nine-slice helper, and are covered by `FlComponentsTest`.

(ColorPicker / CellRenderer / ScrollBar appear only as skins internal to the
above — no standalone instances to migrate.)

## Direction

- End goal: a faithful port of the original Flash game. Same physics/timing,
  same level and character behavior, visuals that match the original. Pixel-level
  parity is pursued through the Flash-vs-OpenFL comparison harnesses (screenshots
  + debug state), not judged by eye.
- Primary target: browser/HTML5 with Haxe + OpenFL. Secondary: Android and iOS
  after browser parity.
- Strategy: build the smallest playable, deterministic harness first, then grow
  fidelity outward (more blocks, items, real levels, real server). Approximate
  visuals are acceptable as intermediate milestones, but every approximation is
  a tracked gap to close, not the destination.
- Normal development and CI must not require Adobe Animate; it is only a
  migration tool for regenerating source assets.
- Testing order: deterministic fixture runs, then Flash/OpenFL screenshot and
  debug-state comparisons, then real-server checks.

## Current Focus

The next push is the full lobby port. End state: a functional post-login lobby
that looks and feels like the Flash client, uses the original lobby artwork, and
has complete left/right tab behavior.

1. Export and wire the lobby background/bottom/tab/page assets.
2. Replace `LobbyStubPage` with a real two-pane `LobbyPage`.
3. Port tab selection/memory/overlap logic, then complete every lobby tab.
4. Keep server/API/WebSocket differences behind small wrappers so lobby pages
   can preserve the original AS3 behavior.

## Lobby Port — Current Push

Reference source: `flash/lobby/Lobby.as`, `LobbyLeft.as`, `LobbyRight.as`,
`LobbySide.as`, `flash/ui/LobbyTab.as`, `TabsHolder.as`, `flash/chat`,
`flash/social`, `flash/level_browser`, and `flash/player_profile/AccountInfo.as`.

- [ ] Export and rasterize lobby artwork.
  - Include `LobbyGraphic`, `LobbyBottomButtonsGraphic`, `LobbyTabGraphic`,
    `ChatGraphic`, `MessagesGraphic`, `MessagesItemGraphic`,
    `PlayersTabListGraphic`, `PlayersTabListItemGraphic`, `AccountInfoGraphic`,
    `SearchGraphic`, level listing/item graphics, `PageNavigation` pieces, and
    popups needed by the lobby (`StorePopupGraphic`, options/credits/message
    popups as they become reachable).
  - Add a dedicated lobby/menu export category to the JSFL/raster manifest, keep
    generated PNG/atlas files committed, and document regeneration in README or
    the vector export plan.
  - Verify `LobbyGraphic` and `LobbyBottomButtonsGraphic` visually against Flash
    before building UI on approximate shapes.
- [x] Replace `LobbyStubPage` with the real lobby shell.
  - Port `Lobby`, `LobbyLeft`, `LobbyRight`, and `LobbySide` layout: background,
    left pane at `(3, 3)` sized `194 x 394`, right pane at `(200, 3)` sized
    `347 x 356`, bottom button strip, and stage/music/quality side effects that
    matter in OpenFL.
  - Wire post-login handoff to the real lobby while preserving logout back to
    `LoginPage`.
  - Implement bottom actions to parity: logout, level editor entry placeholder
    or real handoff, Kongregate/more-games link behavior, options, vault/store,
    credits, and hover popup behavior.
- [x] Port `LobbyTab` and `TabsHolder`.
  - Match Flash tab sizing from text width, `up`/`over`/`selected` states,
    hover-to-front behavior, compressed tab positioning when width exceeds the
    pane, and selected tab memory by holder id (`lobbyLeft`, `lobbyRight`,
    `playerLists`).
  - Add deterministic tests for initial selected tabs, click/hover ordering,
    remembered tab restoration, and guest/member tab differences.
- [x] Complete left pane tab: Chat.
  - Port room selection, send/join buttons, enter-key handling, lock-to-bottom
    scrolling, info hover popup, `set_chat_room` socket commands, link handling,
    and pause/update toggle behavior.
  - Render incoming chat records through the original HTML/name formatting and
    preserve scroll behavior while new messages arrive.
- [x] Complete left pane tab: PMs.
  - Port message list loading (`messages_get.php`), paging, scrollbar,
    send-message popup, delete/report/delete-all flows, unread notification
    badge behavior, and error/loading states.
  - Preserve guest/member availability: PMs tab only appears for logged-in
    accounts (`Main.group > 0`).
- [x] Complete left pane tab: Players.
  - Port nested `PlayersTab` tabs: Online, Friends, Following, Ignored, and the
    guest Guilds view.
  - Implement list loading, item rendering, player/guild popup hooks, online
    status/rank/hat counts, following/friend/ignore actions, and nested tab
    memory under `playerLists`.
- [x] Complete left pane tab: Account.
  - Port customize-info socket flow, character preview using `CharacterDisplay`,
    part/color selectors, stats selector, rank token up/down, guild display,
    loadouts popup entry, outfit hotkeys, and `set_customize_info` writes.
  - Keep account changes synchronized with level access checks and lobby/player
    display refreshes.
- [x] Complete right pane tab: Campaign.
  - Integrate the existing campaign list and level-data clients into the lobby
    listing UI, including the Flash campaign page formula
    `((server_id + day) % 6) + 1`, six-page vertical navigation, list caching,
    level access checks, and right-room socket commands.
  - Selecting a level should open the original-style level info/course menu and
    start/load the selected level path that exists today.
- [x] Complete right pane tabs: All Time Best, Week's Best, Newest, Favorites.
  - Port `LevelListing` page navigation, list hash validation, loading/error
    states, three-column level item layout, page highlight commands, memory of
    page numbers, favorite-only availability, and `set_right_room` behavior.
- [x] Complete right pane tab: Search.
  - Port search controls, mode/order/direction dropdowns, enter-key search,
    blank/id/page guards, POST request to `search_levels.php`, persisted search
    state, and `LobbyRight.lookupUser` / `lookupLevel` hooks from player/level
    popups.
- [x] Port shared lobby UI/services needed by the tabs.
  - Add Haxe wrappers for `Main.group`, logged-in user/server metadata,
    `Memory`, `SecureData`, `CommandHandler`, socket command dispatch, URLLoader
    POST/GET JSON helpers, `PageNavigation`, `CustomScrollBar`, loading
    graphics, hover/message/confirm/uploading popups, and HTML text/link
    handling.
- [ ] Test lobby parity.
  - Add OpenFL sequences for post-login lobby boot, left/right tab switching,
    tab memory after leaving/returning, campaign/search list load via dev proxy,
    chat room command emission, PM/account loading states, and bottom buttons.
  - Add screenshot comparisons for the empty lobby shell, tab selected/hover
    states, campaign listing, search controls, PM list, players list, and account
    customization view against Flash baselines.

Acceptance: after login, the user lands in a lobby that visually matches the
original, every visible tab can be selected and performs its Flash-equivalent
workflow, network-backed tabs use the appropriate real/proxy endpoints, and
automated sequences cover the main lobby workflows.

## Character Rendering — Remaining

Keep character rendering in service of the playable harness and faithful
appearance, not an open-ended art project.

- [x] Finish one full customizable character.
  - Separate static/primary/secondary layers; independent primary/secondary
    tinting; composite layer kept for preview/debug/fallback.
  - Verify against Flash for representative outfits.
- [ ] Compare representative character screenshots against Flash.
  - Default outfit; primary + secondary color change; hat/head/body/feet mix;
    known tricky parts (cheese hat, Fred/body-specific placement).

Acceptance: customization works in the harness; common outfits match Flash
closely; animation-state switching stays compatible with the MovieClip runtime.

## Vector Renderer — Remaining

`pr2.runtime.VectorShapeRenderer` translates XFL `DOMShape` edges/styles into
OpenFL `Graphics` calls (OpenFL rasterizes). Reference: edge coords are raw XFL
twips / 20 = px (DPI-independent); commands `!` moveTo, `|`/`/` lineTo, `[`/`]`
quadTo, coords decimal or hex fixed-point (`#13.FB`). Ruffle/`xfl2svg` are
algorithm references only. The raster asset path remains the fallback for any
symbol the renderer cannot yet reproduce faithfully.

Comparison harness: `tools/compare_symbol_render.py` renders each case symbol
through the `?screen=symbol` vector path and scores it against the Adobe `@4x`
PNG. Cases and thresholds live in `tools/symbol_render_cases.json`.

- [ ] Close stamp fill/contour differences so `tree1` and `rock1` thresholds can
  tighten toward the leaf-symbol level.

Acceptance: stamp cases score close enough to tighten their thresholds and
reduce reliance on raster fallbacks.

## Asset Migration — Remaining

These widen visual coverage toward parity; most can follow the playable harness.
Regeneration commands live in `README.md` / `docs/vector-art-export-plan.md`.

- [ ] Export block overlays / block-piece graphics not covered by tile bitmaps:
  `ArrowBlockGraphic`, `EggBlockGraphic`, `Arrow2Graphic`, `BrickPieceGraphic`,
  `CrumblePieceGraphic`, `StartBlockText`.
- [ ] Export remaining gameplay/item effect symbols as timeline-driven assets
  (not per-frame SVG): `CountdownGraphic`, `EggGraphic`, `HeartGraphic`,
  `IceWaveGraphic`, `DjinnIceGraphic`, and the `PR2_Graphics_..._fla`
  jetpack/sword/gunfire/iceWave/superJump/jump/bumped/frozenSolid anims.
- [ ] Export in-game HUD/page graphics when the harness needs them:
  `FinishedPageGraphic`, `ExpGainGraphic`, `DrawingInfoGraphic`,
  `StatsDisplayGraphic`, `RaceChatGraphic`, `MiniMapGraphic`, `MiniMapDot`,
  `PrizePopupGraphic`, `QuitButtonGraphic`, `MusicSelectionGraphic`.
- [ ] Export editor/menu graphics per screen after the lobby asset pass:
  `LevelEditorMenuGraphic`, `DrawingPopupGraphic`, `HatPickerGraphic`.
- [ ] Finish the intro animations: visually verify the baked Kongregate intro
  art (`bitmap379.jpg` plus nested vector pieces) against Flash.
- [ ] Resolve the five unexported bitmap media entries.
  - `Images/bitmap379.jpg` is a normal XFL image (likely the Kongregate logo).
  - `bitmap1249.png`, `bitmap371.png`, `bitmap386.png`, `bitmap97.jpg` are
    referenced as embedded payloads but absent under `LIBRARY/Images/`.
- [ ] Leave broad Flash component skins / low-priority UI linkage symbols (258
  audited: 3 backgrounds, 8 blocks, 41 components, 10 items_effects, 144 ui, 52
  uncategorized) until a ported screen needs them.

Acceptance: needed assets ship from committed files; the browser build loads
them without Animate; regeneration is documented and reproducible.


## Level Loading And Rendering

- [x] Add dynamic campaign level choice instead of always loading the first
  configured level.
- [x] Expand rendering coverage: backgrounds, stamps/draw objects, text objects,
  minimap if needed.

Acceptance: selected real levels render all required visual layers and remain
usable by the local movement harness.

### Server Campaign Level Test Harness

Fetch a real campaign level from pr2hub.com, render it, and drop the character
in. Reachable via `?screen=campaign`.

- [x] Add user/developer selection for campaign page and level id.
- [x] Render non-block level content: backgrounds, stamps/draw objects, text
  objects, and minimap if needed.

## Gameplay Expansion

Add mechanics in small, testable batches after the flat fixture is playable.
Each should match original PR2 behavior, verified via debug state / comparison.

- [x] Full course rotation behavior.
- [x] Item: super jump.
- [x] Item: teleport.
- [x] Item: speed burst.
- [x] Item: jet pack.
- [x] Items: sword, laser gun, mine, ice wave, lightning.
- [ ] Movement edge cases: frozen state, moving/rotating block collisions,
  corner cases.
  - [x] Frozen-solid state: immobilization, animation, and timed thaw.
  - [x] Mine-hit hurt recovery with bumped animation state.

Acceptance: each mechanic has a fixture level; debug state exposes enough to
compare behavior; common movement feels like Flash.

## Networking And Real Server Flow

Don't block local gameplay on this, but keep it moving: browser deployment
depends on the real gameserver flow.

- [ ] Finish the real post-login flow through lobby, level browser, level
  selection, and loading one real level.

Acceptance: the browser build reaches a real server path over WebSocket; at
least one real response is parsed; login feasibility is known before full UI.

## Testing

- [x] Generalize `tools/pr2driver.py` into a common sequence format shared by
  Flash and OpenFL.
- [x] Add lobby-focused OpenFL/Flash comparison suites after the first lobby
  shell lands.
- [x] Add `intro-flow` OpenFL sequence for Jiggmin render state,
  `data-pr2-intro-state`, and click-to-skip coverage.
- [x] Add `level-load-flat` OpenFL sequence for fixture load/debug coverage.
- [x] Add `finish-race` OpenFL sequence for reaching the fixture finish block.
- [x] Add `real-server-connect` smoke coverage for server-list parsing,
  WebSocket URL selection, and login-id socket framing.
- [x] Kongregate intro art remains pending.

Acceptance: one command runs a useful scripted OpenFL sequence; failures produce
screenshots + debug output that are easy to inspect.

## Later Work

- [ ] Sound and music: extract/import assets, port `SoundEffects`, handle
  browser autoplay restrictions.
- [ ] Full UI polish: login shell, lobby, level browser, customization UI,
  editor shell if needed.
- [ ] Performance/compatibility: profile browser rendering, optimize after
  behavior is right, test Chrome/Firefox/Safari/mobile, watch memory across
  level loads.
- [ ] Mobile targets: responsive wrapper, touch controls, Android, iOS.
- [ ] Release readiness: production build, asset cache/versioning, loading/error
  screens, gameserver WebSocket deploy docs, public test build.
