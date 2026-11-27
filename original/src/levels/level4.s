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
; Stage 4, the cell factory.  Enemies: level 1's Pata-Pata,
; Bug, P-Staff, Bink and Cancer (the same code), Cytron, Geld, the POW
; Armor; the boss is the Compiler, three sections (5000 points each).
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
                dc.l    $4D300                  ; tiles: the start of level B
                dc.l    ScrollScript
                dc.l    $0
                dc.l    $0
                dc.l    LevelFrame
                dc.l    LevelInit
                dc.l    $52078                  ; LvMusic: player in level B; samples $604F8 (9), data $60594, periods $60540
ScrollScript:
                dc.w    $000B,$0000,$0064,$0000,$0000,$FFFF
; Checkpoint list (LV_Waves): scroll x reached, where to resume in the
; wave list.  Highest first; the 0 entry is the level start.
WaveList:
                dc.w    $04A1
                dc.l    WavesFrom_04A1
                dc.w    $0000
                dc.l    Waves
; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes
; for the spawn routine, definition (-1 = POW Armor, the default).
; The parameters of each object: docs/DATA_FORMATS.md, Wave parameters.
Waves:
                dc.w    $0066,$0170,$007D
                dc.l    $00000000,CytronData1,Def_Cytron
                dc.w    $0076,$0170,$007A
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $00C8,$0170,$0096
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $00DE,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $0115,$0170,$002B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0127,$0000,$0000
                dc.l    $03E8000E,CancerData1,Def_Cancer
                dc.w    $0128,$0000,$0000
                dc.l    PataPataData1,$00000000,Def_PataPata
                dc.w    $015E,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $015F,$0000,$0000
                dc.l    PataPataData2,$00000000,Def_PataPata
                dc.w    $018B,$0000,$0000
                dc.l    PataPataData3,$00000000,Def_PataPata
                dc.w    $0192,$000A,$002B
                dc.l    $00060000,$00000000,Def_Cytron
                dc.w    $01A2,$00B6,$000A
                dc.l    $FFFF0006,$00000000,Def_Cytron
                dc.w    $01B8,$0170,$0032
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $01E3,$0000,$0000
                dc.l    PataPataData4,$00000000,Def_PataPata
                dc.w    $01EF,$0118,$0004
                dc.l    $00010000,CytronData2,Def_Cytron
                dc.w    $01F4,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $020A,$0170,$007B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0210,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $023A,$0170,$0028
                dc.l    $0001FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0260,$00CD,$0002
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $0271,$0069,$000A
                dc.l    $FFFF0006,$00000000,Def_Cytron
                dc.w    $0284,$00BA,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $029E,$0000,$0000
                dc.l    $FFFF000A,CancerData2,Def_Cancer
                dc.w    $02BA,$011A,$000B
                dc.l    BugData1,$0008FFFF,Def_Bug 
                dc.w    $0338,$00D0,$00DF
                dc.l    $FFFFFFFA,$00000000,Def_Cytron
                dc.w    $033E,$0170,$003A
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $034A,$00D0,$0005
                dc.l    $FFFF0006,$00000000,Def_Cytron
                dc.w    $034E,$0005,$002B
                dc.l    $00060000,$00000000,Def_Cytron
                dc.w    $035B,$0000,$0000
                dc.l    $FFFF000A,CancerData2,Def_Cancer
                dc.w    $0375,$0170,$007B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0376,$0064,$0005
                dc.l    $0002FFFF,$00000000,Def_Geld
                dc.w    $0384,$0000,$0000
                dc.l    $FFFF000A,CancerData3,Def_Cancer
                dc.w    $0396,$0005,$009B
                dc.l    $00060000,$00000000,Def_Cytron
                dc.w    $03C6,$0064,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $03CA,$0170,$006B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $03DE,$0064,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $03EC,$0064,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $03ED,$009B,$0002
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $03FA,$0170,$007B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0407,$0170,$0032
                dc.l    $0005FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0427,$0170,$00AA
                dc.l    $0004FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $042E,$0118,$0005
                dc.l    $0002FFFF,$00000000,Def_Geld
                dc.w    $0432,$0170,$003B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $045C,$00BE,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $045D,$000A,$002B
                dc.l    $00060000,$00000000,Def_Cytron
                dc.w    $0465,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $047C,$0170,$00B6
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $047D,$002D,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $047E,$006E,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $0482,$0011,$00B6
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $0483,$0014,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $0486,$0170,$00B6
                dc.l    $00090007,$00000000,Def_PStaff
                dc.w    $048B,$012C,$0005
                dc.l    $00010000,CytronData3,Def_Cytron
                dc.w    $048C,$0005,$0090
                dc.l    $00010000,CytronData4,Def_Cytron
WavesFrom_04A1:
                dc.w    $04DD,$0000,$0000
                dc.l    $FFFF000A,CancerData4,Def_Cancer
                dc.w    $04E0,$00CA,$0005
                dc.l    $FFFF0006,$00000000,Def_Cytron
                dc.w    $04ED,$006A,$0005
                dc.l    $FFFF0006,$00000000,Def_Cytron
                dc.w    $0543,$00C6,$00DF
                dc.l    $FFFFFFFA,$00000000,Def_Cytron
                dc.w    $0554,$0170,$002D
                dc.l    $0002FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0556,$0131,$00DF
                dc.l    $FFFFFFFA,$00000000,Def_Cytron
                dc.w    $0558,$0120,$00DF
                dc.l    $0000FFFF,$00000000,Def_Geld
                dc.w    $055F,$0170,$003B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0561,$0170,$006B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0578,$0170,$009B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $059B,$0118,$0002
                dc.l    $FFFE0000,$00000000,Def_Bink
                dc.w    $05AC,$00A0,$0002
                dc.l    $00020000,$00000000,Def_Bink
                dc.w    $05BA,$0170,$0073
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $05BB,$0000,$0000
                dc.l    $FFFF0006,CancerData5,Def_Cancer
                dc.w    $05D1,$0068,$00DF
                dc.l    $00010000,CytronData5,Def_Cytron
                dc.w    $0614,$0005,$0080
                dc.l    $00000000,CytronData4,Def_Cytron
                dc.w    $062C,$0108,$0004
                dc.l    $00000000,CytronData2,Def_Cytron
                dc.w    $066B,$0170,$006D
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0670,$0170,$004A
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $0673,$0170,$009C
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $067A,$0170,$007B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $067B,$0010,$007B
                dc.l    $00060000,$00000000,Def_Cytron
                dc.w    $0684,$0170,$002B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $06BE,$0170,$0098
                dc.l    $0001FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $0740,$0000,$0000
                dc.l    $FFFF0005,CancerData6,Def_Cancer
                dc.w    $076F,$00BA,$0005
                dc.l    $0002FFFF,$00000000,Def_Geld
                dc.w    $07D0,$0170,$0060
                dc.l    $0003FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $07D1,$0170,$00B0
                dc.l    $0000FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $07D2,$0110,$00DF
                dc.l    $0000FFFF,$00000000,Def_Geld
                dc.w    $07D3,$0170,$0021
                dc.l    $0005FFFC,$00000000,$FFFFFFFF ; POW Armor
                dc.w    $07E4,$0098,$00DF
                dc.l    $0000FFFF,$00000000,Def_Geld
                dc.w    $07E5,$0011,$0060
                dc.l    $0001FFFF,$00000000,Def_Geld
                dc.w    $07E6,$0011,$008D
                dc.l    $0001FFFF,$00000000,Def_Geld
                dc.w    $07E7,$0011,$00B0
                dc.l    $0001FFFF,$00000000,Def_Geld
                dc.w    $07E9,$0011,$0032
                dc.l    $0001FFFF,$00000000,Def_Geld
                dc.w    $0828,$0011,$0060
                dc.l    $0001FFFF,$00000000,Def_Geld
                dc.w    $082A,$0098,$0005
                dc.l    $0002FFFF,$00000000,Def_Geld
                dc.w    $082B,$011C,$0005
                dc.l    $0002FFFF,$00000000,Def_Geld
                dc.w    $0852,$0000,$0000
                dc.l    $FFFF001E,CancerData7,Def_Cancer
                dc.w    $08DC,$0170,$003C
                dc.l    $00000000,CytronData6,Def_Cytron
                dc.w    $0911,$0170,$004B
                dc.l    $FFFA0000,$00000000,Def_Cytron
                dc.w    $091B,$0010,$004B
                dc.l    $00000000,CytronData7,Def_Cytron
                dc.w    $7530   ; end: never reached
LevelPalette:
                dc.w    $0555,$0BBB,$0777,$0500,$005F,$00F0,$0050,$0955
                dc.w    $0B00,$09BF,$000B,$0F77,$0B70,$0FF0,$0FFF
Spawn_PataPata:
                movea.l $6(a1),a3               ; the group list
.4AA28:
                move.w  (a3)+,d1                ; y ($FFFF ends)
                bmi.b   .4AA48
                move.w  #$170,d0                ; enter at the right edge
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                move.b  (a3)+,$32(a0)           ; delay before it starts
                move.b  (a3)+,$1F(a0)           ; first animation frame
                clr.w   $34(a0)                 ; position in the wave table
                jsr     (jt_ObjInsert).w
                bra.b   .4AA28
.4AA48:
                rts
Upd_PataPata:
                tst.b   $32(a0)                 ; still waiting?
                beq.b   .4AA56
                subq.b  #$1,$32(a0)
                rts
.4AA56:
                lea.l   ($6C818).l,a1           ; wave: 35 signed y steps (level B)
                move.w  $34(a0),d0
                move.b  (a1,d0.w),d1
                ext.w   d1
                add.w   d1,$C(a0)               ; bob up and down
                addq.w  #$1,d0
                cmp.w   #$23,d0
                bcs.b   .4AA74
                clr.w   d0
.4AA74:
                move.w  d0,$34(a0)
                subq.w  #$4,$A(a0)              ; 4 pixels left a frame
                cmpi.w  #$20,$A(a0)             ; gone off the left edge?
                bhi.b   .4AA88
                jmp     (jt_ObjKillSelf).w
.4AA88:
                rts
Spawn_Bug:
                move.w  $A(a1),d7               ; number of Bugs - 1
                clr.w   d6
.4AA90:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                moveq   #1,d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                move.l  $6(a1),$32(a0)          ; the path
                clr.w   $36(a0)
                move.w  $C(a1),$3A(a0)          ; extra x speed
                move.b  d6,$38(a0)              ; start delay: 7 frames apart
                jsr     (jt_ObjInsert).w
                addq.b  #$7,d6
                dbra    d7,.4AA90
                rts
Upd_Bug:
                move.w  $3A(a0),d0              ; drift with its own x speed
                add.w   d0,$A(a0)
                tst.b   $38(a0)                 ; still waiting?
                beq.b   .4AAD6
                subq.b  #$1,$38(a0)
                rts
.4AAD6:
                movea.l $32(a0),a1              ; path: steps, dx, dy, frame tables
                move.w  $36(a0),d0              ; step number
                move.w  (a1)+,d1
                bsr.b   .4AB08
                add.w   d2,$A(a0)               ; x += dx[step]
                bsr.b   .4AB08
                add.w   d2,$C(a0)               ; y += dy[step]
                bsr.b   .4AB08
                move.b  d2,$1F(a0)              ; frame = frame[step]
                cmp.w   d1,d0                   ; at the end it keeps the last step
                bcc.b   .4AAFA
                addq.w  #$1,$36(a0)
.4AAFA:
                cmpi.w  #$10,$A(a0)
                bhi.b   .4AB06
                jmp     (jt_ObjKillSelf).w
.4AB06:
                rts
.4AB08:
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
                bhi.b   .4AB48
                jmp     (jt_ObjKillSelf).w      ; yes: remove
.4AB48:
                tst.b   $36(a0)                 ; state 0: walking
                beq.b   .4AB66
                cmpi.b  #$1,$36(a0)
                beq.b   .4AB94                  ; state 1: firing a volley
                subq.w  #$1,$A(a0)              ; state 2, paused: scroll with the map
                subq.b  #$1,$37(a0)             ; count down the pause
                bpl.b   .4ABCA
                bsr.w   PStaff_TryFire          ; then fire if the ship is in range, otherwise walk
                rts
.4AB66:
                bsr.w   PStaff_Approach         ; head for 60-79 pixels from the ship
                movem.w $A(a0),d0-d1            ; probe the map ahead at foot level
                add.w   #$B,d1
                tst.w   $32(a0)
                bpl.b   .4AB80                  ; walking right?
                sub.w   #$10,d0                 ; left: probe 16 pixels ahead
                bra.b   .4AB84
.4AB80:
                add.w   #$21,d0                 ; right: probe just past the body
.4AB84:
                jsr     (jt_GetMapCell).w       ; wall ahead?
                bne.b   PStaff_Halt             ; yes: stop
                move.w  $32(a0),d0
                add.w   d0,$A(a0)               ; take a step
                rts
.4AB94:
                subq.w  #$1,$A(a0)              ; state 1: scroll with the map
                subq.w  #$1,$34(a0)             ; frames to the next shot
                bmi.b   .4ABA0
                rts
.4ABA0:
                move.w  #$A,$34(a0)             ; 10 frames between shots
                subq.b  #$1,$37(a0)             ; shots left in the volley
                bpl.b   .4ABCC                  ; more: fire one
                bsr.w   PStaff_Approach         ; volley done: face the ship again
                move.l  #PStaffFireAnimEnd,d0   ; animation index = end of the fire animation
                sub.l   $2A(a0),d0
                move.w  d0,$1E(a0)
                move.b  #$2,$36(a0)             ; then pause (state 2)
                move.b  #$A,$37(a0)             ; for 10 frames
.4ABCA:
                rts
.4ABCC:
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
                bpl.b   .4AC42                  ; ship to the right: d2 = 1
                neg.w   d0                      ; ship to the left: d0 = |dx|, d2 = -1
                neg.w   d2
                add.w   #$1E,d0                 ; and allow 30 pixels for the ship's width
.4AC42:
                rts
ShipDistY:
                moveq   #1,d2
                move.w  ($F0).w,d0              ; ship y
                sub.w   #$1F,d0                 ; to its top edge
                sub.w   $C(a0),d0               ; minus our y
                bpl.b   .4AC58
                neg.w   d0
                neg.w   d2
.4AC58:
                rts
PStaff_Approach:
                bsr.b   ShipDistX
                cmp.w   #$3C,d0                 ; 60-79 pixels away:
                blt.b   .4AC6A
                cmp.w   #$50,d0
                bcs.w   PStaff_Halt             ; stop here
.4AC6A:
                clr.b   $36(a0)                 ; otherwise walk (state 0)
                moveq   #70,d1                  ; 70 - distance
                sub.w   d0,d1
                bpl.b   .4AC86                  ; closer than 70: walk away
                move.w  #$FFFE,$32(a0)          ; further: walk towards the ship
                tst.w   d2
                bmi.b   .4AC84
                move.w  #$2,$32(a0)
.4AC84:
                bra.b   .4AC96
.4AC86:
                move.w  #$2,$32(a0)             ; walk away from the ship
                tst.w   d2
                bmi.b   .4AC96
                move.w  #$FFFE,$32(a0)
.4AC96:
                move.b  #$0,$36(a0)
                lea.l   (PStaffWalkLeft).l,a1   ; walking animation for the direction
                tst.w   $32(a0)
                bmi.b   .4ACAE
                lea.l   (PStaffWalkRight).l,a1
.4ACAE:
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
                bpl.b   .4ACEA
                clr.w   d1                      ; not below 0
.4ACEA:
                move.w  d1,$32(a0)              ; y index into the up-speed table
                bsr.w   ShipDistX               ; x table start = 19 + random(10) - dx/8,
                lsr.w   #$3,d0
                moveq   #19,d1
                move.w  d0,-(a7)
                moveq   #10,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                sub.w   (a7)+,d1
                bpl.b   .4AD06
                clr.w   d1                      ; not below 0
.4AD06:
                move.w  d1,$34(a0)              ; x index into the side-speed table
                move.w  $3C(a4),$36(a0)         ; direction: towards the ship
                clr.b   $22(a0)                 ; frame is set by the update routine
                move.b  #$1,$21(a0)
                jsr     (jt_ObjInsert).w        ; link it in
                movea.l a4,a0                   ; back to the P-Staff
                rts
Upd_PStaffMissile:
                lea.l   ($6C899).l,a3           ; up speeds, by y index ($7F ends)
                lea.l   ($6C83B).l,a1           ; side speeds, by x index ($7F ends)
                lea.l   ($6C8F7).l,a2           ; frame per y index (the arc's angle)
                movem.w $32(a0),d0-d2           ; d0 y index, d1 x index, d2 direction
                move.b  (a3,d0.w),d3
                cmp.b   #$7F,d3                 ; end of the arc:
                beq.b   .4ADB6                  ; explode
                neg.b   d3                      ; table is upward speed
                move.b  (a1,d1.w),d4
                bne.b   .4AD4E                  ; side speed is at least 1
                addq.b  #$1,d4
.4AD4E:
                cmp.b   #$7F,d4
                beq.b   .4ADB6
                addq.w  #$1,$32(a0)             ; step along both tables
                addq.w  #$1,$34(a0)
                ext.w   d3
                ext.w   d4
                asl.w   #$1,d4                  ; side speed doubled
                tst.w   d2
                bpl.b   .4AD68
                neg.w   d4                      ; fired to the left
.4AD68:
                add.w   d3,$C(a0)               ; move
                add.w   d4,$A(a0)
                cmpi.w  #$20,$A(a0)             ; off the left edge,
                bcs.b   .4AD90
                cmpi.w  #$170,$A(a0)            ; or right of x $170,
                bhi.b   .4AD94
                cmpi.w  #$E0,$C(a0)             ; or off the bottom or top:
                bhi.b   .4AD90
                cmpi.w  #$10,$C(a0)
                bhi.b   .4AD94
.4AD90:
                jmp     (jt_ObjKillSelf).w      ; remove
.4AD94:
                move.b  (a2,d0.w),d3            ; frame for this point of the arc
                ext.w   d3
                tst.w   d2
                bpl.b   .4ADA2
                add.w   #$9,d3                  ; left-facing frames start at 9
.4ADA2:
                move.w  d3,$1E(a0)
                movem.w $A(a0),d0-d1            ; centre of the missile
                addq.w  #$8,d0
                addq.w  #$6,d1
                jsr     (jt_GetMapCell).w       ; hit the map?
                beq.b   .4ADC0                  ; no: carry on
.4ADB6:
                move.b  #$1,$5(a0)              ; yes: explode
                clr.l   $6(a0)                  ; and stop updating
.4ADC0:
                rts
Spawn_Bink:
                move.w  $2(a1),d0               ; x, y from the wave entry
                move.w  $4(a1),d1
                move.w  $8(a2),d2               ; hit points from the definition
                jsr     (jt_ObjCreate).w
                move.l  #BinkWalkRight,$2A(a0)  ; walking right,
                move.w  $6(a1),$32(a0)          ; step (entry $06)
                bpl.b   .4ADEA
                move.l  #BinkWalkLeft,$2A(a0)   ; negative: walking left
.4ADEA:
                move.w  $32(a0),d2
                bsr.w   Bink_Jump               ; start with a jump
                move.w  #$200,$34(a0)           ; then state 2 (falling), byte $35 = 0
                clr.w   $1E(a0)                 ; first walking frame
                bsr.w   Bink_Fall               ; drop to the ground
                jmp     (jt_ObjInsert).w
Upd_Bink:
                cmpi.w  #$10,$A(a0)             ; off the screen: remove
                bcs.b   .4AE1C
                cmpi.w  #$170,$A(a0)
                bhi.b   .4AE1C
                cmpi.w  #$E0,$C(a0)
                bcs.b   .4AE20
.4AE1C:
                jmp     (jt_ObjKillSelf).w
.4AE20:
                move.b  $34(a0),d0              ; state: 0 walk, 1 jump, 2 fall, -1 stopped
                beq.b   .4AE6C
                cmp.b   #$1,d0
                beq.w   Bink_Jumping
                cmp.b   #$2,d0
                beq.w   Bink_Fall
                subq.w  #$1,$A(a0)              ; stopped: scrolls with the map
                subq.b  #$1,$35(a0)             ; every 10 frames
                bmi.b   .4AE52
                rts
.4AE42:
                st.b    $34(a0)                 ; blocked: stop (state -1)
                clr.b   $22(a0)                 ; hold the animation
                move.l  #BinkWalkLeft,$2A(a0)
.4AE52:
                move.b  #$A,$35(a0)             ; turn to face the ship every 10 frames
                bsr.w   ShipDistX               ; face the ship
                move.w  #$B,$1E(a0)             ; frame 11: facing right
                tst.w   d2
                bpl.b   .4AE6A
                clr.w   $1E(a0)
.4AE6A:
                rts
.4AE6C:
                move.w  $32(a0),d2              ; walking: step and direction
                movem.w $A(a0),d0-d1            ; probe at foot height
                add.w   #$C,d1
                subq.w  #$3,d0                  ; 3 pixels behind the left edge
                tst.w   d2
                bmi.b   .4AE84                  ; walking left?
                add.w   #$23,d0                 ; right: just past the body
.4AE84:
                jsr     (jt_GetMapCell).w       ; walking: a tile ahead?
                bne.b   .4AE42
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
                bpl.b   .4AEBE
                move.l  #BinkJumpLeft,$2A(a0)
.4AEBE:
                move.w  #$3,$1E(a0)             ; animate from frame 3
                clr.b   $20(a0)
                st.b    $22(a0)
                rts
Bink_Jumping:
                lea.l   (BinkJumpArc).l,a2      ; signed y steps, $7F ends
                move.w  $36(a0),d0
                moveq   #2,d2                   ; 2 pixels a frame right in this copy
                move.b  (a2,d0.w),d3
                cmp.b   #$7F,d3                 ; end of the arc?
                bne.b   .4AEEC
                move.b  #$2,$34(a0)             ; yes: fall (state 2)
                bra.b   Bink_Fall
.4AEEC:
                ext.w   d3
                tst.w   $32(a0)                 ; walking left?
                bpl.b   .4AEF6
                moveq   #-3,d2                  ; and 3 to the left
.4AEF6:
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
                bne.b   .4AF20
                addq.w  #$4,$C(a0)              ; no: fall 4 pixels a frame
                rts
.4AF20:
                clr.w   $34(a0)                 ; landed: walk (state 0)
                move.l  #BinkWalkRight,$2A(a0)  ; walking animation for the direction
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.w   $32(a0)
                bpl.b   .4AF42
                move.l  #BinkWalkLeft,$2A(a0)
.4AF42:
                rts
Spawn_Cancer:
                movea.l $A(a1),a3               ; list of x, y
                move.w  $8(a1),d7               ; frames between them
                clr.w   d6
.4AF4E:
                move.w  (a3)+,d0
                bmi.b   .4AF72
                move.w  (a3)+,d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                move.w  $6(a1),$3A(a0)          ; scroll x at which it gives up
                clr.w   $38(a0)
                move.w  d6,$32(a0)              ; start delay
                add.w   d7,d6
                jsr     (jt_ObjInsert).w
                bra.b   .4AF4E
.4AF72:
                rts
Upd_Cancer:
                tst.w   $32(a0)                 ; waiting to start?
                beq.b   .4AF80
                subq.w  #$1,$32(a0)
                rts
.4AF80:
                subq.w  #$1,$A(a0)              ; scrolls with the map
                movem.w $A(a0),d0-d1
                cmp.w   #$10,d0
                bcs.b   .4AFA2
                cmp.w   #$170,d0
                bhi.b   .4AFA2
                cmp.w   #$2,d1                  ; top limit 2 here (16 in level 1)
                bcs.b   .4AFA2
                cmp.w   #$E0,d1
                bcs.b   .4AFA6
.4AFA2:
                jmp     (jt_ObjKillSelf).w
.4AFA6:
                move.w  $3A(a0),d4
                cmp.w   (ScrollX).w,d4          ; past its scroll x:
                bhi.b   .4AFC0
                moveq   #10,d7                  ; make for the nearer edge
                cmp.w   #$88,d1
                bcs.b   .4AFBC
                move.w  #$E0,d7
.4AFBC:
                moveq   #4,d6
                bra.b   .4AFCC
.4AFC0:
                subq.w  #$1,$38(a0)             ; time for a new heading?
                bpl.b   .4B00A
                movem.w (ShipPos).w,d6-d7       ; target: the ship
.4AFCC:
                moveq   #2,d4
                lea.l   (CancerAnimRight).l,a1  ; x step +2 / -1, facing it
                cmp.w   d6,d0
                bcs.b   .4AFE0
                moveq   #-1,d4
                lea.l   (CancerAnimLeft).l,a1
.4AFE0:
                move.l  a1,$2A(a0)
                moveq   #1,d5                   ; y step +1 / -1
                cmp.w   d7,d1
                bcs.b   .4AFEC
                neg.w   d5
.4AFEC:
                move.w  d0,d2
                sub.w   d6,d2
                bpl.b   .4AFF4
                neg.w   d2
.4AFF4:
                lsr.w   #$2,d2                  ; hold it for |dx|/4 + random 25 frames
                moveq   #25,d0
                jsr     (jt_Random).w
                add.w   d0,d2
                move.w  d2,$38(a0)
                move.b  d4,$36(a0)
                move.b  d5,$37(a0)
.4B00A:
                movem.w $A(a0),d0-d1
                movem.l d0-d1,-(a7)
                move.b  $37(a0),d6
                ext.w   d6
                bpl.b   .4B020
                subq.w  #$2,d1
                bra.b   .4B024
.4B020:
                add.w   #$20,d1
.4B024:
                addq.w  #$8,d0
                jsr     (jt_GetMapCell).w       ; blocked vertically?
                bne.b   .4B030
                add.w   d6,$C(a0)               ; no: move up/down
.4B030:
                movem.l (a7)+,d0-d1
                addq.w  #$8,d1
                move.b  $36(a0),d4
                ext.w   d4
                bpl.b   .4B042
                subq.w  #$2,d0
                bra.b   .4B046
.4B042:
                add.w   #$22,d0
.4B046:
                jsr     (jt_GetMapCell).w       ; blocked horizontally?
                bne.b   .4B050
                add.w   d4,$A(a0)               ; no: move left/right
.4B050:
                rts
; The level 4 map is stored at $50F00 (level B) and copied to $6EA6A, the
; address in LvMap, at every (re)start: the level code changes the map while
; it plays, so a clean copy is needed for restarts.
; LevelInit: copies $1178 bytes of map from $50F00 to $6EA6A (the part of
; level B the map is read from) and sets three Compiler sections to go.
LevelInit:
                move.w  #$8BB,d0
                lea.l   ($50F00).l,a0
                lea.l   ($6EA6A).l,a1
.4B062:
                move.w  (a0)+,(a1)+
                dbra    d0,.4B062
                clr.b   (BossStarted).l
                move.b  #$3,(SectionsLeft).l
InitRts:
                rts
; LevelFrame: at scroll x $970 the scroll stops, three palette colours are
; set, and the Compiler (the boss) is built: three sections
; (CompilerSections: definition, x, y, priority), each with an invisible
; core target and a gun turret.  The level ends when SectionsLeft is 0.
LevelFrame:
                cmpi.w  #$970,(ScrollX).w
                bcs.b   InitRts
                tst.b   (BossStarted).l
                bne.w   .4B186
                clr.b   (ScrollActive).w
                movea.l (PalettePtr).w,a4
                move.w  #$F99,$1E(a4)
                move.w  #$3,$2A(a4)
                move.w  #$F55,$2E(a4)
                lea.l   (CompilerSections).l,a4
                lea.l   (CompilerGunParents).l,a1
                moveq   #2,d7
                moveq   #0,d6
                move.l  #$6CFB2,d5
.4B0BA:
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
                st.b    (CompilerEntering).l
                jsr     (jt_ObjInsert).w
                moveq   #1,d0
                moveq   #1,d1
                moveq   #-1,d2
                lea.l   (Def_CompilerCore).l,a2
                jsr     (jt_ObjCreate).w
                move.w  #$11,$3C(a0)
                move.b  #$A,$4(a0)
                move.l  a3,$32(a0)
                clr.b   $22(a0)
                move.w  d6,$1E(a0)
                clr.w   $36(a0)
                jsr     (jt_ObjInsert).w
                tst.w   d6
                bne.b   .4B126
                move.l  a3,(a1)+
.4B126:
                move.l  a3,(a1)+
                addq.w  #$1,d6
                add.l   #$8E8,d5
                dbra    d7,.4B0BA
                moveq   #2,d7
                moveq   #0,d6
                lea.l   (CompilerGunParents).l,a1
.4B13E:
                moveq   #1,d0
                moveq   #1,d1
                moveq   #-1,d2
                lea.l   (Def_CompilerGun).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$B,$4(a0)
                move.l  (a1)+,$32(a0)
                clr.b   $22(a0)
                clr.w   $1E(a0)
                clr.w   $38(a0)
                move.w  d6,$36(a0)
                beq.b   .4B170
                bset.b  #$2,$23(a0)
.4B170:
                jsr     (jt_ObjInsert).w
                addq.w  #$4,d6
                dbra    d7,.4B13E
                st.b    (BossStarted).l
                st.b    (MusicFadeReq).w
                rts
.4B186:
                tst.b   (SectionsLeft).l
                bne.b   .4B192
                st.b    (LevelComplete).w
.4B192:
                rts
; Upd_CompilerSection: the sections fly in from the left (3 pixels a
; frame) to their start, then each follows its own path ($6CFB2 + n *
; $8E8: $474 x bytes, then $474 y bytes) round the screen.  Section 2 also
; fires CompilerLasers forwards when the ship is level with it and ahead.
Upd_CompilerSection:
                tst.b   $3C(a0)                     ; destroyed by its core?
                beq.b   .4B1AC
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                subq.b  #$1,(SectionsLeft).l        ; one section fewer
                rts
.4B1AC:
                bsr.w   .4B216
                tst.b   (CompilerEntering).l        ; still flying in?
                bpl.b   .4B1DA
                addq.w  #$3,$A(a0)                  ; 3 pixels a frame to the right
                moveq   #0,d0
                movea.l $36(a0),a1                  ; path: x bytes, then y bytes $474 later
                move.b  (a1),d0
                add.w   #$20,d0
                cmp.w   $A(a0),d0
                bgt.b   .4B1D8
                clr.b   (CompilerEntering).l
                subq.w  #$3,$A(a0)
.4B1D8:
                rts
.4B1DA:
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
                cmpi.w  #$474,$34(a0)               ; end of the path: start again
                bcs.b   .4B214
                clr.w   $34(a0)
.4B214:
                rts
.4B216:
                cmpi.b  #$2,$32(a0)
                bne.b   .4B228
                tst.b   $33(a0)
                beq.b   .4B22A
                subq.b  #$1,$33(a0)
.4B228:
                rts
.4B22A:
                movem.w $A(a0),d0-d1
                move.w  d1,d2
                cmp.w   (ShipPos).w,d0
                bhi.b   .4B228
                add.w   #$22,d2
                sub.w   ($F0).w,d2
                bpl.b   .4B244
                neg.w   d2
.4B244:
                cmp.w   #$1C,d2
                bhi.b   .4B228
                add.w   #$14,d1
                movem.l a0,-(a7)
                movem.w d0,-(a7)
                moveq   #40,d0
                jsr     (jt_Random).w
                add.w   d0,d1
                movem.w (a7)+,d0
                add.w   #$3C,d0
                moveq   #-1,d2
                lea.l   (Def_CompilerLaser).l,a2
                jsr     (jt_ObjCreate).w
                bset.b  #$2,$23(a0)
                jsr     (jt_ObjInsert).w
                movem.l (a7)+,a0
                move.b  #$E,$33(a0)
                rts
; Upd_CompilerCore: the target inside a section; hits flash the section.
; After 30 hits the section is destroyed: explosions, 5000 points, one
; section fewer.
Upd_CompilerCore:
                tst.b   $3C(a0)
                bne.w   .4B2DC
                movea.l $32(a0),a1
                movem.w $A(a1),d0-d1                ; sits inside its section
                movem.w d0-d1,$A(a0)
                tst.b   $28(a1)
                bne.b   .4B2CC
                move.w  $26(a0),d0
                cmp.w   $36(a0),d0
                beq.b   .4B2CC
                move.w  d0,$36(a0)
                cmp.w   #$1E,d0                     ; 30 hits:
                bcs.b   .4B2CE
                st.b    $3C(a1)                     ; destroy the section
                st.b    $3C(a0)
                clr.w   $34(a0)
                move.w  #$3,$1E(a0)
.4B2CC:
                rts
.4B2CE:
                bset.b  #$0,$23(a1)                 ; a hit: the section flashes
                move.b  #$3,$28(a1)
                rts
.4B2DC:
                subq.b  #$1,$3D(a0)                 ; explosions, then
                bne.b   .4B2F6
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                move.l  #$5000,d0                   ; 5000 points
                jsr     (jt_AddScore).w
.4B2F6:
                move.l  a0,-(a7)
                moveq   #60,d0
                jsr     (jt_Random).w
                move.w  d0,d1
                moveq   #80,d0
                jsr     (jt_Random).w
                add.w   $A(a0),d0
                add.w   $C(a0),d1
                moveq   #1,d2
                lea.l   (Def_CompilerCore).l,a2
                jsr     (jt_ObjCreate).w
                move.b  #$14,$4(a0)
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                jsr     (jt_ObjInsert).w
                movea.l (a7)+,a0
                rts
; Upd_CompilerGun: a turret on a section (CompilerGunOffsets), turned
; towards the ship, firing every 35-105 frames from its muzzle when the
; ship is behind it (directions 8-15).
Upd_CompilerGun:
                movea.l $32(a0),a1
                tst.b   $3C(a1)
                beq.b   .4B348
                clr.l   $6(a0)
                move.b  #$1,$5(a0)
                rts
.4B348:
                lea.l   (CompilerGunOffsets).l,a2
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
                bcs.b   .4B3AC
                subq.w  #$1,$38(a0)
                bpl.b   .4B3AC
                subq.w  #$8,d0
                lea.l   (CompilerGunMuzzles).l,a1
                lsl.w   #$2,d0
                add.w   (a1,d0.w),d5
                add.w   $2(a1,d0.w),d1
                move.w  d5,d0
                jsr     (jt_FireEnemyBullet).w
                moveq   #70,d0
                jsr     (jt_Random).w
                add.w   #$23,d0
                move.w  d0,$38(a0)
.4B3AC:
                lea.l   (CompilerGunFrames).l,a1
                move.b  (a1,d6.w),d0
                ext.w   d0
                move.w  d0,$1E(a0)
                rts
Upd_CompilerLaser:
                addq.w  #$6,$A(a0)
                cmpi.w  #$170,$A(a0)
                bcs.b   .4B3CE
                jmp     (jt_ObjKillSelf).w
.4B3CE:
                rts
Spawn_Cytron:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                clr.b   $22(a0)
                moveq   #0,d4
                move.w  $6(a1),$32(a0)
                beq.b   .4B3F6
                bpl.b   .4B3F4
                moveq   #12,d4
                bra.b   .4B3F6
.4B3F4:
                moveq   #4,d4
.4B3F6:
                move.w  $8(a1),$34(a0)
                beq.b   .4B406
                bpl.b   .4B404
                moveq   #0,d4
                bra.b   .4B406
.4B404:
                moveq   #8,d4
.4B406:
                move.w  d4,$1E(a0)
                clr.w   $3A(a0)
                move.l  $A(a1),$36(a0)
                jmp     (jt_ObjInsert).w
Upd_Cytron:
                movem.w $A(a0),d0-d1
                add.w   #$C,d0
                add.w   #$C,d1
                cmp.w   #$20,d1
                bls.b   .4B43C
                cmp.w   #$DF,d1
                bcc.b   .4B43C
                jsr     (jt_GetMapCell).w
                bne.b   .4B43C
                move.w  #$9013,(a4)
.4B43C:
                move.l  $36(a0),d0
                bne.b   .4B46E
                movem.w $32(a0),d2-d3
                add.w   d2,$A(a0)
                add.w   d3,$C(a0)
.4B450:
                move.w  $A(a0),d0
                bmi.b   .4B468
                cmp.w   #$170,d0
                bhi.b   .4B468
                move.w  $C(a0),d0
                bmi.b   .4B468
                cmp.w   #$E0,d0
                bcs.b   .4B46C
.4B468:
                jmp     (jt_ObjKillSelf).w
.4B46C:
                rts
.4B46E:
                tst.w   $32(a0)
                beq.b   .4B478
                subq.w  #$1,$A(a0)
.4B478:
                movea.l d0,a1
                move.w  $3A(a0),d0
                move.w  (a1)+,d1
                bsr.b   .4B49C
                add.w   d2,$A(a0)
                bsr.b   .4B49C
                add.w   d2,$C(a0)
                bsr.b   .4B49C
                move.b  d2,$1F(a0)
                cmp.w   d1,d0
                bcc.b   .4B450
                addq.w  #$1,$3A(a0)
                bra.b   .4B450
.4B49C:
                movea.l (a1)+,a2
                move.b  (a2,d0.w),d2
                ext.w   d2
                rts
Spawn_Geld:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                move.w  $8(a2),d2
                jsr     (jt_ObjCreate).w
                st.b    $22(a0)
                move.w  $6(a1),d0
                lsl.w   #$2,d0
                lea.l   (GeldStates).l,a3
                move.l  (a3,d0.w),$34(a0)
                move.l  $10(a3,d0.w),$2A(a0)
                move.w  $8(a1),$3A(a0)
                clr.b   $3C(a0)
                move.w  #$12,$32(a0)
                jmp     (jt_ObjInsert).w
GeldStates:
                dc.l    Geld_Up
                dc.l    Geld_Right,Geld_Down,Geld_Left          ; up, right, down, left
                dc.l    GeldAnimUp,GeldAnimRight,GeldAnimDown,GeldAnimLeft    ; their animations
Upd_Geld:
                subq.w  #$1,$A(a0)
                movem.w $A(a0),d0-d1
                add.w   #$10,d0
                add.w   #$10,d1
                jsr     (jt_GetMapCell).w
                beq.b   .4B526
                btst.b  #$4,(a4)
                beq.b   .4B526
                clr.w   (a4)
.4B526:
                tst.b   $3C(a0)
                beq.b   .4B540
                subq.b  #$1,$3C(a0)
                bne.b   .4B53E
                st.b    $22(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
.4B53E:
                rts
.4B540:
                move.w  $3A(a0),d0
                cmp.w   (ScrollX).w,d0
                bhi.b   .4B550
                move.w  #$7FFF,$32(a0)
.4B550:
                movem.w (ShipPos).w,d0-d1
                addq.w  #$5,d0
                subq.w  #$8,d1
                tst.w   $32(a0)
                beq.b   .4B564
                subq.w  #$1,$32(a0)
.4B564:
                movea.l $34(a0),a1
                jsr     (a1)
                move.w  $A(a0),d0
                bmi.b   .4B582
                cmp.w   #$170,d0
                bhi.b   .4B582
                move.w  $C(a0),d0
                bmi.b   .4B582
                cmp.w   #$F2,d0
                bcs.b   .4B586
.4B582:
                jmp     (jt_ObjKillSelf).w
.4B586:
                rts
Geld_Up:
                bne.b   .4B5C4
                cmp.w   $C(a0),d1
                bcs.b   .4B5C4
                bsr.w   Geld_Turn
                move.w  #$5,$1E(a0)
                cmp.w   $A(a0),d0
                bcs.b   .4B5B2
                move.l  #GeldAnimRight,$2A(a0)
                move.l  #Geld_Right,$34(a0)
                rts
.4B5B2:
                move.l  #GeldAnimLeft,$2A(a0)
                move.l  #Geld_Left,$34(a0)
                rts
.4B5C4:
                subq.w  #$2,$C(a0)
                rts
Geld_Down:
                bne.b   .Geld_Down_move                ; still in the turn delay
                cmp.w   $C(a0),d1
                bhi.b   .Geld_Down_move                ; not level with the ship yet
                bsr.w   Geld_Turn                     ; turn: pause
                move.w  #$7,$1E(a0)
                cmp.w   $A(a0),d0
                bcs.b   .Geld_Down_2
                move.l  #GeldAnimRight,$2A(a0)
                move.l  #Geld_Right,$34(a0)
                rts
.Geld_Down_2:
                move.l  #GeldAnimLeft,$2A(a0)
                move.l  #Geld_Left,$34(a0)
                rts
.Geld_Down_move:
                addq.w  #$2,$C(a0)
                rts
Geld_Left:
                bne.b   .GL_move                ; still in the turn delay
                cmp.w   $A(a0),d0
                bcs.b   .GL_move                ; not level with the ship yet
                bsr.b   Geld_Turn                     ; turn: pause
                move.w  #$5,$1E(a0)
                cmp.w   $C(a0),d1
                bcs.b   .GL_2
                move.l  #GeldAnimDown,$2A(a0)
                move.l  #Geld_Down,$34(a0)
                rts
.GL_2:
                move.l  #GeldAnimUp,$2A(a0)
                move.l  #Geld_Up,$34(a0)
                rts
.GL_move:
                subq.w  #$2,$A(a0)
                rts
Geld_Right:
                bne.b   .GR_move                ; still in the turn delay
                cmp.w   $A(a0),d0
                bhi.b   .GR_move                ; not level with the ship yet
                bsr.b   Geld_Turn                     ; turn: pause
                move.w  #$7,$1E(a0)
                cmp.w   $C(a0),d1
                bcs.b   .GR_2
                move.l  #GeldAnimDown,$2A(a0)
                move.l  #Geld_Down,$34(a0)
                rts
.GR_2:
                move.l  #GeldAnimUp,$2A(a0)
                move.l  #Geld_Up,$34(a0)
                rts
.GR_move:
                addq.w  #$2,$A(a0)
                rts
Geld_Turn:
                move.b  #$6,$3C(a0)
                move.w  #$12,$32(a0)
                clr.b   $20(a0)
                clr.b   $22(a0)
                rts
PataPataData1:
                dc.w    $006B                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $004E                   ; y
                dc.b    $08,$00                 ; delay, frame
                dc.w    $005F                   ; y
                dc.b    $18,$00                 ; delay, frame
                dc.w    $0046                   ; y
                dc.b    $24,$00                 ; delay, frame
                dc.w    $006B                   ; y
                dc.b    $2A,$00                 ; delay, frame
                dc.w    $FFFF
PataPataData2:
                dc.w    $0050                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $0060                   ; y
                dc.b    $06,$00                 ; delay, frame
                dc.w    $008E                   ; y
                dc.b    $13,$00                 ; delay, frame
                dc.w    $005F                   ; y
                dc.b    $1D,$00                 ; delay, frame
                dc.w    $FFFF
PataPataData3:
                dc.w    $0041                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $0055                   ; y
                dc.b    $0A,$00                 ; delay, frame
                dc.w    $005A                   ; y
                dc.b    $14,$00                 ; delay, frame
                dc.w    $004D                   ; y
                dc.b    $28,$00                 ; delay, frame
                dc.w    $FFFF
PataPataData4:
                dc.w    $0061                   ; y
                dc.b    $00,$00                 ; delay, frame
                dc.w    $003C                   ; y
                dc.b    $09,$00                 ; delay, frame
                dc.w    $0061                   ; y
                dc.b    $1B,$00                 ; delay, frame
                dc.w    $007D                   ; y
                dc.b    $27,$00                 ; delay, frame
                dc.w    $004A                   ; y
                dc.b    $33,$00                 ; delay, frame
                dc.w    $FFFF
; PataPata: as in level 1 (the same code)
; (32x19, 8 frames, gfx $55378, 1 hit point, fires every ~65 frames, score 200, update Upd_PataPata, spawn Spawn_PataPata)
Def_PataPata:
                dc.w    $1303,$002E,$0260,$0001,$0001,$0041,$0005,$5378
                dc.w    $0000,$0130,$0004,$B71A,$0004,$B724
                dc.l    Upd_PataPata
                dc.l    Spawn_PataPata
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0005
                dc.w    $0000,$000E,$0012,$0005,$0003,$000F,$000E,$0000
                dc.w    $0006,$0014,$0006,$0005,$0003,$000E,$000E,$0003
                dc.w    $0001,$0010,$0011,$0004,$0003,$000F,$000E,$0000
                dc.w    $0007,$0014,$0006,$0004,$0003,$000F,$000E
BugData1:
                dc.w    $0044                   ; steps
                dc.l    $0006C95D,$0006C9AA,$0006C9F7 ; dx, dy, frame tables (level B)
; Bug: as in level 1 (the same code)
; (32x21, 8 frames, gfx $56678, 1 hit point, fires every ~48 frames, score 200, update Upd_Bug, spawn Spawn_Bug)
Def_Bug:
                dc.w    $1503,$002E
                dc.w    $02A0,$0000,$0001,$0030,$0005,$6678,$0000,$0150
                dc.w    $0004,$B79A,$0004,$B7A4
                dc.l    Upd_Bug
                dc.l    Spawn_Bug
                dc.w    $0000,$0200,$0001,$0203,$0405,$0607,$FF00,$0002
                dc.w    $0003,$0011,$0011,$0002,$0002,$0011,$0012,$0001
                dc.w    $0002,$0011,$0011,$0002,$0001,$0011,$0011,$0002
                dc.w    $0001,$0011,$0012,$0003,$0001,$0010,$0011,$0002
                dc.w    $0002,$0012,$0011,$0003,$0002,$0011,$0012
; PStaff: as in level 1 (the same code)
; (32x26, 6 frames, gfx $57B78, 6 hit points, score 500, update Upd_PStaff, spawn Spawn_PStaff)
Def_PStaff:
                dc.w    $1A03
                dc.w    $002E,$0340,$0002,$0006,$0000,$0005,$7B78,$0000
                dc.w    $01A0,$0004,$B80C,$0004,$B828
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
; (16x13, 16 frames, gfx $5AC38, update Upd_PStaffMissile)
Def_PStaffMissile:
                dc.w    $0D02,$0030,$00D0,$0000,$0000,$0000,$0005,$AC38
                dc.w    $0000,$0068,$0004,$B8C8,$0004,$B8DC
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
; Bink: as in level 1 (the same code)
; (32x26, 4 frames, gfx $5B938, 1 hit point, fires every ~30 frames, score 200, update Upd_Bink, spawn Spawn_Bink)
Def_Bink:
                dc.w    $1A03,$002E
                dc.w    $0340,$0003,$0001,$001E,$0005,$B938,$0000,$01A0
                dc.w    $0004,$B984,$0004,$B998
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
CancerData1:
                dc.w    $0170,$0062             ; x, y
                dc.w    $0170,$00B8             ; x, y
                dc.w    $FFFF
CancerData2:
                dc.w    $0170,$009B             ; x, y
                dc.w    $FFFF
CancerData3:
                dc.w    $0011,$009B             ; x, y
                dc.w    $FFFF
CancerData4:
                dc.w    $0170,$0050             ; x, y
                dc.w    $FFFF
CancerData5:
                dc.w    $0011,$0053             ; x, y
                dc.w    $0064,$0004             ; x, y
                dc.w    $0136,$0004             ; x, y
                dc.w    $FFFF
CancerData6:
                dc.w    $0170,$0070             ; x, y
                dc.w    $014A,$0010             ; x, y
                dc.w    $FFFF
CancerData7:
                dc.w    $0064,$0010             ; x, y
                dc.w    $0069,$0010             ; x, y
                dc.w    $FFFF
; Cancer: as in level 1 (the same code)
; (32x26, 6 frames, gfx $5E038, 1 hit point, fires every ~40 frames, score 300, update Upd_Cancer, spawn Spawn_Cancer)
Def_Cancer:
                dc.w    $1A03,$002E,$0340,$0005,$0001,$0028,$0005
                dc.w    $E038,$0000,$01A0,$0004,$BA72,$0004,$BA7C
                dc.l    Upd_Cancer
                dc.l    Spawn_Cancer
                dc.w    $0000,$0300
CancerAnimRight:
                dc.b    $03,$04,$05,$04,$FF
CancerAnimLeft:
                dc.b    $00,$01,$02,$01,$FF,$00,$04,$00,$02,$00,$18,$00,$16,$00,$02,$00
                dc.b    $03,$00,$1B,$00,$14,$00,$04,$00,$04,$00,$18,$00,$13,$00,$05,$00
                dc.b    $04,$00,$18,$00,$14,$00,$04,$00,$03,$00,$19,$00,$15,$00,$05,$00
                dc.b    $03,$00,$18,$00,$15
BossStarted:
                dc.b    $00
CompilerEntering:
                dc.b    $00
SectionsLeft:
                dc.w    $0000
CompilerSections:
                dc.w    $0004,$BACE,$FFE5,$006B,$0006,$0004,$BAF6,$FFC5
                dc.w    $0044,$0005,$0004,$BB1E,$0000,$0041,$0007
; object definition: 96x81, 1 frame, gfx $665B8, update Upd_CompilerSection
Def_CompilerA:
                dc.w    $5107
                dc.w    $0026,$1E60,$0000,$0000,$0000,$0006,$65B8,$0000
                dc.w    $0F30,$0004,$BB46,$0004,$BB4C
                dc.l    Upd_CompilerSection
                dc.w    $0000,$0000,$0000,$0000
; object definition: 112x58, 1 frame, gfx $68418, update Upd_CompilerSection
Def_CompilerB:
                dc.w    $3A08,$0024,$1960,$0000
                dc.w    $0000,$0000,$0006,$8418,$0000,$0CB0,$0004,$BB46
                dc.w    $0004,$BB54
                dc.l    Upd_CompilerSection
                dc.w    $0000,$0000,$0000,$0000
; object definition: 96x68, 1 frame, gfx $69D78, update Upd_CompilerSection
Def_CompilerC:
                dc.w    $4407,$0026,$1980,$0000
                dc.w    $0000,$0000,$0006,$9D78,$0000,$0CC0,$0004,$BB46
                dc.w    $0004,$BB5C
                dc.l    Upd_CompilerSection
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$FF00,$0008
                dc.w    $001B,$004D,$0032,$0005,$0002,$0064,$002E,$000D
                dc.w    $0004,$0049,$003D
Def_CompilerCore:
                dc.w    $0041,$0032,$0000,$0000,$0000,$0000,$0004,$BC12
                dc.w    $0000,$0000,$0004,$BB46,$0004,$BB8C
                dc.l    Upd_CompilerCore
                dc.w    $0000,$0000,$0000,$0000,$0030,$000D,$0022,$000E
                dc.w    $0027,$002E,$001D,$000C,$0001,$000E,$000C,$001F
                dc.w    $01A4,$000A,$0002,$0002
; object definition: 32x25, 5 frames, gfx $6B6F8, update Upd_CompilerGun
Def_CompilerGun:
                dc.w    $1903,$002E,$0320,$0000,$0000,$0000,$0006,$B6F8
                dc.w    $0000,$0190,$0004,$BBD4,$0004,$BBDA
                dc.l    Upd_CompilerGun
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$04FF,$0004
                dc.w    $FFE6,$001E,$0032,$0004,$FFE6,$001E,$0032,$0004
                dc.w    $FFE6,$001E,$0032,$0004,$FFE6,$001E,$0032,$0004
                dc.w    $FFE6,$001E,$0032
CompilerGunParents:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
CompilerGunOffsets:
                dc.w    $0003,$0022,$000B,$003A,$FFFC,$0010
CompilerGunFrames:
                dc.w    $0000,$0101,$0202,$0304,$0403,$0302,$0201,$0100
CompilerGunMuzzles:
                dc.w    $FFFE,$0012,$FFF9,$000E,$FFF9,$000E,$FFF6,$0006
                dc.w    $FFF6,$0006,$FFF9,$FFFD,$FFF9,$FFFD,$FFFD,$FFF8
; object definition: 32x3, 4 frames, gfx $6C698, update Upd_CompilerLaser
Def_CompilerLaser:
                dc.w    $0303,$002E,$0060,$0002,$0000,$0000,$0006,$C698
                dc.w    $0000,$0030,$0004,$BB46,$0004,$BC86
                dc.l    Upd_CompilerLaser
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003,$0000,$0000,$0020,$0003
                dc.w    $0000,$0000,$0020,$0003
CytronData1:
                dc.w    $004B                   ; steps
                dc.l    $0006CA3C,$0006CA88,$0006CAD4 ; dx, dy, frame tables (level B)
CytronData2:
                dc.w    $004C                   ; steps
                dc.l    $0006CB20,$0006CB6D,$0006CBBA ; dx, dy, frame tables (level B)
CytronData4:
                dc.w    $004F                   ; steps
                dc.l    $0006CC07,$0006CC57,$0006CCA7 ; dx, dy, frame tables (level B)
CytronData3:
                dc.w    $002E                   ; steps
                dc.l    $0006CCF7,$0006CD26,$0006CD55 ; dx, dy, frame tables (level B)
CytronData5:
                dc.w    $0054                   ; steps
                dc.l    $0006CD84,$0006CDD9,$0006CE2E ; dx, dy, frame tables (level B)
CytronData6:
                dc.w    $0031                   ; steps
                dc.l    $0006CE83,$0006CEB5,$0006CEE7 ; dx, dy, frame tables (level B)
CytronData7:
                dc.w    $0032                   ; steps
                dc.l    $0006CF19,$0006CF4C,$0006CF7F ; dx, dy, frame tables (level B)
; Cytron: built to destroy asteroids, it rebuilds the cell walls - every
; frame it writes a solid, destructible cell ($9013) into the map cell
; under it if that one is empty.
; Flies straight (entry $06/$08 = dx, dy, which also pick the frame) or
; along a path (entry $0A).  3 hit points.
; (32x25, 16 frames, gfx $5F3B8, 3 hit points, score 400, update Upd_Cytron, spawn Spawn_Cytron)
Def_Cytron:
                dc.w    $1903,$002E,$0320
                dc.w    $0000,$0003,$0000,$0005,$F3B8,$0000,$0190,$0004
                dc.w    $BD30,$0004,$BD42
                dc.l    Upd_Cytron
                dc.l    Spawn_Cytron
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
; Geld: eats the cell walls - it clears any destructible cell it touches.
; It moves in straight lines (GeldStates: up, right, down, left, picked by
; entry $06) and turns towards the ship when level with it, pausing 6
; frames at each turn (Geld_Turn) and not turning again for 18; after
; scroll x (entry $08) it stops turning.
; (32x32, 3 frames, gfx $625B8, 1 hit point, score 200, update Upd_Geld, spawn Spawn_Geld)
Def_Geld:
                dc.w    $2003,$002E,$0400,$0002,$0001
                dc.w    $0000,$0006,$25B8,$0000,$0200,$0004,$BDEA,$0004
                dc.w    $BE0E
                dc.l    Upd_Geld
                dc.l    Spawn_Geld
                dc.b    $00,$00,$02,$00
GeldAnimUp:
                dc.b    $00,$01,$00,$02,$FF,$0F,$FF,$03,$FF
GeldAnimRight:
                dc.b    $04,$05,$04,$06,$FF,$03,$FF,$07,$FF
GeldAnimDown:
                dc.b    $08,$09,$08,$0A,$FF,$0B,$FF
                dc.b    $07,$FF
GeldAnimLeft:
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
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
