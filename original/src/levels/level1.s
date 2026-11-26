;==============================================================================
; R-Type (Amiga) - level 1 code and data (level part A)
; Tracks 69.., loaded to $4A2E4 (Atari ST program header first)
;
; Assembles byte-identical to files/level1_a_4a2e4.bin with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -I src -o level1_a.bin src/levels/level1.s
;
; TEXT $4A300-$4B8E3: level table, wave list, palette, scroll script, code
; DATA $4B8E4-$4C2DD: object definitions, animations, tables
; $4C2DE on: unused track padding (only $4A2E4-$4CAFF survives the load
; of part B to $4CB00)
;
; First pass: code and data separated, entry points from the level table
; named.  L_xxxxx = code, D_xxxxx = data, still to be named.
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$15E4,$0000,$09FA,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0004,$A300,$0001
LevelInterface:
                dc.w    $0301,$1969
                dc.l    WaveList
                dc.l    LevelPalette
                dc.l    $5AF00
                dc.l    D_4D300
                dc.l    ScrollScript
                dc.l    TileAnims
                dc.l    MapPatches
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $5CA38
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
WaveList:
                dc.w    $0988,$0004,$A68C,$04A0,$0004,$A500,$00A5,$0004
                dc.w    $A350,$0000,$0004,$A350,$00CD,$0000,$0000,$0004
                dc.w    $B8E4,$0000,$0000,$0004,$B99A,$0104,$0000,$0000
                dc.w    $0004,$B8F6,$0000,$0000,$0004,$B99A,$014F,$0170
                dc.w    $0064,$0004,$BA0C,$0004,$0000,$0004,$BA36,$0172
                dc.w    $0170,$00B6,$FFFE,$0000,$0000,$0000,$0004,$BD82
                dc.w    $01B0,$0170,$007A,$0004,$BA1A,$0004,$0000,$0004
                dc.w    $BA36,$01F0,$0000,$0000,$0004,$B908,$0000,$0000
                dc.w    $0004,$B99A,$0224,$0000,$0000,$0004,$B916,$0000
                dc.w    $0000,$0004,$B99A,$0244,$0000,$0000,$0004,$B928
                dc.w    $0000,$0000,$0004,$B99A,$0250,$0000,$0000,$0004
                dc.w    $B936,$0000,$0000,$0004,$B99A,$0280,$0000,$0000
                dc.w    $0004,$B94C,$0000,$0000,$0004,$B99A,$028A,$0170
                dc.w    $0064,$0000,$FFFC,$0000,$0000,$FFFF,$FFFF,$02AA
                dc.w    $0000,$0000,$0004,$B95E,$0000,$0000,$0004,$B99A
                dc.w    $02C2,$0000,$0000,$0004,$B968,$0000,$0000,$0004
                dc.w    $B99A,$02E2,$0170,$00B6,$FFFE,$0000,$0000,$0000
                dc.w    $0004,$BD82,$02EC,$0000,$0000,$0004,$B96E,$0000
                dc.w    $0000,$0004,$B99A,$0322,$0000,$0000,$0004,$B978
                dc.w    $0000,$0000,$0004,$B99A,$033C,$0170,$00B6,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$BD82,$0370,$0170,$0084
                dc.w    $0000,$0000,$0000,$0000,$0004,$BD02,$037A,$0170
                dc.w    $00B6,$FFFE,$0000,$0000,$0000,$0004,$BD82,$03BB
                dc.w    $0170,$00B6,$0009,$0007,$0000,$0000,$0004,$BAA8
                dc.w    $03EE,$0170,$00B6,$FFFE,$0000,$0000,$0000,$0004
                dc.w    $BD82,$0400,$0010,$00B6,$0002,$0000,$0000,$0000
                dc.w    $0004,$BD82,$0420,$0170,$00A6,$FFFE,$0000,$0000
                dc.w    $0000,$0004,$BD82,$0451,$0170,$0032,$0004,$BA1A
                dc.w    $0004,$0000,$0004,$BA36,$04BA,$0170,$0064,$0004
                dc.w    $BA1A,$0000,$0000,$0004,$BA36,$04D3,$0014,$00B6
                dc.w    $0002,$0000,$0000,$0000,$0004,$BD82,$04D4,$010E
                dc.w    $000B,$FFFE,$0000,$0000,$0000,$0004,$BD82,$04F0
                dc.w    $0000,$0000,$0735,$0028,$0004,$BE32,$0004,$BEA0
                dc.w    $0547,$0000,$0000,$0735,$0010,$0004,$BE40,$0004
                dc.w    $BEA0,$0565,$0000,$0000,$0735,$0005,$0004,$BE4E
                dc.w    $0004,$BEA0,$058B,$0000,$0000,$0735,$0010,$0004
                dc.w    $BE5C,$0004,$BEA0,$05AB,$0000,$0000,$0735,$0008
                dc.w    $0004,$BE6A,$0004,$BEA0,$05B8,$0170,$00A6,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$BD82,$0648,$0000,$0000
                dc.w    $0735,$003C,$0004,$BE7C,$0004,$BEA0,$0692,$0000
                dc.w    $0000,$073A,$0035,$0004,$BE8E,$0004,$BEA0,$0694
                dc.w    $0170,$00B6,$0009,$0007,$0000,$0000,$0004,$BAA8
                dc.w    $069B,$0000,$0000,$0000,$0000,$0000,$0000,$0004
                dc.w    $BF04,$06B5,$0170,$0057,$0003,$FFFC,$0000,$0000
                dc.w    $FFFF,$FFFF,$0708,$0170,$0046,$0000,$FFFC,$0000
                dc.w    $0000,$FFFF,$FFFF,$0720,$0128,$000B,$0004,$BA28
                dc.w    $0004,$FFFF,$0004,$BA36,$088C,$0170,$0094,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$BD82,$08E7,$0000,$0000
                dc.w    $0004,$B982,$0000,$0000,$0004,$B99A,$08BD,$0170
                dc.w    $00B6,$0009,$0007,$0000,$0000,$0004,$BAA8,$092D
                dc.w    $0000,$0000,$0004,$B990,$0000,$0000,$0004,$B99A
                dc.w    $0942,$0170,$0082,$0005,$FFFC,$0000,$0000,$FFFF
                dc.w    $FFFF,$0992,$0170,$0087,$0001,$FFFC,$0000,$0000
                dc.w    $FFFF,$FFFF,$09A4,$0170,$0094,$FFFE,$0000,$0000
                dc.w    $0000,$0004,$BD82,$09E5,$010F,$000B,$0004,$BA28
                dc.w    $0009,$FFFF,$0004,$BA36,$0A07,$00F7,$000B,$FFFE
                dc.w    $0000,$0000,$0000,$0004,$BD82,$0A62,$0170,$0087
                dc.w    $0004,$FFFC,$0000,$0000,$FFFF,$FFFF,$0B28,$0170
                dc.w    $00A5,$0000,$0000,$0000,$0000,$0004,$BFCA,$0BE5
                dc.w    $0170,$0046,$0000,$FFFC,$0000,$0000,$FFFF,$FFFF
                dc.w    $0BFE,$0170,$00A5,$0000,$0000,$0000,$0000,$0004
                dc.w    $BFCA,$0D36,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0004,$C1CA,$0DF2,$0170,$007D,$0000,$0000,$0000
                dc.w    $0000,$0004,$C22A,$7530
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
L_4A74E:
                movea.l $6(a1),a3
L_4A752:
                move.w  (a3)+,d1
                bmi.b   L_4A772
                move.w  #$170,d0
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  (a3)+,$32(a0)
                move.b  (a3)+,$1F(a0)
                clr.w   $34(a0)
                jsr     (jt_ObjInsert).w
                bra.b   L_4A752
L_4A772:
                rts
L_4A774:
                tst.b   $32(a0)
                beq.b   L_4A780
                subq.b  #$1,$32(a0)
                rts
L_4A780:
                lea.l   ($78FD8).l,a1
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d1
                ext.w   d1
                add.w   d1,$C(a0)
                addq.w  #$1,d0
                cmp.w   #$23,d0
                bcs.b   L_4A79E
                clr.w   d0
L_4A79E:
                move.w  d0,$34(a0)
                subq.w  #$4,$A(a0)
                cmpi.w  #$20,$A(a0)
                bhi.b   L_4A7B2
                jmp     (jt_ObjKillSelf).w
L_4A7B2:
                rts
L_4A7B4:
                move.w  $A(a1),d7
                clr.w   d6
L_4A7BA:
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
                dbra    d7,L_4A7BA
                rts
L_4A7EC:
                move.w  $3A(a0),d0
                add.w   d0,$A(a0)
                tst.b   $38(a0)
                beq.b   L_4A800
                subq.b  #$1,$38(a0)
                rts
L_4A800:
                movea.l $32(a0),a1
                move.w  $36(a0),d0
                move.w  (a1)+,d1
                bsr.b   L_4A832
                add.w   d2,$A(a0)
                bsr.b   L_4A832
                add.w   d2,$C(a0)
                bsr.b   L_4A832
                move.b  d2,$1F(a0)
                cmp.w   d1,d0
                bcc.b   L_4A824
                addq.w  #$1,$36(a0)
L_4A824:
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4A830
                jmp     (jt_ObjKillSelf).w
L_4A830:
                rts
L_4A832:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
L_4A83C:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a2),$38(a0)
                move.w  $8(a2),$3A(a0)
                bsr.w   L_4A984
                move.b  #$1,$4(a0)
                jmp     (jt_ObjInsert).w
L_4A866:
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4A872
                jmp     (jt_ObjKillSelf).w
L_4A872:
                tst.b   $36(a0)
                beq.b   L_4A890
                cmpi.b  #$1,$36(a0)
                beq.b   L_4A8BE
                subq.w  #$1,$A(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4A8F4
                bsr.w   L_4A912
                rts
L_4A890:
                bsr.w   L_4A984
                movem.w $A(a0),d0-d1
                add.w   #$B,d1
                tst.w   $32(a0)
                bpl.b   L_4A8AA
                sub.w   #$10,d0
                bra.b   L_4A8AE
L_4A8AA:
                add.w   #$21,d0
L_4A8AE:
                jsr     (jt_GetMapCell).w
                bne.b   L_4A8FA
                move.w  $32(a0),d0
                add.w   d0,$A(a0)
                rts
L_4A8BE:
                subq.w  #$1,$A(a0)
                subq.w  #$1,$34(a0)
                bmi.b   L_4A8CA
                rts
L_4A8CA:
                move.w  #$A,$34(a0)
                subq.b  #$1,$37(a0)
                bpl.b   L_4A8F6
                bsr.w   L_4A984
                move.l  #D_4BAE6,d0
                sub.l   $2A(a0),d0
                move.w  d0,$1E(a0)
                move.b  #$2,$36(a0)
                move.b  #$A,$37(a0)
L_4A8F4:
                rts
L_4A8F6:
                bra.w   L_4A9E2
L_4A8FA:
                move.b  #$2,$36(a0)
                move.b  #$14,$37(a0)
                clr.b   $22(a0)
                move.w  #$3,$1E(a0)
                rts
L_4A912:
                bsr.w   L_4A958
                cmp.w   #$37,d0
                blt.b   L_4A984
                cmp.w   #$55,d0
                bgt.b   L_4A984
                bsr.w   L_4A984
                move.b  #$1,$36(a0)
                move.b  $3B(a0),$37(a0)
                move.w  $38(a0),$34(a0)
                st.b    $22(a0)
                move.l  #D_4BADE,$2A(a0)
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                bsr.w   L_4A958
                move.w  d2,$3C(a0)
                rts
L_4A958:
                moveq   #1,d2
                move.w  (ShipPos).w,d0
                sub.w   $A(a0),d0
                bpl.b   L_4A96C
                neg.w   d0
                neg.w   d2
                add.w   #$1E,d0
L_4A96C:
                rts
L_4A96E:
                moveq   #1,d2
                move.w  ($F0).w,d0
                sub.w   #$1F,d0
                sub.w   $C(a0),d0
                bpl.b   L_4A982
                neg.w   d0
                neg.w   d2
L_4A982:
                rts
L_4A984:
                bsr.b   L_4A958
                cmp.w   #$3C,d0
                blt.b   L_4A994
                cmp.w   #$50,d0
                bcs.w   L_4A8FA
L_4A994:
                clr.b   $36(a0)
                moveq   #70,d1
                sub.w   d0,d1
                bpl.b   L_4A9B0
                move.w  #$FFFE,$32(a0)
                tst.w   d2
                bmi.b   L_4A9AE
                move.w  #$2,$32(a0)
L_4A9AE:
                bra.b   L_4A9C0
L_4A9B0:
                move.w  #$2,$32(a0)
                tst.w   d2
                bmi.b   L_4A9C0
                move.w  #$FFFE,$32(a0)
L_4A9C0:
                move.b  #$0,$36(a0)
                lea.l   (D_4BAD0).l,a1
                tst.w   $32(a0)
                bmi.b   L_4A9D8
                lea.l   (D_4BAD7).l,a1
L_4A9D8:
                move.l  a1,$2A(a0)
                st.b    $22(a0)
                rts
L_4A9E2:
                movea.l a0,a4
                movem.w $A(a0),d0-d1
                moveq   #1,d2
                subq.w  #$8,d1
                add.w   #$14,d0
                lea.l   (D_4BB64).l,a2
                jsr     (jt_ObjCreate).w
                bsr.w   L_4A96E
                lsr.w   #$3,d0
                moveq   #16,d1
                move.w  d0,-(a7)
                moveq   #15,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   L_4AA14
                clr.w   d1
L_4AA14:
                move.w  d1,$32(a0)
                bsr.w   L_4A958
                lsr.w   #$3,d0
                moveq   #19,d1
                move.w  d0,-(a7)
                moveq   #10,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   L_4AA30
                clr.w   d1
L_4AA30:
                move.w  d1,$34(a0)
                move.w  $3C(a4),$36(a0)
                clr.b   $22(a0)
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                rts
L_4AA4C:
                lea.l   ($7912E).l,a3
                lea.l   ($790D0).l,a1
                lea.l   ($7918C).l,a2
                movem.w $32(a0),d0-d2
                move.b  (a3,d0.w),d3
                cmp.b   #$7F,d3
                beq.b   L_4AAE0
                neg.b   d3
                move.b  (a1,d1.w),d4
                bne.b   L_4AA78
                addq.b  #$1,d4
L_4AA78:
                cmp.b   #$7F,d4
                beq.b   L_4AAE0
                addq.w  #$1,$32(a0)
                addq.w  #$1,$34(a0)
                ext.w   d3
                ext.w   d4
                asl.w   #$1,d4
                tst.w   d2
                bpl.b   L_4AA92
                neg.w   d4
L_4AA92:
                add.w   d3,$C(a0)
                add.w   d4,$A(a0)
                cmpi.w  #$20,$A(a0)
                bcs.b   L_4AABA
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4AABE
                cmpi.w  #$E0,$C(a0)
                bhi.b   L_4AABA
                cmpi.w  #$10,$C(a0)
                bhi.b   L_4AABE
L_4AABA:
                jmp     (jt_ObjKillSelf).w
L_4AABE:
                move.b  (a2,d0.w),d3
                ext.w   d3
                tst.w   d2
                bpl.b   L_4AACC
                add.w   #$9,d3
L_4AACC:
                move.w  d3,$1E(a0)
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                addq.w  #$6,d1
                jsr     (jt_GetMapCell).w
                beq.b   L_4AAEA
L_4AAE0:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
L_4AAEA:
                rts
L_4AAEC:
                lea.l   (D_4BC38).l,a4
                bra.b   L_4AAFA
L_4AAF4:
                lea.l   (D_4BC20).l,a4
L_4AAFA:
                moveq   #19,d7
                sub.w   d2,d7
                move.w  (ShipPos).w,d6
                sub.w   #$30,d6
                lsr.w   #$4,d6
                sub.w   d6,d7
                moveq   #0,d6
                tst.w   d7
                bmi.b   L_4AB18
                subq.w  #$3,d7
                bpl.b   L_4AB20
                addq.w  #$8,d6
                bra.b   L_4AB20
