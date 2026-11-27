;==============================================================================
; R-Type (Amiga) - level 2 data (level part B)
; Loaded to $4D300 ($4D300-$72579); files/level2_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level2.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$5D4FF: tiles 0-515 (used by the map)
LvTiles:
                incbin  "level2_b_4d300.bin",$0,$10200
; $5D500-$5D6FF: tiles 516-519, never shown: nothing writes them: the map, Brood1Cells/Brood2Cells and BossEyeFrames use tiles up to 515
                ifnd    LEVEL_TRIM              ; (the enhanced build leaves them out)
                incbin  "level2_b_4d300.bin",$10200,$200
                endc
; $5D700-$5E947: map 180x13
LvMap:
                incbin  "level2_b_4d300.bin",$10400,$1248
; $5E948-$608D5: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level2_b_4d300.bin",$11648,$1F8E
; $608D6-$60969: sample table (8), period table
LvMusicSamples:
                incbin  "level2_b_4d300.bin",$135D6,$94
; $6096A-$61C95: 8 samples
LvMusicSampleData:
                incbin  "level2_b_4d300.bin",$1366A,$132C
; $61C96-$67515: BOB graphics: 8 frames of 2832 bytes (Def_Gouger)
Gfx_Gouger:
                incbin  "level2_b_4d300.bin",$14996,$5880
; $67516-$67C65: BOB graphics: 9 frames of 208 bytes (Def_Wick)
Gfx_Wick:
                incbin  "level2_b_4d300.bin",$1A216,$750
; $67C66-$699A5: BOB graphics: 9 frames of 832 bytes (Def_Zoid)
Gfx_Zoid:
                incbin  "level2_b_4d300.bin",$1A966,$1D40
; $699A6-$6D3A5: BOB graphics: 16 frames of 928 bytes (Def_WormHead)
Gfx_WormHead:
                incbin  "level2_b_4d300.bin",$1C6A6,$3A00
; $6D3A6-$709A5: BOB graphics: 16 frames of 864 bytes (Def_WormBody)
Gfx_WormBody:
                incbin  "level2_b_4d300.bin",$200A6,$3600
; $709A6-$716A5: BOB graphics: 4 frames of 832 bytes (Def_WormEye)
Gfx_WormEye:
                incbin  "level2_b_4d300.bin",$236A6,$D00
; $716A6-$718E7: table read by the level code
Tbl_716A6:
                incbin  "level2_b_4d300.bin",$243A6,$242
; $718E8-$71B29: table read by the level code
Tbl_718E8:
                incbin  "level2_b_4d300.bin",$245E8,$242
; $71B2A-$71D6B: table read by the level code
Tbl_71B2A:
                incbin  "level2_b_4d300.bin",$2482A,$242
; $71D6C-$71E61: table read by the level code
Tbl_71D6C:
                incbin  "level2_b_4d300.bin",$24A6C,$F6
; $71E62-$71F57: table read by the level code
Tbl_71E62:
                incbin  "level2_b_4d300.bin",$24B62,$F6
; $71F58-$7204D: table read by the level code
Tbl_71F58:
                incbin  "level2_b_4d300.bin",$24C58,$F6
; $7204E-$720AE: table read by the level code
Tbl_7204E:
                incbin  "level2_b_4d300.bin",$24D4E,$61
; $720AF-$7210F: table read by the level code
Tbl_720AF:
                incbin  "level2_b_4d300.bin",$24DAF,$61
; $72110-$72170: table read by the level code
Tbl_72110:
                incbin  "level2_b_4d300.bin",$24E10,$61
; $72171-$721ED: table read by the level code
Tbl_72171:
                incbin  "level2_b_4d300.bin",$24E71,$7D
; $721EE-$7226A: table read by the level code
Tbl_721EE:
                incbin  "level2_b_4d300.bin",$24EEE,$7D
; $7226B-$722E7: table read by the level code
Tbl_7226B:
                incbin  "level2_b_4d300.bin",$24F6B,$7D
; $722E8-$72375: table read by the level code
Tbl_722E8:
                incbin  "level2_b_4d300.bin",$24FE8,$8E
; $72376-$72403: table read by the level code
Tbl_72376:
                incbin  "level2_b_4d300.bin",$25076,$8E
; $72404-$72495: table read by the level code
Tbl_72404:
                incbin  "level2_b_4d300.bin",$25104,$92
; $72496-$7252E: table read by the level code
Tbl_72496:
                incbin  "level2_b_4d300.bin",$25196,$99
; $7252F-$72579: table read by the level code
Tbl_7252F:
                incbin  "level2_b_4d300.bin",$2522F,$4B
LvEnd:
