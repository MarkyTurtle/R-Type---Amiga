;==============================================================================
; R-Type (Amiga) - level 3 code and data (level part A)
; Tracks 98.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level3_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level3_a.bin src/levels/level3.s
;
; TEXT $4A300-$4B3DB: level table, wave list, palette, scroll script, code
; DATA $4B3DC-$4C393: object definitions, animations, tables
; $4C394 on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; Stage 3, the Mega Battleship: the level is the ship itself.  Parts: gun
; towers, cannon pods, the main engine, the laser tower, hull parts that
; shoot (Def_ShipPart), the rear tower, and the Main Core in the engine
; room.  Names follow the arcade where the behaviour matches.
;==============================================================================
                include "engine.i"
                ifnd    LEVEL_AB
                include "level3_b.i"           ; level B's labels (tools/verify.py writes it
                endc                            ;  from level3_b.s)

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$10DC,$0000,$0FB8,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0004,$A300,$0001
; Level interface table, read by the engine (equates LV_* in game.s):
;   $4A300 magic $03011969  | $4A304 checkpoint list | $4A308 palette (15)
;   $4A30C map (level B)    | $4A310 tiles (level B) | $4A314 scroll script
;   $4A318 tile animations  | $4A31C map patches     | $4A320 every frame
;   $4A324 level start      | $4A328 music player    | ($4A32C level 8:
;   ending music; other levels: the scroll script usually starts here)
; Formats: docs/DATA_FORMATS.md
; Level 3 is the giant battleship: the map (68 x 26 tiles) is the ship
; itself, and the scroll script moves it vertically as well as horizontally.
LevelInterface:
                dc.w    $0301,$1969
                dc.l    WaveList
                dc.l    LevelPalette
                dc.l    LvMap
                dc.l    LvTiles          ; tiles: the start of level B
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    LvMusic          ; LvMusic: player in level B; samples $65A8E (8), data $65B24, periods $65ACE
ScrollScript:
                dc.w    $0009,$0000,$014A,$0008,$FFF7,$0054,$0008,$0000
                dc.w    $0064,$0008,$0007,$0064,$0000,$0000,$000F,$0008
                dc.w    $FFF6,$0023,$0000,$0000,$0005,$0008,$FFF7,$0078
                dc.w    $0000,$0000,$0014,$0008,$0008,$0104,$0000,$0008
                dc.w    $0096,$0000,$0000,$0011,$000A,$FFFF,$0078,$0007
                dc.w    $0000,$0028,$0000,$0000,$0014,$0008,$FFFF,$0078
                dc.w    $0007,$0000,$003E,$0008,$0001,$0028,$0007,$0000
                dc.w    $0055,$0008,$FFFF,$003C,$0007,$0000,$0050,$0008
                dc.w    $0001,$005A,$0007,$0000,$008C,$0000,$0000,$000F
                dc.w    $0005,$FFF7,$00AA,$0000,$0000,$0005,$0009,$0003
                dc.w    $00B9,$0008,$FFFF,$0046,$0008,$0001,$0046,$0000
                dc.w    $0000,$0005,$0008,$0000,$0032,$0009,$FFF7,$001E
                dc.w    $0000,$0000,$0003,$000A,$FFF7,$001E,$0000,$0000
                dc.w    $0007,$0000,$FFF8,$00A0,$FFF8,$0006,$006E,$FFFF
                dc.w    $000A,$0032,$0000,$0000,$0007,$0000,$FFF6,$0054
                dc.w    $0008,$0009,$0078,$0000,$0009,$003C,$FFF8,$FFF8
                dc.w    $008C,$0000,$0000,$0007,$0004,$FFF8,$0078,$0000
                dc.w    $0000,$0005,$0007,$0000,$005A,$FFFE,$000A,$008C
                dc.w    $FFFD,$FFF6,$0028,$0009,$FFFE,$0050,$0000,$0000
                dc.w    $000A,$FFF8,$FFF8,$0078,$FFF8,$0000,$0032,$0000
                dc.w    $0000,$0007,$0000,$0008,$002B,$0000,$0000,$0005
                dc.w    $0000,$0008,$002B,$0000,$0000,$0007,$0008,$0000
                dc.w    $008C,$0000,$0000,$000A,$0000,$0008,$006E,$0000
                dc.w    $0000,$0005,$FFFC,$FFF8,$00B4,$0000,$0000,$0006
                dc.w    $0008,$0000,$003C,$0000,$0000,$0005,$0008,$0000
                dc.w    $0014,$0000,$0000,$0005,$FFF8,$0000,$0014,$0000
                dc.w    $0000,$0005,$FFFA,$FFFA,$0014,$0000,$0000,$0008
                dc.w    $FFFA,$0006,$0014,$0000,$0000,$0008,$0006,$0006
                dc.w    $0019,$0000,$0000,$0008,$FFFA,$FFFA,$0019,$0000
                dc.w    $0000,$0008,$0006,$0006,$001E,$0000,$0000,$0008
                dc.w    $0006,$0000,$0023,$0000,$0000,$0008,$0006,$FFFA
                dc.w    $0014,$0000,$0000,$0008,$FFFA,$FFFA,$001E,$0000
                dc.w    $0000,$0008,$0000,$000A,$0087,$0000,$0000,$0008
                dc.w    $0000,$FFF7,$012C,$0000,$0000,$2710,$0000,$0000
                dc.w    $FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
Waves:
                dc.w    $002D,$0170,$0066
                dc.l    $00000000,$00000000,Def_MainEngine
                dc.w    $009C,$016F,$0036
                dc.l    $00000008,$00000000,Def_GunTower
                dc.w    $00EB,$0170,$0028
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $010F,$015F,$002E
                dc.l    $00000008,$00000000,Def_GunTower
                dc.w    $012C,$0170,$00A9
                dc.l    $00010008,$00000000,Def_GunTower
                dc.w    $0163,$015D,$003C
                dc.l    $00000008,$00000000,Def_GunTower
                dc.w    $01BD,$015D,$003B
                dc.l    $00000008,$00000000,Def_GunTower
                dc.w    $01E0,$015E,$001E
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $02D2,$0170,$00D3
                dc.l    $0001001E,$00000000,Def_GunTower
                dc.w    $032F,$00F8,$00DF
                dc.l    $0001001E,$00000000,Def_GunTower
                dc.w    $0514,$013A,$0088
                dc.l    $00000000,$00000000,Def_LaserTower
                dc.w    $055A,$0154,$0091
                dc.l    $0001FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $07D0,$015B,$008C
                dc.l    $00010032,$00000000,Def_GunTower
                dc.w    $085B,$010C,$0009
                dc.l    $00000003,$00000000,Def_GunTower
                dc.w    $0870,$0159,$009A
                dc.l    $00000008,CannonPodData1,Def_CannonPod
                dc.w    $0898,$016E,$0018
                dc.l    $00000006,$00000000,Def_GunTower
                dc.w    $08CB,$015D,$00AE
                dc.l    $00000004,CannonPodData2,Def_CannonPod
                dc.w    $08D4,$0164,$00A0
                dc.l    $00000004,CannonPodData2,Def_CannonPod
                dc.w    $094C,$0162,$0046
                dc.l    $00000004,CannonPodData3,Def_CannonPod
                dc.w    $094D,$015F,$006A
                dc.l    $00000004,CannonPodData4,Def_CannonPod
                dc.w    $094E,$0167,$0058
                dc.l    $00000004,CannonPodData5,Def_CannonPod
                dc.w    $0993,$0168,$0082
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $FFFF   ; end: never reached
LevelPalette:
                dc.w    $0565,$0BBB,$0777,$0500,$005F,$0343,$0DB0,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0D70,$0FF0,$0FFF
; Level 3, the battleship: the ship is a 26-row map that the scroll script
; moves past in x and y (ScrollY starts at $78), and its parts are map
; cells plus invisible targets.  Waves are triggered by a frame counter.
; LevelInit: ScrollY, the part list, the 10 initial map blocks (gun
; mounts etc., PatchMap), the engine room's state, ShipTimer = 5575
; frames (when it runs out the level ends: the battleship has gone by),
; and the rear tower.
LevelInit:
                move.w  #$78,(ScrollY).w        ; the battleship starts 120 lines down
                move.l  #ShipParts,(NextShipPart).l ; hull parts, by frame
                clr.w   (FrameCount).l
                lea.l   (InitialBlocks).l,a4    ; 10 blocks of map cells
                moveq   #9,d7
.4A71E:
                movea.l (a4)+,a0
                bsr.w   PatchMap
                dbra    d7,.4A71E
                move.l  #EngineRoom,(EngineRoomState).l
                move.l  #CoreIdleFrames,(CoreFramePtr).l ; 5575 frames until it has gone by
                clr.b   (OrbTimer).l
                clr.w   (CoreSteps).l
                clr.w   (CoreTimer).l
                clr.b   (BossDead).l
                move.w  #$15C7,(ShipTimer).l
                bra.w   InitRearTower
; LevelFrame: counts frames; when the next entry of ShipParts is due its
; invisible target (Def_ShipPart) is created.  Then the boss phase and the
; rear tower.
LevelFrame:
                addq.w  #$1,(FrameCount).l
                movea.l (NextShipPart).l,a1     ; next hull part (20 bytes each)
                move.w  (FrameCount).l,d0
                cmp.w   (a1)+,d0                ; due at this frame?
                bcs.b   .4A784
                bsr.w   .4A79E                  ; create it
                addi.l  #$14,(NextShipPart).l
.4A784:
                subq.w  #$1,(ShipTimer).l       ; battleship gone by:
                bpl.b   .4A796
                st.b    (BossDead).l            ; the level ends
                st.b    (LevelComplete).w
.4A796:
                bsr.w   BossPhase
                bra.w   UpdateRearTower
.4A79E:
                movem.w (a1)+,d0-d1             ; x, y
                move.w  #$3E8,d2                ; 1000 hit points: only the hit count matters
                lea.l   (Def_ShipPart).l,a2     ; an invisible target
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.w  (a1)+,d0                ; hits to destroy it
                move.b  d0,$36(a0)
                move.w  (a1)+,d0                ; explosions when it goes
                move.b  d0,$3C(a0)
                move.w  (a1)+,d0                ; which gun (PartGunOffsets)
                move.b  d0,$3D(a0)
                clr.b   $37(a0)                 ; fire timer
                move.l  $4(a1),$32(a0)          ; its wrecked cells
                move.w  (ScrollX).w,$38(a0)     ; scroll position now (FollowScroll)
                move.w  (ScrollY).w,$3A(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a1),a0                 ; then patch the map with the part itself
; PatchMap: a0 = block: map address.l, width-1.b, height-1.b, then the
; cells row by row - written straight into the map (parts appear, open,
; burn or are destroyed this way).
PatchMap:
                moveq   #0,d0
                moveq   #0,d1
                movea.l (a0)+,a1                ; map address
                move.b  (a0)+,d0                ; width - 1
                move.b  (a0)+,d1                ; height - 1
.4A7EC:
                move.w  d0,d2
                movea.l a1,a2                   ; one row
.4A7F0:
                move.w  (a0)+,(a2)+
                dbra    d2,.4A7F0
                adda.l  (MapRowBytes).w,a1      ; next map row
                dbra    d1,.4A7EC
                rts
; Upd_ShipPart: a gun or panel of the hull.  It moves with the map
; (FollowScroll), fires a bullet every 30-80 frames from its gun offset
; (PartGunOffsets), and after its number of hits leaves a trail of
; explosions and patches the map with its wrecked cells.
Upd_ShipPart:
                bsr.w   FollowScroll                ; stay on the hull
                subq.b  #$1,$37(a0)                 ; fire every 30-80 frames
                bpl.b   .4A838
                moveq   #50,d0
                jsr     (jt_Random).w
                add.w   #$1E,d0
                move.b  d0,$37(a0)
                movem.w $A(a0),d0-d1
                moveq   #0,d2
                move.b  $3D(a0),d2
                lsl.w   #$2,d2
                lea.l   (PartGunOffsets).l,a1       ; from its gun
                add.w   (a1,d2.w),d0
                add.w   $2(a1,d2.w),d1
                jsr     (jt_FireEnemyBullet).w
.4A838:
                moveq   #0,d0
                move.b  $36(a0),d0
                cmp.w   $26(a0),d0                  ; enough hits?
                bhi.b   .4A85E
                tst.b   $3C(a0)                     ; explosions still to go?
                bne.b   .4A860
                movea.l a0,a3
                movea.l $32(a0),a0
                bsr.b   PatchMap                    ; none left: wreck cells into the map, gone
                movea.l a3,a0
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
.4A85E:
                rts
.4A860:
                subq.b  #$1,$3C(a0)                 ; one more explosion
                move.w  #$FFFF,$24(a0)              ; (indestructible meanwhile)
                move.l  a0,-(a7)
                moveq   #50,d0                  ; at a random x along it
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                move.w  $C(a0),d1
                moveq   #-1,d2                  ; plain explosion
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)              ; exploding at once
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
; FollowScroll: keeps an object fixed to the map as ScrollX/ScrollY change.
FollowScroll:
                move.w  (ScrollX).w,d0          ; scroll x moved by
                move.w  d0,d1
                sub.w   $38(a0),d0
                move.w  d1,$38(a0)
                sub.w   d0,$A(a0)               ; move the object the other way
                move.w  (ScrollY).w,d0          ; the same for y
                move.w  d0,d1
                sub.w   $3A(a0),d0
                move.w  d1,$3A(a0)
                sub.w   d0,$C(a0)
                rts
BossPhase:
                tst.b   (BossDead).l            ; core destroyed:
                beq.b   .4A912
.4A8C0:
                move.w  #$96,d0                 ; an explosion every frame: y = core y - 80 + random(150)
                jsr     (jt_Random).w
                sub.w   #$50,d0
                add.w   (CoreY).l,d0
                move.w  d0,d1
                bmi.b   .4A8C0                  ; on screen
                cmp.w   #$E0,d1
                bhi.b   .4A8C0
.4A8DC:
                move.w  #$A0,d0                 ; x = core x + random(160)
                jsr     (jt_Random).w
                add.w   (CoreX).l,d0
                bmi.b   .4A8DC                  ; on screen
                cmp.w   #$15E,d0
                bhi.b   .4A8DC
                moveq   #-1,d2
                lea.l   (Def_BattleshipCore).l,a2 ; as a plain explosion
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)                  ; exploding at once
                move.b  #$1,$5(a0)
                move.b  #$A,$4(a0)              ; priority 10
                jmp     (jt_ObjInsert).w
.4A912:
                movea.l (EngineRoomState).l,a1  ; engine room state routine
                jmp     (a1)
; EngineRoom (the boss, from frame $5F0): the core's chamber animates in the
; map (CoreIdleFrames) and between frames $5F0 and $AF0 it sends out a
; CoreOrb every 10 frames; at frame $A8C the core target is created (and
; the music fades), then the core opens (CoreOpenFrames) and closes in a
; cycle.
EngineRoom:
                cmpi.w  #$5F0,(FrameCount).l    ; from frame $5F0
                bcs.b   .4A972
                cmpi.w  #$AF0,(FrameCount).l    ; until $AF0:
                bcs.b   .4A942
                subq.b  #$1,(OrbTimer).l        ; a CoreOrb every 11 frames
                bpl.b   .4A942
                move.b  #$A,(OrbTimer).l
                bsr.w   Spawn_CoreOrb
.4A942:
                subq.w  #$1,(CoreTimer).l       ; chamber animation: every 4 frames
                bpl.b   .4A972
                move.w  #$3,(CoreTimer).l
                movea.l (CoreFramePtr).l,a1     ; next idle frame
                cmpa.l  #CoreOpenFrames,a1      ; past the idle frames:
                bcs.b   .4A966
                lea.l   (CoreIdleFrames).l,a1   ; start them again
.4A966:
                movea.l (a1)+,a0
                move.l  a1,(CoreFramePtr).l
                bsr.w   PatchMap                ; write it into the map
.4A972:
                cmpi.w  #$A8C,(FrameCount).l    ; at frame $A8C:
                bne.b   .4A998
                moveq   #122,d0                 ; the Main Core target
                moveq   #98,d1
                moveq   #-1,d2                  ; indestructible: hits counted by its update
                lea.l   (Def_BattleshipCore).l,a2
                jsr     (jt_ObjCreate).w
                clr.w   $32(a0)                 ; damage seen
                jsr     (jt_ObjInsert).w
                st.b    (MusicFadeReq).w        ; fade the level music out
.4A998:
                bcs.b   .4A9C4                  ; (flags from the compare: before $A8C, done)
                subq.w  #$1,(CoreSteps).l       ; from then on, after CoreSteps frames
                bpl.b   .4A9C4
                move.l  #.4A9C6,(EngineRoomState).l ; open the core
                move.l  #CoreOpenFrames,(CoreFramePtr).l ; CoreOpenFrames: 11 opening, then 11 closing
                clr.w   (CoreTimer).l
                move.w  #$B,(CoreSteps).l       ; 11 steps
.4A9C4:
                rts
.4A9C6:
                subq.w  #$1,(CoreTimer).l
                bpl.b   .4A9C4
                bsr.w   .4AA36                  ; next step (every 3 frames)
                bne.b   .4A9C4                  ; all 11?
                move.w  #$19,(CoreTimer).l      ; stay open 26 frames
                move.l  #.4A9E8,(EngineRoomState).l
                rts
.4A9E8:
                subq.w  #$1,(CoreTimer).l
                bpl.b   .4AA02
                move.w  #$B,(CoreSteps).l       ; then close: 11 steps
                move.l  #.4AA04,(EngineRoomState).l
.4AA02:
                rts
.4AA04:
                subq.w  #$1,(CoreTimer).l
                bpl.b   .4AA02
                bsr.w   .4AA36                  ; next step
                bne.b   .4AA02                  ; all 11?
                move.l  #EngineRoom,(EngineRoomState).l ; closed: back to idle
                clr.w   (CoreTimer).l
                move.l  #CoreIdleFrames,(CoreFramePtr).l
                move.w  #$7D,(CoreSteps).l      ; for 125 frames
                rts
.4AA36:
                move.w  #$2,(CoreTimer).l       ; 3 frames to the next step
                movea.l (CoreFramePtr).l,a1
                movea.l (a1)+,a0                ; next cell block
                move.l  a1,(CoreFramePtr).l
                bsr.w   PatchMap                ; write it into the map
                subq.w  #$1,(CoreSteps).l       ; Z set when the last is done
                rts
; Upd_BattleshipCore: the Main Core, the battleship's weak point.  Moves
; with the map, flashes when hit; 10 hits destroy it (no score; BossDead,
; LevelComplete), then BossPhase keeps setting off explosions round it.
Upd_BattleshipCore:
                movem.w $A(a0),d0-d1
                jsr     (jt_AdjustForScroll).w      ; stay on the hull
                movem.w d0-d1,$A(a0)
                movem.w d0-d1,(CoreX).l             ; for the orbs and the final explosions
                move.w  $26(a0),d0
                cmp.w   $32(a0),d0                  ; hit this frame?
                beq.b   .4AA94
                move.w  d0,$32(a0)
                move.b  #$3,$28(a0)                 ; flash
                cmp.w   #$A,d0                      ; 10 hits:
                bcs.b   .4AA94
                st.b    (BossDead).l                ; the battleship is beaten
                st.b    (LevelComplete).w
.4AA94:
                rts
Spawn_CoreOrb:
                movea.l a0,a4
                movem.w (CoreX).l,d0-d1         ; from the core chamber
                sub.w   #$23,d0
                sub.w   #$14,d1
                moveq   #1,d2
                lea.l   (Def_CoreOrb).l,a2
                jsr     (jt_ObjCreate).w
                moveq   #7,d0                   ; start at a random point of the wave (0-6)
                jsr     (jt_Random).w
                move.w  d0,$32(a0)
.4AABE:
                moveq   #4,d0                   ; x step: 2 or 1 to the right, or 1 to the left
                jsr     (jt_Random).w
                subq.w  #$2,d0
                neg.w   d0
                beq.b   .4AABE
                move.w  d0,$34(a0)
                move.b  #$1,$21(a0)             ; explosion type 1
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                rts
Upd_CoreOrb:
                movem.w $A(a0),d0-d1            ; on the map?
                addq.w  #$8,d0
                addq.w  #$8,d1
                jsr     (jt_GetMapCell).w
                beq.b   .4AAF8
                move.b  #$1,$5(a0)              ; burst
                clr.l   $6(a0)
                rts
.4AAF8:
                lea.l   (Tbl_6FCA6).l,a1           ; wave: signed y steps, $7F ends (level B)
                move.w  $32(a0),d2
                move.b  (a1,d2.w),d1
                cmp.b   #$7F,d1                 ; at the end:
                bne.b   .4AB12
                subq.w  #$1,$32(a0)             ; keep the last step
                bra.b   .4AAF8
.4AB12:
                addq.w  #$1,$32(a0)
                ext.w   d1
                move.w  $34(a0),d0
                add.w   $A(a0),d0               ; off the screen:
                bmi.b   .4AB3C
                cmp.w   #$170,d0
                bhi.b   .4AB3C
                add.w   $C(a0),d1
                bmi.b   .4AB3C
                cmp.w   #$E0,d1
                bhi.b   .4AB3C
                movem.w d0-d1,$A(a0)
                rts
.4AB3C:
                jmp     (jt_ObjKillSelf).w      ; remove
Spawn_GunTower:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2                  ; hit points come from the wave entry
                jsr     (jt_ObjCreate).w
                move.w  $8(a1),$24(a0)          ; entry $08: hit points
                move.w  (ScrollX).w,$38(a0)     ; scroll position now (FollowScroll)
                move.w  (ScrollY).w,$3A(a0)
                clr.b   $37(a0)                 ; fire at once
                clr.b   $22(a0)                 ; frame is set by the update
                clr.w   $32(a0)
                tst.w   $6(a1)                  ; entry $06 non-zero:
                beq.b   .4AB78
                move.l  #GunTowerAnimFlipped,$2A(a0) ; upside down
.4AB78:
                jmp     (jt_ObjInsert).w
Spawn_CannonPod:
                movem.w $2(a1),d0-d1
                move.w  #$1F40,d2               ; 8000 hit points: only the hit count matters
                jsr     (jt_ObjCreate).w
                move.b  $9(a1),$3C(a0)          ; entry $09: hits to knock it out
                move.l  $A(a1),$2A(a0)          ; entry $0A: its animation
                move.w  (ScrollX).w,$38(a0)     ; scroll position now (FollowScroll)
                move.w  (ScrollY).w,$3A(a0)
                move.l  $A(a0),$32(a0)          ; its real position
                move.b  #$32,$36(a0)            ; first shot after 50 frames
                move.b  #$1,$37(a0)             ; out
                clr.b   $22(a0)                 ; frame is set by the update
                jmp     (jt_ObjInsert).w
Upd_GunTower:
                bsr.w   FollowScroll            ; move with the hull
                movem.w $A(a0),d0-d1            ; off the screen:
                cmp.w   #$10,d0
                bcs.b   .4ABDE
                cmp.w   #$172,d0
                bhi.b   .4ABDE
                cmp.w   #$9,d1
                bcs.b   .4ABDE
                cmp.w   #$E0,d1
                bcs.b   .4ABE2
.4ABDE:
                jmp     (jt_ObjKillSelf).w      ; remove
.4ABE2:
                movem.w (ShipPos).w,d2-d3       ; turn towards the ship
                jsr     (jt_DirectionTo).w
                move.w  d0,$1E(a0)
                subq.b  #$1,$37(a0)             ; fire timer
                bpl.b   .4AC2A
                moveq   #50,d0                  ; next shot in 30-79 frames
                jsr     (jt_Random).w
                add.w   #$1E,d0
                move.b  d0,$37(a0)
                movem.w $A(a0),d0-d1
                move.w  $1E(a0),d2              ; the current frame
                movea.l $2A(a0),a1
                move.b  (a1,d2.w),d2
                lea.l   (GunTowerMuzzles).l,a1  ; its muzzle offset
                lsl.w   #$2,d2
                add.w   (a1,d2.w),d0
                add.w   $2(a1,d2.w),d1
                jsr     (jt_FireEnemyBullet).w  ; fire at the ship
.4AC2A:
                rts
Upd_CannonPod:
                move.l  $32(a0),$A(a0)          ; back to its real position
                bsr.w   FollowScroll            ; move with the hull
                movem.w $A(a0),d0-d1
                movem.w d0-d1,$32(a0)           ; and remember it
                tst.b   $37(a0)                 ; blinking (coming out)?
                bmi.w   .4AD84
                beq.w   .4AD58                  ; hidden?
                cmp.w   #$10,d0                 ; out: off the screen?
                bcs.b   .4AC66
                cmp.w   #$172,d0
                bhi.b   .4AC66
                cmp.w   #$10,d1
                bcs.b   .4AC66
                cmp.w   #$DC,d1
                bcs.b   .4AC6A
.4AC66:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AC6A:
                move.b  $3C(a0),d2              ; hits needed
                cmp.b   $27(a0),d2              ; reached (low byte of the damage)?
                bhi.b   .4ACB0
                movea.l a0,a3                   ; yes: an explosion over it
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (Def_CannonPod).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)             ; drawn on top
                move.b  #$1,$5(a0)              ; exploding at once
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                clr.b   $37(a0)                 ; and it hides again (not destroyed: no score)
                move.b  #$6E,$36(a0)            ; for 220 frames
                move.w  #$FFFF,$A(a0)           ; out of sight
                rts
.4ACB0:
                movem.w (ShipPos).w,d2-d3       ; turn towards the ship
                jsr     (jt_DirectionTo).w
                move.w  d0,$1E(a0)
                movea.l $2A(a0),a1              ; the frame's mount direction 0-7
                move.b  (a1,d0.w),d0
                and.w   #$7,d0
                lea.l   (CannonPodSteps).l,a1   ; slide along the mount that way
                move.w  d0,d7
                lsl.w   #$2,d0
                movem.w (a1,d0.w),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                subq.b  #$1,$36(a0)             ; time to fire?
                bne.b   .4AD56
                movea.l a0,a4
                moveq   #-1,d2
                movem.w $A(a0),d0-d1            ; on the screen?
                cmp.w   #$170,d0
                bhi.b   .4AD48
                cmp.w   #$10,d1
                bcs.b   .4AD48
                cmp.w   #$DF,d1
                bhi.b   .4AD48
                lea.l   (Def_Fireball).l,a2     ; a Fireball
                jsr     (jt_ObjCreate).w
                move.b  #$1,$4(a0)              ; priority 1
                move.w  #$3,$1E(a0)
                move.b  d7,$3C(a0)              ; its direction 0-7
                lea.l   (FireballLaunches).l,a3 ; launch path and animation for the direction
                lsl.w   #$3,d7
                move.l  $4(a3,d7.w),$2A(a0)
                move.l  (a3,d7.w),$32(a0)
                move.l  $A(a4),$36(a0)          ; launched from the pod's position
                clr.w   $A(a0)
                move.b  #$4,$3A(a0)             ; 4 launch steps
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
.4AD48:
                moveq   #100,d0                 ; next shot in 150-249 frames
                jsr     (jt_Random).w
                add.w   #$96,d0
                move.b  d0,$36(a0)
.4AD56:
                rts
.4AD58:
                btst.b  #$0,(FrameCountLo).l    ; hidden: count every other frame
                bne.b   .4AD7C
                subq.b  #$1,$36(a0)
                bne.b   .4AD7C
                st.b    $37(a0)                 ; then blink for 40 frames
                move.b  #$28,$36(a0)
                clr.b   $3D(a0)
                move.w  #$FFFF,$24(a0)          ; invulnerable meanwhile
.4AD7C:
                move.w  #$FFFF,$A(a0)           ; out of sight
                rts
.4AD84:
                subq.b  #$1,$36(a0)             ; blinking:
                bne.b   .4ADA2
                move.b  #$1,$37(a0)             ; then out
                move.b  #$19,$36(a0)            ; first shot after 25 frames
                move.w  #$FA0,$24(a0)           ; 4000 hit points: only the hit count matters
                clr.w   $26(a0)                 ; hits from now
                bra.b   .4ADB2
.4ADA2:
                eori.b  #$FF,$3D(a0)            ; shown every other frame
                bne.b   .4ADB2
                move.w  #$FFFF,$A(a0)           ; hidden this frame
                rts
.4ADB2:
                movem.w $32(a0),d0-d1           ; shown: at its real position
                movem.w d0-d1,$A(a0)
                bra.w   .4ACB0
Upd_Fireball:
                tst.b   $3A(a0)                 ; launching?
                beq.b   .4ADEC
                subq.b  #$1,$3A(a0)
                movem.w $36(a0),d0-d1           ; pod position
                movea.l $32(a0),a1              ; plus the next launch offset
                add.w   (a1)+,d0
                add.w   (a1)+,d1
                movem.w d0-d1,$A(a0)
                move.l  a1,$32(a0)
                tst.b   $3A(a0)                 ; launch done?
                beq.b   .4ADEC
                rts
.4ADEC:
                moveq   #0,d0
                move.b  $3C(a0),d0              ; direction
                lsl.w   #$2,d0
                lea.l   (FireballSteps).l,a1    ; straight on: dx, dy for it
                movem.w (a1,d0.w),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                cmpi.w  #$170,$A(a0)            ; off the screen:
                bhi.b   .4AE20
                cmpi.w  #$10,$C(a0)
                bcs.b   .4AE20
                cmpi.w  #$E0,$C(a0)
                bcs.b   .4AE24
.4AE20:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AE24:
                rts
Spawn_MainEngine:
                clr.w   (FlameToggle).l
                move.l  #Flame_Wait,(FlameState).l ; flame: off for 100 frames first
                move.w  #$64,(FlameTimer).l
                movem.w $2(a1),d0-d1
                move.w  #$BB8,d2                ; 3000 hit points: the damage checks decide
                jsr     (jt_ObjCreate).w
                move.b  #$1,$4(a0)              ; priority 1
                move.w  (ScrollX).w,$38(a0)     ; scroll position now (FollowScroll)
                move.w  (ScrollY).w,$3A(a0)
                move.b  #$19,$3D(a0)            ; 25 explosions when it goes
                move.b  #$32,$32(a0)            ; first volley after 50 frames
                clr.w   $34(a0)                 ; breakaway path step
                move.w  #$3E8,$36(a0)           ; breaks away after 1000 frames anyway
                jmp     (jt_ObjInsert).w
Upd_MainEngine:
                cmpi.w  #$1E,$26(a0)            ; 30 damage:
                bcc.w   .4AF2A                  ; explode
                cmpi.w  #$14,$26(a0)            ; more than 20:
                bhi.b   .4AE90                  ; break away
                subq.w  #$1,$36(a0)             ; or 1000 frames up:
                bpl.b   .4AEDE
.4AE90:
                st.b    (EngineDead).l          ; breaking away: the flame stops
                clr.w   (FlameTimer).l
                lea.l   (Tbl_6FAD0).l,a1           ; path: dx table, dy table 235 bytes on (level B)
                move.w  $34(a0),d2
                cmpi.w  #$EA,$34(a0)            ; after 234 steps
                bcc.w   .4AF2A                  ; it explodes
                move.b  (a1,d2.w),d0
                add.w   #$EB,d2
                move.b  (a1,d2.w),d1
                ext.w   d0
                ext.w   d1
                add.w   d1,$C(a0)
                add.w   d0,$A(a0)               ; (no longer fixed to the hull)
                bmi.b   .4AED2                  ; off the left or the bottom:
                cmpi.w  #$D0,$C(a0)
                bcs.b   .4AED6
.4AED2:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AED6:
                addq.w  #$1,$34(a0)             ; next step
                bra.w   .4AF9C
.4AEDE:
                bsr.w   FollowScroll            ; on the hull: move with it
                bsr.w   .4AF9C                  ; and run the flame
                subq.b  #$1,$32(a0)             ; volley due?
                bpl.b   .4AF28
                move.b  #$23,$32(a0)            ; every 36 frames
                movea.l a0,a4
                lea.l   (EngineShotDirs).l,a3   ; per shot: y offset, dx, dy
                moveq   #2,d7                   ; 3 shots
.4AEFC:
                movem.w $A(a4),d0-d1
                add.w   #$10,d0                 ; from 16 pixels in
                add.w   (a3)+,d1
                moveq   #-1,d2                  ; indestructible
                lea.l   (Def_EngineShot).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)             ; priority 20
                move.l  (a3)+,$32(a0)           ; dx, dy
                jsr     (jt_ObjInsert).w
                dbra    d7,.4AEFC
                movea.l a4,a0
.4AF28:
                rts
.4AF2A:
                st.b    (EngineDead).l          ; exploding: the flame stops
                clr.w   (FlameTimer).l
                subq.b  #$1,$3D(a0)             ; 25 explosions, one a frame
                bmi.b   .4AF88
                move.w  #$FFFF,$24(a0)          ; indestructible meanwhile
                movea.l a0,a3
                moveq   #30,d0                  ; y = engine y - 10 + random(30)
                jsr     (jt_Random).w
                sub.w   #$A,d0
                add.w   $C(a0),d0
                move.w  d0,d1
                moveq   #96,d0                  ; x = engine x - 15 + random(96)
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                sub.w   #$F,d0
                moveq   #-1,d2
                lea.l   (Def_MainEngine).l,a2   ; as a plain explosion
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)                  ; exploding at once
                move.b  #$1,$5(a0)
                move.b  #$A,$4(a0)              ; priority 10
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                bra.w   .4AF9C
.4AF88:
                move.b  #$1,$5(a0)              ; then it explodes itself
                clr.l   $6(a0)
                move.l  #$800,d0                ; 800 points
                jmp     (jt_AddScore).w
.4AF9C:
                move.l  a0,-(a7)
                movea.l (FlameState).l,a1       ; flame state routine
                jsr     (a1)
                tst.b   (EngineDead).l          ; engine gone or breaking away:
                beq.b   .4AFCC
                move.l  #FlameRts,(FlameState).l ; no more flame
                lea.l   (EngineGoneCells1).l,a0 ; and the map shows it gone
                bsr.w   PatchMap
                lea.l   (EngineGoneCells2).l,a0
                bsr.w   PatchMap
.4AFCC:
                movea.l (a7)+,a0
                rts
Flame_Wait:
                subq.w  #$1,(FlameTimer).l
                bpl.b   FlameRts
                move.l  #Flame_Start,(FlameState).l
                move.l  #FlameStartCells,(FlamePtr).l
FlameRts:
                rts
Flame_Start:
                movea.l (FlamePtr).l,a4         ; flame start blocks, in pairs
                move.l  (a4)+,d0                ; first of the pair (0 = none)
                beq.b   .4AFFE
                movea.l d0,a0
                bsr.w   PatchMap
.4AFFE:
                move.l  (a4)+,d0                ; second (-1 = the end of the list)
                bmi.b   .4B010
                movea.l d0,a0
                bsr.w   PatchMap
                move.l  a4,(FlamePtr).l         ; one pair a frame
                rts
.4B010:
                move.w  #$4B,(FlameTimer).l     ; then 76 frames of flame
                move.l  #.4B022,(FlameState).l
.4B022:
                subq.w  #$1,(FlameTimer).l
                bpl.b   .4B046
                move.w  #$4B,(FlameTimer).l     ; then 76 frames off
                move.l  #Flame_Wait,(FlameState).l
                lea.l   (EngineGoneCells2).l,a0 ; (the cells without flame)
                bra.w   PatchMap
.4B046:
                lea.l   (FlameCellsA).l,a0      ; flicker between two flame frames
                eori.b  #$FF,(FlameToggle).l
                beq.b   .4B05C
                lea.l   (FlameCellsB).l,a0
.4B05C:
                bra.w   PatchMap
Upd_EngineShot:
                movem.w $32(a0),d0-d1           ; dx, dy
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                cmpi.w  #$10,$A(a0)             ; off the screen:
                bcs.b   .4B086
                cmpi.w  #$10,$C(a0)
                bcs.b   .4B086
                cmpi.w  #$E0,$C(a0)
                bcs.b   .4B08A
.4B086:
                jmp     (jt_ObjKillSelf).w      ; remove
.4B08A:
                rts
Spawn_LaserTower:
                movem.w $2(a1),d0-d1
                move.w  #$7D0,d2                ; 2000 hit points: the damage check decides
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)             ; priority 20
                move.b  #$19,$3D(a0)            ; 25 explosions when it goes
                move.w  (ScrollX).w,$38(a0)     ; scroll position now (FollowScroll)
                move.w  (ScrollY).w,$3A(a0)
                move.w  #$226,$34(a0)           ; starts sinking after 550 frames
                move.b  #$19,$32(a0)            ; first laser after 25 frames
                st.b    $33(a0)                 ; upper laser next
                jmp     (jt_ObjInsert).w
Upd_LaserTower:
                bsr.w   FollowScroll            ; move with the hull
                cmpi.w  #$37,$26(a0)            ; 55 damage:
                bcc.b   .4B0F4                  ; explode
                bsr.w   .4B15A                  ; fire
                subq.w  #$1,$34(a0)             ; time to sink?
                bpl.b   .4B0F2
                addq.w  #$1,$C(a0)              ; 1 pixel a frame
                tst.w   $A(a0)                  ; off the left
                bmi.b   .4B0EE
                cmpi.w  #$CF,$C(a0)             ; or the bottom:
                bcs.b   .4B0F2
.4B0EE:
                jmp     (jt_ObjKillSelf).w      ; remove
.4B0F2:
                rts
.4B0F4:
                subq.b  #$1,$3D(a0)             ; 25 explosions, one a frame
                bmi.b   .4B146
                move.w  #$FFFF,$24(a0)          ; indestructible meanwhile
                movea.l a0,a3
                moveq   #30,d0                  ; y = tower y - 10 + random(30)
                jsr     (jt_Random).w
                sub.w   #$A,d0
                add.w   $C(a0),d0
                move.w  d0,d1
                move.w  #$A0,d0                 ; x = tower x - 15 + random(160)
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                sub.w   #$F,d0
                moveq   #-1,d2
                lea.l   (Def_LaserTower).l,a2   ; as a plain explosion
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)                  ; exploding at once
                move.b  #$1,$5(a0)
                move.b  #$1E,$4(a0)             ; priority 30
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                rts
.4B146:
                move.b  #$1,$5(a0)              ; then it explodes itself
                clr.l   $6(a0)
                move.l  #$800,d0                ; 800 points
                jmp     (jt_AddScore).w
.4B15A:
                moveq   #19,d7                  ; upper laser: 19 pixels down
                subq.b  #$1,$32(a0)             ; due?
                bne.b   .4B1A2
                eori.b  #$FF,$33(a0)            ; alternate
                bne.b   .4B172
                move.b  #$1,$32(a0)             ; the lower one follows next frame
                bra.b   .4B17A
.4B172:
                moveq   #27,d7                  ; lower laser: 27 pixels down
                move.b  #$19,$32(a0)            ; then 25 frames to the next pair
.4B17A:
                movea.l a0,a4
                movem.w $A(a4),d0-d1
                add.w   d7,d1
                moveq   #-1,d2                  ; indestructible
                lea.l   (Def_TowerLaser).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)             ; not hit by weapons
                move.b  #$A,$4(a0)              ; priority 10
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
.4B1A2:
                rts
Upd_TowerLaser:
                subq.w  #$7,$A(a0)              ; 7 pixels a frame left
                cmpi.w  #$10,$A(a0)             ; off the left edge: remove
                bhi.b   .4B1B4
                jmp     (jt_ObjKillSelf).w
.4B1B4:
                rts
InitRearTower:
                lea.l   (RearTowerBase).l,a0    ; its base cells
                bsr.w   PatchMap
                clr.w   (BuildTimer).l
                clr.w   (RearAnimTimer).l
                move.b  #$1,(RearTowerState).l  ; state 1: waiting for frame $578
                move.l  #RearTowerBuild,(BuildPtr).l ; build steps: cell block, frames to the next
                move.l  #RearTowerStages,(StagePtr).l ; stages: damage, explosions, width, cells (or an animation)
                clr.b   (RearAnim).l
                move.w  #$FFFE,(RearTowerFrame).l ; no frame yet
                clr.w   (RearTowerDamage).l
                clr.b   (ExplosionsLeft).l
                move.l  #RearTowerXOffsets,(XOffsetPtr).l ; explosion x offset per stage
                rts
UpdateRearTower:
                tst.b   (RearTowerState).l      ; state 0: building / being destroyed
                beq.b   .4B256
                bmi.w   .4B2F2                  ; -1: finished (explosions only)
                cmpi.w  #$578,(FrameCount).l    ; 1: wait for frame $578
                bcs.b   .4B254
                move.l  a0,-(a7)
                move.w  #$139,d0                ; then its target (4 stacked hit boxes)
                move.w  #$8A,d1
                move.w  #$FA0,d2                ; 4000 hit points: the stage damage decides
                lea.l   (Def_RearTower).l,a2
                jsr     (jt_ObjCreate).w
                move.w  (ScrollX).w,$38(a0)     ; scroll position now (FollowScroll)
                move.w  (ScrollY).w,$3A(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                clr.b   (RearTowerState).l      ; state 0
.4B254:
                rts
.4B256:
                cmpi.w  #$50,(RearTowerDamage).l ; 80 damage: start blowing it up
                bcc.b   .4B28E
                subq.w  #$1,(BuildTimer).l      ; otherwise keep building
                bpl.b   .4B254
                movea.l (BuildPtr).l,a4         ; next build step
                movea.l (a4)+,a0
                move.l  (a4)+,d0                ; frames to the next step
                move.w  d0,(BuildTimer).l
                bmi.b   .4B286                  ; -1: built
                bsr.w   PatchMap                ; write the cells into the map
                move.l  a4,(BuildPtr).l
                rts
.4B286:
                st.b    (RearTowerState).l      ; finished: the target goes, explosions run out
                rts
.4B28E:
                move.b  (RearAnim).l,d7         ; a stage animation running?
                bne.w   .4B35C
.4B298:
                movea.l (StagePtr).l,a4         ; next stage
                move.l  (a4)+,d0                ; damage that triggers it
                bmi.b   .4B286                  ; none left: finished
                cmp.w   (RearTowerDamage).l,d0
                bhi.b   .4B2F2                  ; not reached: just the explosions
                move.w  (a4)+,d0                ; explosions for this stage
                move.b  d0,(ExplosionsLeft).l
                move.w  (a4)+,d0                ; spread across this width
                move.w  d0,(ExplosionWidth).l
                addq.l  #$2,(XOffsetPtr).l      ; and the next x offset
                move.l  (a4)+,d6                ; its cells, or a negative animation number
                bpl.b   .4B2CC
                move.b  d6,(RearAnim).l         ; animation 1 or 2
                bra.b   .4B2D8
.4B2CC:
                movea.l d6,a0
                bsr.w   PatchMap                ; write the cells into the map
                clr.b   (RearAnim).l
.4B2D8:
                move.l  a4,(StagePtr).l
                addq.w  #$1,(RearTowerFrame).l  ; next target frame (the hit boxes shrink)
                clr.w   (RearAnimStep).l
                clr.w   (RearAnimTimer).l
                bra.b   .4B28E                  ; the next stage may be due too
.4B2F2:
                tst.b   (ExplosionsLeft).l      ; explosions to go?
                beq.b   .4B35A
                movea.l a0,a3
                subq.b  #$1,(ExplosionsLeft).l
                bne.b   .4B30E                  ; the last one of a stage:
                move.l  #$600,d0                ; 600 points
                jsr     (jt_AddScore).w
.4B30E:
                moveq   #30,d0                  ; y = tower y - 27 + random(30)
                jsr     (jt_Random).w
                add.w   (RearTowerY).l,d0
                move.w  d0,d1
                sub.w   #$1B,d1
                move.w  (ExplosionWidth).l,d0   ; x = tower x + offset + random(width)
                jsr     (jt_Random).w
                add.w   (RearTowerX).l,d0
                movea.l (XOffsetPtr).l,a2
                add.w   (a2),d0
                moveq   #-1,d2
                lea.l   (Def_RearTower).l,a2    ; as a plain explosion
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)              ; exploding at once
                clr.l   $6(a0)
                move.b  #$5,$4(a0)              ; priority 5
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
.4B35A:
                rts
.4B35C:
                lea.l   (RearTowerAnimA).l,a1   ; animation 1: A, 2: B
                neg.b   d7
                subq.b  #$1,d7
                beq.b   .4B36E
                lea.l   (RearTowerAnimB).l,a1
.4B36E:
                subq.w  #$1,(RearAnimTimer).l   ; next animation step due?
                bpl.w   .4B298
                move.w  (RearAnimStep).l,d7     ; step: cells.l, frames.w
                move.w  $4(a1,d7.w),(RearAnimTimer).l
                movea.l (a1,d7.w),a0
                bsr.w   PatchMap                ; write the cells into the map
                cmp.w   #$18,d7                 ; 5 steps, then round again
                bcs.b   .4B39E
                clr.w   (RearAnimStep).l
                bra.w   .4B298
.4B39E:
                addq.w  #$6,(RearAnimStep).l
                bra.w   .4B298
Upd_RearTower:
                bsr.w   FollowScroll            ; move with the hull
                movem.w $A(a0),d0-d1
                movem.w d0-d1,(RearTowerX).l    ; for the explosions
                move.w  $26(a0),(RearTowerDamage).l ; its damage drives the stages
                move.w  (RearTowerFrame).l,d0   ; frame set by the stages
                bmi.b   .4B3DA
                move.w  d0,$1E(a0)
                tst.b   (RearTowerState).l      ; finished:
                bpl.b   .4B3DA
                jmp     (jt_ObjKillSelf).w      ; remove the target
.4B3DA:
                rts
ShipParts:
                dc.w    $00FA,$015C,$0066,$0012,$0005,$0000,$0004,$B474
                dc.w    $0004,$B486,$00FB,$015C,$0076,$0012,$0005,$0001
                dc.w    $0004,$B498,$0004,$B4A4,$0100,$015B,$0095,$0019
                dc.w    $0000,$0002,$0004,$B4B0,$0004,$B4BE,$0AFD,$00C8
                dc.w    $0037,$0003,$0000,$0003,$0004,$B574,$0004,$B582
                dc.w    $0AFE,$00A4,$0032,$0003,$0000,$0004,$0004,$B558
                dc.w    $0004,$B566,$0B83,$0064,$006E,$0002,$0000,$0005
                dc.w    $0004,$B53C,$0004,$B54A,$0BCF,$0035,$007D,$0002
                dc.w    $0000,$0006,$0004,$B520,$0004,$B52E,$FFFF
NextShipPart:
                dc.w    $0000,$0000
CoreX:
                dc.w    $0000
CoreY:
                dc.w    $0000
FrameCount:
                dc.b    $00
FrameCountLo:
                dc.b    $00
                dc.l    LvMap+$608
                dc.b    $02,$01,$00,$64,$00,$65,$00,$66,$00,$78,$00
                dc.b    $79,$00,$7A
                dc.l    LvMap+$608
                dc.b    $02,$01,$00,$01,$00,$02,$00,$03,$00
                dc.b    $00,$00,$00,$00,$00
                dc.l    LvMap+$718
                dc.b    $02,$00,$00,$8C,$00,$8D,$00
                dc.b    $8E
                dc.l    LvMap+$718
                dc.b    $02,$00,$00,$14,$00,$15,$00,$16
                dc.l    LvMap+$7A0
                dc.b    $01,$01,$00,$A0,$00,$A1,$00,$B4,$00,$B5
                dc.l    LvMap+$7A0
                dc.b    $01
                dc.b    $01,$00,$28,$00,$A1,$00,$00,$00,$29
                dc.l    LvMap+$3FC
                dc.b    $01,$01,$00
                dc.b    $1E,$00,$1F,$00,$32,$00,$33
                dc.l    LvMap+$3FC
                dc.b    $01,$01,$00,$00,$00
                dc.b    $00,$00,$04,$00,$05
                dc.l    LvMap+$400
                dc.b    $01,$01,$00,$20,$00,$21,$00
                dc.b    $34,$00,$35
                dc.l    LvMap+$400
                dc.b    $01,$01,$00,$00,$00,$00,$00,$17,$00
                dc.b    $18
                dc.l    LvMap+$48C
                dc.b    $01,$01,$00,$36,$00,$37,$00,$4A,$00,$4B
                dc.l    LvMap+$48C
                dc.b    $01,$01,$00,$00,$00,$00,$80,$2A,$80,$2B
                dc.l    LvMap+$518
                dc.b    $01,$01,$00,$4C,$00,$4D,$00,$60,$00,$61
                dc.l    LvMap+$518
                dc.b    $01
                dc.b    $01,$80,$19,$00,$00,$80,$60,$00,$06
                dc.l    LvMap+$412
                dc.b    $01,$01,$01
                dc.b    $05,$01,$06,$01,$19,$01,$1A
                dc.l    LvMap+$412
                dc.b    $01,$01,$00,$00,$00
                dc.b    $00,$80,$3C,$81,$1A
                dc.l    LvMap+$30A
                dc.b    $01,$01,$00,$E1,$00,$E2,$00
                dc.b    $F5,$00,$F6
                dc.l    LvMap+$30A
                dc.b    $01,$01,$00,$00,$00,$00,$80,$C8,$80
                dc.b    $C9
                dc.l    LvMap+$30E
                dc.b    $01,$01,$00,$00,$00,$E4,$00,$F7,$00,$F8
                dc.l    LvMap+$30E
                dc.b    $01,$01,$00,$00,$00,$00,$00,$00,$00,$00
InitialBlocks:
                dc.w    $0004,$B4CC,$0004,$B4E8,$0004,$B504,$0004,$B520
                dc.w    $0004,$B53C,$0004,$B558,$0004,$B574,$0004,$BC4A
                dc.w    $0004,$BBCC,$0004,$B696
Def_ShipPart:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B5EA
                dc.w    $0000,$0000,$0004,$B5E0,$0004,$B5E2
                dc.l    Upd_ShipPart
                dc.w    $0000,$0000,$0000,$0400,$00FF,$0000,$0000,$0017
                dc.w    $000D,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000
PartGunOffsets:
                dc.w    $0000,$0002,$0000,$FFFF,$0000,$0006,$0008,$FFF9
                dc.w    $0008,$FFF7,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000
EngineRoomState:
                dc.w    $0000,$0000
CoreFramePtr:
                dc.w    $0000,$0000
CoreTimer:
                dc.w    $0000
CoreSteps:
                dc.w    $0000
ShipTimer:
                dc.w    $0000
BossDead:
                dc.b    $00
OrbTimer:
                dc.b    $00
CoreIdleFrames:
                dc.w    $0004,$B7A4,$0004,$B7B2,$0004,$B7C0,$0004,$B7CE
CoreOpenFrames:
                dc.w    $0004,$B6B4,$0004,$B6D2,$0004,$B6F0,$0004,$B70E
                dc.w    $0004,$B72C,$0004,$B744,$0004,$B75C,$0004,$B774
                dc.w    $0004,$B77E,$0004,$B788,$0004,$B796,$0004,$B788
                dc.w    $0004,$B77E,$0004,$B774,$0004,$B75C,$0004,$B744
                dc.w    $0004,$B72C,$0004,$B70E,$0004,$B6F0,$0004,$B6D2
                dc.w    $0004,$B6B4,$0004,$B7A4
                dc.l    LvMap+$5A4
                dc.w    $0302,$8062
                dc.w    $0063,$8140,$8141,$8076,$8077,$8154,$8155,$808A
                dc.w    $808B,$8168,$8169
                dc.l    LvMap+$5A4
                dc.w    $0302,$000A,$800B
                dc.w    $800C,$800D,$800E,$800F,$8010,$8011,$8022,$8023
                dc.w    $8024,$8169
                dc.l    LvMap+$5A4
                dc.w    $0302,$0012,$8013,$8025
                dc.w    $8026,$0038,$8039,$803A,$803B,$81D4,$8027,$804E
                dc.w    $8169
                dc.l    LvMap+$5A4
                dc.w    $0302,$0000,$00D2,$80AC,$80AD
                dc.w    $00E5,$80E6,$80C0,$80C1,$81D4,$80D3,$80D4,$80D5
                dc.l    LvMap+$5A4
                dc.w    $0302,$0000,$00E7,$80E8,$80E9,$0000
                dc.w    $80FB,$80FC,$80FD,$81D4,$810F,$8110,$8111
                dc.l    LvMap+$5A6
                dc.w    $0202,$0160,$8124,$8125,$0174,$8161,$8139
                dc.w    $81D5,$8175,$814D
                dc.l    LvMap+$5A6
                dc.w    $0202,$0187,$8188
                dc.w    $8189,$019B,$819C,$819D,$81D5,$81B0,$81B1
                dc.l    LvMap+$5A6
                dc.w    $0202,$0000,$81AE,$81AF,$0000,$81C2,$81C3
                dc.w    $81D5,$81D6,$81D7
                dc.l    LvMap+$5A8
                dc.w    $0001,$81C4,$81D8
                dc.l    LvMap+$5A8
                dc.w    $0001,$81C5,$81D9
                dc.l    LvMap+$5A8
                dc.w    $0101
                dc.w    $01BE,$01BF,$01D2,$01D3
                dc.l    LvMap+$5A8
                dc.w    $0101,$00FA
                dc.w    $019A,$01C0,$01C1
                dc.l    LvMap+$5A8
                dc.w    $0101,$8140,$8141
                dc.w    $8154,$8155
                dc.l    LvMap+$5A8
                dc.w    $0101,$80DC,$80DD,$80F0
                dc.w    $80F1
                dc.l    LvMap+$5A8
                dc.w    $0101,$80DE,$80DF,$80F2,$80F3
                dc.l    LvMap+$5A8
                dc.w    $0101,$80CC,$80E3,$80E0,$8104
Def_BattleshipCore:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B5EA
                dc.w    $0000,$0000,$0004,$B5E0,$0004,$B804
                dc.l    Upd_BattleshipCore
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$001E,$0012
; CoreOrb: blue orbs sent out of the core chamber, bouncing on a wave
; table ($6FCA6) to the left or right; they burst on the map.
; (16x10, 4 frames, gfx $6F850, update Upd_CoreOrb, spawn Spawn_CoreOrb)
Def_CoreOrb:
                dc.w    $0A02,$0030,$00A0,$0003,$0000,$0000
                dc.l    Gfx_CoreOrb
                dc.w    $0000,$0050,$0004,$B834,$0004,$B83A
                dc.l    Upd_CoreOrb
                dc.l    Spawn_CoreOrb
                dc.w    $0000,$0000,$0001,$0203,$FF00,$0001,$0001,$0008
                dc.w    $0008,$0001,$0001,$0008,$0008,$0001,$0001,$0008
                dc.w    $0008,$0001,$0001,$0008,$0008
; GunTower: the standard gun tower on the hull (entry $08 = hit points,
; $06 non-zero = upside down).  Moves with the map, turns towards the
; ship and fires every 30-80 frames from the muzzle of its current frame.
; (32x23, 8 frames, gfx $66FD0, score 200, update Upd_GunTower, spawn Spawn_GunTower)
Def_GunTower:
                dc.w    $1703,$002E,$02E0
                dc.w    $0000,$0000,$0000
                dc.l    Gfx_GunTower
                dc.w    $0000,$0170,$0004
                dc.w    $B882,$0004,$B8A2
                dc.l    Upd_GunTower
                dc.l    Spawn_GunTower
                dc.w    $0000,$0200,$0303,$0303,$0202,$0101,$0000,$0000
                dc.w    $0000,$0102
GunTowerAnimFlipped:
                dc.w    $0707,$0707,$0707,$0707,$0606,$0605,$0504,$0404
                dc.w    $0015,$000B,$0016,$000B,$000A,$0009,$000E,$000D
                dc.w    $000B,$0002,$000C,$0014,$0009,$0008,$000D,$000E
                dc.w    $0004,$0001,$0013,$000B,$000A,$0001,$000D,$000D
                dc.w    $000B,$0001,$000C,$0014,$0008,$0001,$000E,$000D
GunTowerMuzzles:
                dc.w    $FFFA,$0007,$0000,$0000,$000A,$FFF9,$0010,$FFFE
                dc.w    $FFF7,$0003,$0003,$000B,$000A,$000F,$0010,$000B
; CannonPod: a cannon that hides in the hull and comes out (blinking for
; 40 frames) to fire Fireballs along one of 8 directions every 150-249
; frames, turning towards the ship and sliding on its mount
; (CannonPodSteps); entry $09 = hits, $0A = animation.  Those hits only
; knock it out: an explosion, and it hides for 220 frames, then comes
; out again - it is never destroyed and gives no score (its hit points,
; 4000, are not reached).
; (32x28, 6 frames, gfx $686D0, score 200, update Upd_CannonPod, spawn Spawn_CannonPod)
Def_CannonPod:
                dc.w    $1C03,$002E,$0380,$0000,$0000,$0000
                dc.l    Gfx_CannonPod
                dc.w    $0000,$01C0,$0004,$B962,$0004,$B92A
                dc.l    Upd_CannonPod
                dc.l    Spawn_CannonPod
                dc.w    $0000,$0200,$0007,$0001,$0012,$0013,$0009,$0001
                dc.w    $000E,$0019,$0007,$0001,$0014,$0014,$0002,$0007
                dc.w    $0018,$000E,$0007,$0006,$0013,$0015,$0009,$0002
                dc.w    $000E,$0019,$0006,$0007,$0013,$0013
CannonPodData1:
                dc.w    $0303,$0303
                dc.w    $0302,$0201,$0100,$0000,$0003,$0303
CannonPodData2:
                dc.w    $0404,$0404
                dc.w    $0303,$0202,$0101,$0101,$0104,$0404
CannonPodData4:
                dc.w    $0404,$0403
                dc.w    $0302,$0201,$0101,$0101,$0104,$0404
CannonPodData5:
                dc.w    $0505,$0404
                dc.w    $0303,$0202,$0101,$0101,$0105,$0505
CannonPodData3:
                dc.w    $0505,$0404
                dc.w    $0303,$0202,$0202,$0202,$0606,$0605
CannonPodSteps:
                dc.w    $0000,$0000,$0004,$FFFF,$0007,$0001,$000D,$FFF9
                dc.w    $0008,$FFF2,$0004,$FFF2,$0000,$FFF3
; Fireball: the CannonPod's shot - a short launch path (FireballLaunches),
; then straight on (FireballSteps).
; (32x26, 5 frames, gfx $6C110, update Upd_Fireball)
Def_Fireball:
                dc.w    $1A03,$002E,$0340,$0000,$0000,$0000
                dc.l    Gfx_Fireball
                dc.w    $0000,$01A0,$0004,$BA7E,$0004,$B9F6
                dc.l    Upd_Fireball
                dc.w    $0000,$0000,$0000,$0000,$0000,$0009,$0007,$0008
                dc.w    $0000,$0006,$000F,$000E,$0000,$0004,$0012,$0012
                dc.w    $0005,$000B,$000F,$000D,$0003,$0008,$0012,$0011
                dc.w    $000D,$0004,$0006,$0016,$000B,$0006,$000A,$0014
                dc.w    $000D,$000A,$000E,$000E,$000A,$0006,$0012,$0013
                dc.w    $0006,$0009,$0016,$0008,$0006,$0008,$0016,$000A
                dc.w    $000C,$0002,$000F,$000E,$000B,$0002,$0011,$0010
                dc.w    $000D,$0000,$0006,$0016,$000B,$0000,$000A,$0014
                dc.w    $0004,$0002,$000F,$000D,$0003,$0001,$0011,$0010
                dc.w    $0304,$FF00,$0102,$FF05,$06FF,$0001,$02FF,$0708
                dc.w    $FF00,$0102,$FF09,$0AFF,$0001,$02FF,$0B0C,$FF00
                dc.w    $0102,$FF0D,$0EFF,$0001,$02FF,$0F10,$FF00,$0102
                dc.w    $FF00
FireballLaunches:
                dc.w    $0004,$BAE8,$0004,$BA7E,$0004,$BAF8,$0004,$BA85
                dc.w    $0004,$BB08,$0004,$BA8C,$0004,$BB18,$0004,$BA93
                dc.w    $0004,$BB28,$0004,$BA9A,$0004,$BB38,$0004,$BAA1
                dc.w    $0004,$BB48,$0004,$BAA8,$0000,$000B,$FFF9,$000D
                dc.w    $FFF5,$000F,$FFEB,$0011,$000C,$0012,$0008,$0015
                dc.w    $0006,$0018,$0000,$000F,$0019,$000B,$0017,$000D
                dc.w    $0016,$0010,$0017,$0013,$001B,$0001,$001B,$0001
                dc.w    $001B,$0001,$001B,$0001,$001A,$FFF7,$0018,$FFF4
                dc.w    $0017,$FFF2,$0018,$FFEF,$000D,$FFF0,$0009,$FFED
                dc.w    $0006,$FFEA,$0000,$FFE9,$FFFF,$FFF6,$FFF9,$FFF4
                dc.w    $FFF6,$FFF1,$FFEB,$FFF1
FireballSteps:
                dc.w    $FFFE,$0002,$0000,$0002,$0002,$0002,$0002,$0000
                dc.w    $0002,$FFFE,$0000,$FFFE,$FFFE,$FFFE
; MainEngine: the big thruster (96x32), fires three EngineShots every 36
; frames (EngineShotDirs).  Its exhaust flame is animated in the map
; (FlameState: 100 frames off, the flame building up, 76 frames
; flickering, 76 off).  After more than 20 damage, or after 1000 frames,
; it breaks away on a 234-step path ($6FAD0) and then explodes; at 30 it
; explodes at once (25 explosions) for 800 points, and the map shows it
; gone.
; (96x32, 1 frame, gfx $69F50, score 1000, update Upd_MainEngine, spawn Spawn_MainEngine)
Def_MainEngine:
                dc.w    $2007,$0026,$0C00,$0000,$0000,$0000
                dc.l    Gfx_MainEngine
                dc.w    $0000,$0600,$0004,$BB9C,$0004,$BB9E
                dc.l    Upd_MainEngine
                dc.l    Spawn_MainEngine
                dc.w    $0000,$1000,$00FF,$0000,$0000,$0059,$0020
                dc.l    LvMap+$5FC
                dc.w    $0303,$01A6,$8193,$8194,$8195,$81BA,$81A7
                dc.w    $81A8,$81A9,$81CE,$81BB,$81BC,$81BD,$01B9,$81CF
                dc.w    $81D0,$01D1
EngineGoneCells1:
                dc.l    LvMap+$5FC
                dc.w    $0303,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000
                dc.l    LvMap+$688
                dc.w    $0101,$01F5,$81CD
                dc.w    $0209,$81E1
                dc.l    LvMap+$688
                dc.w    $0101,$826F,$8270,$0271
                dc.w    $8272
FlameCellsA:
                dc.l    LvMap+$680
                dc.w    $0501,$8266,$8267,$8268,$8269,$826A
                dc.w    $826B,$827A,$827B,$827C,$827D,$827E,$827F
FlameCellsB:
                dc.l    LvMap+$680
                dc.w    $0501,$828E,$828F,$8290,$8291,$8292
                dc.w    $8293,$82A2,$82A3,$82A4,$82A5,$82A6,$82A7
EngineGoneCells2:
                dc.l    LvMap+$680
                dc.w    $0501,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000
FlameStartCells:
                dc.w    $0000,$0000,$0004,$BBA6,$0004,$BBCC,$0004,$BBF2
                dc.w    $0000,$0000,$0004,$BC00,$0000,$0000,$0004,$BBA6
                dc.w    $0004,$BBCC,$FFFF,$FFFF
FlameTimer:
                dc.w    $0000
FlameState:
                dc.w    $0000,$0000
FlamePtr:
                dc.w    $0000,$0000
FlameToggle:
                dc.b    $00
EngineDead:
                dc.b    $00
EngineShotDirs:
                dc.w    $0003,$FFF8,$FFF9,$0009,$FFF4,$0000,$000F,$FFF8
                dc.w    $0007
; object definition: 16x14, 2 frames, gfx $6AB50, update Upd_EngineShot
Def_EngineShot:
                dc.w    $0E02,$0030,$00E0,$0000,$0000,$0000
                dc.l    Gfx_EngineShot
                dc.w    $0000,$0070,$0004,$BCD6,$0004,$BCDA
                dc.l    Upd_EngineShot
                dc.w    $0000,$0000,$0000,$0000,$0001,$FF00,$0002,$0001
                dc.w    $000D,$000C,$0002,$0001,$000D,$000C
; object definition: 32x3, 4 frames, gfx $66E50, update Upd_TowerLaser
Def_TowerLaser:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000
                dc.l    Gfx_TowerLaser
                dc.w    $0000,$0030,$0004,$BD32,$0004,$BD12
                dc.l    Upd_TowerLaser
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0001,$0203,$FF00
; LaserTower: the laser tower block - fires TowerLasers (32x3, 7 pixels a
; frame) in pairs, one at each height a frame apart, every 26 frames.
; Moves with the map, and after 550 frames sinks a pixel a frame; 55
; damage destroys it (25 explosions, 800 points).
Def_LaserTower:
                dc.w    $200B,$001E,$1400,$0000,$0000,$0000,$0006,$AD10
                dc.w    $0000,$0A00,$0004,$BD60,$0004,$BD62
                dc.l    Upd_LaserTower
                dc.l    Spawn_LaserTower
                dc.w    $0000,$0800,$00FF,$0000,$0000,$0094,$0020
RearTowerStages:
                dc.w    $0000,$0000,$0000,$0000,$0004,$C012,$0000,$0000
                dc.w    $0006,$0019,$FFFF,$FFFF,$0000,$00C4,$000C,$0034
                dc.w    $0004,$C26E,$0000,$00DC,$0007,$0019,$0004,$C294
                dc.w    $0000,$0118,$0009,$0019,$0004,$C2A2,$0000,$0154
                dc.w    $000A,$0034,$FFFF,$FFFE,$0000,$01B8,$000E,$0019
                dc.w    $0004,$C30A
RearTowerXOffsets:
                dc.w    $FFFF,$FFFF,$FFE7,$FFE7,$000E,$0028,$0028,$0040
RearTowerAnimA:
                dc.w    $0004,$C214,$0064,$0004,$C232,$0003,$0004,$C240
                dc.w    $0003,$0004,$C24E,$0003,$0004,$C25C,$0003
RearTowerAnimB:
                dc.w    $0004,$C2B4,$0064,$0004,$C2D2,$0002,$0004,$C2E0
                dc.w    $0002,$0004,$C2EE,$0002,$0004,$C2FC,$0002
RearTowerBuild:
                dc.w    $0004,$C012,$0000,$007D,$0004,$C0BC,$0000,$0002
                dc.w    $0004,$C112,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C112,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C012,$0000,$0019
                dc.w    $0004,$C078,$0000,$0019,$0004,$C09A,$0000,$0032
                dc.w    $0004,$C078,$0000,$0019,$0004,$C012,$0000,$0032
                dc.w    $0004,$C0BC,$0000,$0002,$0004,$C112,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C112,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C1BE,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C1BE,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C1BE,$0000,$0002
                dc.w    $0004,$C012,$0000,$004B,$0004,$C0BC,$0000,$0002
                dc.w    $0004,$C112,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C112,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C012,$0000,$004B
                dc.w    $0004,$C078,$0000,$0096,$0004,$C09A,$0000,$0064
                dc.w    $0004,$C078,$0000,$0032,$0004,$C012,$0000,$0032
                dc.w    $0004,$C0BC,$0000,$0002,$0004,$C112,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C112,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C1BE,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C1BE,$0000,$0002
                dc.w    $0004,$C168,$0000,$0002,$0004,$C1BE,$0000,$0002
                dc.w    $0004,$C012,$0000,$007D,$0004,$C0BC,$0000,$0002
                dc.w    $0004,$C112,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C112,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C168,$0000,$0002
                dc.w    $0004,$C1BE,$0000,$0002,$0004,$C012,$0000,$007D
                dc.w    $0000,$0000,$FFFF,$FFFF
RearTowerBase:
                dc.l    LvMap+$844
                dc.w    $0705,$00C2,$80C3,$80C4,$80C5,$80C6
                dc.w    $80C7,$81A4,$81A5,$00D6,$00D7,$00D8,$00D9,$00DA
                dc.w    $00DB,$01B8,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000
                dc.l    LvMap+$844
                dc.w    $0601,$00EA,$80EB
                dc.w    $80EC,$80ED,$80EE,$80EF,$81CC,$00FE,$00FF,$0100
                dc.w    $0101,$0102,$0103,$01E0
                dc.l    LvMap+$844
                dc.w    $0601,$8112
                dc.w    $8113,$8114,$8115,$8116,$8117,$81F4,$0126,$0127
                dc.w    $0128,$0129,$012A,$012B,$0208
                dc.l    LvMap+$8CC
                dc.w    $0704
                dc.w    $013A,$013B,$013C,$013D,$013E,$013F,$021C,$021D
                dc.w    $814E,$814F,$8150,$8151,$8152,$8153,$8230,$8231
                dc.w    $8162,$8163,$8164,$8165,$8166,$8167,$8244,$8245
                dc.w    $8176,$8177,$8178,$8179,$817A,$817B,$8258,$8259
                dc.w    $818A,$818B,$818C,$818D,$818E,$818F,$826C,$826D
                dc.l    LvMap+$8CC
                dc.w    $0704,$019E,$019F,$01A0,$01A1,$01A2
                dc.w    $01A3,$01E2,$01E3,$81B2,$81B3,$81B4,$81B5,$81B6
                dc.w    $81B7,$81F6,$81F7,$81C6,$81C7,$81C8,$81C9,$81CA
                dc.w    $81CB,$820A,$820B,$81DA,$81DB,$81DC,$81DD,$81DE
                dc.w    $81DF,$821E,$821F,$81EE,$81EF,$81F0,$81F1,$81F2
                dc.w    $81F3,$8232,$8233
                dc.l    LvMap+$8CC
                dc.w    $0704,$0202,$0203
                dc.w    $0204,$0205,$0206,$0207,$01E4,$01E5,$8216,$8217
                dc.w    $8218,$8219,$821A,$821B,$81F8,$81F9,$822A,$822B
                dc.w    $822C,$822D,$822E,$822F,$820C,$820D,$823E,$823F
                dc.w    $8240,$8241,$8242,$8243,$8220,$8221,$8252,$8253
                dc.w    $8254,$8255,$8256,$8257,$8234,$8235
                dc.l    LvMap+$8CC
                dc.w    $0704,$01E8,$01E9,$01EA,$01EB,$01EC,$01ED,$01E6
                dc.w    $01E7,$81FC,$81FD,$81FE,$81FF,$8200,$8201,$81FA
                dc.w    $81FB,$8210,$8211,$8212,$8213,$8214,$8215,$820E
                dc.w    $820F,$8224,$8225,$8226,$8227,$8228,$8229,$8222
                dc.w    $8223,$8238,$8239,$823A,$823B,$823C,$823D,$8236
                dc.w    $8237
                dc.l    LvMap+$844
                dc.w    $0203,$0246,$8247,$80C4,$025A
                dc.w    $025B,$026E,$0000,$0000,$0000,$0000,$0000,$0000
                dc.l    LvMap+$8CC
                dc.w    $0101,$0248,$0249,$025C,$825D
                dc.l    LvMap+$8CC
                dc.w    $0101,$024A,$024B,$025E,$825F
                dc.l    LvMap+$8CC
                dc.w    $0101,$024C,$024D,$8260,$8261
                dc.l    LvMap+$8CC
                dc.w    $0102
                dc.w    $024E,$024F,$8262,$8263,$0276,$0277
                dc.l    LvMap+$844
                dc.w    $0303,$0246,$8273,$8250,$8251,$0000,$0000,$0264
                dc.w    $0265,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000
                dc.l    LvMap+$848
                dc.w    $0101,$8278,$8279,$0000,$0000
                dc.l    LvMap+$84A
                dc.w    $0201,$8279,$8280,$8281,$0275,$0294
                dc.w    $0295
                dc.l    LvMap+$84A
                dc.w    $0302,$8279,$8282,$828C,$828D
                dc.w    $0000,$0000,$02A0,$02A1,$0000,$0000,$0000,$0000
                dc.l    LvMap+$8D6
                dc.w    $0101,$0289,$028A,$029D,$829E
                dc.l    LvMap+$8D6
                dc.w    $0101,$0287,$0288,$029B,$829C
                dc.l    LvMap+$8D6
                dc.w    $0101,$0285,$0286,$0299,$829A
                dc.l    LvMap+$8D6
                dc.w    $0101
                dc.w    $0297,$0284,$0296,$8298
                dc.l    LvMap+$84E
                dc.w    $0102,$828B
                dc.w    $829F,$0000,$0000,$0000,$0000
RearTowerX:
                dc.w    $0000
RearTowerY:
                dc.w    $0000
BuildTimer:
                dc.w    $0000
RearAnimTimer:
                dc.w    $0000
ExplosionWidth:
                dc.w    $0000
BuildPtr:
                dc.w    $0000,$0000
StagePtr:
                dc.w    $0000,$0000
XOffsetPtr:
                dc.w    $0000,$0000
RearTowerDamage:
                dc.w    $0000
RearAnimStep:
                dc.w    $0000
RearTowerFrame:
                dc.w    $0000
RearTowerState:
                dc.b    $00
RearAnim:
                dc.b    $00
ExplosionsLeft:
                dc.w    $0000
; RearTower: a tall structure at the rear (4 hit boxes stacked) built up in
; the map from frame $578 (RearTowerBuild); its damage drives RearTowerStages:
; each stage blows up a section (explosions across ExplosionWidth, 600
; points) and patches the map.  Stages fall due at 0, 196, 220, 280, 340
; and 440 damage, but only once it has taken 80 (that also stops the
; build); if the build finishes first, the target is removed and the
; tower can no longer be hit.  (Possibly the FAQ's "multiple gun tower"
; or "spare engines" - not confirmed.)
Def_RearTower:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$C38A
                dc.w    $0000,$0000,$0004,$C364,$0004,$C36A
                dc.l    Upd_RearTower
                dc.w    $0000,$0000,$0000,$0000,$0001,$0202,$03FF,$0001
                dc.w    $0001,$005D,$000F,$001B,$0001,$0041,$000F,$0035
                dc.w    $0001,$0027,$000F,$004F,$0001,$0010,$000F,$0000
                dc.w    $0000,$0000,$0000,$0000
LevelAEnd:                               ; (the end of TEXT and DATA)
                ifnd    LEVEL_AB                ; on its own: the padding to the end
                                                ;  of its tracks, byte for byte
                dc.w    $0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000
                endc