L_4AB18:
                addq.w  #$8,d6
                addq.w  #$3,d7
                bpl.b   L_4AB20
                addq.w  #$8,d6
L_4AB20:
                move.w  d1,d7
                lsr.w   #$8,d7
                and.w   #$F,d7
                btst    #$D,d1
                bne.b   L_4AB52
                btst.b  #$5,(a0)
                bne.b   L_4AB52
                movem.l d4-d6,-(a7)
                move.w  $4(a4,d6.w),d4
                move.w  $6(a4,d6.w),d5
                bsr.w   L_4AB96
                movem.l (a7)+,d4-d6
                move.w  (a4,d6.w),d1
                move.w  $2(a4,d6.w),(a0)
                rts
L_4AB52:
                clr.w   -$2(a0)
                clr.w   (a0)
                moveq   #0,d1
                movem.l d0-d2/a0-a2,-(a7)
                moveq   #19,d0
                sub.w   d2,d0
                lsl.w   #$4,d0
                add.w   #$28,d0
                moveq   #12,d1
                sub.w   d3,d1
                lsl.w   #$4,d1
                add.w   #$1C,d1
                moveq   #0,d2
                jsr     (jt_ObjAlloc).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                move.l  #$100,d0
                jsr     (jt_AddScore).w
                movem.l (a7)+,d0-d2/a0-a2
                rts
L_4AB96:
                move.w  d1,d6
                and.w   #$F00,d6
                bne.b   L_4ABB4
                move.w  d1,d6
                and.w   #$F0,d6
                beq.b   L_4ABBC
                ori.w   #$F00,-$2(a0)
                subi.w  #$10,-$2(a0)
                rts
L_4ABB4:
                subi.w  #$100,-$2(a0)
                rts
L_4ABBC:
                move.w  d1,d6
                and.w   #$F00F,d6
                or.w    #$AA0,d6
                move.w  d6,-$2(a0)
                moveq   #21,d6
                sub.w   d2,d6
                lsl.w   #$4,d6
                moveq   #13,d7
                sub.w   d3,d7
                lsl.w   #$4,d7
                add.w   d4,d6
                add.w   d5,d7
                movem.l d0-d3/a1-a2,-(a7)
                move.w  d6,d0
                move.w  d7,d1
                addq.w  #$8,d0
                addq.w  #$8,d1
                jsr     (jt_FireEnemyBullet).w
                movem.l (a7)+,d0-d3/a1-a2
                rts
L_4ABF0:
                movem.w $2(a1),d0-d1
                move.w  $8(a2),d2
                moveq   #30,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$2,$21(a0)
                clr.w   $3A(a0)
                move.w  #$7D,$3C(a0)
                bsr.w   L_4AD06
                jmp     (jt_ObjInsert).w
L_4AC1C:
                tst.b   $39(a0)
                beq.b   L_4AC32
                cmpi.b  #$1,$39(a0)
                beq.b   L_4AC5C
                subq.b  #$1,$3A(a0)
                bmi.b   L_4AC96
                rts
L_4AC32:
                move.w  $C(a0),d1
                tst.w   $34(a0)
                bmi.b   L_4AC54
                cmp.w   $36(a0),d1
                bgt.b   L_4AC80
L_4AC42:
                movem.w $32(a0),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                bra.w   L_4ADCC
L_4AC54:
                cmp.w   $36(a0),d1
                blt.b   L_4AC80
                bra.b   L_4AC42
L_4AC5C:
                move.w  $A(a0),d1
                tst.w   $32(a0)
                bmi.b   L_4AC78
                cmp.w   $36(a0),d1
                bgt.b   L_4AC80
L_4AC6C:
                move.w  $32(a0),d0
                add.w   d0,$A(a0)
                bra.w   L_4ADCC
L_4AC78:
                cmp.w   $36(a0),d1
                blt.b   L_4AC80
                bra.b   L_4AC6C
L_4AC80:
                move.b  #$2,$39(a0)
                moveq   #25,d0
                jsr     (jt_Random).w
                move.b  d0,$3A(a0)
                clr.w   $1E(a0)
                rts
L_4AC96:
                subq.b  #$1,$38(a0)
                bpl.b   L_4AD06
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
                move.l  #D_4BD6E,$2A(a0)
                move.l  #L_4ADE2,$6(a0)
                move.l  #D_4BD46,$12(a0)
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
L_4AD06:
                move.w  ($F0).w,d0
                sub.w   #$F,d0
                move.w  d0,d1
                add.w   #$14,d1
                cmp.w   $C(a0),d0
                bgt.b   L_4AD5E
                cmp.w   $C(a0),d1
                blt.b   L_4AD5E
                clr.w   $34(a0)
                moveq   #50,d0
                jsr     (jt_Random).w
                move.w  d0,d2
                tst.b   $3B(a0)
                bmi.b   L_4AD3E
                move.w  $A(a0),d1
                add.w   d2,d1
                cmp.w   #$122,d1
                ble.b   L_4AD42
L_4AD3E:
                moveq   #-2,d0
                bra.b   L_4AD46
L_4AD42:
                bsr.w   L_4ADBE
L_4AD46:
                tst.w   d0
                bpl.b   L_4AD4C
                neg.w   d2
L_4AD4C:
                add.w   $A(a0),d2
                move.w  d2,$36(a0)
                move.b  #$1,$39(a0)
                bra.w   L_4ADAA
L_4AD5E:
                clr.b   $39(a0)
                move.w  ($F0).w,d2
                sub.w   #$1E,d2
                moveq   #59,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                cmp.w   #$B1,d2
                blt.b   L_4AD7C
                move.w  #$B0,d2
L_4AD7C:
                move.w  d2,$36(a0)
                moveq   #2,d0
                sub.w   $C(a0),d2
                bpl.b   L_4AD8C
                neg.w   d0
                neg.w   d2
L_4AD8C:
                move.w  d0,$34(a0)
                move.w  $A(a0),d0
                add.w   d2,d0
                tst.b   $3B(a0)
                bmi.b   L_4ADA2
                cmp.w   #$122,d0
                ble.b   L_4ADA6
L_4ADA2:
                moveq   #-2,d0
                bra.b   L_4ADAA
L_4ADA6:
                bsr.w   L_4ADBE
L_4ADAA:
                move.w  #$1,$1E(a0)
                move.w  d0,$32(a0)
                bpl.b   L_4ADBC
                move.w  #$2,$1E(a0)
L_4ADBC:
                rts
L_4ADBE:
                moveq   #1,d0
                jsr     (jt_Random).w
                asl.w   #$1,d0
                addq.w  #$1,d0
                asl.w   #$1,d0
                rts
L_4ADCC:
                subq.w  #$1,$3C(a0)
                bpl.b   L_4ADD6
                st.b    $3B(a0)
L_4ADD6:
                tst.w   $A(a0)
                bpl.b   L_4ADE0
                jmp     (jt_ObjKillSelf).w
L_4ADE0:
                rts
L_4ADE2:
                subq.w  #$8,$A(a0)
                tst.w   $A(a0)
                bpl.b   L_4ADE0
                jmp     (jt_ObjKillSelf).w
L_4ADF0:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.l  #D_4BDB4,$2A(a0)
                move.w  $6(a1),$32(a0)
                bpl.b   L_4AE18
                move.l  #D_4BDAA,$2A(a0)
L_4AE18:
                move.w  $32(a0),d2
                bsr.w   L_4AEC8
                move.w  #$200,$34(a0)
                clr.w   $1E(a0)
                bsr.w   L_4AF32
                jmp     (jt_ObjInsert).w
L_4AE32:
                cmpi.w  #$10,$A(a0)
                bcs.b   L_4AE4A
                cmpi.w  #$170,$A(a0)
                bhi.b   L_4AE4A
                cmpi.w  #$E0,$C(a0)
                bcs.b   L_4AE4E
L_4AE4A:
                jmp     (jt_ObjKillSelf).w
L_4AE4E:
                move.b  $34(a0),d0
                beq.b   L_4AE9A
                cmp.b   #$1,d0
                beq.w   L_4AEFC
                cmp.b   #$2,d0
                beq.w   L_4AF32
                subq.w  #$1,$A(a0)
                subq.b  #$1,$35(a0)
                bmi.b   L_4AE80
                rts
L_4AE70:
                st.b    $34(a0)
                clr.b   $22(a0)
                move.l  #D_4BDAA,$2A(a0)
L_4AE80:
                move.b  #$A,$35(a0)
                bsr.w   L_4A958
                move.w  #$B,$1E(a0)
                tst.w   d2
                bpl.b   L_4AE98
                clr.w   $1E(a0)
L_4AE98:
                rts
L_4AE9A:
                move.w  $32(a0),d2
                movem.w $A(a0),d0-d1
                add.w   #$C,d1
                subq.w  #$3,d0
                tst.w   d2
                bmi.b   L_4AEB2
                add.w   #$23,d0
L_4AEB2:
                jsr     (jt_GetMapCell).w
                bne.b   L_4AE70
                adda.l  (MapRowBytes).w,a4
                btst.b  #$7,(a4)
                beq.b   L_4AEC8
                add.w   d2,$A(a0)
                rts
L_4AEC8:
                move.b  #$1,$34(a0)
                clr.w   $36(a0)
                move.w  #$23,$38(a0)
                move.l  #D_4BDB9,$2A(a0)
                tst.w   d2
                bpl.b   L_4AEEC
                move.l  #D_4BDAF,$2A(a0)
L_4AEEC:
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                st.b    $22(a0)
                rts
L_4AEFC:
                lea.l   (D_4BE1E).l,a2
                move.w  $36(a0),d0
                moveq   #3,d2
                move.b  (a2,d0.w),d3
                cmp.b   #$7F,d3
                bne.b   L_4AF1A
                move.b  #$2,$34(a0)
                bra.b   L_4AF32
L_4AF1A:
                ext.w   d3
                tst.w   $32(a0)
                bpl.b   L_4AF24
                neg.w   d2
L_4AF24:
                add.w   d2,$A(a0)
                add.w   d3,$C(a0)
                addq.w  #$1,$36(a0)
                rts
L_4AF32:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                addq.w  #$8,d0
                add.w   #$1A,d1
                jsr     (jt_GetMapCell).w
                bne.b   L_4AF4E
                addq.w  #$4,$C(a0)
                rts
L_4AF4E:
                clr.w   $34(a0)
                move.l  #D_4BDB4,$2A(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.w   $32(a0)
                bpl.b   L_4AF70
                move.l  #D_4BDAA,$2A(a0)
L_4AF70:
                rts
L_4AF72:
                movea.l $A(a1),a3
                move.w  $8(a1),d7
                clr.w   d6
L_4AF7C:
                move.w  (a3)+,d0
                bmi.b   L_4AFA0
                move.w  (a3)+,d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)
                clr.w   $38(a0)
                move.w  d6,$32(a0)
                add.w   d7,d6
                jsr     (jt_ObjInsert).w
                bra.b   L_4AF7C
L_4AFA0:
                rts
L_4AFA2:
                tst.w   $32(a0)
                beq.b   L_4AFAE
                subq.w  #$1,$32(a0)
                rts
L_4AFAE:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   L_4AFD0
                cmp.w   #$170,d0
                bhi.b   L_4AFD0
                cmp.w   #$10,d1
                bcs.b   L_4AFD0
                cmp.w   #$E0,d1
                bcs.b   L_4AFD4
L_4AFD0:
                jmp     (jt_ObjKillSelf).w
L_4AFD4:
                move.w  $3A(a0),d4
                cmp.w   (ScrollX).w,d4
                bhi.b   L_4AFEE
                moveq   #10,d7
                cmp.w   #$88,d1
                bcs.b   L_4AFEA
                move.w  #$E0,d7
L_4AFEA:
                moveq   #4,d6
                bra.b   L_4AFFA
L_4AFEE:
                subq.w  #$1,$38(a0)
                bpl.b   L_4B038
                movem.w (ShipPos).w,d6-d7
L_4AFFA:
                moveq   #2,d4
                lea.l   (D_4BEC8).l,a1
                cmp.w   d6,d0
                bcs.b   L_4B00E
                moveq   #-1,d4
                lea.l   (D_4BECC).l,a1
L_4B00E:
                move.l  a1,$2A(a0)
                moveq   #1,d5
                cmp.w   d7,d1
                bcs.b   L_4B01A
                neg.w   d5
L_4B01A:
                move.w  d0,d2
                sub.w   d6,d2
                bpl.b   L_4B022
                neg.w   d2
L_4B022:
                lsr.w   #$1,d2
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)
                move.b  d4,$36(a0)
                move.b  d5,$37(a0)
L_4B038:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6
                ext.w   d6
                bpl.b   L_4B04E
                subq.w  #$2,d1
                bra.b   L_4B052
L_4B04E:
                add.w   #$20,d1
L_4B052:
                addq.w  #$8,d0
                jsr     (jt_GetMapCell).w
                bne.b   L_4B05E
                add.w   d6,$C(a0)
L_4B05E:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1
                move.b  $36(a0),d4
                ext.w   d4
                bpl.b   L_4B070
                subq.w  #$2,d0
                bra.b   L_4B074
L_4B070:
                add.w   #$22,d0
L_4B074:
                jsr     (jt_GetMapCell).w
                bne.b   L_4B07E
                add.w   d4,$A(a0)
L_4B07E:
                rts
L_4B080:
                move.w  #$260,(D_4BF00).l
                clr.w   (D_4BF02).l
                moveq   #24,d5
                moveq   #0,d6
                moveq   #11,d7
L_4B094:
                move.w  #$170,d0
                move.w  #$34,d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                clr.w   $32(a0)
                move.w  d6,$34(a0)
                move.w  d5,$38(a0)
                clr.b   $36(a0)
                subq.w  #$2,d5
                add.w   #$14,d6
                cmp.w   #$3,d7
                bne.b   L_4B0CE
                move.l  #D_4BF37,$2A(a0)
                st.b    $36(a0)
L_4B0CE:
                jsr     (jt_ObjInsert).w
                dbra    d7,L_4B094
                rts
L_4B0D8:
                tst.b   (D_4BF03).l
                bpl.b   L_4B0E4
                jmp     (jt_ObjKillSelf).w
L_4B0E4:
                tst.b   (D_4BF02).l
                bmi.b   L_4B120
                move.w  (ShipPos).w,d0
                sub.w   (D_4BF00).l,d0
                bpl.b   L_4B0FA
                neg.w   d0
L_4B0FA:
                cmp.w   #$46,d0
                bcs.b   L_4B106
                clr.w   $2E(a0)
                bra.b   L_4B120
L_4B106:
                tst.w   $2E(a0)
                bne.b   L_4B120
                move.w  #$AF,d0
                jsr     (jt_Random).w
                add.w   #$19,d0
                move.w  d0,$2E(a0)
                move.w  d0,$30(a0)
L_4B120:
                tst.w   $34(a0)
                bmi.b   L_4B138
                subq.w  #$1,$34(a0)
                bpl.b   L_4B134
                st.b    $22(a0)
                clr.b   $20(a0)
L_4B134:
                bra.w   L_4B1C0
L_4B138:
                lea.l   ($792D1).l,a1
                lea.l   $127(a1),a2
L_4B142:
                move.w  $32(a0),d2
                move.b  (a1,d2.w),d0
                move.b  (a2,d2.w),d1
                cmp.b   #$7F,d1
                bne.b   L_4B15A
                clr.w   $32(a0)
                bra.b   L_4B142
L_4B15A:
                ext.w   d0
                ext.w   d1
                addq.w  #$1,$32(a0)
                add.w   #$73,d1
                add.w   (D_4BF00).l,d0
                movem.w d0-d1,$A(a0)
                tst.b   (D_4BF02).l
                bpl.b   L_4B1C0
                subq.w  #$1,$38(a0)
                bpl.b   L_4B1C0
                move.w  #$7FFF,$38(a0)
                move.l  a0,-(a7)
                moveq   #-1,d2
                jsr     (jt_ObjAlloc).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.b  #$A,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                move.l  #$200,d0
                jsr     (jt_AddScore).w
                clr.w   $2E(a0)
                clr.b   $22(a0)
                move.w  #$9,$1E(a0)
                clr.b   $20(a0)
L_4B1C0:
                tst.b   $36(a0)
                bpl.b   L_4B1EC
                subq.w  #$1,(D_4BF00).l
                cmpi.w  #$FFB7,(D_4BF00).l
                beq.b   L_4B1F4
                cmpi.w  #$5,$1E(a0)
                blt.b   L_4B1EE
                cmpi.w  #$6,$26(a0)
                blt.b   L_4B1EC
                st.b    (D_4BF02).l
L_4B1EC:
                rts
L_4B1EE:
                clr.w   $26(a0)
                rts
L_4B1F4:
                st.b    (D_4BF03).l
                rts
L_4B1FC:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.b  #$2,$21(a0)
                move.b  #$1,$4(a0)
                clr.w   $32(a0)
                clr.w   $34(a0)
                move.w  #$64,$36(a0)
                clr.w   $3C(a0)
                jmp     (jt_ObjInsert).w
L_4B22E:
                bsr.w   L_4B346
                tst.w   $A(a0)
                bpl.b   L_4B23C
                jmp     (jt_ObjKillSelf).w
L_4B23C:
                tst.w   $34(a0)
                bmi.b   L_4B254
                subq.w  #$1,$34(a0)
                cmpi.b  #$1,$32(a0)
                bne.b   L_4B252
                subq.w  #$1,$A(a0)
L_4B252:
                rts
L_4B254:
                move.b  $32(a0),d0
                beq.b   L_4B276
                cmp.b   #$1,d0
                beq.b   L_4B2B8
                cmp.b   #$2,d0
                beq.w   L_4B2E8
                cmp.b   #$3,d0
                beq.w   L_4B30C
                subq.w  #$1,$A(a0)
                rts
L_4B276:
                movem.w $A(a0),d0-d1
                add.w   #$22,d1
                subq.w  #$6,d0
                jsr     (jt_GetMapCell).w
                bne.b   L_4B298
                tst.w   $36(a0)
                bmi.b   L_4B298
                subq.w  #$1,$36(a0)
                subq.w  #$3,$A(a0)
                rts
L_4B298:
                move.b  #$1,$32(a0)
                move.w  #$32,$34(a0)
                move.w  #$1B,$36(a0)
                clr.w   $1E(a0)
                clr.b   $22(a0)
                clr.b   $20(a0)
                rts
L_4B2B8:
                move.l  #D_4BFFB,$2A(a0)
                st.b    $22(a0)
                tst.w   $36(a0)
                bmi.b   L_4B2D4
                subq.w  #$1,$36(a0)
                subq.w  #$2,$C(a0)
                rts
L_4B2D4:
                move.b  #$2,$32(a0)
                move.w  #$32,$34(a0)
                move.w  #$41,$36(a0)
                rts
L_4B2E8:
                tst.w   $36(a0)
                bmi.b   L_4B2F8
                subq.w  #$1,$36(a0)
                addq.w  #$2,$A(a0)
                rts
L_4B2F8:
                move.b  #$3,$32(a0)
                move.w  #$14,$34(a0)
                move.w  #$28,$36(a0)
                rts
L_4B30C:
                movem.w $A(a0),d0-d1
                add.w   #$2C,d1
                add.w   #$16,d0
                jsr     (jt_GetMapCell).w
                bne.b   L_4B32A
                addq.w  #$2,$C(a0)
                addq.w  #$1,$A(a0)
                rts
L_4B32A:
                move.b  #$4,$32(a0)
                move.l  #D_4BFF2,$2A(a0)
                clr.w   $1E(a0)
                clr.b   $22(a0)
                clr.b   $20(a0)
                rts
L_4B346:
                bsr.b   L_4B398
                tst.b   $3C(a0)
                beq.b   L_4B352
                subq.b  #$1,$3C(a0)
L_4B352:
                move.w  $C(a0),d0
                addq.w  #$8,d0
                move.w  d0,d1
                sub.w   ($F0).w,d0
                bpl.b   L_4B362
                neg.w   d0
L_4B362:
                cmp.w   #$12,d0
                bhi.b   L_4B396
                tst.b   $3C(a0)
                bne.b   L_4B396
                move.l  a0,-(a7)
                move.w  $A(a0),d0
                moveq   #1,d2
                lea.l   (D_4C036).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$21(a0)
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                move.b  #$12,$3C(a0)
L_4B396:
                rts
L_4B398:
                subq.b  #$1,$3D(a0)
                bmi.b   L_4B3A0
                rts
L_4B3A0:
                move.b  #$73,$3D(a0)
                move.l  a0,-(a7)
                movem.w $A(a0),d0-d1
                add.w   #$F,d0
                add.w   #$A,d1
                moveq   #1,d2
                moveq   #3,d7
                lea.l   (D_4C122).l,a4
                lea.l   (D_4C068).l,a2
L_4B3C6:
                jsr     (jt_ObjCreate).w
                move.b  #$1,$21(a0)
                clr.b   $22(a0)
                move.w  (a4)+,$1E(a0)
                move.w  #$16,$36(a0)
                move.w  #$5,$34(a0)
                jsr     (jt_ObjInsert).w
                dbra    d7,L_4B3C6
                movea.l (a7)+,a0
                rts
L_4B3F0:
                subq.w  #$1,$34(a0)
                bpl.b   L_4B434
                move.w  #$5,$34(a0)
                tst.w   $36(a0)
                beq.b   L_4B434
                subq.w  #$1,$36(a0)
                movem.w $A(a0),d0-d1
                movem.w d0-d1,-(a7)
                addq.w  #$8,d0
                addq.w  #$8,d1
                jsr     (jt_GetMapCell).w
                movem.w (a7)+,d0-d1
                bne.b   L_4B474
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  $1E(a0),d1
                jsr     (jt_TurnTowards).w
                move.w  d1,$1E(a0)
L_4B434:
                move.w  $1E(a0),d0
                lsl.w   #$2,d0
                movem.w $A(a0),d1-d2
                lea.l   (D_4C12A).l,a1
                add.w   (a1,d0.w),d1
                add.w   $2(a1,d0.w),d2
                cmp.w   #$10,d1
                bcs.b   L_4B466
                cmp.w   #$170,d1
                bhi.b   L_4B466
                cmp.w   #$10,d2
                bcs.b   L_4B466
                cmp.w   #$E0,d2
                bcs.b   L_4B46A
L_4B466:
                jmp     (jt_ObjKillSelf).w
L_4B46A:
                move.w  d1,$A(a0)
                move.w  d2,$C(a0)
                rts
L_4B474:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                rts
L_4B480:
                movem.w $A(a0),d0-d1
                sub.w   #$10,d0
                subq.w  #$4,d1
                jsr     (jt_GetMapCell).w
                bne.w   L_4B4A6
                subq.w  #$6,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4B4A4
                jmp     (jt_ObjKillSelf).w
L_4B4A4:
                rts
L_4B4A6:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                rts
LevelInit:
                clr.b   (D_4C1BE).l
                clr.b   (D_4C1BC).l
                clr.b   (D_4C1BD).l
                clr.b   (D_4C1BF).l
                clr.b   (D_4C1C0).l
                clr.b   (D_4C1C1).l
                move.w  #$4E2,(D_4C16A).l
                rts
LevelFrame:
                cmpi.w  #$D3E,(ScrollX).w
                bcs.w   L_4B5B6
                tst.b   (D_4C1BE).l
                beq.b   L_4B53E
                subq.b  #$1,(D_4C1BD).l
                bpl.b   L_4B53E
                move.b  #$A,(D_4C1BD).l
                moveq   #0,d4
                move.b  (D_4C1BC).l,d4
                lea.l   (D_4C16C).l,a0
                movea.l (a0,d4.w),a0
                lea.l   ($5BB5E).l,a1
                bsr.w   L_4B5B8
                addq.b  #$4,d4
                move.b  d4,(D_4C1BC).l
                cmp.b   #$C,d4
                bls.b   L_4B53E
                clr.b   (D_4C1BE).l
                clr.b   (D_4C1BC).l
                clr.b   (D_4C1BD).l
L_4B53E:
                subq.b  #$1,(D_4C1C0).l
                bne.b   L_4B57E
                move.b  #$4B,(D_4C1C0).l
                moveq   #0,d4
                move.b  (D_4C1C1).l,d4
                lea.l   (D_4C194).l,a0
                movea.l (a0,d4.w),a0
                lea.l   ($5B72A).l,a1
                bsr.w   L_4B5B8
                addq.b  #$4,d4
                move.b  d4,(D_4C1C1).l
                cmp.b   #$C,d4
                bls.b   L_4B57E
                clr.b   (D_4C1C1).l
L_4B57E:
                tst.b   (D_4C1BF).l
                beq.b   L_4B598
                cmpi.w  #$F39,(ScrollX).w
                bcs.b   L_4B5B6
                clr.b   (ScrollActive).w
                st.b    (LevelComplete).w
                rts
L_4B598:
                cmpi.w  #$E5D,(ScrollX).w
                bcs.b   L_4B5B6
                clr.b   (ScrollActive).w
                subq.w  #$1,(D_4C16A).l
                bpl.b   L_4B5B6
                st.b    (D_4C1BF).l
                st.b    (ScrollActive).w
L_4B5B6:
                rts
L_4B5B8:
                move.l  (a0)+,(a1)
                adda.l  (MapRowBytes).w,a1
                move.l  (a0),(a1)
                rts
L_4B5C2:
                move.w  #$12C,(D_4C1C2).l
                clr.b   (D_4C2DA).l
                clr.w   (D_4C1C6).l
                clr.w   (D_4C1C8).l
                clr.w   (D_4C1C4).l
                moveq   #15,d7
                moveq   #0,d6
                moveq   #0,d5
L_4B5E8:
                move.w  #$190,d0
                moveq   #5,d1
                moveq   #-1,d2
                movem.w d5-d7,-(a7)
                jsr     (jt_ObjCreate).w
                move.w  d6,$32(a0)
                clr.w   $34(a0)
                move.w  d5,$36(a0)
                move.w  #$5,$1E(a0)
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                movem.w (a7)+,d5-d7
                addq.w  #$2,d6
                addq.w  #$1,d5
                dbra    d7,L_4B5E8
                st.b    $34(a0)
                movea.l (ScoreToAddEnd).w,a1
                move.w  #$90,$16(a1)
                st.b    (MusicFadeReq).w
                rts
L_4B632:
                tst.b   (D_4C1C4).l
                bpl.b   L_4B652
                tst.w   $36(a0)
                bpl.b   L_4B64C
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                rts
L_4B64C:
                subq.w  #$1,$36(a0)
                rts
L_4B652:
                tst.b   (D_4C2DA).l
                beq.b   L_4B660
                bset.b  #$0,$23(a0)
L_4B660:
                lea.l   ($78AB8).l,a1
                move.w  (D_4C1C6).l,d0
                lsl.w   #$5,d0
                add.w   $32(a0),d0
                move.b  (a1,d0.w),d2
                move.b  $1(a1,d0.w),d3
                and.w   #$FF,d2
                and.w   #$FF,d3
                add.w   (D_4C1C2).l,d2
                sub.w   #$A,d3
                movem.w d2-d3,$A(a0)
                tst.b   $34(a0)
                bmi.b   L_4B69A
                rts
L_4B69A:
                tst.b   (ScrollActive).w
                beq.b   L_4B6A6
                subq.w  #$1,(D_4C1C2).l
L_4B6A6:
                subq.w  #$1,(D_4C1C8).l
                bpl.b   L_4B6CC
                move.w  #$1,(D_4C1C8).l
                addq.w  #$1,(D_4C1C6).l
                cmpi.w  #$28,(D_4C1C6).l
                blt.b   L_4B6CC
                clr.w   (D_4C1C6).l
L_4B6CC:
                lea.l   ($78AB8).l,a1
                move.w  (D_4C1C6).l,d0
                lsl.w   #$5,d0
                add.w   $32(a0),d0
                move.b  (a1,d0.w),d2
                move.b  $1(a1,d0.w),d3
                and.w   #$FF,d2
                and.w   #$FF,d3
                add.w   (D_4C1C2).l,d2
                sub.w   #$A,d3
                movem.w d2-d3,$A(a0)
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                and.w   #$7,d0
                lsr.w   #$1,d0
                move.w  d0,$1E(a0)
                rts
L_4B71A:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.w  #$3F,$32(a0)
                clr.w   $34(a0)
                clr.w   $36(a0)
                jmp     (jt_ObjInsert).w
L_4B73C:
                tst.b   (ScrollActive).w
                beq.b   L_4B746
                subq.w  #$1,$A(a0)
L_4B746:
                tst.b   (D_4C1C4).l
                bne.w   L_4B81E
                subq.w  #$1,$32(a0)
                bpl.b   L_4B7CC
                move.w  #$3F,$32(a0)
                move.l  a0,-(a7)
                moveq   #4,d7
                moveq   #1,d5
                movem.w $A(a0),d3-d4
                sub.w   #$14,d3
                move.w  d4,d1
                move.w  #$170,d0
                move.w  ($F0).w,d2
                moveq   #-1,d6
                cmp.w   #$64,d2
                bcs.b   L_4B788
                moveq   #0,d6
                cmp.w   #$9D,d2
                bcs.b   L_4B788
                moveq   #1,d6
L_4B788:
                moveq   #-1,d2
                lea.l   (D_4C26C).l,a2
                moveq   #0,d4
L_4B792:
                jsr     (jt_ObjCreate).w
                move.w  d3,$38(a0)
                move.w  d6,$32(a0)
                move.w  d5,$34(a0)
                clr.w   $36(a0)
                addq.w  #$3,d5
                move.w  d4,$1E(a0)
                addq.w  #$2,d4
                cmp.w   #$7,d4
                bls.b   L_4B7B6
                clr.w   d4
L_4B7B6:
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                dbra    d7,L_4B792
                movea.l (a7)+,a0
                st.b    (D_4C1BE).l
L_4B7CC:
                clr.b   (D_4C2DA).l
                move.w  $26(a0),d0
                cmp.w   $34(a0),d0
                beq.b   L_4B7E6
                move.w  d0,$34(a0)
                st.b    (D_4C2DA).l
L_4B7E6:
                cmpi.w  #$14,$26(a0)
                bcs.b   L_4B800
                cmpi.w  #$32,(D_4C16A).l
                bls.b   L_4B800
                move.w  #$32,(D_4C16A).l
L_4B800:
                cmpi.w  #$1E,$26(a0)
                bcs.b   L_4B81C
                st.b    (D_4C1C4).l
                st.b    (LevelComplete).w
                move.l  #$6200,d0
                jmp     (jt_AddScore).w
L_4B81C:
                rts
L_4B81E:
                subq.w  #$1,$36(a0)
                bpl.b   L_4B872
                move.w  #$1,$36(a0)
                move.l  a0,-(a7)
                moveq   #2,d0
                jsr     (jt_Random).w
                move.w  d0,d7
                beq.b   L_4B838
                addq.w  #$1,d7
L_4B838:
                move.w  #$82,d0
                jsr     (jt_Random).w
                sub.w   #$55,d0
                move.w  d0,d1
                add.w   $C(a0),d1
                moveq   #50,d0
                jsr     (jt_Random).w
                sub.w   #$32,d0
                add.w   $A(a0),d0
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  d7,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
L_4B872:
                rts
L_4B874:
                tst.b   (D_4C1C4).l
                beq.b   L_4B886
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
L_4B886:
                tst.w   $34(a0)
                beq.b   L_4B89A
                subq.w  #$1,$34(a0)
                bne.b   L_4B898
                move.w  $38(a0),$A(a0)
L_4B898:
                rts
L_4B89A:
                move.w  $32(a0),d1
                beq.b   L_4B8D2
                lea.l   ($79607).l,a1
                move.w  $36(a0),d2
                move.b  (a1,d2.w),d3
                move.b  $2A(a1,d2.w),d4
                ext.w   d3
                ext.w   d4
                tst.w   d1
                bmi.b   L_4B8BC
                neg.w   d4
L_4B8BC:
                add.w   d3,$A(a0)
                add.w   d4,$C(a0)
                cmpi.w  #$29,$36(a0)
                bcc.b   L_4B8D6
                addq.w  #$1,$36(a0)
                bra.b   L_4B8D6
L_4B8D2:
                subq.w  #$6,$A(a0)
L_4B8D6:
                cmpi.w  #$10,$A(a0)
                bhi.b   L_4B8E2
                jmp     (jt_ObjKillSelf).w
L_4B8E2:
                rts
                dc.w    $003A,$0000,$0032,$0800,$0052,$1300,$003A,$1D00
                dc.w    $FFFF,$008C,$0000,$00A4,$0900,$0088,$1200,$0074
                dc.w    $1D00,$FFFF,$0089,$0000,$007F,$0600,$008C,$0D00
                dc.w    $FFFF,$007A,$0000,$0057,$0500,$0032,$0C00,$0031
                dc.w    $1200,$FFFF,$0072,$0000,$003C,$0500,$004D,$0A00
                dc.w    $FFFF,$0070,$0000,$0044,$0900,$004A,$1000,$007F
                dc.w    $1A00,$0057,$2200,$FFFF,$004D,$0000,$0061,$0D00
                dc.w    $0041,$1200,$0070,$2300,$FFFF,$007E,$0000,$006E
                dc.w    $0800,$FFFF,$005A,$0000,$FFFF,$0040,$0000,$008A
                dc.w    $0A00,$FFFF,$004D,$0000,$0057,$0C00,$FFFF,$0084
                dc.w    $0000,$007F,$0C00,$0082,$1E00,$FFFF,$004A,$0000
                dc.w    $007F,$3200,$FFFF,$1303,$002E,$0260,$0001,$0001
                dc.w    $003C,$0006,$2DA8,$0000,$0130,$0004,$B9C2,$0004
                dc.w    $B9CC
                dc.l    L_4A774
                dc.l    L_4A74E
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0005
                dc.w    $0000,$000E,$0012,$0005,$0003,$000F,$000E,$0000
                dc.w    $0006,$0014,$0006,$0005,$0003,$000E,$000E,$0003
                dc.w    $0001,$0010,$0011,$0004,$0003,$000F,$000E,$0000
                dc.w    $0007,$0014,$0006,$0004,$0003,$000F,$000E,$0046
                dc.w    $0007,$8FFB,$0007,$9042,$0007,$9089,$004C,$0007
                dc.w    $91EA,$0007,$9237,$0007,$9284,$0047,$0007,$9525
                dc.w    $0007,$9572,$0007,$95BF,$1503,$002E,$02A0,$0000
                dc.w    $0001,$002D,$0006,$40A8,$0000,$0150,$0004,$BA5E
                dc.w    $0004,$BA68
                dc.l    L_4A7EC
                dc.l    L_4A7B4
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0003,$0011,$0011,$0002,$0002,$0011,$0012,$0001
                dc.w    $0002,$0011,$0011,$0002,$0001,$0011,$0011,$0002
                dc.w    $0001,$0011,$0012,$0003,$0001,$0010,$0011,$0002
                dc.w    $0002,$0012,$0011,$0003,$0002,$0011,$0012,$1A03
                dc.w    $002E,$0340,$0002,$0006,$0000,$0006,$7618,$0000
                dc.w    $01A0,$0004,$BAD0,$0004,$BAEC
                dc.l    L_4A866
                dc.l    L_4A83C
                dc.w    $0000,$0500
D_4BAD0:
                dc.b    $00,$01,$02,$03,$04,$05,$FF
D_4BAD7:
                dc.b    $06,$07,$08,$09,$0A,$0B,$FF
D_4BADE:
                dc.w    $0D0E,$FF03,$0C0D,$0EFF
D_4BAE6:
                dc.w    $0E0D,$0C03,$FF00,$0005,$0009,$0019,$0011,$0004
                dc.w    $0009,$001A,$0010,$0005,$0006,$0019,$0013,$0003
                dc.w    $0009,$001A,$0010,$0004,$0007,$0019,$0012,$0004
                dc.w    $0007,$0018,$0012,$0004,$0007,$0018,$0012,$0004
                dc.w    $0007,$0018,$0012,$0003,$0006,$0019,$0013,$0004
                dc.w    $0008,$001B,$0012,$0003,$0007,$0019,$0012,$0004
                dc.w    $0007,$0019,$0012,$000C,$0004,$000F,$0015,$0012
                dc.w    $0002,$000D,$0018,$0012,$0002,$000D,$0018
D_4BB64:
                dc.w    $0D02,$0030,$00D0,$0000,$0000,$0000,$0006,$A6D8
                dc.w    $0000,$0068,$0004,$BB8C,$0004,$BBA0
                dc.l    L_4AA4C
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
D_4BC20:
                dc.w    $00F6,$80F7,$FFF8,$0012,$00E2,$80E3,$0000,$0012
                dc.w    $00C2,$80C3,$0008,$0012
D_4BC38:
                dc.w    $0056,$8057,$FFF8,$0000,$006A,$806B,$0000,$0000
                dc.w    $00A2,$80A3,$0008,$0000
TileAnims:
                dc.l    L_4AAF4
                dc.l    L_4AAEC
MapPatches:
                dc.w    $0070,$0002,$CAA0,$0072,$0002,$CAA0,$0074,$0003
                dc.w    $C0A0,$0076,$0003,$C0C0,$0084,$0001,$C0D0,$0086
                dc.w    $0001,$C3A0,$009B,$0002,$CB50,$009D,$0002,$CC90
                dc.w    $009F,$0001,$C090,$00A1,$0001,$CCC0,$00A3,$0001
                dc.w    $C0D0,$00A5,$0001,$C0E0,$00A7,$0001,$C5E0,$00A9
                dc.w    $0001,$C4D0,$00AF,$0003,$C7B0,$00B1,$0003,$CAA0
                dc.w    $00C1,$0001,$C0B0,$00C3,$0001,$C6B0,$00C5,$0001
                dc.w    $C4A0,$00C7,$0001,$C4D0,$00C9,$0002,$C7A0,$00CB
                dc.w    $0002,$C8C0,$0070,$0009,$CA11,$0072,$0009,$C6B1
                dc.w    $0074,$0008,$C8C1,$0076,$0008,$C2D1,$00AF,$0008
                dc.w    $C5E1,$00B1,$0008,$C3E1,$FFFF,$2F04,$002C,$08D0
                dc.w    $0000,$001E,$0000,$0006,$55A8,$0000,$0468,$0004
                dc.w    $BD2A,$0004,$BD2E
                dc.l    L_4AC1C
                dc.l    L_4ABF0
                dc.w    $0000,$0500,$0001,$0203,$000F,$0003,$0016,$0024
                dc.w    $0007,$0001,$001B,$0027,$0011,$0002,$001A,$002B
D_4BD46:
                dc.w    $1004,$002C,$0300,$0000,$0000,$0000,$0006,$7018
                dc.w    $0000,$0180,$0004,$BD6E,$0004,$BD72,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
D_4BD6E:
                dc.w    $0001,$FF00,$0002,$0004,$002B,$0009,$0001,$0002
                dc.w    $002C,$000C,$1A03,$002E,$0340,$0003,$0001,$001E
                dc.w    $0006,$B3D8,$0000,$01A0,$0004,$BDAA,$0004,$BDBE
                dc.l    L_4AE32
                dc.l    L_4ADF0
                dc.w    $0000,$0200
D_4BDAA:
                dc.b    $00,$01,$02,$03,$FF
D_4BDAF:
                dc.b    $04,$05,$FF,$03,$FF
D_4BDB4:
                dc.b    $06,$07,$08,$09,$FF
D_4BDB9:
                dc.b    $0A,$0B,$FF,$09,$FF,$00,$03,$00,$01,$00,$15,$00,$19,$00,$02,$00
                dc.b    $03,$00,$18,$00,$16,$00,$04,$00,$01,$00,$15,$00,$19,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$02,$00,$02,$00,$18,$00,$17,$00,$02,$00
                dc.b    $02,$00,$18,$00,$16,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$14,$00,$04,$00,$02,$00,$18,$00,$16,$00,$04,$00
                dc.b    $03,$00,$18,$00,$15
D_4BE1E:
                dc.w    $FEFE,$FEFF,$FFFF,$FF00,$0000,$0101,$0101,$0202
                dc.w    $027F,$7F00,$0170,$005A,$0170,$0046,$0170,$00AA
                dc.w    $FFFF,$0170,$002F,$0170,$0056,$0170,$00A4,$FFFF
                dc.w    $0170,$0037,$0170,$00A0,$0170,$00AF,$FFFF,$0170
                dc.w    $0046,$0170,$0032,$0170,$00B4,$FFFF,$0170,$0028
                dc.w    $0170,$002F,$0170,$005A,$0170,$003C,$FFFF,$0170
                dc.w    $005A,$0170,$0046,$0170,$0091,$0170,$0032,$FFFF
                dc.w    $0170,$00A0,$0170,$0055,$0170,$00A6,$0170,$0046
                dc.w    $FFFF,$1A03,$002E,$0340,$0005,$0001,$0028,$0006
                dc.w    $DAD8,$0000,$01A0,$0004,$BEC8,$0004,$BED0
                dc.l    L_4AFA2
                dc.l    L_4AF72
                dc.w    $0000,$0300
D_4BEC8:
                dc.w    $0304,$05FF
D_4BECC:
                dc.w    $0001,$02FF,$0004,$0002,$0018,$0016,$0002,$0003
                dc.w    $001B,$0014,$0004,$0004,$0018,$0013,$0005,$0004
                dc.w    $0018,$0014,$0004,$0003,$0019,$0015,$0005,$0003
                dc.w    $0018,$0015
D_4BF00:
                dc.w    $0000
D_4BF02:
                dc.b    $00
D_4BF03:
                dc.b    $00,$1B,$03,$00,$2E,$03,$60,$00,$23,$00,$01,$00,$00,$00,$06,$EE
                dc.b    $58,$00,$00,$01,$B0,$00,$04,$BF,$2C,$00,$04,$BF,$42
                dc.l    L_4B0D8
                dc.l    L_4B080
                dc.b    $00,$00,$02,$00,$04,$03,$02,$01,$00,$07,$06,$05,$FF,$10,$FF
D_4BF37:
                dc.b    $0C,$0B,$0A,$09,$08,$0F,$0E,$0D,$FF,$10,$FF,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$2B,$04,$00,$2C,$08,$10,$00,$01,$00,$1E,$00,$00,$00
                dc.b    $07,$27,$B8,$00,$00,$04,$08,$00,$04,$BF,$F2,$00,$04,$BF,$FE
                dc.l    L_4B22E
                dc.l    L_4B1FC
                dc.w    $0000,$0800
D_4BFF2:
                dc.b    $00,$01,$02,$01,$00,$03,$04,$03,$FF
D_4BFFB:
                dc.b    $05,$06,$FF,$00,$0E,$00,$02,$00,$12,$00,$24,$00,$0C,$00,$02,$00
                dc.b    $16,$00,$25,$00,$0A,$00,$02,$00,$1A,$00,$23,$00,$0C,$00,$02,$00
                dc.b    $14,$00,$23,$00,$0A,$00,$02,$00,$19,$00,$24,$00,$07,$00,$02,$00
                dc.b    $15,$00,$21,$00,$07,$00,$02,$00,$15,$00,$21
D_4C036:
                dc.w    $0902,$0030,$0090,$0000,$0001,$0000,$0007,$6028
                dc.w    $0000,$0048,$0004,$C05E,$0004,$C060
                dc.l    L_4B480
                dc.w    $0000,$0000,$0000,$0000,$00FF,$0003,$0001,$000C
                dc.w    $0007
D_4C068:
                dc.w    $0F02,$0030,$00F0,$0000,$0001,$0000,$0007,$60B8
                dc.w    $0000,$0078,$0004,$C090,$0004,$C0A2
                dc.l    L_4B3F0
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$0607
                dc.w    $0809,$0A0B,$0C0D,$0E0F,$FF00,$0004,$0002,$0008
                dc.w    $000C,$0005,$0003,$0007,$000A,$0005,$0004,$0007
                dc.w    $0008,$0004,$0004,$0007,$0008,$0002,$0003,$000A
                dc.w    $0008,$0003,$0002,$0008,$0009,$0003,$0002,$0009
                dc.w    $0009,$0004,$0002,$0008,$0009,$0005,$0001,$0008
                dc.w    $000A,$0005,$0002,$0008,$0008,$0005,$0003,$0009
                dc.w    $0008,$0005,$0003,$000A,$0008,$0003,$0004,$000C
                dc.w    $0008,$0005,$0003,$000A,$000A,$0004,$0003,$000A
                dc.w    $000A,$0005,$0003,$000A,$0007
D_4C122:
                dc.w    $000C,$000D,$000F,$0001
D_4C12A:
                dc.w    $0000,$FFFD,$0002,$FFFD,$0003,$FFFD,$0003,$FFFE
                dc.w    $0003,$0000,$0003,$0002,$0003,$0003,$0002,$0003
                dc.w    $0000,$0003,$FFFE,$0003,$FFFD,$0003,$FFFD,$0002
                dc.w    $FFFD,$0000,$FFFD,$FFFE,$FFFD,$FFFD,$FFFE,$FFFD
D_4C16A:
                dc.w    $0000
D_4C16C:
                dc.w    $0004,$C184,$0004,$C18C,$0004,$C184,$0004,$C17C
                dc.w    $017C,$817D,$0190,$8191,$017E,$817F,$0192,$8193
                dc.w    $0180,$8181,$0194,$8195
D_4C194:
                dc.w    $0004,$C1AC,$0004,$C1B4,$0004,$C1AC,$0004,$C1A4
                dc.w    $8154,$8155,$8168,$8169,$8158,$8159,$016C,$816D
                dc.w    $815C,$815D,$0000,$8171
D_4C1BC:
                dc.b    $00
D_4C1BD:
                dc.b    $00
D_4C1BE:
                dc.b    $00
D_4C1BF:
                dc.b    $00
D_4C1C0:
                dc.b    $00
D_4C1C1:
                dc.b    $00
D_4C1C2:
                dc.w    $0000
D_4C1C4:
                dc.w    $0000
D_4C1C6:
                dc.w    $0000
D_4C1C8:
                dc.w    $0000,$1002,$0030,$0100,$0001,$0001,$0000,$0007
                dc.w    $84B8,$0000,$0080,$0004,$C1F2,$0004,$C1FA
                dc.l    L_4B632
                dc.l    L_4B5C2
                dc.w    $0000,$0000,$0001,$0203,$0405,$FF00,$0002,$0002
                dc.w    $000C,$000C,$0002,$0002,$000C,$000C,$0002,$0002
                dc.w    $000C,$000C,$0002,$0002,$000C,$000C,$0002,$0002
                dc.w    $000C,$000C,$0003,$0003,$000A,$000A,$0102,$0030
                dc.w    $0010,$0001,$FFFF,$0000,$0004,$C25C,$0000,$0080
                dc.w    $0004,$C252,$0004,$C254
                dc.l    L_4B73C
                dc.l    L_4B71A
                dc.w    $0000,$0000,$00FF,$0000,$0000,$0014,$0014,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000
D_4C26C:
                dc.w    $1503,$002E,$02A0,$0000,$0001,$0000,$0007,$6FB8
                dc.w    $0000,$0150,$0004,$C290,$0004,$C29A
                dc.l    L_4B874
                dc.w    $0000,$0000,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011
D_4C2DA:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000
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
