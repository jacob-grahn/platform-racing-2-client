# Source Class Coverage

This inventory tracks first-party AS3 classes against their Haxe/OpenFL port,
platform adapter, or remaining gap. Keep entries narrow: an exported symbol
alone is not a class port.

## Background Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/background/Background.as` | `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | The active view-window culling, camera offset, and holder layering are represented by `ServerLevelRenderer` and `Course`; the exact shared Flash base class is not a standalone Haxe type. |
| `flash/background/BlockBackground.as` | `pr2.level.ServerLevelRenderer`, `pr2.level.ServerLevelFixtureAdapter` | partial | Block display creation, segment-grid attachment, and fixture conversion are covered by renderer/fixture tests; editor-specific mutation paths remain with the level-editor TODO. |
| `flash/background/BlockGridLines.as` | level-editor grid gap | gap | The editor's authored block-grid overlay is not ported yet and remains part of the level-editor sidebar/camera/tooling work. |
| `flash/background/DrawableBackground.as` | `pr2.level.ServerLevelRenderer`, `pr2.level.ServerLevelDecoder` | ported | Decoded draw strokes, text, and stamp objects render incrementally across the five art planes, with raster-tile sizing and drawing-readiness coverage in `ServerLevelRendererTest` and `GameShellMountTest`. |
| `flash/background/EffectBackground.as` | `pr2.level.ServerLevelRenderer`, `pr2.effects.*`, `pr2.gameplay.Course` | partial | Mine explosions, block pieces, arrow animations, vanish activation, and water ripples use renderer/effect ownership; loose hats, egg physics, shots, and shared effect-background behavior remain explicit effect gaps. |
| `flash/background/LevelBackground.as` | `pr2.level.ServerLevelRenderer` | ported | The five authored art planes are mounted around the block layer with Flash's rounded parallax scales, covered by `ServerLevelRendererTest`. |
| `flash/background/Map.as` | `pr2.level.ServerLevelFixtureAdapter`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | Server maps decode into fixture/render layers, preserve start-block spawn/non-collision behavior, and drive the live course shell. Editor map editing and live block mutation completeness remain with editor/gameplay gaps. |
| `flash/background/ObjectBackground.as` | `pr2.level.ServerLevelDecoder`, `pr2.level.ServerLevelRenderer` | partial | Server stamp/object decoding and display are represented in the renderer; editor placement, selection, and deletion remain with the level-editor TODO. |

## Item Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/items/IceWave.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Three-use item, 1000ms reload, direction payload, and left-facing parity are covered by `LocalPlayerControllerTest`. Live network effect emission is represented by the local item-effect payload. |
| `flash/items/Item.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Availability-on-key-release, use counts, reload timing, and item clearing are covered by `LocalPlayerControllerTest`. `SecureData` is intentionally replaced by controller state. |
| `flash/items/Items.as` | `pr2.gameplay.Items`, `pr2.harness.LocalPlayerController` | ported | The item-code catalog and level allowed-item pool are represented by `Items`; empty-options item-block selection is covered by `LocalPlayerControllerTest`. |
| `flash/items/JetPack.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Fuel, ammo pips, crouch gate, thrust amounts, and expiry are covered by `LocalPlayerControllerTest`. Jet visual hooks remain part of the broader character-effects TODO. |
| `flash/items/LaserGun.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Three shots, 800ms reload, direction payload, and recoil are covered by `LocalPlayerControllerTest`. Projectile visuals/network side effects remain under multiplayer item/effect integration. |
| `flash/items/Lightning.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | The exact `zap\`` payload and consume-on-use behavior are covered by `LocalPlayerControllerTest`. |
| `flash/items/Mine.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Placement tile, blocked placement, rotated effect coordinates, and placed mine collision are covered by `LocalPlayerControllerTest`. |
| `flash/items/SpeedBurst.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Five-second boost, stat reset on expiry, and held-item lifetime are covered by `LocalPlayerControllerTest`. Sparkle visuals remain part of the broader character-effects TODO. |
| `flash/items/SuperJump.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Upward impulse, consume-on-use, and crouch suppression are covered by `LocalPlayerControllerTest`. |
| `flash/items/Sword.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Three swings, 800ms reload, direction payload, and lunge direction are covered by `LocalPlayerControllerTest`. Weapon visuals/network side effects remain under multiplayer item/effect integration. |
| `flash/items/Teleport.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Distance, destination blocking, start/end effect coordinates, and consume behavior are covered by `LocalPlayerControllerTest`. |

## Block Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/blocks/ArrowBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Shared arrow behavior is represented by the directional block types; stand impulses, remote-visible animation, and fixture conversion are covered by `LocalPlayerControllerTest`, `RemoteCharacterConsumeTest`, and `ServerLevelFixtureAdapterTest`. |
| `flash/blocks/ArrowDownBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Downward stand impulse and object-code mapping are covered by `LocalPlayerControllerTest` and `ServerLevelFixtureAdapterTest`. |
| `flash/blocks/ArrowLeftBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Leftward stand impulse and object-code mapping are covered by `LocalPlayerControllerTest` and `ServerLevelFixtureAdapterTest`. |
| `flash/blocks/ArrowRightBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Rightward stand impulse and object-code mapping are covered by `LocalPlayerControllerTest` and `ServerLevelFixtureAdapterTest`. |
| `flash/blocks/ArrowUpBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Upward stand impulse and object-code mapping are covered by `LocalPlayerControllerTest` and `ServerLevelFixtureAdapterTest`. |
| `flash/blocks/BasicBlock.as` | `pr2.level.BlockType`, `pr2.level.FixtureLevel`, `pr2.level.ServerLevelRenderer` | ported | Solid collision, server-code conversion, and block-layer rendering are covered by `LocalPlayerControllerTest`, `ServerLevelFixtureAdapterTest`, and `ServerLevelRendererTest`. |
| `flash/blocks/Block.as` | `pr2.level.FixtureLevel.LevelBlock`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Tile position/options, active/removed state, collision participation, and block visuals are split across fixture blocks, controller block state, and renderer block instances. |
| `flash/blocks/Blocks.as` | `pr2.level.ObjectCodes`, `pr2.level.BlockType`, `pr2.harness.FixtureLevelRenderer`, `pr2.level.ServerLevelRenderer` | ported | Object-code lookup, type conversion, and 30 px block assets are covered by fixture/renderer tests. |
| `flash/blocks/BrickBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | One-hit break-on-bump behavior and removal from collision are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/CrumbleBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Ten-frame crumble timing and removal are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/CustomStatsBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Stat-option application and reset semantics are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/FinishBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Finish is a one-use supply block; bump-only completion id/center reporting is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/HappyBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Supply stat increase and option clamp behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/HeartBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | One-use life supply behavior is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/IceBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Ice movement friction behavior is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/InfItemBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Items` | ported | Infinite item supply behavior and level allowed-item pool selection are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/ItemBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Items` | ported | One-use item supply, grey transform state, and allowed-item pool selection are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/MineBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Launch/removal behavior and explosion/block-piece visuals are covered by `LocalPlayerControllerTest` and `ServerLevelRendererTest`. |
| `flash/blocks/MoveBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Preview/reselect timing, movement, blocked shifts, and player-occupied blocking are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/PushBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Push-block downward movement behavior is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/RotateBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.RotationMath` | ported | Shared rotation tween, coordinate rotation, and character counter-rotation are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/RotateLeftBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Left rotation direction and completion behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/RotateRightBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Right rotation direction and completion behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/SadBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Supply stat decrease and option clamp behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/SafetyBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Safe-coordinate update without solid collision is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/StartBlock.as` | `pr2.level.BlockType`, `pr2.level.ServerLevelFixtureAdapter` | ported | Spawn discovery and non-colliding start-block behavior are covered by `ServerLevelFixtureAdapterTest` and `LocalPlayerControllerTest`. |
| `flash/blocks/SupplyBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Shared one-use bump-only depletion behavior for brick/finish/stat/life/time supplies is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/TeleportBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Same-color teleport pairing and disabled reset timing are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/TimeBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | One-use race-time supply behavior is covered by `LocalPlayerControllerTest`. |
| `flash/blocks/VanishBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Fade, fall-through, reappear, and remote-visible activation are covered by `LocalPlayerControllerTest`, `RemoteCharacterConsumeTest`, and `ServerLevelRendererTest`. |
| `flash/blocks/WaterBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Swimming mode and remote ripple effects are covered by `LocalPlayerControllerTest` and `RemoteCharacterConsumeTest`. |
| `flash/blocks/options/BlockOptions.as` | `pr2.level.FixtureLevel.LevelBlock`, `pr2.gameplay.LevelConfig` | ported | Raw option strings are preserved on decoded blocks and parsed at each behavior boundary. |
| `flash/blocks/options/CustomStatsBlockOptions.as` | `pr2.harness.LocalPlayerController` | ported | Custom stats options and reset token are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/options/ItemBlockOptions.as` | `pr2.gameplay.Items`, `pr2.harness.LocalPlayerController` | ported | Item option parsing and empty-options allowed-pool selection are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/options/StatBlockOptions.as` | `pr2.harness.LocalPlayerController` | ported | Happy/sad stat option clamps are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/options/TeleportBlockOptions.as` | `pr2.harness.LocalPlayerController` | ported | Teleport color matching and default color behavior are covered by `LocalPlayerControllerTest`. |

## Character Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/character/ArrowSparkleEmitter.as` | `pr2.character.Character` hook boundary | gap | The base character exposes sparkle network hooks, but the random colored arrow particle emitter and its authored `ArrowEffect` visual are still deferred with the character/effects visual work. |
| `flash/character/Character.as` | `pr2.character.Character`, `pr2.character.CharacterDisplay` | ported | Appearance ids/colors, four-slot hat stack and special-hat flags, animation state changes, geometry helpers, block-touch probes, recovery flash, and fade-out removal are covered by `CharacterBaseTest`. Particle, jet, Djinn, weapon-display, and sound side effects are explicit hook boundaries. |
| `flash/character/DjinnEffects.as` | `pr2.character.Character` hook boundary | gap | Djinn body/feet particle emission remains deferred; the character core records it as an unported visual side effect rather than silently substituting a generic effect. |
| `flash/character/LocalCharacter.as` | `pr2.character.LocalCharacter`, `pr2.harness.LocalPlayerController` | ported | Local multiplayer character construction, controller-backed physics, stats/gravity/item state mirroring, network position/var emission, and race event payloads are covered by `LocalCharacterTest`, `LocalPlayerControllerTest`, and `LocalCharacterEmitTest`. Remaining hat/effect visuals stay under the gameplay behavior TODO. |
| `flash/character/ParticleEmitter.as` | character visual-effect hook boundary | gap | Timed particle spawning for sparkles/Djinn visuals is not yet ported; current character tests intentionally verify no hidden substitute behavior. |
| `flash/character/PhysicsParticle.as` | character visual-effect hook boundary | gap | The parameterized Djinn particle physics and lifetime fade are not yet represented in Haxe; this is part of the deferred character visual-effects audit. |
| `flash/character/PositionedParticleEmitter.as` | character visual-effect hook boundary | gap | Parent-space positioned particle spawning for moving character parts remains deferred with `DjinnEffects`. |
| `flash/character/RainbowStarEmitter.as` | `pr2.character.Character` hook boundary | gap | Rainbow sparkle particles are not yet rendered; sparkle start/end is currently exposed through local/remote network hooks. |
| `flash/character/RemoteCharacter.as` | `pr2.character.RemoteCharacter`, `pr2.gameplay.RemoteBlockActivation` | ported | Temp-id command registration, queued position/var/exact-position consumption, Flash catch-up interpolation, minimap-dot updates, remote block-touch probes, and command teardown are covered by `RemoteCharacterConsumeTest`. Sparkle, jet, heart, and sting visuals remain hook boundaries. |

## Chat Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/chat/ChatInstance.as` | `pr2.lobby.tabs.ChatTab`, `pr2.lobby.chat.ChatLog`, `pr2.lobby.chat.HtmlNameMaker` | partial | The authored chat tab, room persistence, `set_chat_room`, send routing, transcript rendering, lock-to-bottom behavior, and Ctrl update toggle are represented in `ChatTab`/`ChatLog`; the hover room-info popup is still a gap. |
| `flash/chat/ChatRoomInfoPopup.as` | chat room info popup gap | gap | The `get_chat_rooms` request, `setChatRoomList` command registration, and authored hover popup list are not yet ported even though the command parser itself is covered by `LobbyServicesTest`. |
| `flash/chat/DeleteMessageButton.as` | `pr2.lobby.dialogs.MessagesItem` | ported | The authored delete button graphic is mounted by `MessagesItem`, and its click opens the delete confirmation before routing to `MessagesTab.doDelete`. |
| `flash/chat/Messages.as` | `pr2.lobby.tabs.MessagesTab`, `pr2.lobby.messages.MessagesPaging`, `pr2.lobby.messages.UnreadNotif` | partial | The PMs tab loads `messages_get.php`, paginates ten messages, lays out `MessagesItem` rows, opens compose/delete-all flows, and POSTs report/delete through `UploadingPopup`; exact unread badge behavior, swear filtering parity, and error/empty visual states remain lobby workflow gaps. |
| `flash/chat/MessagesItem.as` | `pr2.lobby.dialogs.MessagesItem`, `pr2.lobby.chat.ChatText`, `pr2.lobby.chat.HtmlNameMaker` | partial | Sender names, guild marker, escaped body text, sent-time hover, reply quote truncation, and report/delete confirmations are ported; Flash `Data.parseLinks` URL detection and full date-format parity remain explicit gaps. |
| `flash/chat/ReplyMessageButton.as` | `pr2.lobby.dialogs.MessagesItem` | ported | The authored reply button graphic is mounted by `MessagesItem`, and its click opens `SendMessagePopup` with the Flash-shaped quoted body. |
| `flash/chat/ReportMessageButton.as` | `pr2.lobby.dialogs.MessagesItem` | ported | The authored report button graphic is mounted by `MessagesItem`, and its click opens the moderation report confirmation before routing to `MessagesTab.doReport`. |

## Dialogs Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/dialogs/AdminMenu.as` | admin/moderation popup gap | gap | The authored admin side menu and its role-gated server actions remain under the admin/moderation popup TODO. |
| `flash/dialogs/AutoDismissPopup.as` | `pr2.lobby.dialogs.InfoPopup` subclasses | partial | The current hover/info popup base supports explicit popup removal and authored layout, but Flash's generic timed auto-dismiss base is not represented as a standalone reusable class. |
| `flash/dialogs/BanMenu.as` | admin/moderation popup gap | gap | The authored ban menu, duration/reason controls, and moderation requests are not yet ported. |
| `flash/dialogs/ChangePasswordPopup.as` | account password-change gap | gap | The password-change form and request flow remain under the account workflow TODO. |
| `flash/dialogs/ChooseLevelModModePopup.as` | level-info moderation gap | gap | Level moderation mode selection is still part of the level-info report/rating/moderation action TODO. |
| `flash/dialogs/ConfirmPopup.as` | `pr2.lobby.dialogs.ConfirmPopup` | ported | Authored confirmation layout, OK/cancel callbacks, singleton replacement, and gameplay/lobby callers are covered by popup and quit/artifact/rating tests. |
| `flash/dialogs/CreateGuildPopup.as` | guild action gap | gap | Guild creation and its upload flow remain under the account/profile guild-action TODO. |
| `flash/dialogs/DiscordVerificationPopup.as` | account verification gap | gap | Discord verification upload/response handling is not represented in the Haxe lobby yet. |
| `flash/dialogs/ExternalLinkPopup.as` | `pr2.lobby.dialogs.ExternalLinkPopup`, `pr2.lobby.LobbyPopups` | ported | External links open only after explicit confirmation, replace earlier warnings, and are covered by `ExternalLinkPopupTest`. |
| `flash/dialogs/GetLevelsPopup.as` | level-info list popup gap | gap | The user-level listing popup remains unported; level-listing tabs cover the main list surfaces separately. |
| `flash/dialogs/GuildJoinPopup.as` | guild action gap | gap | Guild join/request upload behavior remains with the unported guild action workflows. |
| `flash/dialogs/GuildMemberName.as` | `pr2.lobby.dialogs.GuildMemberName`, `pr2.lobby.dialogs.GuildPopup` | ported | Guild member rows render the authored symbol and linked names inside `GuildPopup`, covered by `GuildPopupTest`. |
| `flash/dialogs/GuildPopup.as` | `pr2.lobby.dialogs.GuildPopup` | partial | The authored guild profile popup, member rows, link route, and profile request are represented; full guild actions and live error/loading parity remain workflow gaps. |
| `flash/dialogs/HatsMenu.as` | level-editor/account menu gap | gap | The authored hats picker menu is not yet ported as a dialogs class; hats/loadout persistence and editor hats menu remain separate TODOs. |
| `flash/dialogs/HoverPopup.as` | `pr2.lobby.dialogs.HoverPopup` | partial | Authored hover-popup framing and text display exist; specialized hover content such as chat room info and exact delay variants remain listed under their feature gaps. |
| `flash/dialogs/InfoPopup.as` | `pr2.lobby.dialogs.InfoPopup`, `pr2.lobby.level.CourseMenu` | partial | Shared info-popup framing supports current hover/info popups and course-menu placement; generic Flash base behavior is not fully audited. |
| `flash/dialogs/ItemMenu.as` | level-editor/account menu gap | gap | The authored item picker menu remains unported outside the generated symbol assets. |
| `flash/dialogs/LevelInfoPopup.as` | `pr2.lobby.dialogs.LevelInfoPopup`, `pr2.lobby.LobbyPopups` | partial | Level links open the authored singleton popup, covered by `LevelInfoPopupTest`; data population, report, rating, and moderation actions remain TODOs. |
| `flash/dialogs/LevelReportPopup.as` | level-info report gap | gap | Level report form fields and submission remain under the level-info actions TODO. |
| `flash/dialogs/LogoutPassPopup.as` | account logout/password confirmation gap | gap | The authored logout password prompt is not yet represented in the account workflows. |
| `flash/dialogs/MessagePopup.as` | `pr2.lobby.dialogs.MessagePopup` | ported | The shared authored message popup is used by login/lobby/store/gameplay flows for informational and error text. |
| `flash/dialogs/OptionsArtQualityMenu.as` | `pr2.lobby.dialogs.OptionsPopup` | ported | Art-quality and filter toggles are folded into the authored options popup and persisted through `Settings`, covered by `OptionsPopupTest`. |
| `flash/dialogs/OptionsPopup.as` | `pr2.lobby.dialogs.OptionsPopup`, `pr2.lobby.account.Settings` | ported | Music/sound sliders, art/filter toggles, alternate controls, quality, song blacklist, and persistence are covered by `OptionsPopupTest`. |
| `flash/dialogs/OptionsSongsMenu.as` | `pr2.lobby.dialogs.OptionsPopup` | ported | Song blacklist selection is implemented inside the authored options popup and persisted with the rest of options state. |
| `flash/dialogs/OutfitPopup.as` | `pr2.lobby.account.LoadoutsPopup`, account outfit persistence gap | partial | Loadout preview/listing has an authored Haxe popup, but full Flash outfit persistence and all account variants remain TODOs. |
| `flash/dialogs/PMRFCodesPopup.as` | `pr2.lobby.dialogs.PMRFCodesPopup`, `pr2.lobby.dialogs.SendMessagePopup` | ported | The PM rich-formatting codes reference opens from the send-message popup as an authored info popup. |
| `flash/dialogs/PlayerGuestPopup.as` | `pr2.lobby.dialogs.PlayerGuestPopup`, `pr2.lobby.LobbyPopups` | ported | Guest profile links open the authored stripped-down popup, covered by `PlayerPopupTest`. |
| `flash/dialogs/PlayerPopup.as` | `pr2.lobby.dialogs.PlayerPopup`, `pr2.lobby.players.SocialActions` | partial | Member profile data, social labels/actions, message/guild routes, and guest handoff are represented; admin/temp-mod/ban side menus and complete live refresh parity remain TODOs. |
| `flash/dialogs/Popup.as` | `pr2.lobby.dialogs.Popup` | partial | The Haxe popup base owns singleton open tracking, parent attachment, close controls, and fade-out/removal; exact Flash modal stacking and every subclass lifecycle remain audited per popup. |
| `flash/dialogs/SendMessagePopup.as` | `pr2.lobby.dialogs.SendMessagePopup`, `pr2.lobby.tabs.MessagesTab` | partial | Compose, validation, quote prefill, character count, PMRF help, and upload routing are represented; swear/link/date parity and live error states remain PM workflow gaps. |
| `flash/dialogs/SetEmailPopup.as` | account email-change gap | gap | The email-change form and request flow remain under the account workflow TODO. |
| `flash/dialogs/TempModMenu.as` | admin/moderation popup gap | gap | Temporary-moderator controls are not yet ported. |
| `flash/dialogs/TransferGuildPopup.as` | guild action gap | gap | Guild transfer flow and confirmation/upload handling remain unported. |
| `flash/dialogs/UploadingPopup.as` | `pr2.lobby.dialogs.UploadingPopup`, `pr2.net.FormPostClient` | partial | Shared POST popup and JSON response callback handling are used by messages, store, ratings, and artifact placement; exact progress/error presentation is still verified per workflow. |

## Social Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/social/Following.as` | `pr2.lobby.players.Following`, `pr2.lobby.players.PlayersUserListLoader` | ported | The following sub-tab uses the shared user-list loader with the `following` mode. Live response and stale/error-state parity remain under the broader lobby verification TODO. |
| `flash/social/Friends.as` | `pr2.lobby.players.Friends`, `pr2.lobby.players.PlayersUserListLoader` | ported | The friends sub-tab uses the shared user-list loader with the `friends` mode. Friend add/remove actions are mapped by `SocialActionPlan` and popup refresh behavior remains a lobby workflow gap. |
| `flash/social/Guilds.as` | `pr2.lobby.players.Guilds`, `pr2.lobby.players.GuildEntry` | partial | Guest guild listings load `guilds_top.php`, render linked rows, and sort by guild/name/active/GP columns; exact loading/error visuals and live refresh coverage remain with lobby verification. |
| `flash/social/Ignored.as` | `pr2.lobby.players.Ignored`, `pr2.lobby.players.PlayersUserListLoader` | ported | The ignored sub-tab uses the shared user-list loader with the `ignored` mode. Ignore/unignore actions are mapped by `SocialActionPlan`; server refresh parity remains broader lobby work. |
| `flash/social/Online.as` | `pr2.lobby.players.Online`, `pr2.net.CommandHandler`, `pr2.net.LobbySocket` | ported | Online registers `addUser`, emits `get_online_list\``, rejects duplicate names through the shared list, and tears the command down on removal. Room-change refresh coverage remains in lobby verification. |
| `flash/social/PlayersTab.as` | `pr2.lobby.tabs.PlayersTab`, `pr2.ui.TabsHolder` | ported | The nested Players tab strip preserves the Flash member/guest tab split and remembered `playerLists` selection. |
| `flash/social/PlayersTabGuildListItem.as` | `pr2.lobby.players.GuildEntry`, `pr2.lobby.chat.HtmlNameMaker` | ported | Guild rows render linked guild names plus GP-today and active-member columns, with comma formatting for GP. |
| `flash/social/PlayersTabList.as` | `pr2.lobby.players.PlayersTabList`, `pr2.lobby.players.PlayerListSort` | ported | The authored list frame, Name/Rank/Hats headers, duplicate suppression, and default descending-rank sort are represented by `PlayersTabList` and pure sort coverage. |
| `flash/social/PlayersTabListHolder.as` | `pr2.lobby.players.PlayersListHolder`, `pr2.ui.CustomScrollBar` | ported | The holder owns row stacking, loading spinner visibility, scrollbar setup, clearing, and relayout after sort. |
| `flash/social/PlayersTabListItem.as` | `pr2.lobby.players.PlayerListItem` | ported | The row base wraps `PlayersTabListItemGraphic`, recovers the three text fields positionally, and centralizes linked-name listener cleanup. |
| `flash/social/PlayersTabListItemInfo.as` | `pr2.lobby.players.PlayerEntry`, `pr2.lobby.chat.HtmlNameMaker` | ported | Player rows render linked name/group, rank, hats, and optional server-name display labels. |
| `flash/social/PlayersTabUserListDataLoader.as` | `pr2.lobby.players.PlayersUserListLoader`, `pr2.net.TextLoader` | partial | The shared friends/following/ignored loader requests `user_list_get.php?mode=...`, parses JSON rows, and leaves malformed/error responses empty; exact Flash error-state visuals remain under lobby verification. |

## Effect Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/effects/ArrowEffect.as` | character visual-effect hook boundary | gap | The floating arrow particle used by sparkle emitters is not yet rendered; character sparkle start/end is exposed as a network/state hook only. |
| `flash/effects/BlockPiece.as` | `pr2.effects.BlockPiece`, `pr2.level.ServerLevelRenderer`, `pr2.harness.FixtureLevelRenderer` | ported | Randomized block fragments for brick, crumble, and mine break visuals are covered by `ServerLevelRendererTest`. |
| `flash/effects/Effect.as` | effect ownership/removal boundaries in `pr2.effects.*`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | Current concrete effects own their frame listeners and display removal directly; the shared `EffectBackground` base/addChild abstraction is not yet ported as a standalone class. |
| `flash/effects/Egg.as` | `pr2.gameplay.EggRound`, `pr2.gameplay.Course` command boundary | partial | Seeded egg round bookkeeping, ids, remove commands, and local `grab_egg` emission are covered by `CharacterLifecycleTest`; egg `PhysicsEffect` movement, attacks, squash, and authored visuals remain under gameplay behavior. |
| `flash/effects/Hat.as` | `pr2.gameplay.GameCommandShell` hook boundary, `pr2.character.Character` hat stack | gap | Loose hat physics, pickup/return commands, `removeHat{id}` registration, and authored falling hat visuals are still deferred; character-owned hats are covered separately. |
| `flash/effects/IceWaveShot.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Local item use/reload/direction emission is covered by `LocalPlayerControllerTest`; projectile branching, block freezing visuals, and remote/local hit side effects are not yet rendered as live `ShotEffect`s. |
| `flash/effects/LaserShot.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Local laser use, recoil, reload, and direction payload parity are covered by `LocalPlayerControllerTest`; projectile travel, hit animation, and laser sounds remain unported live effects. |
| `flash/effects/MineAppear.as` | `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | partial | Mine placement tile/effect payload and final mine block collision are covered by `LocalPlayerControllerTest`; the delayed authored appear animation and sound are not yet a concrete renderer effect. |
| `flash/effects/MineExplode.as` | `pr2.effects.MineExplosion`, `pr2.level.ServerLevelRenderer`, `pr2.harness.FixtureLevelRenderer` | ported | Authored explosion animation, lifetime, sound hook, and renderer teardown are covered by `ServerLevelRendererTest`. |
| `flash/effects/PhysicsEffect.as` | effect hook boundary | gap | Shared gravity/collision physics for loose hats and eggs is not yet ported as a reusable class; the affected concrete effects remain explicit gaps. |
| `flash/effects/ShotEffect.as` | item projectile hook boundary | gap | Shared projectile movement, block/player hit testing, life expiry, and rotation math for laser/ice shots are not yet represented as live effect objects. |
| `flash/effects/Slash.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Sword item use/reload/direction and lunge parity are covered by `LocalPlayerControllerTest`; authored slash hit sweep, sound, and remote/local hit side effects remain unported live effects. |
| `flash/effects/StarEffect.as` | visual-effect hook boundary | gap | Static 15-frame star effect is not yet used by the Haxe runtime. |
| `flash/effects/Sting.as` | `pr2.character.RemoteCharacter`, `pr2.character.Character` hook boundary | gap | Heart/sting commands are consumed and exposed as hooks, but the fading authored sting display and sound are not rendered. |
| `flash/effects/TeleportPop.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Teleport start/end effect coordinates and blocked-destination suppression are covered by `LocalPlayerControllerTest`; authored pop animation and sound are not yet rendered. |
| `flash/effects/Zap.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Lightning `zap\`` command emission and item consumption are covered by `LocalPlayerControllerTest`; the owner-following bolt/flash display and sound remain unported live effects. |

## Sound Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/sounds/NoodleTown.as` | `pr2.audio.MenuMusic`, `pr2.audio.AudioManager` | ported | The two-layer Noodle Town menu loop, randomized crossfade, frame-rate volume fade, and login/lobby handoff are represented by `MenuMusic`/`AudioManager`; teardown stops channels and timers. |
| `flash/sounds/SoundEffects.as` | `pr2.audio.SoundEffects`, `pr2.audio.TimelineSound` | ported | Overlapping one-shot playback, 700 px game-sound attenuation/panning, sound-level scaling, loop forwarding, and timeline-owned sound disposal are covered by `AudioRuntimeTest`. |

## Menu Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/menu/CheckServers.as` | `pr2.net.ServerStatusClient`, `pr2.page.LoginPage` | ported | Server-status loading, filtering, Flash ordering, preferred open server choice, refresh interval, and manual reload cooldown are represented by the login page and covered by `LobbyServicesTest`. |
| `flash/menu/CommAuth.as` | platform crypto boundary | gap | Flash's communication-token `SecureStore` helper is not represented as a standalone Haxe class; the currently ported login/API flows do not consume this token path. |
| `flash/menu/ConnectingPopup.as` | `pr2.page.LoginPage`, `pr2.page.LoginSocketProbe`, `pr2.net.LoginSessionGate` | ported | Socket replacement, `setLoginID` handoff, cancel/error teardown, and transition into the login handshake are represented by the login-page popup flow and covered by login/session tests. |
| `flash/menu/CreateAccountPopup.as` | `pr2.page.LoginPage`, `pr2.net.AccountCreationClient` | ported | Password confirmation, `register_user.php` POST, success handoff to server selection, and uploading/message popup behavior are represented in the authored login popup flow. |
| `flash/menu/CreditsPopup.as` | `pr2.lobby.dialogs.CreditsPopup`, `pr2.page.LoginPage` | ported | The authored credits popup, version/build text, three art pages, two music pages, nav links, and close behavior are covered by popup tests. |
| `flash/menu/ForgotPassPopup.as` | `pr2.page.LoginPage`, `pr2.net.ForgotPasswordClient` | ported | Name prefill, Enter submission, `forgot_password.php` form fields, uploading state, and success/error message handling are represented by the login-page popup flow. |
| `flash/menu/IntroPage.as` | `pr2.page.IntroPage` | ported | Site-mode intro sequencing, click-to-skip, generated timeline playback, final-frame completion, and login transition are covered by intro harness state and deterministic tests. |
| `flash/menu/KongOutfitPopup.as` | login Kong reward gap | gap | The Kong sponsor outfit acceptance flow and next-login award flag are not yet ported; the login page only exposes the Kong hit region boundary. |
| `flash/menu/LoggingInPopup.as` | `pr2.page.LoginPage`, `pr2.net.LoginAuthClient`, `pr2.net.LoginSessionGate`, `pr2.net.SavedAccounts` | ported | The HTTP/socket two-phase login handshake, `loginSuccessful`/failure handling, session fields, remembered token persistence, invalid token deletion, and lobby transition are covered by login and race-session tests. |
| `flash/menu/LoginPage.as` | `pr2.page.LoginPage`, `pr2.audio.AudioManager` | ported | Authored login menu art, button routes, server refresh lifecycle, instructions link, Noodle Town entry, and cleanup are represented by `LoginPage`; site-logo variants other than Kong remain visual-only gaps. |
| `flash/menu/LoginPopup.as` | `pr2.page.LoginPage`, `pr2.net.ServerStatusClient` | ported | Credential fields, remember checkbox, server dropdown, Enter-to-submit, forgot-password route, reload cooldown, and cancel behavior are represented in the login-page popup flow. |
| `flash/menu/ServerSelectPopup.as` | `pr2.page.LoginPage`, `pr2.net.SavedAccounts`, `pr2.net.ServerStatusClient` | ported | Guest/account server selection, saved-account dropdown, delete confirmation/logout request, reload cooldown, cancel state reset, and connection start are represented by the login-page popup flow. |

## Gameplay Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/gameplay/CatCaptcha.as` | gameplay captcha gap | gap | The authored cat-captcha popup, image choice flow, and `/cat/captcha-submit.php` request are not yet ported. This remains under server-authoritative race interactions. |
| `flash/gameplay/CatImage.as` | gameplay captcha gap | gap | Per-image loading from `/cat/cat-img.php`, 200 px fit behavior, and click identity are only represented by generated assets today. |
| `flash/gameplay/Course.as` | `pr2.gameplay.Course` | partial | The real race shell mounts decoded levels, HUD widgets, local/remote characters, minimap, spectate picker, drawing readiness, countdown, egg bookkeeping, and camera follow. Remaining gaps are timer parity, loose hats, full effect backgrounds, and remaining server-authoritative race mode side effects. |
| `flash/gameplay/CourseTimer.as` | `pr2.gameplay.Course` timer boundary | gap | Race/countdown timer display, low-time pulse/sound, pause/resume, and socket-time anchoring are not yet a standalone Haxe component. |
| `flash/gameplay/DrawingInfo.as` | `pr2.gameplay.DrawingInfo` | ported | Four player rows, drawing spinners, `finishDrawing`, and mounted course position are covered by `DrawingInfoTest` and `GameShellMountTest`. Finish-times/Kong stat side effects remain with the finish lifecycle. |
| `flash/gameplay/ExpGain.as` | `pr2.gameplay.ExpGain`, `pr2.gameplay.FinishedPage` | ported | The 45-frame exp bar clamp/step and total display are covered by `FinishedPageTest`. Kong stat submission is an external platform hook boundary. |
| `flash/gameplay/FinishedPage.as` | `pr2.gameplay.FinishedPage`, `pr2.page.GamePage` | ported | Authored popup layout, rating control placement, award lines, exp gain, close/return behavior, and lobby return hook are covered by `FinishedPageTest` and `QuitButtonTest`. |
| `flash/gameplay/Game.as` | `pr2.page.GamePage`, `pr2.gameplay.GameCommandShell`, `pr2.gameplay.Course` | partial | Command registration/parsing, character lifecycle, countdown, prize commands, cowboy mode, artifact placement, hat countdown, quit/finish return, and shell mounting are covered by gameplay tests. Remaining gaps include Lux/happy-hour side effects, timer completion, loose hats, and captcha/server-authoritative race-mode interactions. |
| `flash/gameplay/Hearts.as` | `pr2.gameplay.Hearts` | ported | Deathmatch heart icon stack and 0..15 clamp are covered by `HeartsTest`. |
| `flash/gameplay/ItemDisplay.as` | `pr2.gameplay.ItemDisplay`, `pr2.gameplay.Course` | ported | Authored item display, item code mapping, ammo/use pips, and course sync are covered by `ItemDisplayTest` and `GameShellMountTest`. |
| `flash/gameplay/LuxPopup.as` | live game command hook boundary | gap | `setLuxGain` is parsed by `GameCommandShell`, but the authored `LuxPopupGraphic` animation and account lux display side effects are not yet ported. |
| `flash/gameplay/MiniMap.as` | `pr2.gameplay.MiniMap`, `pr2.gameplay.MiniMapDot` | ported | Block rasterization, dot creation, temp-id assignment, and remote/local dot updates are covered by `MiniMapTest`, `RemoteCharacterConsumeTest`, and `CharacterLifecycleTest`. |
| `flash/gameplay/Modes.as` | `pr2.gameplay.LevelConfig`, `pr2.level.ServerLevelData`, `pr2.gameplay.EggRound` | partial | Decoded mode ids drive course setup and egg rounds, but a named Haxe mode catalog and all mode-specific server side effects are not complete. |
| `flash/gameplay/MusicSelection.as` | `pr2.gameplay.MusicSelection`, `pr2.audio.GameMusic` | ported | Authored music selector, song list, saved song blacklist, random/editor behavior, and game music handoff are covered by `MusicSelectionTest` and audio tests. |
| `flash/gameplay/PlaceArtifact.as` | `pr2.gameplay.PlaceArtifact`, `pr2.gameplay.SpecialEvent` | ported | Privileged click dispatch, date/time validation, place-now behavior, scheduled override, confirmation, and `place_artifact.php` upload response flow are covered by `SpecialEventTest` and `PlaceArtifactTest`. |
| `flash/gameplay/PrizePopup.as` | `pr2.gameplay.PrizePopup`, `pr2.page.GamePage` | ported | Prize/cancel/exp/body text, part target selection, epic decoration, live prize command hooks, and popup replacement are covered by `PrizePopupTest` and `QuitButtonTest`. |
| `flash/gameplay/QuitButton.as` | `pr2.gameplay.QuitButton`, `pr2.page.GamePage` | ported | Authored quit button, confirmation boundary, glow control, force-quit route, and page teardown are covered by `QuitButtonTest`. |
| `flash/gameplay/RaceChat.as` | `pr2.gameplay.RaceChat` | ported | Authored race chat input/display, Enter focus/send behavior, slash-level hook, HTML name/link display, and course mounting are covered by `RaceChatTest`. |
| `flash/gameplay/SpecialEvent.as` | `pr2.gameplay.SpecialEvent`, `pr2.page.GamePage` | ported | Privileged G+C artifact placement and C+X prize cancellation dispatch are covered by `SpecialEventTest`. |
| `flash/gameplay/SpectatePicker.as` | `pr2.gameplay.SpectatePicker`, `pr2.gameplay.Course` | ported | Authored picker UI, player cycling, free-scroll state, visibility gating, name rendering, and course change hook are covered by `SpectatePickerTest`. |
| `flash/gameplay/StatsDisplay.as` | `pr2.gameplay.StatsDisplay`, `pr2.gameplay.Course` | ported | Authored stat boxes, hover popup delay/removal, and course stat sync are covered by `StatsDisplayTest` and `GameShellMountTest`. |
| `flash/gameplay/TestCourse.as` | `pr2.page.CampaignTestScreen`, level-editor test-course gap | partial | The debug campaign/gameplay harness can run decoded levels through `Course`; the authored level-editor test-course controls, stat picker, hat picker, editor return, and report-management variants remain with the level-editor TODO. |

## Level Browser Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/level_browser/Best.as` | `pr2.lobby.level.LevelListingPage`, lobby tab factory | partial | Best is represented by the shared listing page mode and the lobby tab route; real response coverage and exact stale/error states remain with the lobby verification TODO. |
| `flash/level_browser/BestWeek.as` | `pr2.lobby.level.LevelListingPage`, lobby tab factory | partial | Weekly-best mode uses the shared listing request/render path; server paging and out-of-order response parity remain with the lobby verification TODO. |
| `flash/level_browser/Campaign.as` | `pr2.lobby.level.LevelListingPage`, `pr2.net.CampaignListClient` | partial | Campaign list loading and validation are represented by the listing page and campaign client; full live listing state coverage remains under lobby verification. |
| `flash/level_browser/CourseMenu.as` | `pr2.lobby.level.CourseMenu`, `pr2.lobby.level.LevelLaunch` | ported | Authored play/cancel popup, force-time countdown math, close command, auto-dismiss boundary, and confirm/clear routing are covered by `LobbyServicesTest`. |
| `flash/level_browser/Favorites.as` | `pr2.lobby.level.LevelListingPage`, `pr2.lobby.level.LevelItem` | partial | Favorites uses the shared listing grid and item favorite add/remove controls; real HTTP refresh/error behavior remains with the lobby verification TODO. |
| `flash/level_browser/LevelItem.as` | `pr2.lobby.level.LevelItem`, `pr2.lobby.level.LevelAccess`, `pr2.lobby.level.LevelLaunch` | partial | Authored tile rendering, access cover, favorite controls, slots, level popup route, and launch handoff are ported; encrypted password payload parity and full live response refresh remain explicit gaps. |
| `flash/level_browser/LevelListing.as` | `pr2.lobby.level.LevelListingPage`, `pr2.lobby.level.LevelGridLayout`, `pr2.ui.PageNavigation` | partial | Shared holder, loading spinner, page navigation, three-column layout, room command, page highlights, and access retest command are represented; full loading/error/empty state parity remains with lobby verification. |
| `flash/level_browser/ListingEntry.as` | `pr2.lobby.level.LevelItem`, `pr2.net.CampaignLevelInfo` | partial | Listing entry data is parsed into `CampaignLevelInfo` and rendered by `LevelItem`; exact per-mode server field edge cases remain with real response verification. |
| `flash/level_browser/ListingPage.as` | `pr2.lobby.level.LevelListingPage`, `pr2.lobby.level.LevelListingState` | partial | Page-number memory and page-change reload behavior are represented by the shared listing page/state; complete server-driven page restoration remains with lobby verification. |
| `flash/level_browser/Newest.as` | `pr2.lobby.level.LevelListingPage`, lobby tab factory | partial | Newest mode shares the standard listing request/render path; response ordering and stale update handling remain with lobby verification. |
| `flash/level_browser/PaginatedPage.as` | `pr2.ui.PageNavigation`, `pr2.lobby.level.LevelListingPage` | ported | Page number positioning and current-page handoff are covered by `LobbyServicesTest`; visual baselines remain part of the broader screenshot-threshold TODO. |
| `flash/level_browser/Search.as` | `pr2.lobby.search.SearchQuery`, `pr2.lobby.level.LevelListingPage` | partial | Search query normalization/decision logic and the shared listing shell are covered by `LobbyServicesTest`; populated/error response rendering remains with lobby verification. |
| `flash/level_browser/Slot.as` | `pr2.lobby.level.Slot`, `pr2.lobby.level.LevelItem`, `pr2.lobby.level.CourseMenu` | ported | Slot state frames, fill/confirm/clear command routing, pending click, local course-menu creation, and teardown are represented by the Haxe slot/item/menu path and covered through `LobbyServicesTest`. |

## Page Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/page/ArtifactHint.as` | chat artifact-hint gap | gap | The `/files/level_of_the_week.json` fetch and Fred system-chat injection for `/hint`/`/lotw`/`/arti` are not yet ported; RaceChat and lobby chat commands do not synthesize this hint. |
| `flash/page/Chat.as` | `pr2.lobby.tabs.ChatTab`, `pr2.gameplay.RaceChat`, `pr2.lobby.chat.HtmlNameMaker` | partial | Lobby chat and race chat cover command registration, display, send routing, and linked-name rendering in their respective contexts. Shared Flash slash-command routes, artifact hints, and exact swear-filter/link parsing remain with chat/lobby verification gaps. |
| `flash/page/GamePage.as` | `pr2.page.GamePage`, `pr2.gameplay.LevelEntry`, `pr2.gameplay.LevelConfig`, `pr2.level.ServerLevelDecoder`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | In-session game entry, level fetch failure wording, metadata parsing, m1-m4 decode, incremental drawing readiness, course mounting, command buffering, finish/quit return, and special-event hooks are covered by level/gameplay tests. Free-scroll/zoom editor-style camera behavior and remaining race side effects stay under gameplay/editor TODOs. |
| `flash/page/Page.as` | `pr2.page.Page` | ported | Page initialization/removal lifecycle and parent removal are represented by the Haxe base page. |
| `flash/page/PageHolder.as` | `pr2.page.PageHolder`, `pr2.lobby.level.LevelLaunch` | ported | Page replacement removes the old page before initializing/adding the new one, and root-only `startGame` launch ownership is covered by lobby and race transcript tests. |

