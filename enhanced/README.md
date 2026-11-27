# R-Type (Amiga) – enhanced

The game on an ordinary **AmigaDOS disk**, in the old file system (OFS, `DOS\0`): the only kind Kickstart 1.3 boots and reads. The original's custom long tracks are replaced
by files that Workbench can list, copy and check. They are read with the
[4489_byteloader](https://github.com/MarkyTurtle/4489_byteloader) and packed with ZX0. The game
itself is the original's. Next on the plan, in `../original/docs/TODO.md` section 7: a title
menu, cheats and CD32 pad support.

```sh
python3 -I enhanced/tools/build.py       # -> enhanced/build/rtype.adf
python3 -I enhanced/tools/test_disk.py   # the disk code in a 68000 emulator against that disk
```

You need vasm (`VASM`), [salvador](https://github.com/emmanuel-marty/salvador) (`SALVADOR`), and
Python with `unicorn` (for the test) and optionally `amitools` (the build then reads every file
back through the file system with `xdftool`). The GitHub Action builds the disk, runs the test
and attaches `rtype.adf` to the run as **R-Type-enhanced-adf**.

## The disk

An 880K OFS disk (`DOS\0`), volume `R-Type`. Every file is stored in **one run of blocks**,
so a file is just an offset and a length on the disk, and the game needs no file-system code.
An OFS data block is a 24-byte header plus 488 bytes of the file. The loaders read a file's
whole run (512 bytes a block) so that it ends where the file's bytes must end, then squeeze the
headers out by moving each block's data up, from the last block back (`OFSCompact`). The file
headers sit together after the root block, out of the way. (The first version was FFS, which
Kickstart 1.3 won't boot.)

| Id | File | Loaded to | Packed | Read by |
|---:|---|---|---|---|
| 0 | `boot` | ending at `$7A7A0` | (picture: ZX0) | the bootblock, through `trackdisk.device`: the title picture and font packed, then stage 2 |
| 1 | `music` | `$52300` | ZX0 | stage 2: the TFMX replay, smpl, mdat |
| 2 | `game` | `$A4` | ZX0 | stage 2: the engine (`src/game.s`) |
| 3 | `graphics` | `$6000` | ZX0 | stage 2: the `$6000` block |
| 4 | `title` | `$4A300` | ZX0 | the engine (`LoadShared`): the title data and jingle player |
| 5 | `highscores` | – | no | the engine: one block, the table's 100 longs and a checksum |
| 6–13 | `level1a`–`level8a` | `$4A2E4` | ZX0 | `LoadLevel`: level part A, the `$281C` bytes that survive the level B load |
| 14–21 | `level1b`–`level8b` | `$4D300` | ZX0 | `LoadLevel`: level part B, unpacked (the original's was ByteKiller-packed) |

`build.py` prints the sizes and offsets. The files take about 580K, leaving roughly 260K free.
ZX0 packs the level B files about 35% smaller than the original's ByteKiller.

**Unpacking in place.** ZX0 unpacks forwards, so a packed file is loaded to end just past where
its unpacked data will end, then unpacked to its destination. The gap is the file's *margin*
(2 or 3 bytes here). `build.py` works it out by running the format in Python exactly as
`unzx0_68000.s` reads it (`unzx0`), and checks each load against what must survive it. For
example, the title file's packed data must end before the music at `$52300` (8 bytes are free).

**The file table.** It has 12 bytes per file: the offset of its first block, the file's length
(without the block headers), and either 0 (stored as it is) or the unpacked length plus the
margin. `build.py` writes it into stage 2
inside the boot file once the disk is laid out. Stage 2 copies it into the engine's `FileTable`
after loading the engine.

## Booting and loading

1. **Bootblock** (`src/boot.s`), with the OS still running, as the original's:
   - Takes the largest block of fast/slow memory for the file cache.
   - Finds the drive it was booted from, by opening `trackdisk.device`'s units until one is the
     boot request's (as in the GnG enhanced bootblock). Kickstart 2.0 and later can boot from
     any drive.
   - Reads the boot file's blocks (from block 2) with `CMD_READ` so that they end at `$7A7A0`,
     where the original's boot read ended, and squeezes their headers out. The boot file is the
     ZX0-packed title picture and font, then stage 2, so it is half the original's size and the
     read stays inside the memory the original game read into while the OS was still running.
     Then it jumps to stage 2 with d0 = MemBase, d1 = MemLimit, d2 = the drive.
2. **Stage 2** (`src/stage2.s`, the original's apart from loading; the build places it to end
   at `$7A7A0`):
   - Unpacks the title picture and font to `$35FA0` (the original copied them) and takes the
     machine over.
   - Its VBL handler acknowledges only its own interrupt bits. The original's cleared every
     pending bit, DSKBLK included, and the byte loader waits for DSKBLK, so the loads never
     finished. It still runs during the engine's first loads (high scores, title file).
   - Reads the music, the engine and the `$6000` block with the byte loader. Its MFM buffer is
     the original's at `$32000`.
   - Starts the engine with d3 = the drive (the original passed the head's track).
3. **The engine** (`src/game.s` with `src/disk.s`): the original's `$3C3A`–`$41B3`, which held
   the track loader, track cache, decruncher and high-score track, now holds:
   - `LoadFile` (still answering to `LoadTracksCached`): d0 = file id, d2 = destination.
   - The byte loader (MFM buffer at `TRACK_BUFFER`, `$7C400`) and the ZX0 unpacker.
   - `LoadHighScores` / `SaveHighScores`.
   - The cheat code (`cheats.s`, see below).

   It fits with 20 bytes to spare. The rest is padded, so nothing after it moves: the level
   files use the engine's addresses and are unchanged. `LevelTable` holds file ids instead of
   tracks.
   - **File cache:** with extra memory, each packed file is kept there after its first read, and
     later loads unpack straight from it (the original cached tracks).
   - **Failed reads:** a read that fails is tried again; after 8 failures COLOR00 turns red while
     it keeps trying.
   - **High scores:** the table is checked and read at start-up (90 longs back, as from the
     original's track 68). It is saved after a name is entered (not in cheat mode, not on a
     write-protected disk), like this:
     1. The track holding the block is read. The byte loader leaves it decoded in its buffer.
     2. The block's data is replaced and its OFS checksum made right again.
     3. All 11 sectors are MFM-encoded again into `$74000` (free at the title), with a 700-word
        gap before sector 0 to absorb the wrap-round.
     4. The track is written back.

     The block never moves, so the file system's bitmap and directories are never touched.

## Cheats

`CheatFlags` (in `cheats.s`, at a fixed address in the engine) has one bit per cheat. The
title menu will set them. Until it exists, the one cheat so far is on from the start:

- **N skips the stage.** In normal play it sets `LevelComplete`, as killing the boss does: the
  ship flies off, the stage bonus is counted and the next stage loads. It does nothing during a
  stage's intro or ending, after a death, or on stage 8 (whose ending is its own code). Scores
  are kept and saved as usual. Level2Int calls `CheatKeys` in place of its `cmp.b #$19,d0` for
  P, and `CheatKeys` ends with that compare, so no byte of the engine moves.

## The test

`tools/test_disk.py` runs the real 68000 code in Unicorn, against the disk that was built. The
drive is `tools/floppy.py` (from the GnG enhanced project), extended so that a write DMA is
decoded back into the disk image with its MFM and checksums checked. It runs:
- what Kickstart checks before it runs the bootblock (`DOS\0`, the checksum)
- the bootblock, with exec's calls stubbed, booting from DF0 and from DF1: its read stays within
  `$6EFA0`–`$7A7A0`
- stage 2 unpacking the title picture, and its VBL handler leaving DSKBLK pending
- stage 2's three loads, each unpacked in place with stage 2 intact
- every file through the engine's `LoadFile`, without and with extra memory (the second loads
  must come from the cache, with no disk reads)
- `LoadLevel` for all 8 levels
- the N key through Level2Int: the stage skip, the cases where it must do nothing, and P still
  pausing
- reading the high scores, saving a changed table (only its block may change on the track),
  reading it back (the OFS block stays valid), and checking that a damaged block is ignored

It doesn't run stage 2's display or the game itself: that is for WinUAE.

## Checked in WinUAE

Boots from DF0 on Kickstart 1.3, all 8 stages load (using the stage skip), and the high scores
save and load back.

## Still to check in WinUAE

- A500 with 512K slow RAM (the file cache), an A1200, and booting from DF1 with Kickstart 2.0+.
