# R-Type (Amiga) – documentation

| Document | Covers |
|---|---|
| [DISK_FORMAT.md](DISK_FORMAT.md) | Track map, the two custom MFM formats, high-score track, boot sequence, level load table, decruncher, memory map |
| [GAME.md](GAME.md) | How the program is organised: files, start-up, level interface, the frame, interrupts, objects, the Force, the hidden trainer, level code layout |
| [DATA_FORMATS.md](DATA_FORMATS.md) | ST program headers, level table and interface, checkpoints, wave lists, scroll script, map patches, objects and object definitions |
| [GRAPHICS.md](GRAPHICS.md) | Interleaved playfield and double buffering, HUD, tiles, map cells, BOBs and masks, hardware sprites, the `$6000` block, the title picture |
| [TODO.md](TODO.md) | What's left to do on the disassembly and exploration |
| [MUSIC.md](MUSIC.md) | TFMX title music (player, smpl, mdat), the in-game sample sequencer's song/pattern/sample format, sound effects |

The same findings are written as comments in the sources (`src/*.s`, `src/levels/*.s`) next to the code that uses each format.
