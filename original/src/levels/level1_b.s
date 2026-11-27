;==============================================================================
; R-Type (Amiga) - level 1 data (level part B)
; Loaded to $4D300 ($4D300-$7965A); files/level1_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level1.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$5AEFF: tiles 0-439 (used by the map)
LvTiles:
                incbin  "level1_b_4d300.bin",$0,$DC00
; $5AF00-$5CA37: map 268x13
LvMap:
                incbin  "level1_b_4d300.bin",$DC00,$1B38
; $5CA38-$604F7: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level1_b_4d300.bin",$F738,$3AC0
; $604F8-$60593: sample table (9), period table
LvMusicSamples:
                incbin  "level1_b_4d300.bin",$131F8,$9C
; $60594-$62D95: 9 samples
LvMusicSampleData:
                incbin  "level1_b_4d300.bin",$13294,$2802
; $62D96-$62DA7: (not used by the code that is known)
                incbin  "level1_b_4d300.bin",$15A96,$12
; $62DA8-$640A7: BOB graphics: 8 frames of 608 bytes (Def_PataPata)
Gfx_PataPata:
                incbin  "level1_b_4d300.bin",$15AA8,$1300
; $640A8-$655A7: BOB graphics: 8 frames of 672 bytes (Def_Bug)
Gfx_Bug:
                incbin  "level1_b_4d300.bin",$16DA8,$1500
; $655A8-$67017: BOB graphics: 3 frames of 2256 bytes (Def_Scant)
Gfx_Scant:
                incbin  "level1_b_4d300.bin",$182A8,$1A70
; $67018-$67617: BOB graphics: 2 frames of 768 bytes (Def_ScantBeam)
Gfx_ScantBeam:
                incbin  "level1_b_4d300.bin",$19D18,$600
; $67618-$6A6D7: BOB graphics: 15 frames of 832 bytes (Def_PStaff)
Gfx_PStaff:
                incbin  "level1_b_4d300.bin",$1A318,$30C0
; $6A6D8-$6B3D7: BOB graphics: 16 frames of 208 bytes (Def_PStaffMissile)
Gfx_PStaffMissile:
                incbin  "level1_b_4d300.bin",$1D3D8,$D00
; $6B3D8-$6DAD7: BOB graphics: 12 frames of 832 bytes (Def_Bink)
Gfx_Bink:
                incbin  "level1_b_4d300.bin",$1E0D8,$2700
; $6DAD8-$6EE57: BOB graphics: 6 frames of 832 bytes (Def_Cancer)
Gfx_Cancer:
                incbin  "level1_b_4d300.bin",$207D8,$1380
; $6EE58-$727B7: BOB graphics: 17 frames of 864 bytes (Def_Shell)
Gfx_Shell:
                incbin  "level1_b_4d300.bin",$21B58,$3960
; $727B8-$76027: BOB graphics: 7 frames of 2064 bytes (Def_Tabrok)
Gfx_Tabrok:
                incbin  "level1_b_4d300.bin",$254B8,$3870
; $76028-$760B7: BOB graphics: 1 frames of 144 bytes (Def_TabrokMissile)
Gfx_TabrokMissile:
                incbin  "level1_b_4d300.bin",$28D28,$90
; $760B8-$76FB7: BOB graphics: 16 frames of 240 bytes (Def_TabrokHomer)
Gfx_TabrokHomer:
                incbin  "level1_b_4d300.bin",$28DB8,$F00
; $76FB8-$784B7: BOB graphics: 8 frames of 672 bytes (Def_DobkeratopsShot)
Gfx_DobkeratopsShot:
                incbin  "level1_b_4d300.bin",$29CB8,$1500
; $784B8-$78AB7: BOB graphics: 6 frames of 256 bytes (Def_DobkeratopsTail)
Gfx_DobkeratopsTail:
                incbin  "level1_b_4d300.bin",$2B1B8,$600
; $78AB8-$78FD7: table read by the level code
Tbl_78AB8:
                incbin  "level1_b_4d300.bin",$2B7B8,$520
; $78FD8-$78FFA: table read by the level code
Tbl_78FD8:
                incbin  "level1_b_4d300.bin",$2BCD8,$23
; $78FFB-$79041: table read by the level code
Tbl_78FFB:
                incbin  "level1_b_4d300.bin",$2BCFB,$47
; $79042-$79088: table read by the level code
Tbl_79042:
                incbin  "level1_b_4d300.bin",$2BD42,$47
; $79089-$790CF: table read by the level code
Tbl_79089:
                incbin  "level1_b_4d300.bin",$2BD89,$47
; $790D0-$7912D: table read by the level code
Tbl_790D0:
                incbin  "level1_b_4d300.bin",$2BDD0,$5E
; $7912E-$7918B: table read by the level code
Tbl_7912E:
                incbin  "level1_b_4d300.bin",$2BE2E,$5E
; $7918C-$791E9: table read by the level code
Tbl_7918C:
                incbin  "level1_b_4d300.bin",$2BE8C,$5E
; $791EA-$79236: table read by the level code
Tbl_791EA:
                incbin  "level1_b_4d300.bin",$2BEEA,$4D
; $79237-$79283: table read by the level code
Tbl_79237:
                incbin  "level1_b_4d300.bin",$2BF37,$4D
; $79284-$792D0: table read by the level code
Tbl_79284:
                incbin  "level1_b_4d300.bin",$2BF84,$4D
; $792D1-$79524: table read by the level code
Tbl_792D1:
                incbin  "level1_b_4d300.bin",$2BFD1,$254
; $79525-$79571: table read by the level code
Tbl_79525:
                incbin  "level1_b_4d300.bin",$2C225,$4D
; $79572-$795BE: table read by the level code
Tbl_79572:
                incbin  "level1_b_4d300.bin",$2C272,$4D
; $795BF-$79606: table read by the level code
Tbl_795BF:
                incbin  "level1_b_4d300.bin",$2C2BF,$48
; $79607-$7965A: table read by the level code
Tbl_79607:
                incbin  "level1_b_4d300.bin",$2C307,$54
LvEnd:
