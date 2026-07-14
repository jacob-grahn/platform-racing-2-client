# Export audio inventory

The HTML5 and macOS exports each contain the same 35 files under
`assets/audio/sfx`. The canonical copies live in the repository's
`assets/audio/sfx` directory. This inventory records the runtime playback path
for every exported file; generated catalog declarations alone are not counted
as use.

| Exported file | Flash identity / authored role | Runtime use |
| --- | --- | --- |
| `intro_timeline_sound_01.mp3` | Intro timeline sound (`sound57.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frames 2 and 77 |
| `intro_timeline_sound_02.mp3` | Intro timeline sound (`sound58.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frame 2 |
| `intro_timeline_sound_03.mp3` | Intro timeline sound (`sound62.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frame 8 |
| `intro_timeline_sound_04.mp3` | Intro timeline sound (`sound63.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frame 32 |
| `intro_timeline_sound_05.mp3` | Intro timeline sound (`sound64.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frame 37 |
| `intro_timeline_sound_06.mp3` | Intro timeline sound (`sound67.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frame 85 |
| `intro_timeline_sound_07.mp3` | Intro timeline sound (`sound68.mp3`) | `PR2MovieClip` + `TimelineSound`, intro symbol 69 frame 85 |
| `logo_theme.mp3` | Logo animation timeline sound (`sound81.mp3`) | `PR2MovieClip` + `TimelineSound`, logo symbol 80 frame 1 |
| `menu_noodle_town_3.mp3` | `NoodleTown3` | `MenuMusic` channel 2 |
| `menu_noodle_town_2.mp3` | `NoodleTown2` | `MenuMusic` channel 1 |
| `countdown_go.mp3` | `GoSound` | `Countdown` finish cue |
| `countdown_ready.mp3` | `ReadySound` | `Countdown` count cues |
| `victory.mp3` | `VictorySound` | `RaceSounds.playVictorySound`, called by `Course` on local finish/objective |
| `block_thump.mp3` | `ThumpSound` | `RaceSounds.playBlockBumpSound` |
| `star.mp3` | `StarSound` | `RaceSounds.playItemBlockSound` |
| `tick_tock.mp3` | `TickTockSound` | `RaceSounds.playTimeBlockSound` |
| `bump_sad.mp3` | `BumpSadSound` | `CourseBlockVisualController` via `RaceSounds.playStatBlockSound` |
| `bump_happy.mp3` | `BumpHappySound` | `CourseBlockVisualController` and `RaceSounds.playCharacterSound` (`bumpHappy`) |
| `jet_engine.wav` | `EngineSound` | `RaceSounds.startJetSound` loop |
| `speed_up.mp3` | `SpeedUpSound` | `RaceSounds.playCharacterSound` (`speedUp`) |
| `slow_down.mp3` | `SlowDownSound` | `RaceSounds.playCharacterSound` (`slowDown`) |
| `jump.mp3` | `JumpSound` | `RaceSounds.playWorldJumpSound` |
| `egg_collect.mp3` | `CollectEggSound` | `EggRound.playDefaultCollectSound` |
| `squash.mp3` | `SquashSound` | `RaceSounds.playCharacterSound` (`squash`) |
| `super_jump.mp3` | `SuperJumpSound` | `RaceSounds.playSuperJumpSound` |
| `ice_wave.mp3` | `IceWaveSound` | `EffectBackground.playIceWave` |
| `mine_explosion.mp3` | `ExplosionSound` | `MineExplosion` |
| `slash_swish.mp3` | `SwishSound` | `Slash` |
| `laser_hit.mp3` | `LaserHitSound` | `EggRound.playDefaultLaserHitSound` |
| `laser_fire.mp3` | `LaserSound` | `EffectBackground.playLaser` |
| `zap.mp3` | `ZapSound` | `ZapEffect` |
| `mine_appear.mp3` | `MineAppearSound` | `MineAppear` |
| `teleport.mp3` | `TeleportSound` | `TeleportPop` |
| `sting.wav` | `StingSound` | `StingEffect` |
| `artifact_yeah.wav` | `YeahSound` | `RaceSounds.playCharacterSound` (`artifactYeah`) |

The intro/logo entries are real playback uses: their sound names are authored
in generated timeline frame data, and `PR2MovieClip` passes those frames to
`TimelineSound` when the animation enters each keyframe.
