# R-Type (Amiga) – graphics formats

All findings come from the drawing code in `src/game.s`. The same notes are in the source as comments (see `SetBitplanes`, `DrawMap`, `ObjAnimDraw`, `CopperInt`, `CopperList`).

## Playfield

| | |
|---|---|
| Depth | 4 bitplanes, 16 colours (COLOR00–15 from the level palette) |
| Layout | **interleaved**: each line holds plane 0, 1, 2, 3, each **52 bytes** (416 px) → `$D0` bytes per line |
| Visible | 320 × 192 (DIWSTRT `$2C91`, DDFSTRT `$38`, lines `$2C`–`$EB`) |
| Modulo | BPL1MOD = BPL2MOD = `$A8` (3 × 52 + 52 − 40) |
| Buffers | `SCREEN_A` `$2D1BA`, `SCREEN_B` `$3AEBA`, 272 lines each (`$DD00` bytes) |
| View origin | buffer + `$1A06` (32 lines down, 6 bytes in) + FineScrollY lines |
| Scrolling | coarse = map column/row drawn first; fine = BPLCON1 (x) and a line offset (y, 0–15) |

The extra 96 pixels per line and 32 lines on top are margin: the 20 × 13 tile background is redrawn in full every frame (`DrawMap`), and BOBs can be clipped by simply drawing into the margin (x range −16…`$170`).

**Double buffering:** the game draws into `DrawBuffer`, and the copper interrupt (`SwapScreens` → `SetBitplanes`) switches the bitplane pointers once `FrameReady` is set. A countdown (`D_05136`, reloaded with 0 or 1 depending on `D_0513C`) limits the flip rate to every VBL or every second VBL; what selects the mode is still to be confirmed.

## HUD

From line `$ED` the copper switches to **3 bitplanes** (BPLCON0 `$3200`), non-interleaved 40-byte lines: planes at `$2C7B0`, `$2CA08`, `$2CC60` (`$258` bytes = 15 lines each), at the end of the `$6000` graphics block. It has its own colours, plus a COLOR01 gradient on lines `$EE`–`$F3`. The score digits (`DrawDigits`), lives (`DrawLives`, `$2C7DA`) and the beam meter (`DrawBeamMeter`, `$2C7E8`) are written straight into these planes.

## Tiles

`LV_Tiles` (the start of level B, `$4D300`): **16 × 16 pixels, 4 interleaved planes = 128 bytes** (64 words: line 0 plane 0–3, line 1 …). Tile n is at `LV_Tiles + n × 128`. `DrawMap` copies each one with a single A→D blit (BLTSIZE `$1001`, D modulo `$32`).

## Map

`LV_Map`: one word per cell, row-major, `MapRowBytes` bytes per row (from `LevelTable`; the value is in bytes, not cells), row pointers at `$48BFA` (up to 26 rows).

| Bits | Meaning |
|---|---|
| 0–11 | tile number |
| 14 | animated tile: bits 0–3 select a routine in `LV_TileAnims` (called while drawing) |
| 15 | solid: the ship and the walkers collide with it (`GetMapCell` tests bit 7 of the high byte) |

Map sizes (tiles): level 1 268 × 13, 2 180 × 13, 3 68 × 26 (the giant battleship: the map is the ship itself), 4 172 × 13, 5 210 × 13, 6 164 × 13, 7 154 × 13, 8 187 × 13. Rendered in full in `gfx/levelN_map.png`.

## BOBs (enemies, shots, explosions)

Drawn with the blitter, cookie-cut, minterm `$CA` (D = A·B + ¬A·C; A = mask, B = graphics, C = background), with A/B shift from x & 15. The data is **interleaved like the screen**: each line holds plane 0–3 of the frame, with one extra word of width for the shift. The **mask** follows the graphics (definition `+$10`) and holds the one-plane mask repeated for each plane line. While an object's hit-flash bit is set, the mask is also used as B, so the whole shape is drawn in colour 15.

The object definition fields that drawing uses (full list in `docs/DATA_FORMATS.md`): `+$00` BLTSIZE, `+$02` C/D modulo, `+$04` bytes per frame, `+$0C` graphics, `+$10` mask offset, `+$14` animation sequence, `+$18` hit boxes.

Example, level 1 definition at `$4BB64`: BLTSIZE `$0D02` (52 lines = 13 × 4 planes, 2 words), modulo `$30`, frame `$D0` bytes (`$68` graphics + `$68` mask), graphics `$6A6D8` (level B).

## Hardware sprites

The ship, the two Bits and the Force are **attached sprite pairs** (16 colours, COLOR16–31 from `SpriteColours`). All eight channels are used:

| Sprite data | Channel | Used for |
|---|---|---|
| `$490A2` | SPR4/5 | upper Bit |
| `$490D6` | SPR4/5 | ship, left half |
| `$49112` | SPR4/5 | lower Bit |
| `$491F2` | SPR6/7 | ship, right half |
| frame in the `$6000` block | SPR0/1 + SPR2/3 | the Force (32 px wide) |

**Sprite data layout** (the same everywhere): control long, h lines of (plane A word, plane B word), end long = 4 + 4h + 4 bytes. The attached partner (planes 2 and 3) follows directly. Colour = 16 + (B1 B0 A1 A0).

- **Ship, Bits:** `CopperInt` copies the current frame into the chained sprite blocks at `$490A2…` (`CopySprite`, the partner block `$A8` bytes on) and writes the positions (`SetSprite`) every frame.
- **Force:** `UpdateForce` doesn't copy. It aims the copper's SPR0–3 pointers straight at the frame in the `$6000` block and animates by moving the pointers.

BPLCON2 = `$24` puts the sprites in front of the playfield.

| Graphics | Frames | Lines | Frame size |
|---|---|---|---|
| Ship `$6000`–`$64FF` | 5 (tilt, 2 = level) | 14 | `$100` (left + right pair) |
| Bits `$6500`–`$69CF` | 11 (spin) | 12 | `$70` (one pair) |
| Force level 0 `$6A40`–`$703F` | 6 | 14 | `$100` |
| Force level 1 `$7040`–`$775F` | 6 | 17 | `$130` |
| Force level 2 `$7760`–`$7E7F` | 6 | 17 | `$130` |
| Force level 3 `$7E80`–`$847F` | 4 | 22 | `$180` |

The Force table is at `$516C` (16 bytes per level: first frame, last frame, frame size, speed, height). Rendered: `gfx/sprites_ship.png`, `sprites_bits.png`, `sprites_force0-3.png`.

## The `$6000` graphics block (tracks 36–62)

No code at all. References confirmed in the code so far:

| Address | Contents | Used by |
|---|---|---|
| `$06000`–`$064FF` | ship sprite frames (5 × `$100`) | `ShipTilt` |
| `$06500`–`$069CF` | Bit sprite frames (11 × `$70`) | `InitBits`, `UpdateBits` |
| `$06A40`–`$0847F` | Force sprite frames, 4 power levels | `UpdateForce` |
| `$15650`, `$15850` | wave cannon beam | `UpdateWaveBeam` |
| `$19B90` | lasers | `UpdateLasers` |
| `$19D90` | enemy bullets | `FireEnemyBullet` |
| `$1C650` | walker | `Walker_Walk` |
| `$2C7B0`–`$2CEB7` | HUD bitplanes (see above) | HUD routines |

The rest is still to be mapped. Most enemy graphics live in each level's B file instead and are reached through the object definitions.

## Level B files

Each decrunched level B file (`$4D300` on) holds, in this order: the tiles, the map, the level's music player and tunes, then the BOB graphics for the level's enemies (reached through the object definitions in level A). Tile counts come from the highest tile number each map uses.

| Level | Tiles (count) | Map (tiles) | Music player | BOB graphics |
|---|---|---|---|---|
| 1 | `$4D300`–`$5AEFF` (440) | `$5AF00` 268×13 | `$5CA38` | `$62DA8`–`$7965A` |
| 2 | `$4D300`–`$5D4FF` (516) | `$5D700` 180×13 | `$5E948` | `$61C96`–`$72579` |
| 3 | `$4D300`–`$5AF7F` (441) | `$62700` 68×26 | `$634D0` | `$66E50`–`$6FCDB` |
| 4 | `$4D300`–`$50EFF` (120) | `$50F00` 172×13 (copied to `$6EA6A`) | `$52078` | `$55378`–`$6EA69` |
| 5 | `$4D300`–`$503FF` (98) | `$50500` 210×13 | `$51A54` | `$54E08`–`$688B7` |
| 6 | `$4D300`–`$59D7F` (405) | `$5B900` 164×13 | `$5C9A8` | `$604B0`–`$6702F` |
| 7 | `$4D300`–`$56FFF` (314) | `$57300` 154×13 | `$582A4` | `$5BCD6`–`$7108E` |
| 8 | `$4D300`–`$5AAFF` (432) | `$5AF00` 187×13 | `$5C1FE` | `$61738`–`$682B7` |

Level 1's tiles end exactly where its map starts, and level 4's where its stored map starts, which confirms the 128-byte tile size. Level 3 has `$5AF80`–`$626FF` (about 30 KB) between its tiles and its map that isn't identified yet. The BOB ranges start at the lowest definition graphics found, so the gap between music player and BOBs holds the music data plus anything not yet mapped.

## Rendered images (`gfx/`)

`tools/render_gfx.py files gfx` regenerates them all from the extracted files:

| File | Contents |
|---|---|
| `levelN_map.png` | the whole level map as the game draws it (level palette) |
| `levelN_tiles.png` | the tile set, 16 per row, in tile-number order |
| `levelN_bobs.png` | one row per object definition found in the level, all its frames (mask applied) |
| `sprites_ship.png`, `sprites_bits.png`, `sprites_force0-3.png` | the hardware sprites, 3× size |

The BOB sheets come from searching level A's DATA for object definitions by their signature (mask offset = half the frame size, modulo = 52 − 2 × width, valid pointers). Frame counts are capped at the next known graphics block. Level 7's definition `$4BE14` (graphics at `$0B440` in the `$6000` block) renders as noise. It's either a false match or uses another palette.

## Title picture (boot)

`files/title_gfx_35fa0.bin`: 320 × 200, **5 planes, not interleaved** (`$1F40` bytes each), followed by an 8 × 8 font (`$3FBE0`, 5 planes × `$180`, character order in `stage2.s` `CharMap`). The 16-colour palette is `TitlePalette` in `stage2.s`. `docs/title.png` is a render of it.
