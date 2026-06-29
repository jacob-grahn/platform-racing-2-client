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
