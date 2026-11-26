# In-game music samples

Every instrument sample used by the in-game sequencer (the shared jingle player and each level's music player, including level 8's ending tune), written by `python3 -I tools/music_tables.py files music` (run in `original/`). The files are named `<player>_sNN.wav`, where NN is the sample number in that player's sample table. They're 8-bit mono, written at 8287 Hz (period 428); the songs play them at other pitches through the period table. Format: [`../docs/MUSIC.md`](../docs/MUSIC.md).
