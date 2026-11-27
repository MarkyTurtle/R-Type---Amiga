;==============================================================================
; R-Type (Amiga) - level 5 data (level part B)
; Loaded to $4D300 ($4D300-$688B7); files/level5_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level5.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$503FF: tiles 0-97 (used by the map)
LvTiles:
                incbin  "level5_b_4d300.bin",$0,$3100
; $50400-$504FF: (not used by the code that is known)
                incbin  "level5_b_4d300.bin",$3100,$100
; $50500-$51A53: map 210x13
LvMap:
                incbin  "level5_b_4d300.bin",$3200,$1554
; $51A54-$53A45: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level5_b_4d300.bin",$4754,$1FF2
; $53A46-$53ADB: sample table (8), period table
LvMusicSamples:
                incbin  "level5_b_4d300.bin",$6746,$96
; $53ADC-$54E07: 8 samples
LvMusicSampleData:
                incbin  "level5_b_4d300.bin",$67DC,$132C
; $54E08-$56187: BOB graphics: 6 frames of 832 bytes (Def_Cancer)
Gfx_Cancer:
                incbin  "level5_b_4d300.bin",$7B08,$1380
; $56188-$56307: BOB graphics: 4 frames of 96 bytes (Def_CheetahBeam)
Gfx_CheetahBeam:
                incbin  "level5_b_4d300.bin",$8E88,$180
; $56308-$57707: BOB graphics: 8 frames of 640 bytes (Def_MidCheetah)
Gfx_MidCheetah:
                incbin  "level5_b_4d300.bin",$9008,$1400
; $57708-$5AF07: BOB graphics: 16 frames of 896 bytes (Def_Pursuer)
Gfx_Pursuer:
                incbin  "level5_b_4d300.bin",$A408,$3800
; $5AF08-$5CDC7: BOB graphics: 4 frames of 1968 bytes (Def_Cheetah)
Gfx_Cheetah:
                incbin  "level5_b_4d300.bin",$DC08,$1EC0
; $5CDC8-$607C7: BOB graphics: 16 frames of 928 bytes (Def_SlitherHead)
Gfx_SlitherHead:
                incbin  "level5_b_4d300.bin",$FAC8,$3A00
; $607C8-$641C7: BOB graphics: 16 frames of 928 bytes (Def_SlitherBody)
Gfx_SlitherBody:
                incbin  "level5_b_4d300.bin",$134C8,$3A00
; $641C8-$66FC7: BOB graphics: 16 frames of 736 bytes (Def_SlitherTail)
Gfx_SlitherTail:
                incbin  "level5_b_4d300.bin",$16EC8,$2E00
; $66FC8-$678C7: BOB graphics: 1 frames of 2304 bytes (Def_Bellmite)
Gfx_Bellmite:
                incbin  "level5_b_4d300.bin",$19CC8,$900
; $678C8-$67FC7: BOB graphics: 2 frames of 896 bytes (Def_BellmiteShell)
Gfx_BellmiteShell:
                incbin  "level5_b_4d300.bin",$1A5C8,$700
; $67FC8-$688B7: table read by the level code
Tbl_67FC8:
                incbin  "level5_b_4d300.bin",$1ACC8,$8F0
LvEnd:
