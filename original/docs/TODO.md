# R-Type (Amiga) – what's left to do

State on 26 Nov 2026. All 12 sources reassemble byte-identical (`tools/verify.py`). Each item says where to start. Ticked items are done and kept for reference.

## 1. The game program (`src/game.s`)

- [x] **Comments**: every routine in `game.s` has a header or block comment; line comments on the core loop, game states, interrupts, scrolling, objects, collisions, the ship, weapons, missiles and the anti-air laser. (More line comments can always be added inside the longer routines.)
- [x] **Name the remaining labels**: all `L_`/`D_` labels in `game.s` are named (the levels still have theirs).
- [x] **Variables in `DATA`**: all named (the missile arrays, Force state bytes, title variables and death/level counters included).
- [x] **First-pass artefacts**: the 16 `dc.l` values the generator had turned into code labels are numbers again (mask offsets, frame sizes, ground-laser moves, the copper list, the high-score table). The copper list is one instruction per line, the high-score table one entry per line.
- [x] **Frame pacing**: the game is locked to 25 Hz (`Flip50Hz` clear); the ship and Bits move at 50 Hz from the VBL. See `GAME.md`.
- [x] **`PalCheck`** (was `TimerCheck`): times one frame with CIA-A timer B against the TOD (vertical sync) counter; an NTSC frame is too short, so the game hangs on NTSC machines when a game starts. Still to confirm in WinUAE with an NTSC configuration.
- [x] **Title / attract sequence**: states renamed to what they show, title letters, text lists, name entry commented; the Amiga team credits documented in `GAME.md`.
- [x] **Force behaviour**: state machine, docking, launching and weapon selection commented (`GAME.md`).
- [x] **Bits**: trailing movement via a position ring buffer (`UpdateBits`).
- [x] **Homing missiles**: launch, forward, seek (nearest enemy above/below) and home states commented.
- [x] **POW Armor** (was the "walker"): the default wave object and power-up carrier. Its jump/slide/walk states, jump arc and animations, and `ReleasePowerUp`, are commented.
- [x] **Map cell bits 12–15**: what each weapon does with them, confirmed in the engine and level 1's tile routine (`DrawMap` comment, GRAPHICS.md).

## 2. Level code (`src/levels/level1-8.s`)

- [x] **Name the objects**: all 8 levels (GAME.md, *The stages*). Uncertain: Bug (level 1), the rear tower (3), Pursuer (5), the Capsule (6), the Crawler and the Sonar (7).
- [x] **Object gallery** (`docs/OBJECTS.md`): one picture per definition with its stats and routines. Labels are read from the sources.
- [x] **Comment the enemy and boss behaviours**: a header comment for every enemy and boss in all 8 levels. Line comments inside the level routines are still sparse: movement, firing, hit boxes, the bosses' multi-part structure (e.g. level 4's 96×81 / 112×58 / 96×68 pieces).
- [x] **Level start / per-frame routines** (`LevelInit`, `LevelFrame`): commented for every level (the boss sequences, the battleship, the ending).
- [x] **Wave lists**: one entry per line with the definition names (`tools/format_waves.py`); the parameters of every object in DATA_FORMATS.md; the parameter lists in the level files labelled and laid out (Pata-Pata groups, Bug and Cytron paths, Cancer positions).
- [x] **Tile animation routines** (`LV_TileAnims`, level 1) and **map patches**: level 1's are the Blasters, gun batteries built into the map.
- [x] **Level 3** (the battleship): the scroll script moves the 26-row map in x and y; parts are map cells patched in and out (`PatchMap`) plus invisible targets that follow the scroll. Still to check: the exact stage list of the rear tower.
- [x] **Unnamed labels**: none left in the level files or `game.s` (`tools/localise_labels.py` turns branch labels local, `tools/format_waves.py` lays out the wave lists). `shared.s` and `stage2.s` are fully named too.
- [x] **Code hidden as data**: level 4's Geld routines, reached only through a pointer table, are code again.

## 3. Data and assets

- [x] **Level 3's 30 KB**: 239 more tiles (441–679: flames, explosions, battleship parts) not placed in the stored map.
- [x] **How level 3 uses tiles 441–679**: they are written into the map by `PatchMap` - 64 blocks in level 3's data use 237 of the 239 (gun mounts, the engine flame, the core chamber, wrecks).
- [x] **Level B layout**: tiles, map, music player and samples, BOB graphics, movement tables - `tools/levelb_layout.py`, `docs/levelb_layout.txt`, DATA_FORMATS.md.
- [x] **HUD**: the score/lives/beam-meter layout in the 3-plane HUD and the font used (`DigitFont`, `DrawChar`, `$2CEB8`).
- [x] **Extract the HUD and the title-screen graphics** to PNG: `gfx/hud.png`, `gfx/font_game.png`, `gfx/font_digits.png` (`tools/render_hud.py`); the title picture is `docs/title.png`.
- [x] **Map flag overlays**: `gfx/levelN_flags.png` (solid / destructible / animated), made by `tools/render_gfx.py`.
- [x] Tiles, maps, BOBs, sprites, shots and weapons rendered to `gfx/`; the `$6000` block mapped end to end.
- [x] Sound effects decoded and extracted to `sfx/`.

## 4. Music

- [x] **In-game music data**: sample, period and data tables located for all 9 players; 73 samples extracted to `music/`.
- [x] **Songs per player**: two tunes (level, boss) and three jingles; every player's song and pattern addresses in MUSIC.md.
- [x] **Convert the in-game songs**: `tools/render_music.py` runs the players in a 68000 emulator and mixes the Paula output; `music/songs/*.mp3`. 
- [ ] (Low priority) **ProTracker conversion** of the songs, to edit them in a tracker.
- [x] **Level 8's ending music**: a third player variant with 32-row (`$82`) patterns.
- [x] **The music players' command interface**: MUSIC.md, *Commands*.
- [x] **Which TFMX**: the original TFMX format (ExoticA lists R-Type with Turrican and X-Out, before TFMX Pro); its archive has the tune as mdat.title / smpl.title (not compared byte for byte).
- [ ] (Optional) **Disassemble the TFMX replay** (`files/tfmx_player_52300.exe`) as a source of its own.
- [x] **Test the TFMX data**: the game's own replay plays it in the emulator (`music/songs/title.mp3`). (Not yet tried in UADE / DeliTracker.)

## 5. Boot and disk

- [x] Bootblock and stage 2: fully annotated.
- [ ] **High-score saving**: the rebuilt ADF has a valid track 68; test that scores save and reload.
- [x] **Rebuild a disk**: `tools/build_disk.py` writes an extended ADF from `files/` or from the sources (`--from-source`), self-verified by decoding every track.
- [ ] **Boot the rebuilt ADF in WinUAE** (A500 512K and 1 MB) and play through; test high-score saving on it.

## 6. Tooling

- [x] **Continuous build**: a GitHub Action assembles and verifies the sources and publishes the ADF built from them.
- [x] **Build**: `tools/build_disk.py --from-source` assembles every source into a disk image (`tools/verify.py` checks them against `files/`).
- [x] **Cross-reference**: `tools/xref.py` (which routines read/write each label).
- [ ] Retire `work`-style one-off generators once all sources are hand-maintained (`bootstrap_source.py`, `gen_source.py`, `trace68k.py` are kept only for reference).

## 7. Enhanced version (`enhanced/`, later)

The `original/` sources stay byte-identical; changes go in a separate `enhanced/` tree.

### A normal AmigaDOS disk

Replace the custom-track loader with one that reads a standard AmigaDOS (11-sector, `$4489`) disk that has a proper file system, so the disk can be copied, browsed and checked with ordinary tools.

- [ ] **Loader**: use the 4489 byte loader from [MarkyTurtle/infinitedreams](https://github.com/MarkyTurtle/infinitedreams) (`src-singledisk/demo-redux/4489Loader/`: disassembled, TOD-timed fork of [4489/4489_byteloader](https://github.com/4489/4489_byteloader)).
  - Interface: d0 = disk offset, d1 = length, d2 = drive, a0 = destination, a1 = MFM buffer. It returns d0 = 0 on success.
  - It needs `$1760` words of MFM buffer. The game's `TRACK_BUFFER` at `$7C400` has room (`$7C400`–`$7F2C0`); check nothing else uses that area while loading.
- [ ] **Compress the files with ZX0.** The files don't fit on an 880K disk as they are. The custom tracks hold about 987K, which is why the original uses long tracks.
  - Use the 68000 ZX0 decompressor already in infinitedreams (`src-singledisk/demo-redux/zx0/unzx0_68000.s`, Emmanuel Marty, 88 bytes; a0 = packed data, a1 = destination). Pack with [salvador](https://github.com/emmanuel-marty/salvador) `-classic`.
  - Measured with salvador (track padding trimmed, level B files packed from their unpacked form):

    | | on disk now | ZX0 |
    |---|---:|---:|
    | bootblock (stays unpacked) | 1,024 | 1,024 |
    | title picture | 41,920 | 17,846 |
    | stage 2 | 5,184 | 1,817 |
    | music (`$52300`) | 131,296 | 92,982 |
    | game program | 23,872 | 13,030 |
    | `$6000` block | 161,136 | 77,918 |
    | shared file | 32,760 | 11,463 |
    | level A files (8) | 78,624 | 25,887 |
    | level B files (8; now ByteKiller) | 511,056 | 334,246 |
    | **total** | **986,872** | **576,213** |

  - The total of about 576K leaves roughly 300K free on an FFS disk (about 869K of file space). ZX0 also beats the original ByteKiller packing of the level B files by about 35%.
  - **Where to unpack.** ZX0 unpacks forwards, the opposite of the original's backwards `Decrunch`, so the in-place trick changes:
    - Load the packed data at the *end* of the destination area plus salvador's safety margin and unpack forwards. Or use salvador's backwards mode (`-b`, which needs the backwards 68000 decompressor) to keep the original's layout.
    - Check memory per file. Level B now loads at `$4CB00` and unpacks to `$4D300`, ending at up to `$7975B`, close to `TRACK_BUFFER` at `$7C400`.
  - Time how long the 68000 takes to unpack the largest files (`$6000` block, level B) on an A500 against the original load times.
- [ ] **File-system layout**: make an **FFS** disk (`DOS\1`) with each file in **contiguous** blocks.
  - FFS data blocks hold 512 bytes of plain data, with no 24-byte header as on OFS. A contiguous file can therefore be read directly by the byte loader at a known disk offset, with no file-system code in the game.
  - Have the build tool write the disk and an offset/length table that the loader assembles in.
  - Optionally add a small root-directory/file-header lookup instead, so the files can be replaced without rebuilding.
- [ ] **Patch the load calls** in the bootblock, stage 2 (title, music, game program, `$6000` block, shared file) and `LevelTable`/`LoadLevel` (level A/B by track) to use file offsets instead of track numbers.
- [ ] **Bootblock**: a standard `DOS\1` bootblock that loads stage 2 with the byte loader (or through trackdisk.device before taking over the machine).
- [ ] **Saving high scores**: use the **Rob Northen disk routines** for the write.
  - The byte loader is read-only.
  - Writing to an AmigaDOS disk means MFM-encoding and writing a whole 11-sector track, or reading, modifying and rewriting the sector.
  - Keep the high-score table as a one-block file in a fixed place, so the save never touches the file system's bitmap or directory.
  - Keep the checksum check so a bad or missing table falls back to the default.
- [ ] **Build**: extend `build_disk.py` (or add an `enhanced` mode) to write a plain ADF and verify it, and test it in WinUAE on a 512K A500 and with more memory.

### Display and drawing speed-ups (as in GnG and NZS)

The enhanced version doesn't need to keep the original memory layout, so the display code can be rebuilt freely: move buffers, code and data wherever suits.

**What the original already does.** The cheap wins are already taken:
- The playfield is **interleaved** (4 planes, 52 bytes each, `$D0` per line).
- BOBs are **pre-masked**: the mask is stored once per plane line, so each BOB is a single cookie-cut blit (`ObjAnimDraw`, minterm `$CA`).

**The big cost is elsewhere.** `DrawMap` redraws the whole 20 × 13 tile background, about 260 small A→D blits plus CPU set-up, into the back buffer every frame. That redraw is also how the BOBs get erased, and it's probably why the game is locked to 25 Hz.

- [ ] **Double-buffered corkscrew scroll with a pristine buffer** (as in GnG and NZS):
  - Keep a pristine background buffer and two display buffers that scroll by moving the bitplane pointers. Each frame draws only the newly exposed column of tiles (or part of it), into all three buffers.
  - Erase BOBs by copying their rectangles back from the pristine buffer. This replaces the full-screen tile redraw.
  - Handle the wrap at the end of the buffer (the corkscrew), and `BPLCON1` fine scroll.
- [ ] **Vertical scrolling**: `UpdateScroll` also moves `ScrollY`/`FineScrollY` (maps up to 26 rows, 13 visible).
  - Either make the buffers tall enough for the whole map height and scroll vertically by pointer (check chip memory for three such buffers on 512K), or wrap vertically as well, with a copper split.
- [ ] **Map changes go to the pristine buffer too**: tile animations (`LV_TileAnims`), destructible blocks (map bit 12) and map patches must redraw their tile into the pristine buffer and both display buffers.
  - Treat level 3 (the battleship) and level 4 (map copy) separately.
- [ ] **50 Hz**: with the background no longer redrawn, try unlocking the 25 Hz frame rate.
  - As in GnG: run at 50 fps, dropping to 25 in busy scenes.
  - Or as in NZS: keep the logic at 25 Hz and draw interpolated in-between frames.
  - The ship and the Bits already move at 50 Hz from the VBL.
- [ ] **BOB blits**:
  - Skip the extra shift word when x is word-aligned.
  - Clip at the screen edges instead of relying on the 96-pixel margin, which costs memory in every buffer.
  - Sort or batch blits to cut `WaitBlit` stalls, and set up the next blit while the blitter runs.
  - Check whether any BOBs (shots, bullets) would be cheaper as hardware sprites or multiplexed sprites.
- [ ] **Memory detection** (as in GnG and NZS): find the RAM configuration at boot.
  - Move code and data out of chip RAM where possible, so the extra buffers fit on a 512K machine.
  - Cache files in spare RAM on bigger machines.