## Player Profile Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/player_profile/AccountInfo.as` | `pr2.lobby.tabs.AccountTab`, `pr2.lobby.account.AccountCustomizeData`, `pr2.lobby.account.AccountCharacter` | partial | The authored account tab requests/parses `setCustomizeInfo`, previews the character, edits stats/parts, emits `set_customize_info`, handles rank-token commands, and opens loadouts. Guild-name popup behavior, outfit confirmation parity, and full account workflow coverage remain open account/lobby tasks. |
| `flash/player_profile/LoadoutsPopup.as` | `pr2.lobby.account.LoadoutsPopup`, `pr2.lobby.account.Presets` | partial | The ten-slot loadout popup applies and saves presets against the live account character, stats, and selectors. Exact Flash inheritance from `GetLevelsPopup` and complete persistence/user-state variants remain covered by the loadout/account workflow TODO. |
| `flash/player_profile/PartInfo/PartInfoListing.as` | part-information popup gap | gap | The owned-part listing row, epic decoration, Djinn obtain text, and click-through part popup are not ported; account part info currently opens only a lightweight hover boundary. |
| `flash/player_profile/PartInfo/PartInfoPopup.as` | part-information popup gap | gap | The full scrollable part catalog, per-part entries, close behavior, and external obtain links remain under the part-information TODO. |
| `flash/player_profile/PartInfo/PartPopup.as` | part-information popup gap | gap | The detailed part popup, equip dispatch, obtain text, epic flash decoration, and linked player names are not yet represented in Haxe. |
| `flash/player_profile/PartSelector.as` | `pr2.lobby.account.PartSelector`, `pr2.ui.ArrowButtons`, `pr2.lobby.account.ColorPicker` | partial | Part stepping, primary/epic color pickers, randomization, epic-color visibility, and change dispatch are represented. The exact Flash color-picker art and triangle/diagonal mask visuals remain visual fidelity work. |
| `flash/player_profile/PlayerDisplay.as` | `pr2.lobby.account.PlayerDisplay`, `pr2.lobby.account.AccountCharacter` | partial | The hat/head/body/feet selectors, randomize button, preview update, current-hat tracking, and level-access retest dispatch are ported. The full part-info popup route is still a gap. |
| `flash/player_profile/Preset.as` | `pr2.lobby.account.Preset` | ported | Preset slot number, stats, part ids, primary/epic colors, stored-data shape, and outfit-format projection are represented by the Haxe preset model. |
| `flash/player_profile/PresetListing.as` | `pr2.lobby.account.LoadoutsPopup` internal listing | partial | Haxe renders selectable loadout rows inside `LoadoutsPopup`; the standalone `SelectableButton` subclass and exact row art/hover states are still part of account visual fidelity. |
| `flash/player_profile/Presets.as` | `pr2.lobby.account.Presets`, `pr2.lobby.account.Settings` | ported | Ten saved presets load from settings, apply to character/stats/selectors, and save current style back to persistent settings. |
| `flash/player_profile/RandomizeStyleButton.as` | `pr2.lobby.account.PlayerDisplay` randomize button | partial | The random-style action is wired through `PlayerDisplay` using the authored button symbol; the standalone hover-delay popup wrapper text is not represented. |

## UI Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/ui/ArrowButtons.as` | `pr2.ui.ArrowButtons` | ported | Left/right value stepping, wraparound, `Event.CHANGE`, and authored button binding are represented by the shared UI control. |
| `flash/ui/CustomCursor.as` | level-editor cursor gap | gap | The editor cursor singleton, hidden-mouse lifecycle, touch forwarding, and temporary delete-tool shortcut are unported with the level-editor tool/camera work. |
| `flash/ui/CustomScrollBar.as` | `pr2.ui.CustomScrollBar` | ported | Thumb-to-target mapping, arrow continuous scroll, stage drag listeners, and teardown are represented by the shared scrollbar and covered by lobby UI tests. |
| `flash/ui/EmblemLoader.as` | guild-emblem upload gap | gap | The local image browse/scale/JPEG upload flow is not ported; guild emblem management remains under guild/account workflow completion. |
| `flash/ui/GameSound.as` | `pr2.gameplay.MusicSelection`, `pr2.audio.GameMusic`, `pr2.audio.MusicCatalog` | ported | Song catalog, blacklist filtering, random/editor choices, artifact track handling, looping playback, and music handoff are represented by gameplay music selection and audio tests. |
| `flash/ui/GuildName.as` | `pr2.lobby.dialogs.PlayerPopup` boundary, guild popup gap | partial | Player popups reserve the guild-name/emblem boundary, but the clickable `GuildNameGraphic` wrapper and guild popup launch remain part of guild workflow completion. |
| `flash/ui/LobbyTab.as` | `pr2.ui.LobbyTab` | ported | Authored tab art, text sizing, hover/selected frames, click activation, and cleanup are represented with `TabsHolder` and covered by lobby tests. |
| `flash/ui/LoginPageMenuButton.as` | `pr2.page.LoginPageMenuButton` | ported | Login menu button labels, hover text decoration, alpha changes, hit area, click dispatch, and cleanup are represented by the login page button. |
| `flash/ui/MuteButton.as` | `pr2.ui.MuteButton`, `pr2.audio.AudioManager` | ported | Global mute toggles `SoundMixer`, shows/hides wave art, applies hover color, and is owned at the app root as in Flash. |
| `flash/ui/PageNavigation.as` | `pr2.ui.PageNavigation` | ported | Full/vertical/arrow-only layouts, link dispatch, page highlighting, and Flash's compression math are represented and covered by `LobbyServicesTest`. |
| `flash/ui/ProgressBar.as` | `pr2.lobby.dialogs.ProgressBar` | ported | Authored progress bar art, drop shadow, clamped target progress, per-frame interpolation, and disposal are represented by dialog upload flows. |
| `flash/ui/RatingSelect.as` | `pr2.ui.RatingSelect` | ported | Finished-race star hover math, confirm popup, and `submit_rating.php` upload route are represented by the authored rating control. |
| `flash/ui/SelectableButton.as` | selectable-button gap | gap | The generic up/over/selected wrapper is not yet a standalone Haxe control; current screens use direct authored button bindings where needed. |
| `flash/ui/StatSlider.as` | `pr2.lobby.account.StatSlider` | partial | Numeric entry, slider sync, button stepping, point-budget clamp, and display updates are ported; Flash's press-and-hold acceleration and level-editor save hook are intentionally still gaps. |
| `flash/ui/StatsSelect.as` | `pr2.lobby.account.StatsSelect` | partial | Account stat allocation, remaining-points display, info string, and stat extraction are ported; the level-editor live-character/stat persistence hook remains with editor test-course work. |
| `flash/ui/TabsHolder.as` | `pr2.ui.TabsHolder`, `pr2.ui.TabLayout` | ported | Tab ownership, remembered selected tab, overlap layout, selected-front ordering, and removal persistence are represented by the shared tab holder. |
