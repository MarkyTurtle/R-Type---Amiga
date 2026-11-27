;==============================================================================
; R-Type (Amiga) - level 7 data (level part B)
; Loaded to $4D300 ($4D300-$7108E); files/level7_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level7.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$56FFF: tiles 0-313 (used by the map)
LvTiles:
                incbin  "level7_b_4d300.bin",$0,$9D00
; $57000-$572FF: (not used by the code that is known)
                incbin  "level7_b_4d300.bin",$9D00,$300
; $57300-$582A3: map 154x13
LvMap:
                incbin  "level7_b_4d300.bin",$A000,$FA4
; $582A4-$5A913: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level7_b_4d300.bin",$AFA4,$2670
; $5A914-$5A9A9: sample table (8), period table
LvMusicSamples:
                incbin  "level7_b_4d300.bin",$D614,$96
; $5A9AA-$5BCD5: 8 samples
LvMusicSampleData:
                incbin  "level7_b_4d300.bin",$D6AA,$132C
; $5BCD6-$5CFD5: BOB graphics: 8 frames of 608 bytes (Def_PataPata)
Gfx_PataPata:
                incbin  "level7_b_4d300.bin",$E9D6,$1300
; $5CFD6-$5E4D5: BOB graphics: 8 frames of 672 bytes (Def_Bug)
Gfx_Bug:
                incbin  "level7_b_4d300.bin",$FCD6,$1500
; $5E4D6-$5FF45: BOB graphics: 3 frames of 2256 bytes (Def_Scant)
Gfx_Scant:
                incbin  "level7_b_4d300.bin",$111D6,$1A70
; $5FF46-$60545: BOB graphics: 2 frames of 768 bytes (Def_ScantBeam)
Gfx_ScantBeam:
                incbin  "level7_b_4d300.bin",$12C46,$600
; $60546-$63605: BOB graphics: 15 frames of 832 bytes (Def_PStaff)
Gfx_PStaff:
                incbin  "level7_b_4d300.bin",$13246,$30C0
; $63606-$64305: BOB graphics: 16 frames of 208 bytes (Def_PStaffMissile)
Gfx_PStaffMissile:
                incbin  "level7_b_4d300.bin",$16306,$D00
; $64306-$66A05: BOB graphics: 12 frames of 832 bytes (Def_Bink)
Gfx_Bink:
                incbin  "level7_b_4d300.bin",$17006,$2700
; $66A06-$67D85: BOB graphics: 6 frames of 832 bytes (Def_Cancer)
Gfx_Cancer:
                incbin  "level7_b_4d300.bin",$19706,$1380
; $67D86-$68025: BOB graphics: 1 frames of 672 bytes (Def_Crawler)
Gfx_Crawler:
                incbin  "level7_b_4d300.bin",$1AA86,$2A0
; $68026-$68FA5: BOB graphics: 4 frames of 992 bytes (Def_Junk)
Gfx_Junk:
                incbin  "level7_b_4d300.bin",$1AD26,$F80
; $68FA6-$69BA5: BOB graphics: 1 frames of 3072 bytes (Def_Bold)
Gfx_Bold:
                incbin  "level7_b_4d300.bin",$1BCA6,$C00
; $69BA6-$6BFA5: BOB graphics: 4 frames of 2304 bytes (Def_Bronco)
Gfx_Bronco:
                incbin  "level7_b_4d300.bin",$1C8A6,$2400
; $6BFA6-$6F485: BOB graphics: 9 frames of 1504 bytes (Def_Sonar)
Gfx_Sonar:
                incbin  "level7_b_4d300.bin",$1ECA6,$34E0
; $6F486-$6F605: BOB graphics: 4 frames of 96 bytes (Def_CheetahBeam)
Gfx_CheetahBeam:
                incbin  "level7_b_4d300.bin",$22186,$180
; $6F606-$70A05: BOB graphics: 8 frames of 640 bytes (Def_MidCheetah)
Gfx_MidCheetah:
                incbin  "level7_b_4d300.bin",$22306,$1400
; $70A06-$70A28: table read by the level code
Tbl_70A06:
                incbin  "level7_b_4d300.bin",$23706,$23
; $70A29-$70A86: table read by the level code
Tbl_70A29:
                incbin  "level7_b_4d300.bin",$23729,$5E
; $70A87-$70AE4: table read by the level code
Tbl_70A87:
                incbin  "level7_b_4d300.bin",$23787,$5E
; $70AE5-$70B4B: table read by the level code
Tbl_70AE5:
                incbin  "level7_b_4d300.bin",$237E5,$67
; $70B4C-$70B98: table read by the level code
Tbl_70B4C:
                incbin  "level7_b_4d300.bin",$2384C,$4D
; $70B99-$70BE5: table read by the level code
Tbl_70B99:
                incbin  "level7_b_4d300.bin",$23899,$4D
; $70BE6-$70C2C: table read by the level code
Tbl_70BE6:
                incbin  "level7_b_4d300.bin",$238E6,$47
; $70C2D-$70C83: table read by the level code
Tbl_70C2D:
                incbin  "level7_b_4d300.bin",$2392D,$57
; $70C84-$70CDA: table read by the level code
Tbl_70C84:
                incbin  "level7_b_4d300.bin",$23984,$57
; $70CDB-$70D2E: table read by the level code
Tbl_70CDB:
                incbin  "level7_b_4d300.bin",$239DB,$54
; $70D2F-$70D78: table read by the level code
Tbl_70D2F:
                incbin  "level7_b_4d300.bin",$23A2F,$4A
; $70D79-$70E4E: table read by the level code
Tbl_70D79:
                incbin  "level7_b_4d300.bin",$23A79,$D6
; $70E4F-$70E98: table read by the level code
Tbl_70E4F:
                incbin  "level7_b_4d300.bin",$23B4F,$4A
; $70E99-$70F6E: table read by the level code
Tbl_70E99:
                incbin  "level7_b_4d300.bin",$23B99,$D6
; $70F6F-$70FB8: table read by the level code
Tbl_70F6F:
                incbin  "level7_b_4d300.bin",$23C6F,$4A
; $70FB9-$7108E: table read by the level code
Tbl_70FB9:
                incbin  "level7_b_4d300.bin",$23CB9,$D6
LvEnd:
