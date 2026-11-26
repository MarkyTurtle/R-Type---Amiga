# R-Type (Amiga) – disk format and boot process

Electric Dreams, 1989. Amiga version by Factor 5, produced by Rainbow Arts.
Source image: the SPS/CAPS IPF you supplied (164 track records, cylinders 0–81).

## Track map

| Tracks (cyl×2+side) | Format | Read by | Contents |
|---|---|---|---|
| 0–9 (cyl 0–4) | AmigaDOS 11×512, sync `$4489` | Kickstart + trackdisk | Bootblock (blocks 0–1) and the boot read (blocks 2–93); blocks 94–109 are empty. **No filesystem.** |
| 10–62 | "short" custom, sync `$9521`, `$1750` bytes | stage 2 `LoadTracks` ($79A50) | TFMX title music (10–31), game code (32–35), graphics block (36–62) |
| 63–158 (not 68) | "long" custom, sync `$9521`, `$1998` bytes | game `LoadTracks` ($3CC8) | shared data + per-level data |
| 68 (cyl 34, side 0) | sync `$4489`, short block | game $3FA2 / $4022 | high-score save track |
| 159, 160–163 | unformatted | – | – |

Every short and long track passes its own checksum.

## Short track format (stage 2, $79A50)

DMA: `DSKSYNC=$9521`, `ADKCON=$9500` (MFMPREC|WORDSYNC|FAST), `$1800` words to `$32000`.

```
$9521 (sync, not stored)
+0   word   (skipped, $2AAA on disk)
+2   long   checksum (data bits only)
+6   $5D4 longs  odd bits of the whole track
     $5D4 longs  even bits of the whole track
decoded long = (odd & $55555555) << 1 | (even & $55555555)
checksum     = EOR of all $BA8 raw data longs, & $55555555
```
`$1750` (5968) bytes per track. After 5 failed re-reads the routine gives up without reporting an error.

## Long track format (game, $3CC8)

DMA: sync word from `$5BB4` (=`$9521`), `$19AC` words to `$7C400`.

```
$9521 (sync)
+0   word   (skipped)
+2   $666 pairs of (odd long, even long)   - interleaved per long
     1 pair: checksum
checksum = (EOR of the $CCC raw data longs & $55555555) EOR $AAAAAAAA
```
`$1998` (6552) bytes per track. On a bad checksum it steps out and back (`±2` tracks) and re-reads, with no retry limit.

`$3C3A` is a cached front end: when extra memory was found at boot (`$5BBC` ≠ 0) it keeps up to 18 (start track, count) → address entries at `$5BC4`, so loads after the first are memory copies. The cache runs from `$5BBC` up to `$5BC0` (the memory limit passed in from stage 2).

## High-score track (68)

Written by `$4022` (only when the disk is not write protected): `$4489 $2AAA`, then the checksum as an odd/even pair (XOR `$12345678`), a zero pair, then `$64` longs from `$575C` as odd/even pairs. `$3FA2` reads it at start-up (6 attempts) and copies `$5A` longs to `$575C` only if the checksum matches.

On this image the track holds just 209 data bytes after the sync, so the checksum fails and the game keeps the default table already in `game_low_000a4.bin` at `$575C`. That is normal for a factory disk.

## Boot sequence

1. **Bootblock** (`src/bootblock.s`): grabs the largest non-chip memory block with `AvailMem`/`AllocMem(MEMF_FAST)`, reads `$B800` bytes from offset `$400` to `$6EFA0`, motor off, `JMP $79360` with D0 = block base (64K aligned) or 0 and D1 = block end.
2. **Stage 2** (`src/stage2.s`): copies the title picture and font to `$35FA0`, then `TRAP #0` → hardware takeover. It fades the picture in, loads the music (tracks 10–31 → `$52300`, also copied to the extra memory when there is some), starts the title tune, loads the game (32–35 → `$A4`, 36–62 → `$6000`), runs the typed and scrolled credits, and jumps to `$C0`:
   - D0 = first free byte of extra memory after the music copy (or 0): the game's track-cache base (`$5BBC`)
   - D1 = end of extra memory (`$5BC0`)
   - D2 = music copy address or 0 (`$56EA`)
   - D3 = current track (`$5BB2`)
   - A0 = `GameFadeFlag`. The game sets it and waits; stage 2's VBL handler, still running, fades the title out and clears it.
3. **Game** (`$C0` → `bra $10E`): reads the high scores, loads tracks 63–67 to `$4A300` (`$3A0E`), and from then on loads levels from the table at `$41B4`.

## Level table ($41B4, 10 bytes per level)

| Level | file A → `$4A2E4` | file B (crunched) → `$4CB00` | decrunched → `$4D300` | word → `$F4` |
|---|---|---|---|---|
| 1 | 69–70 | 71–83 | `$2C35B` | `$218` |
| 2 | 84 | 85–97 | `$2527A` | `$168` |
| 3 | 98–99 | 100–110 | `$229DC` | `$088` |
| 4 | 111–112 | 113–121 | `$2176A` | `$158` |
| 5 | 122 | 123–130 | `$1B5B8` | `$1A4` |
| 6 | 131 | 132–136 | `$19D30` | `$148` |
| 7 | 137–138 | 139–148 | `$23D8F` | `$134` |
| 8 | 149 | 150–158 | `$1AFB8` | `$176` |

File B is loaded over the end of file A, so only `$281C` bytes of A survive. The meaning of the word stored to `$F4` is still to be found.

## Decruncher ($3EFC)

A ByteKiller-style backwards LZ decruncher (`tools/decrunch.py` is an exact port). The first long is the crunched length L; the long at L-4 is the decrunched length; L-8 is a checksum, and EORing it with every stream long must give 0. All 8 level files decrunch with checksum 0.

| prefix | meaning |
|---|---|
| `00` + 3 bits n | n+1 literal bytes |
| `01` + 8 bits off | copy 2 bytes |
| `100` + 9 bits off | copy 3 bytes |
| `101` + 10 bits off | copy 4 bytes |
| `110` + 8 bits n + 12 bits off | copy n+1 bytes |
| `111` + 8 bits n | n+9 literal bytes |

## Memory map (so far)

| Address | Contents |
|---|---|
| `$000A4–$05DE3` | game low code: entry `$C0`, jump table `$C2–$EA`, disk/decrunch routines `$3C00–$4190`, level table `$41B4`, high scores `$575C`, disk vars `$5B00–$5C60` |
| `$06000–$2D56F` | game main code/data |
| `$32000` | stage-2 MFM buffer |
| `$35000` | stage-2 text-window save |
| `$35FA0–$4035F` | title picture (5 × `$1F40`) + font `$3FBE0` |
| `$4A2E4 / $4A300` | level file A / shared tracks 63–67 |
| `$4CB00 → $4D300` | crunched level file B → decrunched level data |
| `$52300–$71A3B` | music + replay (play `$52324`, start `$5232C`, init `$52334`) |
| `$79360–$7A79F` | stage 2 |
| `$7C400` | game MFM buffer |

## Rebuilding the disk

`tools/build_disk.py` writes a WinUAE **extended ADF** (`UAE-1ADF`), putting every file back on its original tracks in its original format:
- **Tracks 0–9:** AmigaDOS sectors (bootblock and boot read).
- **Tracks 10–62:** short `$9521` tracks of 100,064 bits.
- **Tracks 63–158:** long `$9521` tracks of 105,344 bits, about 5% longer than a standard track, as on the original.
- **Track 68:** written with a **valid** checksum and the game's default high-score table, so saving high scores works (the factory placeholder never loads).

```sh
python3 -I tools/build_disk.py R-Type.adf                  # from files/
VASM=vasmm68k_mot python3 -I tools/build_disk.py --from-source R-Type.adf
```

`--from-source` assembles `src/` first, replacing the bootblock (its checksum is recomputed), stage 2, the game program, the shared file and the level A files. The other files (title picture, music, `$6000` block, level B) come from `files/`. Every raw track it writes is decoded again with the extractor's decoders and compared with its input. Each file must still fit its tracks (the tool reports an overflow); moving files means changing the loaders' track numbers too (stage 2 and `LevelTable`).

Both commands currently give the same image. It hasn't been booted in WinUAE yet.
