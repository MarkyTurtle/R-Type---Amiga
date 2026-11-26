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
- **Level 8** has a second player for the ending (`LV_EndMusic`, `$5F244`), with 32-row patterns.

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

### Commands (how the engine calls the players)

All registers are set by the caller on every call; the players keep their state in their own variables.

| Caller | First call | Every following frame | Finished when |
|---|---|---|---|
| `UpdateMusic`, a tune (`MusicRequest` = n) | d3 = `$FFFF`, d1 = n − 1 (0 = the level's tune, 1 = the boss tune) | d1 = d3 = 2 | the player returns d0 = 0 (the tunes loop, so they run until replaced) |
| `UpdateMusic`, a jingle (`JingleState` = n) | d4 = (n − 1) << 8 \| `$FF` | d4 = 1 | the player returns d4 negative |
| `UpdateJingle` (shared player, level 8's ending player) | d0 = `$FF` (`JingleCmd`) | d0 = 2 | d0 = 0 |

d0 = 1 or 2 with d4 = 0 fades the music out (`MusicFadeReq`): every call lowers all volumes by one (`FadeLevel`). Tunes use channels 0–1 only, with 4-byte song rows, so the sound effects can have channels 2–3; jingles take all four channels and the effects are muted (`PlaySound` ignores requests while a jingle plays).

In level 1's player, for example, the command handler picks: tune 0 `$5CD34`, tune 1 `$5CDC6` (it loops from `$5CDDE`), jingle 0 (game over) `$5CEFC`, 1 (stage clear) `$5CEBA`, 2 (game start) `$5CE20`.

### Listening to them

`tools/render_music.py` runs each player in a 68000 emulator (`machine68k`), calls it as above and mixes the Paula register writes; the results are in `music/songs/` ([index](../music/songs/README.md)). Every level's player has its own tune; the boss tune, the game-over and stage-clear jingles are the same in all of them, and only level 1's player has the game-start fanfare.

### Where each player's data is

Found by `tools/music_tables.py`, which also writes every instrument sample to `music/` as WAV (73 samples):

| Player | Code | Sample table (entries) | Sample data | Period table | Pattern size |
|---|---|---|---|---|---|
| shared | `$4A300` | `$4B430` (10) | `$4B4D6` | `$4B480` | `$62` |
| level1 | `$5CA38` | `$604F8` (9) | `$60594` | `$60540` | `$62` |
| level2 | `$5E948` | `$608D6` (8) | `$6096A` | `$60916` | `$62` |
| level3 | `$634D0` | `$65A8E` (8) | `$65B24` | `$65ACE` | `$62` |
| level4 | `$52078` | `$53FB6` (8) | `$5404C` | `$53FF6` | `$62` |
| level5 | `$51A54` | `$53A46` (8) | `$53ADC` | `$53A86` | `$42`/`$62` |
| level6 | `$5C9A8` | `$5F0EE` (8) | `$5F184` | `$5F12E` | `$42`/`$62` |
| level7 | `$582A4` | `$5A914` (8) | `$5A9AA` | `$5A954` | `$42`/`$62` |
| level8 | `$5C1FE` | `$5DE82` (8) | `$5DF18` | `$5DEC2` | `$62` |
| level8end | `$5F244` | `$60376` (8) | `$6040C` | `$603B6` | `$62` |

There are three variants of the player:
- **Shared and levels 1–4:** fixed 98-byte (`$62`) patterns.
- **Levels 5–8:** the pattern size and pattern table are variables set per song (`$42` = 16 rows or `$62` = 24 rows), and the multiply reads the variable.
- **Level 8's ending tune:** 130-byte (`$82`) patterns of 32 rows.

Each player has several songs, selected by the command in d4 (the `lea`s before `move.l a0,d0` in the command handler).

## Sound effects

14 one-shot samples, played on audio channels 2 and 3. The music sequencer's two-channel mode sets DMACON `$8203` (channels 0 and 1), which leaves 2 and 3 free for effects. They are extracted as WAVs to `sfx/` by `tools/extract_sounds.py`.

`SoundTable` (`$5B08`), 12 bytes per effect:

| Offset | Contents |
|---|---|
| `+0.l` | sample address (`$6000` block) |
| `+4.w` | length in words |
| `+6.w` | period (all 428 = 8287 Hz on PAL) |
| `+8.w` | volume 0–64 |
| `+$A.b` | 0 |
| `+$B.b` | priority |

| # | Effect | Triggered by | Sample | Bytes | Vol | Pri |
|---|---|---|---|---|---|---|
| 0 | ship shot | `ShipFire` | `$1C68A` | 1900 | 40 | 20 |
| 1 | wave cannon | `FireWaveCannon` | `$1CDF6` | 4142 | 55 | 25 |
| 2 | reflect laser bounce | `UpdateLasers` (segment hits a wall) | `$1DE24` | 6428 | 52 | 20 |
| 3 | anti-air laser | `FireForce` | `$1F740` | 7664 | 51 | 20 |
| 4 | ground laser | `FireForce` | `$21530` | 5474 | 56 | 20 |
| 5 | Force docks | `Force_Attached`, `ForceHitsShip` | `$22A92` | 5598 | 52 | 25 |
| 6 | enemy hit | `ObjDamage`, `ObjCollisions` | `$24070` | 542 | 60 | 21 |
| 7 | ship explodes | `ShipDied` | `$2428E` | 7654 | 64 | 30 |
| 8 | power-up | `HitByForceOrShip`, `ReleasePowerUp` | `$26074` | 5688 | 60 | 28 |
| 9 | beam charged | charge reaches 6 | `$276AC` | 7342 | 50 | 23 |
| 10–12 | explosions types 0–2 | `ObjExplode` (10 + type) | `$2935A` / `$2A574` / `$2B4F4` | 4634 / 3968 / 4796 | 42 / 41 / 55 | 21 / 21 / 22 |
| 13 | explosion type 3, also repeated while the beam is fully charged | `ObjExplode`, beam charge | `$28DFA` | 1376 | 50 | 23 |

**Playing an effect:** `PlaySound` (d0 = effect, ignored while a jingle plays) queues it on whichever of the two channels is playing the lower-priority sound, or drops it if both are busier. `UpdateSound` (VBL) starts queued effects. `Level4Int` counts the channel's audio interrupts: the first means Paula has latched the sample, the second that it has played once, and the channel's DMA and interrupt are then switched off. Each channel's state lives in `SoundChannels` / `SoundChannel3` (8 bytes: state, priority, requested effect, interrupt count, DMACON bit, INTENA bit).
