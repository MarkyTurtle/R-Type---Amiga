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
; Stage 7, the city in ruins.  Enemies: level 1's Pata-Pata, Bug, P-Staff,
; Scant, Bink and Cancer, level 5's Mid-phase Cheetah, Bold, the Sonar,
; a Crawler, collapsing buildings, the POW Armor; the boss is Bronco, with
; 5 garbage chutes dropping junk and enemies.
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
                dc.l    $4D300                  ; tiles: the start of level B
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $582A4                  ; LvMusic: player in level B; samples $604F8 (9), data $60594, periods $60540
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $046C
                dc.l    WavesFrom_046C
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
AllWaves:
Waves:
                dc.w    $003C,$0000,$0000
                dc.l    PataPataData1,$00000000,Def_PataPata
                dc.w    $003E,$0170,$0064
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0069,$0000,$0000
                dc.l    PataPataData1,$00000000,Def_PataPata
                dc.w    $008C,$0000,$0000
                dc.l    PataPataData2,$00000000,Def_PataPata
                dc.w    $00BE,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $00D2,$0000,$0000
                dc.l    PataPataData2,$00000000,Def_PataPata
                dc.w    $00F5,$00E9,$0010
                dc.l    $00360000,$00000000,Def_Collapse
                dc.w    $00FA,$0000,$0000
                dc.l    $0BB8000B,CancerData1,Def_Cancer
                dc.w    $010E,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $0122,$0170,$0067
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0131,$0170,$00A6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $013D,$0102,$00B4
                dc.l    $0D7E0001,$00010000,Def_Collapse
                dc.w    $0140,$0170,$005A
                dc.l    $0004FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0168,$00D2,$0010
                dc.l    $00420000,$00000000,Def_Collapse
                dc.w    $0172,$012C,$00B4
                dc.l    $0D8A0001,$00010000,Def_Collapse
                dc.w    $017C,$011D,$000B
                dc.l    BugData1,$0009FFFF,Def_Bug 
                dc.w    $019A,$0170,$0096
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $01A4,$015E,$0092
                dc.l    $FFFE0000,$00000000,Def_Crawler
                dc.w    $01A9,$0000,$0000
                dc.l    $0BB8000B,CancerData2,Def_Cancer
                dc.w    $01B3,$015E,$0092
                dc.l    $00020000,$00000000,Def_Crawler
                dc.w    $01C5,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $01CC,$015E,$0064
                dc.l    $00020000,$00000000,Def_Crawler
                dc.w    $01D1,$015E,$0063
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $01FE,$0000,$0000
                dc.l    $0BB8000B,CancerData3,Def_Cancer
                dc.w    $0203,$00FF,$001E
                dc.l    $00580002,$00000000,Def_Collapse
                dc.w    $0213,$015E,$0087
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $022B,$0010,$0055
                dc.l    $00000004,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0231,$0106,$00B4
                dc.l    $0B320003,$00010000,Def_Collapse
                dc.w    $0244,$015E,$0040
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0258,$00DC,$001E
                dc.l    $00600004,$00000000,Def_Collapse
                dc.w    $028E,$015E,$0078
                dc.l    $00020000,$00000000,Def_Crawler
                dc.w    $028F,$00D8,$00B4
                dc.l    $0B3A0005,$00010000,Def_Collapse
                dc.w    $0294,$00F0,$0014
                dc.l    $006A0000,$00000000,Def_Collapse
                dc.w    $02A8,$0122,$0014
                dc.l    $00700002,$00000000,Def_Collapse
                dc.w    $02B1,$015E,$0078
                dc.l    $00020000,$00000000,Def_Crawler
                dc.w    $02C6,$011E,$00B4
                dc.l    $0DB20001,$00010000,Def_Collapse
                dc.w    $02BC,$0000,$0070
                dc.l    $00000000,$00000000,Def_Bold
                dc.w    $02C6,$0170,$00A6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $02D0,$0170,$0067
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $02E6,$010C,$0014
                dc.l    $00780004,$00000000,Def_Collapse
                dc.w    $0301,$015E,$00A6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0302,$015E,$0067
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0303,$015E,$0028
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0320,$015E,$0028
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $034E,$00F4,$0014
                dc.l    $00820000,$00000000,Def_Collapse
                dc.w    $035C,$015E,$005A
                dc.l    $0001FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0361,$0000,$0000
                dc.l    $0BB8000B,CancerData4,Def_Cancer
                dc.w    $0370,$00FD,$00B4
                dc.l    $0DC40001,$00010000,Def_Collapse
                dc.w    $0375,$0163,$0078
                dc.l    $00000000,$00000000,Def_MidCheetah
                dc.w    $0398,$015E,$0067
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $03AF,$010E,$00B4
                dc.l    $0B620003,$00010000,Def_Collapse
                dc.w    $03CA,$00E8,$0014
                dc.l    $008E0002,$00000000,Def_Collapse
                dc.w    $03F2,$0028,$006B
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $03F7,$00F0,$0014
                dc.l    $00960004,$00000000,Def_Collapse
                dc.w    $0410,$0000,$0000
                dc.l    $0BB8000B,CancerData5,Def_Cancer
                dc.w    $043A,$00AC,$00B4
                dc.l    $0B6A0005,$00010000,Def_Collapse
                dc.w    $0451,$0000,$0000
                dc.l    $0BB8000B,CancerData6,Def_Cancer
                dc.w    $0456,$00DC,$0014
                dc.l    $00A00000,$00000000,Def_Collapse
                dc.w    $0474,$0118,$0014
                dc.l    $00AC0000,$00000000,Def_Collapse
WavesFrom_046C:
                dc.w    $04A8,$0028,$006B
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $04AA,$015E,$00B8
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $04BE,$015E,$00B8
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $04D2,$015E,$00B8
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $04E6,$015E,$00B8
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $04FA,$015E,$00B8
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0500,$0000,$0000
                dc.l    $0BB80041,CancerData7,Def_Cancer
                dc.w    $050E,$015E,$00B8
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0559,$00E6,$00B4
                dc.l    $0DFE0001,$00010000,Def_Collapse
                dc.w    $055F,$011D,$000B
                dc.l    BugData2,$000AFFFF,Def_Bug 
                dc.w    $0581,$0109,$000B
                dc.l    BugData3,$0012FFFF,Def_Bug 
                dc.w    $0607,$00DC,$0014
                dc.l    $00D60000,$00000000,Def_Collapse
                dc.w    $0640,$0163,$00B6
                dc.l    $000F0004,$00000000,Def_PStaff
                dc.w    $0668,$0023,$00B8
                dc.l    BugData4,$000BFFFF,Def_Bug 
                dc.w    $0672,$0000,$0000
                dc.l    PataPataData3,$00000000,Def_PataPata
                dc.w    $06C2,$0000,$0000
                dc.l    PataPataData4,$00000000,Def_PataPata
                dc.w    $06C4,$0163,$00B6
                dc.l    $000F0005,$00000000,Def_PStaff
                dc.w    $06C7,$0170,$005A
                dc.l    $0005FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $06F9,$0073,$0014
                dc.l    $00E80000,$00000000,Def_Collapse
                dc.w    $0703,$007F,$00B4
                dc.l    $0E260001,$00010000,Def_Collapse
                dc.w    $0726,$0000,$0000
                dc.l    PataPataData4,$00000000,Def_PataPata
                dc.w    $0771,$0000,$0000
                dc.l    PataPataData5,$00000000,Def_PataPata
                dc.w    $07D0,$0170,$0084
                dc.l    $00000000,$00000000,Def_Scant
                dc.w    $7530   ; end: never reached
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00C0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
Spawn_PataPata:
                movea.l $6(a1),a3               ; the group list
.4A92C:
                move.w  (a3)+,d1                ; y ($FFFF ends)
                bmi.b   .4A94C
                move.w  #$170,d0                ; enter at the right edge
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  (a3)+,$32(a0)           ; delay before it starts
                move.b  (a3)+,$1F(a0)           ; first animation frame
                clr.w   $34(a0)                 ; position in the wave table
                jsr     (jt_ObjInsert).w
                bra.b   .4A92C
.4A94C:
                rts
Upd_PataPata:
                tst.b   $32(a0)                 ; still waiting?
                beq.b   .4A95A
                subq.b  #$1,$32(a0)
                rts
.4A95A:
                lea.l   ($70A06).l,a1           ; wave: 35 signed y steps (level B)
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d1
                ext.w   d1
                add.w   d1,$C(a0)               ; bob up and down
                addq.w  #$1,d0
                cmp.w   #$23,d0
                bcs.b   .4A978
                clr.w   d0
.4A978:
                move.w  d0,$34(a0)
                subq.w  #$4,$A(a0)              ; 4 pixels left a frame
                cmpi.w  #$20,$A(a0)             ; gone off the left edge?
                bhi.b   .4A98C
                jmp     (jt_ObjKillSelf).w
.4A98C:
                rts
Spawn_Bug:
                moveq   #7,d5                   ; Bugs 7 frames apart,
                move.w  $A(a1),d7               ; entry $0A: number - 1
                cmp.w   #$9,d7                  ; more than 10 Bugs:
                bls.b   .4A99C
                moveq   #10,d5                  ; 10 frames apart (level 7 only)
.4A99C:
                clr.w   d6                      ; d6 = start delay
.4A99E:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                moveq   #1,d2                   ; 1 hit point
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.l  $6(a1),$32(a0)          ; the path
                clr.w   $36(a0)                 ; path step
                move.w  $C(a1),$3A(a0)          ; extra x speed
                move.b  d6,$38(a0)              ; start delay
                jsr     (jt_ObjInsert).w
                add.w   d5,d6
                dbra    d7,.4A99E
                rts
Upd_Bug:
                move.w  $3A(a0),d0              ; drift with its own x speed
                add.w   d0,$A(a0)
                tst.b   $38(a0)                 ; still waiting?
                beq.b   .4A9E4
                subq.b  #$1,$38(a0)
                rts
.4A9E4:
                movea.l $32(a0),a1              ; path: steps, dx, dy, frame tables
                move.w  $36(a0),d0              ; step number
                move.w  (a1)+,d1
                bsr.b   .4AA1E                  ; x += dx[step]
                add.w   d2,$A(a0)
                bsr.b   .4AA1E                  ; y += dy[step]
                add.w   d2,$C(a0)
                bsr.b   .4AA1E                  ; frame
                move.b  d2,$1F(a0)
                cmp.w   d1,d0                   ; end of the path: keep the last step
                bcc.b   .4AA08
                addq.w  #$1,$36(a0)
.4AA08:
                cmpi.w  #$15E,$A(a0)            ; off the screen:
                bhi.b   .4AA18
                cmpi.w  #$2,$A(a0)
                bcc.b   .4AA1C
.4AA18:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AA1C:
                rts
.4AA1E:
                movea.l (a1)+,a2                ; table
                move.b  (a2,d0.w),d2            ; entry for this step
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
                bhi.b   .4AA5E
                jmp     (jt_ObjKillSelf).w      ; yes: remove
.4AA5E:
                tst.b   $36(a0)                 ; state 0: walking
                beq.b   .4AA7C
                cmpi.b  #$1,$36(a0)
                beq.b   .4AAAA                  ; state 1: firing a volley
                subq.w  #$1,$A(a0)              ; state 2, paused: scroll with the map
                subq.b  #$1,$37(a0)             ; count down the pause
                bpl.b   .4AAE0
                bsr.w   PStaff_TryFire          ; then fire if the ship is in range, otherwise walk
                rts
.4AA7C:
                bsr.w   PStaff_Approach         ; head for 60-79 pixels from the ship
                movem.w $A(a0),d0-d1            ; probe the map ahead at foot level
                add.w   #$B,d1
                tst.w   $32(a0)
                bpl.b   .4AA96                  ; walking right?
                sub.w   #$10,d0                 ; left: probe 16 pixels ahead
                bra.b   .4AA9A
.4AA96:
                add.w   #$21,d0                 ; right: probe just past the body
.4AA9A:
                jsr     (jt_GetMapCell).w       ; wall ahead?
                bne.b   PStaff_Halt             ; yes: stop
                move.w  $32(a0),d0
                add.w   d0,$A(a0)               ; take a step
                rts
.4AAAA:
                subq.w  #$1,$A(a0)              ; state 1: scroll with the map
                subq.w  #$1,$34(a0)             ; frames to the next shot
                bmi.b   .4AAB6
                rts
.4AAB6:
                move.w  #$A,$34(a0)             ; 10 frames between shots
                subq.b  #$1,$37(a0)             ; shots left in the volley
                bpl.b   .4AAE2                  ; more: fire one
                bsr.w   PStaff_Approach         ; volley done: face the ship again
                move.l  #PStaffFireAnimEnd,d0   ; animation index = end of the fire animation
                sub.l   $2A(a0),d0
                move.w  d0,$1E(a0)
                move.b  #$2,$36(a0)             ; then pause (state 2)
                move.b  #$A,$37(a0)             ; for 10 frames
.4AAE0:
                rts
.4AAE2:
                bra.w   PStaff_Fire
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
ShipDistX:
                moveq   #1,d2
                move.w  (ShipPos).w,d0          ; ship x
                sub.w   $A(a0),d0               ; minus our x
                bpl.b   .4AB58                  ; ship to the right: d2 = 1
                neg.w   d0                      ; ship to the left: d0 = |dx|, d2 = -1
                neg.w   d2
                add.w   #$1E,d0                 ; and allow 30 pixels for the ship's width
.4AB58:
                rts
ShipDistY:
                moveq   #1,d2
                move.w  ($F0).w,d0              ; ship y
                sub.w   #$1F,d0                 ; to its top edge
                sub.w   $C(a0),d0               ; minus our y
                bpl.b   .4AB6E
                neg.w   d0
                neg.w   d2
.4AB6E:
                rts
PStaff_Approach:
                bsr.b   ShipDistX
                cmp.w   #$3C,d0                 ; 60-79 pixels away:
                blt.b   .4AB80
                cmp.w   #$50,d0
                bcs.w   PStaff_Halt             ; stop here
.4AB80:
                clr.b   $36(a0)                 ; otherwise walk (state 0)
                moveq   #70,d1                  ; 70 - distance
                sub.w   d0,d1
                bpl.b   .4AB9C                  ; closer than 70: walk away
                move.w  #$FFFE,$32(a0)          ; further: walk towards the ship
                tst.w   d2
                bmi.b   .4AB9A
                move.w  #$2,$32(a0)
.4AB9A:
                bra.b   .4ABAC
.4AB9C:
                move.w  #$2,$32(a0)             ; walk away from the ship
                tst.w   d2
                bmi.b   .4ABAC
                move.w  #$FFFE,$32(a0)
.4ABAC:
                move.b  #$0,$36(a0)
                lea.l   (PStaffWalkLeft).l,a1   ; walking animation for the direction
                tst.w   $32(a0)
                bmi.b   .4ABC4
                lea.l   (PStaffWalkRight).l,a1
.4ABC4:
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
                bpl.b   .4AC00
                clr.w   d1                      ; not below 0
.4AC00:
                move.w  d1,$32(a0)              ; y index into the up-speed table
                bsr.w   ShipDistX               ; x table start = 19 + random(10) - dx/8,
                lsr.w   #$3,d0
                moveq   #19,d1
                move.w  d0,-(a7)
                moveq   #10,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   .4AC1C
                clr.w   d1                      ; not below 0
.4AC1C:
                move.w  d1,$34(a0)              ; x index into the side-speed table
                move.w  $3C(a4),$36(a0)         ; direction: towards the ship
                clr.b   $22(a0)                 ; frame is set by the update routine
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w        ; link it in
                movea.l a4,a0                   ; back to the P-Staff
                rts
