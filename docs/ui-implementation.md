# Separate UI configurations

`pr2.app.ScreenFactory` is the selection boundary for title/lobby/My Racer/player-directory/Messages pages, profiles, compose/authentication dialogs, gameplay HUD, race results, options, credits, guild authoring, confirmations, and level details.
Call `ScreenFactory.login()` and `ScreenFactory.lobby(userName, server)` from
navigation code. Do not construct either presentation directly outside the
factory. Startup, authentication, logout, disconnect recovery, editor reconnect,
and returning from a race all use it.

| Configuration | HTML5 build command | Selection |
| --- | --- | --- |
| Classic release (default) | `haxelib run openfl build html5` | Classic title, lobby, and authentication dialogs; their mobile counterparts are omitted. |
| Mobile release | `haxelib run openfl build html5 -Dpr2_mobile_ui` | Mobile title, lobby, and authentication dialogs; their classic counterparts are omitted. |
| Development preview | `haxelib run openfl build html5 -Dpr2_ui_preview -debug` | Both; explicit Classic/Mobile dropdown in the browser. |

`-Dpr2_classic_ui` is an optional explicit spelling of the default. Conflicting
configuration defines are compile errors. The selection is independent of the
target platform. Native mobile builds also request landscape orientation.

In preview, `?screen=login&ui=mobile` and `?screen=login&ui=classic` open the title
variants. The dropdown changes `ui` and reloads, keeping other query parameters.
Reloading intentionally restarts the connection; it does not move a live session
between presentations. Release builds ignore `ui` (and the old `mobile` query
parameter). The comparison dropdown is an HTML5 development tool.

The commands share Lime's `export` directory. Rebuild when changing configuration;
do not serve an earlier build and infer the configuration from its URL. Mobile
fonts are conditionally packaged, while shared artwork/catalog packs remain
shared, including assets used by the dialogs still awaiting mobile treatment.
The HTML5 postbuild gate checks that the opposite title/lobby/My Racer/auth-dialog/HUD/results classes and preview
selector are absent from release output. It also removes stale copied mobile
assets from a classic build.

## Incremental extraction

`LoginPage` and `MobileLoginPage` compose the same `LoginFlow`. It owns server
refresh/cooldown, saved-account selection, registration and password recovery,
authentication, cancellation, and handing the live socket to the lobby. The
classic title retains its artwork and controls. The mobile title uses the
approved landscape composition, original scrolling background, live Gwibble
title, native racer renderer, and shared master mute state.

`LoginFlow` uses the `AuthDialog` contract through `ScreenFactory.authDialog()`.
`ClassicAuthDialog` adapts the original forms and fade lifecycle; `MobileAuthDialog`
provides landscape forms, touch-sized paged account/server choices, progress,
confirmation, and error panels. Both execute the same requests, validation,
saved-account management, cancellation, and session handoff. Narrow/keyboard-reduced
viewports support scrolling and reveal the focused field. Extract other page behavior
as each flow is implemented; do not preemptively rewrite the remaining pages.

Each root page declares whether it needs the full viewport. `PageHolder` applies
that coordinate system before initialization, so returning to a fixed-size
shared game/editor/intro screen does not inherit the mobile lobby's sizing.

The landscape lobby uses the approved Play, Browse, Game Menu, and Race Entry
compositions. Course lists scroll by drag or wheel; Campaign has six pages and
the other collections have nine. Search retains creator/title/ID, all four sort
orders, and both directions. Course details expose access restrictions, password
entry, favorites, and the original detailed-level popup. Empty, loading, invalid
hash, request failure, full-race, and pending-join states have explicit UI.

`LobbyActions` owns logout/editor transitions and temporary-moderator warnings;
the original strip and mobile menu delegate to it. `LevelBrowserData` holds list
transports and remembered campaign seeding, `LevelActions` holds access/password
and favorite-result rules, and `LevelRoom` holds live slot state and commands.
`CourseMenu` and mobile race entry use the same `RaceEntryFlow` countdown and
confirmation protocol. Play sends `confirm_slot`; only `startGame` launches the
selected level. Leaving removes the selection, cancels timers, and releases the
slot. A server roster-clear during race startup keeps the selected course until
`startGame`, matching Flash; it is different from the player's explicit Leave
action. Late acknowledgements after cancel cannot reopen race entry.

