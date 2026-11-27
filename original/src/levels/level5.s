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
; Stage 5.  Enemies: Cancer (level 1's), Slither, Pursuer, Cheetah and the
; Mid-phase Cheetah, the POW Armor; the boss is Bellmite with its shells.
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
                dc.l    $51A54               ; LvMusic: player in level B; samples $53A46 (8), data $53ADC, periods $53A86
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $0604
                dc.l    WavesFrom_0604
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
Waves:
                dc.w    $005A,$016D,$0082
                dc.l    $00080124,$00000000,Def_SlitherHead
                dc.w    $00C8,$016D,$00A0
                dc.l    $0006032A,$00000000,Def_SlitherHead
                dc.w    $0103,$0170,$0087
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0134,$0082,$00DF
                dc.l    $00060221,$00000000,Def_SlitherHead
                dc.w    $0136,$0000,$0000
                dc.l    $03E8000F,CancerData1,Def_Cancer
                dc.w    $01A0,$003C,$0012
                dc.l    $00060418,$00000000,Def_SlitherHead
                dc.w    $0205,$0050,$00DF
                dc.l    $00060221,$00000000,Def_SlitherHead
                dc.w    $0268,$0136,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $026A,$0136,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $026C,$0104,$0012
                dc.l    $00060530,$00000000,Def_SlitherHead
                dc.w    $02CB,$016D,$0078
                dc.l    $0006032A,$00000000,Def_SlitherHead
                dc.w    $02D0,$008C,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $02F0,$008C,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $030D,$0014,$0064
                dc.l    $00040000,$00000000,Def_Pursuer
                dc.w    $0338,$0064,$00DF
                dc.l    $00060221,$00000000,Def_SlitherHead
                dc.w    $0339,$00C8,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $039D,$0170,$0028
                dc.l    $00060618,$00000000,Def_SlitherHead
                dc.w    $03D4,$0170,$005A
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $03E2,$0014,$0078
                dc.l    $00040000,$00000000,Def_Pursuer
                dc.w    $040B,$0096,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $041A,$0046,$0014
                dc.l    $00060418,$00000000,Def_SlitherHead
                dc.w    $044B,$0136,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $044C,$0000,$0000
                dc.l    $07D0000F,CancerData1,Def_Cancer
                dc.w    $04B0,$016D,$0078
                dc.l    $00050032,$00320000,Def_MidCheetah
                dc.w    $04B4,$016D,$0078
                dc.l    $00050032,$00820000,Def_MidCheetah
                dc.w    $0514,$0096,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0516,$0064,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $0541,$016D,$0078
                dc.l    $000C0000,$00000000,Def_Pursuer
                dc.w    $0582,$016D,$00A0
                dc.l    $00070733,$00000000,Def_SlitherHead
                dc.w    $05DC,$0046,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $05FA,$012C,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
WavesFrom_0604:
                dc.w    $0640,$016D,$0096
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $0654,$016D,$0078
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $06A4,$0170,$005A
                dc.l    $0004FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $06CC,$005A,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $06CE,$016D,$0046
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $06F4,$016D,$00B4
                dc.l    $000C0000,$00000000,Def_Pursuer
                dc.w    $06F6,$0000,$0000
                dc.l    $07D0000F,CancerData2,Def_Cancer
                dc.w    $06F9,$016D,$0032
                dc.l    $000C0000,$00000000,Def_Pursuer
                dc.w    $0747,$012C,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0780,$0170,$0078
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0796,$0170,$00A0
                dc.l    $000C0000,$00000000,Def_Pursuer
                dc.w    $07BC,$016D,$006E
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $07BD,$0140,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $07DA,$016D,$009B
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $07F3,$016D,$0046
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $0804,$0140,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $0831,$00F0,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0866,$0000,$0000
                dc.l    $0BB8000F,CancerData3,Def_Cancer
                dc.w    $0884,$00E6,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0886,$0154,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $088D,$016D,$0046
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $0897,$016D,$0073
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $08A1,$016D,$00A0
                dc.l    $00000000,$00000000,Def_Cheetah
                dc.w    $08A4,$0154,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $08CE,$0078,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $08CF,$0000,$0000
                dc.l    $0FA0000F,CancerData4,Def_Cancer
                dc.w    $08E5,$0064,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0953,$0096,$00DF
                dc.l    $00060221,$00000000,Def_SlitherHead
                dc.w    $0977,$0136,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $0995,$0064,$0014
                dc.l    $00080000,$00000000,Def_Pursuer
                dc.w    $09C6,$010E,$0014
                dc.l    $00060530,$00000000,Def_SlitherHead
                dc.w    $09EC,$0136,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0A1E,$0064,$00DF
                dc.l    $00000000,$00000000,Def_Pursuer
                dc.w    $0A50,$0170,$0064
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0AC0,$0168,$0064
                dc.l    $00000000,$00000000,Def_Bellmite
                dc.w    $7530   ; end: never reached
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
Spawn_Cancer:
                movea.l $A(a1),a3               ; list of x, y
                move.w  $8(a1),d7               ; frames between them
                clr.w   d6                      ; first start delay 0
.4A812:
                move.w  (a3)+,d0                ; x ($FFFF ends the list)
                bmi.b   .4A836
                move.w  (a3)+,d1                ; y
                move.w  $8(a2),d2               ; hit points from the definition
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)          ; scroll x at which it gives up
                clr.w   $38(a0)                 ; new heading at once
                move.w  d6,$32(a0)              ; start delay
                add.w   d7,d6                   ; the next one starts later
                jsr     (jt_ObjInsert).w
                bra.b   .4A812                  ; next position
.4A836:
                rts
Upd_Cancer:
                tst.w   $32(a0)                 ; waiting to start?
                beq.b   .4A844
                subq.w  #$1,$32(a0)             ; count the delay down
                rts
.4A844:
                subq.w  #$1,$A(a0)              ; scrolls with the map
                movem.w $A(a0),d0-d1            ; off the screen:
                cmp.w   #$10,d0
                bcs.b   .4A866
                cmp.w   #$170,d0
                bhi.b   .4A866
                cmp.w   #$10,d1
                bcs.b   .4A866
                cmp.w   #$E0,d1
                bcs.b   .4A86A
.4A866:
                jmp     (jt_ObjKillSelf).w      ; remove
.4A86A:
                move.w  $3A(a0),d4              ; scroll x at which it gives up
                cmp.w   (ScrollX).w,d4          ; past its scroll x:
                bhi.b   .4A884
                moveq   #10,d7                  ; make for the nearer edge
                cmp.w   #$88,d1                 ; upper half: the top (y 10),
                bcs.b   .4A880
                move.w  #$E0,d7                 ; lower half: the bottom (y $E0)
.4A880:
                moveq   #4,d6                   ; and x 4: off to the left
                bra.b   .4A890                  ; steer at once
.4A884:
                subq.w  #$1,$38(a0)             ; time for a new heading?
                bpl.b   .4A8CE
                movem.w (ShipPos).w,d6-d7       ; target: the ship
.4A890:
                moveq   #2,d4
                lea.l   (CancerAnimRight).l,a1  ; x step +2 / -1, facing it
                cmp.w   d6,d0                   ; target to the right:
                bcs.b   .4A8A4
                moveq   #-1,d4                  ; left: x step -1
                lea.l   (CancerAnimLeft).l,a1
.4A8A4:
                move.l  a1,$2A(a0)
                moveq   #1,d5                   ; y step +1 / -1
                cmp.w   d7,d1                   ; target below:
                bcs.b   .4A8B0
                neg.w   d5                      ; above: -1
.4A8B0:
                move.w  d0,d2                   ; |dx| to the target
                sub.w   d6,d2
                bpl.b   .4A8B8
                neg.w   d2
.4A8B8:
                lsr.w   #$2,d2                  ; hold it for |dx|/4 + random 25 frames
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)              ; frames on this heading
                move.b  d4,$36(a0)              ; x step
                move.b  d5,$37(a0)              ; y step
.4A8CE:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6              ; y step
                ext.w   d6
                bpl.b   .4A8E4                  ; moving down?
                subq.w  #$2,d1                  ; up: probe just above it
                bra.b   .4A8E8
.4A8E4:
                add.w   #$20,d1                 ; down: just below it (32 pixels tall)
.4A8E8:
                addq.w  #$8,d0                  ; at its middle
                jsr     (jt_GetMapCell).w       ; blocked vertically?
                bne.b   .4A8F4
                add.w   d6,$C(a0)               ; no: move up/down
.4A8F4:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1                  ; probe at its middle height
                move.b  $36(a0),d4              ; x step
                ext.w   d4
                bpl.b   .4A906                  ; moving right?
                subq.w  #$2,d0                  ; left: probe just left of it
                bra.b   .4A90A
.4A906:
                add.w   #$22,d0                 ; right: just past it (34 pixels wide)
.4A90A:
                jsr     (jt_GetMapCell).w       ; blocked horizontally?
                bne.b   .4A914
                add.w   d4,$A(a0)               ; no: move left/right
.4A914:
                rts
LevelInit:
                rts
; LevelFrame: from scroll x $BC0 the background loops back to $B40 (the
; boss fight scrolls on the spot).  LevelInit does nothing.
LevelFrame:
                cmpi.w  #$BC0,(ScrollX).w
                bne.b   .4A926
                move.w  #$B40,(ScrollX).w
.4A926:
                rts
; Slither: a multi-jointed crustacean - a head, entry $06 body segments
; and a tail, 4 frames apart on the head's path ($67FC8: dx, dy, frame).
; When the head takes 10 damage it explodes (1100 points) and the body
; breaks apart: the segments fly off in their own directions
; (SlitherScatter).  When a body segment takes 10 the chain splits
; there: that segment and the ones behind it follow the path to where it
; was hit, then lead off on the path section for its direction
; (SlitherHeadFrames) - a new, shorter Slither.
Spawn_Slither:
                movem.w $2(a1),d0-d1
                move.w  #$3E8,d2                ; 1000 hit points: 10 damage decides
                lea.l   (Def_SlitherHead).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$FF00,$32(a0)          ; head: waiting (0 frames), segment 0
                move.w  $8(a1),$34(a0)          ; entry $08: start position in the path
                clr.w   $3A(a0)                 ; nothing in front
                clr.w   $36(a0)
                clr.b   $22(a0)                 ; frame from the path
                move.b  #$14,$4(a0)             ; priority 20
                jsr     (jt_ObjInsert).w
                move.w  $6(a1),d7               ; entry $06: body segments - 1
                moveq   #0,d6                   ; d6 = segment number
                moveq   #0,d5                   ; d5 = start delay, 4 frames apart
                lea.l   (Def_SlitherBody).l,a2
                bra.b   .4A9A4
.4A96E:
                movea.l a0,a3                   ; a3 = the segment in front
                movem.w $2(a1),d0-d1
                move.w  #$3E8,d2
                jsr     (jt_ObjCreate).w
                st.b    $32(a0)                 ; waiting
                move.b  d6,$33(a0)              ; segment number
                move.w  d5,$36(a0)              ; start delay
                move.w  $8(a1),$34(a0)          ; same path position as the head
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                move.l  a0,d0                   ; link the two
                sub.l   a3,d0
                move.w  d0,$3C(a3)
                move.w  d0,$3A(a0)
.4A9A4:
                addq.w  #$1,d6
                addq.w  #$4,d5
                dbra    d7,.4A96E
                movea.l a0,a3                   ; then the tail
                movem.w $2(a1),d0-d1
                addq.w  #$2,d1
                move.w  #$7D0,d2                ; 2000 hit points
                lea.l   (Def_SlitherTail).l,a2
                jsr     (jt_ObjCreate).w
                st.b    $32(a0)
                move.b  d6,$33(a0)
                move.w  $8(a1),$34(a0)
                move.w  d5,$36(a0)
                clr.w   $3C(a0)                 ; nothing behind it
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w
                move.l  a0,d0
                sub.l   a3,d0
                move.w  d0,$3C(a3)
                move.w  d0,$3A(a0)
                rts
Upd_Slither:
                move.b  $32(a0),d0              ; state 0: leading on the path
                beq.b   .4AA50
                cmp.b   #$1,d0                  ; 1: following to a turn point
                beq.w   .4AB28
                cmp.b   #$2,d0                  ; 2: scattering
                beq.b   .4AA10
                subq.w  #$1,$36(a0)             ; -1: waiting to start
                bpl.b   .4AA0E
                clr.b   $32(a0)
.4AA0E:
                rts
.4AA10:
                moveq   #0,d0
                move.b  $33(a0),d0              ; segment number picks
                lsl.w   #$2,d0
                lea.l   (SlitherScatter).l,a1   ; its own scatter direction
                movem.w (a1,d0.w),d0-d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
.4AA2C:
                movem.w $A(a0),d0-d1            ; off the screen:
                cmp.w   #$10,d0
                bcs.b   .4AA4C
                cmp.w   #$10,d1
                bcs.b   .4AA4C
                cmp.w   #$170,d0
                bhi.b   .4AA4C
                cmp.w   #$E6,d1
                bhi.b   .4AA4C
                rts
.4AA4C:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AA50:
                cmpi.w  #$A,$26(a0)             ; 10 damage?
                blt.w   .4AAEA
                tst.b   $33(a0)                 ; the head?
                beq.b   .4AAB2
                move.w  $3A(a0),d0              ; a body segment: the chain breaks here
                neg.w   d0
                lea.l   (a0,d0.w),a1
                clr.w   $3C(a1)                 ; the segment in front loses its tail
                movea.l a0,a1
                clr.w   $3A(a0)                 ; this one now leads its part of the chain
                move.w  $1E(a0),d0              ; its frame (direction)
                lea.l   (SlitherHeadFrames).l,a2 ; picks the path section going that way
                lsl.w   #$1,d0
                move.w  (a2,d0.w),d1
                move.w  $34(a0),d2              ; d2 = where on the path it is now
.4AA88:
                move.w  d1,$38(a1)              ; every segment from here back: turn point section
                clr.w   $26(a1)                 ; damage reset
                tst.b   $32(a1)                 ; one that has not started yet:
                bpl.b   .4AA9A
                move.w  d1,$34(a0)              ; writes $34 of a0 (the hit segment), probably meant a1
.4AA9A:
                move.w  d2,$36(a1)              ; follow the path to this point,
                move.b  #$1,$32(a1)             ; state 1
                move.w  $3C(a1),d0              ; next segment back
                beq.b   .4AAB0
                lea.l   (a1,d0.w),a1
                bra.b   .4AA88
.4AAB0:
                rts
.4AAB2:
                move.b  #$1,$5(a0)              ; the head: explode
                clr.l   $6(a0)
                move.l  #$1100,d0               ; 1100 points
                jsr     (jt_AddScore).w
                movea.l a0,a1
.4AAC8:
                move.b  #$2,$32(a1)             ; every segment scatters
                st.b    $22(a1)
                move.w  #$3,$24(a1)             ; 3 hit points each
                clr.w   $26(a1)
                move.w  $3C(a1),d0              ; next segment back
                beq.w   .4AA10
                lea.l   (a1,d0.w),a1
                bra.b   .4AAC8
.4AAEA:
                lea.l   ($67FC8).l,a1           ; the path: dx, dy, frame bytes (level B)
                move.w  $34(a0),d0
                lea.l   (a1,d0.w),a1
                addq.w  #$3,$34(a0)             ; next step
                move.b  (a1)+,d0
                move.b  (a1)+,d1
                move.b  (a1)+,d2
                cmp.b   #$7F,d0                 ; $7F at the end:
                bne.w   .4AB10
                subq.w  #$6,$34(a0)             ; repeat the last step
                bra.b   .4AAEA
.4AB10:
                ext.w   d0
                ext.w   d1
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                and.w   #$F,d2                  ; 16 frames (directions)
                move.w  d2,$1E(a0)
                bra.w   .4AA2C
.4AB28:
                cmpi.w  #$A,$26(a0)             ; (the compare is not used)
                bra.b   .4AB58
.4AB30:
                movea.l a0,a1                   ; (not reached: nothing branches here)
.4AB32:
                move.w  $3A(a1),d0
                neg.w   d0
                lea.l   (a1,d0.w),a1
                tst.w   d0
                bne.b   .4AB32
.4AB40:
                move.b  #$2,$32(a1)
                st.b    $22(a1)
                move.w  $3C(a1),d0
                beq.w   .4AA10
                lea.l   (a1,d0.w),a1
                bra.b   .4AB40
.4AB58:
                move.w  $36(a0),d0              ; reached the turn point?
                cmp.w   $34(a0),d0
                bhi.b   .4AAEA
                move.w  $38(a0),$34(a0)         ; jump to the section for its direction
                move.w  #$7FFF,$36(a0)
                clr.b   $32(a0)                 ; and lead (state 0)
                bra.w   .4AAEA
; Pursuer (probably): fast and homing - for 100 steps it turns towards the
; ship every 5 frames (16 directions, PursuerSteps), then flies straight
; on; fires at its definition's rate.
Spawn_Pursuer:
                movem.w $2(a1),d0-d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  #$19,$4(a0)
                clr.w   $34(a0)
                clr.b   $22(a0)
                move.w  #$64,$36(a0)
                move.w  $6(a1),$1E(a0)
                jmp     (jt_ObjInsert).w
Upd_Pursuer:
                subq.w  #$1,$34(a0)
                bpl.b   .4ABD2
                move.w  #$4,$34(a0)
                tst.w   $36(a0)
                beq.b   .4ABD2
                subq.w  #$1,$36(a0)
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  $1E(a0),d1
                jsr     (jt_TurnTowards).w
                move.w  d1,$1E(a0)
.4ABD2:
                move.w  $1E(a0),d0
                lsl.w   #$2,d0
                movem.w $A(a0),d1-d2
                lea.l   (PursuerSteps).l,a1
                add.w   (a1,d0.w),d1
                add.w   $2(a1,d0.w),d2
                cmp.w   #$10,d1
                bcs.b   .4AC04
                cmp.w   #$170,d1
                bhi.b   .4AC04
                cmp.w   #$10,d2
                bcs.b   .4AC04
                cmp.w   #$E0,d2
                bcs.b   .4AC08
.4AC04:
                jmp     (jt_ObjKillSelf).w
.4AC08:
                movem.w d1-d2,$A(a0)
                rts
; Cheetah (48x41) and its Mid-phase form (32x20, groups of entry $06+1 at
; random heights, 24 frames apart): they drift left and fire beams
; (CheetahBeam, 7 pixels a frame) - the Cheetah every 25 frames at a
; random height, the mid-phase every 50 from its middle.
Spawn_Cheetah:
                movem.w $2(a1),d0-d1
                moveq   #20,d2
                jsr     (jt_ObjCreate).w
                moveq   #50,d0
                jsr     (jt_Random).w
                move.w  d0,$32(a0)
                move.b  #$A,$4(a0)
                move.b  #$2,$21(a0)
                jmp     (jt_ObjInsert).w
