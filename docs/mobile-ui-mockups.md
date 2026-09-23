# Mobile UI mockups

[Open the editable Figma file](https://www.figma.com/design/vQnyWfJ7JbHs33WWULEdul). Companion to [the functionality inventory](mobile-ui-plan.md).

## Current direction: landscape throughout

Menus and races share a landscape orientation so players do not need to rotate between them. The September 20, 2026 landscape direction was approved after the Play and Character exploration. The next pass adds the game menu, browse/search, race entry, stats, loadouts, and a replacement confirmation. Earlier portrait concepts remain in Figma for comparison; they no longer define the navigation direction.

The new concepts use original PR2 sky and racer vectors, green landscape accents, dark outlines, raised buttons, and prominent game actions. Lilita One headings and action labels add a playful tone; Nunito supports readable details. These are proposed mobile fonts, not a faithful recreation of the original desktop typography.

| Screen | Figma node | Proposal | Repo snapshot |
| --- | --- | --- | --- |
| Race HUD, joystick right | `37:177` | Default touch layout: large Jump and smaller Item on the left, joystick on the right, a swap icon at bottom center; race HUD at top. | [SVG](design/mobile/race-hud-right.svg) |
| Race HUD, joystick left | `39:183` | Mirrored touch layout, with Jump closest to the right edge; center switch and top HUD stay in place. | [SVG](design/mobile/race-hud-left.svg) |
| Title, landscape | `30:171` | Large outlined title and original racer beside Log In, Play as Guest and Create Account; Instructions, Credits and audio toggle remain accessible. | [SVG](design/mobile/title-landscape.svg) |
| Play, landscape | `15:64` | Campaign list alongside selected-level details, with a prominent Join Race action; My racer and Menu in the header. | [SVG](design/mobile/play-landscape.svg) |
| Character, landscape | `15:65` | Racer preview beside appearance controls; category and part selection, primary/secondary color actions, Save Racer, Stats and Loadouts. | [SVG](design/mobile/character-landscape.svg) |
| Game menu | `20:94` | Three groups for play/creation, social destinations, and game/account controls; return to the previous screen. | [SVG](design/mobile/menu-landscape.svg) |
| Browse and search | `20:144` | Collection selector beside a sample creator search, sort controls, result and paging. | [SVG](design/mobile/browse-landscape.svg) |
| Race entry | `20:194` | Four participant slots, waiting/countdown area, original Play confirmation action, and leave control. | [SVG](design/mobile/race-entry-landscape.svg) |
| Stats | `20:244` | Remaining point budget; separate minus/plus controls for speed, acceleration and jumping; activate/deactivate rank tokens. | [SVG](design/mobile/stats-landscape.svg) |
| Loadouts | `20:294` | Touch selectors for all ten slots, selected appearance/stat summary, apply and replace actions. | [SVG](design/mobile/loadouts-landscape.svg) |
| Replace loadout | `25:157` | Confirmation showing which slot will be replaced, with a cancel action. | [SVG](design/mobile/replace-loadout-landscape.svg) |

All landscape frames are 844 × 390 logical pixels with 44-pixel side margins for landscape safe areas. Primary controls are at least 44 pixels tall, including the revised campaign paging controls. There is no persistent bottom navigation bar. Content panels use auto layout, shared action/card instances, and existing color variables. Phone aspect ratios and actual browser safe-area insets still need validation.

Start at Play (`15:64`). The prototype connects:

- Play → My racer → Stats / Loadouts, with return controls.
- Play → Browse → Campaign or the sample search result → Play.
- Play → Join Race → waiting screen → Leave race → Play.
- Menu access from browsing and customization, plus Race / My racer destinations; Back to game uses prototype history.
- Loadouts → Replace → confirmation / cancellation → Loadouts.
- Save Stats and Use Loadout return to Character as navigation demonstrations.

This is a visual prototype using sample data, not implemented game flows. Navigation reactions were read back; screens were reviewed at full size, and text/font checks found no overflow in auto-layout text containers. The prototype has not been exercised in a device/browser session. Confirm replacement, Save Stats and Use Loadout do not persist or mutate any game data.

Remaining static controls include search input/filter choices and paging, non-Campaign collections, race Play/countdown, stat/token changes, slot selection, appearance editing, Rules/Favorite/More, and menu destinations other than Race/My racer. Search mode choices still need expanded states for creator, level title and level ID; sort choices must retain Date, Alphabetical, Rating and Popularity, with ascending/descending order. The waiting timer is a sample waiting state, not an active countdown.

Original behavior was checked against `flash/level_browser/Search.as`, its XFL SearchOptions asset, `CourseMenu.as`, `flash/ui/StatsSelect.as`, and `flash/player_profile/{AccountInfo,LoadoutsPopup,Presets}.as`. Ten loadout slots and appearance-plus-stat contents come from the original source. The explicit Save Stats action and replacement confirmation are mobile design proposals; immediate stat/token application, persistence, cancellation and unsaved-change behavior need to be resolved before implementation.

The SVG files are review snapshots with live text; viewers need Lilita One and Nunito for matching typography. Editable components and prototype connections remain in Figma; SVG exports are not a complete Figma-file backup.

## Title screen review — September 20, 2026

[Open the landscape title screen in Figma](https://www.figma.com/design/vQnyWfJ7JbHs33WWULEdul?node-id=30-171). Updated at the user's request to retain the original parallax background and Gwibble title. The title reads `Platform Racing` / `-- 2 --`, with black Gwibble lettering and a white halo. Figma's font list did not include Gwibble, so the visible title uses vector glyph outlines generated directly from `assets/fonts/gwibble.ttf`; implementation should use that font as live text. Action labels remain Lilita One and the creator credit remains Nunito. All six controls have at least 44-pixel height; the primary entry actions are 56–64 pixels tall. The complete frame and title were visually reviewed at full size.

The background keeps separate original sky, far, middle and foreground layers, using `art/svg/login/bg_{sky,far,mid,front}.svg`. The foreground is the original embedded bitmap, losslessly cropped to the visible tile region for import. The static composition uses initial layer positions from `haxe/src/pr2/page/LoginBackground.hx`, scaled from the original 550 × 400 stage to this 844 × 390 mockup. It replaces the earlier simplified hills. Implementation must preserve the existing scrolling layers, relative speeds and seamless looping, while validating landscape scaling. No Figma animation was added. Figma Smart Animate can demonstrate layer movement, but this frame is a static design reference. The prior title/background nodes are hidden for edit history and excluded from the visible export.

The title screen is a static mockup. Its controls have no prototype reactions, authentication, registration, server connection, audio changes, Instructions destination or Credits popup yet. Per `flash/menu/LoginPage.as`, Log In opens saved-account/server selection when accounts are remembered, otherwise login; Play as Guest opens server selection; Create Account opens registration; Instructions opens the instructions page; Credits opens its popup. Preserve these branches during implementation rather than connecting the title directly to a signed-in lobby. Returning-player, authentication and server-selection states remain to be implemented. Host-specific sponsor branding is not shown in this standalone mobile proposal.

## In-game touch layout — September 20, 2026

[Open the default gameplay mockup](https://www.figma.com/design/vQnyWfJ7JbHs33WWULEdul?node-id=37-177). The requested default has a 144-pixel virtual joystick at bottom right, a 116-pixel Jump button and 76-pixel Item button at bottom left, and a 128 × 44 opposing-arrow swap icon button at bottom center. The alternate frame mirrors the control groups and keeps Jump nearest the outside edge. The swap icon navigates between both mockup frames in the Figma prototype. It does not change a saved setting or simulate input. Both frames were visually reviewed; swap reactions and text bounds were checked.

The top HUD retains the held item/ammo, time remaining, minimap, Chat and Menu. The bottom chat field, music dropdown, Quit and sound button are removed from the persistent HUD. Their functions remain planned behind the top Chat/Menu actions: chat, music selection, audio, current stats, and confirmed quitting. Those panels are not designed or connected in this pass. Menu must not imply that an online race pauses. Mode-specific lives/event status and countdown/finish states still need layouts; they should use top or contextual space, never displace the touch controls.

This is an illustrative course assembled from original `bg1.svg`, `basic1.png`, and classic racer artwork, not a captured or playable level. The minimap and Sword × 1 / 3:51 values are sample data. Jump, item use and joystick gestures are static. Implementation must preserve simultaneous movement/jump/item input, down/crouch/charge behavior, relevant vertical movement, touch cancellation, safe areas, and consistent behavior when swapping sides. Thumb reach, opacity, accidental swap taps, and smaller landscape devices still require device testing. The original HUD reference is `test/baselines/flash/07_gameplay_start.jpg`, with behavior checked in `flash/gameplay/{ItemDisplay,StatsDisplay,Hearts}.as` and the existing functionality inventory.

## Earlier portrait exploration

Seven 390 × 844 concepts remain on the same canvas: Welcome (`3:2`), Play (`3:3`), Level details (`3:4`), Race entry (`3:5`), Character (`3:6`), Stats (`13:57`), and Loadouts (`13:58`). Selected browse/customization navigation is connected. These are historical explorations, not additional approved portrait requirements.

## Next design work

- Validate the proposed racing controls on devices; design race menu/chat, conditional HUD states and results, followed by social, account, editor and other inventory destinations.
- Complete search/filter, collection, loadout-slot and countdown interaction states; design the destinations now exposed by the game menu.
- Cover guests, empty/loading/error states, locked parts, unsaved changes, confirmation flows and detailed level rules.
- Validate smaller and wider landscape phones, readable text, touch targets and display cutouts. Orientation locking is a later implementation task and has not been added to the game.