The mobile shell requests customization data even while Play is visible, so
rank/hat restrictions do not depend on first visiting My Racer. Its header and
menu show unread-message state. The background reuses the original sky and the
ground exported from the approved Figma frame (`assets/mobile/lobby-ground.svg`).

For a working local live-data preview, use `python3 tools/dev_proxy.py --port 8766`
and open `http://127.0.0.1:8766/?screen=login&ui=mobile&apiHost=/api`. The API proxy
is needed because the live service does not supply cross-origin browser headers.
`?screen=lobby` is a development shortcut; use the title/guest flow to establish
a real gameserver session before testing joining and racing.

## In-game presentation

`ScreenFactory.gameHud` selects `ClassicGameHud` or `MobileGameHud`; `GamePage`
retains level loading, commands, finishing, awards, and lobby transitions. `Course`
retains simulation, keyboard controls, item use, timers, chat routing, music, and
spectating. Mobile composes the existing animated item/ammo and live minimap with
the shared mobile buttons, inputs, panels, typography, and scrolling container.

The default landscape layout has a right joystick, left Jump and smaller held-item
button, and a centered swap icon. Swapping releases captured inputs and persists
for the session. The item button hides when there is no item. The top contains the
live clock/map, conditional lives/progress, Chat, and Menu. Menu provides audio,
touch-sized music choices, stats, confirmed quitting, and spectator selection/free
camera. Opening a panel releases and blocks gameplay input but never pauses the
online simulation. Chat uses the existing filtering, slash commands, player links,
and transport; neither UI sends a second copy of a message.

`LocalPlayerInput.jumpHold` separates joystick-up from Jump: it sustains an already
started land jump, upward swimming/flight, and propeller descent. It cannot initiate
a land/frozen jump or the water-exit jump impulse. Snake steering still uses the
joystick's vertical axis. Touch and keyboard input combine at the simulation step;
releasing one source does not cancel another. Each hold control tracks its own
finger ID and releases on touch end/cancel, focus loss, resize, panel opening,
swapping, finish, or teardown. Desktop mouse dragging is also supported.

Landscape rendering uses a wider viewport with unchanged camera/physics coordinates
and proportional world scaling. Block and art culling follow those bounds. Original
themed background art fills the expanded viewport. Portrait shows a rotation hint.

## Race results

`ScreenFactory.results` selects the original `FinishedPage` or the landscape
`MobileResultsPage` through `RaceResults`. `GamePage` owns completion, buffered and
late awards/experience, timeout/quit outcomes, dismissal/reopening, and return to
the connected lobby. `ResultsState` shares the five server-authored award lines,
experience delta, and statistics hook. `ExperienceProgress` preserves Flash's
45-tick interpolation and rank-cap clamping in both views. `LevelRating` shares
rating validation, request fields/endpoint, pending state, and teardown; classic
keeps its confirmation/upload popups while mobile uses the shared mobile dialog.
Mobile rating errors remain visible with a confirmed retry. Closing cancels pending
work and ignores late replies.

Race prize and Lux notifications also route through `ScreenFactory`. `PrizeContent`
shares the original title/body/flavor copy, type-to-preview mapping, experience
fallback, and canceled-prize text; mobile uses touch-sized overlays over the running
course and reuses the shared part preview for item awards.

Mobile results use the existing panel/button/typography and scrolling components,
with original star artwork, animated XP, touch-sized rating choices, Keep watching,
and Return to lobby. Results block gameplay input while visible. Dismissing returns
to spectating; the HUD Results action reopens the stored results without another
quit command. Portrait shows a rotation hint without losing received results.
No standings or ranks are inferred: the original result protocol sends award text
and experience, not a separate standings table. Prizes and Lux remain separate,
original popups.

Classic result assets still warm during level loading; mobile skips those assets.
The postbuild boundary checks exclude the opposite result presentation from each
release. `?screen=popup&popup=finished&ui=mobile` provides a populated visual fixture
in preview; use the real title/race flow for integration checks.

## My Racer

`ScreenFactory.racer()` selects `AccountTab` or `MobileRacerPage`. The mobile lobby
gives My Racer the full content width with a persistent animated racer preview and
scrollable Style, Stats, and Loadouts sections. Owned-part steppers, a catalog with
ownership/epic status and acquisition text, primary/epic colors, randomization,
bounded stat sliders, rank-token controls, and all ten loadout slots are connected
to the real account flow. Details keeps the existing linked part-info popup.
Guild names still open their existing popup. Changes are sent automatically;
slider drags commit on release rather than sending every pointer event.

`CustomizationSession` owns save serialization/deduplication and rank-token
commands for both presentations. `CustomizationRules` shares Flash's stat clamps,
budget, epic eligibility, and numeric loadout shortcuts. `Presets.applyValues`
shares application order and the stat reset, while the existing account-specific
`Settings` store persists loadouts locally. `ManualPart` decouples catalog equip
events from the classic page. Mobile composes these through `RacerModel`; classic
retains its authored controls. The release gate checks both account page classes
and the classic account artwork. Mobile reuses `LobbyView`, `MobileScrollPane`,
authentication confirmation dialogs, and the original character renderer.
`MobileValueSlider` adapts the shared slider interaction to a 44px target.

`haxe test/mobile-racer.hxml` covers command payloads, duplicate suppression,
owned/epic restrictions, rank/Happy Hour budgets, token bounds, loadout persistence
and confirmation/cancellation, color cancellation, compact layout, resize retention,
slider release saves, and late callbacks after removal. The September 22 pass also
passed `./test.sh --lobby --ui` (57 suites), all three factory configurations,
and classic/mobile/preview HTML5 build-boundary checks.

Live guest checks at 844×390 and 667×375 verified color changes and stat
redistribution survive leaving/reopening My Racer (a fresh server fetch), and
local loadout saving/equipping restores the saved stats. Member-only inventory
and token cases use deterministic server payloads. Physical-device touch, keyboard,
and safe-area validation remains outstanding.

## Players and guild directory

`ScreenFactory.players(guilds)` selects the classic player/guild lists or
`MobilePlayersPage`. Members retain Online, Friends, Following, and Ignored;
guests retain Online and Guilds. The game menu also opens the top-guild directory
directly. Selection is remembered for the session. Mobile uses the existing
landscape panels, typography, buttons, and scrolling container, with 44px actions,
name/rank/hat or name/GP/active-member sorting, refresh, and loading/error/empty states.
Rows preserve group colors and relationship status. View opens the selected player
or guest profile presentation, or the existing guild popup.

`DirectorySource` extracts the roster command, HTTP requests, response parsing,
player duplicate suppression, and cancellation from the classic list classes.
Both views share `PlayerListSort`; online rows are batched at the original 500ms
interval. Online has no completion frame, so its empty state offers refresh rather
than claiming a completed census. Removal ignores late responses and an older
roster owner cannot unregister a newer owner. The classic list artwork and the
mobile directory are excluded from the opposite release. The original
`popup=player-lists` visual fixture is available in classic/preview builds only.

The September 22 pass passed `haxe test/mobile-players.hxml`, the 57 suites in
`./test.sh --lobby --ui`, all three factory configurations, and all three HTML5
build-boundary checks. Tests cover member/guest destinations, real request shapes,
duplicate rows, sorting and tiebreaks, remembered selection, stale responses,
errors/retry, empty lists, teardown, command ownership, and compact touch targets.
Live guest checks at 844×390 and 667×375 verified the online roster, guest profile,
top-guild loading, guild profile, alphabetical sorting, scrolling, and portrait
rotation guard. The temporary guest was logged out afterward. Member-only relationship lists use deterministic payloads;
physical-phone validation remains outstanding.

## Messages

`ScreenFactory.messages()` selects the classic `MessagesTab` or the landscape
`MobileMessagesPage`. The mobile page provides the original ten-message inbox
pages (1–99), a readable message view with sender/profile links, guild indicator,
full sent time and rich links, and a composer with reply quotes, a character count,
1,000-character limit, and formatting reference. Reader and compose actions remain
above the scroll area. Report, delete, and delete-all require confirmation; errors
retain the draft or confirmation, duplicate submissions are disabled while pending,
and successful deletion reloads the server inbox. Opening Messages clears the
shared unread notification just as classic does.

`MessagesSource` owns page requests, parsing and cancellation for both presentations.
`MessageData` shares filtering, HTML escaping/formatting, the original 200-character
reply quote, and compose validation. `MessageRequest` shares the real endpoints and
wire fields, including the existing classic guild-message endpoint. Classic keeps
its authored layout and upload dialogs. Opposite-release build checks now include
the Messages page and classic artwork. Message entry points in profiles, chat,
guild dialogs, and level sharing now route through `ScreenFactory.composeMessage`
and reuse the mobile editor in a modal.

September 22 verification: `haxe test/mobile-messages.hxml`, all three factory
configurations, the 57 suites in `./test.sh --lobby --ui`, and classic/mobile/preview
HTML5 build-boundary checks passed. Deterministic checks cover paging and stale
responses, classic loading, reply quoting, request shapes, validation, duplicate
submission, failed-send draft retention, confirmation/cancellation, deletion refresh,
malformed responses, teardown, and compact touch targets. Browser checks at 844×390
and 667×375 cover menu routing, the unauthenticated error state, scrolling, populated
inbox/reader, reply prefill, and failed-send feedback. Populated browser data and POST
responses used an isolated localhost fixture with no upstream writes. Authenticated
live inbox/send/report/delete and physical-phone keyboard/touch validation remain
outstanding; these checks do not establish end-to-end member parity.

## Player profiles and social actions

`ScreenFactory.profile` selects the original player/guest popups or
`MobileProfilePopup`. Mobile displays the equipped racer, role/status, rank/hats/XP,
user ID, guild link, full dates, and verified/Hall-of-Fame information. An Actions
tab provides message, authored-level search, follow/unfollow, friend/remove-friend,
ignore/unignore, and eligible guild invite/kick controls. Guest restrictions match
classic. Guild mutations require confirmation; pending requests disable repeats
and failures remain visible for retry. Staff tools preserve the existing controls
in a scrollable modal at increased scale; their forms await a full mobile redesign.

`ProfileSource` shares socket-first lookup, five-second HTTP fallback, parsing,
and cancellation. Socket replies have no request IDs: while a reply is outstanding,
other profiles use HTTP. A canceled request retains a reply sink until its response
arrives so an old response cannot fill another profile. `ProfileData`,
`ProfileCharacter`, and `ProfileActions` share role/date rules, avatar assembly,
guild permissions/fields, and navigation. `SocialActions` shares POST fields and
socket verbs. As in classic, the socket command is sent when the action starts;
mobile only changes the persisted relationship label after HTTP success.

`MobilePanelPopup` supplies the shared landscape shell for profiles, compose, and
staff tools. Global compose routes reuse `MobileMessagesPage` without loading or
marking the inbox read. Prefill, locked guild recipients, failure recovery, and
successful dismissal are preserved. Opposite profile and compose implementations
and artwork are excluded from release builds. The original `popup=player-info`
art fixture is available only in classic/preview builds.

Verification: `haxe test/mobile-profile.hxml`, `haxe test/mobile-messages.hxml`, all
three factory configurations, the 57 lobby/UI suites, and all three HTML5 build
boundaries pass. Tests cover socket fallback/overlap, stale replies, permissions,
all relationship actions, guild confirmation/fields, compact targets, compose
handoff/failure/success, and cleanup. Live guest checks cover public profile loading,
disabled relationship controls, mobile compose prefill/cancel, authored-level
search, compact guest profiles, and the portrait rotation guard. The temporary
guest was logged out afterward. Social/guild mutations use fake transports; no live social changes or
messages were submitted. Live member/guild-owner/staff mutations and physical-phone
keyboard, touch, and safe-area validation remain outstanding.

