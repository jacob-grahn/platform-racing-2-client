# Mobile UI plan — page and functionality inventory

Status: step 1, proposed information architecture. No UI implementation changes.

## Direction and scope

Maintain two presentations: a faithful recreation of the original web UI and a responsive, modern mobile UI. Share game rules, session state, networking, validation, and suitable components without requiring the two presentations to share their page structure.

Design direction agreed September 20, 2026: keep mobile menus and gameplay in landscape, avoiding rotation between them. Favor PR2's game identity and artwork over conventional app navigation. See [the mockup notes](mobile-ui-mockups.md) for the current Play and Character exploration. This inventory remains organized by function rather than prescribing controls for every page.

Here, a **page** means a coherent user task or destination. It does not yet mean a separate route or full-screen view. Some entries may eventually become part of another page or a contextual interaction. Navigation, bottom bars, sheets, menus, tabs, layouts, gestures, and breakpoints are deliberately undecided.

The inventory includes ordinary players, guests, creators, guild owners, and staff. Inclusion records required coverage; it does not set release priority or claim that the current mobile implementation supports the feature. Functional groupings below are proposals. Original behavior is grounded in the Flash source.

## Original-game visual references

Reviewed screenshots in `test/baselines/flash/`:

| Reference | Identity to carry forward |
| --- | --- |
| [Login](../test/baselines/flash/01_login.jpg) | Deep blue sky, soft white clouds, bright yellow-green grass, rolling green hills, playful outlined title lettering. |
| [Lobby](../test/baselines/flash/04_lobby_unobstructed.jpg) | Pale blue and translucent light surfaces, dark readable text, green accents and rating stars, colorful character art. |
| [Level entry](../test/baselines/flash/06_level_entry.jpg) | Level and player identity remain visible while preparing to race; a warm highlight distinguishes the selected player slot. |
| [Level editor](../test/baselines/flash/11_item_editor.jpg) | Lavender workspace, visible grid, recognizable block artwork, clear distinction between construction and play. |

Use these as the starting character and palette, with enough contrast and clarity for small screens. Exact colors, typography, surface treatments, and component designs belong to the next step. The screenshots capture a guest session and cannot establish the complete member or staff experience; source code supplies those requirements.

## Entry and account access

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| A1 · Welcome | Identify the game; start login or guest play; reach account creation, instructions, and credits. Represent startup/loading and allow the intro to finish or be skipped where supported. | `flash/menu/LoginPage.as`, `IntroPage.as` |
| A2 · Sign in and saved accounts | Enter credentials; remember an account; select a saved account or use another; remove a saved login without implying account deletion; reach password recovery; explain authentication failures. | `flash/menu/LoginPopup.as`, `ServerSelectPopup.as` |
| A3 · Create account | Collect the original registration fields, confirm password, validate inputs, show server errors and successful creation, then continue to server selection. | `flash/menu/CreateAccountPopup.as` |
| A4 · Recover password | Submit username and email; preserve useful input from login; show the recovery response and return to sign in. | `flash/menu/ForgotPassPopup.as` |
| A5 · Choose server | Show available servers and their supplied status/population; refresh availability; preserve guest or selected-account identity; connect or cancel; handle unavailable servers and failed connections. | `flash/menu/ServerSelectPopup.as`, `CheckServers.as`, `ConnectingPopup.as`, `LoggingInPopup.as` |

## Find and play levels

These destinations replace the level-browsing half of the original lobby. A separate generic home/dashboard is not currently needed: **Play** can be the post-login starting destination, subject to the next design step.

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| P1 · Play / discover levels | Access Campaign, All Time Best, Week's Best, and Newest; browse all available pages; see level title, creator, rating, rank requirement, and live participant/slot information. Preserve the chosen collection and position on return. | `flash/lobby/LobbyRight.as`, `flash/level_browser/{Campaign,Best,BestWeek,Newest,LevelListing,Slot}.as` |
| P2 · Search levels | Search using the original supported search modes, including creator and level ID; set sort order and direction; browse results; retain query and position. Accept entry from a creator profile or shared level reference. Distinguish no results, invalid input, and request failure. | `flash/level_browser/Search.as` |
| P3 · Favorite levels | View and manage the signed-in player's favorites; browse them and enter a level; represent an empty collection and guest restrictions. | `flash/level_browser/Favorites.as`, `LevelItem.as` |
| P4 · Level details | Show title, description, creator, ID/version, plays, rating, last update, minimum rank, game mode, music, gravity, time limit, allowed items/hats, and Cowboy Mode chance. Reach creator profile, share via the existing message flow, report a level, and enter play when eligible. Preserve the existing published/unpublished and access rules. | `flash/dialogs/LevelInfoPopup.as`, `LevelReportPopup.as` |
| P5 · Race entry / waiting | Join a level slot; show the current participants and the server's wait/countdown state; indicate readiness/start via the original Play action; cancel/leave before starting. Handle rank restrictions, a filled slot, remote cancellation, and loading failure. | `flash/level_browser/Slot.as`, `CourseMenu.as`, `flash/gameplay/Course.as` |
| P6 · Race | Provide movement, jumping, crouching/charging, and item use through touch-accessible input. Show countdown, timer, held item, race/player status, minimap, and mode-specific information such as lives. Preserve race chat, music behavior, quit flow, and special-event rules. Additional UI must not imply that an online race pauses. | `flash/gameplay/{Game,Course,ItemDisplay,StatsDisplay,Hearts,MiniMap,RaceChat,QuitButton,SpecialEvent}.as` |
| P7 · Spectate | Observe the race and select a player to follow when spectating is available; retain relevant race status, chat, and a way to leave. Keep this distinct from controlling a racer even if both ultimately share a page. | `flash/gameplay/SpectatePicker.as`, `Game.as` |
| P8 · Race results and rewards | Show awarded experience and its breakdown, progress toward rank, and server-issued rewards. Rate the level when eligible; return to level browsing or dismiss results to remain in the race context. Represent prize announcements, duplicate-prize compensation, cancelled prizes, and Lux awards when issued. | `flash/gameplay/{FinishedPage,ExpGain,PrizePopup,LuxPopup}.as` |

## Character and progression

The original Account area bundles identity, appearance, stats, and loadouts. Separate these responsibilities for planning; their eventual presentation can still be closely connected.

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| C1 · My character and progression | Show current character, player identity, rank/experience, hats, and guild; reach customization, stats, loadouts, and the player's public profile. Clearly distinguish guest changes from persistent account data. | `flash/player_profile/AccountInfo.as`, `PlayerDisplay.as` |
| C2 · Customize appearance | Preview and equip owned hats, heads, bodies, and feet; change supported primary/secondary colors; represent epic variants; randomize appearance; apply supported outfit data and save changes through the existing behavior. | `flash/player_profile/{AccountInfo,PartSelector,RandomizeStyleButton}.as`, `flash/dialogs/OutfitPopup.as` |
| C3 · Stats and rank tokens | Allocate speed, acceleration, and jumping within the available point budget; show points remaining; activate/deactivate owned rank tokens and reflect the resulting rank/stat changes. | `flash/ui/StatsSelect.as`, `flash/player_profile/AccountInfo.as` |
| C4 · Loadouts | Inspect saved slots, save/replace a loadout, and apply a saved appearance/stat configuration according to existing loadout rules. All operations must be reachable without number-key shortcuts. | `flash/player_profile/{LoadoutsPopup,Presets,Preset}.as` |
| C5 · Parts collection and part details | Browse part categories; show owned/unowned and epic ownership, previews, descriptions, and acquisition instructions; follow linked levels/creators; equip eligible owned parts. | `flash/player_profile/PartInfo/{PartInfoPopup,PartInfoListing,PartPopup}.as` |

## Communication and players

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| S1 · Chat | Read/send room messages and system messages; join another named room; inspect room information; follow player, guild, level, and external references. Preserve supported chat commands and artifact hints. Allow reading older messages without incoming messages continually displacing them. | `flash/chat/ChatInstance.as`, `ChatRoomInfoPopup.as`, `flash/page/Chat.as`, `ArtifactHint.as` |
| S2 · Private messages | Browse received messages and pages; show unread state; open/read, reply, report, or delete a message; delete all with confirmation. Preserve system messages and actionable guild invitations. This is an inbox, with no new threaded-conversation backend assumed. | `flash/chat/{Messages,MessagesItem}.as`, `flash/com/jiggmin/data/UnreadNotif.as` |
| S3 · Compose message | Address a player, compose/send text, and show validation or delivery failure; support reply and prefilled level-sharing content; send guild messages when permitted; make existing rich-format/reference help available. | `flash/dialogs/SendMessagePopup.as`, `PMRFCodesPopup.as` |
| S4 · Players and relationships | Browse online players, friends, followed players, and ignored players; retain each list's available paging/sorting and presence information; open player details. Keep friend, follow, and ignore relationships distinct. | `flash/social/{PlayersTab,Online,Friends,Following,Ignored,PlayersTabList}.as` |
| S5 · Player profile | Show character, rank/experience, guild, registration/activity information, badges, and player ID. View their levels; message, friend/unfriend, follow/unfollow, or ignore/unignore as permitted; invite/kick guild members when authorized. Provide the reduced guest profile where appropriate. Make information formerly revealed by hover or Shift accessible by touch. | `flash/dialogs/PlayerPopup.as`, `PlayerGuestPopup.as` |

## Guilds

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| G1 · Guild directory | Browse the existing guild list and its supplied standings/points; open a guild. Do not infer a new global player leaderboard from the presence of guild listings. | `flash/social/Guilds.as`, `PlayersTabGuildListItem.as` |
| G2 · Guild details / my guild | Show name, ID, emblem, description, daily/total guild points, member and active counts, and member profiles. Reach guild messaging and the management actions allowed by membership/ownership. | `flash/dialogs/GuildPopup.as`, `GuildMemberName.as` |
| G3 · Guild membership and management | Create/edit a guild with its original fields, membership policy, and emblem workflow; accept/decline invitations; leave a guild; manage invitations/removals via player profiles; transfer ownership with existing authentication requirements. Keep staff editing/deletion separate from ordinary owner permissions. | `flash/dialogs/{CreateGuildPopup,GuildJoinPopup,TransferGuildPopup,OptionsPopup,PlayerPopup,GuildPopup}.as` |

## Store, settings, and information

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| U1 · Vault of Magics | Load the live catalog, prices, currency balance, availability, promotions, and product explanations; choose supported quantities; review/confirm a purchase; show insufficient funds, success, and failure; refresh ownership/balance; activate eligible boosters. Preserve the external coin-purchase handoff without assuming a new payment integration. | `flash/shop/{StorePopup,StoreListing,QuantityPopup}.as` |
| U2 · Game settings | Set music/effects volume and mute; configure chat filtering, level-art visibility/quality, allowed music, and supported control bindings. Mobile input preferences are an extension to define during interaction design, not a reason to discard existing settings. | `flash/dialogs/{OptionsPopup,OptionsArtQualityMenu,OptionsSongsMenu}.as`, `flash/ui/MuteButton.as` |
| U3 · Account settings | Change password and email; manage sign-out and saved-login behavior; expose the existing account-verification flow when invoked. Preserve errors and reauthentication requirements. Guild settings move conceptually to G3 rather than being lost when Options is reorganized. | `flash/dialogs/{ChangePasswordPopup,SetEmailPopup,LogoutPassPopup,DiscordVerificationPopup}.as`, `flash/lobby/Lobby.as` |
| U4 · Instructions, credits, and community links | Explain play and mobile controls; expose original credits and relevant help/community destinations. Preserve externally hosted instructions as a handoff unless a separately scoped in-app replacement is authored. Explain an external destination before leaving when the original flow does so. | `flash/menu/{LoginPage,CreditsPopup,KongOutfitPopup}.as`, `flash/dialogs/ExternalLinkPopup.as` |

## Level creation

Keep creation in the inventory even if its mobile release comes later. A play-only first release must explicitly mark these destinations deferred, not treat them as covered by a scaled desktop editor.

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| E1 · My levels | List and load saved levels, including unpublished work; start a new level; delete with confirmation; show loading/deletion failures. Preserve the authenticated editor entry/return flow. | `flash/level_management/GetLevels.as`, `LoadingLevelPopup.as`, `DeletingLevelPopup.as`, `flash/levelEditor/GetLevelsPopupItem.as` |
| E2 · Edit level | Navigate/zoom the workspace; place/remove blocks and configure special-block properties; work with art layers 00, 0, 1, 2, and 3; draw/erase, place stamps and text, adjust colors and sizes, and edit backgrounds. Support undo/redo, new/reset, test, save, and exit while protecting unsaved work. | `flash/levelEditor/{LevelEditor,LevelEditorMenu}.as`, `flash/editor_sidebar/`, `flash/drawing_tools/`, `flash/blocks/options/` |
| E3 · Level rules | Edit music, available items, allowed hats, minimum rank, gravity, time limit, game mode, Cowboy Mode chance, and the password for unpublished play. Preserve current values and validation when returning to the workspace. | `flash/editor_sidebar/Settings.as`, `flash/editor_tools/` |
| E4 · Save and publish | Set title and description with their existing limits; choose published/unpublished state and whether to submit to Newest; submit the real save/upload and report its result; retain work after failure. | `flash/level_management/SaveLevelPopup.as`, `UploadingLevelPopup.as` |
| E5 · Test level | Play the current draft, use the existing test-specific hat/drawing capabilities, and return to editing without losing the draft. Keep test results distinct from live race rewards or publication. | `flash/gameplay/TestCourse.as`, `DrawingInfo.as`, `flash/levelEditor/HatPicker.as`, `DrawingPopup.as` |

## Staff-only functionality

These are permission-dependent destinations or contextual tasks, not ordinary player navigation. Preserve temporary/trial/permanent moderator and administrator distinctions, plus guild-server restrictions.

| ID / candidate page | Required functionality | Original source |
| --- | --- | --- |
| M1 · Player moderation | Inspect permitted player information and prior offenses; issue warnings, kicks, and bans with applicable scope, reason, and duration; show consequences and request results; retain relevant chat evidence. Administrators can promote/demote staff according to existing rules. | `flash/dialogs/{PlayerPopup,TempModMenu,BanMenu,AdminMenu}.as` |
| M2 · Level reports and review | Browse reported levels, inspect report context and the level, load/test it for review, archive a report, and perform authorized unpublishing/deletion or creator sanctions. Preserve report context when returning from review. | `flash/level_management/{ChooseLevelsModePopup,GetLevelReports,HandleLevelReportPopup}.as`, `flash/dialogs/ChooseLevelModModePopup.as` |
| M3 · Guild moderation | Edit guild data and delete a guild only at the original permission level, with confirmation and a clear result. | `flash/dialogs/GuildPopup.as`, `CreateGuildPopup.as` |

## Shared flows and states that need a mobile treatment

These are requirements across pages, not a request to make every original popup into a page:

- **Connection lifecycle:** initial loading, authentication, connecting, disconnect/timeout, server rejection, and return to a valid entry point. Do not imply an automatic reconnect/resume guarantee the server does not provide.
- **Request lifecycle:** loading, empty, success, validation failure, permission denial, and retry where valid. Prevent accidental duplicate messages, saves, and purchases while a submission is pending.
- **Confirmations:** purchases, deleting messages/levels/saved logins, leaving/transferring guilds, moderation, quitting, and discarding editor work. Explain the actual consequence; preserve temporary-moderator warnings on logout or editor entry.
- **Context preservation:** return to the originating collection, query, profile, message, or editor draft. Carry entity IDs and pending form input across related tasks.
- **Live state:** preserve the appropriate session, race membership, player-slot updates, unread counts, and currency/ownership updates as the user moves between destinations.
- **Guest and permission states:** make unavailable capabilities and their reasons clear. Keep existing member/rank/ownership/staff checks authoritative.
- **Touch access:** preserve information and actions previously available only through hover, keyboard shortcuts, tiny indicators, or contextual menus. Account for the software keyboard, safe areas, readable text, and device rotation without choosing controls yet.
- **Server-driven events:** welcome/information messages, reward notifications, special events, artifact hints, and the cat verification challenge must remain actionable in context. They do not each require a permanent destination.
- **Cross-links:** player → their levels; part → acquisition level/creator; chat/message → player, guild, or level; guild → member profile; level → share/report. Returning should not strand the user in an unrelated section.

## Proposed regrouping of the original UI

| Original location | Mobile responsibilities |
| --- | --- |
| Login screen plus authentication popups | A1–A5: welcome, account access, and server choice. |
| Right lobby tabs and slot interaction | P1–P5: discovery, search, favorites, level details, and race entry. Collections can share a destination while keeping distinct state. |
| Account tab plus customization popups | C1–C5: identity/progression, appearance, stats, loadouts, and collection knowledge. |
| Chat/PMs/Players tabs and profile popups | S1–S5 and G1–G3: communication, relationships, and guilds, with contextual links between them. |
| Options popup | U2 game preferences, U3 account management, and G3 guild management. |
| Lobby utility actions | Reach creation, store, settings, credits, and logout without inheriting the original arrangement. |
| Race HUD and finish/reward popups | P6–P8 plus contextual events: racing, spectating, and results. |
| Editor layers/settings and management popups | E1–E5: level library, workspace, rules, saving/publishing, and testing. |
| Staff actions embedded throughout the game | M1–M3, reached only where the current user is authorized. |

## Boundaries and next decisions

- The existing `haxe/src/pr2/page/MobileLobbyPage.hx` and `haxe/src/pr2/mobile/` are implementation references, not the approved page map or visual direction. The current shell still hosts original account/player/message views and popups; their presence does not demonstrate completed mobile flows.
- No new social feed, matchmaking system, achievement system, global player leaderboard, threaded messaging backend, or payment platform is assumed.
- Verify deployment-dependent services before implementation: account verification, external purchases/help, sponsor-specific rewards, guild emblem upload, and staff tools. Their source presence establishes a workflow to account for, not live service availability.
- Next, decide which candidate pages stay independent or become contextual tasks; choose navigation and interaction patterns; establish the responsive visual system from the original palette; and choose release order, especially editor and staff coverage.
- Validate the resulting design against complete journeys: guest → server → race → results; member → customize/loadout → race; discovery → detail → favorite/share/report; chat → player → their levels; inbox → reply/invitation; guild creation/management; store → purchase result; and draft → test → save/publish → reopen.

This document inventories functionality and proposes its ownership. It does not certify implementation parity or defer any original feature by omission.
