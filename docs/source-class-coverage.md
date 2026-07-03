# Source Class Coverage

This inventory tracks first-party AS3 classes against their Haxe/OpenFL port,
platform adapter, or remaining gap. Keep entries narrow: an exported symbol
alone is not a class port.

## Background Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/background/Background.as` | `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | The active view-window culling, camera offset, holder layering, async art failure boundary, and Flash warning gate are represented by `ServerLevelRenderer` and `Course`; the exact shared Flash base class is not a standalone Haxe type. |
| `flash/background/BlockBackground.as` | `pr2.level.ServerLevelRenderer`, `pr2.level.ServerLevelFixtureAdapter` | partial | Block display creation, segment-grid attachment, and fixture conversion are covered by renderer/fixture tests; editor-specific mutation paths remain with the level-editor TODO. |
| `flash/background/BlockGridLines.as` | `pr2.page.BlockGridLines`, `pr2.page.LevelEditor` | ported | The level editor mounts the authored 30-pixel grid behind block tiles, redraws it for zoom changes, and snaps it by camera offset modulo segment size; covered by `EditorSettingsTest`. |
| `flash/background/DrawableBackground.as` | `pr2.level.ServerLevelRenderer`, `pr2.level.ServerLevelDecoder` | ported | Decoded draw strokes, text, and stamp objects render incrementally across the five art planes, with raster-tile sizing, raster-stop notification, draw-failure completion, and drawing-readiness coverage in `ServerLevelRendererTest` and `GameShellMountTest`. |
| `flash/background/EffectBackground.as` | `pr2.gameplay.EffectBackground`, `pr2.level.ServerLevelRenderer`, `pr2.effects.*`, `pr2.gameplay.Course` | partial | The server `addEffect` command now routes Laser, Slash, Mine, Hat, IceWave, and Teleport payloads through the ported visuals/sounds/lifecycle; lower-level shot collision and damage behavior remains tracked by the concrete effect and block-damage TODOs. |
| `flash/background/LevelBackground.as` | `pr2.level.ServerLevelRenderer`, `pr2.level.ServerLevelDecoder` | ported | Gameplay honors `Settings.DRAW_ART` for art backgrounds/draw layers, decodes legacy `BGn` background strings, and recreates BG5's colored circle grid; covered by `ServerLevelRendererTest` and `ServerLevelDecoderTest`. |
| `flash/background/Map.as` | `pr2.level.ServerLevelFixtureAdapter`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | Server maps decode into fixture/render layers, preserve start-block and minion-egg spawn-marker behavior, spawn capped minion eggs at gameplay start, register server `activate` packets for remote-visible block effects, emit local `activate` packets for local block activations, and drive the live course shell. Editor map editing remains with editor/gameplay gaps. |
| `flash/background/ObjectBackground.as` | `pr2.level.ServerLevelDecoder`, `pr2.level.ServerLevelRenderer` | partial | Server stamp/object decoding and display are represented in the renderer; editor placement, selection, and deletion remain with the level-editor TODO. |

## Item Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/items/IceWave.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Three-use item, 1000ms reload, direction payload, and left-facing parity are covered by `LocalPlayerControllerTest`. Live network effect emission is represented by the local item-effect payload. |
| `flash/items/Item.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | Availability-on-key-release, use counts, reload timing, and item clearing are covered by `LocalPlayerControllerTest`. `SecureData` is intentionally replaced by controller state. |
| `flash/items/Items.as` | `pr2.gameplay.Items`, `pr2.harness.LocalPlayerController` | ported | The item-code catalog and level allowed-item pool are represented by `Items`; empty-options and randomized item-block selection are covered by `LocalPlayerControllerTest`. |
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
| `flash/blocks/Block.as` | `pr2.level.FixtureLevel.LevelBlock`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | ported | Tile position/options, active/removed state, collision participation, Santa freeze/thaw overlay state, Flash block-bounce return/stop quirks, item/effect `onDamage` side-hit dispatch, recursive push-block movement, local `activate` command emission, and block visuals are split across fixture blocks, controller block state, course networking, and renderer block instances. |
| `flash/blocks/Blocks.as` | `pr2.level.ObjectCodes`, `pr2.level.BlockType`, `pr2.level.ServerLevelRenderer` | ported | Object-code lookup, type conversion, and 30 px block assets are covered by renderer tests. |
| `flash/blocks/BrickBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | One-hit break-on-bump and item-damage behavior, local activation emission, piece spawning, and removal from collision are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/CrumbleBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Ten-frame crumble timing, force-payload local activation emission, item-damage chip behavior, cheese-hat force/adjacent-break behavior, and removal are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/CustomStatsBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Stat-option application, reset semantics, one-use grey depletion visuals, and TestCourse StatsSelect sync requests are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/FinishBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Finish is a one-use supply block; bump-only completion id/center reporting and grey depletion visuals are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/HappyBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Supply stat increase, option clamp behavior, grey depletion visuals, and TestCourse StatsSelect sync requests are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/HeartBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` | ported | One-use life supply behavior, local `gainHeart()` callback routing, `heart\`` socket emission, and grey depletion visuals are covered by `LocalPlayerControllerTest` and `LocalCharacterEmitTest`. |
| `flash/blocks/IceBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Ice movement friction and Santa-created temporary ice overlays are covered by `LocalPlayerControllerTest` and `ServerLevelRendererTest`. |
| `flash/blocks/InfItemBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Items` | ported | Infinite item supply behavior and level allowed-item pool/random candidate selection are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/ItemBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Items` | ported | One-use item supply, grey transform state, `none`/empty options, allowed-item pool selection, and independent randomized candidate selection are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/MineBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Launch/removal behavior, frozen-hit suppression, item-damage explosion/removal behavior, local activation emission, and explosion/block-piece visuals are covered by `LocalPlayerControllerTest` and `ServerLevelRendererTest`. |
| `flash/blocks/MoveBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Preview/reselect timing, movement, recursive destination push-block movement, blocked shifts, and player-occupied blocking are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/PushBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Push-block movement, frozen movement suppression, recursive destination push-block movement, and direction-payload local activation behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/RotateBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.RotationMath` | ported | Shared rotation tween, frozen activation suppression, coordinate rotation, and character counter-rotation are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/RotateLeftBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Left rotation direction and completion behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/RotateRightBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Right rotation direction and completion behavior are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/SadBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Supply stat decrease, option clamp behavior, grey depletion visuals, and TestCourse StatsSelect sync requests are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/SafetyBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Safe-coordinate update without solid collision and frozen return suppression are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/StartBlock.as` | `pr2.level.BlockType`, `pr2.level.ServerLevelFixtureAdapter` | ported | Spawn discovery and non-colliding start-block behavior are covered by `ServerLevelFixtureAdapterTest` and `LocalPlayerControllerTest`. |
| `flash/blocks/SupplyBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController` | ported | Shared one-use bump-only depletion behavior, frozen supply-use suppression, and grey transform visuals for finish/item/custom-stat/stat/life/time supplies are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/TeleportBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | ported | Same-color teleport pairing, crouched bump y-restoration, option/default color rendering, cooldown tint/depletion, disabled reset timing, and start/destination `TeleportPop` visual/socket effects are covered by `LocalPlayerControllerTest`, `ServerLevelRendererTest`, and `CharacterLifecycleTest`. |
| `flash/blocks/TimeBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Course`, `pr2.gameplay.RaceSounds` | ported | One-use race-time supply behavior, grey depletion visuals, and full-volume `TickTockSound` playback are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/VanishBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Contact and item-damage fade activation, fall-through, reappear, and remote-visible activation are covered by `LocalPlayerControllerTest`, `RemoteCharacterConsumeTest`, and `ServerLevelRendererTest`. |
| `flash/blocks/WaterBlock.as` | `pr2.level.BlockType`, `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Swimming mode and remote ripple effects are covered by `LocalPlayerControllerTest` and `RemoteCharacterConsumeTest`. |
| `flash/blocks/options/BlockOptions.as` | `pr2.level.FixtureLevel.LevelBlock`, `pr2.gameplay.LevelConfig` | ported | Raw option strings are preserved on decoded blocks and parsed at each behavior boundary. |
| `flash/blocks/options/CustomStatsBlockOptions.as` | `pr2.harness.LocalPlayerController` | ported | Custom stats options and reset token are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/options/ItemBlockOptions.as` | `pr2.gameplay.Items`, `pr2.harness.LocalPlayerController` | ported | Item option parsing and empty-options allowed-pool selection are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/options/StatBlockOptions.as` | `pr2.harness.LocalPlayerController` | ported | Happy/sad stat option clamps are covered by `LocalPlayerControllerTest`. |
| `flash/blocks/options/TeleportBlockOptions.as` | `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | ported | Teleport color matching, rendering, and default color behavior are covered by `LocalPlayerControllerTest` and `ServerLevelRendererTest`. |

## Character Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/character/ArrowSparkleEmitter.as` | `pr2.character.ArrowSparkleEmitter`, `pr2.effects.ArrowEffect`, `pr2.gameplay.Course` | ported | Arrow sparkle emitters now create randomized-color `ArrowEffect` particles at Flash's 33ms interval and are mounted/cleared through Course character hooks; covered by `ParticleEmitterTest` and `CharacterLifecycleTest`. |
| `flash/character/Character.as` | `pr2.character.Character`, `pr2.character.CharacterDisplay` | ported | Appearance ids/colors, four-slot hat stack and special-hat flags, animation state changes, geometry helpers, block-touch probes, April 1 reversed-control initialization, recovery flash, and fade-out removal are covered by `CharacterBaseTest` and `LocalCharacterTest`. Particle, jet, Djinn, weapon-display, and sound side effects are explicit hook boundaries. |
| `flash/character/DjinnEffects.as` | `pr2.character.Character` hook boundary | gap | Djinn body/feet particle emission remains deferred; the character core records it as an unported visual side effect rather than silently substituting a generic effect. |
| `flash/character/LocalCharacter.as` | `pr2.character.LocalCharacter`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Course` | ported | Local multiplayer character construction, controller-backed physics, stats/gravity/item state mirroring, artifact and April 1 control reversal, local zap/sting/squash command handlers, local heart-gain life/HUD/socket protocol, network position/var emission, and race event payloads are covered by `LocalCharacterTest`, `LocalPlayerControllerTest`, `LocalCharacterEmitTest`, and `CharacterLifecycleTest`. |
| `flash/character/ParticleEmitter.as` | `pr2.character.ParticleEmitter`, `pr2.character.ArrowSparkleEmitter`, `pr2.character.RainbowStarEmitter` | ported | Flash-style interval spawning, randomized character-relative positions, life countdown, default `StarEffect` particles, arrow sparkles, rainbow stars, and cleanup are covered by `ParticleEmitterTest` and `CharacterLifecycleTest`. |
| `flash/character/PhysicsParticle.as` | `pr2.character.PhysicsParticle` | ported | Djinn particle color choice, randomized position/velocity/scale/alpha, friction/acceleration hooks, per-frame alpha/life fade, scale/rotation updates, graphic mounting, and cleanup are covered by `ParticleEmitterTest`. |
| `flash/character/PositionedParticleEmitter.as` | `pr2.character.PositionedParticleEmitter`, `pr2.gameplay.Course` | ported | Parent-space target-point conversion, offset ranges, holder mounting, and Course Djinn body/feet emitter routing are covered by `ParticleEmitterTest` and `CharacterLifecycleTest`. |
| `flash/character/RainbowStarEmitter.as` | `pr2.character.RainbowStarEmitter`, `pr2.effects.StarEffect`, `pr2.gameplay.Course` | ported | Rainbow-star emitters create randomized-rotation/color `StarEffect` particles for recovery/heart sparkles and are mounted/cleared through Course character hooks; covered by `ParticleEmitterTest` and `CharacterLifecycleTest`. |
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
| `flash/effects/ArrowEffect.as` | `pr2.effects.ArrowEffect` | ported | Authored `Arrow2Graphic` mounting, 0.25 scale, upward velocity decay, alpha fade, 15-frame lifetime, and removal are covered by `ParticleEmitterTest`. |
| `flash/effects/BlockPiece.as` | `pr2.effects.BlockPiece`, `pr2.level.ServerLevelRenderer` | ported | Randomized block fragments for brick, crumble, and mine break visuals are covered by `ServerLevelRendererTest`. |
| `flash/effects/Effect.as` | effect ownership/removal boundaries in `pr2.effects.*`, `pr2.level.ServerLevelRenderer`, `pr2.gameplay.Course` | partial | Current concrete effects own their frame listeners and display removal directly; the shared `EffectBackground` base/addChild abstraction is not yet ported as a standalone class. |
| `flash/effects/Egg.as` | `pr2.gameplay.EggRound`, `pr2.gameplay.Course` command boundary | partial | Seeded egg round bookkeeping, ids, remove commands, and local `grab_egg` emission are covered by `CharacterLifecycleTest`; egg `PhysicsEffect` movement, attacks, squash, and authored visuals remain under gameplay behavior. |
| `flash/effects/Hat.as` | `pr2.gameplay.GameCommandShell` hook boundary, `pr2.character.Character` hat stack | gap | Loose hat physics, pickup/return commands, `removeHat{id}` registration, and authored falling hat visuals are still deferred; character-owned hats are covered separately. |
| `flash/effects/IceWaveShot.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Local item use/reload/direction emission is covered by `LocalPlayerControllerTest`; projectile branching, block freezing visuals, and remote/local hit side effects are not yet rendered as live `ShotEffect`s. |
| `flash/effects/LaserShot.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Local laser use, recoil, reload, and direction payload parity are covered by `LocalPlayerControllerTest`; projectile travel, hit animation, and laser sounds remain unported live effects. |
| `flash/effects/MineAppear.as` | `pr2.harness.LocalPlayerController`, `pr2.level.ServerLevelRenderer` | partial | Mine placement tile/effect payload and final mine block collision are covered by `LocalPlayerControllerTest`; the delayed authored appear animation and sound are not yet a concrete renderer effect. |
| `flash/effects/MineExplode.as` | `pr2.effects.MineExplosion`, `pr2.level.ServerLevelRenderer` | ported | Authored explosion animation, lifetime, sound hook, and renderer teardown are covered by `ServerLevelRendererTest`. |
| `flash/effects/PhysicsEffect.as` | effect hook boundary | gap | Shared gravity/collision physics for loose hats and eggs is not yet ported as a reusable class; the affected concrete effects remain explicit gaps. |
| `flash/effects/ShotEffect.as` | item projectile hook boundary | gap | Shared projectile movement, block/player hit testing, life expiry, and rotation math for laser/ice shots are not yet represented as live effect objects. |
| `flash/effects/Slash.as` | `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter` item payload boundary | partial | Sword item use/reload/direction and lunge parity are covered by `LocalPlayerControllerTest`; authored slash hit sweep, sound, and remote/local hit side effects remain unported live effects. |
| `flash/effects/StarEffect.as` | `pr2.effects.StarEffect` | ported | Authored `PointyStar` mounting, 15-frame lifetime, and removal are covered by `ParticleEmitterTest`. |
| `flash/effects/Sting.as` | `pr2.effects.StingEffect`, `pr2.gameplay.Course`, `pr2.character.LocalCharacter` | ported | Incoming local `sting{tempID}` commands mount the authored owner-following sting graphic, choose the left/right timeline side, play the sting sound, and route damage through the local hurt/immunity path; covered by `CharacterLifecycleTest` and `LocalCharacterTest`. |
| `flash/effects/TeleportPop.as` | `pr2.effects.TeleportPop`, `pr2.level.ServerLevelRenderer`, `pr2.harness.LocalPlayerController`, `pr2.gameplay.Course` | partial | Authored pop animation/sound, local teleport-block start/destination rendering, socket emission, remote server effect mounting, and teleport item start/end coordinates are covered by `TeleportPopTest`, `LocalPlayerControllerTest`, and `CharacterLifecycleTest`; live item-teleport rendering/network emission remains under multiplayer item/effect integration. |
| `flash/effects/Zap.as` | `pr2.effects.ZapEffect`, `pr2.harness.LocalPlayerController`, `pr2.character.LocalCharacter`, `pr2.gameplay.Course` | ported | Lightning item `zap\`` emission, artifact flash-only activation, incoming local `zap` command visuals, sound, owner-following fadeout, and local hurt/immunity routing are covered by `LocalPlayerControllerTest`, `LocalCharacterTest`, and `CharacterLifecycleTest`. |

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
| `flash/gameplay/TestCourse.as` | `pr2.page.CampaignTestScreen`, `pr2.page.LevelEditor.TestCoursePage` | partial | Decoded levels run through `Course`; level-editor test-course controls, stat picker, hat picker, editor return, restart persistence, and custom/happy/sad block StatsSelect sync are covered by `LobbyServicesTest`. Report-management variants remain with the level-editor TODO. |

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

## Level Editor Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/levelEditor/BlockObject.as` | level-editor implementation gap | gap | Editor block-object selection, option mutation, serialization, and placement remain unported with the level-editor tools/sidebar work. Runtime decoded block fixtures and rendering are covered separately by the level/server renderer paths. |
| `flash/levelEditor/DrawObject.as` | level-editor implementation gap | gap | Editor drawing-object ownership, transform editing, and save-string projection remain unported; server-authored drawings render only after decoded level load. |
| `flash/levelEditor/DrawingPopup.as` | level-editor implementation gap | gap | The drawing popup, draw settings, and editor-specific drawing controls are not yet represented in Haxe. |
| `flash/levelEditor/GetLevelsPopupItem.as` | level-management implementation gap | gap | The load-level popup row, validation, click behavior, and server response variants remain with the level-management load flow. |
| `flash/levelEditor/GetReportedLevelsPopupItem.as` | report-management implementation gap | gap | Reported-level rows and report-management actions remain unported with the editor report-management flow. |
| `flash/levelEditor/HatPicker.as` | level-editor test-course gap | gap | The editor/test-course hat picker is not ported; race character hats and account preview hats are covered by other subsystems. |
| `flash/levelEditor/LevelEditor.as` | level-editor implementation gap | gap | The main editor stage, camera, tool dispatch, save/load/upload/delete flows, object mutation, and test-course transition are not yet ported. |
| `flash/levelEditor/LevelEditorMenu.as` | level-editor implementation gap | gap | The top-level editor menu, mode buttons, confirmation popups, and navigation are unported beyond the lobby-to-editor handoff boundary. |
| `flash/levelEditor/TextObject.as` | level-editor implementation gap | gap | Editor text-object creation, editing, placement, and serialization remain unported; decoded server text rendering is covered separately by the level renderer. |

## Level Management Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/level_management/ChooseLevelsModePopup.as` | level-management implementation gap | gap | The editor load/report mode chooser, reports/my-levels routing, cancel behavior, and authored popup lifecycle remain unported with the level-management flows. |
| `flash/level_management/DeletingLevelPopup.as` | level-management implementation gap | gap | The `delete_level.php` upload popup, completion handling, and return to the editable level list remain part of the unported delete flow. |
| `flash/level_management/GetLevelReports.as` | level-management implementation gap | gap | Reported-level listing retrieval from `levels_get_reported.php`, row creation, load-as-report routing, and handle action remain with report-management work. |
| `flash/level_management/GetLevels.as` | level-management implementation gap | gap | The user's level-list request, selectable rows, load routing, delete confirmation, and loader cleanup are unported beyond the generated popup symbols. |
| `flash/level_management/HandleLevelReportPopup.as` | level-management implementation gap | gap | The report-detail popup, info hover, archive request, social-ban request, validation, confirmation, and reported-list refresh are unported moderation flows. |
| `flash/level_management/LoadingLevelPopup.as` | level-management implementation gap | gap | Editor level download, hash validation, URL-variable parse, editor state hydration, report-mode handoff, and error popups remain unported. Runtime level loading is covered separately by `GamePage`/`LevelEntry`. |
| `flash/level_management/SaveLevelPopup.as` | level-management implementation gap | gap | The editor save dialog, title/note char counts, publishing/password controls, validation copy, and upload launch are part of the unported save flow. |
| `flash/level_management/UploadingLevelPopup.as` | level-management implementation gap | gap | Save-string generation, MD5 upload hash, `upload_level.php` request, retry wait, override-ban confirmation, overwrite confirmation, and error handling remain unported. |

## Lobby Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/lobby/Lobby.as` | `pr2.page.LobbyPage`, `pr2.lobby.LobbyLeft`, `pr2.lobby.LobbyRight`, `pr2.lobby.LobbyPopups` | partial | The post-login shell mounts the authored lobby background, both panes, bottom button strip, menu music entry/exit, logout, level-editor handoff boundary, Kong link, Options, Vault, and Credits routes. Temporary-moderator confirmation copy and exact Kong-hat hover popup behavior remain lobby workflow/visual gaps. |
| `flash/lobby/LobbyLeft.as` | `pr2.lobby.LobbyLeft`, `pr2.lobby.tabs.ChatTab`, `pr2.lobby.tabs.MessagesTab`, `pr2.lobby.tabs.PlayersTab`, `pr2.lobby.tabs.AccountTab` | ported | Member/guest tab membership, default Account selection, holder id, pane coordinates, unread PM notification container, and PM notify command routing are represented by the Haxe pane and covered by lobby tests. |
| `flash/lobby/LobbyRight.as` | `pr2.lobby.LobbyRight`, `pr2.lobby.tabs.ListingTab`, `pr2.lobby.tabs.SearchTab` | partial | Campaign, All Time Best, Week's Best, Newest, Search, member-only Favorites, lookup-user, and lookup-level tab routing are represented. Each listing tab's live loading/error/populated parity remains tracked under the lobby data-surface verification TODO. |
| `flash/lobby/LobbySide.as` | `pr2.lobby.LobbySide`, `pr2.page.PageHolder`, `pr2.ui.TabsHolder` | ported | The shared half-square background, tab holder, dimensions, selected tab memory, page offset `(4, 20)`, resize behavior, and teardown are represented by the Haxe pane base. |

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

## Shop Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/shop/QuantityPopup.as` | `pr2.lobby.store.QuantityPopup`, `pr2.lobby.store.StoreListingData` | ported | The authored quantity popup, singleton replacement, slider max, selected/count cost text, rank-rental quantity limit, sale-adjusted cost, affordability color, buy enablement, cancel, and listener cleanup are represented by the Haxe popup and covered by `StorePopupTest`. |
| `flash/shop/StoreListing.as` | `pr2.lobby.store.StoreListing`, `pr2.lobby.store.StoreListingData` | partial | Authored listing art, title/price/sale/description links, availability alpha, hover background, purchase/info dispatch, image loading, sale math, and current-price helpers are ported. The random `epic_everything` character previews and exact coin/price background resizing remain visual fidelity gaps. |
| `flash/shop/StorePopup.as` | `pr2.lobby.store.StorePopup`, `pr2.lobby.store.StoreListing`, `pr2.lobby.store.StoreListingData`, `pr2.lobby.dialogs.UploadingPopup`, `pr2.crypto.PR2Encryptor` | partial | The Vault popup loads `/vault/vault.php`, renders authored listings, tracks user coins/title, handles FAQ, quantity selection, member/coin validation, super-booster use, purchase upload, encrypted buy-coins POST, wheel scrolling, and cleanup. Flash `CustomScrollBar` parity, sale title flashing, purchase terms copy, and full live error/empty visual coverage remain lobby/store verification gaps. |

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
| `flash/ui/StatsSelect.as` | `pr2.lobby.account.StatsSelect` | partial | Account stat allocation, remaining-points display, info string, stat extraction, level-editor live-character updates, persistence, and TestCourse set-from-character sync are covered by `LobbyServicesTest`. |
| `flash/ui/TabsHolder.as` | `pr2.ui.TabsHolder`, `pr2.ui.TabLayout` | ported | Tab ownership, remembered selected tab, overlap layout, selected-front ordering, and removal persistence are represented by the shared tab holder. |

## Com Classes

| AS3 source | Haxe/OpenFL target | Status | Notes |
| --- | --- | --- | --- |
| `flash/com/adobe/crypto/MD5.as` | Haxe `haxe.crypto.Md5` call sites | ported | Campaign-list and level-data hash validation use the standard Haxe MD5 implementation at the same protocol boundaries instead of carrying the Adobe helper class. |
| `flash/com/adobe/utils/IntUtil.as` | crypto adapter boundary | gap | The AS3 bit-rotation helpers are only used by the vendored Adobe MD5 implementation; no standalone Haxe adapter is needed while MD5 is supplied by the standard library. |
| `flash/com/hurlant/crypto/hash/IHash.as` | crypto adapter boundary | gap | The Hurlant hash interface is not ported as an interface; current covered flows use direct MD5/AES adapters. |
| `flash/com/hurlant/crypto/hash/MD5.as` | Haxe `haxe.crypto.Md5` call sites | ported | The Hurlant MD5 implementation is replaced by the standard Haxe MD5 at login, level-list, and level-data validation boundaries. |
| `flash/com/hurlant/crypto/prng/ARC4.as` | crypto adapter boundary | gap | ARC4 is part of the vendored Hurlant crypto bundle and is not represented by a Haxe runtime class. |
| `flash/com/hurlant/crypto/prng/IPRNG.as` | crypto adapter boundary | gap | The Hurlant PRNG interface has no standalone Haxe equivalent; covered PR2 flows do not consume this interface directly. |
| `flash/com/hurlant/crypto/prng/Random.as` | `pr2.lobby.Memory`, `pr2.lobby.SecureData` | partial | SecureData-style byte storage is represented for current lobby/account uses, but Hurlant's entropy pool and PRNG API are not ported. |
| `flash/com/hurlant/crypto/symmetric/AESKey.as` | `pr2.crypto.PR2Encryptor` | ported | AES-CBC login/store encryption is implemented through `PR2Encryptor` and covered by `PR2EncryptorTest`. |
| `flash/com/hurlant/crypto/symmetric/CBCMode.as` | `pr2.crypto.PR2Encryptor` | ported | CBC-mode block processing is supplied by the Haxe crypto adapter inside `PR2Encryptor`. |
| `flash/com/hurlant/crypto/symmetric/ICipher.as` | crypto adapter boundary | gap | The Hurlant cipher interface is not exposed as a Haxe type; encryption is kept behind PR2-specific helpers. |
| `flash/com/hurlant/crypto/symmetric/IMode.as` | crypto adapter boundary | gap | The Hurlant mode interface is not exposed as a Haxe type; current parity coverage is at the encrypted payload boundary. |
| `flash/com/hurlant/crypto/symmetric/IPad.as` | crypto adapter boundary | gap | Generic pad strategy injection is not ported; the PR2 pad behavior is folded into `PR2Encryptor`. |
| `flash/com/hurlant/crypto/symmetric/IStreamCipher.as` | crypto adapter boundary | gap | Stream-cipher support is unused by the ported PR2 flows and remains unimplemented. |
| `flash/com/hurlant/crypto/symmetric/ISymmetricKey.as` | crypto adapter boundary | gap | The Hurlant symmetric-key interface is not exposed as a Haxe type; AES use is constrained to `PR2Encryptor`. |
| `flash/com/hurlant/crypto/symmetric/IVMode.as` | `pr2.crypto.PR2Encryptor` | ported | IV handling for PR2 AES-CBC payloads is represented inside `PR2Encryptor`. |
| `flash/com/hurlant/crypto/symmetric/PKCS5.as` | `pr2.crypto.PR2Encryptor` | ported | The login/store encryption pad behavior is represented in `PR2Encryptor` and covered by deterministic encryption vectors. |
| `flash/com/hurlant/util/Base64.as` | `pr2.crypto.PR2Encryptor` | ported | Base64 encoding for encrypted PR2 payloads is handled inside the encryption adapter. |
| `flash/com/hurlant/util/Hex.as` | crypto adapter boundary | gap | The general Hex helper is not ported; current protocol code does not expose Hurlant hex APIs. |
| `flash/com/hurlant/util/Memory.as` | `pr2.lobby.Memory`, `pr2.lobby.SecureData` | partial | Byte storage is represented for SecureData-compatible values; Hurlant's full fast-memory adapter is not ported. |
| `flash/com/jcward/workers/BitString.as` | guild-emblem upload gap | gap | The JPEG bit writer is only needed by the unported local image/JPEG upload path. |
| `flash/com/jcward/workers/JPEGEncoder.as` | guild-emblem upload gap | gap | JPEG encoding remains with the guild-emblem upload TODO; no Haxe encoder is currently wired. |
| `flash/com/jiggmin/ColorPicker/ColorChoices.as` | `pr2.lobby.account.ColorChoices` | ported | The authored color palette is represented by the account color picker data. |
| `flash/com/jiggmin/ColorPicker/ColorPicker.as` | `pr2.lobby.account.ColorPicker` | partial | Account part color selection is functional; exact Flash picker triangle/diagonal mask visuals remain visual fidelity work. |
| `flash/com/jiggmin/ColorPicker/ColorPickerPopup.as` | `pr2.lobby.account.ColorPicker` | partial | Popup-style color editing is represented inside the account picker control; exact popup artwork and focus behavior remain visual gaps. |
| `flash/com/jiggmin/ColorPicker/CursorEyedropper.as` | level-editor color-tool gap | gap | Eyedropper cursor behavior is not ported and remains with level-editor tooling. |
| `flash/com/jiggmin/data/AESPad.as` | `pr2.crypto.PR2Encryptor` | ported | PR2's AES padding quirk is represented in the encrypted login/store payload adapter. |
| `flash/com/jiggmin/data/ColorUtil.as` | `pr2.lobby.account.ColorPicker`, character color parsing | partial | Account customization parses and applies PR2 color values; a standalone color utility API is not ported. |
| `flash/com/jiggmin/data/CommandHandler.as` | `pr2.net.CommandHandler` | ported | Backtick-delimited command registration, dispatch, shared instance routing, and teardown are covered by gameplay/lobby tests. |
| `flash/com/jiggmin/data/Data.as` | targeted protocol/model helpers | partial | Level hashes, save-string parsing, item/block constants, rotate math, links, and account values are split across focused Haxe modules; broad static utility parity is not complete. |
| `flash/com/jiggmin/data/Encryptor.as` | `pr2.crypto.PR2Encryptor` | partial | Login and store encryption are ported; encrypted level-password payload parity is still called out at `LevelItem`. |
| `flash/com/jiggmin/data/EpicFlash.as` | `pr2.runtime.EpicFlash` | ported | Prize and part epic decoration use the ported runtime effect, covered through gameplay/account popup tests. |
| `flash/com/jiggmin/data/GpNotification.as` | GP notification gap | gap | The authored GP notification popup/effect is not ported as a standalone runtime path. |
| `flash/com/jiggmin/data/HTMLNameMaker.as` | `pr2.lobby.chat.HtmlNameMaker` | partial | Linked player/guild-name rendering is represented for chat and popups; full Flash HTML/link parsing parity remains under chat/lobby verification. |
| `flash/com/jiggmin/data/Memory.as` | `pr2.lobby.Memory` | partial | Byte array storage needed by SecureData-style values is represented; the full AS3 memory helper API is not. |
| `flash/com/jiggmin/data/Objects.as` | `pr2.level.ObjectCodes`, generated asset metadata | partial | Block/object code lookup is represented for decoded levels and fixtures; editor object catalogs remain part of the level-editor TODO. |
| `flash/com/jiggmin/data/PR2Socket.as` | `pr2.net.LobbySocket`, `pr2.net.LoginSocketProtocol` | ported | Socket framing, login handoff, command routing, send recording, and close/error boundaries are covered by socket and race-session tests. |
| `flash/com/jiggmin/data/Random.as` | targeted deterministic random use | partial | Item selection and visual random effects use local deterministic/random helpers where ported; the shared Flash random wrapper is not standalone. |
| `flash/com/jiggmin/data/SWFStats.as` | external analytics boundary | gap | Kong/SWF stats submission is intentionally not implemented in the browser port. |
| `flash/com/jiggmin/data/SavedAccounts.as` | `pr2.net.SavedAccounts` | ported | Remembered token storage, recency, case-insensitive replacement, deletion, and invalid-token removal are covered by login tests. |
| `flash/com/jiggmin/data/SecureData.as` | `pr2.lobby.SecureData` | partial | Mutable numeric/string storage and current lobby/account uses are represented; anti-tamper semantics are not reproduced outside required behavior. |
| `flash/com/jiggmin/data/SecureStore.as` | `pr2.lobby.account.Settings`, `pr2.net.SavedAccounts` | partial | Persistent settings and login tokens use browser storage wrappers; Flash secure-store internals are not preserved. |
| `flash/com/jiggmin/data/Settings.as` | `pr2.lobby.account.Settings` | ported | Music/sound volumes, filter/art toggles, alternate controls, disabled songs, and loadout preset storage are covered by options/audio/account tests. |
| `flash/com/jiggmin/data/Time.as` | targeted date/time helpers | partial | Artifact placement and race/session flows parse/format the date fields they use; the broad static Time helper is not ported. |
| `flash/com/jiggmin/data/UnreadNotif.as` | `pr2.lobby.messages.UnreadNotif` | ported | PM unread count, last-read updates, notification container wiring, and reset behavior are covered by lobby tests. |
| `flash/com/jiggmin/pixelEffects/PixelEffect1.as` | `pr2.effects.PixelEffect1` | ported | Pixel burst lifecycle and teardown are represented by the Haxe effect and covered by `PixelEffect1Test`. |
| `flash/com/jiggmin/pixelEffects/pixels/SegPixel.as` | `pr2.effects.SegPixel` | ported | Segment pixel movement/lifetime support is represented by the Haxe pixel effect implementation. |