## Guild details

`ScreenFactory.guild` selects the original authored guild popup or
`MobileGuildPopup`. The mobile panel shows the emblem, guild totals and note, member
activity, and the full member roster with profile links. Current members can send
a guild message or leave; eligible logged-in players can request to join. Owners
can transfer ownership, and staff retain the original edit/delete permissions.
Mobile membership changes and deletion use touch-sized confirmations and show
request progress or errors in the guild panel. Create/edit and transfer use
responsive mobile forms.

`GuildData` and cancellable `GuildSource` share guild response parsing and loading
between classic and mobile. The roster preserves server order and owner identity.
Guild create/edit and transfer also route through the factory. Mobile forms share
save fields and the encrypted account-transfer payload with classic. Join, leave,
and delete use mobile confirmations and show request errors in the guild panel.
Live member and privileged action validation remains outstanding.

September 23 verification: classic, mobile, and preview HTML5 builds compiled and
passed the presentation boundary gate. No live guild membership or staff changes
were submitted; focused UI tests and physical-device validation were not run.

## Options and account credentials

`ScreenFactory.options` selects the original options artwork or
`MobileOptionsPopup`. Mobile provides touch controls for music/sound volume,
course-art and chat-filter preferences, the original track allowlist, and all five
alternate keyboard bindings. The Account section routes password/email changes to
mobile forms and exposes mobile guild create/edit/transfer forms and a leave request.

`OptionsSettings` shares volume, preference, allowed-song, and alternate-control
storage with classic. `AccountCredentialActions` shares password/email validation
and the encrypted server payloads; mobile posts to the same endpoints and retains
errors for correction. The classic presentation continues to use its authored
forms. `GuildManagementActions` shares guild save fields and the encrypted ownership
transfer payload between classic and mobile.

## Credits

`ScreenFactory.credits` selects the authored classic credits popup or
`MobileCreditsPopup`. Mobile keeps the original art/design and music credit pages,
version/build text, and page content while adding touch-sized section and paging
controls around a scrollable landscape panel. `CreditsContent` shares page changes
and version text with the classic popup.

The Vault of Magics is slated for removal, so it is intentionally excluded from the
mobile migration.

## Detailed level information

`ScreenFactory.levelInfo` selects the authored popup or `MobileLevelInfoPopup`.
Both use `LevelInfoSource` and `LevelInfoData` for loading, response parsing, mode
and song labels, dates, and level rules. Mobile shows access requirements, rating,
plays/version, time limit, mode, music, gravity, items, hats, notes, and author
navigation. Play and message sharing use the shared destinations. Report and
moderation fields are shared with classic; mobile provides touch forms and visible
request errors. Authenticated report and moderation validation remains outstanding.

## Migration gaps

These are configuration boundaries, not a claim that the mobile release is ready:

- Profiles, compose, and authentication have mobile dialogs; several secondary
  global popups still use their original UI.
- The lobby Play/browser/search, My Racer, player lists, top-guild directory,
  Messages inbox/reader/composer, game menu, race-entry, options, and credits are
  mobile. The Vault of Magics is slated for removal.
  Chat retains its earlier mobile presentation. Detailed level information, guild
  management, part details, staff controls, and prize/Lux notices also have mobile
  presentations. The menu's Level Editor opens the real editor directly;
  the mockup's proposed My Levels destination has not been added.
- Guild details and the roster have a mobile panel. Staff tools have mobile layouts
  for warnings, priors, kicks, account/IP/game/social bans, and moderator roles,
  using shared request fields and socket commands.
- Authenticated live Messages/social/guild actions and physical-phone keyboard
  behavior remain unverified.
- My Racer's detailed part information uses a mobile card with the shared character
  preview, acquisition links, ownership status, epic status, and equip action. Guild
  detail popups are mobile.
  Its optional advanced color picker preserves the original HSV/eyedropper workflow;
  RGB, hex, and palette selection have mobile controls.
- The Level Editor and other remaining secondary screens retain their original
  presentations. Temporary event announcements reuse original art at the viewport
  center. Physical-device multi-touch, thumb reach, software keyboard behavior, and
  safe areas remain to be validated.
- The mobile title fits a landscape canvas within the available viewport. Browser
  portrait mode shows a rotation hint; browser orientation is not forcibly locked.
  Native landscape configuration still needs device validation and safe-area work.
- Instructions retain the existing browser handoff; no native instructions
  destination has been implemented.
- Native login socket probing remains unsupported; the working transport targets
  HTML5. Mobile software-keyboard behavior and safe areas need physical-device validation.

## Focused verification

The September 22 results pass passed `./test.sh --gameplay --ui` (43 suites),
`haxe test/mobile-results.hxml`, and all three `test/ui-config.hxml`
configurations. The mobile results tests exercise buffered/late awards and XP,
rating confirmation/cancellation/error/retry, duplicate request suppression,
teardown with late completion, resize state retention, timeout, spectating and
reopening, and returning to the mobile lobby. Rating requests use a fake transport
so no live ratings are submitted. Classic, mobile, and preview HTML5 builds passed
their presentation boundary checks.

The live guest flow was checked at 844×390 and 667×375: server-confirmed race
entry, quitting to mobile results, rating selection and confirmation cancellation,
portrait rotation hint, Keep watching, reopening results, and returning to the
mobile lobby. The guest was logged out afterward. The populated results fixture
also verified XP and rating layout at the compact size. No live rating was sent.

`haxe test/mobile-game-ui.hxml` checks grounded up-only input, increased jump height,
no repeat jump on landing, simultaneous action/direction input, independent finger
ownership, swap cancellation, real item-display parenting and empty-state hiding,
menu input blocking, music scrolling, teardown, and wider viewport culling without
changing the camera position. `./test.sh --physics --gameplay --level-rendering --ui`
covers the affected classic behavior. The gameplay pass passed every assertion;
existing physics/item/quit cases exceeded the 250 ms timing gate on the laptop.

The mobile HUD was also exercised at 844×390 and 667×375 through real guest login,
server-confirmed race entry, playable Newbieland 2, side swapping, chat/music panels,
confirmed quitting, timeout/results, and return to lobby. No live chat messages
were sent. Item state and simultaneous finger ownership were tested deterministically;
physical-device testing remains outstanding. Temporary guest sessions were logged out.

Run `haxe test/ui-config.hxml`, then repeat with `-D pr2_mobile_ui` and
`-D pr2_ui_preview`. These check factory selection, release query isolation,
session arguments, title identity for disconnect recovery, and viewport intent.
They also exercise both authentication presentations with mock network transports:
server loading, recovery cancellation, registration validation/retry/success,
saved-account removal, and late responses after page removal. No real accounts or
recovery emails are created by these tests.

Mobile/preview configuration tests also exercise course requests, stale responses,
invalid hashes, search filters, paging boundaries, guest/member favorites, password
unlock, favorite success/failure/teardown, live roster updates, shared countdown,
confirmation, cancellation, and server-only launch. These use transport callbacks
and the real command dispatcher, with no live account mutations.

The September 21 lobby pass was also checked in-browser at 844×390 and 667×375,
using live campaign lists and creator search through the dev proxy. A temporary
guest session verified login, slot acknowledgement, race confirmation, a loaded
playable course, and the results return path back to the mobile lobby. Favorite mutations and password-gated levels were
verified with deterministic responses rather than modifying a real account.

`./test.sh --ui --lobby --network` exercises the shared login workflow and related
UI/session behavior. Authentication test assertions now target `LoginFlow`
directly rather than reaching into a title page's private fields.
