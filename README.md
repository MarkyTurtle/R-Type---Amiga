# R-Type – Amiga

Reverse-engineering and annotated disassembly of the Amiga **R-Type** (Electric Dreams, 1989; Amiga version by Factor 5, produced by Rainbow Arts). The aim is to learn how the game was put together.

![title](original/docs/title.png)

| Folder | Contents |
|---|---|
| [`original/`](original/) | Byte-identical, annotated disassembly of the original disk, the extraction tools and documentation |

Start with [`original/docs/DISK_FORMAT.md`](original/docs/DISK_FORMAT.md) for the disk and boot process, then [`original/docs/GAME.md`](original/docs/GAME.md) for how the game itself is organised.

## Progress

- [x] IPF decoded, all files extracted with checksums verified
- [x] Bootblock – [`original/src/bootblock.s`](original/src/bootblock.s)
- [x] Stage-2 loader / credits – [`original/src/stage2.s`](original/src/stage2.s)
- [x] Game program – [`original/src/game.s`](original/src/game.s): first pass, byte-identical, code and data separated, main systems named
- [ ] Game program: line-by-line comments
- [x] Level code – [`original/src/levels/`](original/src/levels/) (8 levels) and the shared title file [`original/src/shared.s`](original/src/shared.s): first pass, byte-identical
- [ ] Level code: name enemy routines and object definitions
- [ ] Data formats: the $6000 graphics block, level B (tiles, map), waves, scroll script

## Game data

All files extracted from the disk are in [`original/files/`](original/files/) (see `manifest.json` for load addresses, tracks and SHA-1s). To regenerate them from a disk image and check the sources:

```sh
python3 -I original/tools/extract.py path/to/R-Type.ipf original/files/
python3 -I original/tools/verify.py      # needs vasmm68k_mot
```
