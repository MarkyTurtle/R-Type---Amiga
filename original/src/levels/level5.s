;==============================================================================
; R-Type (Amiga) - level 5 code and data (level part A)
; Tracks 122.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level5_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level5_a.bin src/levels/level5.s
;
; TEXT $4A300-$4B00F: level table, wave list, palette, scroll script, code
; DATA $4B010-$4B665: object definitions, animations, tables
; $4B666 on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; First pass: code and data separated, entry points from the level table
; named.  L_xxxxx = code, D_xxxxx = data, still to be named.
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$0D10,$0000,$0656,$0000,$0000,$0000
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
                dc.l    $50500
                dc.l    $4D300
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $51A54
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
WaveList:
                dc.w    $0604,$0004,$A572,$0000,$0004,$A344,$005A,$016D
                dc.w    $0082,$0008,$0124,$0000,$0000,$0004,$B0D0,$00C8
                dc.w    $016D,$00A0,$0006,$032A,$0000,$0000,$0004,$B0D0
                dc.w    $0103,$0170,$0087,$0003,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$0134,$0082,$00DF,$0006,$0221,$0000,$0000
                dc.w    $0004,$B0D0,$0136,$0000,$0000,$03E8,$000F,$0004
                dc.w    $B010,$0004,$B02C,$01A0,$003C,$0012,$0006,$0418
                dc.w    $0000,$0000,$0004,$B0D0,$0205,$0050,$00DF,$0006
                dc.w    $0221,$0000,$0000,$0004,$B0D0,$0268,$0136,$0014
                dc.w    $0008,$0000,$0000,$0000,$0004,$B2DA,$026A,$0136
                dc.w    $00DF,$0000,$0000,$0000,$0000,$0004,$B2DA,$026C
                dc.w    $0104,$0012,$0006,$0530,$0000,$0000,$0004,$B0D0
                dc.w    $02CB,$016D,$0078,$0006,$032A,$0000,$0000,$0004
                dc.w    $B0D0,$02D0,$008C,$0014,$0008,$0000,$0000,$0000
                dc.w    $0004,$B2DA,$02F0,$008C,$00DF,$0000,$0000,$0000
                dc.w    $0000,$0004,$B2DA,$030D,$0014,$0064,$0004,$0000
                dc.w    $0000,$0000,$0004,$B2DA,$0338,$0064,$00DF,$0006
                dc.w    $0221,$0000,$0000,$0004,$B0D0,$0339,$00C8,$00DF
                dc.w    $0000,$0000,$0000,$0000,$0004,$B2DA,$039D,$0170
                dc.w    $0028,$0006,$0618,$0000,$0000,$0004,$B0D0,$03D4
                dc.w    $0170,$005A,$0002,$FFFC,$0000,$0000,$FFFF,$FFFF
                dc.w    $03E2,$0014,$0078,$0004,$0000,$0000,$0000,$0004
                dc.w    $B2DA,$040B,$0096,$00DF,$0000,$0000,$0000,$0000
                dc.w    $0004,$B2DA,$041A,$0046,$0014,$0006,$0418,$0000
                dc.w    $0000,$0004,$B0D0,$044B,$0136,$0014,$0008,$0000
                dc.w    $0000,$0000,$0004,$B2DA,$044C,$0000,$0000,$07D0
                dc.w    $000F,$0004,$B010,$0004,$B02C,$04B0,$016D,$0078
                dc.w    $0005,$0032,$0032,$0000,$0004,$B452,$04B4,$016D
                dc.w    $0078,$0005,$0032,$0082,$0000,$0004,$B452,$0514
                dc.w    $0096,$00DF,$0000,$0000,$0000,$0000,$0004,$B2DA
                dc.w    $0516,$0064,$0014,$0008,$0000,$0000,$0000,$0004
                dc.w    $B2DA,$0541,$016D,$0078,$000C,$0000,$0000,$0000
                dc.w    $0004,$B2DA,$0582,$016D,$00A0,$0007,$0733,$0000
                dc.w    $0000,$0004,$B0D0,$05DC,$0046,$0014,$0008,$0000
                dc.w    $0000,$0000,$0004,$B2DA,$05FA,$012C,$00DF,$0000
                dc.w    $0000,$0000,$0000,$0004,$B2DA,$0640,$016D,$0096
                dc.w    $0000,$0000,$0000,$0000,$0004,$B422,$0654,$016D
                dc.w    $0078,$0000,$0000,$0000,$0000,$0004,$B422,$06A4
                dc.w    $0170,$005A,$0004,$FFFC,$0000,$0000,$FFFF,$FFFF
                dc.w    $06CC,$005A,$0014,$0008,$0000,$0000,$0000,$0004
                dc.w    $B2DA,$06CE,$016D,$0046,$0000,$0000,$0000,$0000
                dc.w    $0004,$B422,$06F4,$016D,$00B4,$000C,$0000,$0000
                dc.w    $0000,$0004,$B2DA,$06F6,$0000,$0000,$07D0,$000F
                dc.w    $0004,$B01A,$0004,$B02C,$06F9,$016D,$0032,$000C
                dc.w    $0000,$0000,$0000,$0004,$B2DA,$0747,$012C,$00DF
                dc.w    $0000,$0000,$0000,$0000,$0004,$B2DA,$0780,$0170
                dc.w    $0078,$0003,$FFFC,$0000,$0000,$FFFF,$FFFF,$0796
                dc.w    $0170,$00A0,$000C,$0000,$0000,$0000,$0004,$B2DA
                dc.w    $07BC,$016D,$006E,$0000,$0000,$0000,$0000,$0004
                dc.w    $B422,$07BD,$0140,$00DF,$0000,$0000,$0000,$0000
                dc.w    $0004,$B2DA,$07DA,$016D,$009B,$0000,$0000,$0000
                dc.w    $0000,$0004,$B422,$07F3,$016D,$0046,$0000,$0000
                dc.w    $0000,$0000,$0004,$B422,$0804,$0140,$0014,$0008
                dc.w    $0000,$0000,$0000,$0004,$B2DA,$0831,$00F0,$00DF
                dc.w    $0000,$0000,$0000,$0000,$0004,$B2DA,$0866,$0000
                dc.w    $0000,$0BB8,$000F,$0004,$B020,$0004,$B02C,$0884
                dc.w    $00E6,$00DF,$0000,$0000,$0000,$0000,$0004,$B2DA
                dc.w    $0886,$0154,$00DF,$0000,$0000,$0000,$0000,$0004
                dc.w    $B2DA,$088D,$016D,$0046,$0000,$0000,$0000,$0000
                dc.w    $0004,$B422,$0897,$016D,$0073,$0000,$0000,$0000
                dc.w    $0000,$0004,$B422,$08A1,$016D,$00A0,$0000,$0000
                dc.w    $0000,$0000,$0004,$B422,$08A4,$0154,$0014,$0008
                dc.w    $0000,$0000,$0000,$0004,$B2DA,$08CE,$0078,$0014
                dc.w    $0008,$0000,$0000,$0000,$0004,$B2DA,$08CF,$0000
                dc.w    $0000,$0FA0,$000F,$0004,$B026,$0004,$B02C,$08E5
                dc.w    $0064,$00DF,$0000,$0000,$0000,$0000,$0004,$B2DA
                dc.w    $0953,$0096,$00DF,$0006,$0221,$0000,$0000,$0004
                dc.w    $B0D0,$0977,$0136,$0014,$0008,$0000,$0000,$0000
                dc.w    $0004,$B2DA,$0995,$0064,$0014,$0008,$0000,$0000
                dc.w    $0000,$0004,$B2DA,$09C6,$010E,$0014,$0006,$0530
                dc.w    $0000,$0000,$0004,$B0D0,$09EC,$0136,$00DF,$0000
                dc.w    $0000,$0000,$0000,$0004,$B2DA,$0A1E,$0064,$00DF
                dc.w    $0000,$0000,$0000,$0000,$0004,$B2DA,$0A50,$0170
                dc.w    $0064,$0002,$FFFC,$0000,$0000,$FFFF,$FFFF,$0AC0
                dc.w    $0168,$0064,$0000,$0000,$0000,$0000,$0004,$B5F8
                dc.w    $7530
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
L_4A808:
                movea.l $A(a1),a3
                move.w  $8(a1),d7
                clr.w   d6
L_4A812:
                move.w  (a3)+,d0
                bmi.b   L_4A836
                move.w  (a3)+,d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)
                clr.w   $38(a0)
                move.w  d6,$32(a0)
                add.w   d7,d6
                jsr     (jt_ObjInsert).w
                bra.b   L_4A812
L_4A836:
                rts
L_4A838:
                tst.w   $32(a0)
                beq.b   L_4A844
                subq.w  #$1,$32(a0)
                rts
L_4A844:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   L_4A866
                cmp.w   #$170,d0
                bhi.b   L_4A866
                cmp.w   #$10,d1
                bcs.b   L_4A866
                cmp.w   #$E0,d1
                bcs.b   L_4A86A
L_4A866:
                jmp     (jt_ObjKillSelf).w
L_4A86A:
                move.w  $3A(a0),d4
                cmp.w   (ScrollX).w,d4
                bhi.b   L_4A884
                moveq   #10,d7
                cmp.w   #$88,d1
                bcs.b   L_4A880
                move.w  #$E0,d7
L_4A880:
                moveq   #4,d6
                bra.b   L_4A890
L_4A884:
                subq.w  #$1,$38(a0)
                bpl.b   L_4A8CE
                movem.w (ShipPos).w,d6-d7
L_4A890:
                moveq   #2,d4
                lea.l   (D_4B054).l,a1
                cmp.w   d6,d0
                bcs.b   L_4A8A4
                moveq   #-1,d4
                lea.l   (D_4B058).l,a1
L_4A8A4:
                move.l  a1,$2A(a0)
                moveq   #1,d5
                cmp.w   d7,d1
                bcs.b   L_4A8B0
                neg.w   d5
L_4A8B0:
                move.w  d0,d2
                sub.w   d6,d2
                bpl.b   L_4A8B8
                neg.w   d2
L_4A8B8:
                lsr.w   #$2,d2
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)
                move.b  d4,$36(a0)
                move.b  d5,$37(a0)
L_4A8CE:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6
                ext.w   d6
                bpl.b   L_4A8E4
                subq.w  #$2,d1
                bra.b   L_4A8E8
L_4A8E4:
                add.w   #$20,d1
L_4A8E8:
                addq.w  #$8,d0
                jsr     (jt_GetMapCell).w
                bne.b   L_4A8F4
                add.w   d6,$C(a0)
L_4A8F4:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1
                move.b  $36(a0),d4
                ext.w   d4
                bpl.b   L_4A906
                subq.w  #$2,d0
                bra.b   L_4A90A
L_4A906:
                add.w   #$22,d0
L_4A90A:
                jsr     (jt_GetMapCell).w
                bne.b   L_4A914
                add.w   d4,$A(a0)
L_4A914:
                rts
LevelInit:
                rts
LevelFrame:
                cmpi.w  #$BC0,(ScrollX).w
                bne.b   L_4A926
                move.w  #$B40,(ScrollX).w
L_4A926:
                rts
L_4A928:
                movem.w $2(a1),d0-d1
                move.w  #$3E8,d2
                lea.l   (D_4B0D0).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$FF00,$32(a0)
                move.w  $8(a1),$34(a0)
                clr.w   $3A(a0)
                clr.w   $36(a0)
                clr.b   $22(a0)
                move.b  #$14,$4(a0)
                jsr     (jt_ObjInsert).w
                move.w  $6(a1),d7
                moveq   #0,d6
                moveq   #0,d5
                lea.l   (D_4B18A).l,a2
                bra.b   L_4A9A4
L_4A96E:
                movea.l a0,a3
                movem.w $2(a1),d0-d1
                move.w  #$3E8,d2
                jsr     (jt_ObjCreate).w
                st.b    $32(a0)
                move.b  d6,$33(a0)
                move.w  d5,$36(a0)
                move.w  $8(a1),$34(a0)
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                move.l  a0,d0
                sub.l   a3,d0
                move.w  d0,$3C(a3)
                move.w  d0,$3A(a0)
L_4A9A4:
                addq.w  #$1,d6
                addq.w  #$4,d5
                dbra    d7,L_4A96E
                movea.l a0,a3
                movem.w $2(a1),d0-d1
                addq.w  #$2,d1
                move.w  #$7D0,d2
                lea.l   (D_4B232).l,a2
                jsr     (jt_ObjCreate).w
                st.b    $32(a0)
                move.b  d6,$33(a0)
                move.w  $8(a1),$34(a0)
                move.w  d5,$36(a0)
                clr.w   $3C(a0)
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                move.l  a0,d0
                sub.l   a3,d0
                move.w  d0,$3C(a3)
                move.w  d0,$3A(a0)
                rts
L_4A9F0:
                move.b  $32(a0),d0
                beq.b   L_4AA50
                cmp.b   #$1,d0
                beq.w   L_4AB28
                cmp.b   #$2,d0
                beq.b   L_4AA10
                subq.w  #$1,$36(a0)
                bpl.b   L_4AA0E
                clr.b   $32(a0)
L_4AA0E:
                rts
L_4AA10:
                moveq   #0,d0
                move.b  $33(a0),d0
                lsl.w   #$2,d0
                lea.l   (D_4B08C).l,a1
                movem.w (a1,d0.w),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
L_4AA2C:
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   L_4AA4C
                cmp.w   #$10,d1
                bcs.b   L_4AA4C
                cmp.w   #$170,d0
                bhi.b   L_4AA4C
                cmp.w   #$E6,d1
                bhi.b   L_4AA4C
                rts
L_4AA4C:
                jmp     (jt_ObjKillSelf).w
L_4AA50:
                cmpi.w  #$A,$26(a0)
                blt.w   L_4AAEA
                tst.b   $33(a0)
                beq.b   L_4AAB2
                move.w  $3A(a0),d0
                neg.w   d0
                lea.l   (a0,d0.w),a1
                clr.w   $3C(a1)
                movea.l a0,a1
                clr.w   $3A(a0)
                move.w  $1E(a0),d0
                lea.l   (D_4B0B0).l,a2
                lsl.w   #$1,d0
                move.w  (a2,d0.w),d1
                move.w  $34(a0),d2
L_4AA88:
                move.w  d1,$38(a1)
                clr.w   $26(a1)
                tst.b   $32(a1)
                bpl.b   L_4AA9A
                move.w  d1,$34(a0)
L_4AA9A:
                move.w  d2,$36(a1)
                move.b  #$1,$32(a1)
                move.w  $3C(a1),d0
                beq.b   L_4AAB0
                lea.l   (a1,d0.w),a1
                bra.b   L_4AA88
L_4AAB0:
                rts
L_4AAB2:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.l  #$1100,d0
                jsr     (jt_AddScore).w
                movea.l a0,a1
L_4AAC8:
                move.b  #$2,$32(a1)
                st.b    $22(a1)
                move.w  #$3,$24(a1)
                clr.w   $26(a1)
                move.w  $3C(a1),d0
                beq.w   L_4AA10
                lea.l   (a1,d0.w),a1
                bra.b   L_4AAC8
L_4AAEA:
                lea.l   ($67FC8).l,a1
                move.w  $34(a0),d0
                lea.l   (a1,d0.w),a1
                addq.w  #$3,$34(a0)
                move.b  (a1)+,d0
                move.b  (a1)+,d1
                move.b  (a1)+,d2
                cmp.b   #$7F,d0
                bne.w   L_4AB10
                subq.w  #$6,$34(a0)
                bra.b   L_4AAEA
L_4AB10:
                ext.w   d0
                ext.w   d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                and.w   #$F,d2
                move.w  d2,$1E(a0)
                bra.w   L_4AA2C
L_4AB28:
                cmpi.w  #$A,$26(a0)
                bra.b   L_4AB58
L_4AB30:
                movea.l a0,a1
L_4AB32:
                move.w  $3A(a1),d0
                neg.w   d0
                lea.l   (a1,d0.w),a1
                tst.w   d0
                bne.b   L_4AB32
L_4AB40:
                move.b  #$2,$32(a1)
                st.b    $22(a1)
                move.w  $3C(a1),d0
                beq.w   L_4AA10
                lea.l   (a1,d0.w),a1
                bra.b   L_4AB40
L_4AB58:
                move.w  $36(a0),d0
                cmp.w   $34(a0),d0
                bhi.b   L_4AAEA
                move.w  $38(a0),$34(a0)
                move.w  #$7FFF,$36(a0)
                clr.b   $32(a0)
                bra.w   L_4AAEA
L_4AB76:
                movem.w $2(a1),d0-d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  #$19,$4(a0)
                clr.w   $34(a0)
                clr.b   $22(a0)
                move.w  #$64,$36(a0)
                move.w  $6(a1),$1E(a0)
                jmp     (jt_ObjInsert).w
L_4ABA0:
                subq.w  #$1,$34(a0)
                bpl.b   L_4ABD2
                move.w  #$4,$34(a0)
                tst.w   $36(a0)
                beq.b   L_4ABD2
                subq.w  #$1,$36(a0)
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  $1E(a0),d1
                jsr     (jt_TurnTowards).w
                move.w  d1,$1E(a0)
L_4ABD2:
                move.w  $1E(a0),d0
                lsl.w   #$2,d0
                movem.w $A(a0),d1-d2
                lea.l   (D_4B394).l,a1
                add.w   (a1,d0.w),d1
                add.w   $2(a1,d0.w),d2
                cmp.w   #$10,d1
                bcs.b   L_4AC04
                cmp.w   #$170,d1
                bhi.b   L_4AC04
                cmp.w   #$10,d2
                bcs.b   L_4AC04
                cmp.w   #$E0,d2
                bcs.b   L_4AC08
L_4AC04:
                jmp     (jt_ObjKillSelf).w
L_4AC08:
                movem.w d1-d2,$A(a0)
                rts
L_4AC10:
                movem.w $2(a1),d0-d1
                moveq   #20,d2
                jsr     (jt_ObjCreate).w
                moveq   #50,d0
                jsr     (jt_Random).w
                move.w  d0,$32(a0)
                move.b  #$A,$4(a0)
                move.b  #$2,$21(a0)
                jmp     (jt_ObjInsert).w
L_4AC36:
                move.w  $6(a1),d7
                moveq   #0,d6
                moveq   #0,d5
L_4AC3E:
                move.w  $8(a1),d0
                jsr     (jt_Random).w
                add.w   $A(a1),d0
                move.w  d0,d1
                move.w  #$170,d0
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.w  d6,$34(a0)
                moveq   #70,d0
                jsr     (jt_Random).w
                move.w  d0,$32(a0)
                move.b  #$A,$4(a0)
                move.w  d5,$1E(a0)
                jsr     (jt_ObjInsert).w
                add.w   #$18,d6
                addq.w  #$1,d5
                cmp.w   #$8,d5
                bcs.b   L_4AC80
                moveq   #0,d5
L_4AC80:
                dbra    d7,L_4AC3E
                rts
L_4AC86:
                moveq   #2,d1
                moveq   #32,d7
                moveq   #25,d6
                bra.b   L_4ACA0
L_4AC8E:
                tst.w   $34(a0)
                beq.b   L_4AC9A
                subq.w  #$1,$34(a0)
                rts
L_4AC9A:
                moveq   #3,d1
                moveq   #-10,d7
                moveq   #50,d6
L_4ACA0:
                sub.w   d1,$A(a0)
                bpl.b   L_4ACAA
                jmp     (jt_ObjKillSelf).w
L_4ACAA:
                subq.w  #$1,$32(a0)
                bpl.b   L_4ACEC
                move.w  d6,$32(a0)
                move.w  d7,d0
                bmi.b   L_4ACC4
                jsr     (jt_Random).w
                addq.w  #$8,d0
                add.w   $C(a0),d0
                bra.b   L_4ACCC
L_4ACC4:
                neg.w   d7
                add.w   $C(a0),d7
                move.w  d7,d0
L_4ACCC:
                move.w  d0,d1
                move.w  $A(a0),d0
                moveq   #-1,d2
                move.l  a0,-(a7)
                lea.l   (D_4B3D4).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
L_4ACEC:
                rts
L_4ACEE:
                subq.w  #$7,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4ACFE
                jmp     (jt_ObjKillSelf).w
L_4ACFE:
                rts
L_4AD00:
                movem.w $2(a1),d0-d1
                movem.w d0-d1,(D_4B534).l
                move.w  #$2710,d2
                jsr     (jt_ObjCreate).w
                clr.w   $3C(a0)
                move.w  #$28,$38(a0)
                st.b    $3A(a0)
                clr.b   $22(a0)
                move.b  #$A,$4(a0)
                move.b  #$2,$21(a0)
                jsr     (jt_ObjInsert).w
                moveq   #7,d7
                moveq   #0,d6
                moveq   #1,d5
                lea.l   (D_4B4F4).l,a4
                lea.l   (D_4B628).l,a2
L_4AD4A:
                movem.w (D_4B534).l,d0-d1
                movem.w (a4),d2-d3
                add.w   d2,d0
                add.w   d3,d1
                move.w  #$BB8,d2
                jsr     (jt_ObjCreate).w
                move.l  a0,$4(a4)
                move.l  (a4),$36(a0)
                move.w  d6,$3A(a0)
                clr.w   $3C(a0)
                clr.l   $32(a0)
                move.b  #$1E,$4(a0)
                move.b  d5,$3D(a0)
                neg.w   d5
                jsr     (jt_ObjInsert).w
                addq.l  #$8,a4
                addq.w  #$1,d6
                dbra    d7,L_4AD4A
                st.b    (MusicFadeReq).w
                rts
L_4AD94:
                cmpi.w  #$1E,$26(a0)
                ble.b   L_4ADCA
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                st.b    (LevelComplete).w
                move.l  #$2000,d0
                jsr     (jt_AddScore).w
                lea.l   (D_4B4F4).l,a1
                moveq   #7,d0
L_4ADBC:
                movea.l $4(a1),a2
                st.b    $3C(a2)
                addq.l  #$8,a1
                dbra    d0,L_4ADBC
L_4ADCA:
                tst.b   $3A(a0)
                bpl.b   L_4ADE8
                subq.w  #$1,$38(a0)
                bmi.b   L_4ADE4
                subq.w  #$2,$A(a0)
                move.l  $A(a0),(D_4B534).l
                rts
L_4ADE4:
                clr.b   $3A(a0)
L_4ADE8:
                subq.w  #$1,$38(a0)
                bmi.w   L_4AE5C
                movem.w $32(a0),d0-d1
                movem.w $A(a0),d2-d3
                add.w   d0,d2
                add.w   d1,d3
                cmp.w   #$30,d2
                blt.b   L_4AE2A
                cmp.w   #$12E,d2
                bhi.b   L_4AE2A
                cmp.w   #$30,d3
                blt.b   L_4AE2A
                cmp.w   #$AC,d3
                bhi.b   L_4AE2A
                movem.w d2-d3,$A(a0)
                movem.w d2-d3,(D_4B534).l
                bra.w   L_4AE98
L_4AE2A:
                lsr.w   $38(a0)
                moveq   #0,d0
                moveq   #0,d1
                move.b  $37(a0),d1
                lea.l   (D_4B4E4).l,a1
                move.b  (a1,d1.w),d0
                move.b  d0,$37(a0)
                lsl.w   #$2,d0
                lea.l   (D_4B598).l,a1
                movem.w (a1,d0.w),d2-d3
                movem.w d2-d3,$32(a0)
                bra.w   L_4ADCA
L_4AE5C:
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.b  d0,$37(a0)
                move.w  d0,d1
                lsl.w   #$2,d1
                lea.l   (D_4B598).l,a1
                movem.w (a1,d1.w),d2-d3
                movem.w d2-d3,$32(a0)
                moveq   #100,d0
                jsr     (jt_Random).w
                add.w   #$14,d0
                move.w  d0,$38(a0)
                bra.w   L_4ADCA
L_4AE98:
                subq.w  #$1,$3C(a0)
                bmi.b   L_4AEA0
                rts
L_4AEA0:
                move.w  #$23,$3C(a0)
                moveq   #0,d2
                movem.w (D_4B534).l,d0-d1
                add.w   #$18,d0
                add.w   #$18,d1
                sub.w   (ShipPos).w,d0
                bpl.b   L_4AEC0
                addq.w  #$1,d2
L_4AEC0:
                sub.w   ($F0).w,d1
                bpl.b   L_4AEC8
                addq.w  #$2,d2
L_4AEC8:
                lsl.w   #$3,d2
                lea.l   (D_4B5D8).l,a1
                lea.l   (D_4B4F4).l,a2
                adda.l  d2,a1
                moveq   #6,d1
L_4AEDA:
                moveq   #0,d0
                move.b  (a1)+,d0
                lsl.w   #$3,d0
                tst.l   $4(a2,d0.w)
                bne.b   L_4AEEC
L_4AEE6:
                dbra    d1,L_4AEDA
                rts
L_4AEEC:
                movea.l $4(a2,d0.w),a3
                tst.w   $32(a3)
                bne.b   L_4AEE6
                movem.w $A(a3),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                addq.w  #$1,d0
                move.w  d0,$32(a3)
                move.w  #$1,$34(a3)
                rts
L_4AF14:
                cmpi.w  #$14,$26(a0)
                blt.b   L_4AF40
L_4AF1C:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.w  $3A(a0),d0
                lsl.w   #$3,d0
                lea.l   (D_4B4F4).l,a1
                clr.l   $4(a1,d0.w)
                move.l  #$300,d0
                jmp     (jt_AddScore).w
L_4AF40:
                tst.b   $3C(a0)
                bmi.b   L_4AF1C
                move.w  $32(a0),d0
                beq.w   L_4AFEA
                subq.w  #$1,d0
                lsl.w   #$2,d0
                lea.l   (D_4B558).l,a1
                lea.l   (a1,d0.w),a1
                movem.w $36(a0),d0-d1
                movem.w (a1),d2-d3
                tst.b   $34(a0)
                bne.b   L_4AF72
                add.w   d2,d0
                add.w   d3,d1
                bra.b   L_4AFAC
L_4AF72:
                sub.w   d2,d0
                sub.w   d3,d1
                subq.b  #$1,$35(a0)
                bne.b   L_4AF92
                clr.w   $32(a0)
                move.w  $3A(a0),d2
                lsl.w   #$3,d2
                lea.l   (D_4B4F4).l,a1
                movem.w (a1,d2.w),d0-d1
L_4AF92:
                movem.w d0-d1,$36(a0)
                add.w   (D_4B534).l,d0
                add.w   (D_4B536).l,d1
                movem.w d0-d1,$A(a0)
                rts
L_4AFAC:
                movem.w d0-d1,$36(a0)
                addq.b  #$1,$35(a0)
                add.w   (D_4B534).l,d0
                add.w   (D_4B536).l,d1
                cmp.w   #$30,d0
                bcs.b   L_4AFE2
                cmp.w   #$148,d0
                bhi.b   L_4AFE2
                cmp.w   #$30,d1
                bcs.b   L_4AFE2
                cmp.w   #$D0,d1
                bhi.b   L_4AFE2
                movem.w d0-d1,$A(a0)
                rts
L_4AFE2:
                st.b    $34(a0)
                bra.w   L_4AF14
L_4AFEA:
                movem.w (D_4B534).l,d0-d1
                add.w   $36(a0),d0
                add.w   $38(a0),d1
                move.b  $3D(a0),d2
                ext.w   d2
                neg.b   $3D(a0)
                add.w   d2,d0
                sub.w   d2,d1
                movem.w d0-d1,$A(a0)
                rts
                dc.w    $0014,$0064,$0170,$00AA,$FFFF,$008C,$00DF,$FFFF
                dc.w    $012C,$00DF,$FFFF,$0014,$0064,$FFFF,$1A03,$002E
                dc.w    $0340,$0005,$0001,$0022,$0005,$4E08,$0000,$01A0
                dc.w    $0004,$B054,$0004,$B05C
                dc.l    L_4A838
                dc.l    L_4A808
                dc.w    $0000,$0300
D_4B054:
                dc.w    $0304,$05FF
D_4B058:
                dc.w    $0001,$02FF,$0004,$0002,$0018,$0016,$0002,$0003
                dc.w    $001B,$0014,$0004,$0004,$0018,$0013,$0005,$0004
                dc.w    $0018,$0014,$0004,$0003,$0019,$0015,$0005,$0003
                dc.w    $0018,$0015
D_4B08C:
                dc.w    $0000,$FFFC,$FFFE,$FFFC,$FFFC,$FFFC,$FFFC,$FFFE
                dc.w    $FFFC,$0000,$FFFC,$0002,$FFFC,$0004,$FFFE,$0004
                dc.w    $0000,$0004
D_4B0B0:
                dc.w    $0000,$0009,$0015,$001E,$002A,$0036,$0042,$004B
                dc.w    $0051,$005D,$0063,$006C,$0072,$0084,$0090,$0099
D_4B0D0:
                dc.w    $1D03,$002E,$03A0,$0000,$0000,$0000,$0005,$CDC8
                dc.w    $0000,$01D0,$0004,$B0F8,$0004,$B10A
                dc.l    L_4A9F0
                dc.l    L_4A928
                dc.w    $0000,$0500,$0001,$0203,$0405,$0607,$0809,$0A0B
                dc.w    $0C0D,$0E0F,$FF00,$0006,$0002,$0014,$0018,$0006
                dc.w    $0001,$0014,$0019,$0006,$0003,$0014,$0016,$0004
                dc.w    $0004,$0018,$0015,$0003,$0005,$0019,$0014,$0005
                dc.w    $0005,$0016,$0014,$0005,$0005,$0016,$0016,$0005
                dc.w    $0003,$0014,$0016,$0005,$0002,$0013,$0018,$0004
                dc.w    $0003,$0015,$0017,$0003,$0002,$0015,$0019,$0003
                dc.w    $0004,$0019,$0015,$0004,$0004,$0017,$0014,$0003
                dc.w    $0003,$0017,$0016,$0004,$0002,$0017,$0015,$0005
                dc.w    $0002,$0014,$0018
D_4B18A:
                dc.w    $1D03,$002E,$03A0,$0000,$0000,$0000,$0006,$07C8
                dc.w    $0000,$01D0,$0004,$B0F8,$0004,$B1B2
                dc.l    L_4A9F0
                dc.l    L_4A928
                dc.w    $0000,$0300,$0006,$0004,$0012,$0016,$0006,$0003
                dc.w    $0012,$0016,$0005,$0005,$0014,$0014,$0004,$0003
                dc.w    $0016,$0015,$0004,$0004,$0016,$0012,$0004,$0003
                dc.w    $0017,$0014,$0005,$0003,$0016,$0014,$0005,$0002
                dc.w    $0014,$0016,$0007,$0003,$0012,$0015,$0007,$0003
                dc.w    $0013,$0016,$0007,$0002,$0013,$0016,$0005,$0004
                dc.w    $0015,$0014,$0005,$0006,$0016,$0012,$0004,$0005
                dc.w    $0017,$0013,$0005,$0004,$0015,$0015,$0005,$0004
                dc.w    $0015,$0015
D_4B232:
                dc.w    $1703,$002E,$02E0,$0000,$0000,$0000,$0006,$41C8
                dc.w    $0000,$0170,$0004,$B0F8,$0004,$B25A
                dc.l    L_4A9F0
                dc.l    L_4A928
                dc.w    $0000,$0300,$0003,$0002,$0011,$0012,$0003,$0001
                dc.w    $0010,$0012,$0003,$0001,$0012,$0012,$0002,$0002
                dc.w    $0013,$0012,$0002,$0003,$0012,$0010,$0004,$0002
                dc.w    $0012,$0012,$0003,$0002,$0013,$0012,$0004,$0003
                dc.w    $0011,$0012,$0003,$0002,$0011,$0012,$0003,$0003
                dc.w    $0012,$0012,$0003,$0003,$0012,$0012,$0003,$0003
                dc.w    $0012,$0011,$0002,$0003,$0014,$0010,$0002,$0003
                dc.w    $0012,$0011,$0001,$0002,$0012,$0012,$0003,$0002
                dc.w    $0010,$0012,$1C03,$002E,$0380,$0000,$0000,$000A
                dc.w    $0005,$7708,$0000,$01C0,$0004,$B302,$0004,$B314
                dc.l    L_4ABA0
                dc.l    L_4AB76
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$0809,$0A0B
                dc.w    $0C0D,$0E0F,$FF00,$0007,$0004,$0012,$0013,$0006
                dc.w    $0005,$0012,$0013,$0008,$0004,$0010,$0014,$0006
                dc.w    $0005,$0012,$0013,$0007,$0005,$0012,$0014,$0008
                dc.w    $0005,$0010,$0014,$0005,$0004,$0013,$0013,$0005
                dc.w    $0007,$0015,$000F,$0007,$0004,$0010,$0015,$0007
                dc.w    $0004,$0011,$0014,$0006,$0006,$0012,$0012,$0007
                dc.w    $0005,$0012,$0013,$0006,$0004,$0012,$0012,$0007
                dc.w    $0004,$0012,$0014,$0007,$0005,$0012,$0013,$0007
                dc.w    $0004,$0011,$0015
D_4B394:
                dc.w    $0000,$FFFD,$0002,$FFFD,$0003,$FFFD,$0003,$FFFE
                dc.w    $0003,$0000,$0003,$0002,$0003,$0003,$0002,$0003
                dc.w    $0000,$0003,$FFFE,$0003,$FFFD,$0003,$FFFD,$0002
                dc.w    $FFFD,$0000,$FFFD,$FFFE,$FFFD,$FFFD,$FFFE,$FFFD
D_4B3D4:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0005,$6188
                dc.w    $0000,$0030,$0004,$B41C,$0004,$B3FC
                dc.l    L_4ACEE
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0001,$0203,$FF00,$2904
                dc.w    $002C,$07B0,$0003,$0000,$0000,$0005,$AF08,$0000
                dc.w    $03D8,$0004,$B44A,$0004,$B47A
                dc.l    L_4AC86
                dc.l    L_4AC10
                dc.w    $0000,$0800,$0001,$0203,$0201,$FF00,$1403,$002E
                dc.w    $0280,$0002,$0000,$0000,$0005,$6308,$0000,$0140
                dc.w    $0004,$B49A,$0004,$B4A4
                dc.l    L_4AC8E
                dc.l    L_4AC36
                dc.w    $0000,$0400,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0001,$0203,$0405,$0607,$FF00,$0001
                dc.w    $0003,$0017,$000F,$0003,$0003,$0015,$000C,$0001
                dc.w    $0002,$0018,$000B,$0001,$0002,$0019,$000D,$0002
                dc.w    $0002,$0017,$0010,$0001,$0005,$0018,$000D,$0001
                dc.w    $0006,$000E,$000C,$0001,$0005,$0018,$000D
D_4B4E4:
                dc.w    $0809,$0A0B,$0C0D,$0E0F,$0001,$0203,$0405,$0607
D_4B4F4:
                dc.w    $FFF9,$000D,$0000,$0000,$FFFA,$0020,$0000,$0000
                dc.w    $0009,$0017,$0000,$0000,$000B,$FFFE,$0000,$0000
                dc.w    $001E,$FFF6,$0000,$0000,$001F,$000D,$0000,$0000
                dc.w    $0019,$001D,$0000,$0000,$FFFB,$FFF7,$0000,$0000
D_4B534:
                dc.w    $0000
D_4B536:
                dc.w    $0000,$0008,$0009,$000A,$000B,$000C,$000D,$000E
                dc.w    $000F,$0000,$0001,$0002,$0003,$0004,$0005,$0006
                dc.w    $0007
D_4B558:
                dc.w    $0000,$FFFC,$0002,$FFFC,$0004,$FFFC,$0004,$FFFE
                dc.w    $0004,$0000,$0004,$0002,$0004,$0004,$0002,$0004
                dc.w    $0000,$0004,$FFFE,$0004,$FFFC,$0004,$FFFC,$0002
                dc.w    $FFFC,$0000,$FFFC,$FFFE,$FFFC,$FFFC,$FFFE,$FFFC
D_4B598:
                dc.w    $0000,$FFFE,$0001,$FFFE,$0002,$FFFE,$0002,$FFFF
                dc.w    $0002,$0000,$0002,$0001,$0002,$0002,$0001,$0002
                dc.w    $0000,$0002,$FFFF,$0002,$FFFE,$0002,$FFFE,$0001
                dc.w    $FFFE,$0000,$FFFE,$FFFF,$FFFE,$FFFE,$FFFF,$FFFE
D_4B5D8:
                dc.w    $0001,$0305,$0204,$0607,$0506,$0304,$0001,$0702
                dc.w    $0704,$0603,$0502,$0100,$0201,$0403,$0700,$0605
                dc.w    $3004,$002C,$0900,$0000,$0000,$0000,$0006,$6FC8
                dc.w    $0000,$0480,$0004,$B660,$0004,$B620
                dc.l    L_4AD94
                dc.l    L_4AD00
                dc.w    $0000,$1000,$0011,$0012,$0010,$0010
D_4B628:
                dc.w    $1C03,$002E,$0380,$0001,$0000,$0000,$0006,$78C8
                dc.w    $0000,$01C0,$0004,$B660,$0004,$B650
                dc.l    L_4AF14
                dc.l    L_4AD00
                dc.w    $0000,$0500,$0001,$0001,$0018,$0019,$0002,$0001
                dc.w    $0016,$0019,$0001,$FF00,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
