# Platform Racing 2 Haxe/OpenFL Port TODO

This file tracks only unfinished work. The target is a 1:1 port of the original
Flash client, not a compatible remake: behavior, protocol,
screen flow, layout, animation, sound, and failure states should match the AS3
and XFL sources. Completed work belongs in git history and `README.md`.

## Parity Rules

- Treat `flash/**/*.as` and `flash/platform-racing-2-xfl/` as the behavioral and
  visual specification. Do not silently simplify a workflow because the happy
  path works.
- Temporary drawings, record-only actions, harness redirects, hard-coded data,
  and unsupported buttons are parity gaps and must remain listed here.
- A task is complete only when the real user flow works. Rendering the art or
  recording the requested action is not completion.
- Run only the related test cases for your change, the full suite is a bit slow

## Follow-up Port Gaps

### Shared Infrastructure

#### Build Size And HTML5 Payload

- Further reduce HTML5 payload size by splitting, lazy-loading, or lowering the
  default scale of character atlases. After the first payload pass,
  `export/html5/bin` is about `33.86 MB` raw and `23.71 MB` with gzip; character
  atlas PNGs remain the largest binary bucket and gzip does not reduce them
  meaningfully.
- Investigate removing unused generated asset metadata from the final JS.
  `AssetCatalog.media()` and `AssetCatalog.linkageClasses()` do not appear to
  have runtime callers, but their bitmap/sound/linkage literals still survive
  into `PlatformRacing2.js`.
- Investigate excluding test-only fixtures from the HTML5 export. The broad
  `assets/` include currently ships `assets/fixtures/flat-level.json`, even
  though local campaign test levels are built in code.
- Investigate dropping `assets/fonts/DejaVuSans-BoldOblique.ttf`. Current
  generated text faces include Verdana, Verdana-Bold, and Verdana-Italic, but no
  Verdana-BoldItalic; the file is about 632 KB raw / 329 KB gzipped.
- Investigate making audio assets non-preloaded. The audio files are needed at
  runtime, but the broad `assets/` include appears to preload about 1.5 MB raw /
  1.28 MB gzipped of sounds up front.

### Lobby Dialogs And Account Workflows

### Login, Lobby, And Social Lists

### Level Browser And Listings

### Level Editor


### Gameplay, Effects, And Items

- Finish "Don't Move JV" race parity. The shared e2e now captures one gameplay
  screenshot per second for both clients under `test/output/dmjv-{target}/gameplay/`,
  and the old Flash baseline screenshots show the race completing. Current Haxe
  parity fixes include Flash-centered race start positioning, immediate collision
  probe refresh after `onStand()`, Flash-style hurt-frame decrement timing,
  runtime omission of start markers, and last-loaded block lookup for overlapping
  tiles. The Haxe route still diverges in the first mine/arrow stack: after
  `bump:mine@12,27`, the port side-collides with `basic@11,30`, snaps to
  `x=370`, lands on `basic@12,31`, and never reaches Race Complete. The current
  published Flash app launches headless in the harness, so a fresh frame trace
  past this point still needs a working projector publish or another tracing path.

### Player Profile, Store, And UI Polish
