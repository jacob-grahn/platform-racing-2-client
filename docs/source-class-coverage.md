# Source Class Coverage

This inventory tracks first-party AS3 classes against their Haxe/OpenFL port,
platform adapter, or remaining gap. Keep entries narrow: an exported symbol
alone is not a class port.

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
