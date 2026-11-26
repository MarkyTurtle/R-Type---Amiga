;==============================================================================
; R-Type (Amiga) - level 2 code and data (level part A)
; Tracks 84.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level2_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level2_a.bin src/levels/level2.s
;
; TEXT $4A300-$4AF13: level table, wave list, palette, scroll script, code
; DATA $4AF14-$4B68F: object definitions, animations, tables
; $4B690 on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; Stage 2, "Creature Cave".  Enemies: Gouger, Wick, the Worm, two Broods
; and their Zoids, the POW Armor; the boss is Gomander (drawn in the map,
; its core is an object).  All labels named.
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$0C14,$0000,$077C,$0000,$0000,$0000
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
                dc.l    $5D700
                dc.l    $4D300
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $5E948               ; LvMusic: player in level B; samples $608D6 (8), data $6096A, periods $60916
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $0472
                dc.l    WavesFrom_0472
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
Waves:
                dc.w    $0092,$0170,$00C3
                dc.l    $00010000,$00000000,Def_Gouger
                dc.w    $00F8,$0170,$0001
                dc.l    $00020000,$00000000,Def_Gouger
                dc.w    $0111,$0170,$0064
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0141,$0170,$0001
                dc.l    $00030000,$00000000,Def_Gouger
                dc.w    $0187,$0170,$00C3
                dc.l    $00000000,$00000000,Def_Gouger
                dc.w    $01F0,$0170,$0001
                dc.l    $00030000,$00000000,Def_Gouger
                dc.w    $0244,$0170,$00C3
                dc.l    $00010000,$00000000,Def_Gouger
                dc.w    $0248,$0170,$0001
                dc.l    $00020000,$00000000,Def_Gouger
                dc.w    $029E,$0170,$00C3
                dc.l    $00000000,$00000000,Def_Gouger
                dc.w    $0310,$0170,$0001
                dc.l    $00030000,$00000000,Def_Gouger
                dc.w    $033E,$0000,$0000
                dc.l    $000A0000,$00000000,Def_Wick
                dc.w    $0384,$0170,$0001
                dc.l    $00020000,$00000000,Def_Gouger
                dc.w    $0399,$0170,$0050
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $03A2,$0170,$00C3
                dc.l    $00000000,$00000000,Def_Gouger
                dc.w    $0406,$0000,$0000
                dc.l    $00110000,$00000000,Def_Wick
                dc.w    $0426,$0170,$0001
                dc.l    $00020000,$00000000,Def_Gouger
WavesFrom_0472:
                dc.w    $04AE,$0170,$0001
                dc.l    $00030000,$00000000,Def_Gouger
                dc.w    $04B2,$0170,$00C3
                dc.l    $00000000,$00000000,Def_Gouger
                dc.w    $0578,$0170,$00C3
                dc.l    $00010000,$00000000,Def_Gouger
                dc.w    $05F6,$0170,$00C3
                dc.l    $00010000,$00000000,Def_Gouger
                dc.w    $0622,$0170,$005A
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0684,$0170,$0001
                dc.l    $00030000,$00000000,Def_Gouger
                dc.w    $0685,$0170,$00C3
                dc.l    $00010000,$00000000,Def_Gouger
                dc.w    $06B3,$0170,$0001
                dc.l    $00020000,$00000000,Def_Gouger
                dc.w    $07BD,$0000,$0000
                dc.l    $00000000,$00000000,Def_WormHead
                dc.w    $0802,$0170,$005A
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $76A0   ; end: never reached
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
Spawn_Gouger:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                clr.w   $32(a0)
                moveq   #0,d0
                move.w  $6(a1),d0
                move.w  d0,$34(a0)
                move.l  #GougerAnims,d1
                add.l   d0,d1
                add.l   d0,d1
                add.l   d0,d1
                move.l  d1,$2A(a0)
                clr.w   $3A(a0)
                clr.b   $22(a0)
                move.b  #$2,$21(a0)
                jmp     (jt_ObjInsert).w
Upd_Gouger:
                cmpi.w  #$170,$A(a0)
                bhi.b   .4A588
                cmpi.w  #$C4,$C(a0)
                blt.b   .4A58C
.4A588:
                jmp     (jt_ObjKillSelf).w
.4A58C:
                tst.b   $32(a0)
                bmi.b   .4A5EE
                subq.w  #$1,$A(a0)
                move.w  $A(a0),d0
                sub.w   (ShipPos).w,d0
                tst.w   $34(a0)
                beq.b   .4A5AC
                cmpi.w  #$3,$34(a0)
                bne.b   .4A5B8
.4A5AC:
                cmp.w   #$50,d0
                ble.b   .4A5C2
                tst.w   d0
                bmi.b   .4A5C2
                rts
.4A5B8:
                neg.w   d0
                cmp.w   #$50,d0
                bgt.b   .4A5C2
                rts
.4A5C2:
                lea.l   (GougerLeaps).l,a1
                move.w  $34(a0),d2
                lsl.w   #$2,d2
                move.w  (a1,d2.w),d0
                move.w  $2(a1,d2.w),d1
                movem.w d0-d1,$36(a0)
                st.b    $32(a0)
                st.b    $22(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                rts
.4A5EE:
                movem.w $36(a0),d0-d1
                clr.b   $22(a0)
                cmpi.w  #$A0,$C(a0)
                bhi.b   .4A608
                cmpi.w  #$2D,$C(a0)
                bhi.b   .4A61A
.4A608:
                asr.w   #$1,d0
                asr.w   #$1,d1
                st.b    $22(a0)
                cmpi.w  #$2,$34(a0)
                bne.b   .4A61A
                moveq   #0,d0
.4A61A:
                tst.b   $28(a0)
                beq.b   .4A626
                st.b    $22(a0)
                rts
.4A626:
                add.w   d0,$A(a0)
                bmi.w   .4A588
                add.w   d1,$C(a0)
                bmi.w   .4A588
                rts
Spawn_Wick:
                move.w  $6(a1),d7
                moveq   #0,d6
                moveq   #4,d5
.4A640:
                subq.w  #$1,d5
                bpl.b   .4A64C
                move.w  (ShipPos).w,d1
                moveq   #4,d5
                bra.b   .4A658
.4A64C:
                moveq   #105,d0
                jsr     (jt_Random).w
                add.w   #$50,d0
                move.w  d0,d1
.4A658:
                move.w  #$174,d0
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.w  d6,$32(a0)
                move.b  #$1,$21(a0)
                move.b  #$1,$34(a0)
                moveq   #7,d0
                jsr     (jt_Random).w
                move.b  d0,$35(a0)
                clr.w   $38(a0)
                move.w  #$7FFF,$36(a0)
                moveq   #100,d0
                jsr     (jt_Random).w
                cmp.w   #$46,d0
                bcs.b   .4A6A0
                moveq   #33,d0
                jsr     (jt_Random).w
                add.w   #$19,d0
                move.w  d0,$36(a0)
.4A6A0:
                jsr     (jt_ObjInsert).w
                add.w   #$14,d6
                dbra    d7,.4A640
                rts
Upd_Wick:
                tst.w   $32(a0)
                bmi.b   .4A6BA
                subq.w  #$1,$32(a0)
                rts
.4A6BA:
                moveq   #0,d0
                move.b  $38(a0),d0
                bne.b   .4A6E4
                eori.b  #$FF,$39(a0)
                beq.b   .4A6E4
                move.b  $34(a0),d1
                ext.w   d1
                add.w   d1,$C(a0)
                subq.b  #$1,$35(a0)
                bpl.b   .4A6E4
                neg.b   $34(a0)
                move.b  #$6,$35(a0)
.4A6E4:
                lsl.w   #$2,d0
                lea.l   (WickSteps).l,a1
                movem.w (a1,d0.w),d1-d2
                add.w   d1,$A(a0)
                add.w   d2,$C(a0)
                move.w  $A(a0),d0
                cmp.w   #$10,d0
                bcs.b   .4A750
                cmp.w   #$173,d0
                bhi.b   .4A750
                cmpi.w  #$C4,$C(a0)
                bhi.b   .4A750
                subq.w  #$1,$36(a0)
                bpl.b   .4A740
                add.w   #$14,d0
                cmp.w   (ShipPos).w,d0
                bhi.b   .4A742
                move.b  #$2,$38(a0)
                lea.l   (WickAnimClimb).l,a1
.4A72E:
                move.l  a1,$2A(a0)
                move.w  #$7FFF,$36(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
.4A740:
                rts
.4A742:
                move.b  #$1,$38(a0)
                lea.l   (WickAnimDive).l,a1
                bra.b   .4A72E
.4A750:
                jmp     (jt_ObjKillSelf).w
LevelInit:
                clr.w   (BossDead).l
                clr.b   (BossFlash).l
                clr.b   (BossStarted).l
                move.l  #Eye_Wait,(EyeState).l
                lea.l   (BossEyeFrames).l,a0
                move.l  a0,(EyeFramePtr).l
                bsr.w   Eye_Draw
                bra.w   InitBroods
; LevelFrame: at scroll x $A0A the scroll stops, the music fades and
; Gomander's core is created.  Then the eye opens and closes (EyeState:
; Eye_Wait, open in 3 steps of 2x4 map cells from BossEyeFrames, stay
; open, close), the wait shortening by 10 frames each time from 100.
; After the boss dies, random explosions.  Before that it runs the
; Broods (UpdateBroods).
LevelFrame:
                tst.b   (BossStarted).l
                bne.b   .4A7D6
                cmpi.w  #$A0A,(ScrollX).w
                bcs.w   UpdateBroods
                st.b    (BossStarted).l
                clr.b   (ScrollActive).w
                move.w  #$B3,d0
                move.w  #$80,d1
                moveq   #-1,d2
                lea.l   (Def_GomanderCore).l,a2
                jsr     (jt_ObjCreate).w
                clr.w   $32(a0)
                jsr     (jt_ObjInsert).w
                move.w  #$64,(EyeInterval).l
                clr.w   (EyeTimer).l
                clr.w   (EyeFrame).l
                st.b    (MusicFadeReq).w
                rts
.4A7D6:
                tst.b   (BossDead).l
                bne.w   BossExplosions
                movea.l (EyeState).l,a1
                jmp     (a1)
Eye_Wait:
                subq.w  #$1,(EyeTimer).l
                bpl.b   .4A802
                move.l  #.4A804,(EyeState).l
                move.b  #$3,(EyeSteps).l
.4A802:
                rts
.4A804:
                subq.w  #$1,(EyeTimer).l
                bpl.b   .4A85A
                tst.b   (EyeSteps).l
                bne.b   .4A828
                move.l  #.4A85C,(EyeState).l
                move.b  #$3,(EyeSteps).l
                rts
.4A828:
                move.w  #$2,(EyeTimer).l
                addi.l  #$10,(EyeFramePtr).l
                addq.w  #$1,(EyeFrame).l
                movea.l (EyeFramePtr).l,a0
                bsr.w   Eye_Draw
                subq.b  #$1,(EyeSteps).l
                bne.b   .4A85A
                move.w  #$14,(EyeTimer).l
.4A85A:
                rts
.4A85C:
                subq.w  #$1,(EyeTimer).l
                bpl.b   .4A8B4
                move.w  #$2,(EyeTimer).l
                subi.l  #$10,(EyeFramePtr).l
                subq.w  #$1,(EyeFrame).l
                movea.l (EyeFramePtr).l,a0
                bsr.w   Eye_Draw
                subq.b  #$1,(EyeSteps).l
                bne.b   .4A8B4
                move.w  (EyeInterval).l,d0
                cmp.w   #$A,d0
                bls.b   .4A8A4
                sub.w   #$A,d0
                move.w  d0,(EyeInterval).l
.4A8A4:
                move.w  d0,(EyeTimer).l
                move.l  #Eye_Wait,(EyeState).l
.4A8B4:
                rts
Eye_Draw:
                lea.l   ($5E0C0).l,a1
                move.l  (a0)+,(a1)
                move.l  (a0)+,$4(a1)
                adda.l  (MapRowBytes).w,a1
                move.l  (a0)+,(a1)
                move.l  (a0)+,$4(a1)
                rts
BossExplosions:
                move.l  a0,-(a7)
                moveq   #100,d0
                jsr     (jt_Random).w
                move.w  d0,d1
                add.w   #$64,d1
                moveq   #126,d0
                jsr     (jt_Random).w
                add.w   #$78,d0
                moveq   #-1,d2
                lea.l   (Def_GomanderCore).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                moveq   #3,d0
                jsr     (jt_Random).w
                move.b  d0,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
Upd_GomanderCore:
                movea.l (PalettePtr).w,a1
                tst.b   (BossFlash).l
                beq.b   .4A922
                clr.b   (BossFlash).l
                bsr.b   .4A982
.4A922:
                move.w  (EyeFrame).l,$1E(a0)
                clr.b   $20(a0)
                move.w  $26(a0),d0
                cmp.w   $32(a0),d0
                beq.b   .4A980
                move.w  d0,$32(a0)
                move.w  #$64,(EyeInterval).l
                move.w  #$FFF,d1
                move.w  d1,$2(a1)
                move.w  d1,$6(a1)
                move.w  d1,$A(a1)
                move.w  d1,$36(a1)
                st.b    (BossFlash).l
                move.b  #$3,$28(a0)
                cmp.w   #$1E,d0
                bcs.b   .4A980
                bsr.b   .4A982
                st.b    (BossDead).l
                st.b    (LevelComplete).w
                move.l  #$9000,d0
                jmp     (jt_AddScore).w
.4A980:
                rts
.4A982:
                move.w  #$555,$2(a1)
                move.w  #$BBB,$6(a1)
                move.w  #$777,$A(a1)
                move.w  #$FF0,$36(a1)
                rts
Spawn_Worm:
                moveq   #10,d7
                moveq   #0,d6
                moveq   #11,d5
                lea.l   (WormSegments).l,a3
.4A9A8:
                move.w  #$160,d0
                moveq   #60,d1
                moveq   #-1,d2
                movea.l (a3)+,a2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  d7,$4(a0)
                movea.l (a3)+,a2
                move.l  a2,$2A(a0)
                cmpa.l  #WormEyeAnim,a2
                bne.b   .4A9D0
                st.b    $22(a0)
.4A9D0:
                move.w  d6,$34(a0)
                clr.w   $32(a0)
                clr.w   $3A(a0)
                clr.b   $3C(a0)
                move.b  d5,$3D(a0)
                cmp.w   #$A,d7
                bne.b   .4A9F0
                move.b  #$1,$32(a0)
.4A9F0:
                jsr     (jt_ObjInsert).w
                addq.w  #$5,d6
                subq.w  #$1,d5
                dbra    d7,.4A9A8
                move.l  #WormFirstPath,(WormPath).l
                rts
Upd_Worm:
                tst.b   (BossDead).l
                beq.b   .4AA22
                subq.b  #$1,$3D(a0)
                bpl.b   .4AA22
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                rts
.4AA22:
                tst.b   $32(a0)
                bmi.w   .4AB1E
.4AA2A:
                tst.w   $34(a0)
                bmi.b   .4AA36
                subq.w  #$1,$34(a0)
                rts
.4AA36:
                tst.b   $33(a0)
                bne.b   .4AA5A
                movea.l (WormPath).l,a1
                move.w  (a1)+,$A(a0)
                move.w  (a1)+,$C(a0)
                move.l  a1,$36(a0)
                clr.w   $3A(a0)
                clr.w   $26(a0)
                st.b    $33(a0)
.4AA5A:
                movea.l $36(a0),a1
                move.w  $3A(a0),d0
                move.w  (a1)+,d1
                bsr.w   .4AB14
                add.w   d2,$A(a0)
                bsr.w   .4AB14
                add.w   d2,$C(a0)
                tst.b   $22(a0)
                bne.b   .4AA84
                bsr.w   .4AB14
                move.b  d2,$1F(a0)
                bra.b   .4AADC
.4AA84:
                tst.b   $3C(a0)
                bne.b   .4AADC
                tst.w   $26(a0)
                beq.b   .4AADC
                movem.l d0-d1/a0,-(a7)
                move.l  #WormEyeShotAnim,$2A(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (Def_WormEye).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.b  #$1E,$4(a0)
                jsr     (jt_ObjInsert).w
                move.l  #$200,d0
                jsr     (jt_AddScore).w
                movem.l (a7)+,d0-d1/a0
                st.b    $3C(a0)
.4AADC:
                cmp.w   d1,d0
                bcc.b   .4AAE6
                addq.w  #$1,$3A(a0)
                rts
.4AAE6:
                move.w  #$FFFF,$A(a0)
                tst.b   $3C(a0)
                beq.b   .4AAFE
                move.l  #WormEyeAnim,$2A(a0)
                clr.b   $3C(a0)
.4AAFE:
                clr.b   $33(a0)
                move.w  #$55,$34(a0)
                tst.b   $32(a0)
                beq.b   .4AB12
                st.b    $32(a0)
.4AB12:
                rts
.4AB14:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
.4AB1E:
                move.b  #$1,$32(a0)
                movea.l (WormPath).l,a1
                adda.l  #$12,a1
                cmpa.l  #WormPath,a1
                bcs.b   .4AB42
                lea.l   (WormPaths).l,a1
                st.b    (LevelComplete).w
.4AB42:
                move.l  a1,(WormPath).l
                bra.w   .4AA2A
InitBroods:
                lea.l   (Brood1).l,a0
                lea.l   (Brood1Cells).l,a1
                bsr.b   .4AB66
                lea.l   (Brood2).l,a0
                lea.l   (Brood2Cells).l,a1
.4AB66:
                move.l  a1,$1C(a0)
                move.l  #Brood_Wait,(a0)
                move.w  $10(a0),$12(a0)
                clr.b   $4(a0)
Brood_DrawCells:
                moveq   #2,d0
                movea.l $14(a0),a0
.4AB80:
                move.l  (a1)+,(a0)
                move.l  (a1)+,$4(a0)
                adda.l  (MapRowBytes).w,a0
                dbra    d0,.4AB80
                rts
UpdateBroods:
                lea.l   (Brood1).l,a0
                bsr.b   .4AB9E
                lea.l   (Brood2).l,a0
.4AB9E:
                tst.b   $4(a0)
                beq.b   .4ABAC
                movea.l $18(a0),a1
                clr.l   (a0)
                bra.b   Brood_DrawCells
.4ABAC:
                move.l  (a0),d0
                beq.b   BroodRts
                movea.l d0,a1
                jmp     (a1)
Brood_Wait:
                move.w  $8(a0),d0
                cmp.w   (ScrollX).w,d0
                bne.b   BroodRts
                move.w  $E(a0),d1
                move.w  #$16B,d0
                move.w  #$1388,d2
                lea.l   (Def_Brood).l,a2
                movea.l a0,a3
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$2,$21(a0)
                move.l  a3,$32(a0)
                move.w  $10(a3),$1E(a0)
                move.w  #$7D,$3A(a0)
                move.w  #$AF,$3C(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                move.l  #Brood_Open,(a0)
BroodRts:
                rts
Brood_Open:
                move.w  $A(a0),d0
                cmp.w   (ScrollX).w,d0
                bne.b   BroodRts
                clr.b   $6(a0)
                move.b  #$4,$7(a0)
                move.l  #.4AC20,(a0)
                rts
.4AC20:
                subq.b  #$1,$6(a0)
                bpl.b   .4AC50
                move.b  #$5,$6(a0)
                addi.l  #$18,$1C(a0)
                addq.w  #$1,$12(a0)
                movea.l a0,a3
                movea.l $1C(a0),a1
                bsr.w   Brood_DrawCells
                movea.l a3,a0
                subq.b  #$1,$7(a0)
                bne.b   .4AC50
                move.l  #.4AC52,(a0)
.4AC50:
                rts
.4AC52:
                move.w  $C(a0),d0
                cmp.w   (ScrollX).w,d0
                bne.b   .4AC50
                clr.b   $6(a0)
                move.b  #$4,$7(a0)
                move.l  #.4AC6E,(a0)
                rts
.4AC6E:
                subq.b  #$1,$6(a0)
                bpl.b   .4AC9A
                move.b  #$5,$6(a0)
                subi.l  #$18,$1C(a0)
                subq.w  #$1,$12(a0)
                movea.l a0,a3
                movea.l $1C(a0),a1
                bsr.w   Brood_DrawCells
                movea.l a3,a0
                subq.b  #$1,$7(a0)
                bne.b   .4AC9A
                clr.l   (a0)
.4AC9A:
                rts
Upd_Brood:
                tst.w   $3A(a0)
                beq.b   .4ACAE
                subq.w  #$1,$3A(a0)
                bne.b   .4ACAE
                nop
                bsr.w   .4AD0E
.4ACAE:
                tst.w   $3C(a0)
                beq.b   .4ACC0
                subq.w  #$1,$3C(a0)
                bne.b   .4ACC0
                nop
                bsr.w   .4AD0E
.4ACC0:
                move.w  $A(a0),d0
                subq.w  #$1,d0
                cmp.w   #$10,d0
                bhi.b   .4ACD0
                jmp     (jt_ObjKillSelf).w
.4ACD0:
                move.w  d0,$A(a0)
                movea.l $32(a0),a1
                move.w  $12(a1),d0
                move.w  d0,$1E(a0)
                cmpi.w  #$23,$26(a0)
                bcs.b   .4AD0C
                st.b    $4(a1)
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                cmp.w   #$5,d0
                bcs.b   .4AD02
                subi.w  #$2B,$C(a0)
.4AD02:
                move.l  #$700,d0
                jmp     (jt_AddScore).w
.4AD0C:
                rts
.4AD0E:
                movea.l a0,a1
                movem.w $A(a1),d0-d1
                add.w   #$A,d0
                addq.w  #$8,d1
                cmp.w   #$64,d1
                bhi.b   .4AD26
                sub.w   #$18,d1
.4AD26:
                moveq   #5,d2
                lea.l   (Def_Zoid).l,a2
                jsr     (jt_ObjCreate).w
                cmpi.w  #$5A,$C(a0)
                bhi.b   .4AD40
                st.b    $32(a0)
                bra.b   .4AD44
.4AD40:
                clr.b   $32(a0)
.4AD44:
                moveq   #100,d0
                jsr     (jt_Random).w
                moveq   #0,d2
                cmp.w   #$46,d0
                bhi.b   .4AD54
                moveq   #1,d2
.4AD54:
                moveq   #37,d1
                move.b  d2,$33(a0)
                bne.b   .4AD5E
                moveq   #78,d1
.4AD5E:
                clr.w   $34(a0)
                move.w  d1,$38(a0)
                clr.b   $36(a0)
                clr.w   $3C(a0)
                move.w  $26(a0),$3A(a0)
                jsr     (jt_ObjInsert).w
                movea.l a1,a0
                rts
Upd_Zoid:
                tst.b   $36(a0)
                bne.w   .4AE1A
                move.w  $26(a0),d0
                cmp.w   $3A(a0),d0
                bne.b   .4ADE8
                lea.l   ($7252F).l,a1
                lea.l   $26(a1),a2
                tst.b   $33(a0)
                bne.b   .4ADA8
                lea.l   ($72496).l,a1
                lea.l   $4E(a1),a2
.4ADA8:
                move.w  $34(a0),d2
                addq.w  #$1,$34(a0)
                movem.w $A(a0),d0-d1
                move.b  (a1,d2.w),d3
                move.b  (a2,d2.w),d4
                cmp.b   #$7F,d4
                beq.b   .4ADE8
                ext.w   d3
                ext.w   d4
                tst.b   $32(a0)
                bmi.b   .4ADD0
                neg.w   d4
.4ADD0:
                add.w   d3,d0
                add.w   d4,d1
                cmp.w   #$20,d0
                bcs.b   .4ADE8
                cmp.w   #$12E,d0
                bhi.b   .4ADE8
                movem.w d0-d1,$A(a0)
                rts
.4ADE8:
                move.b  #$1,$36(a0)
                move.l  #ZoidAnim,$2A(a0)
                st.b    $22(a0)
                clr.b   $20(a0)
                move.w  #$5,$1E(a0)
                clr.w   $32(a0)
                clr.w   $34(a0)
                move.w  #$F,$38(a0)
                move.w  $26(a0),$3A(a0)
                rts
.4AE1A:
                subq.w  #$1,$38(a0)
                bmi.w   .4AEB0
                tst.b   $3D(a0)
                beq.b   .4AE7E
                move.w  $26(a0),d0
                cmp.w   $3A(a0),d0
                beq.b   .4AE50
                move.w  d0,$3A(a0)
                clr.w   $32(a0)
                move.w  #$8,$34(a0)
                move.w  #$C0,d0
                sub.w   $C(a0),d0
                lsr.w   #$3,d0
                subq.w  #$2,d0
                move.w  d0,$38(a0)
.4AE50:
                movem.w $32(a0),d0-d1
                movem.w $A(a0),d2-d3
                add.w   d0,d2
                add.w   d1,d3
                cmp.w   #$30,d2
                blt.b   .4AE80
                cmp.w   #$12E,d2
                bhi.b   .4AE80
                cmp.w   #$30,d3
                blt.b   .4AE80
                cmp.w   #$C0,d3
                bhi.b   .4AE80
                movem.w d2-d3,$A(a0)
.4AE7E:
                rts
.4AE80:
                lsr.w   $38(a0)
                moveq   #0,d0
                moveq   #0,d1
                move.b  $37(a0),d1
                lea.l   (ZoidTurns).l,a1
                move.b  (a1,d1.w),d0
                move.b  d0,$37(a0)
                lsl.w   #$2,d0
                lea.l   (ZoidSteps).l,a1
                movem.w (a1,d0.w),d2-d3
                movem.w d2-d3,$32(a0)
                bra.b   .4AE50
.4AEB0:
                st.b    $3D(a0)
                subq.b  #$1,$3C(a0)
                bpl.b   .4AED2
                move.b  #$4,$3C(a0)
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                bra.b   .4AED8
.4AED2:
                moveq   #16,d0
                jsr     (jt_Random).w
.4AED8:
                move.b  d0,$37(a0)
                move.w  d0,d1
                moveq   #100,d0
                jsr     (jt_Random).w
                cmp.w   #$5A,d0
                bhi.b   .4AEEE
                add.w   #$10,d1
.4AEEE:
                lsl.w   #$2,d1
                lea.l   (ZoidSteps).l,a1
                movem.w (a1,d1.w),d2-d3
                movem.w d2-d3,$32(a0)
                moveq   #100,d0
                jsr     (jt_Random).w
                add.w   #$14,d0
                move.w  d0,$38(a0)
                bra.w   .4AE50
GougerLeaps:
                dc.w    $FFFC,$FFFC,$0004,$FFFC,$0004,$0004,$FFFC,$0004
; Gouger: a biological weapon clinging to the cave wall (entry $06 picks the
; corner 0-3 and its animation).  It scrolls in, and when the ship is
; within 80 pixels it leaps at it diagonally (GougerLeaps: 4 pixels a
; frame, half speed near the floor and ceiling).  10 hit points.
; (48x59, 2 frames, gfx $61C96, 10 hit points, score 500, update Upd_Gouger, spawn Spawn_Gouger)
Def_Gouger:
                dc.w    $3B04,$002C,$0B10,$0001,$000A,$0000,$0006,$1C96
                dc.w    $0000,$0588,$0004,$AF4C,$0004,$AF58
                dc.l    Upd_Gouger
                dc.l    Spawn_Gouger
                dc.w    $0000,$0500
GougerAnims:
                dc.w    $0001,$FF02,$03FF,$0405,$FF06,$07FF,$0006,$000D
                dc.w    $0023,$0024,$0006,$000D,$0023,$0024,$0006,$000D
                dc.w    $0023,$0024,$0006,$000D,$0023,$0024,$0006,$000D
                dc.w    $0023,$0024,$0006,$000D,$0023,$0024,$0006,$000D
                dc.w    $0023,$0024,$0006,$000D,$0023,$0024
WickSteps:
                dc.w    $FFFB,$0000,$FFFC,$0004,$0004,$0004
