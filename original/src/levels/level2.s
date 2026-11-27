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
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
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
                move.w  $6(a1),d0                   ; corner 0-3
                move.w  d0,$34(a0)
                move.l  #GougerAnims,d1             ; animation for that corner (3 bytes each)
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
                tst.b   $32(a0)                     ; already leaping?
                bmi.b   .4A5EE
                subq.w  #$1,$A(a0)                  ; scrolls with the map
                move.w  $A(a0),d0
                sub.w   (ShipPos).w,d0              ; distance to the ship in x
                tst.w   $34(a0)
                beq.b   .4A5AC
                cmpi.w  #$3,$34(a0)
                bne.b   .4A5B8
.4A5AC:
                cmp.w   #$50,d0                     ; within 80 pixels: leap
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
                lea.l   (GougerLeaps).l,a1          ; dx, dy for the corner
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
                cmpi.w  #$A0,$C(a0)                 ; near the floor or ceiling:
                bhi.b   .4A608
                cmpi.w  #$2D,$C(a0)
                bhi.b   .4A61A
.4A608:
                asr.w   #$1,d0                      ; half speed
                asr.w   #$1,d1
                st.b    $22(a0)
                cmpi.w  #$2,$34(a0)
                bne.b   .4A61A
                moveq   #0,d0
.4A61A:
                tst.b   $28(a0)                     ; flashing (hit): pause
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
                move.w  $6(a1),d7                   ; number - 1
                moveq   #0,d6                   ; first start delay 0
                moveq   #4,d5                   ; count to every 5th
.4A640:
                subq.w  #$1,d5
                bpl.b   .4A64C
                move.w  (ShipPos).w,d1          ; every 5th: y = the ship's x (ShipPos is x)
                moveq   #4,d5
                bra.b   .4A658
.4A64C:
                moveq   #105,d0                 ; the others at a random height 80-184
                jsr     (jt_Random).w
                add.w   #$50,d0
                move.w  d0,d1
.4A658:
                move.w  #$174,d0                    ; enter at the right
                moveq   #1,d2                   ; 1 hit point
                jsr     (jt_ObjCreate).w
                move.w  d6,$32(a0)                  ; 20 frames apart
                move.b  #$1,$21(a0)             ; explosion type 1
                move.b  #$1,$34(a0)             ; bob 1 pixel,
                moveq   #7,d0                   ; first bob after 0-6 steps
                jsr     (jt_Random).w
                move.b  d0,$35(a0)
                clr.w   $38(a0)                 ; step 0: fly left
                move.w  #$7FFF,$36(a0)              ; 70%: never dives
                moveq   #100,d0
                jsr     (jt_Random).w
                cmp.w   #$46,d0
                bcs.b   .4A6A0
                moveq   #33,d0                      ; 30%: dives after 25-57 frames
                jsr     (jt_Random).w
                add.w   #$19,d0
                move.w  d0,$36(a0)
.4A6A0:
                jsr     (jt_ObjInsert).w
                add.w   #$14,d6
                dbra    d7,.4A640
                rts
Upd_Wick:
                tst.w   $32(a0)                     ; waiting to start?
                bmi.b   .4A6BA
                subq.w  #$1,$32(a0)
                rts
.4A6BA:
                moveq   #0,d0
                move.b  $38(a0),d0              ; step: 0 left, 1 dive left, 2 dive right
                bne.b   .4A6E4                  ; diving: no bob
                eori.b  #$FF,$39(a0)                ; every other frame:
                beq.b   .4A6E4
                move.b  $34(a0),d1
                ext.w   d1
                add.w   d1,$C(a0)                   ; bob up and down
                subq.b  #$1,$35(a0)             ; 7 bobs each way
                bpl.b   .4A6E4
                neg.b   $34(a0)                 ; then turn
                move.b  #$6,$35(a0)
.4A6E4:
                lsl.w   #$2,d0
                lea.l   (WickSteps).l,a1            ; dx, dy: fly left, or dive / climb
                movem.w (a1,d0.w),d1-d2
                add.w   d1,$A(a0)
                add.w   d2,$C(a0)
                move.w  $A(a0),d0               ; off the screen:
                cmp.w   #$10,d0
                bcs.b   .4A750
                cmp.w   #$173,d0
                bhi.b   .4A750
                cmpi.w  #$C4,$C(a0)
                bhi.b   .4A750
                subq.w  #$1,$36(a0)             ; time to dive?
                bpl.b   .4A740
                add.w   #$14,d0                 ; centre x
                cmp.w   (ShipPos).w,d0          ; right of the ship:
                bhi.b   .4A742                  ; dive left
                move.b  #$2,$38(a0)             ; ship to the right: dive down-right
                lea.l   (WickAnimDiveRight).l,a1
.4A72E:
                move.l  a1,$2A(a0)
                move.w  #$7FFF,$36(a0)          ; no more turns
                clr.b   $20(a0)
                clr.w   $1E(a0)
.4A740:
                rts
.4A742:
                move.b  #$1,$38(a0)             ; dive down-left
                lea.l   (WickAnimDiveLeft).l,a1
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
; open 21 frames, close), the wait shortening by 10 frames each time
; from 100 (down to 10; a hit on the core puts it back to 100).
; After the boss dies, random explosions.  Before that it runs the
; Broods (UpdateBroods).
LevelFrame:
                tst.b   (BossStarted).l         ; boss started?
                bne.b   .4A7D6
                cmpi.w  #$A0A,(ScrollX).w       ; no: reached it yet?
                bcs.w   UpdateBroods            ; before then, the Broods
                st.b    (BossStarted).l
                clr.b   (ScrollActive).w        ; stop the scroll
                move.w  #$B3,d0                 ; the core, at the eye
                move.w  #$80,d1
                moveq   #-1,d2                  ; indestructible: hits counted by its update
                lea.l   (Def_GomanderCore).l,a2
                jsr     (jt_ObjCreate).w
                clr.w   $32(a0)                 ; damage seen
                jsr     (jt_ObjInsert).w
                move.w  #$64,(EyeInterval).l    ; 100 frames between eye openings,
                clr.w   (EyeTimer).l            ; the first at once
                clr.w   (EyeFrame).l            ; eye closed
                st.b    (MusicFadeReq).w        ; fade the level music out
                rts
.4A7D6:
                tst.b   (BossDead).l
                bne.w   BossExplosions          ; dead: explosions
                movea.l (EyeState).l,a1         ; eye state routine
                jmp     (a1)
Eye_Wait:
                subq.w  #$1,(EyeTimer).l        ; waiting:
                bpl.b   .4A802
                move.l  #.4A804,(EyeState).l    ; then open
                move.b  #$3,(EyeSteps).l        ; in 3 steps
.4A802:
                rts
.4A804:
                subq.w  #$1,(EyeTimer).l
                bpl.b   .4A85A
                tst.b   (EyeSteps).l            ; opened?
                bne.b   .4A828
                move.l  #.4A85C,(EyeState).l    ; then close
                move.b  #$3,(EyeSteps).l        ; in 3 steps
                rts
.4A828:
                move.w  #$2,(EyeTimer).l        ; a step every 3 frames
                addi.l  #$10,(EyeFramePtr).l    ; next 2x4 cells
                addq.w  #$1,(EyeFrame).l        ; and core frame
                movea.l (EyeFramePtr).l,a0
                bsr.w   Eye_Draw                ; write them into the map
                subq.b  #$1,(EyeSteps).l
                bne.b   .4A85A
                move.w  #$14,(EyeTimer).l       ; fully open: stay 21 frames
.4A85A:
                rts
.4A85C:
                subq.w  #$1,(EyeTimer).l
                bpl.b   .4A8B4
                move.w  #$2,(EyeTimer).l        ; a step every 3 frames
                subi.l  #$10,(EyeFramePtr).l    ; previous cells
                subq.w  #$1,(EyeFrame).l
                movea.l (EyeFramePtr).l,a0
                bsr.w   Eye_Draw                ; write them into the map
                subq.b  #$1,(EyeSteps).l
                bne.b   .4A8B4                  ; closed:
                move.w  (EyeInterval).l,d0      ; next wait 10 frames shorter,
                cmp.w   #$A,d0                  ; down to 10
                bls.b   .4A8A4
                sub.w   #$A,d0
                move.w  d0,(EyeInterval).l
.4A8A4:
                move.w  d0,(EyeTimer).l
                move.l  #Eye_Wait,(EyeState).l  ; then wait again
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
                moveq   #100,d0                 ; y = 100 + random(100)
                jsr     (jt_Random).w
                move.w  d0,d1
                add.w   #$64,d1
                moveq   #126,d0                 ; x = 120 + random(126)
                jsr     (jt_Random).w
                add.w   #$78,d0
                moveq   #-1,d2
                lea.l   (Def_GomanderCore).l,a2 ; as a plain explosion
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)              ; exploding at once
                clr.l   $6(a0)
                moveq   #3,d0                   ; type 0-2
                jsr     (jt_Random).w
                move.b  d0,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
Upd_GomanderCore:
                movea.l (PalettePtr).w,a1       ; colour table in the copper list
                tst.b   (BossFlash).l           ; flashed last frame:
                beq.b   .4A922
                clr.b   (BossFlash).l
                bsr.b   .4A982                  ; restore the colours
.4A922:
                move.w  (EyeFrame).l,$1E(a0)    ; frame (and hit box) follows the eye
                clr.b   $20(a0)
                move.w  $26(a0),d0              ; hit?
                cmp.w   $32(a0),d0
                beq.b   .4A980
                move.w  d0,$32(a0)
                move.w  #$64,(EyeInterval).l    ; the eye opens slowly again: 100 frames
                move.w  #$FFF,d1                ; flash colours 0, 1, 2 and 13 white
                move.w  d1,$2(a1)
                move.w  d1,$6(a1)
                move.w  d1,$A(a1)
                move.w  d1,$36(a1)
                st.b    (BossFlash).l           ; for one frame
                move.b  #$3,$28(a0)             ; and the core itself for 3
                cmp.w   #$1E,d0                 ; 30 hits:
                bcs.b   .4A980
                bsr.b   .4A982                  ; dead
                st.b    (BossDead).l
                st.b    (LevelComplete).w
                move.l  #$9000,d0               ; 9000 points
                jmp     (jt_AddScore).w
.4A980:
                rts
.4A982:
                move.w  #$555,$2(a1)            ; the eye's colours
                move.w  #$BBB,$6(a1)
                move.w  #$777,$A(a1)
                move.w  #$FF0,$36(a1)
                rts
Spawn_Worm:
                moveq   #10,d7                  ; 11 segments, priority 10 down to 0
                moveq   #0,d6                   ; d6 = start delay, 5 frames apart
                moveq   #11,d5                  ; d5 = explosion delay when the boss dies
                lea.l   (WormSegments).l,a3     ; definition and animation per segment
.4A9A8:
                move.w  #$160,d0                ; parked off screen until its turn
                moveq   #60,d1
                moveq   #-1,d2                  ; indestructible
                movea.l (a3)+,a2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)                 ; segment frames come from the path
                move.b  d7,$4(a0)
                movea.l (a3)+,a2
                move.l  a2,$2A(a0)
                cmpa.l  #WormEyeAnim,a2         ; an eye?
                bne.b   .4A9D0
                st.b    $22(a0)                 ; eyes animate
.4A9D0:
                move.w  d6,$34(a0)
                clr.w   $32(a0)                 ; $32: 1 = the leading segment
                clr.w   $3A(a0)                 ; path step
                clr.b   $3C(a0)                 ; eye not shot
                move.b  d5,$3D(a0)
                cmp.w   #$A,d7                  ; the first segment
                bne.b   .4A9F0
                move.b  #$1,$32(a0)             ; leads
.4A9F0:
                jsr     (jt_ObjInsert).w
                addq.w  #$5,d6
                subq.w  #$1,d5
                dbra    d7,.4A9A8
                move.l  #WormFirstPath,(WormPath).l ; the first path
                rts
Upd_Worm:
                tst.b   (BossDead).l            ; boss dead:
                beq.b   .4AA22
                subq.b  #$1,$3D(a0)             ; each segment in turn
                bpl.b   .4AA22
                move.b  #$1,$5(a0)              ; explodes
                clr.l   $6(a0)
                rts
.4AA22:
                tst.b   $32(a0)                 ; leader finished its path?
                bmi.w   .4AB1E
.4AA2A:
                tst.w   $34(a0)                 ; waiting?
                bmi.b   .4AA36
                subq.w  #$1,$34(a0)
                rts
.4AA36:
                tst.b   $33(a0)                 ; on a path?
                bne.b   .4AA5A
                movea.l (WormPath).l,a1         ; no: start the current one
                move.w  (a1)+,$A(a0)            ; start x
                move.w  (a1)+,$C(a0)            ; start y
                move.l  a1,$36(a0)              ; then steps and the dx, dy, frame tables
                clr.w   $3A(a0)
                clr.w   $26(a0)                 ; hits count from the start of the pass
                st.b    $33(a0)                 ; on the path
.4AA5A:
                movea.l $36(a0),a1
                move.w  $3A(a0),d0              ; step
                move.w  (a1)+,d1                ; number of steps
                bsr.w   .4AB14                  ; dx
                add.w   d2,$A(a0)
                bsr.w   .4AB14                  ; dy
                add.w   d2,$C(a0)
                tst.b   $22(a0)                 ; an eye?
                bne.b   .4AA84
                bsr.w   .4AB14                  ; no: frame from the path
                move.b  d2,$1F(a0)
                bra.b   .4AADC
.4AA84:
                tst.b   $3C(a0)                 ; eye already shot?
                bne.b   .4AADC
                tst.w   $26(a0)                 ; or not hit:
                beq.b   .4AADC
                movem.l d0-d1/a0,-(a7)
                move.l  #WormEyeShotAnim,$2A(a0) ; hit: the shot-eye animation
                clr.b   $20(a0)
                clr.w   $1E(a0)
                movem.w $A(a0),d0-d1            ; and an explosion over it
                moveq   #-1,d2
                lea.l   (Def_WormEye).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)              ; exploding at once
                clr.l   $6(a0)
                move.b  #$1E,$4(a0)             ; drawn on top
                jsr     (jt_ObjInsert).w
                move.l  #$200,d0                ; 200 points
                jsr     (jt_AddScore).w
                movem.l (a7)+,d0-d1/a0
                st.b    $3C(a0)                 ; shot (until the end of this pass)
.4AADC:
                cmp.w   d1,d0                   ; end of the path?
                bcc.b   .4AAE6
                addq.w  #$1,$3A(a0)             ; no: next step
                rts
.4AAE6:
                move.w  #$FFFF,$A(a0)           ; yes: park off screen
                tst.b   $3C(a0)                 ; eye shot:
                beq.b   .4AAFE
                move.l  #WormEyeAnim,$2A(a0)    ; open it again
                clr.b   $3C(a0)
.4AAFE:
                clr.b   $33(a0)                 ; off the path
                move.w  #$55,$34(a0)            ; 85 frames before the next
                tst.b   $32(a0)                 ; the leader
                beq.b   .4AB12
                st.b    $32(a0)                 ; moves the Worm on to the next path
.4AB12:
                rts
.4AB14:
                movea.l (a1)+,a2                ; table pointer
                move.b  (a2,d0.w),d2            ; entry for this step
                ext.w   d2
                rts
.4AB1E:
                move.b  #$1,$32(a0)             ; still the leader
                movea.l (WormPath).l,a1
                adda.l  #$12,a1                 ; next path (18 bytes each)
                cmpa.l  #WormPath,a1            ; past the last?
                bcs.b   .4AB42
                lea.l   (WormPaths).l,a1        ; back to the first
                st.b    (LevelComplete).w       ; and the level ends
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
                bsr.b   .4AB9E                  ; run Brood1, then fall through for Brood2
                lea.l   (Brood2).l,a0
.4AB9E:
                tst.b   $4(a0)                  ; destroyed?
                beq.b   .4ABAC
                movea.l $18(a0),a1              ; yes: draw the destroyed cells
                clr.l   (a0)                    ; and stop
                bra.b   Brood_DrawCells
.4ABAC:
                move.l  (a0),d0                 ; current state routine
                beq.b   BroodRts
                movea.l d0,a1
                jmp     (a1)
