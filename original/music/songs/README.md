# R-Type (Amiga) – the in-game music, played by the game's own code

Rendered by `tools/render_music.py`, which runs each music player from the level B files (and the jingle player from the shared file) in a 68000 emulator, calls it once per 50 Hz frame as `UpdateMusic` / `UpdateJingle` do, and mixes what it writes to Paula. Long tunes loop and are cut at 75 seconds (the title at 120). The in-game music is credited to Darius Zendeh; the title music is Chris Hülsbeck's TFMX, played by its own replay routine from the disk.

| File | What | Command |
|---|---|---|
| `title.mp3` | the title music (TFMX) | init `$52334` (d0 = mdat, d1 = smpl), song 0 `$5232C`, play `$52324` every VBL |
| `level1_music.mp3` … `level8_music.mp3` | each stage's tune, on channels 0–1 (2–3 are for the sound effects) | `MusicRequest` 1: d3 = `$FF`, d1 = 0 |
| `boss.mp3` | the boss tune, the same in every level's player | `MusicRequest` 2: d1 = 1 |
| `start.mp3` | the game-start fanfare (level 1's player only; the others play `gameover` for this command) | `JingleState` 3: d4 = `$02FF` |
| `stageclear.mp3` | stage cleared | `JingleState` 2: d4 = `$01FF` |
| `gameover.mp3` | game over | `JingleState` 1: d4 = `$00FF` |
| `highscore.mp3` | the shared jingle player: high-score entry and the end of the game | `JingleCmd` `$FF` |
| `ending.mp3` | level 8's ending player (`LV_EndMusic`) | `JingleCmd` `$FF` |

The jingles play on all four channels. Rendering details: no interpolation or Amiga filter, mono, 22050 Hz, MP3 48 kbit/s.
