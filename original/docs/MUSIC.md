# R-Type (Amiga) – music and sound

R-Type uses **two separate music systems**. Neither is a Soundtracker/ProTracker module.

## 1. Title music: TFMX (Chris Huelsbeck)

`music_52300.bin` (tracks 10–31) is Chris Huelsbeck's **TFMX** ("The Final Musicsystem eXtended"), in three parts. The extractor writes each part out separately:

| File | Load | Contents |
|---|---|---|
| `tfmx_player_52300.exe` | `$52300` | the replay as a complete **AmigaDOS executable**: HUNK_HEADER, one code hunk of `$1444` bytes, HUNK_END |
| `smpl.rtypetitle` | `$53768` | samples |
| `mdat.rtypetitle` | `$6FD28` | song data, `TFMX-SONG ` header |

The player still contains `dos.library` and the paths `df1:mdat.rtypetitle.pck` / `df1:smpl.rtypetitle.pck`: during development it loaded the song from a second floppy. On the game disk the data follows the player directly, and stage 2 calls the jump table at the start of the code hunk (`$52320`):

| Entry | Use |
|---|---|
| `$52324` (+4) | play: called every VBL |
| `$5232C` (+`$C`) | start song d0 |
| `$52334` (+`$14`) | init: d0 = mdat, d1 = smpl |

The `mdat` uses the classic layout (the offset fields at `$1D0` are 0): text at `$10`, song start/end/tempo tables at `$100`/`$140`/`$180`, pattern pointers at `$400`, macro pointers at `$600`, track steps at `$800`. Song 0 runs track steps 0–79 at tempo 4. TFMX sequences instrument **macros** (programs for volume, pitch and sample changes) from **patterns** of commands, rather than a fixed grid of notes.

With extra memory the game keeps a copy of the music there (stage 2 copies `$52300`–`$71A3B`, which ends exactly at the end of the mdat).

`mdat.rtypetitle` + `smpl.rtypetitle` should play in a TFMX-capable player (e.g. UADE / DeliTracker); not yet tested.

## 2. In-game music and jingles: a small sample sequencer

The same simple four-channel sequencer is used three times:

- **The jingle player** in the shared title file (`src/shared.s`, `$4A300`) plays the title and high-score jingles.
- **Each level's music player** sits in its level B file (`LV_Music`, e.g. `$5CA38` in level 1). These are variants of the same code with different data; credited as game music by Darius Zendeh.
- **Level 8** has a second music entry for the ending (`LV_EndMusic`, `$5F244`), not yet examined.

The engine calls it from the VBL (`UpdateJingle` / `UpdateMusic`) with a command in d0/d4. It plays one row on every second call, i.e. 25 rows a second.

### Song

Rows of `pattern.b, transpose.b` for each channel (8 bytes per row for 4 channels, 4 for 2 channels), ending with `$FF`. Example from the jingle song (`$4A62C`): `01 00 07 1D 0B 0D 07 25`. Every pattern is 24 rows, so all channels move on together.

### Pattern (`$62` = 98 bytes)

24 rows × 4 bytes, then `$FF $FF`. Pattern 0 is silence.

| Byte | Meaning |
|---|---|
| +0 | sample number |
| +1 | note: index into the period table, plus the song row's transpose. **Bit 7 set = slide**: period = previous period ± (note & `$7F`) |
| +2 | volume 0–64 (minus the current fade level) |
| +3 | flags: bit 7 = slide direction; **bit 0 set = keep playing**. Only the next sample start/length is written, so the hardware plays it after the current one: an attack sample (e.g. 8) runs straight into its loop sample (9). **Bit 0 clear**: the channel's DMA goes off on the in-between call and on again, retriggering the note |

### Samples and periods

- Sample table: 8 bytes per sample: `offset.l` (from the sample data), `0.w`, `length.w` (words).
- Period table: 43 Amiga periods, 1440 … 127. Index 9 = 856, ProTracker's C-1.
- Samples: raw signed 8-bit.

Compared with a module, there are no song name, sample names or effect commands, and no pattern grid of 64 × 4 notes. Patterns here are short per-channel phrases with their own volume per row, and the song transposes them.

## Sound effects

`PlaySound` (engine, `$3AE6`; level code uses `jt_PlaySound` at `$10A`): d0 = effect number from `SoundTable` (`$5B08`). Effects are played on two channels with priorities (`SoundChannels`, `$5AF8`). The level 4 interrupt (`Level4Int`) handles the audio interrupts for channels 2 and 3. The effect table and sample format are still to be worked out.
