;==============================================================================
; R-Type (Amiga) - level 4 code and data (level part A)
; Tracks 111.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level4_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level4_a.bin src/levels/level4.s
;
; TEXT $4A300-$4B6A1: level table, wave list, palette, scroll script, code
; DATA $4B6A2-$4BE8F: object definitions, animations, tables
; $4BE90 on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; First pass: code and data separated, entry points from the level table
; named.  L_xxxxx = code, D_xxxxx = data, still to be named.
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$13A2,$0000,$07EE,$0000,$0000,$0000
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
                dc.l    $6EA6A
                dc.l    D_4D300
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $52078               ; LvMusic: player in level B; samples $53FB6 (8), data $5404C, periods $53FF6
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
WaveList:
                dc.w    $04A1,$0004,$A710,$0000,$0004,$A344,$0066,$0170
                dc.w    $007D,$0000,$0000,$0004,$BCA6,$0004,$BD08,$0076
                dc.w    $0170,$007A,$FFFA,$0000,$0000,$0000,$0004,$BD08
                dc.w    $00C8,$0170,$0096,$0000,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$00DE,$0170,$00B6,$0009,$0007,$0000,$0000
                dc.w    $0004,$B7E4,$0115,$0170,$002B,$FFFA,$0000,$0000
                dc.w    $0000,$0004,$BD08,$0127,$0000,$0000,$03E8,$000E
                dc.w    $0004,$BA0C,$0004,$BA4A,$0128,$0000,$0000,$0004
                dc.w    $B6A2,$0000,$0000,$0004,$B6F2,$015E,$0170,$00B6
                dc.w    $0009,$0007,$0000,$0000,$0004,$B7E4,$015F,$0000
                dc.w    $0000,$0004,$B6B8,$0000,$0000,$0004,$B6F2,$018B
                dc.w    $0000,$0000,$0004,$B6CA,$0000,$0000,$0004,$B6F2
                dc.w    $0192,$000A,$002B,$0006,$0000,$0000,$0000,$0004
                dc.w    $BD08,$01A2,$00B6,$000A,$FFFF,$0006,$0000,$0000
                dc.w    $0004,$BD08,$01B8,$0170,$0032,$0003,$FFFC,$0000
                dc.w    $0000,$FFFF,$FFFF,$01E3,$0000,$0000,$0004,$B6DC
                dc.w    $0000,$0000,$0004,$B6F2,$01EF,$0118,$0004,$0001
                dc.w    $0000,$0004,$BCB4,$0004,$BD08,$01F4,$0170,$00B6
                dc.w    $FFFE,$0000,$0000,$0000,$0004,$B95C,$020A,$0170
                dc.w    $007B,$FFFA,$0000,$0000,$0000,$0004,$BD08,$0210
                dc.w    $0170,$00B6,$0009,$0007,$0000,$0000,$0004,$B7E4
                dc.w    $023A,$0170,$0028,$0001,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$0260,$00CD,$0002,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$B95C,$0271,$0069,$000A,$FFFF,$0006,$0000
                dc.w    $0000,$0004,$BD08,$0284,$00BA,$0002,$0002,$0000
                dc.w    $0000,$0000,$0004,$B95C,$029E,$0000,$0000,$FFFF
                dc.w    $000A,$0004,$BA16,$0004,$BA4A,$02BA,$011A,$000B
                dc.w    $0004,$B764,$0008,$FFFF,$0004,$B772,$0338,$00D0
                dc.w    $00DF,$FFFF,$FFFA,$0000,$0000,$0004,$BD08,$033E
                dc.w    $0170,$003A,$FFFA,$0000,$0000,$0000,$0004,$BD08
                dc.w    $034A,$00D0,$0005,$FFFF,$0006,$0000,$0000,$0004
                dc.w    $BD08,$034E,$0005,$002B,$0006,$0000,$0000,$0000
                dc.w    $0004,$BD08,$035B,$0000,$0000,$FFFF,$000A,$0004
                dc.w    $BA16,$0004,$BA4A,$0375,$0170,$007B,$FFFA,$0000
                dc.w    $0000,$0000,$0004,$BD08,$0376,$0064,$0005,$0002
                dc.w    $FFFF,$0000,$0000,$0004,$BDC2,$0384,$0000,$0000
                dc.w    $FFFF,$000A,$0004,$BA1C,$0004,$BA4A,$0396,$0005
                dc.w    $009B,$0006,$0000,$0000,$0000,$0004,$BD08,$03C6
                dc.w    $0064,$0002,$0002,$0000,$0000,$0000,$0004,$B95C
                dc.w    $03CA,$0170,$006B,$FFFA,$0000,$0000,$0000,$0004
                dc.w    $BD08,$03DE,$0064,$0002,$0002,$0000,$0000,$0000
                dc.w    $0004,$B95C,$03EC,$0064,$0002,$0002,$0000,$0000
                dc.w    $0000,$0004,$B95C,$03ED,$009B,$0002,$FFFE,$0000
                dc.w    $0000,$0000,$0004,$B95C,$03FA,$0170,$007B,$FFFA
                dc.w    $0000,$0000,$0000,$0004,$BD08,$0407,$0170,$0032
                dc.w    $0005,$FFFC,$0000,$0000,$FFFF,$FFFF,$0427,$0170
                dc.w    $00AA,$0004,$FFFC,$0000,$0000,$FFFF,$FFFF,$042E
                dc.w    $0118,$0005,$0002,$FFFF,$0000,$0000,$0004,$BDC2
                dc.w    $0432,$0170,$003B,$FFFA,$0000,$0000,$0000,$0004
                dc.w    $BD08,$045C,$00BE,$0002,$0002,$0000,$0000,$0000
                dc.w    $0004,$B95C,$045D,$000A,$002B,$0006,$0000,$0000
                dc.w    $0000,$0004,$BD08,$0465,$0170,$00B6,$FFFE,$0000
                dc.w    $0000,$0000,$0004,$B95C,$047C,$0170,$00B6,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$B95C,$047D,$002D,$0002
                dc.w    $0002,$0000,$0000,$0000,$0004,$B95C,$047E,$006E
                dc.w    $0002,$0002,$0000,$0000,$0000,$0004,$B95C,$0482
                dc.w    $0011,$00B6,$0002,$0000,$0000,$0000,$0004,$B95C
                dc.w    $0483,$0014,$00B6,$0009,$0007,$0000,$0000,$0004
                dc.w    $B7E4,$0486,$0170,$00B6,$0009,$0007,$0000,$0000
                dc.w    $0004,$B7E4,$048B,$012C,$0005,$0001,$0000,$0004
                dc.w    $BCD0,$0004,$BD08,$048C,$0005,$0090,$0001,$0000
                dc.w    $0004,$BCC2,$0004,$BD08,$04DD,$0000,$0000,$FFFF
                dc.w    $000A,$0004,$BA22,$0004,$BA4A,$04E0,$00CA,$0005
                dc.w    $FFFF,$0006,$0000,$0000,$0004,$BD08,$04ED,$006A
                dc.w    $0005,$FFFF,$0006,$0000,$0000,$0004,$BD08,$0543
                dc.w    $00C6,$00DF,$FFFF,$FFFA,$0000,$0000,$0004,$BD08
                dc.w    $0554,$0170,$002D,$0002,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$0556,$0131,$00DF,$FFFF,$FFFA,$0000,$0000
                dc.w    $0004,$BD08,$0558,$0120,$00DF,$0000,$FFFF,$0000
                dc.w    $0000,$0004,$BDC2,$055F,$0170,$003B,$FFFA,$0000
                dc.w    $0000,$0000,$0004,$BD08,$0561,$0170,$006B,$FFFA
                dc.w    $0000,$0000,$0000,$0004,$BD08,$0578,$0170,$009B
                dc.w    $FFFA,$0000,$0000,$0000,$0004,$BD08,$059B,$0118
                dc.w    $0002,$FFFE,$0000,$0000,$0000,$0004,$B95C,$05AC
                dc.w    $00A0,$0002,$0002,$0000,$0000,$0000,$0004,$B95C
                dc.w    $05BA,$0170,$0073,$0003,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$05BB,$0000,$0000,$FFFF,$0006,$0004,$BA28
                dc.w    $0004,$BA4A,$05D1,$0068,$00DF,$0001,$0000,$0004
                dc.w    $BCDE,$0004,$BD08,$0614,$0005,$0080,$0000,$0000
                dc.w    $0004,$BCC2,$0004,$BD08,$062C,$0108,$0004,$0000
                dc.w    $0000,$0004,$BCB4,$0004,$BD08,$066B,$0170,$006D
                dc.w    $FFFA,$0000,$0000,$0000,$0004,$BD08,$0670,$0170
                dc.w    $004A,$FFFA,$0000,$0000,$0000,$0004,$BD08,$0673
                dc.w    $0170,$009C,$FFFA,$0000,$0000,$0000,$0004,$BD08
                dc.w    $067A,$0170,$007B,$FFFA,$0000,$0000,$0000,$0004
                dc.w    $BD08,$067B,$0010,$007B,$0006,$0000,$0000,$0000
                dc.w    $0004,$BD08,$0684,$0170,$002B,$FFFA,$0000,$0000
                dc.w    $0000,$0004,$BD08,$06BE,$0170,$0098,$0001,$FFFC
                dc.w    $0000,$0000,$FFFF,$FFFF,$0740,$0000,$0000,$FFFF
                dc.w    $0005,$0004,$BA36,$0004,$BA4A,$076F,$00BA,$0005
                dc.w    $0002,$FFFF,$0000,$0000,$0004,$BDC2,$07D0,$0170
                dc.w    $0060,$0003,$FFFC,$0000,$0000,$FFFF,$FFFF,$07D1
                dc.w    $0170,$00B0,$0000,$FFFC,$0000,$0000,$FFFF,$FFFF
                dc.w    $07D2,$0110,$00DF,$0000,$FFFF,$0000,$0000,$0004
                dc.w    $BDC2,$07D3,$0170,$0021,$0005,$FFFC,$0000,$0000
                dc.w    $FFFF,$FFFF,$07E4,$0098,$00DF,$0000,$FFFF,$0000
                dc.w    $0000,$0004,$BDC2,$07E5,$0011,$0060,$0001,$FFFF
                dc.w    $0000,$0000,$0004,$BDC2,$07E6,$0011,$008D,$0001
                dc.w    $FFFF,$0000,$0000,$0004,$BDC2,$07E7,$0011,$00B0
                dc.w    $0001,$FFFF,$0000,$0000,$0004,$BDC2,$07E9,$0011
                dc.w    $0032,$0001,$FFFF,$0000,$0000,$0004,$BDC2,$0828
                dc.w    $0011,$0060,$0001,$FFFF,$0000,$0000,$0004,$BDC2
                dc.w    $082A,$0098,$0005,$0002,$FFFF,$0000,$0000,$0004
                dc.w    $BDC2,$082B,$011C,$0005,$0002,$FFFF,$0000,$0000
                dc.w    $0004,$BDC2,$0852,$0000,$0000,$FFFF,$001E,$0004
                dc.w    $BA40,$0004,$BA4A,$08DC,$0170,$003C,$0000,$0000
                dc.w    $0004,$BCEC,$0004,$BD08,$0911,$0170,$004B,$FFFA
                dc.w    $0000,$0000,$0000,$0004,$BD08,$091B,$0010,$004B
                dc.w    $0000,$0000,$0004,$BCFA,$0004,$BD08,$7530
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
Spawn_4AA24:
                movea.l $6(a1),a3
L_4AA28:
                move.w  (a3)+,d1
                bmi.b   L_4AA48
                move.w  #$170,d0
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  (a3)+,$32(a0)
                move.b  (a3)+,$1F(a0)
                clr.w   $34(a0)
                jsr     (jt_ObjInsert).w
                bra.b   L_4AA28
L_4AA48:
                rts
Upd_4AA4A:
                tst.b   $32(a0)
                beq.b   L_4AA56
                subq.b  #$1,$32(a0)
                rts
L_4AA56:
                lea.l   ($6C818).l,a1
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d1
                ext.w   d1
                add.w   d1,$C(a0)
                addq.w  #$1,d0
                cmp.w   #$23,d0
                bcs.b   L_4AA74
                clr.w   d0
L_4AA74:
                move.w  d0,$34(a0)
                subq.w  #$4,$A(a0)
                cmpi.w  #$20,$A(a0)
                bhi.b   L_4AA88
                jmp     (jt_ObjKillSelf).w
L_4AA88:
                rts
Spawn_4AA8A:
                move.w  $A(a1),d7
                clr.w   d6
L_4AA90:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.l  $6(a1),$32(a0)
                clr.w   $36(a0)
                move.w  $C(a1),$3A(a0)
                move.b  d6,$38(a0)
                jsr     (jt_ObjInsert).w
                addq.b  #$7,d6
                dbra    d7,L_4AA90
                rts
Upd_4AAC2:
                move.w  $3A(a0),d0
                add.w   d0,$A(a0)
                tst.b   $38(a0)
                beq.b   L_4AAD6
                subq.b  #$1,$38(a0)
                rts
L_4AAD6:
                movea.l $32(a0),a1
                move.w  $36(a0),d0
                move.w  (a1)+,d1
                bsr.b   L_4AB08
                add.w   d2,$A(a0)
                bsr.b   L_4AB08
                add.w   d2,$C(a0)
                bsr.b   L_4AB08
                move.b  d2,$1F(a0)
                cmp.w   d1,d0
                bcc.b   L_4AAFA
                addq.w  #$1,$36(a0)
L_4AAFA:
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4AB06
                jmp     (jt_ObjKillSelf).w
L_4AB06:
                rts
L_4AB08:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
Spawn_4AB12:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a2),$38(a0)
                move.w  $8(a2),$3A(a0)
                bsr.w   L_4AC5A
                move.b  #$1,$4(a0)
                jmp     (jt_ObjInsert).w
Upd_4AB3C:
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4AB48
                jmp     (jt_ObjKillSelf).w
L_4AB48:
                tst.b   $36(a0)
                beq.b   L_4AB66
                cmpi.b  #$1,$36(a0)
                beq.b   L_4AB94
                subq.w  #$1,$A(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4ABCA
                bsr.w   L_4ABE8
                rts
L_4AB66:
                bsr.w   L_4AC5A
                movem.w $A(a0),d0-d1
                add.w   #$B,d1
                tst.w   $32(a0)
                bpl.b   L_4AB80
                sub.w   #$10,d0
                bra.b   L_4AB84
L_4AB80:
                add.w   #$21,d0
L_4AB84:
                jsr     (jt_GetMapCell).w
                bne.b   L_4ABD0
                move.w  $32(a0),d0
                add.w   d0,$A(a0)
                rts
L_4AB94:
                subq.w  #$1,$A(a0)
                subq.w  #$1,$34(a0)
                bmi.b   L_4ABA0
                rts
L_4ABA0:
                move.w  #$A,$34(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4ABCC
                bsr.w   L_4AC5A
                move.l  #D_4B822,d0
                sub.l   $2A(a0),d0
                move.w  d0,$1E(a0)
                move.b  #$2,$36(a0)
                move.b  #$A,$37(a0)
L_4ABCA:
                rts
L_4ABCC:
                bra.w   L_4ACB8
L_4ABD0:
                move.b  #$2,$36(a0)
                move.b  #$14,$37(a0)
                clr.b   $22(a0)
                move.w  #$3,$1E(a0)
                rts
L_4ABE8:
                bsr.w   L_4AC2E
                cmp.w   #$37,d0
                blt.b   L_4AC5A
                cmp.w   #$55,d0
                bgt.b   L_4AC5A
                bsr.w   L_4AC5A
                move.b  #$1,$36(a0)
                move.b  $3B(a0),$37(a0)
                move.w  $38(a0),$34(a0)
                st.b    $22(a0)
                move.l  #D_4B81A,$2A(a0)
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                bsr.w   L_4AC2E
                move.w  d2,$3C(a0)
                rts
L_4AC2E:
                moveq   #1,d2
                move.w  (ShipPos).w,d0
                sub.w   $A(a0),d0
                bpl.b   L_4AC42
                neg.w   d0
                neg.w   d2
                add.w   #$1E,d0
L_4AC42:
                rts
L_4AC44:
                moveq   #1,d2
                move.w  ($F0).w,d0
                sub.w   #$1F,d0
                sub.w   $C(a0),d0
                bpl.b   L_4AC58
                neg.w   d0
                neg.w   d2
L_4AC58:
                rts
L_4AC5A:
                bsr.b   L_4AC2E
                cmp.w   #$3C,d0
                blt.b   L_4AC6A
                cmp.w   #$50,d0
                bcs.w   L_4ABD0
L_4AC6A:
                clr.b   $36(a0)
                moveq   #70,d1
                sub.w   d0,d1
                bpl.b   L_4AC86
                move.w  #$FFFE,$32(a0)
                tst.w   d2
                bmi.b   L_4AC84
                move.w  #$2,$32(a0)
L_4AC84:
                bra.b   L_4AC96
L_4AC86:
                move.w  #$2,$32(a0)
                tst.w   d2
                bmi.b   L_4AC96
                move.w  #$FFFE,$32(a0)
L_4AC96:
                move.b  #$0,$36(a0)
                lea.l   (D_4B80C).l,a1
                tst.w   $32(a0)
                bmi.b   L_4ACAE
                lea.l   (D_4B813).l,a1
L_4ACAE:
                move.l  a1,$2A(a0)
                st.b    $22(a0)
                rts
L_4ACB8:
                movea.l a0,a4
                movem.w $A(a0),d0-d1
                moveq   #1,d2
                subq.w  #$8,d1
                add.w   #$14,d0
                lea.l   (Def_4B8A0).l,a2
                jsr     (jt_ObjCreate).w
                bsr.w   L_4AC44
                lsr.w   #$3,d0
                moveq   #16,d1
                move.w  d0,-(a7)
                moveq   #15,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   L_4ACEA
                clr.w   d1
L_4ACEA:
                move.w  d1,$32(a0)
                bsr.w   L_4AC2E
                lsr.w   #$3,d0
                moveq   #19,d1
                move.w  d0,-(a7)
                moveq   #10,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   L_4AD06
                clr.w   d1
L_4AD06:
                move.w  d1,$34(a0)
                move.w  $3C(a4),$36(a0)
                clr.b   $22(a0)
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                rts
Upd_4AD22:
                lea.l   ($6C899).l,a3
                lea.l   ($6C83B).l,a1
                lea.l   ($6C8F7).l,a2
                movem.w $32(a0),d0-d2
                move.b  (a3,d0.w),d3
                cmp.b   #$7F,d3
                beq.b   L_4ADB6
                neg.b   d3
                move.b  (a1,d1.w),d4
                bne.b   L_4AD4E
                addq.b  #$1,d4
L_4AD4E:
                cmp.b   #$7F,d4
                beq.b   L_4ADB6
                addq.w  #$1,$32(a0)
                addq.w  #$1,$34(a0)
                ext.w   d3
                ext.w   d4
                asl.w   #$1,d4
                tst.w   d2
                bpl.b   L_4AD68
                neg.w   d4
L_4AD68:
                add.w   d3,$C(a0)
                add.w   d4,$A(a0)
                cmpi.w  #$20,$A(a0)
                bcs.b   L_4AD90
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4AD94
                cmpi.w  #$E0,$C(a0)
                bhi.b   L_4AD90
                cmpi.w  #$10,$C(a0)
                bhi.b   L_4AD94
L_4AD90:
                jmp     (jt_ObjKillSelf).w
L_4AD94:
                move.b  (a2,d0.w),d3
                ext.w   d3
                tst.w   d2
                bpl.b   L_4ADA2
                add.w   #$9,d3
L_4ADA2:
                move.w  d3,$1E(a0)
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                addq.w  #$6,d1
                jsr     (jt_GetMapCell).w
                beq.b   L_4ADC0
L_4ADB6:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
L_4ADC0:
                rts
Spawn_4ADC2:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.l  #D_4B98E,$2A(a0)
                move.w  $6(a1),$32(a0)
                bpl.b   L_4ADEA
                move.l  #D_4B984,$2A(a0)
L_4ADEA:
                move.w  $32(a0),d2
                bsr.w   L_4AE9A
                move.w  #$200,$34(a0)
                clr.w   $1E(a0)
                bsr.w   L_4AF04
                jmp     (jt_ObjInsert).w
Upd_4AE04:
                cmpi.w  #$10,$A(a0)
                bcs.b   L_4AE1C
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4AE1C
                cmpi.w  #$E0,$C(a0)
                bcs.b   L_4AE20
L_4AE1C:
                jmp     (jt_ObjKillSelf).w
L_4AE20:
                move.b  $34(a0),d0
                beq.b   L_4AE6C
                cmp.b   #$1,d0
                beq.w   L_4AECE
                cmp.b   #$2,d0
                beq.w   L_4AF04
                subq.w  #$1,$A(a0)
                subq.b  #$1,$35(a0)
                bmi.b   L_4AE52
                rts
L_4AE42:
                st.b    $34(a0)
                clr.b   $22(a0)
                move.l  #D_4B984,$2A(a0)
L_4AE52:
                move.b  #$A,$35(a0)
                bsr.w   L_4AC2E
                move.w  #$B,$1E(a0)
                tst.w   d2
                bpl.b   L_4AE6A
                clr.w   $1E(a0)
L_4AE6A:
                rts
L_4AE6C:
                move.w  $32(a0),d2
                movem.w $A(a0),d0-d1
                add.w   #$C,d1
                subq.w  #$3,d0
                tst.w   d2
                bmi.b   L_4AE84
                add.w   #$23,d0
L_4AE84:
                jsr     (jt_GetMapCell).w
                bne.b   L_4AE42
                adda.l  (MapRowBytes).w,a4
                btst.b  #$7,(a4)
                beq.b   L_4AE9A
                add.w   d2,$A(a0)
                rts
L_4AE9A:
                move.b  #$1,$34(a0)
                clr.w   $36(a0)
                move.w  #$23,$38(a0)
                move.l  #D_4B993,$2A(a0)
                tst.w   d2
                bpl.b   L_4AEBE
                move.l  #D_4B989,$2A(a0)
L_4AEBE:
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                st.b    $22(a0)
                rts
L_4AECE:
                lea.l   (D_4B9F8).l,a2
                move.w  $36(a0),d0
                moveq   #2,d2
                move.b  (a2,d0.w),d3
                cmp.b   #$7F,d3
                bne.b   L_4AEEC
                move.b  #$2,$34(a0)
                bra.b   L_4AF04
L_4AEEC:
                ext.w   d3
                tst.w   $32(a0)
                bpl.b   L_4AEF6
                moveq   #-3,d2
L_4AEF6:
                add.w   d2,$A(a0)
                add.w   d3,$C(a0)
                addq.w  #$1,$36(a0)
                rts
L_4AF04:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                add.w   #$1A,d1
                jsr     (jt_GetMapCell).w
                bne.b   L_4AF20
                addq.w  #$4,$C(a0)
                rts
L_4AF20:
                clr.w   $34(a0)
                move.l  #D_4B98E,$2A(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.w   $32(a0)
                bpl.b   L_4AF42
                move.l  #D_4B984,$2A(a0)
L_4AF42:
                rts
Spawn_4AF44:
                movea.l $A(a1),a3
                move.w  $8(a1),d7
                clr.w   d6
L_4AF4E:
                move.w  (a3)+,d0
                bmi.b   L_4AF72
                move.w  (a3)+,d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)
                clr.w   $38(a0)
                move.w  d6,$32(a0)
                add.w   d7,d6
                jsr     (jt_ObjInsert).w
                bra.b   L_4AF4E
L_4AF72:
                rts
Upd_4AF74:
                tst.w   $32(a0)
                beq.b   L_4AF80
                subq.w  #$1,$32(a0)
                rts
L_4AF80:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   L_4AFA2
                cmp.w   #$170,d0
                bhi.b   L_4AFA2
                cmp.w   #$2,d1
                bcs.b   L_4AFA2
                cmp.w   #$E0,d1
                bcs.b   L_4AFA6
L_4AFA2:
                jmp     (jt_ObjKillSelf).w
L_4AFA6:
                move.w  $3A(a0),d4
                cmp.w   (ScrollX).w,d4
                bhi.b   L_4AFC0
                moveq   #10,d7
                cmp.w   #$88,d1
                bcs.b   L_4AFBC
                move.w  #$E0,d7
L_4AFBC:
                moveq   #4,d6
                bra.b   L_4AFCC
L_4AFC0:
                subq.w  #$1,$38(a0)
                bpl.b   L_4B00A
                movem.w (ShipPos).w,d6-d7
L_4AFCC:
                moveq   #2,d4
                lea.l   (D_4BA72).l,a1
                cmp.w   d6,d0
                bcs.b   L_4AFE0
                moveq   #-1,d4
                lea.l   (D_4BA77).l,a1
L_4AFE0:
                move.l  a1,$2A(a0)
                moveq   #1,d5
                cmp.w   d7,d1
                bcs.b   L_4AFEC
                neg.w   d5
L_4AFEC:
                move.w  d0,d2
                sub.w   d6,d2
                bpl.b   L_4AFF4
                neg.w   d2
L_4AFF4:
                lsr.w   #$2,d2
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)
                move.b  d4,$36(a0)
                move.b  d5,$37(a0)
L_4B00A:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6
                ext.w   d6
                bpl.b   L_4B020
                subq.w  #$2,d1
                bra.b   L_4B024
L_4B020:
                add.w   #$20,d1
L_4B024:
                addq.w  #$8,d0
                jsr     (jt_GetMapCell).w
                bne.b   L_4B030
                add.w   d6,$C(a0)
L_4B030:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1
                move.b  $36(a0),d4
                ext.w   d4
                bpl.b   L_4B042
                subq.w  #$2,d0
                bra.b   L_4B046
L_4B042:
                add.w   #$22,d0
L_4B046:
                jsr     (jt_GetMapCell).w
                bne.b   L_4B050
                add.w   d4,$A(a0)
L_4B050:
                rts
; The level 4 map is stored at $50F00 (level B) and copied to $6EA6A, the
; address in LvMap, at every (re)start: the level code changes the map while
; it plays, so a clean copy is needed for restarts.
LevelInit:
                move.w  #$8BB,d0
                lea.l   ($50F00).l,a0
                lea.l   ($6EA6A).l,a1
L_4B062:
                move.w  (a0)+,(a1)+
                dbra    d0,L_4B062
                clr.b   (D_4BAAC).l
                move.b  #$3,(D_4BAAE).l
L_4B076:
                rts
LevelFrame:
                cmpi.w  #$970,(ScrollX).w
                bcs.b   L_4B076
                tst.b   (D_4BAAC).l
                bne.w   L_4B186
                clr.b   (ScrollActive).w
                movea.l (ScoreToAddEnd).w,a4
                move.w  #$F99,$1E(a4)
                move.w  #$3,$2A(a4)
                move.w  #$F55,$2E(a4)
                lea.l   (D_4BAB0).l,a4
                lea.l   (D_4BC02).l,a1
                moveq   #2,d7
                moveq   #0,d6
                move.l  #$6CFB2,d5
L_4B0BA:
                movea.l (a4)+,a2
                move.w  (a4)+,d0
                move.w  (a4)+,d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                move.w  (a4)+,d0
                move.b  d0,$4(a0)
                movea.l a0,a3
                clr.b   $22(a0)
                clr.b   $33(a0)
                clr.b   $3C(a0)
                move.b  d6,$32(a0)
                clr.w   $34(a0)
                move.l  d5,$36(a0)
                st.b    (D_4BAAD).l
                jsr     (jt_ObjInsert).w
                moveq   #1,d0
                moveq   #1,d1
                moveq   #-1,d2
                lea.l   (D_4BB64).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$11,$3C(a0)
                move.b  #$A,$4(a0)
                move.l  a3,$32(a0)
                clr.b   $22(a0)
                move.w  d6,$1E(a0)
                clr.w   $36(a0)
                jsr     (jt_ObjInsert).w
                tst.w   d6
                bne.b   L_4B126
                move.l  a3,(a1)+
L_4B126:
                move.l  a3,(a1)+
                addq.w  #$1,d6
                add.l   #$8E8,d5
                dbra    d7,L_4B0BA
                moveq   #2,d7
                moveq   #0,d6
                lea.l   (D_4BC02).l,a1
L_4B13E:
                moveq   #1,d0
                moveq   #1,d1
                moveq   #-1,d2
                lea.l   (Def_4BBAC).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$B,$4(a0)
                move.l  (a1)+,$32(a0)
                clr.b   $22(a0)
                clr.w   $1E(a0)
                clr.w   $38(a0)
                move.w  d6,$36(a0)
                beq.b   L_4B170
                bset.b  #$2,$23(a0)
L_4B170:
                jsr     (jt_ObjInsert).w
                addq.w  #$4,d6
                dbra    d7,L_4B13E
                st.b    (D_4BAAC).l
                st.b    (MusicFadeReq).w
                rts
L_4B186:
                tst.b   (D_4BAAE).l
                bne.b   L_4B192
                st.b    (LevelComplete).w
L_4B192:
                rts
Upd_4B194:
                tst.b   $3C(a0)
                beq.b   L_4B1AC
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                subq.b  #$1,(D_4BAAE).l
                rts
L_4B1AC:
                bsr.w   L_4B216
                tst.b   (D_4BAAD).l
                bpl.b   L_4B1DA
                addq.w  #$3,$A(a0)
                moveq   #0,d0
                movea.l $36(a0),a1
                move.b  (a1),d0
                add.w   #$20,d0
                cmp.w   $A(a0),d0
                bgt.b   L_4B1D8
                clr.b   (D_4BAAD).l
                subq.w  #$3,$A(a0)
L_4B1D8:
                rts
L_4B1DA:
                movea.l $36(a0),a1
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d2
                adda.l  #$474,a1
                move.b  (a1,d0.w),d3
                and.w   #$FF,d2
                and.w   #$FF,d3
                add.w   #$20,d2
                move.w  d2,$A(a0)
                move.w  d3,$C(a0)
                addq.w  #$1,$34(a0)
                cmpi.w  #$474,$34(a0)
                bcs.b   L_4B214
                clr.w   $34(a0)
L_4B214:
                rts
L_4B216:
                cmpi.b  #$2,$32(a0)
                bne.b   L_4B228
                tst.b   $33(a0)
                beq.b   L_4B22A
                subq.b  #$1,$33(a0)
L_4B228:
                rts
L_4B22A:
                movem.w $A(a0),d0-d1
                move.w  d1,d2
                cmp.w   (ShipPos).w,d0
                bhi.b   L_4B228
                add.w   #$22,d2
                sub.w   ($F0).w,d2
                bpl.b   L_4B244
                neg.w   d2
L_4B244:
                cmp.w   #$1C,d2
                bhi.b   L_4B228
                add.w   #$14,d1
                movem.l a0,-(a7)
                movem.w d0,-(a7)
                moveq   #40,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                movem.w (a7)+,d0
                add.w   #$3C,d0
                moveq   #-1,d2
                lea.l   (Def_4BC5E).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movem.l (a7)+,a0
                move.b  #$E,$33(a0)
                rts
L_4B288:
                tst.b   $3C(a0)
                bne.w   L_4B2DC
                movea.l $32(a0),a1
                movem.w $A(a1),d0-d1
                movem.w d0-d1,$A(a0)
                tst.b   $28(a1)
                bne.b   L_4B2CC
                move.w  $26(a0),d0
                cmp.w   $36(a0),d0
                beq.b   L_4B2CC
                move.w  d0,$36(a0)
                cmp.w   #$1E,d0
                bcs.b   L_4B2CE
                st.b    $3C(a1)
                st.b    $3C(a0)
                clr.w   $34(a0)
                move.w  #$3,$1E(a0)
L_4B2CC:
                rts
L_4B2CE:
                bset.b  #$0,$23(a1)
                move.b  #$3,$28(a1)
                rts
L_4B2DC:
                subq.b  #$1,$3D(a0)
                bne.b   L_4B2F6
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.l  #$5000,d0
                jsr     (jt_AddScore).w
L_4B2F6:
                move.l  a0,-(a7)
                moveq   #60,d0
                jsr     (jt_Random).w
                move.w  d0,d1
                moveq   #80,d0
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                add.w   $C(a0),d1
                moveq   #1,d2
                lea.l   (D_4BB64).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
Upd_4B332:
                movea.l $32(a0),a1
                tst.b   $3C(a1)
                beq.b   L_4B348
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                rts
L_4B348:
                lea.l   (D_4BC22).l,a2
                move.w  $36(a0),d2
                movem.w (a2,d2.w),d2-d3
                movea.l $32(a0),a1
                movem.w $A(a1),d0-d1
                add.w   d2,d0
                add.w   d3,d1
                movem.w d0-d1,$A(a0)
                move.w  d0,d5
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  d0,d6
                cmp.w   #$8,d0
                bcs.b   L_4B3AC
                subq.w  #$1,$38(a0)
                bpl.b   L_4B3AC
                subq.w  #$8,d0
                lea.l   (D_4BC3E).l,a1
                lsl.w   #$2,d0
                add.w   (a1,d0.w),d5
                add.w   $2(a1,d0.w),d1
                move.w  d5,d0
                jsr     (jt_FireEnemyBullet).w
                moveq   #70,d0
                jsr     (jt_Random).w
                add.w   #$23,d0
                move.w  d0,$38(a0)
L_4B3AC:
                lea.l   (D_4BC2E).l,a1
                move.b  (a1,d6.w),d0
                ext.w   d0
                move.w  d0,$1E(a0)
                rts
Upd_4B3BE:
                addq.w  #$6,$A(a0)
                cmpi.w  #$170,$A(a0)
                bcs.b   L_4B3CE
                jmp     (jt_ObjKillSelf).w
L_4B3CE:
                rts
Spawn_4B3D0:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                moveq   #0,d4
                move.w  $6(a1),$32(a0)
                beq.b   L_4B3F6
                bpl.b   L_4B3F4
                moveq   #12,d4
                bra.b   L_4B3F6
L_4B3F4:
                moveq   #4,d4
L_4B3F6:
                move.w  $8(a1),$34(a0)
                beq.b   L_4B406
                bpl.b   L_4B404
                moveq   #0,d4
                bra.b   L_4B406
L_4B404:
                moveq   #8,d4
L_4B406:
                move.w  d4,$1E(a0)
                clr.w   $3A(a0)
                move.l  $A(a1),$36(a0)
                jmp     (jt_ObjInsert).w
Upd_4B418:
                movem.w $A(a0),d0-d1
                add.w   #$C,d0
                add.w   #$C,d1
                cmp.w   #$20,d1
                bls.b   L_4B43C
                cmp.w   #$DF,d1
                bcc.b   L_4B43C
                jsr     (jt_GetMapCell).w
                bne.b   L_4B43C
                move.w  #$9013,(a4)
L_4B43C:
                move.l  $36(a0),d0
                bne.b   L_4B46E
                movem.w $32(a0),d2-d3
                add.w   d2,$A(a0)
                add.w   d3,$C(a0)
L_4B450:
                move.w  $A(a0),d0
                bmi.b   L_4B468
                cmp.w   #$170,d0
                bhi.b   L_4B468
                move.w  $C(a0),d0
                bmi.b   L_4B468
                cmp.w   #$E0,d0
                bcs.b   L_4B46C
L_4B468:
                jmp     (jt_ObjKillSelf).w
L_4B46C:
                rts
L_4B46E:
                tst.w   $32(a0)
                beq.b   L_4B478
                subq.w  #$1,$A(a0)
L_4B478:
                movea.l d0,a1
                move.w  $3A(a0),d0
                move.w  (a1)+,d1
                bsr.b   L_4B49C
                add.w   d2,$A(a0)
                bsr.b   L_4B49C
                add.w   d2,$C(a0)
                bsr.b   L_4B49C
                move.b  d2,$1F(a0)
                cmp.w   d1,d0
                bcc.b   L_4B450
                addq.w  #$1,$3A(a0)
                bra.b   L_4B450
L_4B49C:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
Spawn_4B4A6:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                st.b    $22(a0)
                move.w  $6(a1),d0
                lsl.w   #$2,d0
                lea.l   (D_4B4E6).l,a3
                move.l  (a3,d0.w),$34(a0)
                move.l  $10(a3,d0.w),$2A(a0)
                move.w  $8(a1),$3A(a0)
                clr.b   $3C(a0)
                move.w  #$12,$32(a0)
                jmp     (jt_ObjInsert).w
D_4B4E6:
                dc.l    L_4B588
                dc.w    $0004,$B64C,$0004,$B5CA,$0004,$B60C,$0004,$BDEA
                dc.w    $0004,$BDF3,$0004,$BDFC,$0004,$BE05
Upd_4B506:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                add.w   #$10,d0
                add.w   #$10,d1
                jsr     (jt_GetMapCell).w
                beq.b   L_4B526
                btst.b  #$4,(a4)
                beq.b   L_4B526
                clr.w   (a4)
L_4B526:
                tst.b   $3C(a0)
                beq.b   L_4B540
                subq.b  #$1,$3C(a0)
                bne.b   L_4B53E
                st.b    $22(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
L_4B53E:
                rts
L_4B540:
                move.w  $3A(a0),d0
                cmp.w   (ScrollX).w,d0
                bhi.b   L_4B550
                move.w  #$7FFF,$32(a0)
L_4B550:
                movem.w (ShipPos).w,d0-d1
                addq.w  #$5,d0
                subq.w  #$8,d1
                tst.w   $32(a0)
                beq.b   L_4B564
                subq.w  #$1,$32(a0)
L_4B564:
                movea.l $34(a0),a1
                jsr     (a1)
                move.w  $A(a0),d0
                bmi.b   L_4B582
                cmp.w   #$170,d0
                bhi.b   L_4B582
                move.w  $C(a0),d0
                bmi.b   L_4B582
                cmp.w   #$F2,d0
                bcs.b   L_4B586
L_4B582:
                jmp     (jt_ObjKillSelf).w
L_4B586:
                rts
L_4B588:
                bne.b   L_4B5C4
                cmp.w   $C(a0),d1
                bcs.b   L_4B5C4
                bsr.w   L_4B68C
                move.w  #$5,$1E(a0)
                cmp.w   $A(a0),d0
                bcs.b   L_4B5B2
                move.l  #D_4BDF3,$2A(a0)
                move.l  #D_4B64C,$34(a0)
                rts
L_4B5B2:
                move.l  #D_4BE05,$2A(a0)
                move.l  #D_4B60C,$34(a0)
                rts
L_4B5C4:
                subq.w  #$2,$C(a0)
                rts
                dc.w    $663A,$B268,$000C,$6234,$6100,$00B8,$317C,$0007
                dc.w    $001E,$B068,$000A,$6512,$217C,$0004,$BDF3,$002A
                dc.w    $217C,$0004,$B64C,$0034,$4E75,$217C,$0004,$BE05
                dc.w    $002A,$217C,$0004,$B60C,$0034,$4E75,$5468,$000C
                dc.w    $4E75
D_4B60C:
                dc.w    $6638,$B068,$000A,$6532,$6176,$317C,$0005,$001E
                dc.w    $B268,$000C,$6512,$217C,$0004,$BDFC,$002A,$217C
                dc.w    $0004,$B5CA,$0034,$4E75,$217C,$0004,$BDEA,$002A
                dc.w    $217C
                dc.l    L_4B588
                dc.w    $0034,$4E75,$5568,$000A,$4E75
D_4B64C:
                dc.w    $6638,$B068,$000A,$6232,$6136,$317C,$0007,$001E
                dc.w    $B268,$000C,$6512,$217C,$0004,$BDFC,$002A,$217C
                dc.w    $0004,$B5CA,$0034,$4E75,$217C,$0004,$BDEA,$002A
                dc.w    $217C
                dc.l    L_4B588
                dc.w    $0034,$4E75,$5468,$000A,$4E75
L_4B68C:
                move.b  #$6,$3C(a0)
                move.w  #$12,$32(a0)
                clr.b   $20(a0)
                clr.b   $22(a0)
                rts
                dc.w    $006B,$0000,$004E,$0800,$005F,$1800,$0046,$2400
                dc.w    $006B,$2A00,$FFFF,$0050,$0000,$0060,$0600,$008E
                dc.w    $1300,$005F,$1D00,$FFFF,$0041,$0000,$0055,$0A00
                dc.w    $005A,$1400,$004D,$2800,$FFFF,$0061,$0000,$003C
                dc.w    $0900,$0061,$1B00,$007D,$2700,$004A,$3300,$FFFF
; object definition: 32x19, 8 frames, gfx $55378, 1 hit point, fires every ~65 frames, score 200, update Upd_4AA4A, spawn Spawn_4AA24
Def_4B6F2:
                dc.w    $1303,$002E,$0260,$0001,$0001,$0041,$0005,$5378
                dc.w    $0000,$0130,$0004,$B71A,$0004,$B724
                dc.l    Upd_4AA4A
                dc.l    Spawn_4AA24
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0005
                dc.w    $0000,$000E,$0012,$0005,$0003,$000F,$000E,$0000
                dc.w    $0006,$0014,$0006,$0005,$0003,$000E,$000E,$0003
                dc.w    $0001,$0010,$0011,$0004,$0003,$000F,$000E,$0000
                dc.w    $0007,$0014,$0006,$0004,$0003,$000F,$000E,$0044
                dc.w    $0006,$C95D,$0006,$C9AA,$0006,$C9F7
; object definition: 32x21, 8 frames, gfx $56678, 1 hit point, fires every ~48 frames, score 200, update Upd_4AAC2, spawn Spawn_4AA8A
Def_4B772:
                dc.w    $1503,$002E
                dc.w    $02A0,$0000,$0001,$0030,$0005,$6678,$0000,$0150
                dc.w    $0004,$B79A,$0004,$B7A4
                dc.l    Upd_4AAC2
                dc.l    Spawn_4AA8A
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0003,$0011,$0011,$0002,$0002,$0011,$0012,$0001
                dc.w    $0002,$0011,$0011,$0002,$0001,$0011,$0011,$0002
                dc.w    $0001,$0011,$0012,$0003,$0001,$0010,$0011,$0002
                dc.w    $0002,$0012,$0011,$0003,$0002,$0011,$0012
; object definition: 32x26, 6 frames, gfx $57B78, 6 hit points, score 500, update Upd_4AB3C, spawn Spawn_4AB12
Def_4B7E4:
                dc.w    $1A03
                dc.w    $002E,$0340,$0002,$0006,$0000,$0005,$7B78,$0000
                dc.w    $01A0,$0004,$B80C,$0004,$B828
                dc.l    Upd_4AB3C
                dc.l    Spawn_4AB12
                dc.w    $0000,$0500
D_4B80C:
                dc.b    $00,$01,$02,$03,$04,$05,$FF
D_4B813:
                dc.b    $06,$07,$08,$09,$0A,$0B,$FF
D_4B81A:
                dc.w    $0D0E,$FF03,$0C0D,$0EFF
D_4B822:
                dc.w    $0E0D,$0C03,$FF00,$0005,$0009,$0019,$0011,$0004
                dc.w    $0009,$001A,$0010,$0005,$0006,$0019,$0013,$0003
                dc.w    $0009,$001A,$0010,$0004,$0007,$0019,$0012,$0004
                dc.w    $0007,$0018,$0012,$0004,$0007,$0018,$0012,$0004
                dc.w    $0007,$0018,$0012,$0003,$0006,$0019,$0013,$0004
                dc.w    $0008,$001B,$0012,$0003,$0007,$0019,$0012,$0004
                dc.w    $0007,$0019,$0012,$000C,$0004,$000F,$0015,$0012
                dc.w    $0002,$000D,$0018,$0012,$0002,$000D,$0018
; object definition: 16x13, 16 frames, gfx $5AC38, update Upd_4AD22
Def_4B8A0:
                dc.w    $0D02,$0030,$00D0,$0000,$0000,$0000,$0005,$AC38
                dc.w    $0000,$0068,$0004,$B8C8,$0004,$B8DC
                dc.l    Upd_4AD22
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$0607
                dc.w    $0800,$0F0E,$0D0C,$0B0A,$0908,$FF00,$0003,$0000
                dc.w    $0008,$000D,$0003,$0001,$0008,$000C,$0001,$0001
                dc.w    $000A,$000B,$0001,$0002,$000B,$0008,$0000,$0003
                dc.w    $000D,$0007,$0000,$0003,$000C,$0008,$0001,$0001
                dc.w    $000A,$000A,$0002,$0000,$0008,$000B,$0003,$0000
                dc.w    $0007,$000C,$0002,$0000,$0009,$000B,$0001,$0001
                dc.w    $000B,$000B,$0000,$0003,$000D,$0008,$0000,$0003
                dc.w    $000D,$0007,$0001,$0003,$000E,$0008,$0001,$0002
                dc.w    $000B,$000A,$0002,$0001,$0009,$000C
; object definition: 32x26, 4 frames, gfx $5B938, 1 hit point, fires every ~30 frames, score 200, update Upd_4AE04, spawn Spawn_4ADC2
Def_4B95C:
                dc.w    $1A03,$002E
                dc.w    $0340,$0003,$0001,$001E,$0005,$B938,$0000,$01A0
                dc.w    $0004,$B984,$0004,$B998
                dc.l    Upd_4AE04
                dc.l    Spawn_4ADC2
                dc.w    $0000,$0200
D_4B984:
                dc.b    $00,$01,$02,$03,$FF
D_4B989:
                dc.b    $04,$05,$FF,$03,$FF
D_4B98E:
                dc.b    $06,$07,$08,$09,$FF
D_4B993:
                dc.b    $0A,$0B,$FF,$09,$FF,$00,$03,$00,$01,$00,$15,$00,$19,$00,$02,$00
                dc.b    $03,$00,$18,$00,$16,$00,$04,$00,$01,$00,$15,$00,$19,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$02,$00,$02,$00,$18,$00,$17,$00,$02,$00
                dc.b    $02,$00,$18,$00,$16,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$14,$00,$04,$00,$02,$00,$18,$00,$16,$00,$04,$00
                dc.b    $03,$00,$18,$00,$15
D_4B9F8:
                dc.w    $FEFE,$FEFF,$FFFF,$FF00,$0000,$0101,$0101,$0202
                dc.w    $027F,$7F00,$0170,$0062,$0170,$00B8,$FFFF,$0170
                dc.w    $009B,$FFFF,$0011,$009B,$FFFF,$0170,$0050,$FFFF
                dc.w    $0011,$0053,$0064,$0004,$0136,$0004,$FFFF,$0170
                dc.w    $0070,$014A,$0010,$FFFF,$0064,$0010,$0069,$0010
                dc.w    $FFFF
; object definition: 32x26, 6 frames, gfx $5E038, 1 hit point, fires every ~40 frames, score 300, update Upd_4AF74, spawn Spawn_4AF44
Def_4BA4A:
                dc.w    $1A03,$002E,$0340,$0005,$0001,$0028,$0005
                dc.w    $E038,$0000,$01A0,$0004,$BA72,$0004,$BA7C
                dc.l    Upd_4AF74
                dc.l    Spawn_4AF44
                dc.w    $0000,$0300
D_4BA72:
                dc.b    $03,$04,$05,$04,$FF
D_4BA77:
                dc.b    $00,$01,$02,$01,$FF,$00,$04,$00,$02,$00,$18,$00,$16,$00,$02,$00
                dc.b    $03,$00,$1B,$00,$14,$00,$04,$00,$04,$00,$18,$00,$13,$00,$05,$00
                dc.b    $04,$00,$18,$00,$14,$00,$04,$00,$03,$00,$19,$00,$15,$00,$05,$00
                dc.b    $03,$00,$18,$00,$15
D_4BAAC:
                dc.b    $00
D_4BAAD:
                dc.b    $00
D_4BAAE:
                dc.w    $0000
D_4BAB0:
                dc.w    $0004,$BACE,$FFE5,$006B,$0006,$0004,$BAF6,$FFC5
                dc.w    $0044,$0005,$0004,$BB1E,$0000,$0041,$0007
; object definition: 96x81, 1 frame, gfx $665B8, update Upd_4B194
Def_4BACE:
                dc.w    $5107
                dc.w    $0026,$1E60,$0000,$0000,$0000,$0006,$65B8,$0000
                dc.w    $0F30,$0004,$BB46,$0004,$BB4C
                dc.l    Upd_4B194
                dc.w    $0000,$0000,$0000,$0000
; object definition: 112x58, 1 frame, gfx $68418, update Upd_4B194
Def_4BAF6:
                dc.w    $3A08,$0024,$1960,$0000
                dc.w    $0000,$0000,$0006,$8418,$0000,$0CB0,$0004,$BB46
                dc.w    $0004,$BB54
                dc.l    Upd_4B194
                dc.w    $0000,$0000,$0000,$0000
; object definition: 96x68, 1 frame, gfx $69D78, update Upd_4B194
Def_4BB1E:
                dc.w    $4407,$0026,$1980,$0000
                dc.w    $0000,$0000,$0006,$9D78,$0000,$0CC0,$0004,$BB46
                dc.w    $0004,$BB5C
                dc.l    Upd_4B194
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$FF00,$0008
                dc.w    $001B,$004D,$0032,$0005,$0002,$0064,$002E,$000D
                dc.w    $0004,$0049,$003D
D_4BB64:
                dc.w    $0041,$0032,$0000,$0000,$0000,$0000,$0004,$BC12
                dc.w    $0000,$0000,$0004,$BB46,$0004,$BB8C
                dc.l    L_4B288
                dc.w    $0000,$0000,$0000,$0000,$0030,$000D,$0022,$000E
                dc.w    $0027,$002E,$001D,$000C,$0001,$000E,$000C,$001F
                dc.w    $01A4,$000A,$0002,$0002
; object definition: 32x25, 5 frames, gfx $6B6F8, update Upd_4B332
Def_4BBAC:
                dc.w    $1903,$002E,$0320,$0000,$0000,$0000,$0006,$B6F8
                dc.w    $0000,$0190,$0004,$BBD4,$0004,$BBDA
                dc.l    Upd_4B332
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$04FF,$0004
                dc.w    $FFE6,$001E,$0032,$0004,$FFE6,$001E,$0032,$0004
                dc.w    $FFE6,$001E,$0032,$0004,$FFE6,$001E,$0032,$0004
                dc.w    $FFE6,$001E,$0032
D_4BC02:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
D_4BC22:
                dc.w    $0003,$0022,$000B,$003A,$FFFC,$0010
D_4BC2E:
                dc.w    $0000,$0101,$0202,$0304,$0403,$0302,$0201,$0100
D_4BC3E:
                dc.w    $FFFE,$0012,$FFF9,$000E,$FFF9,$000E,$FFF6,$0006
                dc.w    $FFF6,$0006,$FFF9,$FFFD,$FFF9,$FFFD,$FFFD,$FFF8
; object definition: 32x3, 4 frames, gfx $6C698, update Upd_4B3BE
Def_4BC5E:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0006,$C698
                dc.w    $0000,$0030,$0004,$BB46,$0004,$BC86
                dc.l    Upd_4B3BE
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$004B,$0006,$CA3C,$0006
                dc.w    $CA88,$0006,$CAD4,$004C,$0006,$CB20,$0006,$CB6D
                dc.w    $0006,$CBBA,$004F,$0006,$CC07,$0006,$CC57,$0006
                dc.w    $CCA7,$002E,$0006,$CCF7,$0006,$CD26,$0006,$CD55
                dc.w    $0054,$0006,$CD84,$0006,$CDD9,$0006,$CE2E,$0031
                dc.w    $0006,$CE83,$0006,$CEB5,$0006,$CEE7,$0032,$0006
                dc.w    $CF19,$0006,$CF4C,$0006,$CF7F
; object definition: 32x25, 16 frames, gfx $5F3B8, 3 hit points, score 400, update Upd_4B418, spawn Spawn_4B3D0
Def_4BD08:
                dc.w    $1903,$002E,$0320
                dc.w    $0000,$0003,$0000,$0005,$F3B8,$0000,$0190,$0004
                dc.w    $BD30,$0004,$BD42
                dc.l    Upd_4B418
                dc.l    Spawn_4B3D0
                dc.w    $0000,$0400,$0001,$0203,$0405,$0607,$0809,$0A0B
                dc.w    $0C0D,$0E0F,$FF00,$0007,$0005,$0010,$000E,$0007
                dc.w    $0004,$0010,$000E,$0007,$0004,$000F,$0010,$0006
                dc.w    $0003,$000F,$0012,$0008,$0005,$000E,$0010,$0008
                dc.w    $0004,$000D,$0012,$0007,$0004,$000F,$0010,$0006
                dc.w    $0005,$0011,$000F,$0006,$0006,$0010,$000E,$0007
                dc.w    $0006,$0010,$000D,$0007,$0006,$000E,$000E,$0008
                dc.w    $0004,$000D,$0011,$0008,$0004,$000D,$0010,$0007
                dc.w    $0005,$000E,$000D,$0007,$0005,$000E,$000E,$0007
                dc.w    $0005,$0011,$000E
; object definition: 32x32, 3 frames, gfx $625B8, 1 hit point, score 200, update Upd_4B506, spawn Spawn_4B4A6
Def_4BDC2:
                dc.w    $2003,$002E,$0400,$0002,$0001
                dc.w    $0000,$0006,$25B8,$0000,$0200,$0004,$BDEA,$0004
                dc.w    $BE0E
                dc.l    Upd_4B506
                dc.l    Spawn_4B4A6
                dc.b    $00,$00,$02,$00,$00,$01,$00,$02,$FF,$0F,$FF,$03,$FF
D_4BDF3:
                dc.b    $04,$05,$04,$06,$FF,$03,$FF,$07,$FF,$08,$09,$08,$0A,$FF,$0B,$FF
                dc.b    $07,$FF
D_4BE05:
                dc.b    $0C,$0D,$0C,$0E,$FF,$0F,$FF,$0B,$FF,$00,$04,$00,$07,$00,$15,$00
                dc.b    $15,$00,$05,$00,$06,$00,$14,$00,$17,$00,$05,$00,$08,$00,$14,$00
                dc.b    $15,$00,$08,$00,$06,$00,$0E,$00,$15,$00,$03,$00,$07,$00,$15,$00
                dc.b    $14,$00,$03,$00,$07,$00,$15,$00,$14,$00,$02,$00,$08,$00,$14,$00
                dc.b    $13,$00,$06,$00,$06,$00,$13,$00,$14,$00,$04,$00,$07,$00,$15,$00
                dc.b    $15,$00,$05,$00,$05,$00,$13,$00,$17,$00,$04,$00,$06,$00,$15,$00
                dc.b    $15,$00,$0B,$00,$02,$00,$10,$00,$1A,$00,$04,$00,$08,$00,$15,$00
                dc.b    $15,$00,$05,$00,$07,$00,$15,$00,$15,$00,$05,$00,$08,$00,$15,$00
                dc.b    $15,$00,$09,$00,$05,$00,$12,$00,$17,$00,$00,$00,$00,$00,$00,$00
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
                dc.b    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
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