Spawn_MidCheetah:
                move.w  $6(a1),d7
                moveq   #0,d6
                moveq   #0,d5
.4AC3E:
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
                bcs.b   .4AC80
                moveq   #0,d5
.4AC80:
                dbra    d7,.4AC3E
                rts
Upd_Cheetah:
                moveq   #2,d1
                moveq   #32,d7
                moveq   #25,d6
                bra.b   Cheetah_MoveFire
Upd_MidCheetah:
                tst.w   $34(a0)
                beq.b   .4AC9A
                subq.w  #$1,$34(a0)
                rts
.4AC9A:
                moveq   #3,d1
                moveq   #-10,d7
                moveq   #50,d6
Cheetah_MoveFire:
                sub.w   d1,$A(a0)
                bpl.b   .4ACAA
                jmp     (jt_ObjKillSelf).w
.4ACAA:
                subq.w  #$1,$32(a0)
                bpl.b   .4ACEC
                move.w  d6,$32(a0)
                move.w  d7,d0
                bmi.b   .4ACC4
                jsr     (jt_Random).w
                addq.w  #$8,d0
                add.w   $C(a0),d0
                bra.b   .4ACCC
.4ACC4:
                neg.w   d7
                add.w   $C(a0),d7
                move.w  d7,d0
.4ACCC:
                move.w  d0,d1
                move.w  $A(a0),d0
                moveq   #-1,d2
                move.l  a0,-(a7)
                lea.l   (Def_CheetahBeam).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
.4ACEC:
                rts
Upd_CheetahBeam:
                subq.w  #$7,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   .4ACFE
                jmp     (jt_ObjKillSelf).w
.4ACFE:
                rts
; Bellmite (the boss): a control centre (10000 hit points, but 30 hits
; kill it: LevelComplete, 2000 points) guarded by 8 shells that hold
; formations round it (BellmiteShells, ShellFormations).  It drifts in
; straight lines, bouncing (BellmiteBounce/BellmiteSteps); shells scatter
; (ShellScatter) when hit or when the formation changes.
Spawn_Bellmite:
                movem.w $2(a1),d0-d1
                movem.w d0-d1,(BellmiteX).l
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
                lea.l   (BellmiteShells).l,a4
                lea.l   (Def_BellmiteShell).l,a2
.4AD4A:
                movem.w (BellmiteX).l,d0-d1
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
                dbra    d7,.4AD4A
                st.b    (MusicFadeReq).w
                rts
Upd_Bellmite:
                cmpi.w  #$1E,$26(a0)
                ble.b   .4ADCA
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                st.b    (LevelComplete).w
                move.l  #$2000,d0
                jsr     (jt_AddScore).w
                lea.l   (BellmiteShells).l,a1
                moveq   #7,d0
.4ADBC:
                movea.l $4(a1),a2
                st.b    $3C(a2)
                addq.l  #$8,a1
                dbra    d0,.4ADBC
.4ADCA:
                tst.b   $3A(a0)
                bpl.b   .4ADE8
                subq.w  #$1,$38(a0)
                bmi.b   .4ADE4
                subq.w  #$2,$A(a0)
                move.l  $A(a0),(BellmiteX).l
                rts
.4ADE4:
                clr.b   $3A(a0)
.4ADE8:
                subq.w  #$1,$38(a0)
                bmi.w   .4AE5C
                movem.w $32(a0),d0-d1
                movem.w $A(a0),d2-d3
                add.w   d0,d2
                add.w   d1,d3
                cmp.w   #$30,d2
                blt.b   .4AE2A
                cmp.w   #$12E,d2
                bhi.b   .4AE2A
                cmp.w   #$30,d3
                blt.b   .4AE2A
                cmp.w   #$AC,d3
                bhi.b   .4AE2A
                movem.w d2-d3,$A(a0)
                movem.w d2-d3,(BellmiteX).l
                bra.w   .4AE98
.4AE2A:
                lsr.w   $38(a0)
                moveq   #0,d0
                moveq   #0,d1
                move.b  $37(a0),d1
                lea.l   (BellmiteBounce).l,a1
                move.b  (a1,d1.w),d0
                move.b  d0,$37(a0)
                lsl.w   #$2,d0
                lea.l   (BellmiteSteps).l,a1
                movem.w (a1,d0.w),d2-d3
                movem.w d2-d3,$32(a0)
                bra.w   .4ADCA
.4AE5C:
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.b  d0,$37(a0)
                move.w  d0,d1
                lsl.w   #$2,d1
                lea.l   (BellmiteSteps).l,a1
                movem.w (a1,d1.w),d2-d3
                movem.w d2-d3,$32(a0)
                moveq   #100,d0
                jsr     (jt_Random).w
                add.w   #$14,d0
                move.w  d0,$38(a0)
                bra.w   .4ADCA
.4AE98:
                subq.w  #$1,$3C(a0)
                bmi.b   .4AEA0
                rts
.4AEA0:
                move.w  #$23,$3C(a0)
                moveq   #0,d2
                movem.w (BellmiteX).l,d0-d1
                add.w   #$18,d0
                add.w   #$18,d1
                sub.w   (ShipPos).w,d0
                bpl.b   .4AEC0
                addq.w  #$1,d2
.4AEC0:
                sub.w   ($F0).w,d1
                bpl.b   .4AEC8
                addq.w  #$2,d2
.4AEC8:
                lsl.w   #$3,d2
                lea.l   (ShellFormations).l,a1
                lea.l   (BellmiteShells).l,a2
                adda.l  d2,a1
                moveq   #6,d1
.4AEDA:
                moveq   #0,d0
                move.b  (a1)+,d0
                lsl.w   #$3,d0
                tst.l   $4(a2,d0.w)
                bne.b   .4AEEC
.4AEE6:
                dbra    d1,.4AEDA
                rts
.4AEEC:
                movea.l $4(a2,d0.w),a3
                tst.w   $32(a3)
                bne.b   .4AEE6
                movem.w $A(a3),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                addq.w  #$1,d0
                move.w  d0,$32(a3)
                move.w  #$1,$34(a3)
                rts
Upd_BellmiteShell:
                cmpi.w  #$14,$26(a0)
                blt.b   .4AF40
.4AF1C:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.w  $3A(a0),d0
                lsl.w   #$3,d0
                lea.l   (BellmiteShells).l,a1
                clr.l   $4(a1,d0.w)
                move.l  #$300,d0
                jmp     (jt_AddScore).w
.4AF40:
                tst.b   $3C(a0)
                bmi.b   .4AF1C
                move.w  $32(a0),d0
                beq.w   .4AFEA
                subq.w  #$1,d0
                lsl.w   #$2,d0
                lea.l   (ShellScatter).l,a1
                lea.l   (a1,d0.w),a1
                movem.w $36(a0),d0-d1
                movem.w (a1),d2-d3
                tst.b   $34(a0)
                bne.b   .4AF72
                add.w   d2,d0
                add.w   d3,d1
                bra.b   .4AFAC
.4AF72:
                sub.w   d2,d0
                sub.w   d3,d1
                subq.b  #$1,$35(a0)
                bne.b   .4AF92
                clr.w   $32(a0)
                move.w  $3A(a0),d2
                lsl.w   #$3,d2
                lea.l   (BellmiteShells).l,a1
                movem.w (a1,d2.w),d0-d1
.4AF92:
                movem.w d0-d1,$36(a0)
                add.w   (BellmiteX).l,d0
                add.w   (BellmiteY).l,d1
                movem.w d0-d1,$A(a0)
                rts
.4AFAC:
                movem.w d0-d1,$36(a0)
                addq.b  #$1,$35(a0)
                add.w   (BellmiteX).l,d0
                add.w   (BellmiteY).l,d1
                cmp.w   #$30,d0
                bcs.b   .4AFE2
                cmp.w   #$148,d0
                bhi.b   .4AFE2
                cmp.w   #$30,d1
                bcs.b   .4AFE2
                cmp.w   #$D0,d1
                bhi.b   .4AFE2
                movem.w d0-d1,$A(a0)
                rts
.4AFE2:
                st.b    $34(a0)
                bra.w   Upd_BellmiteShell
.4AFEA:
                movem.w (BellmiteX).l,d0-d1
                add.w   $36(a0),d0
                add.w   $38(a0),d1
                move.b  $3D(a0),d2
                ext.w   d2
                neg.b   $3D(a0)
                add.w   d2,d0
                sub.w   d2,d1
                movem.w d0-d1,$A(a0)
                rts
CancerData1:
                dc.w    $0014,$0064             ; x, y
                dc.w    $0170,$00AA             ; x, y
                dc.w    $FFFF
CancerData2:
                dc.w    $008C,$00DF             ; x, y
                dc.w    $FFFF
CancerData3:
                dc.w    $012C,$00DF             ; x, y
                dc.w    $FFFF
CancerData4:
                dc.w    $0014,$0064             ; x, y
                dc.w    $FFFF
; object definition: 32x26, 6 frames, gfx $54E08, 1 hit point, fires every ~34 frames, score 300, update Upd_Cancer, spawn Spawn_Cancer
Def_Cancer:
                dc.w    $1A03,$002E
                dc.w    $0340,$0005,$0001,$0022,$0005,$4E08,$0000,$01A0
                dc.w    $0004,$B054,$0004,$B05C
                dc.l    Upd_Cancer
                dc.l    Spawn_Cancer
                dc.w    $0000,$0300