Upd_PStaffMissile:
                lea.l   ($70A87).l,a3           ; up speeds, by y index ($7F ends)
                lea.l   ($70A29).l,a1           ; side speeds, by x index ($7F ends)
                lea.l   ($70AE5).l,a2           ; frame per y index (the arc's angle)
                movem.w $32(a0),d0-d2           ; d0 y index, d1 x index, d2 direction
                move.b  (a3,d0.w),d3
                cmp.b   #$7F,d3                 ; end of the arc:
                beq.b   .4ACCC                  ; explode
                neg.b   d3                      ; table is upward speed
                move.b  (a1,d1.w),d4
                bne.b   .4AC64                  ; side speed is at least 1
                addq.b  #$1,d4
.4AC64:
                cmp.b   #$7F,d4
                beq.b   .4ACCC
                addq.w  #$1,$32(a0)             ; step along both tables
                addq.w  #$1,$34(a0)
                ext.w   d3
                ext.w   d4
                asl.w   #$1,d4                  ; side speed doubled
                tst.w   d2
                bpl.b   .4AC7E
                neg.w   d4                      ; fired to the left
.4AC7E:
                add.w   d3,$C(a0)               ; move
                add.w   d4,$A(a0)
                cmpi.w  #$20,$A(a0)             ; off the left edge,
                bcs.b   .4ACA6
                cmpi.w  #$170,$A(a0)            ; or right of x $170,
                bhi.b   .4ACAA
                cmpi.w  #$E0,$C(a0)             ; or off the bottom or top:
                bhi.b   .4ACA6
                cmpi.w  #$10,$C(a0)
                bhi.b   .4ACAA
.4ACA6:
                jmp     (jt_ObjKillSelf).w      ; remove
.4ACAA:
                move.b  (a2,d0.w),d3            ; frame for this point of the arc
                ext.w   d3
                tst.w   d2
                bpl.b   .4ACB8
                add.w   #$9,d3                  ; left-facing frames start at 9
.4ACB8:
                move.w  d3,$1E(a0)
                movem.w $A(a0),d0-d1            ; centre of the missile
                addq.w  #$8,d0
                addq.w  #$6,d1
                jsr     (jt_GetMapCell).w       ; hit the map?
                beq.b   .4ACD6                  ; no: carry on
.4ACCC:
                move.b  #$1,$5(a0)              ; yes: explode
                clr.l   $6(a0)                  ; and stop updating
.4ACD6:
                rts
Spawn_Scant:
                st.b    (MusicFadeReq).w        ; level 7's Scant also fades the music out (the boss is near)
                movem.w $2(a1),d0-d1
                move.w  $8(a2),d2               ; (overwritten:)
                moveq   #30,d2                  ; 30 hit points
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$2,$21(a0)             ; explosion type 2
                clr.w   $3A(a0)
                move.w  #$7D,$3C(a0)            ; after 125 frames it heads off left
                bsr.w   Scant_NextMove          ; first move
                jmp     (jt_ObjInsert).w
Upd_Scant:
                tst.b   $39(a0)                 ; state: 0 vertical, 1 horizontal, 2 pause
                beq.b   .4AD1E
                cmpi.b  #$1,$39(a0)
                beq.b   .4AD48
                subq.b  #$1,$3A(a0)             ; pausing
                bmi.b   .4AD82
                rts
.4AD1E:
                move.w  $C(a0),d1               ; state 0, diagonal move: y
                tst.w   $34(a0)                 ; moving up?
                bmi.b   .4AD40
                cmp.w   $36(a0),d1              ; down: reached the target y?
                bgt.b   .4AD6C
.4AD2E:
                movem.w $32(a0),d0-d1           ; move by dx, dy
                add.w   d0,$A(a0)
                add.w   d1,$C(a0)
                bra.w   Scant_Age
.4AD40:
                cmp.w   $36(a0),d1              ; up: reached the target y?
                blt.b   .4AD6C
                bra.b   .4AD2E
.4AD48:
                move.w  $A(a0),d1               ; state 1, sideways move: x
                tst.w   $32(a0)                 ; moving left?
                bmi.b   .4AD64
                cmp.w   $36(a0),d1              ; right: reached the target x?
                bgt.b   .4AD6C
.4AD58:
                move.w  $32(a0),d0              ; move by dx
                add.w   d0,$A(a0)
                bra.w   Scant_Age
.4AD64:
                cmp.w   $36(a0),d1              ; left: reached the target x?
                blt.b   .4AD6C
                bra.b   .4AD58
.4AD6C:
                move.b  #$2,$39(a0)             ; arrived: pause (state 2)
                moveq   #25,d0
                jsr     (jt_Random).w           ; pause up to 25 frames
                move.b  d0,$3A(a0)
                clr.w   $1E(a0)                 ; resting frame
                rts
.4AD82:
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
                move.w  #$2,$1E(a0)             ; firing frame
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
Scant_NextMove:
                move.w  ($F0).w,d0              ; ship y - 15 .. ship y + 5:
                sub.w   #$F,d0
                move.w  d0,d1
                add.w   #$14,d1
                cmp.w   $C(a0),d0               ; above the band:
                bgt.b   .4AE4A
                cmp.w   $C(a0),d1               ; or below it: move diagonally
                blt.b   .4AE4A
                clr.w   $34(a0)                 ; level with the ship: sideways only
                moveq   #50,d0                  ; a random distance up to 49 pixels
                jsr     (jt_Random).w
                move.w  d0,d2
                tst.b   $3B(a0)                 ; leaving?
                bmi.b   .4AE2A
                move.w  $A(a0),d1
                add.w   d2,d1
                cmp.w   #$122,d1                ; or it would pass x $122:
                ble.b   .4AE2E
.4AE2A:
                moveq   #-2,d0                  ; go left
                bra.b   .4AE32
.4AE2E:
                bsr.w   .4AEAA                  ; otherwise right (always 2: random(1) is 0)
.4AE32:
                tst.w   d0
                bpl.b   .4AE38
                neg.w   d2
.4AE38:
                add.w   $A(a0),d2               ; target x
                move.w  d2,$36(a0)
                move.b  #$1,$39(a0)             ; state 1
                bra.w   .4AE96
.4AE4A:
                clr.b   $39(a0)                 ; state 0: diagonal
                move.w  ($F0).w,d2              ; target y = ship y - 30 + random(59),
                sub.w   #$1E,d2
                moveq   #59,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                cmp.w   #$B1,d2                 ; at most $B0
                blt.b   .4AE68
                move.w  #$B0,d2
.4AE68:
                move.w  d2,$36(a0)
                moveq   #2,d0                   ; 2 pixels a frame up or down
                sub.w   $C(a0),d2
                bpl.b   .4AE78
                neg.w   d0
                neg.w   d2
.4AE78:
                move.w  d0,$34(a0)
                move.w  $A(a0),d0
                add.w   d2,d0                   ; the same distance sideways:
                tst.b   $3B(a0)                 ; leaving,
                bmi.b   .4AE8E
                cmp.w   #$122,d0                ; or past x $122:
                ble.b   .4AE92
.4AE8E:
                moveq   #-2,d0                  ; go left
                bra.b   .4AE96
.4AE92:
                bsr.w   .4AEAA                  ; otherwise right
.4AE96:
                move.w  #$1,$1E(a0)             ; frame 1 moving right,
                move.w  d0,$32(a0)
                bpl.b   .4AEA8
                move.w  #$2,$1E(a0)             ; frame 2 moving left
.4AEA8:
                rts
.4AEAA:
                moveq   #1,d0                   ; random(1) is always 0, so this is always 2
                jsr     (jt_Random).w
                asl.w   #$1,d0
                addq.w  #$1,d0
                asl.w   #$1,d0
                rts
Scant_Age:
                subq.w  #$1,$3C(a0)             ; after 125 frames
                bpl.b   .4AEC2
                st.b    $3B(a0)                 ; it only moves left
.4AEC2:
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
                move.l  #BinkWalkRight,$2A(a0)  ; walking right,
                move.w  $6(a1),$32(a0)          ; step (entry $06)
                bpl.b   .4AF04
                move.l  #BinkWalkLeft,$2A(a0)   ; negative: walking left
.4AF04:
                move.w  $32(a0),d2
                bsr.w   Bink_Jump               ; start with a jump
                move.w  #$200,$34(a0)           ; then state 2 (falling), byte $35 = 0
                clr.w   $1E(a0)                 ; first walking frame
                bsr.w   Bink_Fall               ; drop to the ground
                jmp     (jt_ObjInsert).w
Upd_Bink:
                cmpi.w  #$10,$A(a0)             ; off the screen: remove
                bcs.b   .4AF36
                cmpi.w  #$170,$A(a0)
                bhi.b   .4AF36
                cmpi.w  #$E0,$C(a0)
                bcs.b   .4AF3A
.4AF36:
                jmp     (jt_ObjKillSelf).w
.4AF3A:
                move.b  $34(a0),d0              ; state: 0 walk, 1 jump, 2 fall, -1 stopped
                beq.b   .4AF86
                cmp.b   #$1,d0
                beq.w   Bink_Jumping
                cmp.b   #$2,d0
                beq.w   Bink_Fall
                subq.w  #$1,$A(a0)              ; stopped: scrolls with the map
                subq.b  #$1,$35(a0)             ; every 10 frames
                bmi.b   .4AF6C
                rts
.4AF5C:
                st.b    $34(a0)                 ; blocked: stop (state -1)
                clr.b   $22(a0)                 ; hold the animation
                move.l  #BinkWalkLeft,$2A(a0)
.4AF6C:
                move.b  #$A,$35(a0)             ; turn to face the ship every 10 frames
                bsr.w   ShipDistX               ; face the ship
                move.w  #$B,$1E(a0)             ; frame 11: facing right
                tst.w   d2
                bpl.b   .4AF84
                clr.w   $1E(a0)
.4AF84:
                rts
.4AF86:
                move.w  $32(a0),d2              ; walking: step and direction
                movem.w $A(a0),d0-d1            ; probe at foot height
                add.w   #$C,d1
                subq.w  #$3,d0                  ; 3 pixels behind the left edge
                tst.w   d2
                bmi.b   .4AF9E                  ; walking left?
                add.w   #$23,d0                 ; right: just past the body
.4AF9E:
                jsr     (jt_GetMapCell).w       ; walking: a tile ahead?
                bne.b   .4AF5C
                adda.l  (MapRowBytes).w,a4      ; the cell below
                btst.b  #$7,(a4)                ; ground ahead (one row down)?
                beq.b   Bink_Jump               ; no ground: jump off
                add.w   d2,$A(a0)               ; yes: step on
                rts
Bink_Jump:
                move.b  #$1,$34(a0)             ; state 1: jumping
                clr.w   $36(a0)                 ; start of the jump arc
                move.w  #$23,$38(a0)
                move.l  #BinkJumpRight,$2A(a0)  ; jump animation for the direction
                tst.w   d2
                bpl.b   .4AFD8
                move.l  #BinkJumpLeft,$2A(a0)
.4AFD8:
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
                bne.b   .4B006
                move.b  #$2,$34(a0)             ; yes: fall (state 2)
                bra.b   Bink_Fall
.4B006:
                ext.w   d3
                tst.w   $32(a0)                 ; walking left?
                bpl.b   .4B010
                neg.w   d2                      ; yes: sideways step to the left
.4B010:
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
                bne.b   .4B03A
                addq.w  #$4,$C(a0)              ; no: fall 4 pixels a frame
                rts
.4B03A:
                clr.w   $34(a0)                 ; landed: walk (state 0)
                move.l  #BinkWalkRight,$2A(a0)  ; walking animation for the direction
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.w   $32(a0)
                bpl.b   .4B05C
                move.l  #BinkWalkLeft,$2A(a0)
.4B05C:
                rts
Spawn_Cancer:
                movea.l $A(a1),a3               ; list of x, y
                move.w  $8(a1),d7               ; frames between them
                clr.w   d6                      ; first start delay 0
.4B068:
                move.w  (a3)+,d0                ; x ($FFFF ends the list)
                bmi.b   .4B08C
                move.w  (a3)+,d1                ; y
                move.w  $8(a2),d2               ; hit points from the definition
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)          ; scroll x at which it gives up
                clr.w   $38(a0)                 ; new heading at once
                move.w  d6,$32(a0)              ; start delay
                add.w   d7,d6                   ; the next one starts later
                jsr     (jt_ObjInsert).w
                bra.b   .4B068                  ; next position
.4B08C:
                rts
Upd_Cancer:
                tst.w   $32(a0)                 ; waiting to start?
                beq.b   .4B09A
                subq.w  #$1,$32(a0)             ; count the delay down
                rts
.4B09A:
                subq.w  #$1,$A(a0)              ; scrolls with the map
                movem.w $A(a0),d0-d1            ; off the screen:
                cmp.w   #$10,d0
                bcs.b   .4B0BC
                cmp.w   #$170,d0
                bhi.b   .4B0BC
                cmp.w   #$2,d1                  ; top limit 2 here (16 in level 1)
                bcs.b   .4B0BC
                cmp.w   #$E0,d1
                bcs.b   .4B0C0
.4B0BC:
                jmp     (jt_ObjKillSelf).w      ; remove
.4B0C0:
                move.w  $3A(a0),d4              ; scroll x at which it gives up
                cmp.w   (ScrollX).w,d4          ; past its scroll x:
                bhi.b   .4B0DA
                moveq   #10,d7                  ; make for the nearer edge
                cmp.w   #$88,d1                 ; upper half: the top (y 10),
                bcs.b   .4B0D6
                move.w  #$E0,d7                 ; lower half: the bottom (y $E0)
.4B0D6:
                moveq   #4,d6                   ; and x 4: off to the left
                bra.b   .4B0E6                  ; steer at once
.4B0DA:
                subq.w  #$1,$38(a0)             ; time for a new heading?
                bpl.b   .4B124
                movem.w (ShipPos).w,d6-d7       ; target: the ship
.4B0E6:
                moveq   #2,d4
                lea.l   (CancerAnimRight).l,a1  ; x step +2 / -1, facing it
                cmp.w   d6,d0                   ; target to the right:
                bcs.b   .4B0FA
                moveq   #-1,d4                  ; left: x step -1
                lea.l   (CancerAnimLeft).l,a1
.4B0FA:
                move.l  a1,$2A(a0)
                moveq   #1,d5                   ; y step +1 / -1
                cmp.w   d7,d1                   ; target below:
                bcs.b   .4B106
                neg.w   d5                      ; above: -1
.4B106:
                move.w  d0,d2                   ; |dx| to the target
                sub.w   d6,d2
                bpl.b   .4B10E
                neg.w   d2
.4B10E:
                lsr.w   #$2,d2                  ; hold it for |dx|/4 + random 25 frames
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)              ; frames on this heading
                move.b  d4,$36(a0)              ; x step
                move.b  d5,$37(a0)              ; y step
.4B124:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6              ; y step
                ext.w   d6
                bpl.b   .4B13A                  ; moving down?
                subq.w  #$2,d1                  ; up: probe just above it
                bra.b   .4B13E
.4B13A:
                add.w   #$20,d1                 ; down: just below it (32 pixels tall)
.4B13E:
                addq.w  #$8,d0                  ; at its middle
                jsr     (jt_GetMapCell).w       ; blocked vertically?
                bne.b   .4B14A
                add.w   d6,$C(a0)               ; no: move up/down
.4B14A:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1                  ; probe at its middle height
                move.b  $36(a0),d4              ; x step
                ext.w   d4
                bpl.b   .4B15C                  ; moving right?
                subq.w  #$2,d0                  ; left: probe just left of it
                bra.b   .4B160
.4B15C:
                add.w   #$22,d0                 ; right: just past it (34 pixels wide)
.4B160:
                jsr     (jt_GetMapCell).w       ; blocked horizontally?
                bne.b   .4B16A
                add.w   d4,$A(a0)               ; no: move left/right
.4B16A:
                rts
; LevelInit: sets up the 5 garbage chutes of the boss area (Chutes: timer,
; map address, build list) and pre-patches the map for every Collapse in
; the wave list (PrepareCollapses).
LevelInit:
                clr.b   (ChutesReady).l         ; no chute complete yet
                clr.b   (BossDead).l
                lea.l   (Chutes).l,a0           ; 5 chutes
                lea.l   (ChuteBuild).l,a1       ; all build from the same list
                move.w  #$5,(a0)                ; start delays 5, 8, 11, 14, 17 steps
                move.l  a1,$8(a0)
                move.w  #$8,$C(a0)
                move.l  a1,$14(a0)
                move.w  #$B,$18(a0)
                move.l  a1,$20(a0)
                move.w  #$E,$24(a0)
                move.l  a1,$2C(a0)
                move.w  #$11,$30(a0)
                move.l  a1,$38(a0)
                clr.b   (ChuteTimer).l
                moveq   #4,d7
.4B1BC:
                movea.l $4(a0),a2               ; its place in the map
                lea.l   (ChuteBase).l,a1        ; its empty base
                bsr.w   PatchMap                ; written in
                adda.l  #$C,a0
                dbra    d7,.4B1BC
                bra.w   PrepareCollapses        ; and the Collapse cells
FrameRts:
                rts
; LevelFrame: at scroll x $83E Bronco (the boss) and a Sonar appear; from
; $83F the scroll stops and the 5 chutes are built up in the map (3
; frames a step).  Once all 5 are complete (ChutesReady = $1F) each drops
; a random object from DropList every 25-60 frames (Upd_Falling: 4 pixels
; a frame down).  After the boss dies: random explosions.
LevelFrame:
                tst.b   (BossDead).l            ; boss dead:
                bne.w   BossExplosions          ; explosions
                cmpi.w  #$83E,(ScrollX).w       ; at scroll x $83E:
                bne.b   .4B1F4
                bsr.w   Spawn_Sonar             ; a Sonar
                bsr.w   Spawn_Bronco            ; and Bronco
.4B1F4:
                cmpi.w  #$83F,(ScrollX).w       ; from $83F:
                bcs.b   FrameRts
                clr.b   (ScrollActive).w        ; stop the scroll
                moveq   #4,d7
                lea.l   (Chutes).l,a4
                cmpi.b  #$1F,(ChutesReady).l    ; all 5 chutes complete?
                beq.b   .4B260
                subq.b  #$1,(ChuteTimer).l      ; building: a step every 3 frames
                bpl.b   FrameRts
                move.b  #$2,(ChuteTimer).l
.4B222:
                tst.w   (a4)                    ; this chute's delay
                bne.b   .4B252
                movea.l $4(a4),a2               ; map address
                movea.l $8(a4),a0               ; next build step
                move.l  (a0)+,d0
                bmi.b   .4B23E                  ; -1: complete
                movea.l d0,a1
                move.l  a0,$8(a4)
                bsr.w   PatchMap                ; write it into the map
                bra.b   .4B254
.4B23E:
                bset.b  d7,(ChutesReady).l      ; mark this chute complete
                moveq   #20,d0                  ; first drop after 10-29 frames
                jsr     (jt_Random).w
                add.w   #$A,d0
                move.w  d0,(a4)
                bra.b   .4B254
.4B252:
                subq.w  #$1,(a4)                ; count the delay down
.4B254:
                adda.l  #$C,a4                  ; next chute
                dbra    d7,.4B222
                rts
.4B260:
                subq.w  #$1,(a4)                ; dropping: this chute's timer
                bpl.b   .4B2B8
                moveq   #35,d0                  ; next drop in 25-59 frames
                jsr     (jt_Random).w
                add.w   #$19,d0
                move.w  d0,(a4)
                moveq   #5,d0                   ; one of 5 things
                jsr     (jt_Random).w
                lsl.w   #$3,d0
                lea.l   (DropList).l,a1
                movea.l (a1,d0.w),a2
                move.w  $6(a1,d0.w),d6          ; its frame
                move.w  $2(a4),d0               ; at the chute's x
                moveq   #20,d1                  ; y 20
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.w  d6,$1E(a0)
                move.l  #Upd_Falling,$6(a0)     ; falls 4 pixels a frame
                clr.b   $22(a0)                 ; no animation
                clr.w   $2E(a0)                 ; never fires
                cmpi.l  #Def_Bug,$12(a0)        ; a Bug
                bne.b   .4B2B4
                st.b    $22(a0)                 ; animates
.4B2B4:
                jsr     (jt_ObjInsert).w
.4B2B8:
                adda.l  #$C,a4
                dbra    d7,.4B260
                rts
Upd_Falling:
                addq.w  #$4,$C(a0)
                cmpi.w  #$BA,$C(a0)
                bcs.b   .4B2DA
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
.4B2DA:
                rts
Spawn_Bronco:
                moveq   #95,d1
                move.w  #$172,d0
                move.w  #$7D0,d2
                lea.l   (Def_Bronco).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$AF,$32(a0)
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
; Bronco: the runaway disposal machine.  It waits, slides out to x $131,
; opens, and slides back; 50 hits destroy it (BossDead, LevelComplete,
; 500 points).
Upd_Bronco:
                subq.w  #$1,$32(a0)                 ; wait
                bpl.b   .4B352
                clr.w   $1E(a0)
                move.l  #.4B312,$6(a0)
                bra.b   .4B352
.4B312:
                subq.w  #$2,$A(a0)                  ; slide out to x $131
                cmpi.w  #$131,$A(a0)
                bhi.b   .4B352
                st.b    $22(a0)                     ; and open
                move.l  #.4B32C,$6(a0)
                bra.b   .4B352
.4B32C:
                cmpi.w  #$10,$1E(a0)
                bne.b   .4B352
                clr.b   $22(a0)
                addq.w  #$2,$A(a0)                  ; closed again: slide back
                cmpi.w  #$163,$A(a0)
                bcs.b   .4B352
                move.w  #$7D,$32(a0)
                move.l  #Upd_Bronco,$6(a0)
.4B352:
                cmpi.w  #$32,$26(a0)                ; 50 hits:
                bcs.b   .4B372
                st.b    (BossDead).l                ; dead
                st.b    (LevelComplete).w
                move.l  #$500,d0
                jsr     (jt_AddScore).w
                jmp     (jt_ObjKillSelf).w
.4B372:
                rts
BossExplosions:
                move.w  #$A4,d0                 ; y = 40 + random(164)
                jsr     (jt_Random).w
                add.w   #$28,d0
                move.w  d0,d1
                move.w  #$118,d0                ; x = 40 + random(280)
                jsr     (jt_Random).w
                add.w   #$28,d0
                moveq   #-1,d2
                lea.l   (Def_Bronco).l,a2       ; as a plain explosion
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)                  ; exploding at once
                move.b  #$1,$5(a0)
                move.b  #$2,$21(a0)             ; type 2
                jmp     (jt_ObjInsert).w
PrepareCollapses:
                lea.l   (AllWaves).l,a0         ; every wave entry
                lea.l   (CollapseCells).l,a4    ; rubble blocks; the standing buildings are at +$18
.4B3BA:
                cmpi.w  #$7530,(a0)             ; end of the list ($7530)?
                beq.b   .4B3EA
                cmpi.l  #Def_Collapse,$E(a0)    ; a Collapse?
                bne.b   .4B3E2
                lea.l   ($57300).l,a2           ; the map (level B)
                adda.w  $6(a0),a2               ; + entry $06: its cells
                move.w  $8(a0),d0               ; entry $08: which block
                lsl.w   #$2,d0
                movea.l $18(a4,d0.w),a1         ; the standing building's cells
                bsr.w   PatchMap                ; written into the map
.4B3E2:
                adda.l  #$12,a0                 ; next entry (18 bytes)
                bra.b   .4B3BA
.4B3EA:
                rts
; Collapse: a building in the ruins that blows up - 3 explosions, and
; 16 frames after it appears its map cells are replaced by rubble
; (CollapseCells: 6 rubble blocks, then the standing buildings that
; PrepareCollapses writes into the map at level start) and the collapse
; animation plays as it slides away with the scroll (sound 12).  Placed by
; the wave list; it cannot be shot.
Spawn_Collapse:
                moveq   #-1,d0                  ; placed by its update
                moveq   #0,d1
                moveq   #-1,d2                  ; indestructible
                jsr     (jt_ObjCreate).w
                move.l  $2(a1),$32(a0)          ; entry $02: x, y
                move.l  $6(a1),$36(a0)          ; entry $06: map offset, $08: block
                move.b  #$F,$3A(a0)             ; rubble after 16 frames
                move.b  #$2,$3B(a0)             ; 3 explosions first
                move.b  #$2,$4(a0)              ; priority 2
                moveq   #16,d0                  ; explosion height 16,
                tst.w   $A(a1)                  ; entry $0A non-zero (taller):
                beq.b   .4B420
                add.w   #$A,d0                  ; 26
.4B420:
                move.w  d0,$3C(a0)
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
Upd_Collapse:
                subq.w  #$1,$32(a0)             ; x moves with the scroll
                subq.b  #$1,$3A(a0)             ; time for the rubble?
                bmi.b   .4B47E
                tst.b   $3B(a0)                 ; explosions left?
                bmi.b   .4B47C
                subq.b  #$1,$3B(a0)
                moveq   #10,d0                  ; y = y + height - 5 + random(10)
                jsr     (jt_Random).w
                subq.w  #$5,d0
                add.w   $3C(a0),d0
                add.w   $34(a0),d0
                move.w  d0,d1
                moveq   #20,d0                  ; x = x - 5 + random(20)
                jsr     (jt_Random).w
                subq.w  #$5,d0
                add.w   $32(a0),d0
                moveq   #-1,d2
                lea.l   (Def_Collapse).l,a2     ; as a plain explosion
                movea.l a0,a3
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)                  ; exploding at once
                move.b  #$1,$5(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
.4B47C:
                rts
.4B47E:
                lea.l   ($57300).l,a2           ; the map (level B)
                adda.w  $36(a0),a2              ; + its offset
                lea.l   (CollapseCells).l,a1    ; the rubble cells
                move.w  $38(a0),d0
                lsl.w   #$2,d0
                movea.l (a1,d0.w),a1
                bsr.w   PatchMap                ; replace the building
                move.l  $32(a0),$A(a0)          ; and show the collapse itself here
                st.b    $22(a0)                 ; animated
                move.l  #.4B4B4,$6(a0)          ; from now on
                moveq   #12,d0                  ; sound 12
                jmp     (jt_PlaySound).w
.4B4B4:
                subq.w  #$1,$A(a0)              ; scroll with the map
                cmpi.w  #$19,$1E(a0)            ; last frame:
                bne.b   .4B4C4
                jmp     (jt_ObjKillSelf).w      ; gone
.4B4C4:
                rts
PatchMap:
                moveq   #0,d0                   ; a1 = cells, a2 = map address (level 3's takes a0)
                moveq   #0,d1
                move.b  (a1)+,d0                ; width - 1
                move.b  (a1)+,d1                ; height - 1
.4B4CE:
                move.w  d0,d2
                movea.l a2,a3
.4B4D2:
                move.w  (a1)+,(a3)+
                dbra    d2,.4B4D2
                adda.l  (MapRowBytes).w,a2      ; next map row
                dbra    d1,.4B4CE
                rts
; Crawler (arcade name not identified, perhaps the Newt): runs left along
; the floor or ceiling (entry $06 = the y step towards it), following the
; map.
Spawn_Crawler:
                movem.w $2(a1),d0-d1
                moveq   #1,d2                   ; 1 hit point
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$32(a0)          ; entry $06: y step
                clr.b   $22(a0)
                jmp     (jt_ObjInsert).w
Upd_Crawler:
                subq.w  #$1,$A(a0)              ; scroll with the map
                movem.w $A(a0),d0-d1
                move.w  $32(a0),d7              ; y step
                bpl.b   .4B512                  ; positive: probe 2 px above,
                add.w   #$15,d1                 ; negative: 21 px below
                bra.b   .4B514
.4B512:
                subq.w  #$2,d1
.4B514:
                subq.w  #$8,d0                  ; 8 px ahead
                jsr     (jt_GetMapCell).w
                beq.b   .4B522                  ; map there:
                add.w   d7,$C(a0)               ; step in y
                bra.b   .4B532
.4B522:
                subq.w  #$2,$A(a0)              ; clear: run left 2 more pixels
                cmpi.w  #$10,$A(a0)             ; off the left edge: remove
                bhi.b   .4B532
                jmp     (jt_ObjKillSelf).w
.4B532:
                rts
; Bold: a massive floating obstacle.  It drifts right for 470 frames, then
; left; it only takes damage while the ship is behind it, and 70 hits
; destroy it (40 explosions, 1500 points).
Spawn_Bold:
                movem.w $2(a1),d0-d1
                moveq   #-1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.b  #$A,$4(a0)
                move.w  #$1D6,$32(a0)
                clr.w   $34(a0)
                clr.b   $36(a0)
                jmp     (jt_ObjInsert).w
Upd_Bold:
                tst.b   $36(a0)                     ; exploding?
                bne.w   .4B5AC
                move.w  $26(a0),d1
                clr.w   $26(a0)
                move.w  $A(a0),d0
                sub.w   (ShipPos).w,d0              ; ship in front: hits don't count
                bmi.b   .4B588
                add.w   d1,$34(a0)
                cmpi.w  #$46,$34(a0)                ; 70 hits from behind:
                bcs.b   .4B588
                move.w  #$110,$36(a0)
.4B588:
                tst.w   $32(a0)                     ; drift right for 470 frames,
                bmi.b   .4B5A0
                subq.w  #$1,$32(a0)
                btst.b  #$0,$33(a0)
                beq.b   .4B5AA
                addq.w  #$1,$A(a0)
                rts
.4B5A0:
                subq.w  #$1,$A(a0)                  ; then left
                bpl.b   .4B5AA
                jmp     (jt_ObjKillSelf).w
.4B5AA:
                rts
.4B5AC:
                subq.b  #$1,$37(a0)
                bmi.b   .4B5F8
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
                lea.l   (Def_Bold).l,a2
                jsr     (jt_ObjCreate).w
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.b  #$28,$4(a0)
                jsr     (jt_ObjInsert).w
                movea.l a3,a0
                rts
.4B5F8:
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                move.l  #$1500,d0                   ; 1500 points
                jmp     (jt_AddScore).w
Spawn_MidCheetah:
                moveq   #1,d7
                moveq   #0,d6
                moveq   #0,d5
.4B612:
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
                dbra    d7,.4B612
                rts
Upd_MidCheetah:
                tst.w   $34(a0)
                beq.b   .4B64C
                subq.w  #$1,$34(a0)
                rts
.4B64C:
                subq.w  #$3,$A(a0)
                bpl.b   .4B656
                jmp     (jt_ObjKillSelf).w
.4B656:
                subq.w  #$1,$32(a0)
                bpl.b   .4B68A
                move.w  #$32,$32(a0)
                moveq   #10,d7
                add.w   $C(a0),d7
                move.w  d7,d0
                move.w  d0,d1
                move.w  $A(a0),d0
                moveq   #-1,d2
                move.l  a0,-(a7)
                lea.l   (Def_CheetahBeam).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
.4B68A:
                rts
Upd_CheetahBeam:
                subq.w  #$7,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   .4B69C
                jmp     (jt_ObjKillSelf).w
.4B69C:
                rts
; Sonar (probably): rises out of the floor (y $DC to $AA), then turns
; towards the ship and fires every 20-40 frames; 5 hits destroy it (500
; points) and another rises at a random x after 100 frames - until the
; boss dies.
Spawn_Sonar:
                bsr.w   RandomX
                move.w  #$DC,d1
                move.w  #$7D0,d2
                lea.l   (Def_Sonar).l,a2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                clr.b   $34(a0)
                move.b  #$14,$32(a0)
                jmp     (jt_ObjInsert).w
Sonar_Up:
                cmpi.w  #$5,$26(a0)
                bcs.b   Sonar_Aim
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (Def_Sonar).l,a2
                movea.l a0,a4
                jsr     (jt_ObjCreate).w
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                jsr     (jt_ObjInsert).w
                movea.l a4,a0
                move.b  #$64,$34(a0)
                move.w  #$DC,$C(a0)
                bsr.b   RandomX
                move.w  d0,$A(a0)
                move.l  #Upd_Sonar,$6(a0)
                move.l  #$500,d0
                jmp     (jt_AddScore).w
RandomX:
                moveq   #100,d0
                jsr     (jt_Random).w
                add.w   #$64,d0
                rts
Sonar_Aim:
                tst.b   (BossDead).l
                beq.b   .4B72E
                jmp     (jt_ObjKillSelf).w
.4B72E:
                movem.w $A(a0),d0-d1
                movem.w (ShipPos).w,d2-d3
                jsr     (jt_DirectionTo).w
                move.w  d0,$1E(a0)
                subq.b  #$1,$32(a0)
                bne.b   .4B772
                lea.l   (SonarMuzzles).l,a3
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
.4B772:
                rts
Upd_Sonar:
                tst.b   $34(a0)
                beq.b   .4B780
                subq.b  #$1,$34(a0)
                rts
.4B780:
                subq.w  #$2,$C(a0)
                cmpi.w  #$AA,$C(a0)
                bhi.b   .4B798
                clr.w   $26(a0)
                move.l  #Sonar_Up,$6(a0)
.4B798:
                rts
PataPataData1:
                dc.w    $006E                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $0078                   ; y
                dc.b    $08,$00                 ; delay, frame
                dc.w    $007A                   ; y
                dc.b    $13,$00                 ; delay, frame
                dc.w    $FFFF
PataPataData2:
                dc.w    $0078
                dc.w    $0000,$006E,$1000,$007A,$2000,$006E,$3000,$0078
                dc.w    $4000,$FFFF,$006E,$0000,$0078,$3000,$FFFF
PataPataData3:
                dc.w    $005A                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $0064                   ; y
                dc.b    $10,$00                 ; delay, frame
                dc.w    $0064                   ; y
                dc.b    $32,$00                 ; delay, frame
                dc.w    $0064                   ; y
                dc.b    $42,$00                 ; delay, frame
                dc.w    $FFFF
PataPataData4:
                dc.w    $0064                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $005A                   ; y
                dc.b    $12,$00                 ; delay, frame
                dc.w    $0064                   ; y
                dc.b    $24,$00                 ; delay, frame
                dc.w    $0050                   ; y
                dc.b    $36,$00                 ; delay, frame
                dc.w    $FFFF
PataPataData5:
                dc.w    $005A                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $0064                   ; y
                dc.b    $0F,$00                 ; delay, frame
                dc.w    $0050                   ; y
                dc.b    $1E,$00                 ; delay, frame
                dc.w    $005A                   ; y
                dc.b    $2D,$00                 ; delay, frame
                dc.w    $0064                   ; y
                dc.b    $3C,$00                 ; delay, frame
                dc.w    $FFFF
BugData1:
                dc.w    $0043                   ; steps
                dc.l    $00070B4C,$00070B99,$00070BE6 ; dx, dy, frame tables (level B)
BugData2:
                dc.w    $0053                   ; steps
                dc.l    $00070C2D,$00070C84,$00070CDB ; dx, dy, frame tables (level B)
BugData3:
                dc.w    $011F                   ; steps
                dc.l    $00070D2F,$00070E4F,$00070F6F ; dx, dy, frame tables (level B)
BugData4:
                dc.w    $00D5                   ; steps
                dc.l    $00070D79,$00070E99,$00070FB9 ; dx, dy, frame tables (level B)
CancerData1:
                dc.w    $0170,$005A             ; x, y
                dc.w    $0170,$0046             ; x, y
                dc.w    $0012,$005A             ; x, y
                dc.w    $FFFF
CancerData2:
                dc.w    $0170,$0046             ; x, y
                dc.w    $FFFF
CancerData3:
                dc.w    $015E,$0082             ; x, y
                dc.w    $00B4,$0003             ; x, y
                dc.w    $FFFF
CancerData4:
                dc.w    $015E,$0078             ; x, y
                dc.w    $FFFF
CancerData5:
                dc.w    $0012,$0028             ; x, y
                dc.w    $0012,$0067             ; x, y
                dc.w    $0163,$0032             ; x, y
                dc.w    $0163,$005A             ; x, y
                dc.w    $FFFF
CancerData6:
                dc.w    $0012,$00B4             ; x, y
                dc.w    $0163,$00A6             ; x, y
                dc.w    $FFFF
CancerData7:
                dc.w    $0163,$0028             ; x, y
                dc.w    $0163,$00B4             ; x, y
                dc.w    $FFFF
; PataPata: as in level 1 (the same code)
; (32x19, 8 frames, gfx $5BCD6, 1 hit point, fires every ~45 frames, score 200, update Upd_PataPata, spawn Spawn_PataPata)
Def_PataPata:
                dc.w    $1303,$002E,$0260
                dc.w    $0001,$0001,$002D,$0005,$BCD6,$0000,$0130,$0004
                dc.w    $B8AC,$0004,$B8B6
                dc.l    Upd_PataPata
                dc.l    Spawn_PataPata
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0005
                dc.w    $0000,$000E,$0012,$0005,$0003,$000F,$000E,$0000
                dc.w    $0006,$0014,$0006,$0005,$0003,$000E,$000E,$0003
                dc.w    $0001,$0010,$0011,$0004,$0003,$000F,$000E,$0000
                dc.w    $0007,$0014,$0006,$0004,$0003,$000F,$000E
; Bug: as in level 1 (the same code)
; (32x21, 8 frames, gfx $5CFD6, 1 hit point, fires every ~95 frames, score 200, update Upd_Bug, spawn Spawn_Bug)
Def_Bug:
                dc.w    $1503
                dc.w    $002E,$02A0,$0002,$0001,$005F,$0005,$CFD6,$0000
                dc.w    $0150,$0004,$B91E,$0004,$B928
                dc.l    Upd_Bug
                dc.l    Spawn_Bug
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0003,$0011,$0011,$0002,$0002,$0011,$0012,$0001
                dc.w    $0002,$0011,$0011,$0002,$0001,$0011,$0011,$0002
                dc.w    $0001,$0011,$0012,$0003,$0001,$0010,$0011,$0002
                dc.w    $0002,$0012,$0011,$0003,$0002,$0011,$0012
; PStaff: as in level 1 (the same code)
; (32x26, 6 frames, gfx $60546, 6 hit points, score 500, update Upd_PStaff, spawn Spawn_PStaff)
Def_PStaff:
                dc.w    $1A03
                dc.w    $002E,$0340,$0002,$0006,$0000,$0006,$0546,$0000
                dc.w    $01A0,$0004,$B990,$0004,$B9AC
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
; PStaffMissile: as in level 1 (the same code)
; (16x13, 16 frames, gfx $63606, update Upd_PStaffMissile)
Def_PStaffMissile:
                dc.w    $0D02,$0030,$00D0,$0000,$0000,$0000,$0006,$3606
                dc.w    $0000,$0068,$0004,$BA4C,$0004,$BA60
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
; Scant: as in level 1 (the same code)
; (48x47, 3 frames, gfx $5E4D6, 30 hit points, score 500, update Upd_Scant, spawn Spawn_Scant)
Def_Scant:
                dc.w    $2F04,$002C
                dc.w    $08D0,$0000,$001E,$0000,$0005,$E4D6,$0000,$0468
                dc.w    $0004,$BB08,$0004,$BB0C
                dc.l    Upd_Scant
                dc.l    Spawn_Scant
                dc.w    $0000,$0500,$0001,$0203,$000F,$0003,$0016,$0024
                dc.w    $0007,$0001,$001B,$0027,$0011,$0002,$001A,$002B
; ScantBeam: as in level 1 (the same code)
; (48x16, 2 frames, gfx $5FF46)
Def_ScantBeam:
                dc.w    $1004,$002C,$0300,$0000,$0000,$0000,$0005,$FF46
                dc.w    $0000,$0180,$0004,$BB4C,$0004,$BB50,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
ScantBeamAnim:
                dc.w    $0001,$FF00,$0002,$0004,$002B,$0009,$0001,$0002
                dc.w    $002C,$000C
; Bink: as in level 1 (the same code)
; (32x26, 4 frames, gfx $64306, 1 hit point, fires every ~30 frames, score 200, update Upd_Bink, spawn Spawn_Bink)
Def_Bink:
                dc.w    $1A03,$002E,$0340,$0003,$0001,$001E
                dc.w    $0006,$4306,$0000,$01A0,$0004,$BB88,$0004,$BB9C
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
                dc.w    $027F,$7F00
; Cancer: as in level 1 (the same code)
; (32x26, 6 frames, gfx $66A06, 1 hit point, fires every ~40 frames, score 300, update Upd_Cancer, spawn Spawn_Cancer)
Def_Cancer:
                dc.w    $1A03,$002E,$0340,$0005,$0001,$0028
                dc.w    $0006,$6A06,$0000,$01A0,$0004,$BC38,$0004,$BC40
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
; object definition: 48x48, 4 frames, gfx $69BA6, update Upd_Bronco
Def_Bronco:
                dc.w    $3004,$002C,$0900,$0003,$0000,$0000,$0006,$9BA6
                dc.w    $0000,$0480,$0004,$BCB8,$0004,$BC98
                dc.l    Upd_Bronco
                dc.w    $0000,$0000,$0000,$0000,$0016,$0001,$001A,$002E
                dc.w    $0016,$0001,$001A,$002E,$0016,$0001,$001A,$002E
                dc.w    $0016,$0001,$001A,$002E,$0001,$0203,$0303,$0303
                dc.b    $02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$FF
ChutesReady:
                dc.b    $00
ChuteTimer:
                dc.b    $00
BossDead:
                dc.b    $00
; DropList: what the chutes drop - definition, frame (as a long).
DropList:
                dc.l    Def_Junk,0              ; junk, frame 0
                dc.l    Def_Junk,1
                dc.l    Def_Junk,2
                dc.l    Def_Junk,3
                dc.l    Def_Bug,0               ; or a Bug
; object definition: 32x31, 4 frames, gfx $68026, score 100, update Upd_Falling
Def_Junk:
                dc.w    $1F03,$002E,$03E0,$0000
                dc.w    $0000,$0000,$0006,$8026,$0000,$01F0,$0004,$BD1E
                dc.w    $0004,$BD24
                dc.l    Upd_Falling
                dc.w    $0000,$0000,$0000,$0100,$0001,$0203,$FF00,$0002
                dc.w    $0002,$0015,$001B,$0004,$0002,$0019,$001C,$0002
                dc.w    $0002,$0017,$001B,$0002,$0001,$001B,$001B
Chutes:
                dc.w    $0000,$00FA,$0005,$7420,$0004,$BD80,$0000,$00CB
                dc.w    $0005,$741A,$0004,$BD80,$0000,$009B,$0005,$7414
                dc.w    $0004,$BD80,$0000,$0069,$0005,$740E,$0004,$BD80
                dc.w    $0000,$0037,$0005,$7408,$0004,$BD80
ChuteBuild:
                dc.w    $0004,$BD94,$0004,$BDA8,$0004,$BDBC,$0004,$BDD0
                dc.w    $FFFF,$FFFF
ChuteBase:
                dc.w    $0202,$80F0,$80F1,$80F2,$8104,$8105,$8106,$0000
                dc.w    $0000,$0000,$0202,$80F3,$80F4,$80F5,$8107,$8108
                dc.w    $8109,$011B,$011C,$011D,$0202,$80F6,$80F7,$80F8
                dc.w    $810A,$810B,$810C,$011E,$011F,$0120,$0202,$80F9
                dc.w    $80FA,$80FB,$810D,$810E,$810F,$0121,$0122,$0123
CollapseCells:
                dc.w    $0004,$BEA8,$0004,$BEB8,$0004,$BEDA,$0004,$BF4E
                dc.w    $0004,$BF14,$0004,$BF88,$0004,$BEA0,$0004,$BEB0
                dc.w    $0004,$BEC0,$0004,$BF34,$0004,$BEF4,$0004,$BF68
; object definition: 48x51, 9 frames, gfx $0B440, indestructible, update Upd_Collapse, spawn Spawn_Collapse
Def_Collapse:
                dc.w    $3304,$002C,$0990,$0000,$FFFF,$0000,$0000,$B440
                dc.w    $0000,$04C8,$0004,$BE3C,$0004,$BE58
                dc.l    Upd_Collapse
                dc.l    Spawn_Collapse
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
; object definition: 32x21, 1 frame, gfx $67D86, score 300, update Upd_Crawler, spawn Spawn_Crawler
Def_Crawler:
                dc.w    $1503,$002E,$02A0,$0000,$0000,$0000,$0006,$7D86
                dc.w    $0000,$0150,$0004,$BFD0,$0004,$BFD2
                dc.l    Upd_Crawler
                dc.l    Spawn_Crawler
                dc.w    $0000,$0300,$00FF,$0002,$0002,$0014,$0011
; object definition: 96x32, 1 frame, gfx $68FA6, score 1500, update Upd_Bold, spawn Spawn_Bold
Def_Bold:
                dc.w    $2007,$0026,$0C00,$0000,$0000,$0000,$0006,$8FA6
                dc.w    $0000,$0600,$0004,$BFD0,$0004,$C002
                dc.l    Upd_Bold
                dc.l    Spawn_Bold
                dc.w    $0000,$1500,$0002,$0002,$005B,$001C
; CheetahBeam: as in level 5 (the same code)
; (32x3, 4 frames, gfx $6F486, update Upd_CheetahBeam)
Def_CheetahBeam:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0006,$F486
                dc.w    $0000,$0030,$0004,$C052,$0004,$C032
                dc.l    Upd_CheetahBeam
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0001,$0203,$FF00
; MidCheetah: level 5's mid-phase Cheetah, in pairs 24 frames apart, with
; its own simpler code: 3 pixels a frame left, a beam every 50 frames.
; (32x20, 8 frames, gfx $6F606, score 400, update Upd_MidCheetah, spawn Spawn_MidCheetah)
Def_MidCheetah:
                dc.w    $1403
                dc.w    $002E,$0280,$0002,$0000,$0000,$0006,$F606,$0000
                dc.w    $0140,$0004,$C0A0,$0004,$C0AA
                dc.l    Upd_MidCheetah
                dc.l    Spawn_MidCheetah
                dc.w    $0000,$0400,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0002,$0002,$001D,$0025,$0002,$0002
                dc.w    $001D,$0025,$0001,$0203,$0405,$0607,$FF00,$0001
                dc.w    $0003,$0017,$000F,$0003,$0003,$0015,$000C,$0001
                dc.w    $0002,$0018,$000B,$0001,$0002,$0019,$000D,$0002
                dc.w    $0002,$0017,$0010,$0001,$0005,$0018,$000D,$0001
                dc.w    $0006,$000E,$000C,$0001,$0005,$0018,$000D
; object definition: 32x47, 9 frames, gfx $6BFA6, score 100, update Upd_Sonar
Def_Sonar:
                dc.w    $2F03,$002E,$05E0,$0000,$0000,$0000,$0006,$BFA6
                dc.w    $0000,$02F0,$0004,$C112,$0004,$C124
                dc.l    Upd_Sonar
                dc.w    $0000,$0000,$0000,$0100,$0001,$0203,$0404,$0404
                dc.w    $0405,$0505,$0506,$0708,$FF00,$0009,$0001,$000F
                dc.w    $002D,$0007,$0002,$0010,$002B,$0009,$0004,$000F
                dc.w    $002A,$0009,$0006,$000F,$0027,$0008,$0006,$000F
                dc.w    $0028,$0008,$0005,$000F,$002A,$0009,$0007,$000E
                dc.w    $0027,$0009,$0004,$000E,$002A,$0009,$0002,$000F
                dc.w    $002B
SonarMuzzles:
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
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
