# R-Type (Amiga) – disassembly

Reverse-engineering of the Amiga R-Type (Electric Dreams 1989; Amiga version by Factor 5, produced by Rainbow Arts), set up the same way as the Ghosts'n Goblins and New Zealand Story projects.

![title](docs/title.png)

## Status

- [x] IPF decoded; all files extracted with checksums verified (`files/`, `files/manifest.json`)
- [x] Bootblock and stage-2 loader / credits – `src/bootblock.s`, `src/stage2.s`, byte-identical and annotated
- [x] Disk formats, game loader, track cache, decruncher and level table – `docs/DISK_FORMAT.md`
- [x] Game program (`game_low_000a4.bin`) – `src/game.s`: byte-identical, all labels named, every routine commented; see `docs/GAME.md`
- [x] Level code (`levelN_a`) – `src/levels/level1-8.s`: all labels named, enemies and bosses named and commented line by line
- [x] Level data (`levelN_b`) – `src/levels/levelN_b.s`: byte-identical, in labelled blocks (tiles, map, music, each object's graphics, tables); level A refers to it by label, so A and B assemble together at any address (`tools/check_levelab.py`)
- [x] Shared title file and jingle player – `src/shared.s`; TFMX replay – `src/tfmx.s`: byte-identical, all named
- [x] Data, graphics and music formats – `docs/`; extended ADF rebuilt from the sources (`tools/build_disk.py`), boots in WinUAE
- [ ] What's left: `docs/TODO.md`

## Layout

```
src/bootblock.s        annotated bootblock
src/stage2.s           annotated stage-2 loader ($79360)
src/game.s             the game program ($000A4): engine, all game code
src/engine.i           engine symbols for the level and shared sources
src/levels/levelN.s    per-level code and data (level part A, $4A2E4)
src/levels/levelN_b.s  per-level data (level part B, $4D300): labelled incbin blocks
src/shared.s           shared title file ($4A300): jingle player + samples
src/tfmx.s             the TFMX replay for the title music ($52300)
files/                 every file extracted from the disk; manifest.json lists
                       names, tracks, load addresses and SHA-1s
docs/DISK_FORMAT.md    track formats, boot sequence, level table, memory map
docs/GAME.md           how the game is organised: interfaces, frame, objects
docs/DATA_FORMATS.md   level interface, checkpoints, waves, scroll script, objects
docs/GRAPHICS.md       playfield, HUD, tiles, map, BOBs, sprites, $6000 block
docs/MUSIC.md          TFMX title music, in-game sequencer format, effects
docs/OBJECTS.md        gallery of every object definition (generated)
docs/levelb_layout.txt the contents of every level B file (generated)
docs/TODO.md           what's left, and the enhanced-version plan
gfx/                   rendered maps, tile sets, enemy frames and sprites (PNG)
sfx/                   the 14 sound effects as WAV
music/                 the in-game music's instrument samples as WAV (73)
music/songs/           every tune rendered to MP3 with the game's own players
tools/
  ipf2mfm.py           IPF -> raw MFM bitstreams per track
  mfmlib.py            MFM helpers + AmigaDOS sector decoder
  extract.py           IPF -> files/  (runs ipf2mfm, decodes all three formats,
                       verifies every checksum, decrunches the levels)
  decrunch.py          exact Python port of the game's decruncher at $3EFC
  verify.py            assemble src/*.s and compare with files/
  gen_levelb.py        (bootstrap, run once) write levelN_b.s, label A's pointers into B
  check_levelab.py     check that each level's A and B assemble together anywhere
  render_gfx.py        render maps, tiles, BOBs and sprites to gfx/
  render_hud.py        render the HUD and fonts
  levelb_layout.py     map the contents of each level B file
  render_music.py      play the in-game music with the game's own player code (68000 emulator)
  extract_sounds.py    write the sound effects to sfx/
  add_labels.py        insert labels at addresses in a source (keeps it identical)
  music_tables.py      locate each music player's tables, write its samples to music/
  object_gallery.py    build docs/OBJECTS.md and gfx/objects/
  xref.py              which routines read/write each label (for naming)
  build_disk.py        write an extended ADF from files/ or the sources
  rtype_tracks.py      the custom $9521 track decoder
  extract_dos.py       rebuild the AmigaDOS cylinders 0-4 as an ADF fragment
  line_comments.py     add line comments by label anchor; copy them to identical routines
  localise_labels.py   turn generated L_ labels into local ones (keeps it identical)
  format_waves.py      lay the wave lists out one entry per line
  dis68k.py            quick capstone listing of any region
  bootstrap_source.py  one-off first-pass source generator (not part of the build)
  trace68k.py          recursive-descent code/data separation
  gen_source.py        first-pass source from a trace (bootstrap only)
```

## Use

```sh
pip install capstone                                  # for dis68k / bootstrap only
python3 -I tools/extract.py path/to/R-Type.ipf files/
python3 -I tools/verify.py                            # needs vasmm68k_mot (or VASM=...);
                                                      # checks against manifest SHA-1s
```

The sources are hand-edited and read directly; there is no generation step. Assemble with:

```
vasmm68k_mot -Fbin -m68000 -no-opt -o bootblock.bin src/bootblock.s
```
