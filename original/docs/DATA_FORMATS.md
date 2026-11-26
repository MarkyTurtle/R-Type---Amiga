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
| `$24` | score / other (still to confirm) |

## High scores

`HighScores` (`$575C`, `$64` longs). The table is saved to track 68 (format in `DISK_FORMAT.md`). The entries are formatted for display by `FormatScores` and changed by `InsertScore` / `EnterName`. The hidden "sumita." trainer name is checked in `St_HighScore`.
