;==============================================================================
; R-Type (Amiga) - level 8 data (level part B)
; Loaded to $4D300 ($4D300-$682B7); files/level8_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level8.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$5AAFF: tiles 0-431 (used by the map)
LvTiles:
                incbin  "level8_b_4d300.bin",$0,$D800
; $5AB00-$5AEFF: (not used by the code that is known)
                incbin  "level8_b_4d300.bin",$D800,$400
; $5AF00-$5C1FD: map 187x13
LvMap:
                incbin  "level8_b_4d300.bin",$DC00,$12FE
; $5C1FE-$5DE81: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level8_b_4d300.bin",$EEFE,$1C84
; $5DE82-$5DF17: sample table (8), period table
LvMusicSamples:
                incbin  "level8_b_4d300.bin",$10B82,$96
; $5DF18-$5F243: 8 samples
LvMusicSampleData:
                incbin  "level8_b_4d300.bin",$10C18,$132C
; $5F244-$60375: music player (the ending): code, variables, songs, patterns (PC-relative)
LvMusicEnd:
                incbin  "level8_b_4d300.bin",$11F44,$1132
; $60376-$6040B: sample table (8), period table
LvMusicEndSamples:
                incbin  "level8_b_4d300.bin",$13076,$96
; $6040C-$61737: 8 samples
LvMusicEndSampleData:
                incbin  "level8_b_4d300.bin",$1310C,$132C
; $61738-$65C37: BOB graphics: 24 frames of 736 bytes (Def_Mikun)
Gfx_Mikun:
                incbin  "level8_b_4d300.bin",$14438,$4500
; $65C38-$672B7: BOB graphics: 6 frames of 960 bytes (Def_MikunBurst)
Gfx_MikunBurst:
                incbin  "level8_b_4d300.bin",$18938,$1680
; $672B8-$679B7: BOB graphics: 4 frames of 448 bytes (Def_R9Escort)
Gfx_R9Escort:
                incbin  "level8_b_4d300.bin",$19FB8,$700
; $679B8-$682B7: BOB graphics: 3 frames of 768 bytes (Def_Win)
Gfx_Win:
                incbin  "level8_b_4d300.bin",$1A6B8,$900
LvEnd:
