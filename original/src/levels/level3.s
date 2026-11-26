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
; First pass: code and data separated, entry points from the level table
; named.  L_xxxxx = code, D_xxxxx = data, still to be named.
;==============================================================================
                include "engine.i"

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
                dc.l    $62700
                dc.l    D_4D300
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $634D0
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
WaveList:
                dc.w    $0000,$0004,$A554,$002D,$0170,$0066,$0000,$0000
                dc.w    $0000,$0000,$0004,$BB74,$009C,$016F,$0036,$0000
                dc.w    $0008,$0000,$0000,$0004,$B85A,$00EB,$0170,$0028
                dc.w    $0002,$FFFC,$0000,$0000,$FFFF,$FFFF,$010F,$015F
                dc.w    $002E,$0000,$0008,$0000,$0000,$0004,$B85A,$012C
                dc.w    $0170,$00A9,$0001,$0008,$0000,$0000,$0004,$B85A
                dc.w    $0163,$015D,$003C,$0000,$0008,$0000,$0000,$0004
                dc.w    $B85A,$01BD,$015D,$003B,$0000,$0008,$0000,$0000
                dc.w    $0004,$B85A,$01E0,$015E,$001E,$0002,$FFFC,$0000
                dc.w    $0000,$FFFF,$FFFF,$02D2,$0170,$00D3,$0001,$001E
                dc.w    $0000,$0000,$0004,$B85A,$032F,$00F8,$00DF,$0001
                dc.w    $001E,$0000,$0000,$0004,$B85A,$0514,$013A,$0088
                dc.w    $0000,$0000,$0000,$0000,$0004,$BD38,$055A,$0154
                dc.w    $0091,$0001,$FFFC,$0000,$0000,$FFFF,$FFFF,$07D0
                dc.w    $015B,$008C,$0001,$0032,$0000,$0000,$0004,$B85A
                dc.w    $085B,$010C,$0009,$0000,$0003,$0000,$0000,$0004
                dc.w    $B85A,$0870,$0159,$009A,$0000,$0008,$0004,$B962
                dc.w    $0004,$B902,$0898,$016E,$0018,$0000,$0006,$0000
                dc.w    $0000,$0004,$B85A,$08CB,$015D,$00AE,$0000,$0004
                dc.w    $0004,$B972,$0004,$B902,$08D4,$0164,$00A0,$0000
                dc.w    $0004,$0004,$B972,$0004,$B902,$094C,$0162,$0046
                dc.w    $0000,$0004,$0004,$B9A2,$0004,$B902,$094D,$015F
                dc.w    $006A,$0000,$0004,$0004,$B982,$0004,$B902,$094E
                dc.w    $0167,$0058,$0000,$0004,$0004,$B992,$0004,$B902
                dc.w    $0993,$0168,$0082,$0000,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$FFFF
LevelPalette:
                dc.w    $0565,$0BBB,$0777,$0500,$005F,$0343,$0DB0,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0D70,$0FF0,$0FFF
LevelInit:
                move.w  #$78,(ScrollY).w
                move.l  #D_4B3DC,(D_4B46A).l
                clr.w   (D_4B472).l
                lea.l   (D_4B590).l,a4
                moveq   #9,d7
L_4A71E:
                movea.l (a4)+,a0
                bsr.w   L_4A7E2
                dbra    d7,L_4A71E
                move.l  #L_4A91A,(D_4B61E).l
                move.l  #D_4B62E,(D_4B622).l
                clr.b   (D_4B62D).l
                clr.w   (D_4B628).l
                clr.w   (D_4B626).l
                clr.b   (D_4B62C).l
                move.w  #$15C7,(D_4B62A).l
                bra.w   L_4B1B6
LevelFrame:
                addq.w  #$1,(D_4B472).l
                movea.l (D_4B46A).l,a1
                move.w  (D_4B472).l,d0
                cmp.w   (a1)+,d0
                bcs.b   L_4A784
                bsr.w   L_4A79E
                addi.l  #$14,(D_4B46A).l
L_4A784:
                subq.w  #$1,(D_4B62A).l
                bpl.b   L_4A796
                st.b    (D_4B62C).l
                st.b    (LevelComplete).w
L_4A796:
                bsr.w   L_4A8B8
                bra.w   L_4B20E
L_4A79E:
                movem.w (a1)+,d0-d1
                move.w  #$3E8,d2
                lea.l   (D_4B5B8).l,a2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.w  (a1)+,d0
                move.b  d0,$36(a0)
                move.w  (a1)+,d0
                move.b  d0,$3C(a0)
                move.w  (a1)+,d0
                move.b  d0,$3D(a0)
                clr.b   $37(a0)
                move.l  $4(a1),$32(a0)
                move.w  (ScrollX).w,$38(a0)
                move.w  (ScrollY).w,$3A(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a1),a0
L_4A7E2:
                moveq   #0,d0
                moveq   #0,d1
                movea.l (a0)+,a1
                move.b  (a0)+,d0
                move.b  (a0)+,d1
L_4A7EC:
                move.w  d0,d2
                movea.l a1,a2
L_4A7F0:
                move.w  (a0)+,(a2)+
                dbra    d2,L_4A7F0
                adda.l  (MapRowBytes).w,a1
                dbra    d1,L_4A7EC
                rts
L_4A800:
                bsr.w   L_4A892
                subq.b  #$1,$37(a0)
                bpl.b   L_4A838
                moveq   #50,d0
                jsr     (jt_Random).w
                add.w   #$1E,d0
                move.b  d0,$37(a0)
                movem.w $A(a0),d0-d1
                moveq   #0,d2
                move.b  $3D(a0),d2
                lsl.w   #$2,d2
                lea.l   (D_4B5FA).l,a1
                add.w   (a1,d2.w),d0
                add.w   $2(a1,d2.w),d1
                jsr     (jt_FireEnemyBullet).w
L_4A838:
                moveq   #0,d0
                move.b  $36(a0),d0
                cmp.w   $26(a0),d0
                bhi.b   L_4A85E
                tst.b   $3C(a0)
                bne.b   L_4A860
                movea.l a0,a3
                movea.l $32(a0),a0
                bsr.b   L_4A7E2
                movea.l a3,a0
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
L_4A85E:
                rts
L_4A860:
                subq.b  #$1,$3C(a0)
                move.w  #$FFFF,$24(a0)
                move.l  a0,-(a7)
                moveq   #50,d0
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                move.w  $C(a0),d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
L_4A892:
                move.w  (ScrollX).w,d0
                move.w  d0,d1
                sub.w   $38(a0),d0
                move.w  d1,$38(a0)
                sub.w   d0,$A(a0)
                move.w  (ScrollY).w,d0
                move.w  d0,d1
                sub.w   $3A(a0),d0
                move.w  d1,$3A(a0)
                sub.w   d0,$C(a0)
                rts
L_4A8B8:
                tst.b   (D_4B62C).l
                beq.b   L_4A912
L_4A8C0:
                move.w  #$96,d0
                jsr     (jt_Random).w
                sub.w   #$50,d0
                add.w   (D_4B470).l,d0
                move.w  d0,d1
                bmi.b   L_4A8C0
                cmp.w   #$E0,d1
                bhi.b   L_4A8C0
L_4A8DC:
                move.w  #$A0,d0
                jsr     (jt_Random).w
                add.w   (D_4B46E).l,d0
                bmi.b   L_4A8DC
                cmp.w   #$15E,d0
                bhi.b   L_4A8DC
                moveq   #-1,d2
                lea.l   (D_4B7DC).l,a2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  #$A,$4(a0)
                jmp     (jt_ObjInsert).w
L_4A912:
                movea.l (D_4B61E).l,a1
                jmp     (a1)
L_4A91A:
                cmpi.w  #$5F0,(D_4B472).l
                bcs.b   L_4A972
                cmpi.w  #$AF0,(D_4B472).l
                bcs.b   L_4A942
                subq.b  #$1,(D_4B62D).l
                bpl.b   L_4A942
                move.b  #$A,(D_4B62D).l
                bsr.w   Spawn_4AA96
L_4A942:
                subq.w  #$1,(D_4B626).l
                bpl.b   L_4A972
                move.w  #$3,(D_4B626).l
                movea.l (D_4B622).l,a1
                cmpa.l  #D_4B63E,a1
                bcs.b   L_4A966
                lea.l   (D_4B62E).l,a1
L_4A966:
                movea.l (a1)+,a0
                move.l  a1,(D_4B622).l
                bsr.w   L_4A7E2
L_4A972:
                cmpi.w  #$A8C,(D_4B472).l
                bne.b   L_4A998
                moveq   #122,d0
                moveq   #98,d1
                moveq   #-1,d2
                lea.l   (D_4B7DC).l,a2
                jsr     (jt_ObjCreate).w
                clr.w   $32(a0)
                jsr     (jt_ObjInsert).w
                st.b    (MusicFadeReq).w
L_4A998:
                bcs.b   L_4A9C4
                subq.w  #$1,(D_4B628).l
                bpl.b   L_4A9C4
                move.l  #L_4A9C6,(D_4B61E).l
                move.l  #D_4B63E,(D_4B622).l
                clr.w   (D_4B626).l
                move.w  #$B,(D_4B628).l
L_4A9C4:
                rts
L_4A9C6:
                subq.w  #$1,(D_4B626).l
                bpl.b   L_4A9C4
                bsr.w   L_4AA36
                bne.b   L_4A9C4
                move.w  #$19,(D_4B626).l
                move.l  #L_4A9E8,(D_4B61E).l
                rts
L_4A9E8:
                subq.w  #$1,(D_4B626).l
                bpl.b   L_4AA02
                move.w  #$B,(D_4B628).l
                move.l  #L_4AA04,(D_4B61E).l
L_4AA02:
                rts
L_4AA04:
                subq.w  #$1,(D_4B626).l
                bpl.b   L_4AA02
                bsr.w   L_4AA36
                bne.b   L_4AA02
                move.l  #L_4A91A,(D_4B61E).l
                clr.w   (D_4B626).l
                move.l  #D_4B62E,(D_4B622).l
                move.w  #$7D,(D_4B628).l
                rts
L_4AA36:
                move.w  #$2,(D_4B626).l
                movea.l (D_4B622).l,a1
                movea.l (a1)+,a0
                move.l  a1,(D_4B622).l
                bsr.w   L_4A7E2
                subq.w  #$1,(D_4B628).l
                rts
L_4AA58:
                movem.w $A(a0),d0-d1
                jsr     (jt_AdjustForScroll).w
                movem.w d0-d1,$A(a0)
                movem.w d0-d1,(D_4B46E).l
                move.w  $26(a0),d0
                cmp.w   $32(a0),d0
                beq.b   L_4AA94
                move.w  d0,$32(a0)
                move.b  #$3,$28(a0)
                cmp.w   #$A,d0
                bcs.b   L_4AA94
                st.b    (D_4B62C).l
                st.b    (LevelComplete).w
L_4AA94:
                rts
Spawn_4AA96:
                movea.l a0,a4
                movem.w (D_4B46E).l,d0-d1
                sub.w   #$23,d0
                sub.w   #$14,d1
                moveq   #1,d2
                lea.l   (Def_4B80C).l,a2
                jsr     (jt_ObjCreate).w
                moveq   #7,d0
                jsr     (jt_Random).w
                move.w  d0,$32(a0)
L_4AABE:
                moveq   #4,d0
                jsr     (jt_Random).w
                subq.w  #$2,d0
                neg.w   d0
                beq.b   L_4AABE
                move.w  d0,$34(a0)
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                rts
Upd_4AADC:
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                addq.w  #$8,d1
                jsr     (jt_GetMapCell).w
                beq.b   L_4AAF8
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                rts
L_4AAF8:
                lea.l   ($6FCA6).l,a1
                move.w  $32(a0),d2
                move.b  (a1,d2.w),d1
                cmp.b   #$7F,d1
                bne.b   L_4AB12
                subq.w  #$1,$32(a0)
                bra.b   L_4AAF8
L_4AB12:
                addq.w  #$1,$32(a0)
                ext.w   d1
                move.w  $34(a0),d0
                add.w   $A(a0),d0
                bmi.b   L_4AB3C
                cmp.w   #$170,d0
                bhi.b   L_4AB3C
                add.w   $C(a0),d1
                bmi.b   L_4AB3C
                cmp.w   #$E0,d1
                bhi.b   L_4AB3C
                movem.w d0-d1,$A(a0)
                rts
L_4AB3C:
                jmp     (jt_ObjKillSelf).w
Spawn_4AB40:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                move.w  $8(a1),$24(a0)
                move.w  (ScrollX).w,$38(a0)
                move.w  (ScrollY).w,$3A(a0)
                clr.b   $37(a0)
                clr.b   $22(a0)
                clr.w   $32(a0)
                tst.w   $6(a1)
                beq.b   L_4AB78
                move.l  #D_4B892,$2A(a0)
L_4AB78:
                jmp     (jt_ObjInsert).w
Spawn_4AB7C:
                movem.w $2(a1),d0-d1
                move.w  #$1F40,d2
                jsr     (jt_ObjCreate).w
                move.b  $9(a1),$3C(a0)
                move.l  $A(a1),$2A(a0)
                move.w  (ScrollX).w,$38(a0)
                move.w  (ScrollY).w,$3A(a0)
                move.l  $A(a0),$32(a0)
                move.b  #$32,$36(a0)
                move.b  #$1,$37(a0)
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
Upd_4ABBC:
                bsr.w   L_4A892
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   L_4ABDE
                cmp.w   #$172,d0
                bhi.b   L_4ABDE
                cmp.w   #$9,d1
                bcs.b   L_4ABDE
                cmp.w   #$E0,d1
                bcs.b   L_4ABE2
L_4ABDE:
                jmp     (jt_ObjKillSelf).w
L_4ABE2:
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  d0,$1E(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4AC2A
                moveq   #50,d0
                jsr     (jt_Random).w
                add.w   #$1E,d0
                move.b  d0,$37(a0)
                movem.w $A(a0),d0-d1
                move.w  $1E(a0),d2
                movea.l $2A(a0),a1
                move.b  (a1,d2.w),d2
                lea.l   (D_4B8E2).l,a1
                lsl.w   #$2,d2
                add.w   (a1,d2.w),d0
                add.w   $2(a1,d2.w),d1
                jsr     (jt_FireEnemyBullet).w
L_4AC2A:
                rts
Upd_4AC2C:
                move.l  $32(a0),$A(a0)
                bsr.w   L_4A892
                movem.w $A(a0),d0-d1
                movem.w d0-d1,$32(a0)
                tst.b   $37(a0)
                bmi.w   L_4AD84
                beq.w   L_4AD58
                cmp.w   #$10,d0
                bcs.b   L_4AC66
                cmp.w   #$172,d0
                bhi.b   L_4AC66
                cmp.w   #$10,d1
                bcs.b   L_4AC66
                cmp.w   #$DC,d1
                bcs.b   L_4AC6A
L_4AC66:
                jmp     (jt_ObjKillSelf).w
L_4AC6A:
                move.b  $3C(a0),d2
                cmp.b   $27(a0),d2
                bhi.b   L_4ACB0
                movea.l a0,a3
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (Def_4B902).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                clr.b   $37(a0)
                move.b  #$6E,$36(a0)
                move.w  #$FFFF,$A(a0)
                rts
L_4ACB0:
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  d0,$1E(a0)
                movea.l $2A(a0),a1
                move.b  (a1,d0.w),d0
                and.w   #$7,d0
                lea.l   (D_4B9B2).l,a1
                move.w  d0,d7
                lsl.w   #$2,d0
                movem.w (a1,d0.w),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                subq.b  #$1,$36(a0)
                bne.b   L_4AD56
                movea.l a0,a4
                moveq   #-1,d2
                movem.w $A(a0),d0-d1
                cmp.w   #$170,d0
                bhi.b   L_4AD48
                cmp.w   #$10,d1
                bcs.b   L_4AD48
                cmp.w   #$DF,d1
                bhi.b   L_4AD48
                lea.l   (Def_4B9CE).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$4(a0)
                move.w  #$3,$1E(a0)
                move.b  d7,$3C(a0)
                lea.l   (D_4BAB0).l,a3
                lsl.w   #$3,d7
                move.l  $4(a3,d7.w),$2A(a0)
                move.l  (a3,d7.w),$32(a0)
                move.l  $A(a4),$36(a0)
                clr.w   $A(a0)
                move.b  #$4,$3A(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
L_4AD48:
                moveq   #100,d0
                jsr     (jt_Random).w
                add.w   #$96,d0
                move.b  d0,$36(a0)
L_4AD56:
                rts
L_4AD58:
                btst.b  #$0,(D_4B473).l
                bne.b   L_4AD7C
                subq.b  #$1,$36(a0)
                bne.b   L_4AD7C
                st.b    $37(a0)
                move.b  #$28,$36(a0)
                clr.b   $3D(a0)
                move.w  #$FFFF,$24(a0)
L_4AD7C:
                move.w  #$FFFF,$A(a0)
                rts
L_4AD84:
                subq.b  #$1,$36(a0)
                bne.b   L_4ADA2
                move.b  #$1,$37(a0)
                move.b  #$19,$36(a0)
                move.w  #$FA0,$24(a0)
                clr.w   $26(a0)
                bra.b   L_4ADB2
L_4ADA2:
                eori.b  #$FF,$3D(a0)
                bne.b   L_4ADB2
                move.w  #$FFFF,$A(a0)
                rts
L_4ADB2:
                movem.w $32(a0),d0-d1
                movem.w d0-d1,$A(a0)
                bra.w   L_4ACB0
Upd_4ADC2:
                tst.b   $3A(a0)
                beq.b   L_4ADEC
                subq.b  #$1,$3A(a0)
                movem.w $36(a0),d0-d1
                movea.l $32(a0),a1
                add.w   (a1)+,d0
                add.w   (a1)+,d1
                movem.w d0-d1,$A(a0)
                move.l  a1,$32(a0)
                tst.b   $3A(a0)
                beq.b   L_4ADEC
                rts
L_4ADEC:
                moveq   #0,d0
                move.b  $3C(a0),d0
                lsl.w   #$2,d0
                lea.l   (D_4BB58).l,a1
                movem.w (a1,d0.w),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4AE20
                cmpi.w  #$10,$C(a0)
                bcs.b   L_4AE20
                cmpi.w  #$E0,$C(a0)
                bcs.b   L_4AE24
L_4AE20:
                jmp     (jt_ObjKillSelf).w
L_4AE24:
                rts
Spawn_4AE26:
                clr.w   (D_4BC9A).l
                move.l  #L_4AFD0,(D_4BC92).l
                move.w  #$64,(D_4BC90).l
                movem.w $2(a1),d0-d1
                move.w  #$BB8,d2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$4(a0)
                move.w  (ScrollX).w,$38(a0)
                move.w  (ScrollY).w,$3A(a0)
                move.b  #$19,$3D(a0)
                move.b  #$32,$32(a0)
                clr.w   $34(a0)
                move.w  #$3E8,$36(a0)
                jmp     (jt_ObjInsert).w
Upd_4AE78:
                cmpi.w  #$1E,$26(a0)
                bcc.w   L_4AF2A
                cmpi.w  #$14,$26(a0)
                bhi.b   L_4AE90
                subq.w  #$1,$36(a0)
                bpl.b   L_4AEDE
L_4AE90:
                st.b    (D_4BC9B).l
                clr.w   (D_4BC90).l
                lea.l   ($6FAD0).l,a1
                move.w  $34(a0),d2
                cmpi.w  #$EA,$34(a0)
                bcc.w   L_4AF2A
                move.b  (a1,d2.w),d0
                add.w   #$EB,d2
                move.b  (a1,d2.w),d1
                ext.w   d0
                ext.w   d1
                add.w   d1,$C(a0)
                add.w   d0,$A(a0)
                bmi.b   L_4AED2
                cmpi.w  #$D0,$C(a0)
                bcs.b   L_4AED6
L_4AED2:
                jmp     (jt_ObjKillSelf).w
L_4AED6:
                addq.w  #$1,$34(a0)
                bra.w   L_4AF9C
L_4AEDE:
                bsr.w   L_4A892
                bsr.w   L_4AF9C
                subq.b  #$1,$32(a0)
                bpl.b   L_4AF28
                move.b  #$23,$32(a0)
                movea.l a0,a4
                lea.l   (D_4BC9C).l,a3
                moveq   #2,d7
L_4AEFC:
                movem.w $A(a4),d0-d1
                add.w   #$10,d0
                add.w   (a3)+,d1
                moveq   #-1,d2
                lea.l   (Def_4BCAE).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)
                move.l  (a3)+,$32(a0)
                jsr     (jt_ObjInsert).w
                dbra    d7,L_4AEFC
                movea.l a4,a0
L_4AF28:
                rts
L_4AF2A:
                st.b    (D_4BC9B).l
                clr.w   (D_4BC90).l
                subq.b  #$1,$3D(a0)
                bmi.b   L_4AF88
                move.w  #$FFFF,$24(a0)
                movea.l a0,a3
                moveq   #30,d0
                jsr     (jt_Random).w
                sub.w   #$A,d0
                add.w   $C(a0),d0
                move.w  d0,d1
                moveq   #96,d0
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                sub.w   #$F,d0
                moveq   #-1,d2
                lea.l   (Def_4BB74).l,a2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  #$A,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                bra.w   L_4AF9C
L_4AF88:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.l  #$800,d0
                jmp     (jt_AddScore).w
L_4AF9C:
                move.l  a0,-(a7)
                movea.l (D_4BC92).l,a1
                jsr     (a1)
                tst.b   (D_4BC9B).l
                beq.b   L_4AFCC
                move.l  #L_4AFEC,(D_4BC92).l
                lea.l   (D_4BBCC).l,a0
                bsr.w   L_4A7E2
                lea.l   (D_4BC4A).l,a0
                bsr.w   L_4A7E2
L_4AFCC:
                movea.l (a7)+,a0
                rts
L_4AFD0:
                subq.w  #$1,(D_4BC90).l
                bpl.b   L_4AFEC
                move.l  #L_4AFEE,(D_4BC92).l
                move.l  #D_4BC68,(D_4BC96).l
L_4AFEC:
                rts
L_4AFEE:
                movea.l (D_4BC96).l,a4
                move.l  (a4)+,d0
                beq.b   L_4AFFE
                movea.l d0,a0
                bsr.w   L_4A7E2
L_4AFFE:
                move.l  (a4)+,d0
                bmi.b   L_4B010
                movea.l d0,a0
                bsr.w   L_4A7E2
                move.l  a4,(D_4BC96).l
                rts
L_4B010:
                move.w  #$4B,(D_4BC90).l
                move.l  #L_4B022,(D_4BC92).l
L_4B022:
                subq.w  #$1,(D_4BC90).l
                bpl.b   L_4B046
                move.w  #$4B,(D_4BC90).l
                move.l  #L_4AFD0,(D_4BC92).l
                lea.l   (D_4BC4A).l,a0
                bra.w   L_4A7E2
L_4B046:
                lea.l   (D_4BC0E).l,a0
                eori.b  #$FF,(D_4BC9A).l
                beq.b   L_4B05C
                lea.l   (D_4BC2C).l,a0
L_4B05C:
                bra.w   L_4A7E2
Upd_4B060:
                movem.w $32(a0),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                cmpi.w  #$10,$A(a0)
                bcs.b   L_4B086
                cmpi.w  #$10,$C(a0)
                bcs.b   L_4B086
                cmpi.w  #$E0,$C(a0)
                bcs.b   L_4B08A
L_4B086:
                jmp     (jt_ObjKillSelf).w
L_4B08A:
                rts
L_4B08C:
                movem.w $2(a1),d0-d1
                move.w  #$7D0,d2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)
                move.b  #$19,$3D(a0)
                move.w  (ScrollX).w,$38(a0)
                move.w  (ScrollY).w,$3A(a0)
                move.w  #$226,$34(a0)
                move.b  #$19,$32(a0)
                st.b    $33(a0)
                jmp     (jt_ObjInsert).w
L_4B0C6:
                bsr.w   L_4A892
                cmpi.w  #$37,$26(a0)
                bcc.b   L_4B0F4
                bsr.w   L_4B15A
                subq.w  #$1,$34(a0)
                bpl.b   L_4B0F2
                addq.w  #$1,$C(a0)
                tst.w   $A(a0)
                bmi.b   L_4B0EE
                cmpi.w  #$CF,$C(a0)
                bcs.b   L_4B0F2
L_4B0EE:
                jmp     (jt_ObjKillSelf).w
L_4B0F2:
                rts
L_4B0F4:
                subq.b  #$1,$3D(a0)
                bmi.b   L_4B146
                move.w  #$FFFF,$24(a0)
                movea.l a0,a3
                moveq   #30,d0
                jsr     (jt_Random).w
                sub.w   #$A,d0
                add.w   $C(a0),d0
                move.w  d0,d1
                move.w  #$A0,d0
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                sub.w   #$F,d0
                moveq   #-1,d2
                lea.l   (D_4BD38).l,a2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  #$1E,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                rts
L_4B146:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.l  #$800,d0
                jmp     (jt_AddScore).w
L_4B15A:
                moveq   #19,d7
                subq.b  #$1,$32(a0)
                bne.b   L_4B1A2
                eori.b  #$FF,$33(a0)
                bne.b   L_4B172
                move.b  #$1,$32(a0)
                bra.b   L_4B17A
L_4B172:
                moveq   #27,d7
                move.b  #$19,$32(a0)
L_4B17A:
                movea.l a0,a4
                movem.w $A(a4),d0-d1
                add.w   d7,d1
                moveq   #-1,d2
                lea.l   (Def_4BCEA).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                move.b  #$A,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
L_4B1A2:
                rts
Upd_4B1A4:
                subq.w  #$7,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4B1B4
                jmp     (jt_ObjKillSelf).w
L_4B1B4:
                rts
L_4B1B6:
                lea.l   (D_4C012).l,a0
                bsr.w   L_4A7E2
                clr.w   (D_4C320).l
                clr.w   (D_4C322).l
                move.b  #$1,(D_4C338).l
                move.l  #D_4BE0A,(D_4C326).l
                move.l  #D_4BD6A,(D_4C32A).l
                clr.b   (D_4C339).l
                move.w  #$FFFE,(D_4C336).l
                clr.w   (D_4C332).l
                clr.b   (D_4C33A).l
                move.l  #D_4BDBE,(D_4C32E).l
                rts
L_4B20E:
                tst.b   (D_4C338).l
                beq.b   L_4B256
                bmi.w   L_4B2F2
                cmpi.w  #$578,(D_4B472).l
                bcs.b   L_4B254
                move.l  a0,-(a7)
                move.w  #$139,d0
                move.w  #$8A,d1
                move.w  #$FA0,d2
                lea.l   (D_4C33C).l,a2
                jsr     (jt_ObjCreate).w
                move.w  (ScrollX).w,$38(a0)
                move.w  (ScrollY).w,$3A(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                clr.b   (D_4C338).l
L_4B254:
                rts
L_4B256:
                cmpi.w  #$50,(D_4C332).l
                bcc.b   L_4B28E
                subq.w  #$1,(D_4C320).l
                bpl.b   L_4B254
                movea.l (D_4C326).l,a4
                movea.l (a4)+,a0
                move.l  (a4)+,d0
                move.w  d0,(D_4C320).l
                bmi.b   L_4B286
                bsr.w   L_4A7E2
                move.l  a4,(D_4C326).l
                rts
L_4B286:
                st.b    (D_4C338).l
                rts
L_4B28E:
                move.b  (D_4C339).l,d7
                bne.w   L_4B35C
L_4B298:
                movea.l (D_4C32A).l,a4
                move.l  (a4)+,d0
                bmi.b   L_4B286
                cmp.w   (D_4C332).l,d0
                bhi.b   L_4B2F2
                move.w  (a4)+,d0
                move.b  d0,(D_4C33A).l
                move.w  (a4)+,d0
                move.w  d0,(D_4C324).l
                addq.l  #$2,(D_4C32E).l
                move.l  (a4)+,d6
                bpl.b   L_4B2CC
                move.b  d6,(D_4C339).l
                bra.b   L_4B2D8
L_4B2CC:
                movea.l d6,a0
                bsr.w   L_4A7E2
                clr.b   (D_4C339).l
L_4B2D8:
                move.l  a4,(D_4C32A).l
                addq.w  #$1,(D_4C336).l
                clr.w   (D_4C334).l
                clr.w   (D_4C322).l
                bra.b   L_4B28E
L_4B2F2:
                tst.b   (D_4C33A).l
                beq.b   L_4B35A
                movea.l a0,a3
                subq.b  #$1,(D_4C33A).l
                bne.b   L_4B30E
                move.l  #$600,d0
                jsr     (jt_AddScore).w
L_4B30E:
                moveq   #30,d0
                jsr     (jt_Random).w
                add.w   (D_4C31E).l,d0
                move.w  d0,d1
                sub.w   #$1B,d1
                move.w  (D_4C324).l,d0
                jsr     (jt_Random).w
                add.w   (D_4C31C).l,d0
                movea.l (D_4C32E).l,a2
                add.w   (a2),d0
                moveq   #-1,d2
                lea.l   (D_4C33C).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.b  #$5,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
L_4B35A:
                rts
L_4B35C:
                lea.l   (D_4BDCE).l,a1
                neg.b   d7
                subq.b  #$1,d7
                beq.b   L_4B36E
                lea.l   (D_4BDEC).l,a1
L_4B36E:
                subq.w  #$1,(D_4C322).l
                bpl.w   L_4B298
                move.w  (D_4C334).l,d7
                move.w  $4(a1,d7.w),(D_4C322).l
                movea.l (a1,d7.w),a0
                bsr.w   L_4A7E2
                cmp.w   #$18,d7
                bcs.b   L_4B39E
                clr.w   (D_4C334).l
                bra.w   L_4B298
L_4B39E:
                addq.w  #$6,(D_4C334).l
                bra.w   L_4B298
L_4B3A8:
                bsr.w   L_4A892
                movem.w $A(a0),d0-d1
                movem.w d0-d1,(D_4C31C).l
                move.w  $26(a0),(D_4C332).l
                move.w  (D_4C336).l,d0
                bmi.b   L_4B3DA
                move.w  d0,$1E(a0)
                tst.b   (D_4C338).l
                bpl.b   L_4B3DA
                jmp     (jt_ObjKillSelf).w
L_4B3DA:
                rts
D_4B3DC:
                dc.w    $00FA,$015C,$0066,$0012,$0005,$0000,$0004,$B474
                dc.w    $0004,$B486,$00FB,$015C,$0076,$0012,$0005,$0001
                dc.w    $0004,$B498,$0004,$B4A4,$0100,$015B,$0095,$0019
                dc.w    $0000,$0002,$0004,$B4B0,$0004,$B4BE,$0AFD,$00C8
                dc.w    $0037,$0003,$0000,$0003,$0004,$B574,$0004,$B582
                dc.w    $0AFE,$00A4,$0032,$0003,$0000,$0004,$0004,$B558
                dc.w    $0004,$B566,$0B83,$0064,$006E,$0002,$0000,$0005
                dc.w    $0004,$B53C,$0004,$B54A,$0BCF,$0035,$007D,$0002
                dc.w    $0000,$0006,$0004,$B520,$0004,$B52E,$FFFF
D_4B46A:
                dc.w    $0000,$0000
D_4B46E:
                dc.w    $0000
D_4B470:
                dc.w    $0000
D_4B472:
                dc.b    $00
D_4B473:
                dc.b    $00,$00,$06,$2D,$08,$02,$01,$00,$64,$00,$65,$00,$66,$00,$78,$00
                dc.b    $79,$00,$7A,$00,$06,$2D,$08,$02,$01,$00,$01,$00,$02,$00,$03,$00
                dc.b    $00,$00,$00,$00,$00,$00,$06,$2E,$18,$02,$00,$00,$8C,$00,$8D,$00
                dc.b    $8E,$00,$06,$2E,$18,$02,$00,$00,$14,$00,$15,$00,$16,$00,$06,$2E
                dc.b    $A0,$01,$01,$00,$A0,$00,$A1,$00,$B4,$00,$B5,$00,$06,$2E,$A0,$01
                dc.b    $01,$00,$28,$00,$A1,$00,$00,$00,$29,$00,$06,$2A,$FC,$01,$01,$00
                dc.b    $1E,$00,$1F,$00,$32,$00,$33,$00,$06,$2A,$FC,$01,$01,$00,$00,$00
                dc.b    $00,$00,$04,$00,$05,$00,$06,$2B,$00,$01,$01,$00,$20,$00,$21,$00
                dc.b    $34,$00,$35,$00,$06,$2B,$00,$01,$01,$00,$00,$00,$00,$00,$17,$00
                dc.b    $18,$00,$06,$2B,$8C,$01,$01,$00,$36,$00,$37,$00,$4A,$00,$4B,$00
                dc.b    $06,$2B,$8C,$01,$01,$00,$00,$00,$00,$80,$2A,$80,$2B,$00,$06,$2C
                dc.b    $18,$01,$01,$00,$4C,$00,$4D,$00,$60,$00,$61,$00,$06,$2C,$18,$01
                dc.b    $01,$80,$19,$00,$00,$80,$60,$00,$06,$00,$06,$2B,$12,$01,$01,$01
                dc.b    $05,$01,$06,$01,$19,$01,$1A,$00,$06,$2B,$12,$01,$01,$00,$00,$00
                dc.b    $00,$80,$3C,$81,$1A,$00,$06,$2A,$0A,$01,$01,$00,$E1,$00,$E2,$00
                dc.b    $F5,$00,$F6,$00,$06,$2A,$0A,$01,$01,$00,$00,$00,$00,$80,$C8,$80
                dc.b    $C9,$00,$06,$2A,$0E,$01,$01,$00,$00,$00,$E4,$00,$F7,$00,$F8,$00
                dc.b    $06,$2A,$0E,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
D_4B590:
                dc.w    $0004,$B4CC,$0004,$B4E8,$0004,$B504,$0004,$B520
                dc.w    $0004,$B53C,$0004,$B558,$0004,$B574,$0004,$BC4A
                dc.w    $0004,$BBCC,$0004,$B696
D_4B5B8:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B5EA
                dc.w    $0000,$0000,$0004,$B5E0,$0004,$B5E2
                dc.l    L_4A800
                dc.w    $0000,$0000,$0000,$0400,$00FF,$0000,$0000,$0017
                dc.w    $000D,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000
D_4B5FA:
                dc.w    $0000,$0002,$0000,$FFFF,$0000,$0006,$0008,$FFF9
                dc.w    $0008,$FFF7,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000
D_4B61E:
                dc.w    $0000,$0000
D_4B622:
                dc.w    $0000,$0000
D_4B626:
                dc.w    $0000
D_4B628:
                dc.w    $0000
D_4B62A:
                dc.w    $0000
D_4B62C:
                dc.b    $00
D_4B62D:
                dc.b    $00
D_4B62E:
                dc.w    $0004,$B7A4,$0004,$B7B2,$0004,$B7C0,$0004,$B7CE
D_4B63E:
                dc.w    $0004,$B6B4,$0004,$B6D2,$0004,$B6F0,$0004,$B70E
                dc.w    $0004,$B72C,$0004,$B744,$0004,$B75C,$0004,$B774
                dc.w    $0004,$B77E,$0004,$B788,$0004,$B796,$0004,$B788
                dc.w    $0004,$B77E,$0004,$B774,$0004,$B75C,$0004,$B744
                dc.w    $0004,$B72C,$0004,$B70E,$0004,$B6F0,$0004,$B6D2
                dc.w    $0004,$B6B4,$0004,$B7A4,$0006,$2CA4,$0302,$8062
                dc.w    $0063,$8140,$8141,$8076,$8077,$8154,$8155,$808A
                dc.w    $808B,$8168,$8169,$0006,$2CA4,$0302,$000A,$800B
                dc.w    $800C,$800D,$800E,$800F,$8010,$8011,$8022,$8023
                dc.w    $8024,$8169,$0006,$2CA4,$0302,$0012,$8013,$8025
                dc.w    $8026,$0038,$8039,$803A,$803B,$81D4,$8027,$804E
                dc.w    $8169,$0006,$2CA4,$0302,$0000,$00D2,$80AC,$80AD
                dc.w    $00E5,$80E6,$80C0,$80C1,$81D4,$80D3,$80D4,$80D5
                dc.w    $0006,$2CA4,$0302,$0000,$00E7,$80E8,$80E9,$0000
                dc.w    $80FB,$80FC,$80FD,$81D4,$810F,$8110,$8111,$0006
                dc.w    $2CA6,$0202,$0160,$8124,$8125,$0174,$8161,$8139
                dc.w    $81D5,$8175,$814D,$0006,$2CA6,$0202,$0187,$8188
                dc.w    $8189,$019B,$819C,$819D,$81D5,$81B0,$81B1,$0006
                dc.w    $2CA6,$0202,$0000,$81AE,$81AF,$0000,$81C2,$81C3
                dc.w    $81D5,$81D6,$81D7,$0006,$2CA8,$0001,$81C4,$81D8
                dc.w    $0006,$2CA8,$0001,$81C5,$81D9,$0006,$2CA8,$0101
                dc.w    $01BE,$01BF,$01D2,$01D3,$0006,$2CA8,$0101,$00FA
                dc.w    $019A,$01C0,$01C1,$0006,$2CA8,$0101,$8140,$8141
                dc.w    $8154,$8155,$0006,$2CA8,$0101,$80DC,$80DD,$80F0
                dc.w    $80F1,$0006,$2CA8,$0101,$80DE,$80DF,$80F2,$80F3
                dc.w    $0006,$2CA8,$0101,$80CC,$80E3,$80E0,$8104
D_4B7DC:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$B5EA
                dc.w    $0000,$0000,$0004,$B5E0,$0004,$B804
                dc.l    L_4AA58
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$001E,$0012
; object definition: 16x10, 4 frames, gfx $6F850, update Upd_4AADC, spawn Spawn_4AA96
Def_4B80C:
                dc.w    $0A02,$0030,$00A0,$0003,$0000,$0000,$0006,$F850
                dc.w    $0000,$0050,$0004,$B834,$0004,$B83A
                dc.l    Upd_4AADC
                dc.l    Spawn_4AA96
                dc.w    $0000,$0000,$0001,$0203,$FF00,$0001,$0001,$0008
                dc.w    $0008,$0001,$0001,$0008,$0008,$0001,$0001,$0008
                dc.w    $0008,$0001,$0001,$0008,$0008
; object definition: 32x23, 8 frames, gfx $66FD0, score 200, update Upd_4ABBC, spawn Spawn_4AB40
Def_4B85A:
                dc.w    $1703,$002E,$02E0
                dc.w    $0000,$0000,$0000,$0006,$6FD0,$0000,$0170,$0004
                dc.w    $B882,$0004,$B8A2
                dc.l    Upd_4ABBC
                dc.l    Spawn_4AB40
                dc.w    $0000,$0200,$0303,$0303,$0202,$0101,$0000,$0000
                dc.w    $0000,$0102
D_4B892:
                dc.w    $0707,$0707,$0707,$0707,$0606,$0605,$0504,$0404
                dc.w    $0015,$000B,$0016,$000B,$000A,$0009,$000E,$000D
                dc.w    $000B,$0002,$000C,$0014,$0009,$0008,$000D,$000E
                dc.w    $0004,$0001,$0013,$000B,$000A,$0001,$000D,$000D
                dc.w    $000B,$0001,$000C,$0014,$0008,$0001,$000E,$000D
D_4B8E2:
                dc.w    $FFFA,$0007,$0000,$0000,$000A,$FFF9,$0010,$FFFE
                dc.w    $FFF7,$0003,$0003,$000B,$000A,$000F,$0010,$000B
; object definition: 32x28, 6 frames, gfx $686D0, score 200, update Upd_4AC2C, spawn Spawn_4AB7C
Def_4B902:
                dc.w    $1C03,$002E,$0380,$0000,$0000,$0000,$0006,$86D0
                dc.w    $0000,$01C0,$0004,$B962,$0004,$B92A
                dc.l    Upd_4AC2C
                dc.l    Spawn_4AB7C
                dc.w    $0000,$0200,$0007,$0001,$0012,$0013,$0009,$0001
                dc.w    $000E,$0019,$0007,$0001,$0014,$0014,$0002,$0007
                dc.w    $0018,$000E,$0007,$0006,$0013,$0015,$0009,$0002
                dc.w    $000E,$0019,$0006,$0007,$0013,$0013,$0303,$0303
                dc.w    $0302,$0201,$0100,$0000,$0003,$0303,$0404,$0404
                dc.w    $0303,$0202,$0101,$0101,$0104,$0404,$0404,$0403
                dc.w    $0302,$0201,$0101,$0101,$0104,$0404,$0505,$0404
                dc.w    $0303,$0202,$0101,$0101,$0105,$0505,$0505,$0404
                dc.w    $0303,$0202,$0202,$0202,$0606,$0605
D_4B9B2:
                dc.w    $0000,$0000,$0004,$FFFF,$0007,$0001,$000D,$FFF9
                dc.w    $0008,$FFF2,$0004,$FFF2,$0000,$FFF3
; object definition: 32x26, 5 frames, gfx $6C110, update Upd_4ADC2
Def_4B9CE:
                dc.w    $1A03,$002E,$0340,$0000,$0000,$0000,$0006,$C110
                dc.w    $0000,$01A0,$0004,$BA7E,$0004,$B9F6
                dc.l    Upd_4ADC2
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
D_4BAB0:
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
D_4BB58:
                dc.w    $FFFE,$0002,$0000,$0002,$0002,$0002,$0002,$0000
                dc.w    $0002,$FFFE,$0000,$FFFE,$FFFE,$FFFE
; object definition: 96x32, 1 frame, gfx $69F50, score 1000, update Upd_4AE78, spawn Spawn_4AE26
Def_4BB74:
                dc.w    $2007,$0026,$0C00,$0000,$0000,$0000,$0006,$9F50
                dc.w    $0000,$0600,$0004,$BB9C,$0004,$BB9E
                dc.l    Upd_4AE78
                dc.l    Spawn_4AE26
                dc.w    $0000,$1000,$00FF,$0000,$0000,$0059,$0020,$0006
                dc.w    $2CFC,$0303,$01A6,$8193,$8194,$8195,$81BA,$81A7
                dc.w    $81A8,$81A9,$81CE,$81BB,$81BC,$81BD,$01B9,$81CF
                dc.w    $81D0,$01D1
D_4BBCC:
                dc.w    $0006,$2CFC,$0303,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0006,$2D88,$0101,$01F5,$81CD
                dc.w    $0209,$81E1,$0006,$2D88,$0101,$826F,$8270,$0271
                dc.w    $8272
D_4BC0E:
                dc.w    $0006,$2D80,$0501,$8266,$8267,$8268,$8269,$826A
                dc.w    $826B,$827A,$827B,$827C,$827D,$827E,$827F
D_4BC2C:
                dc.w    $0006,$2D80,$0501,$828E,$828F,$8290,$8291,$8292
                dc.w    $8293,$82A2,$82A3,$82A4,$82A5,$82A6,$82A7
D_4BC4A:
                dc.w    $0006,$2D80,$0501,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000
D_4BC68:
                dc.w    $0000,$0000,$0004,$BBA6,$0004,$BBCC,$0004,$BBF2
                dc.w    $0000,$0000,$0004,$BC00,$0000,$0000,$0004,$BBA6
                dc.w    $0004,$BBCC,$FFFF,$FFFF
D_4BC90:
                dc.w    $0000
D_4BC92:
                dc.w    $0000,$0000
D_4BC96:
                dc.w    $0000,$0000
D_4BC9A:
                dc.b    $00
D_4BC9B:
                dc.b    $00
D_4BC9C:
                dc.w    $0003,$FFF8,$FFF9,$0009,$FFF4,$0000,$000F,$FFF8
                dc.w    $0007
; object definition: 16x14, 2 frames, gfx $6AB50, update Upd_4B060
Def_4BCAE:
                dc.w    $0E02,$0030,$00E0,$0000,$0000,$0000,$0006,$AB50
                dc.w    $0000,$0070,$0004,$BCD6,$0004,$BCDA
                dc.l    Upd_4B060
                dc.w    $0000,$0000,$0000,$0000,$0001,$FF00,$0002,$0001
                dc.w    $000D,$000C,$0002,$0001,$000D,$000C
; object definition: 32x3, 4 frames, gfx $66E50, update Upd_4B1A4
Def_4BCEA:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0006,$6E50
                dc.w    $0000,$0030,$0004,$BD32,$0004,$BD12
                dc.l    Upd_4B1A4
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0001,$0203,$FF00
D_4BD38:
                dc.w    $200B,$001E,$1400,$0000,$0000,$0000,$0006,$AD10
                dc.w    $0000,$0A00,$0004,$BD60,$0004,$BD62
                dc.l    L_4B0C6
                dc.l    L_4B08C
                dc.w    $0000,$0800,$00FF,$0000,$0000,$0094,$0020
D_4BD6A:
                dc.w    $0000,$0000,$0000,$0000,$0004,$C012,$0000,$0000
                dc.w    $0006,$0019,$FFFF,$FFFF,$0000,$00C4,$000C,$0034
                dc.w    $0004,$C26E,$0000,$00DC,$0007,$0019,$0004,$C294
                dc.w    $0000,$0118,$0009,$0019,$0004,$C2A2,$0000,$0154
                dc.w    $000A,$0034,$FFFF,$FFFE,$0000,$01B8,$000E,$0019
                dc.w    $0004,$C30A
D_4BDBE:
                dc.w    $FFFF,$FFFF,$FFE7,$FFE7,$000E,$0028,$0028,$0040
D_4BDCE:
                dc.w    $0004,$C214,$0064,$0004,$C232,$0003,$0004,$C240
                dc.w    $0003,$0004,$C24E,$0003,$0004,$C25C,$0003
D_4BDEC:
                dc.w    $0004,$C2B4,$0064,$0004,$C2D2,$0002,$0004,$C2E0
                dc.w    $0002,$0004,$C2EE,$0002,$0004,$C2FC,$0002
D_4BE0A:
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
D_4C012:
                dc.w    $0006,$2F44,$0705,$00C2,$80C3,$80C4,$80C5,$80C6
                dc.w    $80C7,$81A4,$81A5,$00D6,$00D7,$00D8,$00D9,$00DA
                dc.w    $00DB,$01B8,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0006,$2F44,$0601,$00EA,$80EB
                dc.w    $80EC,$80ED,$80EE,$80EF,$81CC,$00FE,$00FF,$0100
                dc.w    $0101,$0102,$0103,$01E0,$0006,$2F44,$0601,$8112
                dc.w    $8113,$8114,$8115,$8116,$8117,$81F4,$0126,$0127
                dc.w    $0128,$0129,$012A,$012B,$0208,$0006,$2FCC,$0704
                dc.w    $013A,$013B,$013C,$013D,$013E,$013F,$021C,$021D
                dc.w    $814E,$814F,$8150,$8151,$8152,$8153,$8230,$8231
                dc.w    $8162,$8163,$8164,$8165,$8166,$8167,$8244,$8245
                dc.w    $8176,$8177,$8178,$8179,$817A,$817B,$8258,$8259
                dc.w    $818A,$818B,$818C,$818D,$818E,$818F,$826C,$826D
                dc.w    $0006,$2FCC,$0704,$019E,$019F,$01A0,$01A1,$01A2
                dc.w    $01A3,$01E2,$01E3,$81B2,$81B3,$81B4,$81B5,$81B6
                dc.w    $81B7,$81F6,$81F7,$81C6,$81C7,$81C8,$81C9,$81CA
                dc.w    $81CB,$820A,$820B,$81DA,$81DB,$81DC,$81DD,$81DE
                dc.w    $81DF,$821E,$821F,$81EE,$81EF,$81F0,$81F1,$81F2
                dc.w    $81F3,$8232,$8233,$0006,$2FCC,$0704,$0202,$0203
                dc.w    $0204,$0205,$0206,$0207,$01E4,$01E5,$8216,$8217
                dc.w    $8218,$8219,$821A,$821B,$81F8,$81F9,$822A,$822B
                dc.w    $822C,$822D,$822E,$822F,$820C,$820D,$823E,$823F
                dc.w    $8240,$8241,$8242,$8243,$8220,$8221,$8252,$8253
                dc.w    $8254,$8255,$8256,$8257,$8234,$8235,$0006,$2FCC
                dc.w    $0704,$01E8,$01E9,$01EA,$01EB,$01EC,$01ED,$01E6
                dc.w    $01E7,$81FC,$81FD,$81FE,$81FF,$8200,$8201,$81FA
                dc.w    $81FB,$8210,$8211,$8212,$8213,$8214,$8215,$820E
                dc.w    $820F,$8224,$8225,$8226,$8227,$8228,$8229,$8222
                dc.w    $8223,$8238,$8239,$823A,$823B,$823C,$823D,$8236
                dc.w    $8237,$0006,$2F44,$0203,$0246,$8247,$80C4,$025A
                dc.w    $025B,$026E,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0006,$2FCC,$0101,$0248,$0249,$025C,$825D,$0006
                dc.w    $2FCC,$0101,$024A,$024B,$025E,$825F,$0006,$2FCC
                dc.w    $0101,$024C,$024D,$8260,$8261,$0006,$2FCC,$0102
                dc.w    $024E,$024F,$8262,$8263,$0276,$0277,$0006,$2F44
                dc.w    $0303,$0246,$8273,$8250,$8251,$0000,$0000,$0264
                dc.w    $0265,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0006,$2F48,$0101,$8278,$8279,$0000,$0000
                dc.w    $0006,$2F4A,$0201,$8279,$8280,$8281,$0275,$0294
                dc.w    $0295,$0006,$2F4A,$0302,$8279,$8282,$828C,$828D
                dc.w    $0000,$0000,$02A0,$02A1,$0000,$0000,$0000,$0000
                dc.w    $0006,$2FD6,$0101,$0289,$028A,$029D,$829E,$0006
                dc.w    $2FD6,$0101,$0287,$0288,$029B,$829C,$0006,$2FD6
                dc.w    $0101,$0285,$0286,$0299,$829A,$0006,$2FD6,$0101
                dc.w    $0297,$0284,$0296,$8298,$0006,$2F4E,$0102,$828B
                dc.w    $829F,$0000,$0000,$0000,$0000
D_4C31C:
                dc.w    $0000
D_4C31E:
                dc.w    $0000
D_4C320:
                dc.w    $0000
D_4C322:
                dc.w    $0000
D_4C324:
                dc.w    $0000
D_4C326:
                dc.w    $0000,$0000
D_4C32A:
                dc.w    $0000,$0000
D_4C32E:
                dc.w    $0000,$0000
D_4C332:
                dc.w    $0000
D_4C334:
                dc.w    $0000
D_4C336:
                dc.w    $0000
D_4C338:
                dc.b    $00
D_4C339:
                dc.b    $00
D_4C33A:
                dc.w    $0000
D_4C33C:
                dc.w    $0101,$0032,$0000,$0000,$0000,$0000,$0004,$C38A
                dc.w    $0000,$0000,$0004,$C364,$0004,$C36A
                dc.l    L_4B3A8
                dc.w    $0000,$0000,$0000,$0000,$0001,$0202,$03FF,$0001
                dc.w    $0001,$005D,$000F,$001B,$0001,$0041,$000F,$0035
                dc.w    $0001,$0027,$000F,$004F,$0001,$0010,$000F,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
D_4D300:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