CancerAnimRight:
                dc.w    $0304,$05FF
CancerAnimLeft:
                dc.w    $0001,$02FF,$0004,$0002,$0018,$0016,$0002,$0003
                dc.w    $001B,$0014,$0004,$0004,$0018,$0013,$0005,$0004
                dc.w    $0018,$0014,$0004,$0003,$0019,$0015,$0005,$0003
                dc.w    $0018,$0015
SlitherScatter:
                dc.w    $0000,$FFFC,$FFFE,$FFFC,$FFFC,$FFFC,$FFFC,$FFFE
                dc.w    $FFFC,$0000,$FFFC,$0002,$FFFC,$0004,$FFFE,$0004
                dc.w    $0000,$0004
SlitherHeadFrames:
                dc.w    $0000,$0009,$0015,$001E,$002A,$0036,$0042,$004B
                dc.w    $0051,$005D,$0063,$006C,$0072,$0084,$0090,$0099
; object definition: 32x29, 16 frames, gfx $5CDC8, score 500, update Upd_Slither, spawn Spawn_Slither
Def_SlitherHead:
                dc.w    $1D03,$002E,$03A0,$0000,$0000,$0000,$0005,$CDC8
                dc.w    $0000,$01D0,$0004,$B0F8,$0004,$B10A
                dc.l    Upd_Slither
                dc.l    Spawn_Slither
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
; object definition: 32x29, 16 frames, gfx $607C8, score 300, update Upd_Slither, spawn Spawn_Slither
Def_SlitherBody:
                dc.w    $1D03,$002E,$03A0,$0000,$0000,$0000,$0006,$07C8
                dc.w    $0000,$01D0,$0004,$B0F8,$0004,$B1B2
                dc.l    Upd_Slither
                dc.l    Spawn_Slither
                dc.w    $0000,$0300,$0006,$0004,$0012,$0016,$0006,$0003
                dc.w    $0012,$0016,$0005,$0005,$0014,$0014,$0004,$0003
                dc.w    $0016,$0015,$0004,$0004,$0016,$0012,$0004,$0003
                dc.w    $0017,$0014,$0005,$0003,$0016,$0014,$0005,$0002
                dc.w    $0014,$0016,$0007,$0003,$0012,$0015,$0007,$0003
                dc.w    $0013,$0016,$0007,$0002,$0013,$0016,$0005,$0004
                dc.w    $0015,$0014,$0005,$0006,$0016,$0012,$0004,$0005
                dc.w    $0017,$0013,$0005,$0004,$0015,$0015,$0005,$0004
                dc.w    $0015,$0015
; object definition: 32x23, 16 frames, gfx $641C8, score 300, update Upd_Slither, spawn Spawn_Slither
Def_SlitherTail:
                dc.w    $1703,$002E,$02E0,$0000,$0000,$0000,$0006,$41C8
                dc.w    $0000,$0170,$0004,$B0F8,$0004,$B25A
                dc.l    Upd_Slither
                dc.l    Spawn_Slither
                dc.w    $0000,$0300,$0003,$0002,$0011,$0012,$0003,$0001
                dc.w    $0010,$0012,$0003,$0001,$0012,$0012,$0002,$0002
                dc.w    $0013,$0012,$0002,$0003,$0012,$0010,$0004,$0002
                dc.w    $0012,$0012,$0003,$0002,$0013,$0012,$0004,$0003
                dc.w    $0011,$0012,$0003,$0002,$0011,$0012,$0003,$0003
                dc.w    $0012,$0012,$0003,$0003,$0012,$0012,$0003,$0003
                dc.w    $0012,$0011,$0002,$0003,$0014,$0010,$0002,$0003
                dc.w    $0012,$0011,$0001,$0002,$0012,$0012,$0003,$0002
                dc.w    $0010,$0012
; object definition: 32x28, 16 frames, gfx $57708, fires every ~10 frames, score 200, update Upd_Pursuer, spawn Spawn_Pursuer
Def_Pursuer:
                dc.w    $1C03,$002E,$0380,$0000,$0000,$000A
                dc.w    $0005,$7708,$0000,$01C0,$0004,$B302,$0004,$B314
                dc.l    Upd_Pursuer
                dc.l    Spawn_Pursuer
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
PursuerSteps:
                dc.w    $0000,$FFFD,$0002,$FFFD,$0003,$FFFD,$0003,$FFFE
                dc.w    $0003,$0000,$0003,$0002,$0003,$0003,$0002,$0003
                dc.w    $0000,$0003,$FFFE,$0003,$FFFD,$0003,$FFFD,$0002
                dc.w    $FFFD,$0000,$FFFD,$FFFE,$FFFD,$FFFD,$FFFE,$FFFD
