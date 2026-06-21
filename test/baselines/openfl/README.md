# OpenFL Baseline Captures

Captured from the Haxe/OpenFL HTML5 build with `tools/openfl_driver.py`.

- Stage size: `550x400`
- Runtime path: `export/html5/bin/index.html`
- Harness: local gameplay fixture with atlas-backed `CharacterDisplay`
- Default part ids: `hat=2`, `head=1`, `body=1`, `feet=1`

## Captures

- `run_harness.png` - Local gameplay harness with the default outfit and the
  root 27 FPS frame loop.
- `lobby.png` - Lobby (`screen=lobby&user=Tester`) at `--delay 6`, rendered with
  the default `pr2_flatten_cache` flatten path on. This is the **flatten parity
  lock**: it captures the canonical post-flatten render so any future regression
  in `FlattenPolicy` / `PR2MovieClip.maybeFlattenSubtree` is caught. The lobby
  render is deterministic at this delay (repeat captures diff to 0 pixels).

## Flatten parity lock

`pr2_flatten_cache` collapses static, render-safe subtrees into one cached GPU
quad (lobby measured 18.7fps -> 60fps vsync cap). Against the un-flattened build
the only delta is sub-perceptual anti-alias rounding (rmsDelta 0.071, maxDelta
2/255, confined to the bottom-strip band). The locked tolerance below accepts
that rounding while failing on any real drift:

```sh
haxelib run openfl build html5
python3 tools/openfl_driver.py --query 'screen=lobby&user=Tester' --delay 6 shot test/output/lobby.png
python3 tools/compare_screenshots.py test/baselines/openfl/lobby.png test/output/lobby.png --diff test/output/lobby-diff.png --metrics test/output/lobby-metrics.json --threshold-percent 2 --threshold-rms 1.0
```

## Commands

```sh
haxelib run openfl build html5
python3 tools/openfl_driver.py --delay 1.6 shot test/baselines/openfl/run_harness.png
python3 tools/openfl_driver.py --delay 2.0 --query 'hat=16&head=37&body=29&feet=40&primary=aa00ff&secondary=00cc11&render=composite' shot test/output/openfl-character-outfit.png
python3 tools/openfl_driver.py --fps-duration 30 --fps-target 27 --fps-tolerance 5 fps
python3 tools/compare_screenshots.py test/baselines/flash/07_gameplay_start.jpg test/baselines/openfl/run_harness.png --diff test/output/openfl-vs-flash-diff.png --metrics test/output/openfl-vs-flash-metrics.json --threshold-percent 100 --threshold-rms 255
```

The comparison command accepts repeated `--ignore x,y,width,height` regions for
live UI, prompts, or blinking elements that should not affect the diff metrics.
