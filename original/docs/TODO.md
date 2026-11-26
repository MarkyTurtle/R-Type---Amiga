# R-Type (Amiga) – what's left to do

State on 26 Nov 2026. All 12 sources reassemble byte-identical (`tools/verify.py`). Each item says where to start. Ticked items are done and kept for reference.

## 1. The game program (`src/game.s`)

- [ ] **Line-by-line comments.** Routines are named and grouped and the formats are commented, but most instructions aren't explained yet. Suggested order: main loop and frame (`MainLoop`, `GameFrame`, `Level3Int`, `CopperInt`), then the object system, collisions, weapons, the Force, the title sequence.
- [ ] **Name the remaining labels**: 174 `L_`/`D_` labels left (`tools/add_labels.py` inserts labels by address safely).
- [ ] **Variables in `DATA`**: many `D_0xxxx` variables between `$41B4` and `$5C66` are still unnamed (ship state `$50EE–$5160`, Force state, shot arrays at `$4B5x–$4BAx`, the title variables at `$56xx`).
- [ ] **Remaining first-pass artefacts**: check other `dc.l L_xxxxx` / immediates the generator turned into labels when they're really numbers (two blit sizes in `ShotTypes` were found and fixed).
- [ ] **Frame pacing**: what selects 25 Hz vs 50 Hz screen flipping (`D_05136`, `D_0513C` in `SwapScreens`).
- [ ] **`TimerCheck`**: work out what the CIA timer measurement guards against (speed check or anti-tamper) and why it hangs above `$CCDD`.
- [ ] **Title / attract sequence**: comment the title-letter objects, the text lists (`TitleTextList`) and the high-score name entry.
- [ ] **Bits and Force behaviour in detail**: the Force state machine is named; the movement, collision and weapon selection (`FireForce`, Force levels 0–3) need comments.
- [ ] **Homing missiles**: `UpdateMissiles` and the `Missile_*` states (how targets are picked).
- [ ] **Walker AI** (`ObjUpd_Walker`, `Walker_Walk`) and the power-up carrier (`ReleasePowerUp`).
- [ ] **Map cell bits 12–14**: confirm the destructible-block and "hit" behaviour against the level tile routines.

## 2. Level code (`src/levels/level1-8.s`)

- [ ] **Name the objects**: the 73 `Def_xxxxx` definitions and their `Upd_`/`Spawn_` routines have structural names only. Give them their R-Type names (Patapata, Bink, Cancer, Pow Armor, Gains, Dobkeratops…) by matching against `gfx/levelN_bobs.png`, ideally with an object gallery (one image per definition, see below) to check each name.
- [x] **Object gallery** (`docs/OBJECTS.md`): one picture per definition with its stats and routines. Fill in the Name column (`NAMES` in `tools/object_gallery.py`).
- [ ] **Comment the enemy and boss behaviours**: movement, firing, hit boxes, the bosses' multi-part structure (e.g. level 4's 96×81 / 112×58 / 96×68 pieces).
- [ ] **Level start / per-frame routines** (`LevelInit`, `LevelFrame`) for each level.
- [ ] **Wave lists**: decode the per-wave parameters (`$06`–`$0D`), which differ per spawn routine.
- [ ] **Tile animation routines** (`LV_TileAnims`, level 1) and **map patches**.
- [ ] **Level 3** (the battleship): how its 26-row map moves and how its parts are destroyed.
- [ ] **Unnamed labels**: 52–215 per level.

## 3. Data and assets

- [x] **Level 3's 30 KB**: 239 more tiles (441–679: flames, explosions, battleship parts) not placed in the stored map.
- [ ] **How level 3 uses tiles 441–679** (written into the map or drawn by its code).
- [ ] **Level B layout**: between each music player and its first BOB graphics lie the songs, patterns, sample and period tables and samples (located per player in `MUSIC.md`); check nothing else is there.
- [ ] **HUD**: the score/lives/beam-meter layout in the 3-plane HUD and the font used (`DigitFont`, `DrawChar`, `$2CEB8`).
- [ ] **Extract the HUD and the title-screen graphics** to PNG.
- [ ] **Map editor-style export**: per-level maps with solid, destructible and animated cells marked (overlay on `levelN_map.png`).
- [x] Tiles, maps, BOBs, sprites, shots and weapons rendered to `gfx/`; the `$6000` block mapped end to end.
- [x] Sound effects decoded and extracted to `sfx/`.

## 4. Music

- [x] **In-game music data**: sample, period and data tables located for all 9 players; 73 samples extracted to `music/`.
- [ ] **Song and pattern tables per player**: list each player's songs (d4 command) and pattern table addresses.
- [ ] **Convert the in-game songs** to something playable (e.g. MIDI or a ProTracker module) as a check on the format.
- [x] **Level 8's ending music**: a third player variant with 32-row (`$82`) patterns.
- [ ] **The music players' command interface** (d0/d4 commands, fades) as used by `UpdateMusic` / `UpdateJingle`.
- [ ] **Disassemble the TFMX replay** (`files/tfmx_player_52300.exe`) or confirm it matches a known TFMX version.
- [ ] **Test** `mdat.rtypetitle` + `smpl.rtypetitle` in a TFMX player (UADE / DeliTracker).

## 5. Boot and disk

- [x] Bootblock and stage 2: fully annotated.
- [ ] **High-score saving**: test writing track 68 in WinUAE with a writable disk image.
- [ ] **Rebuild a disk**: write a tool that builds an IPF-independent disk image (ADF or custom-format MFM) from `files/` and the sources, as a first step towards an enhanced build (as with GnG/NZS).

## 6. Tooling

- [ ] **Makefile / build script** that assembles every source and rebuilds `files/` from them.
- [ ] **Listing-based cross-reference** (which routines read and write each variable) to speed up naming.
- [ ] Retire `work`-style one-off generators once all sources are hand-maintained (`bootstrap_source.py`, `gen_source.py`, `trace68k.py` are kept only for reference).