; object definition: 32x3, 4 frames, gfx $56188, update Upd_CheetahBeam
Def_CheetahBeam:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0005,$6188
                dc.w    $0000,$0030,$0004,$B41C,$0004,$B3FC
                dc.l    Upd_CheetahBeam
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0001,$0203,$FF00
; object definition: 48x41, 4 frames, gfx $5AF08, score 800, update Upd_Cheetah, spawn Spawn_Cheetah
Def_Cheetah:
                dc.w    $2904
                dc.w    $002C,$07B0,$0003,$0000,$0000,$0005,$AF08,$0000
                dc.w    $03D8,$0004,$B44A,$0004,$B47A
                dc.l    Upd_Cheetah
                dc.l    Spawn_Cheetah
                dc.w    $0000,$0800,$0001,$0203,$0201,$FF00
; object definition: 32x20, 8 frames, gfx $56308, score 400, update Upd_MidCheetah, spawn Spawn_MidCheetah
Def_MidCheetah:
                dc.w    $1403,$002E
                dc.w    $0280,$0002,$0000,$0000,$0005,$6308,$0000,$0140
                dc.w    $0004,$B49A,$0004,$B4A4
                dc.l    Upd_MidCheetah
                dc.l    Spawn_MidCheetah
                dc.w    $0000,$0400,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0001,$0203,$0405,$0607,$FF00,$0001
                dc.w    $0003,$0017,$000F,$0003,$0003,$0015,$000C,$0001
                dc.w    $0002,$0018,$000B,$0001,$0002,$0019,$000D,$0002
                dc.w    $0002,$0017,$0010,$0001,$0005,$0018,$000D,$0001
                dc.w    $0006,$000E,$000C,$0001,$0005,$0018,$000D
BellmiteBounce:
                dc.w    $0809,$0A0B,$0C0D,$0E0F,$0001,$0203,$0405,$0607
BellmiteShells:
                dc.w    $FFF9,$000D,$0000,$0000,$FFFA,$0020,$0000,$0000
                dc.w    $0009,$0017,$0000,$0000,$000B,$FFFE,$0000,$0000
                dc.w    $001E,$FFF6,$0000,$0000,$001F,$000D,$0000,$0000
                dc.w    $0019,$001D,$0000,$0000,$FFFB,$FFF7,$0000,$0000
BellmiteX:
                dc.w    $0000
BellmiteY:
                dc.w    $0000,$0008,$0009,$000A,$000B,$000C,$000D,$000E
                dc.w    $000F,$0000,$0001,$0002,$0003,$0004,$0005,$0006
                dc.w    $0007
ShellScatter:
                dc.w    $0000,$FFFC,$0002,$FFFC,$0004,$FFFC,$0004,$FFFE
                dc.w    $0004,$0000,$0004,$0002,$0004,$0004,$0002,$0004
                dc.w    $0000,$0004,$FFFE,$0004,$FFFC,$0004,$FFFC,$0002
                dc.w    $FFFC,$0000,$FFFC,$FFFE,$FFFC,$FFFC,$FFFE,$FFFC
BellmiteSteps:
                dc.w    $0000,$FFFE,$0001,$FFFE,$0002,$FFFE,$0002,$FFFF
                dc.w    $0002,$0000,$0002,$0001,$0002,$0002,$0001,$0002
                dc.w    $0000,$0002,$FFFF,$0002,$FFFE,$0002,$FFFE,$0001
                dc.w    $FFFE,$0000,$FFFE,$FFFF,$FFFE,$FFFE,$FFFF,$FFFE
ShellFormations:
                dc.w    $0001,$0305,$0204,$0607,$0506,$0304,$0001,$0702
                dc.w    $0704,$0603,$0502,$0100,$0201,$0403,$0700,$0605
; object definition: 48x48, 1 frame, gfx $66FC8, score 1000, update Upd_Bellmite, spawn Spawn_Bellmite
Def_Bellmite:
                dc.w    $3004,$002C,$0900,$0000,$0000,$0000,$0006,$6FC8
                dc.w    $0000,$0480,$0004,$B660,$0004,$B620
                dc.l    Upd_Bellmite
                dc.l    Spawn_Bellmite
                dc.w    $0000,$1000,$0011,$0012,$0010,$0010
; object definition: 32x28, 2 frames, gfx $678C8, score 500, update Upd_BellmiteShell, spawn Spawn_Bellmite
Def_BellmiteShell:
                dc.w    $1C03,$002E,$0380,$0001,$0000,$0000,$0006,$78C8
                dc.w    $0000,$01C0,$0004,$B660,$0004,$B650
                dc.l    Upd_BellmiteShell
                dc.l    Spawn_Bellmite
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
