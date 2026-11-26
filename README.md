# R-Type – Amiga

Reverse-engineering and annotated disassembly of the Amiga **R-Type** (Electric Dreams, 1989; Amiga version by Factor 5, produced by Rainbow Arts). The aim is to learn how the game was put together.

![title](original/docs/title.png)

| Folder | Contents |
|---|---|
| [`original/`](original/) | Byte-identical, annotated disassembly of the original disk, the extraction tools and documentation |

Start with [`original/docs/DISK_FORMAT.md`](original/docs/DISK_FORMAT.md) for how the disk, the boot process and the level loading work.

## Progress

- [x] IPF decoded, all files extracted with checksums verified
- [x] Bootblock – [`original/src/bootblock.s`](original/src/bootblock.s)
- [x] Stage-2 loader / credits – [`original/src/stage2.s`](original/src/stage2.s)
- [ ] Game low code ($A4–$5DE3)
- [ ] Game main code ($6000–$2D56F)
- [ ] Level data formats

## Game data

The game's binaries are not included. Extract them from your own disk image:

```sh
python3 -I original/tools/extract.py path/to/R-Type.ipf original/files/
python3 -I original/tools/verify.py      # needs vasmm68k_mot
```
