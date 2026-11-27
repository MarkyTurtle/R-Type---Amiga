;==============================================================================
; R-Type (Amiga) - level 6 data (level part B)
; Loaded to $4D300 ($4D300-$6702F); files/level6_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level6.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$59D7F: tiles 0-404 (used by the map)
LvTiles:
                incbin  "level6_b_4d300.bin",$0,$CA80
; $59D80-$5B8FF: (not used by the code that is known)
                incbin  "level6_b_4d300.bin",$CA80,$1B80
; $5B900-$5C9A7: map 164x13
LvMap:
                incbin  "level6_b_4d300.bin",$E600,$10A8
; $5C9A8-$5F0ED: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level6_b_4d300.bin",$F6A8,$2746
; $5F0EE-$5F183: sample table (8), period table
LvMusicSamples:
                incbin  "level6_b_4d300.bin",$11DEE,$96
; $5F184-$604AF: 8 samples
LvMusicSampleData:
                incbin  "level6_b_4d300.bin",$11E84,$132C
; $604B0-$628AF: BOB graphics: 6 frames of 1536 bytes (Def_Dop)
Gfx_Dop:
                incbin  "level6_b_4d300.bin",$131B0,$2400
; $628B0-$6492F: BOB graphics: 10 frames of 832 bytes (Def_Capsule)
Gfx_Capsule:
                incbin  "level6_b_4d300.bin",$155B0,$2080
; $64930-$6702F: BOB graphics: 12 frames of 832 bytes (Def_Bink)
Gfx_Bink:
                incbin  "level6_b_4d300.bin",$17630,$2700
LvEnd:
