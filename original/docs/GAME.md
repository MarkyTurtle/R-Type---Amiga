# R-Type (Amiga) – how the game is organised

Findings from the first pass over `src/game.s`. Addresses are absolute.

## The program files

| File | Load | What it is |
|---|---|---|
| `game_low_000a4.bin` (tracks 32–35) | `$000A4` | **The whole engine.** Atari ST style header, TEXT `$000C0–$041B3` (all code), DATA `$041B4–$05C65`, then work space to `$05DE3`. Source: `src/game.s` |
| `game_main_06000.bin` (tracks 36–62) | `$06000` | Graphics and sound data only: no code at all (sprites, bullets, explosions, font, HUD) |
| `shared_4a300.bin` (tracks 63–67) | `$4A300` | Title / high-score data plus the jingle player called at `$4A300`. Overwritten when a level loads |
| `levelN_a_4a2e4.bin` | `$4A2E4` | ST header + level table at `$4A300` + level-specific code and data |
| `levelN_b_4d300.bin` | `$4D300` | Decrunched: tile graphics (from `$4D300`), map, level graphics and the level's music player |
| `music_52300.bin` | `$52300` | Title music: TFMX replay + `smpl` + `mdat` (also extracted separately: `tfmx_player_52300.exe`, `smpl.rtypetitle`, `mdat.rtypetitle`; see `MUSIC.md`) |

### Atari ST heritage

The program and the level A files start with a GEMDOS executable header: `$601A`, then the TEXT, DATA, BSS and symbol sizes and the flags. In `game_low` the TEXT/DATA sizes (`$40F4`/`$1AB2`) match exactly where code stops and data starts. The Amiga version was clearly built from the ST code base, and the credits say "ST graphics by Mark Jones". It also explains the ST-style screen handling, for example the HUD addresses being byte offsets into planar buffers.

## Start-up (`Init`, `$0010E`)

1. Stack at `StackTop` (`$466E`). It stores stage 2's d0–d3 (cache base, cache limit, music copy, current track).
2. `LoadHighScores` (track 68), `FormatScores`, `LoadShared` (tracks 63–67 → `$4A300`).
3. Sets stage 2's fade flag and waits until stage 2's VBL handler has faded the title out.
4. `ClearScreens`, `InitHardware`; installs the interrupt handlers: level 2 = keyboard (`$DE4`), level 3 = VBL + copper (`$20FC`), level 4 = audio (`$3BD6`); copper list `CopperList` (`$52E8`).
5. `TimerCheck` measures with a CIA timer and hangs if the result is out of range. It looks like a speed or tamper check.
6. `TitleSequence`: the attract mode (title letters, "blast off and strike the evil bydo empire!", high-score table, credits) until fire is pressed.
7. `NewGame` → `LoadLevel`.

## Level loading (`LoadLevel`, `$0029A`)

From `LevelTable` (`$41B4`, 10 bytes per level): load part A to `$4A2E4` and part B to `$4CB00`, set `MapWidth` (`$F4`: the map row length in bytes), then `Decrunch` part B to `$4D300`.

### Level interface (`$4A300`)

The first TEXT bytes of each level A file are a table the engine reads directly:

| Addr | Contents |
|---|---|
| `$4A300` | magic `$03011969` (in the shared file this is the jingle player's code) |
| `$4A304` LV_Waves | enemy wave list: `(scroll x.w, wave ptr.l)` |
| `$4A308` LV_Palette | 15 colours |
| `$4A30C` LV_Map | tile map (in level B) |
| `$4A310` LV_Tiles | tile graphics (`$4D300`) |
| `$4A314` LV_ScrollScript | scroll speed script (usually `$4A32C`) |
| `$4A318` LV_TileAnims | animated-tile routines (level 1 only) |
| `$4A31C` LV_MapPatches | map patch list (level 1 only) |
| `$4A320` LV_Frame | level routine called every frame |
| `$4A324` LV_Init | level start routine |
| `$4A328` LV_Music | music player inside level B |
| `$4A32C` | level 8: ending music; levels 1–7: start of the scroll script |

The level code calls back into the engine through the jump table at `$C2–$EA` (ObjInsert, ObjKillSelf, ObjCreate, ObjAlloc, Random, GetMapCell, FireEnemyBullet, DirectionTo, TurnTowards, AddScore, AdjustForScroll) and `$10A` (PlaySound), and it reads the shared variables at `$EE–$109` (ship position, scroll position, map row length…).

| Level | TEXT | DATA | LV_Frame | LV_Init | LV_Music |
|---|---|---|---|---|---|
| 1 | `$15E4` | `$9FA` | `$4B4E0` | `$4B4B2` | `$5CA38` |
| 2 | `$C14` | `$77C` | `$4A784` | `$4A754` | `$5E948` |
| 3 | `$10DC` | `$FB8` | `$4A760` | `$4A700` | `$634D0` |
| 4 | `$13A2` | `$7EE` | `$4B078` | `$4B052` | `$52078` |
| 5 | `$D10` | `$656` | `$4A918` | `$4A916` | `$51A54` |
| 6 | `$A2A` | `$266` | `$4A94C` | `$4A93A` | `$5C9A8` |
| 7 | `$149A` | `$9F8` | `$4B1DA` | `$4B16C` | `$582A4` |
| 8 | `$6B2` | `$6B6` | `$4A420` | `$4A3CE` | `$5C1FE` |

## The frame (`MainLoop` / `GameFrame`)

The main loop calls the routine in `GameState` (fade in → playing → stage clear …), then:

`UpdateScroll` → `DrawMap` (blits the 20×13 visible tiles into the back buffer) → `UpdateShots`, `UpdateWaveBeam`, `UpdateObjects`, `UpdateEnemyBullets`, `UpdateMissiles`, `ShipHitsMap` → `LV_Frame` → `UpdateScore`. It then sets `FrameReady` and waits.

The VBL (`Level3Int`) plays music, sound effects and jingles, reads the joystick (`ShipControl`) and moves the Bits. The **copper interrupt** (`CopperInt`) positions the hardware sprites used for the ship, the Force and the two Bits, and swaps the double buffers (`SwapScreens`: `SCREEN_A` `$2D1BA` / `SCREEN_B` `$3AEBA`) when a frame is ready. Everything else, enemies and shots included, is a blitter BOB drawn with `BlitBob` / `ObjAnimDraw`.

Controls: joystick in port 2. Fire taps for shots; holding fire charges the wave cannon (`ChargeBeam` / `DrawBeamMeter`). Button 2 or **Space** (`ReadFire2`) launches and recalls the Force. **P** pauses (keyboard interrupt).

## Object system

See the comment block in `src/game.s` ("Object system") for the 62-byte object layout and the object-definition layout. There are 40 objects, a free list plus an active list sorted by priority, and each object has its own update routine pointer at `+6`. The level code creates its enemies through `ObjCreate` with a definition pointer.

## The Force (`UpdateForce`)

A state machine in `ForceState` (`$5164`): Idle → Enter (flies on-screen) → Free (floats and tracks the ship's Y) → Return / Attached (front or back, `ForceSide`) → Launched. `ForceLevel` (`$5142`) is the Force's power level, which selects the weapon that `FireForce` uses (reflect, ground and anti-air lasers).

## Hidden trainer

Enter **`sumita.`** as your high-score name. `CheatMode` (`$56FF`) is then set: no score, no lives lost, high scores not saved, and the title's "freeplay" line reads "trainer". The game hides both the name (`$E6EADAD2 >> 1` = "sumi", `$74612E20` = "ta. ") and the string pointer (stored halved). See `St_HighScore`.

## Level code (`src/levels/levelN.s`)

Each level A file is an ST program: a 28-byte header, then TEXT starting at `$4A300` and DATA straight after it. TEXT opens with the level interface table, then the level's data tables (wave list, palette, scroll script), then its code. DATA holds the object definitions, animation sequences and tables that the code and the engine's object system use. Whatever follows DATA in the file is unused padding to the track boundary.

| Level | TEXT tables | Code | DATA |
|---|---|---|---|
| 1 | `$4A300–$4A74D` | `$4A74E–$4B8E3` | `$4B8E4–$4C2DD` |
| 2 | `$4A300–$4A537` | `$4A538–$4AF13` | `$4AF14–$4B68F` |
| 3 | `$4A300–$4A6FF` | `$4A700–$4B3DB` | `$4B3DC–$4C393` |
| 4 | `$4A300–$4AA23` | `$4AA24–$4B6A1` | `$4B6A2–$4BE8F` |
| 5 | `$4A300–$4A807` | `$4A808–$4B00F` | `$4B010–$4B665` |
| 6 | `$4A300–$4A939` | `$4A93A–$4AD29` | `$4AD2A–$4AF8F` |
| 7 | `$4A300–$4A927` | `$4A928–$4B799` | `$4B79A–$4C191` |
| 8 | `$4A300–$4A3CD` | `$4A3CE–$4A971` | `$4A972–$4B067` (table at `$4A972`) |

The code was found by tracing from `LevelInit` and `LevelFrame` and from every pointer in DATA (enemy update and spawn routines are only reached that way). Levels 1, 4, 5 and 6 also contain a few routines that nothing calls: dead code left in the build. They are kept as code in the sources.

Engine calls in the level sources use the names in `src/engine.i` (for example `jsr (jt_ObjCreate).w`, `move.w (ShipPos).w,d0`).

## Shared title file (`src/shared.s`)

`$4A300–$4A615` is a small position-independent sample sequencer (`JinglePlayer`) that drives all four audio channels; `$4A616` on is its state and data: the jingle sequence, `NoteTable` (`$4A78E`), `SampleTable` (`$4B430`), `PeriodTable` (`$4B480`) and the 8-bit samples (`$4B4D6` on). The engine calls it from the VBL (`UpdateJingle`) for the title and high-score screens. The in-game music players are separate: each one sits in its level's part B and is reached through `LV_Music`.

## Still to do

- Comment `src/game.s` routine by routine; name the remaining `L_`/`D_` labels.
- Give the level objects their R-Type names (the `Def_`/`Upd_`/`Spawn_` labels are structural) and comment the enemy and boss behaviours.
- The small frames at `$08480`–`$0873F`, the beam/laser/bullet/missile frame sizes, level 3's unidentified 30 KB.
- The in-game music data per level, the level 8 ending music, and disassembling the TFMX replay.
