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
; Stage 1, "Encounter".  Enemies: Pata-Pata, Bug, P-Staff, Scant, Bink,
; Cancer, Shell, Tabrok, the Blasters in the map, the POW Armor; the boss
; is Dobkeratops (drawn in the map; its tail and core are objects).
; All labels named; local .xxxxx labels keep their address.
;==============================================================================
                include "engine.i"

                org     $4A2E4
LevelHeader:
                dc.w    $601A,$0000,$15E4,$0000,$09FA,$0000,$0000,$0000
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
                dc.l    $4D300                  ; tiles: the start of level B
                dc.l    ScrollScript
                dc.l    TileAnims
                dc.l    MapPatches
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $5CA38               ; LvMusic: player in level B; samples $604F8 (9), data $60594, periods $60540
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $0988
                dc.l    WavesFrom_0988
                dc.w    $04A0
                dc.l    WavesFrom_04A0
                dc.w    $00A5
                dc.l    Waves
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
Waves:
                dc.w    $00CD,$0000,$0000
                dc.l    PataPataData1,$00000000,Def_PataPata
                dc.w    $0104,$0000,$0000
                dc.l    PataPataData2,$00000000,Def_PataPata
                dc.w    $014F,$0170,$0064
                dc.l    BugData1,$00040000,Def_Bug 
                dc.w    $0172,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $01B0,$0170,$007A
                dc.l    BugData2,$00040000,Def_Bug 
                dc.w    $01F0,$0000,$0000
                dc.l    PataPataData3,$00000000,Def_PataPata
                dc.w    $0224,$0000,$0000
                dc.l    PataPataData4,$00000000,Def_PataPata
                dc.w    $0244,$0000,$0000
                dc.l    PataPataData5,$00000000,Def_PataPata
                dc.w    $0250,$0000,$0000
                dc.l    PataPataData6,$00000000,Def_PataPata
                dc.w    $0280,$0000,$0000
                dc.l    PataPataData7,$00000000,Def_PataPata
                dc.w    $028A,$0170,$0064
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $02AA,$0000,$0000
                dc.l    PataPataData8,$00000000,Def_PataPata
                dc.w    $02C2,$0000,$0000
                dc.l    PataPataData9,$00000000,Def_PataPata
                dc.w    $02E2,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $02EC,$0000,$0000
                dc.l    PataPataData10,$00000000,Def_PataPata
                dc.w    $0322,$0000,$0000
                dc.l    PataPataData11,$00000000,Def_PataPata
                dc.w    $033C,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0370,$0170,$0084
                dc.l    $00000000,$00000000,Def_Scant
                dc.w    $037A,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $03BB,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $03EE,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0400,$0010,$00B6
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $0420,$0170,$00A6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0451,$0170,$0032
                dc.l    BugData2,$00040000,Def_Bug 
WavesFrom_04A0:
                dc.w    $04BA,$0170,$0064
                dc.l    BugData2,$00000000,Def_Bug 
                dc.w    $04D3,$0014,$00B6
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $04D4,$010E,$000B
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $04F0,$0000,$0000
                dc.l    $07350028,$0004BE32,Def_Cancer
                dc.w    $0547,$0000,$0000
                dc.l    $07350010,$0004BE40,Def_Cancer
                dc.w    $0565,$0000,$0000
                dc.l    $07350005,$0004BE4E,Def_Cancer
                dc.w    $058B,$0000,$0000
                dc.l    $07350010,$0004BE5C,Def_Cancer
                dc.w    $05AB,$0000,$0000
                dc.l    $07350008,$0004BE6A,Def_Cancer
                dc.w    $05B8,$0170,$00A6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0648,$0000,$0000
                dc.l    $0735003C,$0004BE7C,Def_Cancer
                dc.w    $0692,$0000,$0000
                dc.l    $073A0035,$0004BE8E,Def_Cancer
                dc.w    $0694,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $069B,$0000,$0000
                dc.l    $00000000,$00000000,Def_Shell
                dc.w    $06B5,$0170,$0057
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0708,$0170,$0046
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0720,$0128,$000B
                dc.l    BugData3,$0004FFFF,Def_Bug 
                dc.w    $088C,$0170,$0094
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $08E7,$0000,$0000
                dc.l    PataPataData12,$00000000,Def_PataPata
                dc.w    $08BD,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $092D,$0000,$0000
                dc.l    PataPataData13,$00000000,Def_PataPata
                dc.w    $0942,$0170,$0082
                dc.l    $0005FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0992,$0170,$0087
                dc.l    $0001FFFC,$00000000,$FFFFFFFF ; POW Armor
WavesFrom_0988:
                dc.w    $09A4,$0170,$0094
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $09E5,$010F,$000B
                dc.l    BugData3,$0009FFFF,Def_Bug 
                dc.w    $0A07,$00F7,$000B
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0A62,$0170,$0087
                dc.l    $0004FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0B28,$0170,$00A5
                dc.l    $00000000,$00000000,Def_Tabrok
                dc.w    $0BE5,$0170,$0046
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0BFE,$0170,$00A5
                dc.l    $00000000,$00000000,Def_Tabrok
                dc.w    $0D36,$0000,$0000
                dc.l    $00000000,$00000000,Def_DobkeratopsTail
                dc.w    $0DF2,$0170,$007D
                dc.l    $00000000,$00000000,Def_DobkeratopsCore
                dc.w    $7530   ; end: never reached
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
Spawn_PataPata:
                movea.l $6(a1),a3                   ; the group list
.4A752:
                move.w  (a3)+,d1                    ; y ($FFFF ends)
                bmi.b   .4A772
                move.w  #$170,d0                    ; enter at the right edge
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  (a3)+,$32(a0)               ; delay before it starts
                move.b  (a3)+,$1F(a0)               ; first animation frame
                clr.w   $34(a0)                     ; position in the wave table
                jsr     (jt_ObjInsert).w
                bra.b   .4A752
.4A772:
                rts
Upd_PataPata:
                tst.b   $32(a0)                     ; still waiting?
                beq.b   .4A780
                subq.b  #$1,$32(a0)
                rts
.4A780:
                lea.l   ($78FD8).l,a1               ; wave: 35 signed y steps (level B)
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d1
                ext.w   d1
                add.w   d1,$C(a0)                   ; bob up and down
                addq.w  #$1,d0
                cmp.w   #$23,d0
                bcs.b   .4A79E
                clr.w   d0
.4A79E:
                move.w  d0,$34(a0)
                subq.w  #$4,$A(a0)                  ; 4 pixels left a frame
                cmpi.w  #$20,$A(a0)                 ; gone off the left edge?
                bhi.b   .4A7B2
                jmp     (jt_ObjKillSelf).w
.4A7B2:
                rts
Spawn_Bug:
                move.w  $A(a1),d7                   ; number of Bugs - 1
                clr.w   d6
.4A7BA:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.l  $6(a1),$32(a0)              ; the path
                clr.w   $36(a0)
                move.w  $C(a1),$3A(a0)              ; extra x speed
                move.b  d6,$38(a0)                  ; start delay: 7 frames apart
                jsr     (jt_ObjInsert).w
                addq.b  #$7,d6
                dbra    d7,.4A7BA
                rts
Upd_Bug:
                move.w  $3A(a0),d0                  ; drift with its own x speed
                add.w   d0,$A(a0)
                tst.b   $38(a0)                     ; still waiting?
                beq.b   .4A800
                subq.b  #$1,$38(a0)
                rts
.4A800:
                movea.l $32(a0),a1                  ; path: steps, dx, dy, frame tables
                move.w  $36(a0),d0                  ; step number
                move.w  (a1)+,d1
                bsr.b   .4A832
                add.w   d2,$A(a0)                   ; x += dx[step]
                bsr.b   .4A832
                add.w   d2,$C(a0)                   ; y += dy[step]
                bsr.b   .4A832
                move.b  d2,$1F(a0)                  ; frame = frame[step]
                cmp.w   d1,d0                       ; at the end it keeps the last step
                bcc.b   .4A824
                addq.w  #$1,$36(a0)
.4A824:
                cmpi.w  #$10,$A(a0)
                bhi.b   .4A830
                jmp     (jt_ObjKillSelf).w
.4A830:
                rts
.4A832:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
Spawn_PStaff:
                move.w  $2(a1),d0               ; x, y from the wave entry
                move.w  $4(a1),d1
                move.w  $8(a2),d2               ; hit points from the definition
                jsr     (jt_ObjCreate).w
                move.w  $6(a2),$38(a0)          ; definition word $06 (2): first-shot delay
                move.w  $8(a2),$3A(a0)          ; hit points (6): low byte is the volley size
                bsr.w   PStaff_Approach         ; start walking
                move.b  #$1,$4(a0)              ; priority 1
                jmp     (jt_ObjInsert).w
Upd_PStaff:
                cmpi.w  #$10,$A(a0)             ; off the left edge?
                bhi.b   .4A872
                jmp     (jt_ObjKillSelf).w      ; yes: remove
.4A872:
                tst.b   $36(a0)                 ; state 0: walking
                beq.b   .4A890
                cmpi.b  #$1,$36(a0)
                beq.b   .4A8BE                  ; state 1: firing a volley
                subq.w  #$1,$A(a0)              ; state 2, paused: scroll with the map
                subq.b  #$1,$37(a0)             ; count down the pause
                bpl.b   .4A8F4
                bsr.w   PStaff_TryFire          ; then fire if the ship is in range, otherwise walk
                rts
.4A890:
                bsr.w   PStaff_Approach         ; head for 60-79 pixels from the ship
                movem.w $A(a0),d0-d1            ; probe the map ahead at foot level
                add.w   #$B,d1
                tst.w   $32(a0)
                bpl.b   .4A8AA                  ; walking right?
                sub.w   #$10,d0                 ; left: probe 16 pixels ahead
                bra.b   .4A8AE
.4A8AA:
                add.w   #$21,d0                 ; right: probe just past the body
.4A8AE:
                jsr     (jt_GetMapCell).w       ; wall ahead?
                bne.b   PStaff_Halt             ; yes: stop
                move.w  $32(a0),d0
                add.w   d0,$A(a0)               ; take a step
                rts
.4A8BE:
                subq.w  #$1,$A(a0)              ; state 1: scroll with the map
                subq.w  #$1,$34(a0)             ; frames to the next shot
                bmi.b   .4A8CA
                rts
.4A8CA:
                move.w  #$A,$34(a0)             ; 10 frames between shots
                subq.b  #$1,$37(a0)             ; shots left in the volley
                bpl.b   .4A8F6                  ; more: fire one
                bsr.w   PStaff_Approach         ; volley done: face the ship again
                move.l  #PStaffFireAnimEnd,d0   ; animation index = end of the fire animation
                sub.l   $2A(a0),d0
                move.w  d0,$1E(a0)
                move.b  #$2,$36(a0)             ; then pause (state 2)
                move.b  #$A,$37(a0)             ; for 10 frames
.4A8F4:
                rts
.4A8F6:
                bra.w   PStaff_Fire
; P-Staff: walks along the ground keeping 60-80 pixels from the ship
; (PStaff_Approach), then stops; at 55-85 pixels it starts firing
; (PStaff_TryFire, PStaff_Fire: a PStaffMissile on a ballistic path from
; tables at $790D0-$7918C, chosen by the ship's distance plus a random part).
PStaff_Halt:
                move.b  #$2,$36(a0)             ; pause (state 2)
                move.b  #$14,$37(a0)            ; for 20 frames
                clr.b   $22(a0)                 ; hold the animation
                move.w  #$3,$1E(a0)             ; on the standing frame
                rts
PStaff_TryFire:
                bsr.w   ShipDistX
                cmp.w   #$37,d0                 ; closer than 55 pixels:
                blt.b   PStaff_Approach         ; keep walking
                cmp.w   #$55,d0                 ; further than 85 pixels:
                bgt.b   PStaff_Approach         ; keep walking
                bsr.w   PStaff_Approach         ; face the ship
                move.b  #$1,$36(a0)             ; start a volley (state 1)
                move.b  $3B(a0),$37(a0)         ; shots per volley ($3B, from the hit points: 6)
                move.w  $38(a0),$34(a0)         ; delay before the first shot (definition word $06: 2)
                st.b    $22(a0)                 ; animate
                move.l  #PStaffFireAnim,$2A(a0) ; with the fire animation
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                bsr.w   ShipDistX
                move.w  d2,$3C(a0)              ; remember which side the ship is on
                rts
; ShipDistX / ShipDistY: d0 = distance to the ship in x (+30 when the ship
; is to the left) / y, d2 = direction (1 / -1).
ShipDistX:
                moveq   #1,d2
                move.w  (ShipPos).w,d0          ; ship x
                sub.w   $A(a0),d0               ; minus our x
                bpl.b   .4A96C                  ; ship to the right: d2 = 1
                neg.w   d0                      ; ship to the left: d0 = |dx|, d2 = -1
                neg.w   d2
                add.w   #$1E,d0                 ; and allow 30 pixels for the ship's width
.4A96C:
                rts
ShipDistY:
                moveq   #1,d2
                move.w  ($F0).w,d0              ; ship y
                sub.w   #$1F,d0                 ; to its top edge
                sub.w   $C(a0),d0               ; minus our y
                bpl.b   .4A982
                neg.w   d0
                neg.w   d2
.4A982:
                rts
PStaff_Approach:
                bsr.b   ShipDistX
                cmp.w   #$3C,d0                 ; 60-79 pixels away:
                blt.b   .4A994
                cmp.w   #$50,d0
                bcs.w   PStaff_Halt             ; stop here
.4A994:
                clr.b   $36(a0)                 ; otherwise walk (state 0)
                moveq   #70,d1                  ; 70 - distance
                sub.w   d0,d1
                bpl.b   .4A9B0                  ; closer than 70: walk away
                move.w  #$FFFE,$32(a0)          ; further: walk towards the ship
                tst.w   d2
                bmi.b   .4A9AE
                move.w  #$2,$32(a0)
.4A9AE:
                bra.b   .4A9C0
.4A9B0:
                move.w  #$2,$32(a0)             ; walk away from the ship
                tst.w   d2
                bmi.b   .4A9C0
                move.w  #$FFFE,$32(a0)
.4A9C0:
                move.b  #$0,$36(a0)
                lea.l   (PStaffWalkLeft).l,a1   ; walking animation for the direction
                tst.w   $32(a0)
                bmi.b   .4A9D8
                lea.l   (PStaffWalkRight).l,a1
.4A9D8:
                move.l  a1,$2A(a0)              ; set it
                st.b    $22(a0)                 ; and animate
                rts
PStaff_Fire:
                movea.l a0,a4                   ; a4 = the P-Staff
                movem.w $A(a0),d0-d1
                moveq   #1,d2
                subq.w  #$8,d1                  ; launch from the gun barrel
                add.w   #$14,d0
                lea.l   (Def_PStaffMissile).l,a2 ; create the missile (a0)
                jsr     (jt_ObjCreate).w
                bsr.w   ShipDistY               ; y table start = 16 + random(15) - dy/8,
                lsr.w   #$3,d0
                moveq   #16,d1
                move.w  d0,-(a7)
                moveq   #15,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   .4AA14
                clr.w   d1                      ; not below 0
.4AA14:
                move.w  d1,$32(a0)              ; y index into the up-speed table
                bsr.w   ShipDistX               ; x table start = 19 + random(10) - dx/8,
                lsr.w   #$3,d0
                moveq   #19,d1
                move.w  d0,-(a7)
                moveq   #10,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   .4AA30
                clr.w   d1                      ; not below 0
.4AA30:
                move.w  d1,$34(a0)              ; x index into the side-speed table
                move.w  $3C(a4),$36(a0)         ; direction: towards the ship
                clr.b   $22(a0)                 ; frame is set by the update routine
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w        ; link it in
                movea.l a4,a0                   ; back to the P-Staff
                rts
Upd_PStaffMissile:
                lea.l   ($7912E).l,a3           ; up speeds, by y index ($7F ends)
                lea.l   ($790D0).l,a1           ; side speeds, by x index ($7F ends)
                lea.l   ($7918C).l,a2           ; frame per y index (the arc's angle)
                movem.w $32(a0),d0-d2           ; d0 y index, d1 x index, d2 direction
                move.b  (a3,d0.w),d3
                cmp.b   #$7F,d3                 ; end of the arc:
                beq.b   .4AAE0                  ; explode
                neg.b   d3                      ; table is upward speed
                move.b  (a1,d1.w),d4
                bne.b   .4AA78                  ; side speed is at least 1
                addq.b  #$1,d4
.4AA78:
                cmp.b   #$7F,d4
                beq.b   .4AAE0
                addq.w  #$1,$32(a0)             ; step along both tables
                addq.w  #$1,$34(a0)
                ext.w   d3
                ext.w   d4
                asl.w   #$1,d4                  ; side speed doubled
                tst.w   d2
                bpl.b   .4AA92
                neg.w   d4                      ; fired to the left
.4AA92:
                add.w   d3,$C(a0)               ; move
                add.w   d4,$A(a0)
                cmpi.w  #$20,$A(a0)             ; off the left edge,
                bcs.b   .4AABA
                cmpi.w  #$170,$A(a0)            ; or right of x $170,
                bhi.b   .4AABE
                cmpi.w  #$E0,$C(a0)             ; or off the bottom or top:
                bhi.b   .4AABA
                cmpi.w  #$10,$C(a0)
                bhi.b   .4AABE
.4AABA:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AABE:
                move.b  (a2,d0.w),d3            ; frame for this point of the arc
                ext.w   d3
                tst.w   d2
                bpl.b   .4AACC
                add.w   #$9,d3                  ; left-facing frames start at 9
.4AACC:
                move.w  d3,$1E(a0)
                movem.w $A(a0),d0-d1            ; centre of the missile
                addq.w  #$8,d0
                addq.w  #$6,d1
                jsr     (jt_GetMapCell).w       ; hit the map?
                beq.b   .4AAEA                  ; no: carry on
.4AAE0:
                move.b  #$1,$5(a0)              ; yes: explode
                clr.l   $6(a0)                  ; and stop updating
.4AAEA:
                rts
TileAnim_BlasterFloor:
                lea.l   (BlasterFloorAims).l,a4 ; aims for a Blaster on the floor
                bra.b   Blaster
TileAnim_BlasterCeiling:
                lea.l   (BlasterCeilingAims).l,a4 ; aims for one on the ceiling
Blaster:
                moveq   #19,d7                  ; screen column of this cell
                sub.w   d2,d7
                move.w  (ShipPos).w,d6          ; ship's column
                sub.w   #$30,d6
                lsr.w   #$4,d6
                sub.w   d6,d7                   ; columns from the ship
                moveq   #0,d6                   ; aim 0 (8 bytes an aim)
                tst.w   d7
                bmi.b   .4AB18                  ; ship to the right?
                subq.w  #$3,d7                  ; ship 3 or more columns left: aim 0
                bpl.b   .4AB20
                addq.w  #$8,d6                  ; nearer: aim 1 (straight)
                bra.b   .4AB20
.4AB18:
                addq.w  #$8,d6                  ; ship to the right: aim 1,
                addq.w  #$3,d7                  ; 3 or more columns: aim 2
                bpl.b   .4AB20
                addq.w  #$8,d6
.4AB20:
                move.w  d1,d7                   ; (d7 is not used)
                lsr.w   #$8,d7
                and.w   #$F,d7
                btst    #$D,d1                  ; hit (bit 13)?
                bne.b   .4AB52
                btst.b  #$5,(a0)                ; or its right half hit?
                bne.b   .4AB52
                movem.l d4-d6,-(a7)
                move.w  $4(a4,d6.w),d4          ; bullet x offset for the aim
                move.w  $6(a4,d6.w),d5          ; bullet y offset
                bsr.w   .4AB96                  ; count down, fire when due
                movem.l (a7)+,d4-d6
                move.w  (a4,d6.w),d1            ; draw the left tile for the aim
                move.w  $2(a4,d6.w),(a0)        ; and set the right cell's tile (solid)
                rts
.4AB52:
                clr.w   -$2(a0)                 ; destroyed: clear both cells
                clr.w   (a0)
                moveq   #0,d1                   ; draw tile 0
                movem.l d0-d2/a0-a2,-(a7)
                moveq   #19,d0                  ; explosion at the cell:
                sub.w   d2,d0                   ; x = column * 16 + 40
                lsl.w   #$4,d0
                add.w   #$28,d0
                moveq   #12,d1
                sub.w   d3,d1                   ; y = row * 16 + 28
                lsl.w   #$4,d1
                add.w   #$1C,d1
                moveq   #0,d2
                jsr     (jt_ObjAlloc).w         ; explosion object
                move.b  #$1,$5(a0)              ; explode now
                clr.l   $6(a0)                  ; no update routine
                jsr     (jt_ObjInsert).w
                move.l  #$100,d0                ; 100 points
                jsr     (jt_AddScore).w
                movem.l (a7)+,d0-d2/a0-a2
                rts
.4AB96:
                move.w  d1,d6                   ; cell bits 8-11: frame count
                and.w   #$F00,d6
                bne.b   .4ABB4                  ; counting: take one
                move.w  d1,d6                   ; bits 4-7: steps left
                and.w   #$F0,d6
                beq.b   .4ABBC                  ; none: fire
                ori.w   #$F00,-$2(a0)           ; next step: 15 more frames
                subi.w  #$10,-$2(a0)            ; one step fewer
                rts
.4ABB4:
                subi.w  #$100,-$2(a0)           ; one frame fewer
                rts
.4ABBC:
                move.w  d1,d6                   ; reload with $AA: 170 frames to the next shot
                and.w   #$F00F,d6
                or.w    #$AA0,d6
                move.w  d6,-$2(a0)
                moveq   #21,d6                  ; bullet x = (column + 2) * 16 + aim offset
                sub.w   d2,d6
                lsl.w   #$4,d6
                moveq   #13,d7                  ; bullet y = (row + 1) * 16 + aim offset
                sub.w   d3,d7
                lsl.w   #$4,d7
                add.w   d4,d6
                add.w   d5,d7
                movem.l d0-d3/a1-a2,-(a7)
                move.w  d6,d0
                move.w  d7,d1
                addq.w  #$8,d0
                addq.w  #$8,d1
                jsr     (jt_FireEnemyBullet).w  ; fire at the ship
                movem.l (a7)+,d0-d3/a1-a2
                rts
Spawn_Scant:
                movem.w $2(a1),d0-d1
                move.w  $8(a2),d2
                moveq   #30,d2                      ; 30 hit points
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$2,$21(a0)
                clr.w   $3A(a0)
                move.w  #$7D,$3C(a0)                ; after 125 frames it heads off left
                bsr.w   Scant_NextMove              ; first move
                jmp     (jt_ObjInsert).w
Upd_Scant:
                tst.b   $39(a0)                     ; state: 0 vertical, 1 horizontal, 2 pause
                beq.b   .4AC32
                cmpi.b  #$1,$39(a0)
                beq.b   .4AC5C
                subq.b  #$1,$3A(a0)                 ; pausing
                bmi.b   .4AC96
                rts
.4AC32:
                move.w  $C(a0),d1               ; state 0, diagonal move: y
                tst.w   $34(a0)                 ; moving up?
                bmi.b   .4AC54
                cmp.w   $36(a0),d1              ; down: reached the target y?
                bgt.b   .4AC80
.4AC42:
                movem.w $32(a0),d0-d1           ; move by dx, dy
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                bra.w   Scant_Age
.4AC54:
                cmp.w   $36(a0),d1              ; up: reached the target y?
                blt.b   .4AC80
                bra.b   .4AC42
.4AC5C:
                move.w  $A(a0),d1               ; state 1, sideways move: x
                tst.w   $32(a0)                 ; moving left?
                bmi.b   .4AC78
                cmp.w   $36(a0),d1              ; right: reached the target x?
                bgt.b   .4AC80
.4AC6C:
                move.w  $32(a0),d0              ; move by dx
                add.w   d0,$A(a0)
                bra.w   Scant_Age
.4AC78:
                cmp.w   $36(a0),d1              ; left: reached the target x?
                blt.b   .4AC80
                bra.b   .4AC6C
.4AC80:
                move.b  #$2,$39(a0)             ; arrived: pause (state 2)
                moveq   #25,d0
                jsr     (jt_Random).w               ; pause up to 25 frames
                move.b  d0,$3A(a0)
                clr.w   $1E(a0)                 ; resting frame
                rts
.4AC96:
                subq.b  #$1,$38(a0)             ; moves left before the next beam
                bpl.b   Scant_NextMove
                moveq   #2,d0                   ; fire: next beam after 1-2 more moves
                jsr     (jt_Random).w
                addq.w  #$1,d0
                move.b  d0,$38(a0)
                move.b  #$1,$39(a0)             ; state 1: recoil
                clr.w   $34(a0)
                move.w  #$2,$32(a0)             ; 10 pixels to the right
                move.w  $A(a0),d0
                add.w   #$A,d0
                move.w  d0,$36(a0)
                move.w  #$2,$1E(a0)                 ; firing frame
                move.l  a0,-(a7)
                movem.w $A(a0),d0-d1            ; the beam: 40 pixels in front, 10 down
                add.w   #$FFD8,d0
                add.w   #$A,d1
                moveq   #-1,d2                  ; indestructible
                jsr     (jt_ObjAlloc).w
                move.l  #ScantBeamAnim,$2A(a0)
                move.l  #Upd_ScantBeam,$6(a0)
                move.l  #Def_ScantBeam,$12(a0)
                bset.b  #$2,$23(a0)             ; not hit by weapons
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
; Scant: moves in steps - level with the ship (ship y -15..+5) it moves
; sideways up to 49 pixels, otherwise diagonally towards a random y near
; the ship's.  It moves right unless that would pass x $122 (the random
; choice of right step always gives 2).  Between moves it pauses up to 25
; frames; every second or third pause it fires its beam (ScantBeam, 8
; pixels a frame) and recoils 10 pixels.  After 125 frames (Scant_Age) it
; only moves left.
Scant_NextMove:
                move.w  ($F0).w,d0              ; ship y - 15 .. ship y + 5:
                sub.w   #$F,d0
                move.w  d0,d1
                add.w   #$14,d1
                cmp.w   $C(a0),d0               ; above the band:
                bgt.b   .4AD5E
                cmp.w   $C(a0),d1               ; or below it: move diagonally
                blt.b   .4AD5E
                clr.w   $34(a0)                 ; level with the ship: sideways only
                moveq   #50,d0                  ; a random distance up to 49 pixels
                jsr     (jt_Random).w
                move.w  d0,d2
                tst.b   $3B(a0)                 ; leaving?
                bmi.b   .4AD3E
                move.w  $A(a0),d1
                add.w   d2,d1
                cmp.w   #$122,d1                ; or it would pass x $122:
                ble.b   .4AD42
.4AD3E:
                moveq   #-2,d0                  ; go left
                bra.b   .4AD46
.4AD42:
                bsr.w   .4ADBE                  ; otherwise right (always 2: random(1) is 0)
.4AD46:
                tst.w   d0
                bpl.b   .4AD4C
                neg.w   d2
.4AD4C:
                add.w   $A(a0),d2               ; target x
                move.w  d2,$36(a0)
                move.b  #$1,$39(a0)             ; state 1
                bra.w   .4ADAA
.4AD5E:
                clr.b   $39(a0)                 ; state 0: diagonal
                move.w  ($F0).w,d2              ; target y = ship y - 30 + random(59),
                sub.w   #$1E,d2
                moveq   #59,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                cmp.w   #$B1,d2                 ; at most $B0
                blt.b   .4AD7C
                move.w  #$B0,d2
.4AD7C:
                move.w  d2,$36(a0)
                moveq   #2,d0                   ; 2 pixels a frame up or down
                sub.w   $C(a0),d2
                bpl.b   .4AD8C
                neg.w   d0
                neg.w   d2
.4AD8C:
                move.w  d0,$34(a0)
                move.w  $A(a0),d0
                add.w   d2,d0                   ; the same distance sideways:
                tst.b   $3B(a0)                 ; leaving,
                bmi.b   .4ADA2
                cmp.w   #$122,d0                ; or past x $122:
                ble.b   .4ADA6
.4ADA2:
                moveq   #-2,d0                  ; go left
                bra.b   .4ADAA
.4ADA6:
                bsr.w   .4ADBE                  ; otherwise right
.4ADAA:
                move.w  #$1,$1E(a0)             ; frame 1 moving right,
                move.w  d0,$32(a0)
                bpl.b   .4ADBC
                move.w  #$2,$1E(a0)             ; frame 2 moving left
.4ADBC:
                rts
.4ADBE:
                moveq   #1,d0                   ; random(1) is always 0, so this is always 2
                jsr     (jt_Random).w
                asl.w   #$1,d0
                addq.w  #$1,d0
                asl.w   #$1,d0
                rts
Scant_Age:
                subq.w  #$1,$3C(a0)             ; after 125 frames
                bpl.b   .4ADD6
                st.b    $3B(a0)                 ; it only moves left
.4ADD6:
                tst.w   $A(a0)                  ; off the left edge: remove
                bpl.b   ScantRts
                jmp     (jt_ObjKillSelf).w
ScantRts:
                rts
Upd_ScantBeam:
                subq.w  #$8,$A(a0)              ; 8 pixels a frame
                tst.w   $A(a0)
                bpl.b   ScantRts
                jmp     (jt_ObjKillSelf).w
Spawn_Bink:
                move.w  $2(a1),d0               ; x, y from the wave entry
                move.w  $4(a1),d1
                move.w  $8(a2),d2               ; hit points from the definition
                jsr     (jt_ObjCreate).w
                move.l  #BinkWalkRight,$2A(a0)      ; walking right,
                move.w  $6(a1),$32(a0)              ; step (entry $06)
                bpl.b   .4AE18
                move.l  #BinkWalkLeft,$2A(a0)       ; negative: walking left
.4AE18:
                move.w  $32(a0),d2
                bsr.w   Bink_Jump               ; start with a jump
                move.w  #$200,$34(a0)           ; then state 2 (falling), byte $35 = 0
                clr.w   $1E(a0)                 ; first walking frame
                bsr.w   Bink_Fall               ; drop to the ground
                jmp     (jt_ObjInsert).w
Upd_Bink:
                cmpi.w  #$10,$A(a0)                 ; off the screen: remove
                bcs.b   .4AE4A
                cmpi.w  #$170,$A(a0)
                bhi.b   .4AE4A
                cmpi.w  #$E0,$C(a0)
                bcs.b   .4AE4E
.4AE4A:
                jmp     (jt_ObjKillSelf).w
.4AE4E:
                move.b  $34(a0),d0                  ; state: 0 walk, 1 jump, 2 fall, -1 stopped
                beq.b   .4AE9A
                cmp.b   #$1,d0
                beq.w   Bink_Jumping
                cmp.b   #$2,d0
                beq.w   Bink_Fall
                subq.w  #$1,$A(a0)                  ; stopped: scrolls with the map
                subq.b  #$1,$35(a0)                 ; every 10 frames
                bmi.b   .4AE80
                rts
.4AE70:
                st.b    $34(a0)                 ; blocked: stop (state -1)
                clr.b   $22(a0)                 ; hold the animation
                move.l  #BinkWalkLeft,$2A(a0)
.4AE80:
                move.b  #$A,$35(a0)             ; turn to face the ship every 10 frames
                bsr.w   ShipDistX                   ; face the ship
                move.w  #$B,$1E(a0)             ; frame 11: facing right
                tst.w   d2
                bpl.b   .4AE98
                clr.w   $1E(a0)
.4AE98:
                rts
.4AE9A:
                move.w  $32(a0),d2              ; walking: step and direction
                movem.w $A(a0),d0-d1            ; probe at foot height
                add.w   #$C,d1
                subq.w  #$3,d0                  ; 3 pixels behind the left edge
                tst.w   d2
                bmi.b   .4AEB2                  ; walking left?
                add.w   #$23,d0                 ; right: just past the body
.4AEB2:
                jsr     (jt_GetMapCell).w           ; walking: a tile ahead?
                bne.b   .4AE70
                adda.l  (MapRowBytes).w,a4      ; the cell below
                btst.b  #$7,(a4)                    ; ground ahead (one row down)?
                beq.b   Bink_Jump               ; no ground: jump off
                add.w   d2,$A(a0)                   ; yes: step on
                rts
; Bink states ($34): 0 walk along the ground (entry $06: step and
; direction); a tile ahead -> -1: it stops and keeps turning to face the
; ship; no ground ahead -> 1 Bink_Jumping: follows BinkJumpArc, 3 pixels a
; frame across, until $7F -> 2 Bink_Fall: 4 pixels down a frame until it
; lands, then it walks again.  It fires at its definition's rate.
Bink_Jump:
                move.b  #$1,$34(a0)             ; state 1: jumping
                clr.w   $36(a0)                 ; start of the jump arc
                move.w  #$23,$38(a0)
                move.l  #BinkJumpRight,$2A(a0)  ; jump animation for the direction
                tst.w   d2
                bpl.b   .4AEEC
                move.l  #BinkJumpLeft,$2A(a0)
.4AEEC:
                move.w  #$3,$1E(a0)             ; animate from frame 3
                clr.b   $20(a0)
                st.b    $22(a0)
                rts
Bink_Jumping:
                lea.l   (BinkJumpArc).l,a2      ; signed y steps, $7F ends
                move.w  $36(a0),d0
                moveq   #3,d2                   ; 3 pixels a frame sideways
                move.b  (a2,d0.w),d3
                cmp.b   #$7F,d3                 ; end of the arc?
                bne.b   .4AF1A
                move.b  #$2,$34(a0)             ; yes: fall (state 2)
                bra.b   Bink_Fall
.4AF1A:
                ext.w   d3
                tst.w   $32(a0)                 ; walking left?
                bpl.b   .4AF24
                neg.w   d2                      ; yes: sideways step to the left
.4AF24:
                add.w   d2,$A(a0)
                add.w   d3,$C(a0)
                addq.w  #$1,$36(a0)             ; next point of the arc
                rts
Bink_Fall:
                subq.w  #$1,$A(a0)              ; scroll with the map
                movem.w $A(a0),d0-d1            ; probe under the feet
                addq.w  #$8,d0
                add.w   #$1A,d1
                jsr     (jt_GetMapCell).w       ; ground?
                bne.b   .4AF4E
                addq.w  #$4,$C(a0)              ; no: fall 4 pixels a frame
                rts
.4AF4E:
                clr.w   $34(a0)                 ; landed: walk (state 0)
                move.l  #BinkWalkRight,$2A(a0)  ; walking animation for the direction
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.w   $32(a0)
                bpl.b   .4AF70
                move.l  #BinkWalkLeft,$2A(a0)
.4AF70:
                rts
Spawn_Cancer:
                movea.l $A(a1),a3                   ; list of x, y
                move.w  $8(a1),d7                   ; frames between them
                clr.w   d6
.4AF7C:
                move.w  (a3)+,d0
                bmi.b   .4AFA0
                move.w  (a3)+,d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)              ; scroll x at which it gives up
                clr.w   $38(a0)
                move.w  d6,$32(a0)                  ; start delay
                add.w   d7,d6
                jsr     (jt_ObjInsert).w
                bra.b   .4AF7C
.4AFA0:
                rts
Upd_Cancer:
                tst.w   $32(a0)                     ; waiting to start?
                beq.b   .4AFAE
                subq.w  #$1,$32(a0)
                rts
.4AFAE:
                subq.w  #$1,$A(a0)                  ; scrolls with the map
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   .4AFD0
                cmp.w   #$170,d0
                bhi.b   .4AFD0
                cmp.w   #$10,d1
                bcs.b   .4AFD0
                cmp.w   #$E0,d1
                bcs.b   .4AFD4
.4AFD0:
                jmp     (jt_ObjKillSelf).w
.4AFD4:
                move.w  $3A(a0),d4
                cmp.w   (ScrollX).w,d4              ; past its scroll x:
                bhi.b   .4AFEE
                moveq   #10,d7                      ; make for the nearer edge
                cmp.w   #$88,d1
                bcs.b   .4AFEA
                move.w  #$E0,d7
.4AFEA:
                moveq   #4,d6
                bra.b   .4AFFA
.4AFEE:
                subq.w  #$1,$38(a0)                 ; time for a new heading?
                bpl.b   .4B038
                movem.w (ShipPos).w,d6-d7           ; target: the ship
.4AFFA:
                moveq   #2,d4
                lea.l   (CancerAnimRight).l,a1      ; x step +2 / -1, facing it
                cmp.w   d6,d0
                bcs.b   .4B00E
                moveq   #-1,d4
                lea.l   (CancerAnimLeft).l,a1
.4B00E:
                move.l  a1,$2A(a0)
                moveq   #1,d5                       ; y step +1 / -1
                cmp.w   d7,d1
                bcs.b   .4B01A
                neg.w   d5
.4B01A:
                move.w  d0,d2
                sub.w   d6,d2
                bpl.b   .4B022
                neg.w   d2
.4B022:
                lsr.w   #$1,d2                      ; hold it for |dx|/2 + random 25 frames
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)
                move.b  d4,$36(a0)
                move.b  d5,$37(a0)
.4B038:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6
                ext.w   d6
                bpl.b   .4B04E
                subq.w  #$2,d1
                bra.b   .4B052
.4B04E:
                add.w   #$20,d1
.4B052:
                addq.w  #$8,d0
                jsr     (jt_GetMapCell).w           ; blocked vertically?
                bne.b   .4B05E
                add.w   d6,$C(a0)                   ; no: move up/down
.4B05E:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1
                move.b  $36(a0),d4
                ext.w   d4
                bpl.b   .4B070
                subq.w  #$2,d0
                bra.b   .4B074
.4B070:
                add.w   #$22,d0
.4B074:
                jsr     (jt_GetMapCell).w           ; blocked horizontally?
                bne.b   .4B07E
                add.w   d4,$A(a0)                   ; no: move left/right
.4B07E:
                rts
Spawn_Shell:
                move.w  #$260,(ShellCentreX).l      ; centre of the ring, off to the right
                clr.w   (ShellBroken).l
                moveq   #24,d5
                moveq   #0,d6
                moveq   #11,d7                      ; 12 turrets
.4B094:
                move.w  #$170,d0
                move.w  #$34,d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                clr.w   $32(a0)
                move.w  d6,$34(a0)                  ; start delay: 20 frames apart
                move.w  d5,$38(a0)                  ; explosion countdown when the ring breaks
                clr.b   $36(a0)
                subq.w  #$2,d5
                add.w   #$14,d6
                cmp.w   #$3,d7                      ; number 3 is the control unit
                bne.b   .4B0CE
                move.l  #ShellControlAnim,$2A(a0)
                st.b    $36(a0)
.4B0CE:
                jsr     (jt_ObjInsert).w
                dbra    d7,.4B094
                rts
Upd_Shell:
                tst.b   (ShellGone).l               ; ring gone off the left: remove
                bpl.b   .4B0E4
                jmp     (jt_ObjKillSelf).w
.4B0E4:
                tst.b   (ShellBroken).l             ; broken: skip the firing
                bmi.b   .4B120
                move.w  (ShipPos).w,d0
                sub.w   (ShellCentreX).l,d0
                bpl.b   .4B0FA
                neg.w   d0
.4B0FA:
                cmp.w   #$46,d0                     ; ship within 70 pixels of the centre:
                bcs.b   .4B106
                clr.w   $2E(a0)
                bra.b   .4B120
.4B106:
                tst.w   $2E(a0)
                bne.b   .4B120
                move.w  #$AF,d0                     ; fire every 25-200 frames
                jsr     (jt_Random).w
                add.w   #$19,d0
                move.w  d0,$2E(a0)
                move.w  d0,$30(a0)
.4B120:
                tst.w   $34(a0)                     ; waiting to join the ring?
                bmi.b   .4B138
                subq.w  #$1,$34(a0)
                bpl.b   .4B134
                st.b    $22(a0)
                clr.b   $20(a0)
.4B134:
                bra.w   .4B1C0
.4B138:
                lea.l   ($792D1).l,a1               ; ring path: x table, y table at +$127
                lea.l   $127(a1),a2
.4B142:
                move.w  $32(a0),d2
                move.b  (a1,d2.w),d0
                move.b  (a2,d2.w),d1
                cmp.b   #$7F,d1                     ; end of the path: start again
                bne.b   .4B15A
                clr.w   $32(a0)
                bra.b   .4B142
.4B15A:
                ext.w   d0
                ext.w   d1
                addq.w  #$1,$32(a0)
                add.w   #$73,d1
                add.w   (ShellCentreX).l,d0         ; x relative to the moving centre
                movem.w d0-d1,$A(a0)
                tst.b   (ShellBroken).l             ; broken: count down, then explode
                bpl.b   .4B1C0
                subq.w  #$1,$38(a0)
                bpl.b   .4B1C0
                move.w  #$7FFF,$38(a0)
                move.l  a0,-(a7)
                moveq   #-1,d2
                jsr     (jt_ObjAlloc).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.b  #$A,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                move.l  #$200,d0                    ; 200 points for each turret
                jsr     (jt_AddScore).w
                clr.w   $2E(a0)
                clr.b   $22(a0)
                move.w  #$9,$1E(a0)
                clr.b   $20(a0)
.4B1C0:
                tst.b   $36(a0)                     ; the control unit moves the centre
                bpl.b   .4B1EC
                subq.w  #$1,(ShellCentreX).l
                cmpi.w  #$FFB7,(ShellCentreX).l     ; left the screen?
                beq.b   .4B1F4
                cmpi.w  #$5,$1E(a0)                 ; open (frame 5+)?
                blt.b   .4B1EE
                cmpi.w  #$6,$26(a0)                 ; 6 hits while open break the ring
                blt.b   .4B1EC
                st.b    (ShellBroken).l
.4B1EC:
                rts
.4B1EE:
                clr.w   $26(a0)                     ; closed: hits don't count
                rts
.4B1F4:
                st.b    (ShellGone).l
                rts
Spawn_Tabrok:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.b  #$2,$21(a0)             ; explosion type 2
                move.b  #$1,$4(a0)              ; priority 1
                clr.w   $32(a0)                 ; phase 0: walk in
                clr.w   $34(a0)                 ; no pause
                move.w  #$64,$36(a0)            ; for up to 100 frames
                clr.w   $3C(a0)                 ; fire at once
                jmp     (jt_ObjInsert).w
Upd_Tabrok:
                bsr.w   .4B346                  ; fire missiles and homers
                tst.w   $A(a0)                  ; off the left edge: remove
                bpl.b   .4B23C
                jmp     (jt_ObjKillSelf).w
.4B23C:
                tst.w   $34(a0)                 ; pausing between phases?
                bmi.b   .4B254
                subq.w  #$1,$34(a0)             ; count the pause down
                cmpi.b  #$1,$32(a0)             ; in phase 1 it scrolls with the map;
                bne.b   .4B252                  ; other phases hold their screen position
                subq.w  #$1,$A(a0)              ; phase 1: scroll with the map
.4B252:
                rts
.4B254:
                move.b  $32(a0),d0              ; phase 0: walk in
                beq.b   .4B276
                cmp.b   #$1,d0
                beq.b   .4B2B8                  ; 1: rise
                cmp.b   #$2,d0
                beq.w   .4B2E8                  ; 2: move forward
                cmp.b   #$3,d0
                beq.w   .4B30C                  ; 3: drop to the ground
                subq.w  #$1,$A(a0)              ; 4: stand, scrolling with the map
                rts
.4B276:
                movem.w $A(a0),d0-d1            ; probe the ground ahead at its feet
                add.w   #$22,d1
                subq.w  #$6,d0
                jsr     (jt_GetMapCell).w
                bne.b   .4B298                  ; blocked:
                tst.w   $36(a0)                 ; or walked 100 frames:
                bmi.b   .4B298                  ; stop
                subq.w  #$1,$36(a0)
                subq.w  #$3,$A(a0)              ; walk 3 pixels a frame
                rts
.4B298:
                move.b  #$1,$32(a0)             ; phase 1
                move.w  #$32,$34(a0)            ; after a 50-frame pause
                move.w  #$1B,$36(a0)            ; for 28 frames
                clr.w   $1E(a0)                 ; standing frame, still
                clr.b   $22(a0)
                clr.b   $20(a0)
                rts
.4B2B8:
                move.l  #TabrokFireAnim,$2A(a0) ; phase 1: fire animation (legs fold up)
                st.b    $22(a0)
                tst.w   $36(a0)                 ; 28 frames:
                bmi.b   .4B2D4
                subq.w  #$1,$36(a0)
                subq.w  #$2,$C(a0)              ; rise 2 pixels a frame
                rts
.4B2D4:
                move.b  #$2,$32(a0)             ; phase 2
                move.w  #$32,$34(a0)            ; after a 50-frame pause
                move.w  #$41,$36(a0)            ; for 66 frames
                rts
.4B2E8:
                tst.w   $36(a0)                 ; 66 frames:
                bmi.b   .4B2F8
                subq.w  #$1,$36(a0)
                addq.w  #$2,$A(a0)              ; 2 pixels a frame to the right
                rts
.4B2F8:
                move.b  #$3,$32(a0)             ; phase 3
                move.w  #$14,$34(a0)            ; after a 20-frame pause
                move.w  #$28,$36(a0)
                rts
.4B30C:
                movem.w $A(a0),d0-d1            ; probe below its feet
                add.w   #$2C,d1
                add.w   #$16,d0
                jsr     (jt_GetMapCell).w       ; ground below?
                bne.b   .4B32A
                addq.w  #$2,$C(a0)              ; no: drop 2 down, 1 right
                addq.w  #$1,$A(a0)
                rts
.4B32A:
                move.b  #$4,$32(a0)             ; landed: phase 4
                move.l  #TabrokWalkAnim,$2A(a0) ; walking animation, still
                clr.w   $1E(a0)
                clr.b   $22(a0)
                clr.b   $20(a0)
                rts
.4B346:
                bsr.b   .4B398                  ; homers every 116 frames
                tst.b   $3C(a0)                 ; missile cooldown
                beq.b   .4B352
                subq.b  #$1,$3C(a0)
.4B352:
                move.w  $C(a0),d0               ; y distance from the ship
                addq.w  #$8,d0
                move.w  d0,d1                   ; d1 = launch y
                sub.w   ($F0).w,d0              ; minus the ship's y
                bpl.b   .4B362
                neg.w   d0
.4B362:
                cmp.w   #$12,d0                 ; within 18 pixels
                bhi.b   .4B396
                tst.b   $3C(a0)                 ; and not cooling down:
                bne.b   .4B396
                move.l  a0,-(a7)
                move.w  $A(a0),d0               ; launch x
                moveq   #1,d2
                lea.l   (Def_TabrokMissile).l,a2 ; the missile
                jsr     (jt_ObjCreate).w
                move.b  #$1,$21(a0)             ; explosion type 1
                clr.b   $22(a0)                 ; no animation
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                move.b  #$12,$3C(a0)            ; 18 frames to the next one
.4B396:
                rts
.4B398:
                subq.b  #$1,$3D(a0)             ; time for homers?
                bmi.b   .4B3A0
                rts
.4B3A0:
                move.b  #$73,$3D(a0)            ; 116 frames to the next salvo
                move.l  a0,-(a7)
                movem.w $A(a0),d0-d1
                add.w   #$F,d0                  ; launch point
                add.w   #$A,d1
                moveq   #1,d2
                moveq   #3,d7                   ; 4 homers
                lea.l   (TabrokHomerDirs).l,a4  ; starting directions (of 16)
                lea.l   (Def_TabrokHomer).l,a2  ; the homer
.4B3C6:
                jsr     (jt_ObjCreate).w
                move.b  #$1,$21(a0)
                clr.b   $22(a0)
                move.w  (a4)+,$1E(a0)           ; start direction
                move.w  #$16,$36(a0)            ; steer 22 times
                move.w  #$5,$34(a0)             ; every 6 frames
                jsr     (jt_ObjInsert).w
                dbra    d7,.4B3C6
                movea.l (a7)+,a0
                rts
Upd_TabrokHomer:
                subq.w  #$1,$34(a0)             ; time to steer?
                bpl.b   .4B434
                move.w  #$5,$34(a0)             ; every 6 frames
                tst.w   $36(a0)                 ; steering over:
                beq.b   .4B434                  ; fly straight on
                subq.w  #$1,$36(a0)
                movem.w $A(a0),d0-d1
                movem.w d0-d1,-(a7)
                addq.w  #$8,d0
                addq.w  #$8,d1                  ; hit the map?
                jsr     (jt_GetMapCell).w       ; hit the map?
                movem.w (a7)+,d0-d1
                bne.b   .4B474                  ; yes: explode
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w      ; direction to the ship
                move.w  $1E(a0),d1
                jsr     (jt_TurnTowards).w      ; turn one step towards it
                move.w  d1,$1E(a0)
.4B434:
                move.w  $1E(a0),d0              ; direction (frame) 0-15
                lsl.w   #$2,d0
                movem.w $A(a0),d1-d2
                lea.l   (TabrokHomerSteps).l,a1 ; x, y step for the direction
                add.w   (a1,d0.w),d1
                add.w   $2(a1,d0.w),d2
                cmp.w   #$10,d1                 ; off the screen:
                bcs.b   .4B466
                cmp.w   #$170,d1
                bhi.b   .4B466
                cmp.w   #$10,d2
                bcs.b   .4B466
                cmp.w   #$E0,d2
                bcs.b   .4B46A
.4B466:
                jmp     (jt_ObjKillSelf).w      ; remove
.4B46A:
                move.w  d1,$A(a0)
                move.w  d2,$C(a0)
                rts
.4B474:
                move.b  #$1,$5(a0)              ; explode
                clr.l   $6(a0)
                rts
Upd_TabrokMissile:
                movem.w $A(a0),d0-d1            ; probe ahead of the nose
                sub.w   #$10,d0
                subq.w  #$4,d1
                jsr     (jt_GetMapCell).w
                bne.w   .4B4A6                  ; hit the map: explode
                subq.w  #$6,$A(a0)              ; 6 pixels a frame left
                cmpi.w  #$10,$A(a0)             ; off the left edge: remove
                bhi.b   .4B4A4
                jmp     (jt_ObjKillSelf).w
.4B4A4:
                rts
.4B4A6:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                rts
; LevelInit: resets the boss's state; BossTimer = 1250 frames.
LevelInit:
                clr.b   (BossMouthOpen).l
                clr.b   (BossMouthStep).l
                clr.b   (BossMouthTimer).l
                clr.b   (BossAdvance).l
                clr.b   (BossPulseTimer).l
                clr.b   (BossPulseStep).l
                move.w  #$4E2,(BossTimer).l     ; 1250 frames before the boss advances
                rts
; LevelFrame: the boss (Dobkeratops), from scroll x $D3E:
;  - while BossMouthOpen (set when the core fires) the mouth opens: every
;    10 frames 2x2 cells from BossMouthFrames are written into the map
;  - every 75 frames the next of BossPulseFrames is written (the pulsing
;    body)
;  - at $E5D the scroll stops and BossTimer runs down (after 20 hits on
;    the core it is cut to 50); then the scroll starts again - the boss
;    advances - and at $F39 the level ends.
LevelFrame:
                cmpi.w  #$D3E,(ScrollX).w       ; boss area yet?
                bcs.w   .4B5B6
                tst.b   (BossMouthOpen).l       ; mouth opening?
                beq.b   .4B53E
                subq.b  #$1,(BossMouthTimer).l  ; count down
                bpl.b   .4B53E
                move.b  #$A,(BossMouthTimer).l  ; every 10 frames
                moveq   #0,d4
                move.b  (BossMouthStep).l,d4    ; next mouth frame (4 of them)
                lea.l   (BossMouthFrames).l,a0
                movea.l (a0,d4.w),a0            ; its map cells
                lea.l   ($5BB5E).l,a1           ; the mouth's place in the map
                bsr.w   .4B5B8                  ; write 2x2 cells
                addq.b  #$4,d4
                move.b  d4,(BossMouthStep).l
                cmp.b   #$C,d4                  ; all 4 shown:
                bls.b   .4B53E
                clr.b   (BossMouthOpen).l       ; the mouth is done
                clr.b   (BossMouthStep).l
                clr.b   (BossMouthTimer).l
.4B53E:
                subq.b  #$1,(BossPulseTimer).l  ; body pulse
                bne.b   .4B57E
                move.b  #$4B,(BossPulseTimer).l ; every 75 frames
                moveq   #0,d4
                move.b  (BossPulseStep).l,d4    ; next pulse frame (4 of them)
                lea.l   (BossPulseFrames).l,a0
                movea.l (a0,d4.w),a0            ; its map cells
                lea.l   ($5B72A).l,a1           ; the body's place in the map
                bsr.w   .4B5B8
                addq.b  #$4,d4
                move.b  d4,(BossPulseStep).l
                cmp.b   #$C,d4                  ; after the last
                bls.b   .4B57E
                clr.b   (BossPulseStep).l       ; start again
.4B57E:
                tst.b   (BossAdvance).l         ; advancing?
                beq.b   .4B598
                cmpi.w  #$F39,(ScrollX).w       ; reached the end of the map:
                bcs.b   .4B5B6
                clr.b   (ScrollActive).w        ; stop the scroll
                st.b    (LevelComplete).w       ; and end the level
                rts
.4B598:
                cmpi.w  #$E5D,(ScrollX).w       ; reached the boss:
                bcs.b   .4B5B6
                clr.b   (ScrollActive).w        ; stop the scroll
                subq.w  #$1,(BossTimer).l       ; and wait BossTimer frames,
                bpl.b   .4B5B6
                st.b    (BossAdvance).l         ; then advance
                st.b    (ScrollActive).w        ; (the scroll moves on)
.4B5B6:
                rts
.4B5B8:
                move.l  (a0)+,(a1)              ; 2 cells on this row
                adda.l  (MapRowBytes).w,a1      ; 2 on the next
                move.l  (a0),(a1)
                rts
Spawn_DobkeratopsTail:
                move.w  #$12C,(TailX).l         ; tail root x
                clr.b   (BossHit).l
                clr.w   (TailWave).l
                clr.w   (TailTimer).l
                clr.w   (BossDead).l
                moveq   #15,d7                  ; 16 segments
                moveq   #0,d6                   ; d6 = offset into a wave row
                moveq   #0,d5                   ; d5 = explosion delay
.4B5E8:
                move.w  #$190,d0                ; created off screen (placed by the update)
                moveq   #5,d1
                moveq   #-1,d2                  ; indestructible
                movem.w d5-d7,-(a7)
                jsr     (jt_ObjCreate).w
                move.w  d6,$32(a0)              ; segment's (x, y) in each wave row
                clr.w   $34(a0)                 ; 0 = follower
                move.w  d5,$36(a0)              ; segments explode one after another
                move.w  #$5,$1E(a0)             ; segment frame
                clr.b   $22(a0)
                jsr     (jt_ObjInsert).w        ; link it in
                movem.w (a7)+,d5-d7
                addq.w  #$2,d6                  ; next pair of bytes
                addq.w  #$1,d5
                dbra    d7,.4B5E8
                st.b    $34(a0)                 ; the last segment leads (the tip)
                movea.l (PalettePtr).w,a1       ; colour 11 = $090
                move.w  #$90,$16(a1)
                st.b    (MusicFadeReq).w        ; fade the level music out
                rts
Upd_DobkeratopsTail:
                tst.b   (BossDead).l            ; boss dead?
                bpl.b   .4B652
                tst.w   $36(a0)                 ; delay over:
                bpl.b   .4B64C
                move.b  #$1,$5(a0)              ; explode
                clr.l   $6(a0)                  ; and stop updating
                rts
.4B64C:
                subq.w  #$1,$36(a0)             ; wait for this segment's turn
                rts
.4B652:
                tst.b   (BossHit).l             ; core hit this frame:
                beq.b   .4B660
                bset.b  #$0,$23(a0)             ; flash the segment too
.4B660:
                lea.l   ($78AB8).l,a1           ; wave rows: 40 x 16 (x, y) byte pairs (level B)
                move.w  (TailWave).l,d0
                lsl.w   #$5,d0                  ; row * 32
                add.w   $32(a0),d0              ; + this segment's pair
                move.b  (a1,d0.w),d2
                move.b  $1(a1,d0.w),d3
                and.w   #$FF,d2
                and.w   #$FF,d3
                add.w   (TailX).l,d2            ; x from the tail root
                sub.w   #$A,d3                  ; y - 10
                movem.w d2-d3,$A(a0)
                tst.b   $34(a0)                 ; the tip?
                bmi.b   .4B69A
                rts                             ; followers: done
.4B69A:
                tst.b   (ScrollActive).w        ; scrolling (the boss advances):
                beq.b   .4B6A6
                subq.w  #$1,(TailX).l           ; the tail moves left with it
.4B6A6:
                subq.w  #$1,(TailTimer).l       ; every 2 frames
                bpl.b   .4B6CC
                move.w  #$1,(TailTimer).l
                addq.w  #$1,(TailWave).l        ; the next wave row
                cmpi.w  #$28,(TailWave).l       ; 40 rows,
                blt.b   .4B6CC
                clr.w   (TailWave).l            ; then round again
.4B6CC:
                lea.l   ($78AB8).l,a1           ; place the tip on the new row
                move.w  (TailWave).l,d0
                lsl.w   #$5,d0
                add.w   $32(a0),d0
                move.b  (a1,d0.w),d2
                move.b  $1(a1,d0.w),d3
                and.w   #$FF,d2
                and.w   #$FF,d3
                add.w   (TailX).l,d2
                sub.w   #$A,d3
                movem.w d2-d3,$A(a0)
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w      ; direction to the ship
                and.w   #$7,d0                  ; tip frame: one of 4 directions
                lsr.w   #$1,d0
                move.w  d0,$1E(a0)
                rts
Spawn_DobkeratopsCore:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w        ; indestructible: hits are counted by the update
                clr.b   $22(a0)
                move.w  #$3F,$32(a0)
                clr.w   $34(a0)
                clr.w   $36(a0)
                jmp     (jt_ObjInsert).w
Upd_DobkeratopsCore:
                tst.b   (ScrollActive).w            ; stays fixed to the map
                beq.b   .4B746
                subq.w  #$1,$A(a0)
.4B746:
                tst.b   (BossDead).l                ; dead: random explosions
                bne.w   .4B81E
                subq.w  #$1,$32(a0)                 ; fire every 64 frames:
                bpl.b   .4B7CC
                move.w  #$3F,$32(a0)            ; 64 frames to the next volley
                move.l  a0,-(a7)
                moveq   #4,d7                       ; 5 shots
                moveq   #1,d5                   ; d5 = launch delay, 3 frames apart
                movem.w $A(a0),d3-d4
                sub.w   #$14,d3                 ; from 20 pixels left of the core
                move.w  d4,d1
                move.w  #$170,d0                ; created off screen, at x $170
                move.w  ($F0).w,d2                  ; path set by the ship's height
                moveq   #-1,d6                  ; ship high (y < $64): -1, curve up
                cmp.w   #$64,d2
                bcs.b   .4B788
                moveq   #0,d6                   ; middle: 0, straight
                cmp.w   #$9D,d2
                bcs.b   .4B788
                moveq   #1,d6                   ; low (y >= $9D): 1, curve down
.4B788:
                moveq   #-1,d2                  ; indestructible
                lea.l   (Def_DobkeratopsShot).l,a2
                moveq   #0,d4                   ; first frame
.4B792:
                jsr     (jt_ObjCreate).w
                move.w  d3,$38(a0)              ; launch x
                move.w  d6,$32(a0)              ; path: -1 up, 0 straight, 1 down
                move.w  d5,$34(a0)              ; wait before appearing
                clr.w   $36(a0)                 ; position on the curve
                addq.w  #$3,d5
                move.w  d4,$1E(a0)              ; frames 0, 2, 4, 6, 0: a spinning chain
                addq.w  #$2,d4
                cmp.w   #$7,d4
                bls.b   .4B7B6
                clr.w   d4
.4B7B6:
                bset.b  #$2,$23(a0)             ; not hit by weapons
                jsr     (jt_ObjInsert).w
                dbra    d7,.4B792
                movea.l (a7)+,a0
                st.b    (BossMouthOpen).l           ; and the mouth opens
.4B7CC:
                clr.b   (BossHit).l                 ; hit this frame? -> tail flashes
                move.w  $26(a0),d0              ; damage taken
                cmp.w   $34(a0),d0              ; changed since last frame?
                beq.b   .4B7E6
                move.w  d0,$34(a0)              ; remember it
                st.b    (BossHit).l
.4B7E6:
                cmpi.w  #$14,$26(a0)                ; 20 hits: the timer is cut to 50
                bcs.b   .4B800
                cmpi.w  #$32,(BossTimer).l
                bls.b   .4B800
                move.w  #$32,(BossTimer).l
.4B800:
                cmpi.w  #$1E,$26(a0)                ; 30 hits: dead
                bcs.b   .4B81C
                st.b    (BossDead).l
                st.b    (LevelComplete).w
                move.l  #$6200,d0                   ; 6200 points
                jmp     (jt_AddScore).w
.4B81C:
                rts
.4B81E:
                subq.w  #$1,$36(a0)             ; dead: an explosion every 2 frames
                bpl.b   .4B872
                move.w  #$1,$36(a0)
                move.l  a0,-(a7)
                moveq   #2,d0                   ; explosion type 0 or 2
                jsr     (jt_Random).w
                move.w  d0,d7
                beq.b   .4B838
                addq.w  #$1,d7
.4B838:
                move.w  #$82,d0                 ; y = core y - 85 + random(130)
                jsr     (jt_Random).w
                sub.w   #$55,d0
                move.w  d0,d1
                add.w   $C(a0),d1
                moveq   #50,d0                  ; x = core x - 50 + random(50)
                jsr     (jt_Random).w
                sub.w   #$32,d0
                add.w   $A(a0),d0
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)                  ; explosion object, exploding now
                move.b  #$1,$5(a0)
                move.b  d7,$21(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
.4B872:
                rts
Upd_DobkeratopsShot:
                tst.b   (BossDead).l            ; boss dead:
                beq.b   .4B886
                move.b  #$1,$5(a0)              ; explode
                clr.l   $6(a0)
.4B886:
                tst.w   $34(a0)                 ; waiting to launch?
                beq.b   .4B89A
                subq.w  #$1,$34(a0)
                bne.b   .4B898
                move.w  $38(a0),$A(a0)          ; launch: appear at the core
.4B898:
                rts
.4B89A:
                move.w  $32(a0),d1              ; path
                beq.b   .4B8D2                  ; straight: 6 pixels a frame left
                lea.l   ($79607).l,a1           ; dx, dy curve tables (42 steps, level B)
                move.w  $36(a0),d2              ; step number
                move.b  (a1,d2.w),d3            ; dx
                move.b  $2A(a1,d2.w),d4         ; dy
                ext.w   d3
                ext.w   d4
                tst.w   d1
                bmi.b   .4B8BC
                neg.w   d4                      ; downward path: mirror dy
.4B8BC:
                add.w   d3,$A(a0)
                add.w   d4,$C(a0)
                cmpi.w  #$29,$36(a0)            ; end of the curve (step 41)?
                bcc.b   .4B8D6                  ; then it keeps its last step
                addq.w  #$1,$36(a0)             ; next step
                bra.b   .4B8D6
.4B8D2:
                subq.w  #$6,$A(a0)              ; straight on
.4B8D6:
                cmpi.w  #$10,$A(a0)             ; off the left edge: remove
                bhi.b   .4B8E2
                jmp     (jt_ObjKillSelf).w
.4B8E2:
                rts
; Pata-Pata groups (wave parameter $06): per fighter its y, the delay
; before it starts (frames) and its first animation frame; $FFFF ends.
PataPataData1:
                dc.w    $003A                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $0032                   ; y
                dc.b    $08,$00                ; delay, frame
                dc.w    $0052                   ; y
                dc.b    $13,$00                ; delay, frame
                dc.w    $003A                   ; y
                dc.b    $1D,$00                ; delay, frame
                dc.w    $FFFF
PataPataData2:
                dc.w    $008C                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $00A4                   ; y
                dc.b    $09,$00                ; delay, frame
                dc.w    $0088                   ; y
                dc.b    $12,$00                ; delay, frame
                dc.w    $0074                   ; y
                dc.b    $1D,$00                ; delay, frame
                dc.w    $FFFF
PataPataData3:
                dc.w    $0089                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $007F                   ; y
                dc.b    $06,$00                ; delay, frame
                dc.w    $008C                   ; y
                dc.b    $0D,$00                ; delay, frame
                dc.w    $FFFF
PataPataData4:
                dc.w    $007A                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $0057                   ; y
                dc.b    $05,$00                ; delay, frame
                dc.w    $0032                   ; y
                dc.b    $0C,$00                ; delay, frame
                dc.w    $0031                   ; y
                dc.b    $12,$00                ; delay, frame
                dc.w    $FFFF
PataPataData5:
                dc.w    $0072                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $003C                   ; y
                dc.b    $05,$00                ; delay, frame
                dc.w    $004D                   ; y
                dc.b    $0A,$00                ; delay, frame
                dc.w    $FFFF
PataPataData6:
                dc.w    $0070                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $0044                   ; y
                dc.b    $09,$00                ; delay, frame
                dc.w    $004A                   ; y
                dc.b    $10,$00                ; delay, frame
                dc.w    $007F                   ; y
                dc.b    $1A,$00                ; delay, frame
                dc.w    $0057                   ; y
                dc.b    $22,$00                ; delay, frame
                dc.w    $FFFF
PataPataData7:
                dc.w    $004D                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $0061                   ; y
                dc.b    $0D,$00                ; delay, frame
                dc.w    $0041                   ; y
                dc.b    $12,$00                ; delay, frame
                dc.w    $0070                   ; y
                dc.b    $23,$00                ; delay, frame
                dc.w    $FFFF
PataPataData8:
                dc.w    $007E                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $006E                   ; y
                dc.b    $08,$00                ; delay, frame
                dc.w    $FFFF
PataPataData9:
                dc.w    $005A                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $FFFF
PataPataData10:
                dc.w    $0040                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $008A                   ; y
                dc.b    $0A,$00                ; delay, frame
                dc.w    $FFFF
PataPataData11:
                dc.w    $004D                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $0057                   ; y
                dc.b    $0C,$00                ; delay, frame
                dc.w    $FFFF
PataPataData12:
                dc.w    $0084                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $007F                   ; y
                dc.b    $0C,$00                ; delay, frame
                dc.w    $0082                   ; y
                dc.b    $1E,$00                ; delay, frame
                dc.w    $FFFF
PataPataData13:
                dc.w    $004A                   ; y
                dc.b    $00,$00                ; delay, frame
                dc.w    $007F                   ; y
                dc.b    $32,$00                ; delay, frame
                dc.w    $FFFF
; Pata-Pata: red fighters in groups. Spawn: a list of y, delay, start frame;
;   they enter at the right edge, fly left 4 px a frame on a 35-step wave (y
;   table at $78FD8)
; (32x19, 8 frames, gfx $62DA8, 1 hit point, fires every ~60 frames, score 200, update Upd_PataPata, spawn Spawn_PataPata)
Def_PataPata:
                dc.w    $1303,$002E,$0260,$0001,$0001
                dc.w    $003C,$0006,$2DA8,$0000,$0130,$0004,$B9C2,$0004
                dc.w    $B9CC
                dc.l    Upd_PataPata
                dc.l    Spawn_PataPata
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0005
                dc.w    $0000,$000E,$0012,$0005,$0003,$000F,$000E,$0000
                dc.w    $0006,$0014,$0006,$0005,$0003,$000E,$000E,$0003
                dc.w    $0001,$0010,$0011,$0004,$0003,$000F,$000E,$0000
                dc.w    $0007,$0014,$0006,$0004,$0003,$000F,$000E
; Bug chains (wave parameter $06): number of path steps, then the dx, dy
; and frame tables (signed bytes, one per step, in level B).  Parameter
; $0A is the number of Bugs - 1, $0C their extra x speed.
BugData1:
                dc.w    $0046                   ; steps
                dc.l    $00078FFB,$00079042,$00079089 ; dx, dy, frame tables (level B)
BugData2:
                dc.w    $004C                   ; steps
                dc.l    $000791EA,$00079237,$00079284 ; dx, dy, frame tables (level B)
BugData3:
                dc.w    $0047                   ; steps
                dc.l    $00079525,$00079572,$000795BF ; dx, dy, frame tables (level B)
; Bug (probably): a chain of pods, 7 frames apart, each following the same
;   path (dx/dy/frame tables, entry $06)
; (32x21, 8 frames, gfx $640A8, 1 hit point, fires every ~45 frames, score 200, update Upd_Bug, spawn Spawn_Bug)
Def_Bug:
                dc.w    $1503,$002E,$02A0,$0000
                dc.w    $0001,$002D,$0006,$40A8,$0000,$0150,$0004,$BA5E
                dc.w    $0004,$BA68
                dc.l    Upd_Bug
                dc.l    Spawn_Bug
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0003,$0011,$0011,$0002,$0002,$0011,$0012,$0001
                dc.w    $0002,$0011,$0011,$0002,$0001,$0011,$0011,$0002
                dc.w    $0001,$0011,$0012,$0003,$0001,$0010,$0011,$0002
                dc.w    $0002,$0012,$0011,$0003,$0002,$0011,$0012
; P-Staff: ground missile launcher, 6 hit points; fires PStaffMissile
; (32x26, 6 frames, gfx $67618, 6 hit points, score 500, update Upd_PStaff, spawn Spawn_PStaff)
Def_PStaff:
                dc.w    $1A03
                dc.w    $002E,$0340,$0002,$0006,$0000,$0006,$7618,$0000
                dc.w    $01A0,$0004,$BAD0,$0004,$BAEC
                dc.l    Upd_PStaff
                dc.l    Spawn_PStaff
                dc.w    $0000,$0500
PStaffWalkLeft:
                dc.b    $00,$01,$02,$03,$04,$05,$FF
PStaffWalkRight:
                dc.b    $06,$07,$08,$09,$0A,$0B,$FF
PStaffFireAnim:
                dc.w    $0D0E,$FF03,$0C0D,$0EFF
PStaffFireAnimEnd:
                dc.w    $0E0D,$0C03,$FF00,$0005,$0009,$0019,$0011,$0004
                dc.w    $0009,$001A,$0010,$0005,$0006,$0019,$0013,$0003
                dc.w    $0009,$001A,$0010,$0004,$0007,$0019,$0012,$0004
                dc.w    $0007,$0018,$0012,$0004,$0007,$0018,$0012,$0004
                dc.w    $0007,$0018,$0012,$0003,$0006,$0019,$0013,$0004
                dc.w    $0008,$001B,$0012,$0003,$0007,$0019,$0012,$0004
                dc.w    $0007,$0019,$0012,$000C,$0004,$000F,$0015,$0012
                dc.w    $0002,$000D,$0018,$0012,$0002,$000D,$0018
; P-Staff missile: 16 directions
; (16x13, 16 frames, gfx $6A6D8, update Upd_PStaffMissile)
Def_PStaffMissile:
                dc.w    $0D02,$0030,$00D0,$0000,$0000,$0000,$0006,$A6D8
                dc.w    $0000,$0068,$0004,$BB8C,$0004,$BBA0
                dc.l    Upd_PStaffMissile
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
BlasterCeilingAims:
                dc.w    $00F6,$80F7,$FFF8,$0012,$00E2,$80E3,$0000,$0012
                dc.w    $00C2,$80C3,$0008,$0012
BlasterFloorAims:
                dc.w    $0056,$8057,$FFF8,$0000,$006A,$806B,$0000,$0000
                dc.w    $00A2,$80A3,$0008,$0000
; Tile animations (map cells with bit 14; bits 0-3 pick the routine).
; Level 1's are the Blasters, small gun batteries built into the map by
; MapPatches: DrawMap calls the routine for each one on screen.  It picks
; the pair of tiles that points towards the ship (3 aims, BlasterCeiling/
; FloorAims: left tile, right tile, bullet x, y offset), counts the
; cell's bits 4-11 down to fire an enemy bullet (every 170 frames while
; on screen: bits 8-11 count frames, bits 4-7 steps of 16; the map
; patches start them at different counts), and when the cell's hit
; bit (13) is set the Blaster is destroyed: both cells cleared, an
; explosion, 100 points.
TileAnims:
                dc.l    TileAnim_BlasterCeiling
                dc.l    TileAnim_BlasterFloor
; Map patches: column, row, cell - written into the map at level start.
; Here: the Blasters (cells $Cxxx: solid + animated, routine 0 in the
; ceiling rows 1-3, routine 1 in the floor rows 8-9).
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
                dc.w    $C5E1,$00B1,$0008,$C3E1,$FFFF
; Scant: the big mech, 30 hit points; fires ScantBeam
; (48x47, 3 frames, gfx $655A8, 30 hit points, score 500, update Upd_Scant, spawn Spawn_Scant)
Def_Scant:
                dc.w    $2F04,$002C,$08D0
                dc.w    $0000,$001E,$0000,$0006,$55A8,$0000,$0468,$0004
                dc.w    $BD2A,$0004,$BD2E
                dc.l    Upd_Scant
                dc.l    Spawn_Scant
                dc.w    $0000,$0500,$0001,$0203,$000F,$0003,$0016,$0024
                dc.w    $0007,$0001,$001B,$0027,$0011,$0002,$001A,$002B
; Scant's wave blast, 48x16, 2 frames
; (48x16, 2 frames, gfx $67018)
Def_ScantBeam:
                dc.w    $1004,$002C,$0300,$0000,$0000,$0000,$0006,$7018
                dc.w    $0000,$0180,$0004,$BD6E,$0004,$BD72,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
ScantBeamAnim:
                dc.w    $0001,$FF00,$0002,$0004,$002B,$0009,$0001,$0002
                dc.w    $002C,$000C
; Bink: walks along the ground and hops (entry $06 = direction)
; (32x26, 4 frames, gfx $6B3D8, 1 hit point, fires every ~30 frames, score 200, update Upd_Bink, spawn Spawn_Bink)
Def_Bink:
                dc.w    $1A03,$002E,$0340,$0003,$0001,$001E
                dc.w    $0006,$B3D8,$0000,$01A0,$0004,$BDAA,$0004,$BDBE
                dc.l    Upd_Bink
                dc.l    Spawn_Bink
                dc.w    $0000,$0200
BinkWalkLeft:
                dc.b    $00,$01,$02,$03,$FF
BinkJumpLeft:
                dc.b    $04,$05,$FF,$03,$FF
BinkWalkRight:
                dc.b    $06,$07,$08,$09,$FF
BinkJumpRight:
                dc.b    $0A,$0B,$FF,$09,$FF,$00,$03,$00,$01,$00,$15,$00,$19,$00,$02,$00
                dc.b    $03,$00,$18,$00,$16,$00,$04,$00,$01,$00,$15,$00,$19,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$02,$00,$02,$00,$18,$00,$17,$00,$02,$00
                dc.b    $02,$00,$18,$00,$16,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$15,$00,$04,$00,$02,$00,$17,$00,$17,$00,$03,$00
                dc.b    $04,$00,$18,$00,$14,$00,$04,$00,$02,$00,$18,$00,$16,$00,$04,$00
                dc.b    $03,$00,$18,$00,$15
BinkJumpArc:
                dc.w    $FEFE,$FEFF,$FFFF,$FF00,$0000,$0101,$0101,$0202
                dc.w    $027F,$7F00,$0170,$005A,$0170,$0046,$0170,$00AA
                dc.w    $FFFF,$0170,$002F,$0170,$0056,$0170,$00A4,$FFFF
                dc.w    $0170,$0037,$0170,$00A0,$0170,$00AF,$FFFF,$0170
                dc.w    $0046,$0170,$0032,$0170,$00B4,$FFFF,$0170,$0028
                dc.w    $0170,$002F,$0170,$005A,$0170,$003C,$FFFF,$0170
                dc.w    $005A,$0170,$0046,$0170,$0091,$0170,$0032,$FFFF
                dc.w    $0170,$00A0,$0170,$0055,$0170,$00A6,$0170,$0046
                dc.w    $FFFF
; Cancer: hovers after the ship - a group from a position list (entry
; $0A), $08 frames apart.  It picks a heading towards the ship (x 2 or -1,
; y 1 or -1 a frame) for |dx|/2 + up to 25 frames, sliding along walls;
; after scroll x (entry $06) it gives up and makes for the nearer edge.
; (32x26, 6 frames, gfx $6DAD8, 1 hit point, fires every ~40 frames, score 300, update Upd_Cancer, spawn Spawn_Cancer)
Def_Cancer:
                dc.w    $1A03,$002E,$0340,$0005,$0001,$0028,$0006
                dc.w    $DAD8,$0000,$01A0,$0004,$BEC8,$0004,$BED0
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
ShellCentreX:
                dc.w    $0000
ShellBroken:
                dc.b    $00
ShellGone:
                dc.b    $00
; Shell: a ring of 12 turrets circling a moving centre (path at $792D1). One
;   of them (number 3) is the control unit: when it is open (frame 5+) and
;   has taken 6 hits, every turret explodes for 200 points each
; (32x27, 8 frames, gfx $6EE58, 1 hit point, score 200, update Upd_Shell, spawn Spawn_Shell)
Def_Shell:
                dc.b    $1B,$03,$00,$2E,$03,$60,$00,$23,$00,$01,$00,$00,$00,$06,$EE
                dc.b    $58,$00,$00,$01,$B0,$00,$04,$BF,$2C,$00,$04,$BF,$42
                dc.l    Upd_Shell
                dc.l    Spawn_Shell
                dc.b    $00,$00,$02,$00,$04,$03,$02,$01,$00,$07,$06,$05,$FF,$10,$FF
ShellControlAnim:
                dc.b    $0C,$0B,$0A,$09,$08,$0F,$0E,$0D,$FF,$10,$FF,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15,$00,$02,$00,$03,$00,$17,$00,$15,$00,$02,$00,$03,$00
                dc.b    $17,$00,$15
; Tabrok: big interceptor, 30 hit points.  It walks in (up to 100 frames,
;   3 px a frame) until blocked, rises 56 px, moves 132 px right, then
;   drops to the ground and stands.  Level with the ship (18 px) it fires a
;   TabrokMissile (18 frames apart), and every 116 frames 4 TabrokHomers
;   that steer towards the ship every 6 frames, 22 times.
; (48x43, 5 frames, gfx $727B8, 30 hit points, score 800, update Upd_Tabrok, spawn Spawn_Tabrok)
Def_Tabrok:
                dc.b    $2B,$04,$00,$2C,$08,$10,$00,$01,$00,$1E,$00,$00,$00
                dc.b    $07,$27,$B8,$00,$00,$04,$08,$00,$04,$BF,$F2,$00,$04,$BF,$FE
                dc.l    Upd_Tabrok
                dc.l    Spawn_Tabrok
                dc.w    $0000,$0800
TabrokWalkAnim:
                dc.b    $00,$01,$02,$01,$00,$03,$04,$03,$FF
TabrokFireAnim:
                dc.b    $05,$06,$FF,$00,$0E,$00,$02,$00,$12,$00,$24,$00,$0C,$00,$02,$00
                dc.b    $16,$00,$25,$00,$0A,$00,$02,$00,$1A,$00,$23,$00,$0C,$00,$02,$00
                dc.b    $14,$00,$23,$00,$0A,$00,$02,$00,$19,$00,$24,$00,$07,$00,$02,$00
                dc.b    $15,$00,$21,$00,$07,$00,$02,$00,$15,$00,$21
; Tabrok's missile: 6 px a frame to the left, explodes on the map
; (16x9, 1 frame, gfx $76028, 1 hit point, update Upd_TabrokMissile)
Def_TabrokMissile:
                dc.w    $0902,$0030,$0090,$0000,$0001,$0000,$0007,$6028
                dc.w    $0000,$0048,$0004,$C05E,$0004,$C060
                dc.l    Upd_TabrokMissile
                dc.w    $0000,$0000,$0000,$0000,$00FF,$0003,$0001,$000C
                dc.w    $0007
; Tabrok's homing micro-missile: turns towards the ship every 6 frames for a
;   while, explodes on the map
; (16x15, 16 frames, gfx $760B8, 1 hit point, update Upd_TabrokHomer)
Def_TabrokHomer:
                dc.w    $0F02,$0030,$00F0,$0000,$0001,$0000,$0007,$60B8
                dc.w    $0000,$0078,$0004,$C090,$0004,$C0A2
                dc.l    Upd_TabrokHomer
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
TabrokHomerDirs:
                dc.w    $000C,$000D,$000F,$0001
TabrokHomerSteps:
                dc.w    $0000,$FFFD,$0002,$FFFD,$0003,$FFFD,$0003,$FFFE
                dc.w    $0003,$0000,$0003,$0002,$0003,$0003,$0002,$0003
                dc.w    $0000,$0003,$FFFE,$0003,$FFFD,$0003,$FFFD,$0002
                dc.w    $FFFD,$0000,$FFFD,$FFFE,$FFFD,$FFFD,$FFFE,$FFFD
BossTimer:
                dc.w    $0000
BossMouthFrames:
                dc.w    $0004,$C184,$0004,$C18C,$0004,$C184,$0004,$C17C
                dc.w    $017C,$817D,$0190,$8191,$017E,$817F,$0192,$8193
                dc.w    $0180,$8181,$0194,$8195
BossPulseFrames:
                dc.w    $0004,$C1AC,$0004,$C1B4,$0004,$C1AC,$0004,$C1A4
                dc.w    $8154,$8155,$8168,$8169,$8158,$8159,$016C,$816D
                dc.w    $815C,$815D,$0000,$8171
BossMouthStep:
                dc.b    $00
BossMouthTimer:
                dc.b    $00
BossMouthOpen:
                dc.b    $00
BossAdvance:
                dc.b    $00
BossPulseTimer:
                dc.b    $00
BossPulseStep:
                dc.b    $00
TailX:
                dc.w    $0000
BossDead:
                dc.w    $0000
TailWave:
                dc.w    $0000
TailTimer:
                dc.w    $0000
; Dobkeratops (boss): its tail, 16 segments on a 40-step wave table
;   ($78AB8); each segment points at the ship. Flashes while the core is
;   hit; explodes segment by segment when the boss dies
; (16x16, 6 frames, gfx $784B8, 1 hit point, update Upd_DobkeratopsTail, spawn Spawn_DobkeratopsTail)
Def_DobkeratopsTail:
                dc.w    $1002,$0030,$0100,$0001,$0001,$0000,$0007
                dc.w    $84B8,$0000,$0080,$0004,$C1F2,$0004,$C1FA
                dc.l    Upd_DobkeratopsTail
                dc.l    Spawn_DobkeratopsTail
                dc.w    $0000,$0000,$0001,$0203,$0405,$FF00,$0002,$0002
                dc.w    $000C,$000C,$0002,$0002,$000C,$000C,$0002,$0002
                dc.w    $000C,$000C,$0002,$0002,$000C,$000C,$0002,$0002
                dc.w    $000C,$000C,$0003,$0003,$000A,$000A
; Dobkeratops's core, the alien in its belly: an invisible, indestructible
; 20x20 target that counts its damage.  Every 64 frames it fires 5
; DobkeratopsShots; BossHit flashes the tail when it is hit; after 20
; hits the shots come faster, after 30 the boss dies (BossDead,
; LevelComplete, 6200 points) and it keeps leaving random explosions.
Def_DobkeratopsCore:
                dc.w    $0102,$0030
                dc.w    $0010,$0001,$FFFF,$0000,$0004,$C25C,$0000,$0080
                dc.w    $0004,$C252,$0004,$C254
                dc.l    Upd_DobkeratopsCore
                dc.l    Spawn_DobkeratopsCore
                dc.w    $0000,$0000,$00FF,$0000,$0000,$0014,$0014,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000
; Dobkeratops's shots: fired in fives, on curved paths ($79607) chosen by
;   the ship's height
; (32x21, 8 frames, gfx $76FB8, 1 hit point, update Upd_DobkeratopsShot)
Def_DobkeratopsShot:
                dc.w    $1503,$002E,$02A0,$0000,$0001,$0000,$0007,$6FB8
                dc.w    $0000,$0150,$0004,$C290,$0004,$C29A
                dc.l    Upd_DobkeratopsShot
                dc.w    $0000,$0000,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011,$0002
                dc.w    $0002,$0010,$0011,$0002,$0002,$0010,$0011
BossHit:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
