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
