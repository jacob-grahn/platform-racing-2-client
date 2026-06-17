# Real PR2 Level Payload Format

This inventory tracks the saved/server level payload format used by the Flash
client and the current Haxe/OpenFL port. It is based on:

- `flash/page/GamePage.as`
- `haxe/src/pr2/net/LevelDataClient.hx`
- `haxe/src/pr2/net/ServerLevelData.hx`
- `haxe/src/pr2/level/ServerLevelDecoder.hx`
- `haxe/src/pr2/level/ObjectCodes.hx`

## Response Envelope

Level data is fetched from `{host}/levels/{id}.txt?version={version}`. The body
is the URL-style level string followed by a 32-character MD5 hash.

The hash is:

```text
MD5(version + levelId + levelData + "0kg4%dsw")
```

The Flash client sanitizes the `levelData` string before parsing it. Only these
top-level query parameters are allowed to split into separate fields:

```text
credits, data, title, note, song, gravity, max_time, items, level_id, live,
time, min_level, has_pass, gameMode, version, user_id, cowboyChance, badHats
```

Unknown apparent params are folded back into the previous value. This preserves
literal `and` text in values after Flash's `&` to `and` replacement.

## Top-Level Fields

The port currently reads:

- `level_id`: numeric level id.
- `version`: numeric level version.
- `title`: level title, default `(untitled)`.
- `note`: level note.
- `song`: music identifier/name.
- `gravity`: numeric gravity, default `1.0`.
- `max_time`: time limit, default `0` in the parsed model.
- `min_level`: minimum rank/level.
- `gameMode`: mode string, default `race`.
- `items`: backtick-delimited allowed item list.
- `data`: raw backtick-delimited level content.

Flash additionally applies UI/gameplay bounds when setting variables:

- `gravity` is clamped to `-99..99` and formatted with a decimal.
- `max_time` is clamped to `0..9999`.
- `gameMode=eggs` is normalized to `egg`.
- `items=all` or missing allows every item; empty allows no items.
- `badHats` is a comma-delimited excluded hat list.
- `cowboyChance` is clamped to `0..100`, default `5`.

## `data` Sections

The `data` field is split on backticks. Section `0` is the read mode:

- `m1`
- `m2`
- `m3`
- `m4`

After removing the mode token, Flash treats the remaining sections as:

```text
0: background color, hex
1: blocks
2: art layer 1
3: art layer 2
4: art layer 3
9: art layer 0
10: art layer 00
```

Only the background color and block layer are decoded by the current Haxe port.
The art-layer strings remain known gaps for backgrounds, stamps, draw objects,
and text objects.

## Block Layer

Decoded blocks are stored as absolute PR2 pixel coordinates. Block codes are the
Flash `Objects.as` codes. Saved block codes below `100` resolve by adding `100`,
so saved code `11` becomes start block code `111`.

Implemented block code range:

```text
100 basic1
101 basic2
102 basic3
103 basic4
104 brick
105 arrow down
106 arrow up
107 arrow left
108 arrow right
109 mine
110 item
111 start 1
112 start 2
113 start 3
114 start 4
115 ice
116 finish
117 crumble
118 vanish
119 move
120 water
121 rotate right
122 rotate left
123 push
124 safety
125 infinite item
126 happy
127 sad
128 heart
129 time
130 minion egg
131 custom stats
132 teleport
```

### `m1`

`m1` block strings use a leading hex base offset, then absolute hex entries:

```text
baseX;baseY,code;x;y[,width;height],...
```

The current block decoder reads `code`, `x + baseX`, and `y + baseY`. Flash can
also decode optional width/height percentages for non-block object layers.

### `m2`

`m2` uses relative coordinate deltas with segment multiplier `1`:

```text
relX;relY[;code],...
```

The object code carries forward when omitted.

### `m3`

`m3` uses the same relative coordinate walk as `m2`, but multiplies coordinates
by the PR2 segment size of `30` pixels. This is the common campaign-era block
format.

### `m4`

`m4` uses relative coordinate deltas multiplied by `30`, plus an optional raw
block option field:

```text
relX;relY[;code[;options]],...
```

The current port preserves the option string for mechanics such as move,
teleport, and custom stats blocks.

## Art, Draw, And Text Layers

Flash decodes art sections `2`, `3`, `4`, `9`, and `10` with the same relative
object walker used by `m2`/`m3` object strings.

Object entries decode to:

```text
o<objectCode>;<x>;<y>[;<widthScale>;<heightScale>]
```

Text entries use `t` in the saved object code slot and decode to:

```text
u<textContent>;<x>;<y>;<textColor>;<widthPercent>;<heightPercent>
```

These layers are inventoried but not yet rendered by the Haxe/OpenFL server
level harness.
