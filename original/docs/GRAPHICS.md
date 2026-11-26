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

`LV_Map`: one word per cell, `MapWidth` cells per row (from `LevelTable`), row pointers at `$48BFA` (up to 26 rows).

| Bits | Meaning |
|---|---|
| 0–11 | tile number |
| 14 | animated tile: bits 0–3 select a routine in `LV_TileAnims` (called while drawing) |
| 15 | solid: the ship and the walkers collide with it (`GetMapCell` tests bit 7 of the high byte) |

Map widths: level 1 536, 2 360, 3 136 (vertical level), 4 344, 5 420, 6 328, 7 308, 8 374 tiles.

## BOBs (enemies, shots, explosions)

Drawn with the blitter, cookie-cut, minterm `$CA` (D = A·B + ¬A·C; A = mask, B = graphics, C = background), with A/B shift from x & 15. The data is **interleaved like the screen**: each line holds plane 0–3 of the frame, with one extra word of width for the shift. The **mask** follows the graphics (definition `+$10`) and holds the one-plane mask repeated for each plane line. While an object's hit-flash bit is set, the mask is also used as B, so the whole shape is drawn in colour 15.

The object definition fields that drawing uses (full list in `docs/DATA_FORMATS.md`): `+$00` BLTSIZE, `+$02` C/D modulo, `+$04` bytes per frame, `+$0C` graphics, `+$10` mask offset, `+$14` animation sequence, `+$18` hit boxes.

Example, level 1 definition at `$4BB64`: BLTSIZE `$0D02` (52 lines = 13 × 4 planes, 2 words), modulo `$30`, frame `$D0` bytes (`$68` graphics + `$68` mask), graphics `$6A6D8` (level B).

## Hardware sprites

The ship, the two Bits and the Force are **attached sprite pairs** (16 colours, COLOR16–31 from `SpriteColours`) on channels 4–7, with several sprites chained down the screen in the same channel:

| Sprite data | Channel | Used for |
|---|---|---|
| `$490A2` | SPR4/5 | upper Bit |
| `$490D6` | SPR4/5 | ship, left half |
| `$49112` | SPR4/5 | lower Bit |
| `$491F2` | SPR6/7 | ship, right half |

The attached partner of each sprite is `$A8` bytes further on. `CopperInt` copies the current frames in (`CopySprite`) and writes the positions (`SetSprite`) every frame. SPR0–3 are not used. BPLCON2 = `$24` puts the sprites in front of the playfield.

## The `$6000` graphics block (tracks 36–62)

No code at all. References confirmed in the code so far:

| Address | Contents | Used by |
|---|---|---|
| `$06000` + n | ship sprite frames (tilt) | `ShipTilt` |
| `$06500`–`$069D0` | Bit sprite frames | `InitBits`, `UpdateBits` |
| `$06A40` | Force sprite frames | `Force_Idle`, `NewGame` |
| `$15650`, `$15850` | wave cannon beam | `UpdateWaveBeam` |
| `$19B90` | lasers | `UpdateLasers` |
| `$19D90` | enemy bullets | `FireEnemyBullet` |
| `$1C650` | walker | `Walker_Walk` |
| `$2C7B0`–`$2CEB7` | HUD bitplanes (see above) | HUD routines |

The rest is still to be mapped. Most enemy graphics live in each level's B file instead and are reached through the object definitions.

## Title picture (boot)

`files/title_gfx_35fa0.bin`: 320 × 200, **5 planes, not interleaved** (`$1F40` bytes each), followed by an 8 × 8 font (`$3FBE0`, 5 planes × `$180`, character order in `stage2.s` `CharMap`). The 16-colour palette is `TitlePalette` in `stage2.s`. `docs/title.png` is a render of it.
