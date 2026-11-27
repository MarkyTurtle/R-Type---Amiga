;==============================================================================
; R-Type (Amiga) - level 3 data (level part B)
; Loaded to $4D300 ($4D300-$6FCDB); files/level3_b_4d300.bin, byte for byte.
;
; Data, and the level's music player, which only uses PC-relative addresses: so
; the file is here in labelled pieces (incbin), split at every place level A
; points to.  Level A (level3.s) refers to it by these labels, so A and B can be
; assembled together at any address.  Blocks (docs/levelb_layout.txt):
;
; first written by tools/gen_levelb.py; the source of truth from then on.
;==============================================================================
                ifnd    LEVEL_AB
                org     $4D300
                endc

; $4D300-$5AF7F: tiles 0-440 (used by the map)
LvTiles:
                incbin  "level3_b_4d300.bin",$0,$DC80
; $5AF80-$626FF: tiles 441-679, written into the map by PatchMap (the battleship's
;   changing parts: CoreOpenFrames, EngineGoneCells, FlameCells, RearTowerBase...)
                incbin  "level3_b_4d300.bin",$DC80,$7780
; $62700-$634CF: map 68x26
LvMap:
                incbin  "level3_b_4d300.bin",$15400,$DD0
; $634D0-$65A8D: music player: code, variables, songs, patterns (PC-relative)
LvMusic:
                incbin  "level3_b_4d300.bin",$161D0,$25BE
; $65A8E-$65B23: sample table (8), period table
LvMusicSamples:
                incbin  "level3_b_4d300.bin",$1878E,$96
; $65B24-$66E4F: 8 samples
LvMusicSampleData:
                incbin  "level3_b_4d300.bin",$18824,$132C
; $66E50-$66FCF: BOB graphics: 4 frames of 96 bytes (Def_TowerLaser)
Gfx_TowerLaser:
                incbin  "level3_b_4d300.bin",$19B50,$180
; $66FD0-$686CF: BOB graphics: 8 frames of 736 bytes (Def_GunTower)
Gfx_GunTower:
                incbin  "level3_b_4d300.bin",$19CD0,$1700
; $686D0-$69F4F: BOB graphics: 7 frames of 896 bytes (Def_CannonPod)
Gfx_CannonPod:
                incbin  "level3_b_4d300.bin",$1B3D0,$1880
; $69F50-$6AB4F: BOB graphics: 1 frames of 3072 bytes (Def_MainEngine)
Gfx_MainEngine:
                incbin  "level3_b_4d300.bin",$1CC50,$C00
; $6AB50-$6AD0F: BOB graphics: 2 frames of 224 bytes (Def_EngineShot)
Gfx_EngineShot:
                incbin  "level3_b_4d300.bin",$1D850,$1C0
; $6AD10-$6C10F: BOB graphics: 1 frame of 5120 bytes (Def_LaserTower)
Gfx_LaserTower:
                incbin  "level3_b_4d300.bin",$1DA10,$1400
; $6C110-$6F84F: BOB graphics: 17 frames of 832 bytes (Def_Fireball)
Gfx_Fireball:
                incbin  "level3_b_4d300.bin",$1EE10,$3740
; $6F850-$6FACF: BOB graphics: 4 frames of 160 bytes (Def_CoreOrb)
Gfx_CoreOrb:
                incbin  "level3_b_4d300.bin",$22550,$280
; $6FAD0-$6FCA5: table read by the level code
Tbl_6FAD0:
                incbin  "level3_b_4d300.bin",$227D0,$1D6
; $6FCA6-$6FCDB: table read by the level code
Tbl_6FCA6:
                incbin  "level3_b_4d300.bin",$229A6,$36
LvEnd:
