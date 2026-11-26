# R-Type (Amiga) – data formats

The level files, map, scrolling, waves and objects. Disk and track formats are in `DISK_FORMAT.md`, graphics in `GRAPHICS.md` and music in `MUSIC.md`. The same notes are in the sources as comments.

## Program and level files: Atari ST headers

`game_low_000a4.bin` and every `levelN_a_4a2e4.bin` start with a GEMDOS executable header:

```
+$00 $601A   +$02 TEXT size   +$06 DATA size   +$0A BSS size   +$0E symbols
+$12 reserved   +$16 flags (game: $000000C0)   +$1A $0001 (absolute)
```
TEXT starts right after it (`$C0` / `$4A300`), and DATA follows TEXT.

## Level table (`LevelTable`, `$41B4`, in the engine)

8 × 10 bytes: `track.w, count.w` (part A → `$4A2E4`), `track.w, count.w` (part B, crunched → `$4CB00`, decrunched to `$4D300`), `map row length.w` in **bytes**, 2 per cell (→ `MapWidth`, which is also the low word of `MapRowBytes`).

## Level interface (`$4A300`, start of each level's TEXT)

| Addr | Equate | Contents |
|---|---|---|
| `$4A300` | – | magic `$03011969` |
| `$4A304` | `LV_Waves` | → checkpoint list |
| `$4A308` | `LV_Palette` | → 15 colours (COLOR01–15) |
| `$4A30C` | `LV_Map` | → map (level B) |
| `$4A310` | `LV_Tiles` | → tiles (level B, `$4D300`) |
| `$4A314` | `LV_ScrollScript` | → scroll script |
| `$4A318` | `LV_TileAnims` | → table of animated-tile routines |
| `$4A31C` | `LV_MapPatches` | → map patch list, or 0 |
| `$4A320` | `LV_Frame` | → routine called every frame |
| `$4A324` | `LV_Init` | → routine called at (re)start |
| `$4A328` | `LV_Music` | → music player (level B) |
| `$4A32C` | `LV_EndMusic` | level 8: → ending music; levels 1–7: start of the scroll script |

## Checkpoint list (`LV_Waves`)

6-byte entries `scroll x.w, wave list.l`, highest x first, ending with the x = 0 entry (level start). When the ship respawns, `InitLevelScroll` takes the first entry at or below `Checkpoint`. It sets `ScrollX` from that entry and continues the wave list from its pointer.

| Level | Checkpoints (scroll x) |
|---|---|
| 1 | 2440, 1184, 165, 0 |
| 2 | 1138, 0 |
| 3 | 0 |
| 4 | 1185, 0 |
| 5 | 1540, 0 |
| 6 | 1407, 0 |
| 7 | 1132, 0 |
| 8 | 0 |

## Wave list

`$12`-byte entries, read by `SpawnWaves` once per frame:

| Offset | Contents |
|---|---|
| `$00.w` | trigger: scroll x (level 3 uses a frame counter instead) |
| `$02.w`, `$04.w` | x, y |
| `$06`–`$0D` | parameters for the spawn routine (count, spacing, type… per level) |
| `$0E.l` | object definition (negative → engine default `$051FC`) |

The definition's **spawn routine** (`+$20`) is called with a1 = the wave entry and a2 = the definition. It creates the objects (usually through `jt_ObjCreate`).

## Scroll script (`LV_ScrollScript`)

6-byte entries `x speed.w, y speed.w, duration.w` (frames). When an entry runs out, the next one is loaded. If the entry *after that* has a negative duration, the current one repeats for ever: that's the end marker. Levels 1, 2, 4–8 just use `(11, 0, 100), (0, 0, −1)`: a steady 1 pixel a frame. Level 3, the giant battleship, also moves vertically: its map is the battleship itself.

Speeds index the table at `$48E9`:

| n | Movement |
|---|---|
| 0 | stopped |
| 1–10 | 1 pixel every 12 − n frames |
| 11 | 1 pixel a frame |
| 12, 13, 14 | 2, 3, 4 pixels a frame |
| negative | the same, the other way |

## Map patches (`LV_MapPatches`)

`x.w, y.w, tile.w` … until x < 0. They are written into the map at level start (level 1 only).

## Map cells and tiles

See `GRAPHICS.md`: one word per cell (tile number, animated flag, solid flag), 16 × 16 four-plane interleaved tiles of 128 bytes. Each map is 13 rows (level 3: 26), row-major, `MapRowBytes` bytes per row. Level 4 keeps its map at `$50F00` and its `LevelInit` copies it to `$6EA6A` at every (re)start, because the level code changes the map while it plays.

## Objects

40 objects of `$3E` bytes at `$4935A`, a free list and an active list sorted by priority. Each object has its own update routine.

| Offset | Contents |
|---|---|
| `$00.l` | next |
| `$04.b` | priority |
| `$05.b` | state: 0 alive, 1 start explosion, `$FF` exploding |
| `$06.l` | update routine (0 = none) |
| `$0A.w`, `$0C.w` | x, y |
| `$0E.l` | current frame graphics |
| `$12.l` | definition |
| `$16`–`$1C` | hit box (from the definition) |
| `$1E.w` | animation index |
| `$20.b` | animation timer |
| `$21.b` | explosion type / timer |
| `$22.b` | advance the animation |
| `$23.b` | flags: 0 hit flash, 1 carries a power-up, 2 no collisions, 3 is a power-up |
| `$24.w` | hit points (−1 = indestructible) |
| `$26.w` | damage taken |
| `$28.b` | hit-flash timer |
| `$2A.l` | animation sequence |
| `$2E.w`, `$30.w` | fire rate, fire timer |
| `$32`– | free for the object's routine |

### Object definition (`$28` bytes)

| Offset | Contents |
|---|---|
| `$00.w` | BLTSIZE (lines × 4 planes, width in words incl. shift word) |
| `$02.w` | C/D modulo (52 − width × 2) |
| `$04.w` | bytes per frame (graphics + mask) |
| `$07.b` | frames per animation step |
| `$08.w` | hit points |
| `$0A.w` | fire rate (0 = doesn't fire; a random 0–74 is added) |
| `$0C.l` | graphics, frame 0 |
| `$10.l` | mask offset from the graphics |
| `$14.l` | animation sequence: frame numbers (bytes), negative = back to the start |
| `$18.l` | hit boxes, 4 words per frame |
| `$1C.l` | update routine |
| `$20.l` | spawn routine (wave lists) |
| `$24.l` | score, BCD (e.g. `$500` = 500); added by `ObjDamage` when the object is destroyed |

### Definitions in the sources

Every definition found is labelled in the sources:
- **Labels:** `Def_xxxxx` in the level files; `DefExplosion1`, `DefPowArmor`, `DefPowerUp`… in `game.s`.
- **Summary comment:** size, frame count, graphics address, hit points, fire rate and score.
- **Routines:** each update routine is labelled `Upd_xxxxx` and each spawn routine `Spawn_xxxxx`. Several definitions often share one update routine with different graphics: level 2's three 32-pixel enemies all use `Upd_4AA08`.

They were found by signature (mask offset = half the frame size, modulo = 52 − 2 × width, valid pointers), and their frames are in `gfx/levelN_bobs.png` in the same order.

## High scores

`HighScores` (`$575C`, `$64` longs). The table is saved to track 68 (format in `DISK_FORMAT.md`). The entries are formatted for display by `FormatScores` and changed by `InsertScore` / `EnterName`. The hidden "sumita." trainer name is checked in `St_HighScore`.

## Level B layout

`tools/levelb_layout.py` maps every level B file (the full listing is in [levelb_layout.txt](levelb_layout.txt)). In address order each holds:

1. **Tiles** from `$4D300` (`LV_Tiles`). Most levels have a few more tiles than their stored map uses (level 2: 4, level 5: 2, level 6: 55, level 7: 6, level 8: 8); level 3 has 239 more, which `PatchMap` writes into the map.
2. **The map** (`LV_Map`; level 4's is copied to `$6EA6A` by `LevelInit`).
3. **The music player** (`LV_Music`): code, its variables, songs and patterns, then the sample and period tables and the samples. Level 8 has a second player for the ending.
4. **BOB graphics** for the level's object definitions, one block per definition, with more frames than the first animation sequence shows (e.g. the Gouger's 8 frames are four wall corners × 2).
5. **Movement tables** at the end, read by the level code with absolute addresses: wave paths, jump arcs, the Compiler's section paths, the Worm's and the Zoids' paths.

Apart from these only a few small gaps are left (at most 240 bytes, between the last BOB frames and the tables, or padding after the samples).

## Wave parameters by object

Every wave entry is `trigger.w, x.w, y.w`, 8 bytes of parameters (`$06`–`$0D`) and the definition. What the spawn routines read from the parameters (objects not listed use only x and y):

| Object (levels) | Parameters |
|---|---|
| POW Armor (all) | `$07.b` the power-up it carries, `$09.b` direction (signed x step) |
| Pata-Pata (1, 4, 7) | `$06.l` group list: per fighter y.w, delay.b, start frame.b; `$FFFF` ends |
| Bug (1, 4, 7) | `$06.l` path: steps.w, then dx, dy and frame tables (signed bytes, level B); `$0A.w` number − 1; `$0C.w` extra x speed |
| Bink (1, 4, 6, 7) | `$06.w` walking step (signed: direction) |
| Cancer (1, 4, 5, 7) | `$06.w` scroll x after which it stops chasing the ship and leaves, `$08.w` frames between them, `$0A.l` list of x, y; `$FFFF` ends |
| Gouger (2) | `$06.w` corner 0–3 (which wall it clings to, and its frames) |
| Wick (2) | `$06.w` number − 1 |
| Gun tower (3) | `$06.w` non-zero = upside down, `$08.w` hit points |
| Cannon pod (3) | `$09.b` hits to destroy it, `$0A.l` its animation |
| Cytron (4) | `$06.w` dx, `$08.w` dy (both also pick its frame), or `$0A.l` a path like the Bug's |
| Geld (4) | `$06.w` starting direction 0–3 (up, right, down, left), `$08.w` scroll x after which it stops turning |
| Slither (5) | `$06.w` body segments, `$08.w` copied to every segment (`$34`) |
| Pursuer (5) | `$06.w` starting direction (0–15) |
| Mid-phase Cheetah (5) | `$06.w` number − 1, `$08.w` random y range, `$0A.w` lowest y |
| Dop (6) | from `$06`: its route, bytes - first the start direction, then a direction change at each junction |
| Capsule (6) | `$06.l` list of modes (animation, duration, direction) |
| Collapse (7) | `$02.l` (x, y), `$06.w` offset of its map cells, `$08.w` which rubble block, `$0A.w` non-zero = taller |
| Crawler (7) | `$06.w` y step towards the floor or ceiling |
| Win (8) | `$06.w` starting direction |

In the sources the parameter lists that live in the level files are labelled `<Object>Data<n>` and laid out one entry per line.
