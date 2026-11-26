# R-Type (Amiga) – what's left to do

State on 26 Nov 2026. All 12 sources reassemble byte-identical (`tools/verify.py`). Each item says where to start. Ticked items are done and kept for reference.

## 1. The game program (`src/game.s`)

- [ ] **Line-by-line comments.** Done for the core (`MainLoop`, the game states, `GameFrame`, `Level3Int`, `SwapScreens`, `SetBitplanes`, `UpdateScroll`, `UpdateObjects`, `ObjExplode`). Also done: `CopperInt`, `ShipControl`/`ShipTilt`, collisions (`ObjCollisions`, `HitByShots`, `BoxTest`, `ObjDamage`), with block comments for the Force states, `FireForce`, the fly-in and autopilot. Also block comments for the Bits and the homing missiles. Also the three lasers (`UpdateLasers`, `UpdateAntiAirLaser`), the missile states and power-up collection. Also the attract mode (state machine, title letters, name entry).
- [ ] **Name the remaining labels**: 88 `L_`/`D_` labels left. `tools/xref.py src/game.s` lists who reads and writes each one; `tools/add_labels.py` inserts labels by address safely.
- [ ] **Variables in `DATA`**: 48 named this round (frame pacing, scroll, ship, Bits, Force animation, wave beam). Still unnamed: the missile arrays (`$556C`–`$55AA`), Force state bytes (`$5143`–`$514B`), title variables (`$56F2`–`$56FE`), death/level counters (`$4209`–`$420D`).
- [ ] **Remaining first-pass artefacts**: check other `dc.l L_xxxxx` / immediates the generator turned into labels when they're really numbers (two blit sizes in `ShotTypes` were found and fixed).
- [x] **Frame pacing**: the game is locked to 25 Hz (`Flip50Hz` clear); the ship and Bits move at 50 Hz from the VBL. See `GAME.md`.
- [ ] **`TimerCheck`**: work out what the CIA timer measurement guards against (speed check or anti-tamper) and why it hangs above `$CCDD`.
- [x] **Title / attract sequence**: states renamed to what they show, title letters, text lists, name entry commented; the Amiga team credits documented in `GAME.md`.
- [x] **Force behaviour**: state machine, docking, launching and weapon selection commented (`GAME.md`).
- [x] **Bits**: trailing movement via a position ring buffer (`UpdateBits`).
- [x] **Homing missiles**: launch, forward, seek (nearest enemy above/below) and home states commented.
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
- [ ] **High-score saving**: the rebuilt ADF has a valid track 68; test that scores save and reload.
- [x] **Rebuild a disk**: `tools/build_disk.py` writes an extended ADF from `files/` or from the sources (`--from-source`), self-verified by decoding every track.
- [ ] **Boot the rebuilt ADF in WinUAE** (A500 512K and 1 MB) and play through; test high-score saving on it.

## 6. Tooling

- [x] **Build**: `tools/build_disk.py --from-source` assembles every source into a disk image (`tools/verify.py` checks them against `files/`).
- [x] **Cross-reference**: `tools/xref.py` (which routines read/write each label).
- [ ] Retire `work`-style one-off generators once all sources are hand-maintained (`bootstrap_source.py`, `gen_source.py`, `trace68k.py` are kept only for reference).
