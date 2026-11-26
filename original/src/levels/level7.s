;==============================================================================
; R-Type (Amiga) - level 7 code and data (level part A)
; Tracks 137.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level7_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level7_a.bin src/levels/level7.s
;
; TEXT $4A300-$4B799: level table, wave list, palette, scroll script, code
; DATA $4B79A-$4C191: object definitions, animations, tables
; $4C192 on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; First pass: code and data separated, entry points from the level table
; named.  L_xxxxx = code, D_xxxxx = data, still to be named.
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$149A,$0000,$09F8,$0000,$0000,$0000
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
                dc.l    $57300
                dc.l    D_4D300
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $582A4
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
WaveList:
                dc.w    $046C,$0004,$A76A,$0000,$0004,$A344
D_4A344:
                dc.w    $003C,$0000,$0000,$0004,$B79A,$0000,$0000,$0004
                dc.w    $B884,$003E,$0170,$0064,$0003,$FFFC,$0000,$0000
                dc.w    $FFFF,$FFFF,$0069,$0000,$0000,$0004,$B79A,$0000
                dc.w    $0000,$0004,$B884,$008C,$0000,$0000,$0004,$B7A8
                dc.w    $0000,$0000,$0004,$B884,$00BE,$0170,$00B6,$0009
                dc.w    $0007,$0000,$0000,$0004,$B968,$00D2,$0000,$0000
                dc.w    $0004,$B7A8,$0000,$0000,$0004,$B884,$00F5,$00E9
                dc.w    $0010,$0036,$0000,$0000,$0000,$0004,$BE14,$00FA
                dc.w    $0000,$0000,$0BB8,$000B,$0004,$B83A,$0004,$BC10
                dc.w    $010E,$0170,$00B6,$0009,$0007,$0000,$0000,$0004
                dc.w    $B968,$0122,$0170,$0067,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$BB60,$0131,$0170,$00A6,$FFFE,$0000,$0000
                dc.w    $0000,$0004,$BB60,$013D,$0102,$00B4,$0D7E,$0001
                dc.w    $0001,$0000,$0004,$BE14,$0140,$0170,$005A,$0004
                dc.w    $FFFC,$0000,$0000,$FFFF,$FFFF,$0168,$00D2,$0010
                dc.w    $0042,$0000,$0000,$0000,$0004,$BE14,$0172,$012C
                dc.w    $00B4,$0D8A,$0001,$0001,$0000,$0004,$BE14,$017C
                dc.w    $011D,$000B,$0004,$B802,$0009,$FFFF,$0004,$B8F6
                dc.w    $019A,$0170,$0096,$0000,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$01A4,$015E,$0092,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$BFA8,$01A9,$0000,$0000,$0BB8,$000B,$0004
                dc.w    $B848,$0004,$BC10,$01B3,$015E,$0092,$0002,$0000
                dc.w    $0000,$0000,$0004,$BFA8,$01C5,$0170,$00B6,$0009
                dc.w    $0007,$0000,$0000,$0004,$B968,$01CC,$015E,$0064
                dc.w    $0002,$0000,$0000,$0000,$0004,$BFA8,$01D1,$015E
                dc.w    $0063,$FFFE,$0000,$0000,$0000,$0004,$BB60,$01FE
                dc.w    $0000,$0000,$0BB8,$000B,$0004,$B84E,$0004,$BC10
                dc.w    $0203,$00FF,$001E,$0058,$0002,$0000,$0000,$0004
                dc.w    $BE14,$0213,$015E,$0087,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$BB60,$022B,$0010,$0055,$0000,$0004,$0000
                dc.w    $0000,$FFFF,$FFFF,$0231,$0106,$00B4,$0B32,$0003
                dc.w    $0001,$0000,$0004,$BE14,$0244,$015E,$0040,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$BB60,$0258,$00DC,$001E
                dc.w    $0060,$0004,$0000,$0000,$0004,$BE14,$028E,$015E
                dc.w    $0078,$0002,$0000,$0000,$0000,$0004,$BFA8,$028F
                dc.w    $00D8,$00B4,$0B3A,$0005,$0001,$0000,$0004,$BE14
                dc.w    $0294,$00F0,$0014,$006A,$0000,$0000,$0000,$0004
                dc.w    $BE14,$02A8,$0122,$0014,$0070,$0002,$0000,$0000
                dc.w    $0004,$BE14,$02B1,$015E,$0078,$0002,$0000,$0000
                dc.w    $0000,$0004,$BFA8,$02C6,$011E,$00B4,$0DB2,$0001
                dc.w    $0001,$0000,$0004,$BE14,$02BC,$0000,$0070,$0000
                dc.w    $0000,$0000,$0000,$0004,$BFDA,$02C6,$0170,$00A6
                dc.w    $FFFE,$0000,$0000,$0000,$0004,$BB60,$02D0,$0170
                dc.w    $0067,$FFFE,$0000,$0000,$0000,$0004,$BB60,$02E6
                dc.w    $010C,$0014,$0078,$0004,$0000,$0000,$0004,$BE14
                dc.w    $0301,$015E,$00A6,$FFFE,$0000,$0000,$0000,$0004
                dc.w    $BB60,$0302,$015E,$0067,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$BB60,$0303,$015E,$0028,$FFFE,$0000,$0000
                dc.w    $0000,$0004,$BB60,$0320,$015E,$0028,$FFFE,$0000
                dc.w    $0000,$0000,$0004,$BB60,$034E,$00F4,$0014,$0082
                dc.w    $0000,$0000,$0000,$0004,$BE14,$035C,$015E,$005A
                dc.w    $0001,$FFFC,$0000,$0000,$FFFF,$FFFF,$0361,$0000
                dc.w    $0000,$0BB8,$000B,$0004,$B858,$0004,$BC10,$0370
                dc.w    $00FD,$00B4,$0DC4,$0001,$0001,$0000,$0004,$BE14
                dc.w    $0375,$0163,$0078,$0000,$0000,$0000,$0000,$0004
                dc.w    $C058,$0398,$015E,$0067,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$BB60,$03AF,$010E,$00B4,$0B62,$0003,$0001
                dc.w    $0000,$0004,$BE14,$03CA,$00E8,$0014,$008E,$0002
                dc.w    $0000,$0000,$0004,$BE14,$03F2,$0028,$006B,$0002
                dc.w    $0000,$0000,$0000,$0004,$BB60,$03F7,$00F0,$0014
                dc.w    $0096,$0004,$0000,$0000,$0004,$BE14,$0410,$0000
                dc.w    $0000,$0BB8,$000B,$0004,$B85E,$0004,$BC10,$043A
                dc.w    $00AC,$00B4,$0B6A,$0005,$0001,$0000,$0004,$BE14
                dc.w    $0451,$0000,$0000,$0BB8,$000B,$0004,$B870,$0004
                dc.w    $BC10,$0456,$00DC,$0014,$00A0,$0000,$0000,$0000
                dc.w    $0004,$BE14,$0474,$0118,$0014,$00AC,$0000,$0000
                dc.w    $0000,$0004,$BE14,$04A8,$0028,$006B,$0002,$0000
                dc.w    $0000,$0000,$0004,$BB60,$04AA,$015E,$00B8,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$BB60,$04BE,$015E,$00B8
                dc.w    $FFFE,$0000,$0000,$0000,$0004,$BB60,$04D2,$015E
                dc.w    $00B8,$FFFE,$0000,$0000,$0000,$0004,$BB60,$04E6
                dc.w    $015E,$00B8,$FFFE,$0000,$0000,$0000,$0004,$BB60
                dc.w    $04FA,$015E,$00B8,$FFFE,$0000,$0000,$0000,$0004
                dc.w    $BB60,$0500,$0000,$0000,$0BB8,$0041,$0004,$B87A
                dc.w    $0004,$BC10,$050E,$015E,$00B8,$FFFE,$0000,$0000
                dc.w    $0000,$0004,$BB60,$0559,$00E6,$00B4,$0DFE,$0001
                dc.w    $0001,$0000,$0004,$BE14,$055F,$011D,$000B,$0004
                dc.w    $B810,$000A,$FFFF,$0004,$B8F6,$0581,$0109,$000B
                dc.w    $0004,$B81E,$0012,$FFFF,$0004,$B8F6,$0607,$00DC
                dc.w    $0014,$00D6,$0000,$0000,$0000,$0004,$BE14,$0640
                dc.w    $0163,$00B6,$000F,$0004,$0000,$0000,$0004,$B968
                dc.w    $0668,$0023,$00B8,$0004,$B82C,$000B,$FFFF,$0004
                dc.w    $B8F6,$0672,$0000,$0000,$0004,$B7C8,$0000,$0000
                dc.w    $0004,$B884,$06C2,$0000,$0000,$0004,$B7DA,$0000
                dc.w    $0000,$0004,$B884,$06C4,$0163,$00B6,$000F,$0005
                dc.w    $0000,$0000,$0004,$B968,$06C7,$0170,$005A,$0005
                dc.w    $FFFC,$0000,$0000,$FFFF,$FFFF,$06F9,$0073,$0014
                dc.w    $00E8,$0000,$0000,$0000,$0004,$BE14,$0703,$007F
                dc.w    $00B4,$0E26,$0001,$0001,$0000,$0004,$BE14,$0726
                dc.w    $0000,$0000,$0004,$B7DA,$0000,$0000,$0004,$B884
                dc.w    $0771,$0000,$0000,$0004,$B7EC,$0000,$0000,$0004
                dc.w    $B884,$07D0,$0170,$0084,$0000,$0000,$0000,$0000
                dc.w    $0004,$BAE0,$7530
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00C0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
L_4A928:
                movea.l $6(a1),a3
L_4A92C:
                move.w  (a3)+,d1
                bmi.b   L_4A94C
                move.w  #$170,d0
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  (a3)+,$32(a0)
                move.b  (a3)+,$1F(a0)
                clr.w   $34(a0)
                jsr     (jt_ObjInsert).w
                bra.b   L_4A92C
L_4A94C:
                rts
L_4A94E:
                tst.b   $32(a0)
                beq.b   L_4A95A
                subq.b  #$1,$32(a0)
                rts
L_4A95A:
                lea.l   ($70A06).l,a1
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d1
                ext.w   d1
                add.w   d1,$C(a0)
                addq.w  #$1,d0
                cmp.w   #$23,d0
                bcs.b   L_4A978
                clr.w   d0
L_4A978:
                move.w  d0,$34(a0)
                subq.w  #$4,$A(a0)
                cmpi.w  #$20,$A(a0)
                bhi.b   L_4A98C
                jmp     (jt_ObjKillSelf).w
L_4A98C:
                rts
L_4A98E:
                moveq   #7,d5
                move.w  $A(a1),d7
                cmp.w   #$9,d7
                bls.b   L_4A99C
                moveq   #10,d5
L_4A99C:
                clr.w   d6
L_4A99E:
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
                add.w   d5,d6
                dbra    d7,L_4A99E
                rts
L_4A9D0:
                move.w  $3A(a0),d0
                add.w   d0,$A(a0)
                tst.b   $38(a0)
                beq.b   L_4A9E4
                subq.b  #$1,$38(a0)
                rts
L_4A9E4:
                movea.l $32(a0),a1
                move.w  $36(a0),d0
                move.w  (a1)+,d1
                bsr.b   L_4AA1E
                add.w   d2,$A(a0)
                bsr.b   L_4AA1E
                add.w   d2,$C(a0)
                bsr.b   L_4AA1E
                move.b  d2,$1F(a0)
                cmp.w   d1,d0
                bcc.b   L_4AA08
                addq.w  #$1,$36(a0)
L_4AA08:
                cmpi.w  #$15E,$A(a0)
                bhi.b   L_4AA18
                cmpi.w  #$2,$A(a0)
                bcc.b   L_4AA1C
L_4AA18:
                jmp     (jt_ObjKillSelf).w
L_4AA1C:
                rts
L_4AA1E:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
L_4AA28:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a2),$38(a0)
                move.w  $8(a2),$3A(a0)
                bsr.w   L_4AB70
                move.b  #$1,$4(a0)
                jmp     (jt_ObjInsert).w
L_4AA52:
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4AA5E
                jmp     (jt_ObjKillSelf).w
L_4AA5E:
                tst.b   $36(a0)
                beq.b   L_4AA7C
                cmpi.b  #$1,$36(a0)
                beq.b   L_4AAAA
                subq.w  #$1,$A(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4AAE0
                bsr.w   L_4AAFE
                rts
L_4AA7C:
                bsr.w   L_4AB70
                movem.w $A(a0),d0-d1
                add.w   #$B,d1
                tst.w   $32(a0)
                bpl.b   L_4AA96
                sub.w   #$10,d0
                bra.b   L_4AA9A
L_4AA96:
                add.w   #$21,d0
L_4AA9A:
                jsr     (jt_GetMapCell).w
                bne.b   L_4AAE6
                move.w  $32(a0),d0
                add.w   d0,$A(a0)
                rts
L_4AAAA:
                subq.w  #$1,$A(a0)
                subq.w  #$1,$34(a0)
                bmi.b   L_4AAB6
                rts
L_4AAB6:
                move.w  #$A,$34(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4AAE2
                bsr.w   L_4AB70
                move.l  #D_4B9A6,d0
                sub.l   $2A(a0),d0
                move.w  d0,$1E(a0)
                move.b  #$2,$36(a0)
                move.b  #$A,$37(a0)
L_4AAE0:
                rts
L_4AAE2:
                bra.w   L_4ABCE
L_4AAE6:
                move.b  #$2,$36(a0)
                move.b  #$14,$37(a0)
                clr.b   $22(a0)
                move.w  #$3,$1E(a0)
                rts
L_4AAFE:
                bsr.w   L_4AB44
                cmp.w   #$37,d0
                blt.b   L_4AB70
                cmp.w   #$55,d0
                bgt.b   L_4AB70
                bsr.w   L_4AB70
                move.b  #$1,$36(a0)
                move.b  $3B(a0),$37(a0)
                move.w  $38(a0),$34(a0)
                st.b    $22(a0)
                move.l  #D_4B99E,$2A(a0)
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                bsr.w   L_4AB44
                move.w  d2,$3C(a0)
                rts
L_4AB44:
                moveq   #1,d2
                move.w  (ShipPos).w,d0
                sub.w   $A(a0),d0
                bpl.b   L_4AB58
                neg.w   d0
                neg.w   d2
                add.w   #$1E,d0
L_4AB58:
                rts
L_4AB5A:
                moveq   #1,d2
                move.w  ($F0).w,d0
                sub.w   #$1F,d0
                sub.w   $C(a0),d0
                bpl.b   L_4AB6E
                neg.w   d0
                neg.w   d2
L_4AB6E:
                rts
L_4AB70:
                bsr.b   L_4AB44
                cmp.w   #$3C,d0
                blt.b   L_4AB80
                cmp.w   #$50,d0
                bcs.w   L_4AAE6
L_4AB80:
                clr.b   $36(a0)
                moveq   #70,d1
                sub.w   d0,d1
                bpl.b   L_4AB9C
                move.w  #$FFFE,$32(a0)
                tst.w   d2
                bmi.b   L_4AB9A
                move.w  #$2,$32(a0)
L_4AB9A:
                bra.b   L_4ABAC
L_4AB9C:
                move.w  #$2,$32(a0)
                tst.w   d2
                bmi.b   L_4ABAC
                move.w  #$FFFE,$32(a0)
L_4ABAC:
                move.b  #$0,$36(a0)
                lea.l   (D_4B990).l,a1
                tst.w   $32(a0)
                bmi.b   L_4ABC4
                lea.l   (D_4B997).l,a1
L_4ABC4:
                move.l  a1,$2A(a0)
                st.b    $22(a0)
                rts
L_4ABCE:
                movea.l a0,a4
                movem.w $A(a0),d0-d1
                moveq   #1,d2
                subq.w  #$8,d1
                add.w   #$14,d0
                lea.l   (D_4BA24).l,a2
                jsr     (jt_ObjCreate).w
                bsr.w   L_4AB5A
                lsr.w   #$3,d0
                moveq   #16,d1
                move.w  d0,-(a7)
                moveq   #15,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   L_4AC00
                clr.w   d1
L_4AC00:
                move.w  d1,$32(a0)
                bsr.w   L_4AB44
                lsr.w   #$3,d0
                moveq   #19,d1
                move.w  d0,-(a7)
                moveq   #10,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   L_4AC1C
                clr.w   d1
L_4AC1C:
                move.w  d1,$34(a0)
                move.w  $3C(a4),$36(a0)
                clr.b   $22(a0)
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                rts
L_4AC38:
                lea.l   ($70A87).l,a3
                lea.l   ($70A29).l,a1
                lea.l   ($70AE5).l,a2
                movem.w $32(a0),d0-d2
                move.b  (a3,d0.w),d3
                cmp.b   #$7F,d3
                beq.b   L_4ACCC
                neg.b   d3
                move.b  (a1,d1.w),d4
                bne.b   L_4AC64
                addq.b  #$1,d4
L_4AC64:
                cmp.b   #$7F,d4
                beq.b   L_4ACCC
                addq.w  #$1,$32(a0)
                addq.w  #$1,$34(a0)
                ext.w   d3
                ext.w   d4
                asl.w   #$1,d4
                tst.w   d2
                bpl.b   L_4AC7E
                neg.w   d4
L_4AC7E:
                add.w   d3,$C(a0)
                add.w   d4,$A(a0)
                cmpi.w  #$20,$A(a0)
                bcs.b   L_4ACA6
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4ACAA
                cmpi.w  #$E0,$C(a0)
                bhi.b   L_4ACA6
                cmpi.w  #$10,$C(a0)
                bhi.b   L_4ACAA
L_4ACA6:
                jmp     (jt_ObjKillSelf).w
L_4ACAA:
                move.b  (a2,d0.w),d3
                ext.w   d3
                tst.w   d2
                bpl.b   L_4ACB8
                add.w   #$9,d3
L_4ACB8:
                move.w  d3,$1E(a0)
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                addq.w  #$6,d1
                jsr     (jt_GetMapCell).w
                beq.b   L_4ACD6
L_4ACCC:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
L_4ACD6:
                rts
L_4ACD8:
                st.b    (MusicFadeReq).w
                movem.w $2(a1),d0-d1
                move.w  $8(a2),d2
                moveq   #30,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$2,$21(a0)
                clr.w   $3A(a0)
                move.w  #$7D,$3C(a0)
                bsr.w   L_4ADF2
                jmp     (jt_ObjInsert).w
L_4AD08:
                tst.b   $39(a0)
                beq.b   L_4AD1E
                cmpi.b  #$1,$39(a0)
                beq.b   L_4AD48
                subq.b  #$1,$3A(a0)
                bmi.b   L_4AD82
                rts
L_4AD1E:
                move.w  $C(a0),d1
                tst.w   $34(a0)
                bmi.b   L_4AD40
                cmp.w   $36(a0),d1
                bgt.b   L_4AD6C
L_4AD2E:
                movem.w $32(a0),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                bra.w   L_4AEB8
L_4AD40:
                cmp.w   $36(a0),d1
                blt.b   L_4AD6C
                bra.b   L_4AD2E
L_4AD48:
                move.w  $A(a0),d1
                tst.w   $32(a0)
                bmi.b   L_4AD64
                cmp.w   $36(a0),d1
                bgt.b   L_4AD6C
L_4AD58:
                move.w  $32(a0),d0
                add.w   d0,$A(a0)
                bra.w   L_4AEB8
L_4AD64:
                cmp.w   $36(a0),d1
                blt.b   L_4AD6C
                bra.b   L_4AD58
L_4AD6C:
                move.b  #$2,$39(a0)
                moveq   #25,d0
                jsr     (jt_Random).w
                move.b  d0,$3A(a0)
                clr.w   $1E(a0)
                rts
L_4AD82:
                subq.b  #$1,$38(a0)
                bpl.b   L_4ADF2
                moveq   #2,d0
                jsr     (jt_Random).w
                addq.w  #$1,d0
                move.b  d0,$38(a0)
                move.b  #$1,$39(a0)
                clr.w   $34(a0)
                move.w  #$2,$32(a0)
                move.w  $A(a0),d0
                add.w   #$A,d0
                move.w  d0,$36(a0)
                move.w  #$2,$1E(a0)
                move.l  a0,-(a7)
                movem.w $A(a0),d0-d1
                add.w   #$FFD8,d0
                add.w   #$A,d1
                moveq   #-1,d2
                jsr     (jt_ObjAlloc).w
                move.l  #D_4BB4C,$2A(a0)
                move.l  #L_4AECE,$6(a0)
                move.l  #D_4BB24,$12(a0)
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
L_4ADF2:
                move.w  ($F0).w,d0
                sub.w   #$F,d0
                move.w  d0,d1
                add.w   #$14,d1
                cmp.w   $C(a0),d0
                bgt.b   L_4AE4A
                cmp.w   $C(a0),d1
                blt.b   L_4AE4A
                clr.w   $34(a0)
                moveq   #50,d0
                jsr     (jt_Random).w
                move.w  d0,d2
                tst.b   $3B(a0)
                bmi.b   L_4AE2A
                move.w  $A(a0),d1
                add.w   d2,d1
                cmp.w   #$122,d1
                ble.b   L_4AE2E
L_4AE2A:
                moveq   #-2,d0
                bra.b   L_4AE32
L_4AE2E:
                bsr.w   L_4AEAA
L_4AE32:
                tst.w   d0
                bpl.b   L_4AE38
                neg.w   d2
L_4AE38:
                add.w   $A(a0),d2
                move.w  d2,$36(a0)
                move.b  #$1,$39(a0)
                bra.w   L_4AE96
L_4AE4A:
                clr.b   $39(a0)
                move.w  ($F0).w,d2
                sub.w   #$1E,d2
                moveq   #59,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                cmp.w   #$B1,d2
                blt.b   L_4AE68
                move.w  #$B0,d2
L_4AE68:
                move.w  d2,$36(a0)
                moveq   #2,d0
                sub.w   $C(a0),d2
                bpl.b   L_4AE78
                neg.w   d0
                neg.w   d2
L_4AE78:
                move.w  d0,$34(a0)
                move.w  $A(a0),d0
                add.w   d2,d0
                tst.b   $3B(a0)
                bmi.b   L_4AE8E
                cmp.w   #$122,d0
                ble.b   L_4AE92
L_4AE8E:
                moveq   #-2,d0
                bra.b   L_4AE96
L_4AE92:
                bsr.w   L_4AEAA
L_4AE96:
                move.w  #$1,$1E(a0)
                move.w  d0,$32(a0)
                bpl.b   L_4AEA8
                move.w  #$2,$1E(a0)
L_4AEA8:
                rts
L_4AEAA:
                moveq   #1,d0
                jsr     (jt_Random).w
                asl.w   #$1,d0
                addq.w  #$1,d0
                asl.w   #$1,d0
                rts
L_4AEB8:
                subq.w  #$1,$3C(a0)
                bpl.b   L_4AEC2
                st.b    $3B(a0)
L_4AEC2:
                tst.w   $A(a0)
                bpl.b   L_4AECC
                jmp     (jt_ObjKillSelf).w
L_4AECC:
                rts
L_4AECE:
                subq.w  #$8,$A(a0)
                tst.w   $A(a0)
                bpl.b   L_4AECC
                jmp     (jt_ObjKillSelf).w
L_4AEDC:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.l  #D_4BB92,$2A(a0)
                move.w  $6(a1),$32(a0)
                bpl.b   L_4AF04
                move.l  #D_4BB88,$2A(a0)
L_4AF04:
                move.w  $32(a0),d2
                bsr.w   L_4AFB4
                move.w  #$200,$34(a0)
                clr.w   $1E(a0)
                bsr.w   L_4B01E
                jmp     (jt_ObjInsert).w
L_4AF1E:
                cmpi.w  #$10,$A(a0)
                bcs.b   L_4AF36
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4AF36
                cmpi.w  #$E0,$C(a0)
                bcs.b   L_4AF3A
L_4AF36:
                jmp     (jt_ObjKillSelf).w
L_4AF3A:
                move.b  $34(a0),d0
                beq.b   L_4AF86
                cmp.b   #$1,d0
                beq.w   L_4AFE8
                cmp.b   #$2,d0
                beq.w   L_4B01E
                subq.w  #$1,$A(a0)
                subq.b  #$1,$35(a0)
                bmi.b   L_4AF6C
                rts
L_4AF5C:
                st.b    $34(a0)
                clr.b   $22(a0)
                move.l  #D_4BB88,$2A(a0)
L_4AF6C:
                move.b  #$A,$35(a0)
                bsr.w   L_4AB44
                move.w  #$B,$1E(a0)
                tst.w   d2
                bpl.b   L_4AF84
                clr.w   $1E(a0)
L_4AF84:
                rts
L_4AF86:
                move.w  $32(a0),d2
                movem.w $A(a0),d0-d1
                add.w   #$C,d1
                subq.w  #$3,d0
                tst.w   d2
                bmi.b   L_4AF9E
                add.w   #$23,d0
L_4AF9E:
                jsr     (jt_GetMapCell).w
                bne.b   L_4AF5C
                adda.l  (MapRowBytes).w,a4
                btst.b  #$7,(a4)
                beq.b   L_4AFB4
                add.w   d2,$A(a0)
                rts
L_4AFB4:
                move.b  #$1,$34(a0)
                clr.w   $36(a0)
                move.w  #$23,$38(a0)
                move.l  #D_4BB97,$2A(a0)
                tst.w   d2
                bpl.b   L_4AFD8
                move.l  #D_4BB8D,$2A(a0)
L_4AFD8:
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                st.b    $22(a0)
                rts
L_4AFE8:
                lea.l   (D_4BBFC).l,a2
                move.w  $36(a0),d0
                moveq   #3,d2
                move.b  (a2,d0.w),d3
                cmp.b   #$7F,d3
                bne.b   L_4B006
                move.b  #$2,$34(a0)
                bra.b   L_4B01E
L_4B006:
                ext.w   d3
                tst.w   $32(a0)
                bpl.b   L_4B010
                neg.w   d2
L_4B010:
                add.w   d2,$A(a0)
                add.w   d3,$C(a0)
                addq.w  #$1,$36(a0)
                rts
L_4B01E:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                add.w   #$1A,d1
                jsr     (jt_GetMapCell).w
                bne.b   L_4B03A
                addq.w  #$4,$C(a0)
                rts
L_4B03A:
                clr.w   $34(a0)
                move.l  #D_4BB92,$2A(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.w   $32(a0)
                bpl.b   L_4B05C
                move.l  #D_4BB88,$2A(a0)
L_4B05C:
                rts
L_4B05E:
                movea.l $A(a1),a3
                move.w  $8(a1),d7
                clr.w   d6
L_4B068:
                move.w  (a3)+,d0
                bmi.b   L_4B08C
                move.w  (a3)+,d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)
                clr.w   $38(a0)
                move.w  d6,$32(a0)
                add.w   d7,d6
                jsr     (jt_ObjInsert).w
                bra.b   L_4B068
L_4B08C:
                rts
L_4B08E:
                tst.w   $32(a0)
                beq.b   L_4B09A
                subq.w  #$1,$32(a0)
                rts
L_4B09A:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   L_4B0BC
                cmp.w   #$170,d0
                bhi.b   L_4B0BC
                cmp.w   #$2,d1
                bcs.b   L_4B0BC
                cmp.w   #$E0,d1
                bcs.b   L_4B0C0
L_4B0BC:
                jmp     (jt_ObjKillSelf).w
L_4B0C0:
                move.w  $3A(a0),d4
                cmp.w   (ScrollX).w,d4
                bhi.b   L_4B0DA
                moveq   #10,d7
                cmp.w   #$88,d1
                bcs.b   L_4B0D6
                move.w  #$E0,d7
L_4B0D6:
                moveq   #4,d6
                bra.b   L_4B0E6
L_4B0DA:
                subq.w  #$1,$38(a0)
                bpl.b   L_4B124
                movem.w (ShipPos).w,d6-d7
L_4B0E6:
                moveq   #2,d4
                lea.l   (D_4BC38).l,a1
                cmp.w   d6,d0
                bcs.b   L_4B0FA
                moveq   #-1,d4
                lea.l   (D_4BC3C).l,a1
L_4B0FA:
                move.l  a1,$2A(a0)
                moveq   #1,d5
                cmp.w   d7,d1
                bcs.b   L_4B106
                neg.w   d5
L_4B106:
                move.w  d0,d2
                sub.w   d6,d2
                bpl.b   L_4B10E
                neg.w   d2
L_4B10E:
                lsr.w   #$2,d2
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)
                move.b  d4,$36(a0)
                move.b  d5,$37(a0)
L_4B124:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6
                ext.w   d6
                bpl.b   L_4B13A
                subq.w  #$2,d1
                bra.b   L_4B13E
L_4B13A:
                add.w   #$20,d1
L_4B13E:
                addq.w  #$8,d0
                jsr     (jt_GetMapCell).w
                bne.b   L_4B14A
                add.w   d6,$C(a0)
L_4B14A:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1
                move.b  $36(a0),d4
                ext.w   d4
                bpl.b   L_4B15C
                subq.w  #$2,d0
                bra.b   L_4B160
L_4B15C:
                add.w   #$22,d0
L_4B160:
                jsr     (jt_GetMapCell).w
                bne.b   L_4B16A
                add.w   d4,$A(a0)
L_4B16A:
                rts
LevelInit:
                clr.b   (D_4BCCB).l
                clr.b   (D_4BCCD).l
                lea.l   (D_4BD44).l,a0
                lea.l   (D_4BD80).l,a1
                move.w  #$5,(a0)
                move.l  a1,$8(a0)
                move.w  #$8,$C(a0)
                move.l  a1,$14(a0)
                move.w  #$B,$18(a0)
                move.l  a1,$20(a0)
                move.w  #$E,$24(a0)
                move.l  a1,$2C(a0)
                move.w  #$11,$30(a0)
                move.l  a1,$38(a0)
                clr.b   (D_4BCCC).l
                moveq   #4,d7
L_4B1BC:
                movea.l $4(a0),a2
                lea.l   (D_4BD94).l,a1
                bsr.w   L_4B4C6
                adda.l  #$C,a0
                dbra    d7,L_4B1BC
                bra.w   L_4B3AE
L_4B1D8:
                rts
LevelFrame:
                tst.b   (D_4BCCD).l
                bne.w   L_4B374
                cmpi.w  #$83E,(ScrollX).w
                bne.b   L_4B1F4
                bsr.w   L_4B69E
                bsr.w   L_4B2DC
L_4B1F4:
                cmpi.w  #$83F,(ScrollX).w
                bcs.b   L_4B1D8
                clr.b   (ScrollActive).w
                moveq   #4,d7
                lea.l   (D_4BD44).l,a4
                cmpi.b  #$1F,(D_4BCCB).l
                beq.b   L_4B260
                subq.b  #$1,(D_4BCCC).l
                bpl.b   L_4B1D8
                move.b  #$2,(D_4BCCC).l
L_4B222:
                tst.w   (a4)
                bne.b   L_4B252
                movea.l $4(a4),a2
                movea.l $8(a4),a0
                move.l  (a0)+,d0
                bmi.b   L_4B23E
                movea.l d0,a1
                move.l  a0,$8(a4)
                bsr.w   L_4B4C6
                bra.b   L_4B254
L_4B23E:
                bset.b  d7,(D_4BCCB).l
                moveq   #20,d0
                jsr     (jt_Random).w
                add.w   #$A,d0
                move.w  d0,(a4)
                bra.b   L_4B254
L_4B252:
                subq.w  #$1,(a4)
L_4B254:
                adda.l  #$C,a4
                dbra    d7,L_4B222
                rts
L_4B260:
                subq.w  #$1,(a4)
                bpl.b   L_4B2B8
                moveq   #35,d0
                jsr     (jt_Random).w
                add.w   #$19,d0
                move.w  d0,(a4)
                moveq   #5,d0
                jsr     (jt_Random).w
                lsl.w   #$3,d0
                lea.l   (D_4BCCE).l,a1
                movea.l (a1,d0.w),a2
                move.w  $6(a1,d0.w),d6
                move.w  $2(a4),d0
                moveq   #20,d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.w  d6,$1E(a0)
                move.l  #L_4B2C4,$6(a0)
                clr.b   $22(a0)
                clr.w   $2E(a0)
                cmpi.l  #$4B8F6,$12(a0)
                bne.b   L_4B2B4
                st.b    $22(a0)
L_4B2B4:
                jsr     (jt_ObjInsert).w
L_4B2B8:
                adda.l  #$C,a4
                dbra    d7,L_4B260
                rts
L_4B2C4:
                addq.w  #$4,$C(a0)
                cmpi.w  #$BA,$C(a0)
                bcs.b   L_4B2DA
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
L_4B2DA:
                rts
L_4B2DC:
                moveq   #95,d1
                move.w  #$172,d0
                move.w  #$7D0,d2
                lea.l   (D_4BC70).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$AF,$32(a0)
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
L_4B2FE:
                subq.w  #$1,$32(a0)
                bpl.b   L_4B352
                clr.w   $1E(a0)
                move.l  #L_4B312,$6(a0)
                bra.b   L_4B352
L_4B312:
                subq.w  #$2,$A(a0)
                cmpi.w  #$131,$A(a0)
                bhi.b   L_4B352
                st.b    $22(a0)
                move.l  #L_4B32C,$6(a0)
                bra.b   L_4B352
L_4B32C:
                cmpi.w  #$10,$1E(a0)
                bne.b   L_4B352
                clr.b   $22(a0)
                addq.w  #$2,$A(a0)
                cmpi.w  #$163,$A(a0)
                bcs.b   L_4B352
                move.w  #$7D,$32(a0)
                move.l  #L_4B2FE,$6(a0)
L_4B352:
                cmpi.w  #$32,$26(a0)
                bcs.b   L_4B372
                st.b    (D_4BCCD).l
                st.b    (LevelComplete).w
                move.l  #$500,d0
                jsr     (jt_AddScore).w
                jmp     (jt_ObjKillSelf).w
L_4B372:
                rts
L_4B374:
                move.w  #$A4,d0
                jsr     (jt_Random).w
                add.w   #$28,d0
                move.w  d0,d1
                move.w  #$118,d0
                jsr     (jt_Random).w
                add.w   #$28,d0
                moveq   #-1,d2
                lea.l   (D_4BC70).l,a2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  #$2,$21(a0)
                jmp     (jt_ObjInsert).w
L_4B3AE:
                lea.l   (D_4A344).l,a0
                lea.l   (D_4BDE4).l,a4
L_4B3BA:
                cmpi.w  #$7530,(a0)
                beq.b   L_4B3EA
                cmpi.l  #$4BE14,$E(a0)
                bne.b   L_4B3E2
                lea.l   ($57300).l,a2
                adda.w  $6(a0),a2
                move.w  $8(a0),d0
                lsl.w   #$2,d0
                movea.l $18(a4,d0.w),a1
                bsr.w   L_4B4C6
L_4B3E2:
                adda.l  #$12,a0
                bra.b   L_4B3BA
L_4B3EA:
                rts
L_4B3EC:
                moveq   #-1,d0
                moveq   #0,d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                move.l  $2(a1),$32(a0)
                move.l  $6(a1),$36(a0)
                move.b  #$F,$3A(a0)
                move.b  #$2,$3B(a0)
                move.b  #$2,$4(a0)
                moveq   #16,d0
                tst.w   $A(a1)
                beq.b   L_4B420
                add.w   #$A,d0
L_4B420:
                move.w  d0,$3C(a0)
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
L_4B42C:
                subq.w  #$1,$32(a0)
                subq.b  #$1,$3A(a0)
                bmi.b   L_4B47E
                tst.b   $3B(a0)
                bmi.b   L_4B47C
                subq.b  #$1,$3B(a0)
                moveq   #10,d0
                jsr     (jt_Random).w
                subq.w  #$5,d0
                add.w   $3C(a0),d0
                add.w   $34(a0),d0
                move.w  d0,d1
                moveq   #20,d0
                jsr     (jt_Random).w
                subq.w  #$5,d0
                add.w   $32(a0),d0
                moveq   #-1,d2
                lea.l   (D_4BE14).l,a2
                movea.l a0,a3
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
L_4B47C:
                rts
L_4B47E:
                lea.l   ($57300).l,a2
                adda.w  $36(a0),a2
                lea.l   (D_4BDE4).l,a1
                move.w  $38(a0),d0
                lsl.w   #$2,d0
                movea.l (a1,d0.w),a1
                bsr.w   L_4B4C6
                move.l  $32(a0),$A(a0)
                st.b    $22(a0)
                move.l  #L_4B4B4,$6(a0)
                moveq   #12,d0
                jmp     (jt_PlaySound).w
L_4B4B4:
                subq.w  #$1,$A(a0)
                cmpi.w  #$19,$1E(a0)
                bne.b   L_4B4C4
                jmp     (jt_ObjKillSelf).w
L_4B4C4:
                rts
L_4B4C6:
                moveq   #0,d0
                moveq   #0,d1
                move.b  (a1)+,d0
                move.b  (a1)+,d1
L_4B4CE:
                move.w  d0,d2
                movea.l a2,a3
L_4B4D2:
                move.w  (a1)+,(a3)+
                dbra    d2,L_4B4D2
                adda.l  (MapRowBytes).w,a2
                dbra    d1,L_4B4CE
                rts
L_4B4E2:
                movem.w $2(a1),d0-d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$32(a0)
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
L_4B4FC:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                move.w  $32(a0),d7
                bpl.b   L_4B512
                add.w   #$15,d1
                bra.b   L_4B514
L_4B512:
                subq.w  #$2,d1
L_4B514:
                subq.w  #$8,d0
                jsr     (jt_GetMapCell).w
                beq.b   L_4B522
                add.w   d7,$C(a0)
                bra.b   L_4B532
L_4B522:
                subq.w  #$2,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4B532
                jmp     (jt_ObjKillSelf).w
L_4B532:
                rts
L_4B534:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$A,$4(a0)
                move.w  #$1D6,$32(a0)
                clr.w   $34(a0)
                clr.b   $36(a0)
                jmp     (jt_ObjInsert).w
L_4B55C:
                tst.b   $36(a0)
                bne.w   L_4B5AC
                move.w  $26(a0),d1
                clr.w   $26(a0)
                move.w  $A(a0),d0
                sub.w   (ShipPos).w,d0
                bmi.b   L_4B588
                add.w   d1,$34(a0)
                cmpi.w  #$46,$34(a0)
                bcs.b   L_4B588
                move.w  #$110,$36(a0)
L_4B588:
                tst.w   $32(a0)
                bmi.b   L_4B5A0
                subq.w  #$1,$32(a0)
                btst.b  #$0,$33(a0)
                beq.b   L_4B5AA
                addq.w  #$1,$A(a0)
                rts
L_4B5A0:
                subq.w  #$1,$A(a0)
                bpl.b   L_4B5AA
                jmp     (jt_ObjKillSelf).w
L_4B5AA:
                rts
L_4B5AC:
                subq.b  #$1,$37(a0)
                bmi.b   L_4B5F8
                movea.l a0,a3
                moveq   #30,d0
                jsr     (jt_Random).w
                sub.w   #$A,d0
                add.w   $C(a0),d0
                move.w  d0,d1
                move.w  #$60,d0
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                sub.w   #$F,d0
                moveq   #-1,d2
                lea.l   (D_4BFDA).l,a2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  #$28,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                rts
L_4B5F8:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.l  #$1500,d0
                jmp     (jt_AddScore).w
L_4B60C:
                moveq   #1,d7
                moveq   #0,d6
                moveq   #0,d5
L_4B612:
                movem.w $2(a1),d0-d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.w  d6,$34(a0)
                moveq   #30,d0
                jsr     (jt_Random).w
                move.w  d0,$32(a0)
                move.w  d5,$1E(a0)
                jsr     (jt_ObjInsert).w
                add.w   #$18,d6
                addq.w  #$1,d5
                dbra    d7,L_4B612
                rts
L_4B640:
                tst.w   $34(a0)
                beq.b   L_4B64C
                subq.w  #$1,$34(a0)
                rts
L_4B64C:
                subq.w  #$3,$A(a0)
                bpl.b   L_4B656
                jmp     (jt_ObjKillSelf).w
L_4B656:
                subq.w  #$1,$32(a0)
                bpl.b   L_4B68A
                move.w  #$32,$32(a0)
                moveq   #10,d7
                add.w   $C(a0),d7
                move.w  d7,d0
                move.w  d0,d1
                move.w  $A(a0),d0
                moveq   #-1,d2
                move.l  a0,-(a7)
                lea.l   (D_4C00A).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
L_4B68A:
                rts
L_4B68C:
                subq.w  #$7,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4B69C
                jmp     (jt_ObjKillSelf).w
L_4B69C:
                rts
L_4B69E:
                bsr.w   L_4B716
                move.w  #$DC,d1
                move.w  #$7D0,d2
                lea.l   (D_4C0EA).l,a2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                clr.b   $34(a0)
                move.b  #$14,$32(a0)
                jmp     (jt_ObjInsert).w
L_4B6C6:
                cmpi.w  #$5,$26(a0)
                bcs.b   L_4B722
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (D_4C0EA).l,a2
                movea.l a0,a4
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                move.b  #$64,$34(a0)
                move.w  #$DC,$C(a0)
                bsr.b   L_4B716
                move.w  d0,$A(a0)
                move.l  #L_4B774,$6(a0)
                move.l  #$500,d0
                jmp     (jt_AddScore).w
L_4B716:
                moveq   #100,d0
                jsr     (jt_Random).w
                add.w   #$64,d0
                rts
L_4B722:
                tst.b   (D_4BCCD).l
                beq.b   L_4B72E
                jmp     (jt_ObjKillSelf).w
L_4B72E:
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  d0,$1E(a0)
                subq.b  #$1,$32(a0)
                bne.b   L_4B772
                lea.l   (D_4C16C).l,a3
                move.w  d0,d2
                lsl.w   #$2,d2
                movem.w $A(a0),d0-d1
                add.w   (a3,d2.w),d0
                add.w   $2(a3,d2.w),d1
                jsr     (jt_FireEnemyBullet).w
                moveq   #20,d0
                jsr     (jt_Random).w
                add.w   #$14,d0
                move.b  d0,$32(a0)
L_4B772:
                rts
L_4B774:
                tst.b   $34(a0)
                beq.b   L_4B780
                subq.b  #$1,$34(a0)
                rts
L_4B780:
                subq.w  #$2,$C(a0)
                cmpi.w  #$AA,$C(a0)
                bhi.b   L_4B798
                clr.w   $26(a0)
                move.l  #L_4B6C6,$6(a0)
L_4B798:
                rts
                dc.w    $006E,$0000,$0078,$0800,$007A,$1300,$FFFF,$0078
                dc.w    $0000,$006E,$1000,$007A,$2000,$006E,$3000,$0078
                dc.w    $4000,$FFFF,$006E,$0000,$0078,$3000,$FFFF,$005A
                dc.w    $0000,$0064,$1000,$0064,$3200,$0064,$4200,$FFFF
                dc.w    $0064,$0000,$005A,$1200,$0064,$2400,$0050,$3600
                dc.w    $FFFF,$005A,$0000,$0064,$0F00,$0050,$1E00,$005A
                dc.w    $2D00,$0064,$3C00,$FFFF,$0043,$0007,$0B4C,$0007
                dc.w    $0B99,$0007,$0BE6,$0053,$0007,$0C2D,$0007,$0C84
                dc.w    $0007,$0CDB,$011F,$0007,$0D2F,$0007,$0E4F,$0007
                dc.w    $0F6F,$00D5,$0007,$0D79,$0007,$0E99,$0007,$0FB9
                dc.w    $0170,$005A,$0170,$0046,$0012,$005A,$FFFF,$0170
                dc.w    $0046,$FFFF,$015E,$0082,$00B4,$0003,$FFFF,$015E
                dc.w    $0078,$FFFF,$0012,$0028,$0012,$0067,$0163,$0032
                dc.w    $0163,$005A,$FFFF,$0012,$00B4,$0163,$00A6,$FFFF
                dc.w    $0163,$0028,$0163,$00B4,$FFFF,$1303,$002E,$0260
                dc.w    $0001,$0001,$002D,$0005,$BCD6,$0000,$0130,$0004
                dc.w    $B8AC,$0004,$B8B6
                dc.l    L_4A94E
                dc.l    L_4A928
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0005
                dc.w    $0000,$000E,$0012,$0005,$0003,$000F,$000E,$0000
                dc.w    $0006,$0014,$0006,$0005,$0003,$000E,$000E,$0003
                dc.w    $0001,$0010,$0011,$0004,$0003,$000F,$000E,$0000
                dc.w    $0007,$0014,$0006,$0004,$0003,$000F,$000E,$1503
                dc.w    $002E,$02A0,$0002,$0001,$005F,$0005,$CFD6,$0000
                dc.w    $0150,$0004,$B91E,$0004,$B928
                dc.l    L_4A9D0
                dc.l    L_4A98E
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0003,$0011,$0011,$0002,$0002,$0011,$0012,$0001
                dc.w    $0002,$0011,$0011,$0002,$0001,$0011,$0011,$0002
                dc.w    $0001,$0011,$0012,$0003,$0001,$0010,$0011,$0002
                dc.w    $0002,$0012,$0011,$0003,$0002,$0011,$0012,$1A03
                dc.w    $002E,$0340,$0002,$0006,$0000,$0006,$0546,$0000
                dc.w    $01A0,$0004,$B990,$0004,$B9AC
                dc.l    L_4AA52
                dc.l    L_4AA28
                dc.w    $0000,$0500
D_4B990:
                dc.b    $00,$01,$02,$03,$04,$05,$FF
D_4B997:
                dc.b    $06,$07,$08,$09,$0A,$0B,$FF
D_4B99E:
                dc.w    $0D0E,$FF03,$0C0D,$0EFF
D_4B9A6:
                dc.w    $0E0D,$0C03,$FF00,$0005,$0009,$0019,$0011,$0004
                dc.w    $0009,$001A,$0010,$0005,$0006,$0019,$0013,$0003
                dc.w    $0009,$001A,$0010,$0004,$0007,$0019,$0012,$0004
                dc.w    $0007,$0018,$0012,$0004,$0007,$0018,$0012,$0004
                dc.w    $0007,$0018,$0012,$0003,$0006,$0019,$0013,$0004
                dc.w    $0008,$001B,$0012,$0003,$0007,$0019,$0012,$0004
                dc.w    $0007,$0019,$0012,$000C,$0004,$000F,$0015,$0012
                dc.w    $0002,$000D,$0018,$0012,$0002,$000D,$0018
D_4BA24:
                dc.w    $0D02,$0030,$00D0,$0000,$0000,$0000,$0006,$3606
                dc.w    $0000,$0068,$0004,$BA4C,$0004,$BA60
                dc.l    L_4AC38
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$0607
                dc.w    $0800,$0F0E,$0D0C,$0B0A,$0908,$FF00,$0003,$0000
                dc.w    $0008,$000D,$0003,$0001,$0008,$000C,$0001,$0001
                dc.w    $000A,$000B,$0001,$0002,$000B,$0008,$0000,$0003
                dc.w    $000D,$0007,$0000,$0003,$000C,$0008,$0001,$0001
                dc.w    $000A,$000A,$0002,$0000,$0008,$000B,$0003,$0000
                dc.w    $0007,$000C,$0002,$0000,$0009,$000B,$0001,$0001
                dc.w    $000B,$000B,$0000,$0003,$000D,$0008,$0000,$0003
                dc.w    $000D,$0007,$0001,$0003,$000E,$0008,$0001,$0002
                dc.w    $000B,$000A,$0002,$0001,$0009,$000C,$2F04,$002C
                dc.w    $08D0,$0000,$001E,$0000,$0005,$E4D6,$0000,$0468
                dc.w    $0004,$BB08,$0004,$BB0C
                dc.l    L_4AD08
                dc.l    L_4ACD8
                dc.w    $0000,$0500,$0001,$0203,$000F,$0003,$0016,$0024
                dc.w    $0007,$0001,$001B,$0027,$0011,$0002,$001A,$002B
D_4BB24:
                dc.w    $1004,$002C,$0300,$0000,$0000,$0000,$0005,$FF46
                dc.w    $0000,$0180,$0004,$BB4C,$0004,$BB50,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
D_4BB4C:
                dc.w    $0001,$FF00,$0002,$0004,$002B,$0009,$0001,$0002
                dc.w    $002C,$000C,$1A03,$002E,$0340,$0003,$0001,$001E
                dc.w    $0006,$4306,$0000,$01A0,$0004,$BB88,$0004,$BB9C
                dc.l    L_4AF1E
                dc.l    L_4AEDC
                dc.w    $0000,$0200
D_4BB88:
                dc.b    $00,$01,$02,$03,$FF
D_4BB8D:
                dc.b    $04,$05,$FF,$03,$FF
D_4BB92:
                dc.b    $06,$07,$08,$09,$FF
D_4BB97:
                dc.b    $0A,$0B,$FF,$09,$FF,$00,$03,$00,$01,$00,$15,$00,$19,$00,$02,$00
                dc.b    $03,$00,$18,$00,$16,$00,$04,$00,$01,$00,$15,$00,$19,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$02,$00,$02,$00,$18,$00,$17,$00,$02,$00
                dc.b    $02,$00,$18,$00,$16,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$14,$00,$04,$00,$02,$00,$18,$00,$16,$00,$04,$00
                dc.b    $03,$00,$18,$00,$15
D_4BBFC:
                dc.w    $FEFE,$FEFF,$FFFF,$FF00,$0000,$0101,$0101,$0202
                dc.w    $027F,$7F00,$1A03,$002E,$0340,$0005,$0001,$0028
                dc.w    $0006,$6A06,$0000,$01A0,$0004,$BC38,$0004,$BC40
                dc.l    L_4B08E
                dc.l    L_4B05E
                dc.w    $0000,$0300
D_4BC38:
                dc.w    $0304,$05FF
D_4BC3C:
                dc.w    $0001,$02FF,$0004,$0002,$0018,$0016,$0002,$0003
                dc.w    $001B,$0014,$0004,$0004,$0018,$0013,$0005,$0004
                dc.w    $0018,$0014,$0004,$0003,$0019,$0015,$0005,$0003
                dc.w    $0018,$0015
D_4BC70:
                dc.w    $3004,$002C,$0900,$0003,$0000,$0000,$0006,$9BA6
                dc.w    $0000,$0480,$0004,$BCB8,$0004,$BC98
                dc.l    L_4B2FE
                dc.w    $0000,$0000,$0000,$0000,$0016,$0001,$001A,$002E
                dc.w    $0016,$0001,$001A,$002E,$0016,$0001,$001A,$002E
                dc.w    $0016,$0001,$001A,$002E,$0001,$0203,$0303,$0303
                dc.b    $02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$FF
D_4BCCB:
                dc.b    $00
D_4BCCC:
                dc.b    $00
D_4BCCD:
                dc.b    $00
D_4BCCE:
                dc.w    $0004,$BCF6,$0000,$0000,$0004,$BCF6,$0000,$0001
                dc.w    $0004,$BCF6,$0000,$0002,$0004,$BCF6,$0000,$0003
                dc.w    $0004,$B8F6,$0000,$0000,$1F03,$002E,$03E0,$0000
                dc.w    $0000,$0000,$0006,$8026,$0000,$01F0,$0004,$BD1E
                dc.w    $0004,$BD24
                dc.l    L_4B2C4
                dc.w    $0000,$0000,$0000,$0100,$0001,$0203,$FF00,$0002
                dc.w    $0002,$0015,$001B,$0004,$0002,$0019,$001C,$0002
                dc.w    $0002,$0017,$001B,$0002,$0001,$001B,$001B
D_4BD44:
                dc.w    $0000,$00FA,$0005,$7420,$0004,$BD80,$0000,$00CB
                dc.w    $0005,$741A,$0004,$BD80,$0000,$009B,$0005,$7414
                dc.w    $0004,$BD80,$0000,$0069,$0005,$740E,$0004,$BD80
                dc.w    $0000,$0037,$0005,$7408,$0004,$BD80
D_4BD80:
                dc.w    $0004,$BD94,$0004,$BDA8,$0004,$BDBC,$0004,$BDD0
                dc.w    $FFFF,$FFFF
D_4BD94:
                dc.w    $0202,$80F0,$80F1,$80F2,$8104,$8105,$8106,$0000
                dc.w    $0000,$0000,$0202,$80F3,$80F4,$80F5,$8107,$8108
                dc.w    $8109,$011B,$011C,$011D,$0202,$80F6,$80F7,$80F8
                dc.w    $810A,$810B,$810C,$011E,$011F,$0120,$0202,$80F9
                dc.w    $80FA,$80FB,$810D,$810E,$810F,$0121,$0122,$0123
D_4BDE4:
                dc.w    $0004,$BEA8,$0004,$BEB8,$0004,$BEDA,$0004,$BF4E
                dc.w    $0004,$BF14,$0004,$BF88,$0004,$BEA0,$0004,$BEB0
                dc.w    $0004,$BEC0,$0004,$BF34,$0004,$BEF4,$0004,$BF68
D_4BE14:
                dc.w    $3304,$002C,$0990,$0000,$FFFF,$0000,$0000,$B440
                dc.w    $0000,$04C8,$0004,$BE3C,$0004,$BE58
                dc.l    L_4B42C
                dc.l    L_4B3EC
                dc.w    $0000,$0000,$0001,$0201,$0102,$0203,$0304,$0405
                dc.w    $0506,$0607,$0708,$0805,$0506,$0607,$0708,$08FF
                dc.w    $0008,$0007,$0020,$0026,$0011,$000E,$000F,$0016
                dc.w    $000F,$000B,$0014,$001C,$000B,$0009,$001C,$0020
                dc.w    $0005,$0004,$0024,$002B,$000C,$0003,$0017,$002A
                dc.w    $000A,$0006,$001A,$0028,$0015,$0015,$0001,$0001
                dc.w    $0017,$0017,$0001,$0001,$0200,$8031,$8032,$8033
                dc.w    $0200,$8020,$8021,$8022,$0200,$802E,$802F,$8030
                dc.w    $0200,$800C,$800D,$800E,$0302,$801D,$801E,$801F
                dc.w    $8003,$0000,$0000,$0000,$8017,$0000,$0000,$0000
                dc.w    $802B,$0302,$8087,$8088,$8089,$809D,$0000,$0000
                dc.w    $0000,$80B1,$0000,$0000,$0000,$80C5,$0402,$8004
                dc.w    $8005,$8009,$800A,$800B,$8018,$8019,$0000,$0000
                dc.w    $0000,$802C,$802D,$0000,$0000,$0000,$0402,$809E
                dc.w    $809F,$8073,$8074,$8075,$80B2,$80B3,$0000,$0000
                dc.w    $0000,$80C6,$80C7,$0000,$0000,$0000,$0302,$0000
                dc.w    $0000,$0000,$808B,$0000,$0000,$0000,$8014,$8006
                dc.w    $8007,$8008,$8028,$0302,$0000,$0000,$0000,$8037
                dc.w    $0000,$0000,$0000,$804B,$8070,$8071,$8072,$805F
                dc.w    $0402,$8001,$8002,$0000,$0000,$0000,$8015,$8016
                dc.w    $0000,$0000,$0000,$8029,$802A,$801A,$801B,$801C
                dc.w    $0402,$8038,$8039,$0000,$0000,$0000,$804C,$804D
                dc.w    $0000,$0000,$0000,$8060,$8061,$8084,$8085,$8086
                dc.w    $1503,$002E,$02A0,$0000,$0000,$0000,$0006,$7D86
                dc.w    $0000,$0150,$0004,$BFD0,$0004,$BFD2
                dc.l    L_4B4FC
                dc.l    L_4B4E2
                dc.w    $0000,$0300,$00FF,$0002,$0002,$0014,$0011
D_4BFDA:
                dc.w    $2007,$0026,$0C00,$0000,$0000,$0000,$0006,$8FA6
                dc.w    $0000,$0600,$0004,$BFD0,$0004,$C002
                dc.l    L_4B55C
                dc.l    L_4B534
                dc.w    $0000,$1500,$0002,$0002,$005B,$001C
D_4C00A:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0006,$F486
                dc.w    $0000,$0030,$0004,$C052,$0004,$C032
                dc.l    L_4B68C
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0001,$0203,$FF00,$1403
                dc.w    $002E,$0280,$0002,$0000,$0000,$0006,$F606,$0000
                dc.w    $0140,$0004,$C0A0,$0004,$C0AA
                dc.l    L_4B640
                dc.l    L_4B60C
                dc.w    $0000,$0400,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0001,$0203,$0405,$0607,$FF00,$0001
                dc.w    $0003,$0017,$000F,$0003,$0003,$0015,$000C,$0001
                dc.w    $0002,$0018,$000B,$0001,$0002,$0019,$000D,$0002
                dc.w    $0002,$0017,$0010,$0001,$0005,$0018,$000D,$0001
                dc.w    $0006,$000E,$000C,$0001,$0005,$0018,$000D
D_4C0EA:
                dc.w    $2F03,$002E,$05E0,$0000,$0000,$0000,$0006,$BFA6
                dc.w    $0000,$02F0,$0004,$C112,$0004,$C124
                dc.l    L_4B774
                dc.w    $0000,$0000,$0000,$0100,$0001,$0203,$0404,$0404
                dc.w    $0405,$0505,$0506,$0708,$FF00,$0009,$0001,$000F
                dc.w    $002D,$0007,$0002,$0010,$002B,$0009,$0004,$000F
                dc.w    $002A,$0009,$0006,$000F,$0027,$0008,$0006,$000F
                dc.w    $0028,$0008,$0005,$000F,$002A,$0009,$0007,$000E
                dc.w    $0027,$0009,$0004,$000E,$002A,$0009,$0002,$000F
                dc.w    $002B
D_4C16C:
                dc.w    $0009,$0004,$000B,$0003,$000E,$0001,$0010,$0003
                dc.w    $0010,$0005,$0001,$0005,$0002,$0003,$0003,$0001
                dc.w    $0006,$0003,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