Brood_Wait:
                move.w  $8(a0),d0               ; appear at this scroll x
                cmp.w   (ScrollX).w,d0
                bne.b   BroodRts
                move.w  $E(a0),d1               ; the Brood's y
                move.w  #$16B,d0                ; at the right edge
                move.w  #$1388,d2               ; 5000 hit points: only the 35-hit check counts
                lea.l   (Def_Brood).l,a2        ; the invisible target
                movea.l a0,a3
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)                 ; no animation
                move.b  #$2,$21(a0)             ; explosion type 2
                move.l  a3,$32(a0)              ; its record
                move.w  $10(a3),$1E(a0)         ; frame
                move.w  #$7D,$3A(a0)            ; a Zoid after 125 frames
                move.w  #$AF,$3C(a0)            ; and another after 175
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                move.l  #Brood_Open,(a0)        ; next: open
BroodRts:
                rts
Brood_Open:
                move.w  $A(a0),d0               ; open at this scroll x
                cmp.w   (ScrollX).w,d0
                bne.b   BroodRts
                clr.b   $6(a0)                  ; in 4 steps
                move.b  #$4,$7(a0)
                move.l  #.4AC20,(a0)            ; then opening
                rts
.4AC20:
                subq.b  #$1,$6(a0)              ; every 6 frames
                bpl.b   .4AC50
                move.b  #$5,$6(a0)
                addi.l  #$18,$1C(a0)            ; next cell frame
                addq.w  #$1,$12(a0)             ; and target frame
                movea.l a0,a3
                movea.l $1C(a0),a1              ; write its cells into the map
                bsr.w   Brood_DrawCells
                movea.l a3,a0
                subq.b  #$1,$7(a0)              ; 4 steps:
                bne.b   .4AC50
                move.l  #.4AC52,(a0)            ; then wait to close
.4AC50:
                rts
.4AC52:
                move.w  $C(a0),d0               ; close at this scroll x
                cmp.w   (ScrollX).w,d0
                bne.b   .4AC50
                clr.b   $6(a0)                  ; in 4 steps
                move.b  #$4,$7(a0)
                move.l  #.4AC6E,(a0)            ; then closing
                rts
.4AC6E:
                subq.b  #$1,$6(a0)              ; every 6 frames
                bpl.b   .4AC9A
                move.b  #$5,$6(a0)
                subi.l  #$18,$1C(a0)            ; previous cell frame
                subq.w  #$1,$12(a0)
                movea.l a0,a3
                movea.l $1C(a0),a1
                bsr.w   Brood_DrawCells         ; write its cells into the map
                movea.l a3,a0
                subq.b  #$1,$7(a0)
                bne.b   .4AC9A
                clr.l   (a0)                    ; closed: done
.4AC9A:
                rts
Upd_Brood:
                tst.w   $3A(a0)                 ; first Zoid due?
                beq.b   .4ACAE
                subq.w  #$1,$3A(a0)
                bne.b   .4ACAE
                nop
                bsr.w   .4AD0E                  ; release it
.4ACAE:
                tst.w   $3C(a0)                 ; second Zoid due?
                beq.b   .4ACC0
                subq.w  #$1,$3C(a0)
                bne.b   .4ACC0
                nop
                bsr.w   .4AD0E                  ; release it
.4ACC0:
                move.w  $A(a0),d0               ; scroll with the map
                subq.w  #$1,d0
                cmp.w   #$10,d0                 ; off the left edge: remove
                bhi.b   .4ACD0
                jmp     (jt_ObjKillSelf).w
.4ACD0:
                move.w  d0,$A(a0)
                movea.l $32(a0),a1              ; its record
                move.w  $12(a1),d0              ; frame follows the cells
                move.w  d0,$1E(a0)
                cmpi.w  #$23,$26(a0)            ; 35 hits:
                bcs.b   .4AD0C
                st.b    $4(a1)                  ; destroyed (UpdateBroods draws the wreck)
                move.b  #$1,$5(a0)              ; explode
                clr.l   $6(a0)
                cmp.w   #$5,d0                  ; open (frame 5+):
                bcs.b   .4AD02
                subi.w  #$2B,$C(a0)             ; the explosion 43 pixels higher
.4AD02:
                move.l  #$700,d0                ; 700 points
                jmp     (jt_AddScore).w
.4AD0C:
                rts
.4AD0E:
                movea.l a0,a1                   ; a1 = the Brood
                movem.w $A(a1),d0-d1
                add.w   #$A,d0                  ; from its middle
                addq.w  #$8,d1
                cmp.w   #$64,d1                 ; upper Brood:
                bhi.b   .4AD26
                sub.w   #$18,d1                 ; 24 pixels higher
.4AD26:
                moveq   #5,d2                   ; 5 hit points
                lea.l   (Def_Zoid).l,a2
                jsr     (jt_ObjCreate).w
                cmpi.w  #$5A,$C(a0)             ; upper half of the screen:
                bhi.b   .4AD40
                st.b    $32(a0)                 ; $32 = -1: paths mirrored for the ceiling
                bra.b   .4AD44
.4AD40:
                clr.b   $32(a0)                 ; lower half: 0
.4AD44:
                moveq   #100,d0                 ; path: 71% the 37-step one, 29% the 78-step one
                jsr     (jt_Random).w
                moveq   #0,d2
                cmp.w   #$46,d0
                bhi.b   .4AD54
                moveq   #1,d2
.4AD54:
                moveq   #37,d1
                move.b  d2,$33(a0)              ; path number
                bne.b   .4AD5E
                moveq   #78,d1
.4AD5E:
                clr.w   $34(a0)                 ; path step
                move.w  d1,$38(a0)              ; steps on the path
                clr.b   $36(a0)
                clr.w   $3C(a0)
                move.w  $26(a0),$3A(a0)         ; damage so far: a hit ends the path early
                jsr     (jt_ObjInsert).w
                movea.l a1,a0
                rts
Upd_Zoid:
                tst.b   $36(a0)                 ; off its path?
                bne.w   .4AE1A
                move.w  $26(a0),d0              ; hit:
                cmp.w   $3A(a0),d0
                bne.b   .4ADE8                  ; leave the path
                lea.l   ($7252F).l,a1           ; path 1: dx table, dy 38 bytes on
                lea.l   $26(a1),a2
                tst.b   $33(a0)                 ; path 1?
                bne.b   .4ADA8
                lea.l   ($72496).l,a1           ; path 0: dx table, dy 78 bytes on
                lea.l   $4E(a1),a2
.4ADA8:
                move.w  $34(a0),d2              ; step
                addq.w  #$1,$34(a0)
                movem.w $A(a0),d0-d1
                move.b  (a1,d2.w),d3
                move.b  (a2,d2.w),d4
                cmp.b   #$7F,d4                 ; end of the path:
                beq.b   .4ADE8                  ; go free
                ext.w   d3
                ext.w   d4
                tst.b   $32(a0)                 ; lower Brood:
                bmi.b   .4ADD0
                neg.w   d4                      ; mirror dy (the tables are for the ceiling)
.4ADD0:
                add.w   d3,d0
                add.w   d4,d1
                cmp.w   #$20,d0                 ; outside x $20-$12E:
                bcs.b   .4ADE8                  ; go free
                cmp.w   #$12E,d0
                bhi.b   .4ADE8
                movem.w d0-d1,$A(a0)
                rts
.4ADE8:
                move.b  #$1,$36(a0)             ; free
                move.l  #ZoidAnim,$2A(a0)       ; animate
                st.b    $22(a0)
                clr.b   $20(a0)
                move.w  #$5,$1E(a0)             ; from frame 5
                clr.w   $32(a0)                 ; hover
                clr.w   $34(a0)
                move.w  #$F,$38(a0)             ; for 15 frames
                move.w  $26(a0),$3A(a0)         ; damage seen
                rts
.4AE1A:
                subq.w  #$1,$38(a0)             ; time for a new heading?
                bmi.w   .4AEB0
                tst.b   $3D(a0)                 ; still hovering:
                beq.b   .4AE7E                  ; wait
                move.w  $26(a0),d0              ; hit?
                cmp.w   $3A(a0),d0
                beq.b   .4AE50
                move.w  d0,$3A(a0)              ; yes:
                clr.w   $32(a0)                 ; drop straight down
                move.w  #$8,$34(a0)             ; 8 pixels a frame
                move.w  #$C0,d0                 ; to 16 pixels above y $C0
                sub.w   $C(a0),d0
                lsr.w   #$3,d0
                subq.w  #$2,d0
                move.w  d0,$38(a0)
.4AE50:
                movem.w $32(a0),d0-d1           ; dx, dy
                movem.w $A(a0),d2-d3
                add.w   d0,d2
                add.w   d1,d3
                cmp.w   #$30,d2                 ; would leave x $30-$12E
                blt.b   .4AE80
                cmp.w   #$12E,d2
                bhi.b   .4AE80
                cmp.w   #$30,d3                 ; or y $30-$C0:
                blt.b   .4AE80
                cmp.w   #$C0,d3
                bhi.b   .4AE80
                movem.w d2-d3,$A(a0)            ; no: move
.4AE7E:
                rts
.4AE80:
                lsr.w   $38(a0)                 ; bounce: halve the time left
                moveq   #0,d0
                moveq   #0,d1
                move.b  $37(a0),d1              ; direction
                lea.l   (ZoidTurns).l,a1        ; turned direction for a bounce
                move.b  (a1,d1.w),d0
                move.b  d0,$37(a0)
                lsl.w   #$2,d0                  ; its dx, dy
                lea.l   (ZoidSteps).l,a1
                movem.w (a1,d0.w),d2-d3
                movem.w d2-d3,$32(a0)
                bra.b   .4AE50
.4AEB0:
                st.b    $3D(a0)                 ; moving
                subq.b  #$1,$3C(a0)             ; every 5th heading
                bpl.b   .4AED2
                move.b  #$4,$3C(a0)             ; aims at the ship
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                bra.b   .4AED8
.4AED2:
                moveq   #16,d0                  ; the others: a random direction
                jsr     (jt_Random).w
.4AED8:
                move.b  d0,$37(a0)              ; direction 0-15
                move.w  d0,d1
                moveq   #100,d0                 ; 91%: slow (2 pixels a frame), 9% fast (4)
                jsr     (jt_Random).w
                cmp.w   #$5A,d0
                bhi.b   .4AEEE
                add.w   #$10,d1
.4AEEE:
                lsl.w   #$2,d1                  ; dx, dy for it
                lea.l   (ZoidSteps).l,a1
                movem.w (a1,d1.w),d2-d3
                movem.w d2-d3,$32(a0)
                moveq   #100,d0                 ; for 20-119 frames
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
; at random heights 80-184; every 5th starts at y = the ship's x (it reads
; ShipPos, the x, where the y is at $F0).  They fly left 5 px a frame,
; bobbing up and down; 30% of them dive after 25-57 frames, down-left if
; the ship is to their left, otherwise down-right (WickSteps).
; (16x13, 3 frames, gfx $67516, 1 hit point, score 100, update Upd_Wick, spawn Spawn_Wick)
Def_Wick:
                dc.w    $0D02,$0030
                dc.w    $00D0,$0002,$0001,$0000,$0006,$7516,$0000,$0068
                dc.w    $0004,$AFCC,$0004,$AFD8
                dc.l    Upd_Wick
                dc.l    Spawn_Wick
                dc.w    $0000,$0100,$0001,$02FF
WickAnimDiveLeft:
                dc.w    $0304,$05FF
WickAnimDiveRight:
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
; target at the boss's eye, its frame (and hit box) following the eye.
; Each hit flashes colours 0, 1, 2 and 13 (PalettePtr) white for a frame
; and resets the eye's interval to 100 frames; after 30 hits the boss
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
; level B), 5 frames apart.  Each eye can be shot out once per pass (200
; points) and then shows its "shot" frame until the pass ends.  When the
; leading segment finishes a path the Worm moves on to the next
; (WormPaths, 18 bytes each); each segment waits 85 frames after its
; pass.  After the last path the level ends.
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
; $72496/$7252F; mirrored for the lower Brood), hovers 15 frames, then
; flies in straight lines of 20-119 frames, every 5th aimed at the ship,
; the others random (ZoidSteps: 16 directions at 4 and at 2 pixels a
; frame, mostly 2), bouncing off x $30-$12E / y $30-$C0 (ZoidTurns).  A
; hit knocks it off its path, and when free drops it 8 pixels a frame
; towards the floor.
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