; Wick: small creatures in groups (entry $06 = count - 1), 20 frames apart,
; at random heights (every 5th at the ship's).  They fly left bobbing up
; and down, and after a random time dive or climb towards the ship.
; (16x13, 3 frames, gfx $67516, 1 hit point, score 100, update Upd_Wick, spawn Spawn_Wick)
Def_Wick:
                dc.w    $0D02,$0030
                dc.w    $00D0,$0002,$0001,$0000,$0006,$7516,$0000,$0068
                dc.w    $0004,$AFCC,$0004,$AFD8
                dc.l    Upd_Wick
                dc.l    Spawn_Wick
                dc.w    $0000,$0100,$0001,$02FF
WickAnimDive:
                dc.w    $0304,$05FF
WickAnimClimb:
                dc.w    $0607,$08FF,$0000,$0000,$0010,$0009,$0000,$0000
                dc.w    $0010,$0009,$0000,$0000,$0010,$0009,$0000,$0002
                dc.w    $000E,$000B,$0000,$0002,$000E,$000B,$0000,$0002
                dc.w    $000E,$000B,$0004,$0001,$000B,$000C,$0004,$0001
                dc.w    $000B,$000C,$0004,$0001,$000B,$000C
BossStarted:
                dc.b    $00
EyeSteps:
                dc.b    $00
EyeTimer:
                dc.w    $0000
EyeFramePtr:
                dc.w    $0000,$0000
EyeState:
                dc.w    $0000,$0000
EyeInterval:
                dc.w    $0000
EyeFrame:
                dc.w    $0000
BossDead:
                dc.w    $0000
BossFlash:
                dc.w    $0000
BossEyeFrames:
                dc.w    $00B8,$00B9,$00BA,$00BB,$80CC,$80CD,$80CE,$80CF
                dc.w    $00BC,$00BD,$00BE,$00BF,$80D0,$80D1,$80D2,$80D3
                dc.w    $00C0,$00C1,$00C2,$00C3,$80D4,$80D5,$80D6,$80D7
                dc.w    $00C4,$00C5,$00C6,$00C7,$80D8,$80D9,$80DA,$80DB
; Gomander's core (the stage 2 boss; the FAQ calls it Cyst): an invisible
; target at the boss's eye.  Each hit flashes four palette colours
; (PalettePtr) white and resets the eye timer; after 30 hits the boss
; dies: BossDead, LevelComplete, 9000 points.
Def_GomanderCore:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B0C2
                dc.w    $0000,$0000,$0004,$B09C,$0004,$B0A2
                dc.l    Upd_GomanderCore
                dc.w    $0000,$0000,$0000,$2000,$0001,$0203,$04FF,$0008
                dc.w    $0023,$0013,$000C,$000C,$000B,$000F,$0007,$0008
                dc.w    $0008,$0017,$000B,$000C,$0006,$0014,$0011,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000
WormFirstPath:
                dc.w    $0160,$003C,$0236,$0007,$16A6,$0007,$18E8,$0007
                dc.w    $1B2A
WormPaths:
                dc.w    $0064,$00B4,$00F2,$0007,$1D6C,$0007,$1E62,$0007
                dc.w    $1F58,$010E,$00B9,$005E,$0007,$204E,$0007,$20AF
                dc.w    $0007,$2110,$00EC,$007D,$007C,$0007,$2171,$0007
                dc.w    $21EE,$0007,$226B,$0085,$007D,$008B,$0007,$22E8
                dc.w    $0007,$2376,$0007,$2404,$010E,$00B9,$005E,$0007
                dc.w    $204E,$0007,$20AF,$0007,$2110,$0064,$00B4,$00F2
                dc.w    $0007,$1D6C,$0007,$1E62,$0007,$1F58,$0085,$007D
                dc.w    $008B,$0007,$22E8,$0007,$2376,$0007,$2404,$00EC
                dc.w    $007D,$007C,$0007,$2171,$0007,$21EE,$0007,$226B
WormPath:
                dc.w    $0000,$0000
WormSegments:
                dc.w    $0004,$B1CC,$0004,$B1F4,$0004,$B296,$0004,$B1F4
                dc.w    $0004,$B33E,$0004,$B386,$0004,$B33E,$0004,$B386
                dc.w    $0004,$B33E,$0004,$B386,$0004,$B33E,$0004,$B386
                dc.w    $0004,$B33E,$0004,$B386,$0004,$B33E,$0004,$B386
                dc.w    $0004,$B33E,$0004,$B386,$0004,$B296,$0004,$B205
                dc.w    $0004,$B1CC,$0004,$B205
; The Worm: an 11-segment creature - a head at each end (WormHead), body
; segments next to them and 7 armoured eyes (WormEye) in between - that
; follows paths (WormPath: start x, y, steps, then dx/dy/frame tables in
; level B), 5 frames apart.  Each eye can be shot out once (200 points)
; and then shows its "shot" frame.  When the last segment finishes a path
; the next path starts (WormPaths); after the last one the level ends.
; When the boss dies the segments explode one by one.
; (32x29, 16 frames, gfx $699A6, score 1000, update Upd_Worm, spawn Spawn_Worm)
Def_WormHead:
                dc.w    $1D03,$002E,$03A0,$0000
                dc.w    $0000,$0000,$0006,$99A6,$0000,$01D0,$0004,$B1F4
                dc.w    $0004,$B216
                dc.l    Upd_Worm
                dc.l    Spawn_Worm
                dc.w    $0000,$1000,$0001,$0203,$0405,$0607,$0809,$0A0B
                dc.w    $0C0D,$0E0F,$FF08,$090A,$0B0C,$0D0E,$0F00,$0102
                dc.w    $0304,$0506,$07FF,$0006,$0002,$0013,$0017,$0006
                dc.w    $0002,$0014,$0018,$0004,$0003,$0017,$0017,$0005
                dc.w    $0002,$0017,$0018,$0003,$0004,$0019,$0015,$0005
                dc.w    $0004,$0017,$0016,$0005,$0003,$0015,$0016,$0006
                dc.w    $0004,$0015,$0017,$0005,$0003,$0015,$0017,$0005
                dc.w    $0003,$0016,$0017,$0005,$0003,$0016,$0016,$0004
                dc.w    $0004,$0017,$0016,$0004,$0004,$0017,$0015,$0003
                dc.w    $0003,$0017,$0017,$0004,$0003,$0016,$0017,$0004
                dc.w    $0002,$0016,$0018
; object definition: 32x27, 16 frames, gfx $6D3A6, score 1000, update Upd_Worm, spawn Spawn_Worm
Def_WormBody:
                dc.w    $1B03,$002E,$0360,$0000,$0000
                dc.w    $0000,$0006,$D3A6,$0000,$01B0,$0004,$B1F4,$0004
                dc.w    $B2BE
                dc.l    Upd_Worm
                dc.l    Spawn_Worm
                dc.w    $0000,$1000,$0006,$0002,$0013,$0017,$0006,$0001
                dc.w    $0014,$0018,$0006,$0002,$0015,$0016,$0004,$0003
                dc.w    $0018,$0015,$0004,$0004,$0019,$0014,$0005,$0003
                dc.w    $0017,$0015,$0006,$0003,$0014,$0015,$0007,$0002
                dc.w    $0013,$0018,$0007,$0002,$0013,$0018,$0006,$0002
                dc.w    $0014,$0017,$0007,$0003,$0013,$0015,$0005,$0003
                dc.w    $0016,$0014,$0003,$0003,$0018,$0014,$0005,$0004
                dc.w    $0015,$0014,$0005,$0003,$0014,$0014,$0006,$0001
                dc.w    $0014,$0018
; object definition: 32x26, 3 frames, gfx $709A6, score 1000, update Upd_Worm, spawn Spawn_Worm
Def_WormEye:
                dc.w    $1A03,$002E,$0340,$0003,$0000,$0000,$0007,$09A6
                dc.w    $0000,$01A0,$0004,$B386,$0004,$B366
                dc.l    Upd_Worm
                dc.l    Spawn_Worm
                dc.w    $0000,$1000,$0002,$0002,$0017,$0016,$0002,$0002
                dc.w    $0017,$0016,$0002,$0002,$0017,$0016,$0002,$0002
                dc.w    $0017,$0016
WormEyeAnim:
                dc.w    $0001,$02FF
WormEyeShotAnim:
                dc.w    $03FF
Brood1:
                dc.w    $0000,$0000,$0000,$0000,$02C8,$0331,$0398,$00A9
                dc.w    $0000,$0000,$0005,$E428,$0004,$B4C8,$0000,$0000
Brood2:
                dc.w    $0000,$0000,$0000,$0000,$03C8,$0430,$0492,$004D
                dc.w    $0005,$0000,$0005,$D7A0,$0004,$B558,$0000,$0000
; Brood: two of them (Brood1/Brood2: scroll positions, map address, cell
; frames) grow out of the cave wall as the screen scrolls: Brood_Wait
; waits for the scroll position, creates the invisible Brood target,
; Brood_Open then opens it in 4 steps of map cells (and closes it again
; later).  The target releases a Zoid after 125 and after 175 frames;
; 35 hits destroy it (700 points).
Def_Brood:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B570
                dc.w    $0000,$0000,$0004,$B3F4,$0004,$B400
                dc.l    Upd_Brood
                dc.w    $0000,$0000,$0000,$1000,$0001,$0203,$0405,$0607
                dc.w    $0809,$0AFF,$0008,$0018,$0035,$0018,$0009,$0013
                dc.w    $0029,$0022,$0008,$000F,$002B,$0027,$0008,$000E
                dc.w    $002C,$0029,$0004,$0008,$0036,$002D,$0009,$FFCC
                dc.w    $0032,$0025,$000B,$FFD1,$0028,$0024,$000A,$FFD3
                dc.w    $0028,$0025,$0008,$FFD5,$002B,$0026,$0003,$FFD5
                dc.w    $0036,$002B
Brood1Cells:
                dc.w    $019C,$019D,$019E,$019F,$00DC,$00DD,$00DE,$00DF
                dc.w    $80F0,$80F1,$80F2,$80F3,$00E0,$00E1,$00E2,$00E3
                dc.w    $00F4,$00F5,$00F6,$00F7,$8108,$8109,$810A,$810B
                dc.w    $00E4,$00E5,$00E6,$00E7,$00F8,$00F9,$00FA,$00FB
                dc.w    $810C,$810D,$810E,$810F,$00E8,$00E9,$00EA,$00EB
                dc.w    $00FC,$00FD,$00FE,$00FF,$8110,$8111,$8112,$8113
                dc.w    $00EC,$00ED,$00EE,$00EF,$0100,$0101,$0102,$0103
                dc.w    $8114,$8115,$8116,$8117,$019C,$019D,$019E,$019F
                dc.w    $8010,$8011,$8012,$8013,$8024,$8025,$8026,$8027
Brood2Cells:
                dc.w    $8104,$8105,$8106,$8107,$0118,$0119,$011A,$011B
                dc.w    $0180,$0181,$0182,$0183,$811C,$811D,$811E,$811F
                dc.w    $0130,$0131,$0132,$0133,$0144,$0145,$0146,$0147
                dc.w    $8120,$8121,$8122,$8123,$0134,$0135,$0136,$0137
                dc.w    $0148,$0149,$014A,$014B,$8124,$8125,$8126,$8127
                dc.w    $0138,$0139,$013A,$013B,$014C,$014D,$014E,$014F
                dc.w    $8128,$8129,$812A,$812B,$013C,$013D,$013E,$013F
                dc.w    $0150,$0151,$0152,$0153,$800C,$800D,$800E,$800F
                dc.w    $8020,$8021,$8022,$8023,$0180,$0181,$0182,$0183
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
ZoidTurns:
                dc.w    $0809,$0A0B,$0C0D,$0E0F,$0001,$0203,$0405,$0607
ZoidSteps:
                dc.w    $0000,$FFFC,$0002,$FFFC,$0004,$FFFC,$0004,$FFFE
                dc.w    $0004,$0000,$0004,$0002,$0004,$0004,$0002,$0004
                dc.w    $0000,$0004,$FFFE,$0004,$FFFC,$0004,$FFFC,$0002
                dc.w    $FFFC,$0000,$FFFC,$FFFE,$FFFC,$FFFC,$FFFE,$FFFC
                dc.w    $0000,$FFFE,$0001,$FFFE,$0002,$FFFE,$0002,$FFFF
                dc.w    $0002,$0000,$0002,$0001,$0002,$0002,$0001,$0002
                dc.w    $0000,$0002,$FFFF,$0002,$FFFE,$0002,$FFFE,$0001
                dc.w    $FFFE,$0000,$FFFE,$FFFF,$FFFE,$FFFE,$FFFF,$FFFE
; Zoid: born from a Brood.  It drifts out on one of two paths (tables at
; $72496/$7252F), then flies around in short random straight lines, now
; and then aiming at the ship (ZoidSteps: 16 directions at 4 and at 2
; pixels a frame).  When hit it turns away.
; (32x26, 2 frames, gfx $67C66, score 500, update Upd_Zoid)
Def_Zoid:
                dc.w    $1A03,$002E,$0340,$0002,$0000,$0000,$0006,$7C66
                dc.w    $0000,$01A0,$0004,$B638,$0004,$B646
                dc.l    Upd_Zoid
                dc.b    $00,$00,$00,$00,$00,$00,$05,$00,$00,$01,$FF
ZoidAnim:
                dc.b    $06,$07,$08,$07,$FF,$02,$03,$04,$05,$FF,$00,$00,$05,$00,$02,$00
                dc.b    $16,$00,$15,$00,$04,$00,$02,$00,$18,$00,$16,$00,$02,$00,$05,$00
                dc.b    $1D,$00,$15,$00,$03,$00,$02,$00,$1A,$00,$16,$00,$08,$00,$04,$00
                dc.b    $14,$00,$12,$00,$09,$00,$05,$00,$13,$00,$11,$00,$05,$00,$01,$00
                dc.b    $19,$00,$21,$00,$05,$00,$01,$00,$1A,$00,$16,$00,$05,$00,$01,$00
                dc.b    $1A,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b    $00
