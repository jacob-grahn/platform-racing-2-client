# OpenFL Baseline Captures

Captured from the Haxe/OpenFL HTML5 build with `tools/openfl_driver.py`.

- Stage size: `550x400`
- Runtime path: `export/html5/bin/index.html`
- Harness: `CharacterGraphic` with only `runAnim` visible
- Part ids: `hat=1`, `head=1`, `body=1`, `feet=1`

## Captures

- `run_harness.png` - Generated vector character art with id 1 character
  parts selected and the run timeline advanced by the root 27 FPS frame loop.

## Commands

```sh
haxelib run openfl build html5
python3 tools/openfl_driver.py --delay 1.6 shot test/baselines/openfl/run_harness.png
python3 tools/openfl_driver.py --fps-duration 30 --fps-target 27 --fps-tolerance 5 fps
python3 tools/compare_screenshots.py test/baselines/flash/07_gameplay_start.jpg test/baselines/openfl/run_harness.png --diff test/output/openfl-vs-flash-diff.png --metrics test/output/openfl-vs-flash-metrics.json --threshold-percent 100 --threshold-rms 255
```

The comparison command accepts repeated `--ignore x,y,width,height` regions for
live UI, prompts, or blinking elements that should not affect the diff metrics.
