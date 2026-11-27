;==============================================================================
; R-Type (Amiga) - level 4 data (level part B)
; Loaded to $4D300 ($4D300-$6EA69); files/level4_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level4.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$50EFF: tiles 0-119 (used by the map)
LvTiles:
                incbin  "level4_b_4d300.bin",$0,$3C00
; $50F00-$52077: map 172x13
LvMap:
                incbin  "level4_b_4d300.bin",$3C00,$1178
; $52078-$53FB5: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level4_b_4d300.bin",$4D78,$1F3E
; $53FB6-$5404B: sample table (8), period table
LvMusicSamples:
                incbin  "level4_b_4d300.bin",$6CB6,$96
; $5404C-$55377: 8 samples
LvMusicSampleData:
                incbin  "level4_b_4d300.bin",$6D4C,$132C
; $55378-$56677: BOB graphics: 8 frames of 608 bytes (Def_PataPata)
Gfx_PataPata:
                incbin  "level4_b_4d300.bin",$8078,$1300
; $56678-$57B77: BOB graphics: 8 frames of 672 bytes (Def_Bug)
Gfx_Bug:
                incbin  "level4_b_4d300.bin",$9378,$1500
; $57B78-$5AC37: BOB graphics: 15 frames of 832 bytes (Def_PStaff)
Gfx_PStaff:
                incbin  "level4_b_4d300.bin",$A878,$30C0
; $5AC38-$5B937: BOB graphics: 16 frames of 208 bytes (Def_PStaffMissile)
Gfx_PStaffMissile:
                incbin  "level4_b_4d300.bin",$D938,$D00
; $5B938-$5E037: BOB graphics: 12 frames of 832 bytes (Def_Bink)
Gfx_Bink:
                incbin  "level4_b_4d300.bin",$E638,$2700
; $5E038-$5F3B7: BOB graphics: 6 frames of 832 bytes (Def_Cancer)
Gfx_Cancer:
                incbin  "level4_b_4d300.bin",$10D38,$1380
; $5F3B8-$625B7: BOB graphics: 16 frames of 800 bytes (Def_Cytron)
Gfx_Cytron:
                incbin  "level4_b_4d300.bin",$120B8,$3200
; $625B8-$665B7: BOB graphics: 16 frames of 1024 bytes (Def_Geld)
Gfx_Geld:
                incbin  "level4_b_4d300.bin",$152B8,$4000
; $665B8-$68417: BOB graphics: 1 frames of 7776 bytes (Def_CompilerA)
Gfx_CompilerA:
                incbin  "level4_b_4d300.bin",$192B8,$1E60
; $68418-$69D77: BOB graphics: 1 frames of 6496 bytes (Def_CompilerB)
Gfx_CompilerB:
                incbin  "level4_b_4d300.bin",$1B118,$1960
; $69D78-$6B6F7: BOB graphics: 1 frames of 6528 bytes (Def_CompilerC)
Gfx_CompilerC:
                incbin  "level4_b_4d300.bin",$1CA78,$1980
; $6B6F8-$6C697: BOB graphics: 5 frames of 800 bytes (Def_CompilerGun)
Gfx_CompilerGun:
                incbin  "level4_b_4d300.bin",$1E3F8,$FA0
; $6C698-$6C817: BOB graphics: 4 frames of 96 bytes (Def_CompilerLaser)
Gfx_CompilerLaser:
                incbin  "level4_b_4d300.bin",$1F398,$180
; $6C818-$6C83A: table read by the level code
Tbl_6C818:
                incbin  "level4_b_4d300.bin",$1F518,$23
; $6C83B-$6C898: table read by the level code
Tbl_6C83B:
                incbin  "level4_b_4d300.bin",$1F53B,$5E
; $6C899-$6C8F6: table read by the level code
Tbl_6C899:
                incbin  "level4_b_4d300.bin",$1F599,$5E
; $6C8F7-$6C95C: table read by the level code
Tbl_6C8F7:
                incbin  "level4_b_4d300.bin",$1F5F7,$66
; $6C95D-$6C9A9: table read by the level code
Tbl_6C95D:
                incbin  "level4_b_4d300.bin",$1F65D,$4D
; $6C9AA-$6C9F6: table read by the level code
Tbl_6C9AA:
                incbin  "level4_b_4d300.bin",$1F6AA,$4D
; $6C9F7-$6CA3B: table read by the level code
Tbl_6C9F7:
                incbin  "level4_b_4d300.bin",$1F6F7,$45
; $6CA3C-$6CA87: table read by the level code
Tbl_6CA3C:
                incbin  "level4_b_4d300.bin",$1F73C,$4C
; $6CA88-$6CAD3: table read by the level code
Tbl_6CA88:
                incbin  "level4_b_4d300.bin",$1F788,$4C
; $6CAD4-$6CB1F: table read by the level code
Tbl_6CAD4:
                incbin  "level4_b_4d300.bin",$1F7D4,$4C
; $6CB20-$6CB6C: table read by the level code
Tbl_6CB20:
                incbin  "level4_b_4d300.bin",$1F820,$4D
; $6CB6D-$6CBB9: table read by the level code
Tbl_6CB6D:
                incbin  "level4_b_4d300.bin",$1F86D,$4D
; $6CBBA-$6CC06: table read by the level code
Tbl_6CBBA:
                incbin  "level4_b_4d300.bin",$1F8BA,$4D
; $6CC07-$6CC56: table read by the level code
Tbl_6CC07:
                incbin  "level4_b_4d300.bin",$1F907,$50
; $6CC57-$6CCA6: table read by the level code
Tbl_6CC57:
                incbin  "level4_b_4d300.bin",$1F957,$50
; $6CCA7-$6CCF6: table read by the level code
Tbl_6CCA7:
                incbin  "level4_b_4d300.bin",$1F9A7,$50
; $6CCF7-$6CD25: table read by the level code
Tbl_6CCF7:
                incbin  "level4_b_4d300.bin",$1F9F7,$2F
; $6CD26-$6CD54: table read by the level code
Tbl_6CD26:
                incbin  "level4_b_4d300.bin",$1FA26,$2F
; $6CD55-$6CD83: table read by the level code
Tbl_6CD55:
                incbin  "level4_b_4d300.bin",$1FA55,$2F
; $6CD84-$6CDD8: table read by the level code
Tbl_6CD84:
                incbin  "level4_b_4d300.bin",$1FA84,$55
; $6CDD9-$6CE2D: table read by the level code
Tbl_6CDD9:
                incbin  "level4_b_4d300.bin",$1FAD9,$55
; $6CE2E-$6CE82: table read by the level code
Tbl_6CE2E:
                incbin  "level4_b_4d300.bin",$1FB2E,$55
; $6CE83-$6CEB4: table read by the level code
Tbl_6CE83:
                incbin  "level4_b_4d300.bin",$1FB83,$32
; $6CEB5-$6CEE6: table read by the level code
Tbl_6CEB5:
                incbin  "level4_b_4d300.bin",$1FBB5,$32
; $6CEE7-$6CF18: table read by the level code
Tbl_6CEE7:
                incbin  "level4_b_4d300.bin",$1FBE7,$32
; $6CF19-$6CF4B: table read by the level code
Tbl_6CF19:
                incbin  "level4_b_4d300.bin",$1FC19,$33
; $6CF4C-$6CF7E: table read by the level code
Tbl_6CF4C:
                incbin  "level4_b_4d300.bin",$1FC4C,$33
; $6CF7F-$6CFB1: table read by the level code
Tbl_6CF7F:
                incbin  "level4_b_4d300.bin",$1FC7F,$33
; $6CFB2-$6EA69: table read by the level code
Tbl_6CFB2:
                incbin  "level4_b_4d300.bin",$1FCB2,$1AB8
LvEnd:                                  ; LevelInit copies the map here
