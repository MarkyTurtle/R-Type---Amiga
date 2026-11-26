;==============================================================================
; R-Type (Amiga) - level 8 code and data (level part A)
; Tracks 149.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level8_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level8_a.bin src/levels/level8.s
;
; TEXT $4A300-$4A9B1: level table, wave list, palette, scroll script, code
; DATA $4A9B2-$4B067: object definitions, animations, tables
; $4B068 on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; Stage 8, the Bydo Empire's star.  Enemies: Mikun, Win, the POW Armor;
; the boss is the Bydo itself.  Then the ending (EndingSequence).
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$06B2,$0000,$06B6,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0004,$A300,$0001
; Level interface table, read by the engine (equates LV_* in game.s):
;   $4A300 magic $03011969  | $4A304 checkpoint list | $4A308 palette (15)
;   $4A30C map (level B)    | $4A310 tiles (level B) | $4A314 scroll script
;   $4A318 tile animations  | $4A31C map patches     | $4A320 every frame
;   $4A324 level start      | $4A328 music player    | ($4A32C level 8:
;   ending music; other levels: the scroll script usually starts here)
; Formats: docs/DATA_FORMATS.md
LevelInterface:
                dc.w    $0301,$1969
                dc.l    WaveList
                dc.l    LevelPalette
                dc.l    $5AF00
                dc.l    $4D300
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $5C1FE               ; LvMusic: player in level B; samples $5DE82 (8), data $5DF18, periods $5DEC2
                dc.l    $5F244               ; LvEndMusic: ending tune player, 32-row ($82) patterns; samples $60376, data $6040C
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
Waves:
                dc.w    $00AA,$0170,$0041
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $00CC,$0170,$0069
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $01C3,$0168,$0032
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $01F4,$00FA,$00E0
                dc.l    $00000000,$00000000,Def_Win
                dc.w    $0436,$0168,$008C
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $046A,$0168,$0041
                dc.l    $0001FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $7530   ; end: never reached
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00A0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0C70,$0FF0,$0FFF
; Level 8, the Bydo Empire's star.  LevelInit: the boss state machine
; (BossState) starts at BossArea, Mikuns every 100 frames, the wall and
; core animations (lists of PatchMap blocks; bit 31 = loop/repeat marker,
; bit 30 = spawn a Win at this step - set here on CoreAnimWinStep), and
; the two initial map blocks.
LevelInit:
                move.w  #$6,(WinTurnDelay).l
                move.l  #BossArea,(BossState).l
                move.b  #$64,(MikunTimer).l
                move.l  #WallAnim,(WallAnimPtr).l
                clr.w   (StateTimer).l
                clr.b   (CoreOpening).l
                clr.b   (WinToggle).l
                bset.b  #$6,(CoreAnimWinStep).l
                lea.l   (InitialCellsA).l,a0
                bsr.w   PatchMap
                lea.l   (InitialCellsB).l,a0
                bra.w   PatchMap
LevelFrame:
                movea.l (BossState).l,a1
                jmp     (a1)
FrameRts:
                rts
; BossArea: Mikuns keep coming (SpawnMikun).  From scroll x $5D2 the walls
; animate in the map, every 5 frames; at $64D the Bydo core is created
; (music fades), at $64F the scroll stops.  The core opens and closes
; (CoreOpenAnim); each time it is fully open a Win is released, and the
; Wins home in faster each time (WinTurnDelay counts down from 6).
BossArea:
                bsr.w   SpawnMikun
                move.w  (ScrollX).w,d7
                cmp.w   #$5D2,d7
                bcs.b   FrameRts
                cmp.w   #$64D,d7
                bne.b   .4A462
                move.w  #$12C,d0
                moveq   #100,d1
                move.w  #$7D0,d2
                lea.l   (Def_BydoCore).l,a2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                clr.w   $32(a0)
                jsr     (jt_ObjInsert).w
                st.b    (MusicFadeReq).w
.4A462:
                cmp.w   #$64F,d7
                bne.b   .4A46C
                clr.b   (ScrollActive).w
.4A46C:
                subq.b  #$1,(StateTimer).l
                bpl.b   .4A4CA
                move.b  #$4,(StateTimer).l
                movea.l (WallAnimPtr).l,a4
.4A482:
                move.l  (a4),d0
                bpl.b   .4A4BC
                btst    #$1E,d0
                bne.b   .4A4B6
                move.b  d0,d1
                subq.b  #$1,d1
                bne.b   .4A4B2
                lsr.w   #$8,d0
                move.b  d0,$3(a4)
                addq.l  #$8,a4
                st.b    (CoreOpening).l
                clr.b   (StepTimer).l
                move.l  #CoreOpenAnim,(CoreAnimPtr).l
                bra.b   .4A482
.4A4B2:
                move.b  d1,$3(a4)
.4A4B6:
                movea.l $4(a4),a4
                bra.b   .4A482
.4A4BC:
                movea.l d0,a0
                bsr.w   PatchMap
                addq.l  #$4,a4
                move.l  a4,(WallAnimPtr).l
.4A4CA:
                tst.b   (CoreOpening).l
                beq.b   .4A51E
                subq.b  #$1,(StepTimer).l
                bpl.b   .4A51E
                move.b  #$4,(StepTimer).l
                movea.l (CoreAnimPtr).l,a4
                move.l  (a4)+,d7
                btst    #$1E,d7
                beq.b   .4A50C
                eori.b  #$FF,(WinToggle).l
                bne.b   .4A50C
                bsr.w   SpawnWinAtCore
                tst.w   (WinTurnDelay).l
                beq.b   .4A50C
                subq.w  #$1,(WinTurnDelay).l
.4A50C:
                btst    #$1F,d7
                bne.b   .4A520
                movea.l d7,a0
                bsr.w   PatchMap
                move.l  a4,(CoreAnimPtr).l
.4A51E:
                rts
.4A520:
                clr.b   (CoreOpening).l
                rts
; Upd_BydoCore: the Bydo - flashes when hit; 60 hits end the game: music
; off, the autopilot takes the ship (ShipMode), 15000 points, and
; BossState moves to EndingSequence.
Upd_BydoCore:
                move.w  $26(a0),d0
                cmp.w   $32(a0),d0
                beq.b   .4A57C
                move.w  d0,$32(a0)
                move.b  #$3,$28(a0)
                cmpi.w  #$3C,$32(a0)
                bcs.b   .4A57C
                move.l  #EndingSequence,(BossState).l
                move.b  #$28,(StateTimer).l
                move.w  #$F,$96(a6)
                clr.b   (MusicFadeReq).w
                clr.b   (MusicRequest).w
                bset.b  #$0,(EndSequenceFlags).w
                st.b    (ShipMode).w
                move.l  #$15000,d0
                jsr     (jt_AddScore).w
                jmp     (jt_ObjKillSelf).w
.4A57C:
                rts
PatchMap:
                moveq   #0,d0
                moveq   #0,d1
                movea.l (a0)+,a1
                move.b  (a0)+,d0
                move.b  (a0)+,d1
.4A588:
                move.w  d0,d2
                movea.l a1,a2
.4A58C:
                move.w  (a0)+,(a2)+
                dbra    d2,.4A58C
                adda.l  (MapRowBytes).w,a1
                dbra    d1,.4A588
                rts
; SpawnMikun: every 26 frames a Mikun appears at the top or bottom edge at a
; random x and drifts towards where the ship is (MikunDirections; not
; straight up or down).
SpawnMikun:
                subq.b  #$1,(MikunTimer).l
                bne.b   .4A618
                move.b  #$1A,(MikunTimer).l
                moveq   #10,d0
                jsr     (jt_Random).w
                cmp.w   #$5,d0
                bcc.b   .4A5BC
                moveq   #0,d1
                bra.b   .4A5C0
.4A5BC:
                move.w  #$E0,d1
.4A5C0:
                move.w  #$12C,d0
                jsr     (jt_Random).w
                add.w   #$2D,d0
                movem.w d0-d1,-(a7)
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                cmp.w   #$4,d0
                beq.b   .4A616
                cmp.w   #$C,d0
                beq.b   .4A616
                lea.l   (MikunDirections).l,a3
                lsl.w   #$2,d0
                move.l  (a3,d0.w),d6
                movea.l $40(a3,d0.w),a1
                movem.w (a7)+,d0-d1
                moveq   #-1,d2
                lea.l   (Def_Mikun).l,a2
                jsr     (jt_ObjCreate).w
                move.l  d6,$32(a0)
                move.l  a1,$2A(a0)
                clr.b   $36(a0)
                jmp     (jt_ObjInsert).w
.4A616:
                addq.l  #$4,a7
.4A618:
                rts
; Mikun: a Bydo spirit drifting in a straight line; one hit turns it into
; a burst (sound 10, 200 points).
Upd_Mikun:
                tst.b   $36(a0)
                bne.b   .4A682
                cmpi.w  #$1,$26(a0)
                bcc.b   .4A656
                movem.w $A(a0),d0-d1
                add.w   $32(a0),d0
                add.w   $34(a0),d1
                bmi.b   .4A64A
                cmp.w   #$E0,d1
                bhi.b   .4A64A
                cmp.w   #$10,d0
                bcs.b   .4A64A
                cmp.w   #$168,d0
                bcs.b   .4A64E
.4A64A:
                jmp     (jt_ObjKillSelf).w
.4A64E:
                movem.w d0-d1,$A(a0)
                rts
.4A656:
                st.b    $36(a0)
                move.l  #Def_MikunBurst,$12(a0)
                clr.w   $1E(a0)
                clr.b   $20(a0)
                move.l  #MikunBurstAnim,$2A(a0)
                moveq   #10,d0
                jsr     (jt_PlaySound).w
                move.l  #$200,d0
                jsr     (jt_AddScore).w
.4A682:
                cmpi.w  #$D,$1E(a0)
                bcc.b   .4A64A
                rts
; EndingSequence: 40 frames of explosions round the core (its cells replaced by
; the wreck), then the scroll runs on while the palette fades to black;
; the scroll jumps to $7C1 and the ending music starts (EndSequenceFlags
; bit 1); the palette fades in to EndPalette, the R-9 escort flies in
; (EscortList: y, frame, speed, delay), and finally everything fades out
; and stops (bit 3 - CheckEndOfGame shows the ending text).
EndingSequence:
                subq.b  #$1,(StateTimer).l
                bmi.b   .4A6E2
                cmpi.b  #$14,(StateTimer).l
                bne.b   .4A6A8
                lea.l   (CoreWreckCells).l,a0
                bsr.w   PatchMap
.4A6A8:
                move.w  #$AA,d0
                jsr     (jt_Random).w
                add.w   #$1E,d0
                move.w  d0,d1
                move.w  #$82,d0
                jsr     (jt_Random).w
                add.w   #$C8,d0
                moveq   #-1,d2
                lea.l   (Def_BydoCore).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$2,$21(a0)
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                jmp     (jt_ObjInsert).w
.4A6E2:
                st.b    (ScrollActive).w
                move.b  #$F,(StateTimer).l
                move.l  #.4A6FE,(BossState).l
                clr.b   (StepTimer).l
.4A6FE:
                cmpi.w  #$69F,(ScrollX).w
                bcs.b   .4A740
                subq.b  #$1,(StepTimer).l
                bpl.b   .4A740
                move.b  #$2,(StepTimer).l
                bsr.w   .4A87A
                subq.b  #$1,(StateTimer).l
                bne.b   .4A740
                move.l  #.4A742,(BossState).l
                move.b  #$F,(StateTimer).l
                bset.b  #$1,(EndSequenceFlags).w
                move.w  #$7C1,(ScrollX).w
.4A740:
                rts
.4A742:
                cmpi.w  #$7C6,(ScrollX).w
                bcs.b   .4A740
                subq.b  #$1,(StepTimer).l
                bpl.b   .4A740
                move.b  #$3,(StepTimer).l
                lea.l   (EndPalette).l,a0
                bsr.w   .4A846
                subq.b  #$1,(StateTimer).l
                bne.b   .4A740
                move.l  #.4A790,(BossState).l
                clr.b   (CoreOpening).l
                move.b  #$1,(StateTimer).l
                move.l  #EscortList,(CoreAnimPtr).l
                rts
.4A790:
                tst.b   (CoreOpening).l
                bne.b   .4A7F2
                subq.b  #$1,(StateTimer).l
                bne.b   .4A7DA
                movea.l (CoreAnimPtr).l,a4
.4A7A6:
                move.w  (a4)+,d1
                bmi.b   .4A7DC
                move.w  #$10,d0
                moveq   #-1,d2
                lea.l   (Def_R9Escort).l,a2
                jsr     (jt_ObjCreate).w
                move.w  (a4)+,$1E(a0)
                move.w  (a4)+,$32(a0)
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                move.w  (a4)+,d0
                beq.b   .4A7A6
                move.l  a4,(CoreAnimPtr).l
                move.b  d0,(StateTimer).l
.4A7DA:
                rts
.4A7DC:
                st.b    (CoreOpening).l
                bset.b  #$2,(EndSequenceFlags).w
                move.b  #$90,(StateTimer).l
                rts
.4A7F2:
                subq.b  #$1,(StateTimer).l
                bne.b   .4A7DA
                move.b  #$F,(StateTimer).l
                clr.b   (StepTimer).l
                move.l  #.4A814,(BossState).l
                rts
.4A814:
                subq.b  #$1,(StepTimer).l
                bpl.b   .4A7DA
                move.b  #$2,(StepTimer).l
                bsr.w   .4A87A
                subq.b  #$1,(StateTimer).l
                bne.b   .4A7DA
                clr.b   (ScrollActive).w
                move.l  #.4A7DA,(BossState).l
                bset.b  #$3,(EndSequenceFlags).w
                rts
.4A846:
                moveq   #14,d0
                movea.l (PalettePtr).w,a1
                addq.l  #$2,a1
.4A84E:
                move.w  (a1),d2
                move.w  (a0)+,d3
                moveq   #1,d4
                moveq   #2,d5
.4A856:
                move.w  d2,d6
                move.w  d3,d7
                and.w   #$F,d6
                and.w   #$F,d7
                cmp.b   d7,d6
                bcc.b   .4A868
                add.w   d4,(a1)
.4A868:
                lsl.w   #$4,d4
                lsr.w   #$4,d2
                lsr.w   #$4,d3
                dbra    d5,.4A856
                addq.l  #$4,a1
                dbra    d0,.4A84E
                rts
.4A87A:
                movea.l (PalettePtr).w,a0
                addq.l  #$2,a0
                moveq   #14,d5
.4A882:
                move.w  (a0),d4
                clr.w   d2
                moveq   #1,d7
                moveq   #2,d3
.4A88A:
                move.w  d4,d0
                and.w   #$F,d0
                beq.w   .4A896
                or.w    d7,d2
.4A896:
                lsr.w   #$4,d4
                lsl.w   #$4,d7
                dbra    d3,.4A88A
                sub.w   d2,(a0)
                addq.l  #$4,a0
                dbra    d5,.4A882
                rts
; R9Escort: the ending's R-9 fighters, flying right at their own speed.
Upd_R9Escort:
                move.w  $32(a0),d0
                add.w   d0,$A(a0)
                cmpi.w  #$168,$A(a0)
                bcs.b   .4A8BC
                jmp     (jt_ObjKillSelf).w
.4A8BC:
                rts
; Win: immortal - immune to all weapons (flag bit 2).  It homes in on the
; ship, turning one step every WinTurnDelay frames (WinSteps: 16
; directions).  Wins vanish when the Bydo dies.
Spawn_Win:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$38(a0)
                clr.w   $34(a0)
Win_Insert:
                bset.b  #$2,$23(a0)
                move.b  #$A,$4(a0)
                jmp     (jt_ObjInsert).w
SpawnWinAtCore:
                move.w  #$12C,d0
                move.w  #$78,d1
                moveq   #-1,d2
                lea.l   (Def_Win).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$C,$38(a0)
                move.w  #$14,$34(a0)
                bra.b   Win_Insert
Upd_Win:
                btst.b  #$0,(EndSequenceFlags).w
                beq.b   .4A912
                jmp     (jt_ObjKillSelf).w
.4A912:
                subq.w  #$1,$34(a0)
                bpl.b   .4A940
                move.w  (WinTurnDelay).l,$34(a0)
                subq.w  #$1,$36(a0)
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  $38(a0),d1
                jsr     (jt_TurnTowards).w
                move.w  d1,$38(a0)
.4A940:
                move.w  $38(a0),d0
                lsl.w   #$2,d0
                lea.l   (WinSteps).l,a1
                movem.w $A(a0),d1-d2
                add.w   (a1,d0.w),d1
                add.w   $2(a1,d0.w),d2
                bpl.b   .4A960
                moveq   #0,d2
                bra.b   .4A96A
.4A960:
                cmp.w   #$E0,d2
                bcs.b   .4A96A
                move.w  #$DF,d2
.4A96A:
                movem.w d1-d2,$A(a0)
                rts
WinSteps:
                dc.w    $0000,$FFFA,$0004,$FFFA,$0006,$FFFA,$0006,$FFFC
                dc.w    $0006,$0000,$0006,$0004,$0006,$0006,$0004,$0006
                dc.w    $0000,$0006,$FFFC,$0006,$FFFA,$0006,$FFFA,$0004
                dc.w    $FFFA,$0000,$FFFA,$FFFC,$FFFA,$FFFA,$FFFC,$FFFA
EscortList:
                dc.w    $0028,$0000,$0003,$0032,$00BE,$0001,$0001,$000A
                dc.w    $0046,$0002,$0001,$0000,$0064,$0003,$0002,$0014
                dc.w    $00AF,$0000,$0003,$0004,$0037,$0003,$0003,$0000
                dc.w    $00A0,$0000,$0002,$001E,$0091,$0001,$0004,$0000
                dc.w    $0055,$0001,$0002,$0014,$0028,$0001,$0003,$000A
                dc.w    $0064,$0002,$0002,$000E,$00AF,$0000,$0003,$000A
                dc.w    $0046,$0002,$0001,$0000,$0037,$0000,$0004,$0014
                dc.w    $0091,$0003,$0002,$000A,$0028,$0001,$0003,$0006
                dc.w    $0055,$0000,$0001,$0000,$0082,$0001,$0004,$0000
                dc.w    $00A0,$0003,$0002,$0000,$FFFF
; object definition: 32x14, 4 frames, gfx $672B8, update Upd_R9Escort
Def_R9Escort:
                dc.w    $0E03,$002E,$01C0,$0000,$0000,$0000,$0006,$72B8
                dc.w    $0000,$00E0,$0004,$AA74,$0004,$AAA0
                dc.l    Upd_R9Escort
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203
; object definition: 32x23, 10 frames, gfx $61738, score 200, update Upd_Mikun
Def_Mikun:
                dc.w    $1703,$002E,$02E0,$0002,$0000,$0000,$0006,$1738
                dc.w    $0000,$0170,$0004,$AB60,$0004,$AAA0
                dc.l    Upd_Mikun
                dc.w    $0000,$0000,$0000,$0200,$0004,$0000,$0010,$0015
                dc.w    $0004,$0000,$0010,$0015,$0004,$0000,$0010,$0016
                dc.w    $0004,$0000,$000F,$0016,$0002,$0001,$0016,$0010
                dc.w    $0002,$0001,$0015,$0010,$0008,$0001,$0015,$0010
                dc.w    $0007,$0001,$0015,$0010,$000E,$0000,$000F,$0016
                dc.w    $000D,$0001,$0010,$0014,$000E,$0001,$000E,$0014
                dc.w    $000D,$0001,$000F,$0014,$0007,$0006,$0015,$000F
                dc.w    $0006,$0008,$0018,$000E,$000D,$0001,$0010,$0015
                dc.w    $000E,$0001,$000D,$0015,$0010,$0001,$000C,$0015
                dc.w    $000E,$0002,$000F,$0013,$0004,$0002,$0010,$0014
                dc.w    $0005,$0002,$000C,$0014,$0003,$0001,$000F,$0015
                dc.w    $0003,$0001,$0010,$0015,$0005,$0007,$0015,$000F
                dc.w    $0004,$0007,$0014,$000F,$0809,$FF02,$03FF,$0001
                dc.w    $FF04,$05FF,$1617,$FF14,$15FF,$1213,$FF0E,$0FFF
                dc.w    $1011,$FF0C,$0DFF,$0607,$FF0A,$0BFF
MikunDirections:
                dc.w    $0000,$FFFC,$0002,$FFFC,$0004,$FFFC,$0004,$FFFE
                dc.w    $0000,$0000,$0004,$0002,$0004,$0004,$0002,$0004
                dc.w    $0000,$0004,$FFFE,$0004,$FFFC,$0004,$FFFC,$0002
                dc.w    $0000,$0000,$FFFC,$FFFE,$FFFC,$FFFC,$FFFE,$0004
                dc.w    $0004,$AB60,$0004,$AB63,$0004,$AB66,$0004,$AB69
                dc.w    $0000,$0000,$0004,$AB6C,$0004,$AB6F,$0004,$AB72
                dc.w    $0004,$AB75,$0004,$AB78,$0004,$AB7B,$0004,$AB7B
                dc.w    $0000,$0000,$0004,$AB7E,$0004,$AB60,$0004,$AB81
; object definition: 32x30, 6 frames, gfx $65C38
Def_MikunBurst:
                dc.w    $1E03,$002E,$03C0,$0000,$0000,$0000,$0006,$5C38
                dc.w    $0000,$01E0,$0004,$AC2C,$0004,$AC3C,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
MikunBurstAnim:
                dc.w    $0001,$0001,$0202,$0303,$0404,$0405,$0505,$05FF
                dc.w    $0190,$000F,$0002,$0002,$0190,$000F,$0002,$0002
                dc.w    $0190,$000F,$0002,$0002,$0190,$000F,$0002,$0002
                dc.w    $0190,$000F,$0002,$0002,$0190,$000F,$0002,$0002
MikunTimer:
                dc.b    $00
CoreOpening:
                dc.b    $00
StepTimer:
                dc.b    $00
WinToggle:
                dc.b    $00
WallAnimPtr:
                dc.w    $0000,$0000
CoreAnimPtr:
                dc.w    $0000,$0000
BossState:
                dc.w    $0000,$0000
StateTimer:
                dc.w    $0000
WallAnim:
                dc.w    $0004,$AD5A,$0004,$AD34,$0004,$AD0E,$0004,$AD34
                dc.w    $0004,$AD5A,$0004,$AD80,$8000,$0505,$0004,$AC7E
                dc.w    $0004,$ADA6,$0004,$ADCC,$0004,$ADF2,$0004,$AE18
                dc.w    $0004,$AE18,$0004,$AE18,$0004,$AE18,$0004,$AE18
                dc.w    $0004,$AE18,$0004,$AE18,$0004,$ADF2,$0004,$ADCC
                dc.w    $0004,$ADA6,$0004,$AD80,$C000,$0000,$0004,$AC7E
CoreOpenAnim:
                dc.w    $0004,$AE64,$0004,$AE8A,$0004,$AEB0,$0004,$AED6
CoreAnimWinStep:
                dc.w    $0004,$AED6,$0004,$AED6,$0004,$AED6,$0004,$AEB0
                dc.w    $0004,$AE8A,$0004,$AE64,$0004,$AE3E,$8000,$0000
                dc.w    $0005,$B5B8,$0303,$8058,$8059,$805A,$805B,$806C
                dc.w    $806D,$806E,$806F,$8080,$8081,$8082,$8083,$8094
                dc.w    $8095,$8096,$8097,$0005,$B5B8,$0303,$805C,$805D
                dc.w    $805E,$805F,$8070,$8071,$8072,$8073,$8084,$8085
                dc.w    $8086,$8087,$8098,$8099,$809A,$809B,$0005,$B5B8
                dc.w    $0303,$8060,$8061,$8062,$8063,$8074,$8075,$8076
                dc.w    $8077,$8088,$8089,$808A,$808B,$809C,$809D,$809E
                dc.w    $809F
InitialCellsA:
                dc.w    $0005,$B5B8,$0303,$8035,$8036,$8037,$8038,$8049
                dc.w    $804A,$804B,$804C,$8009,$800A,$800B,$800C,$801D
                dc.w    $801E,$801F,$8020,$0005,$B5B8,$0303,$80A4,$80A5
                dc.w    $80A6,$80A7,$80B8,$80B9,$80BA,$80BB,$80CC,$80CD
                dc.w    $80CE,$80CF,$80E0,$80E1,$80E2,$80E3,$0005,$B5B8
                dc.w    $0303,$80A8,$80A9,$80AA,$80AB,$80BC,$80BD,$80BE
                dc.w    $80BF,$80D0,$80D1,$80D2,$80D3,$80E4,$80E5,$80E6
                dc.w    $80E7,$0005,$B5B8,$0303,$80AC,$80AD,$80AE,$80AF
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $80C0,$80C1,$80C2,$80C3,$0005,$B5B8,$0303,$80B0
                dc.w    $80B1,$80B2,$80B3,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$80C4,$80C5,$80C6,$80C7
InitialCellsB:
                dc.w    $0005,$B5C0,$0303,$00D4,$00D5,$00D6,$00D7,$00E8
                dc.w    $00E9,$00EA,$00EB,$00FC,$00FD,$00FE,$00FF,$0110
                dc.w    $0111,$0112,$0113,$0005,$B5C0,$0303,$00D8,$00D9
                dc.w    $00DA,$00DB,$00EC,$00ED,$00EE,$00EF,$0100,$0101
                dc.w    $0102,$0103,$0114,$0115,$0116,$0117,$0005,$B5C0
                dc.w    $0303,$0124,$0125,$0126,$0127,$0138,$0139,$013A
                dc.w    $013B,$014C,$014D,$014E,$014F,$0160,$0161,$0162
                dc.w    $0163,$0005,$B5C0,$0303,$0128,$0129,$012A,$012B
                dc.w    $013C,$013D,$013E,$013F,$0150,$0151,$0152,$0153
                dc.w    $0164,$0165,$0166,$0167,$0005,$B5C0,$0303,$0174
                dc.w    $0175,$0176,$0177,$0188,$0189,$018A,$018B,$019C
                dc.w    $019D,$019E,$019F,$01B0,$01B1,$01B2,$01B3
CoreWreckCells:
                dc.w    $0005,$AFE0,$070B,$00F0,$00F1,$00F2,$00F3,$00F4
                dc.w    $00F5,$00F6,$00F7,$0104,$0105,$0106,$0107,$0108
                dc.w    $0109,$010A,$010B,$0118,$0119,$011A,$011B,$011C
                dc.w    $011D,$011E,$011F,$012C,$012D,$012E,$012F,$0130
                dc.w    $0131,$0132,$0133,$0140,$0141,$0142,$0143,$0144
                dc.w    $0145,$0146,$0147,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0154,$0155,$0156,$0157,$0158
                dc.w    $0159,$015A,$015B,$0168,$0169,$016A,$016B,$016C
                dc.w    $016D,$016E,$016F,$017C,$017D,$017E,$017F,$0180
                dc.w    $0181,$0182,$0183,$0190,$0191,$0192,$0193,$0194
                dc.w    $0195,$0196,$0197,$01A4,$01A5,$01A6,$01A7,$01A8
                dc.w    $01A9,$01AA,$01AB
EndPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0C70,$0FF0,$0FFF
Def_BydoCore:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B010
                dc.w    $0000,$0000,$0004,$AB66,$0004,$B008
                dc.l    Upd_BydoCore
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0014,$002D
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
; object definition: 32x24, 3 frames, gfx $679B8, update Upd_Win, spawn Spawn_Win
Def_Win:
                dc.w    $1803,$002E,$0300,$0000,$0000,$0000,$0006,$79B8
                dc.w    $0000,$0180,$0004,$B048,$0004,$B04C
                dc.l    Upd_Win
                dc.l    Spawn_Win
                dc.w    $0000,$0000,$0001,$02FF,$0004,$0001,$0012,$0016
                dc.w    $0004,$0003,$0013,$0012,$0002,$0003,$0015,$0011
WinTurnDelay:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
