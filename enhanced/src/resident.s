;==============================================================================
; R-Type (enhanced): the resident part of the menu - the cheats' hooks
;==============================================================================
; Loaded once by stage 2 to RES_ORG ($49D0A, files.i), the gap between the
; engine's object table and the level file, which nothing else uses.  It
; holds what must stay in memory through a game: the engine's hooks for the
; cheats and the cheat settings.  The title menu itself (menu.s) is only
; needed on the title, so it is loaded with the title file each time
; (LoadTitle) to the top of memory, which is free during play.
;
; Assembled after the engine, against its symbols (build/game_syms.i).  The
; engine reaches it through the jump table below (MJ_* in files.i); each
; hook in game.s replaced instructions of the same size.  menu.s is
; assembled after this, against both.
;==============================================================================

                include "files.i"
                include "game_syms.i"

                org     RES_ORG

; the jump table (MJ_* in files.i; MJ_FRAME and MJ_TITLETEXT are menu.s's)
                jmp     (MenuPrintFire).l
                jmp     (CheatNewGame).l
                jmp     (CheatLoseLife).l
                jmp     (CheatShipHit).l
                jmp     (CheatWeapons).l
                jmp     (CheatScore).l
                jmp     (LoadTitle).l

RES_IN_FIRE     equ     4               ; (menu.s: IN_FIRE)

;==============================================================================
; LoadTitle: the engine's LoadShared (jumped to): the title file to $4A300,
; then the title menu to MENU_ORG.  At start-up and whenever the title
; comes back after a game (the levels overwrite both).
;==============================================================================
LoadTitle:
                move.l  #$4A300,d2
                moveq   #FID_SHARED,d0
                moveq   #0,d1
                jsr     (LoadTracksCached).l
                move.l  #MENU_ORG,d2
                moveq   #FID_MENU,d0
                moveq   #0,d1
                jmp     (LoadTracksCached).l

;==============================================================================
; MenuPrintFire: from PrintString, before each character, in place of its
; fire test (which left the title from the middle of the typing).  On the
; title, fire now types the rest of the text at once.  Returns Z clear.
;==============================================================================
MenuPrintFire:
                tst.b   (MenuInTitle).l
                beq.b   .r
                btst.b  #7,(CIAA_PRA).l
                bne.b   .fast
                st.b    (MenuFast).l
                bset.b  #RES_IN_FIRE,(MenuHeld).l   ; (not a press for the menu)
.fast:
                tst.b   (MenuFast).l
                beq.b   .r
                moveq   #0,d1                   ; no typing delay
.r:
                andi.b  #$FB,ccr
                rts

;==============================================================================
; The cheats, from the engine's hooks
;==============================================================================
; AnyCheat: Z clear if any cheat is on (the stage skip and a start stage
; other than 1 included)
AnyCheat:
                move.l  d0,-(a7)
                move.b  (CheatFlags).l,d0
                or.b    (StartStage).l,d0
                or.b    (Weapons).l,d0
                movem.l (a7)+,d0                ; (keeps the flags)
                rts

; CheatNewGame: NewGame, in place of move.l #LevelTable,LevelTablePtr
; (Level is already 0): start at StartStage; note whether this game counts
CheatNewGame:
                movem.l d0,-(a7)
                clr.b   (MenuInTitle).l
                moveq   #0,d0
                move.b  (StartStage).l,d0
                move.b  d0,(Level).l
                mulu.w  #10,d0
                add.l   #LevelTable,d0
                move.l  d0,(LevelTablePtr).l
                bsr.b   AnyCheat
                sne.b   (CheatUsed).l
                movem.l (a7)+,d0
                rts

; CheatLoseLife: ShipRespawn, in place of subq.w #1,Lives
CheatLoseLife:
                btst.b  #CHEATB_LIVES,(CheatFlags).l
                bne.b   .r
                subq.w  #1,(Lives).l
.r:             rts

; CheatShipHit: the ship's three deaths (an enemy or its bullet touching
; it, a power-up's "anything else", a solid map cell), in place of
; st.b ShipHit
CheatShipHit:
                btst.b  #CHEATB_INVINCIBLE,(CheatFlags).l
                bne.b   .r
                st.b    (ShipHit).l
.r:             rts

; CheatWeapons: the end of ResetShipWeapons (jumped to): its last
; instruction, and when called from SpawnShip (a new ship: level start or
; after a death) with full weapons on, the Force at level 3 flying in with
; the chosen laser, both Bits and the missiles.  (The Force's own start,
; Force_Idle, would set its level back to 0, so this starts it at
; Force_Reset with Force_Idle's other settings.)
CheatWeapons:
                move.l  #Force_Idle,(ForceState).l
                tst.b   (Weapons).l
                beq.b   .r
                cmpi.l  #SpawnShipArmed,(a7)    ; not after a death or in the ending
                bne.b   .r
                move.l  d0,-(a7)
                move.b  (Weapons).l,d0
                subq.b  #1,d0
                move.b  d0,(LaserType).l        ; 0 blue, 1 red, 2 yellow
                move.l  (a7)+,d0
                move.l  #$6A40,(ForceFrame).l
                move.b  #1,(ForceAnimDir).l
                clr.b   (ForceAnimLevel).l
                clr.b   (ForceAnimTimer).l
                move.b  #3,(ForceLevel).l
                st.b    (ForceActive).l
                move.b  #3,(BitsFlags).l
                st.b    (MissilesEnabled).l
                move.l  #Force_Reset,(ForceState).l
.r:             rts

; CheatScore: St_HighScore, in place of move.l Score,d0: after a game with
; cheats, 0 (no place in the table, nothing saved)
CheatScore:
                move.l  (Score).l,d0
                tst.b   (CheatUsed).l
                beq.b   .r
                moveq   #0,d0
.r:             rts

;==============================================================================
; Settings and state, kept for the whole session (menu.s sets them)
;==============================================================================
MenuHeld:       dc.b    $FF             ; the input last frame (nothing pressed at first)
MenuFast:       dc.b    0               ; fire while typing: the rest at once
MenuInTitle:    dc.b    0               ; the title is running (not a game)
StartStage:     dc.b    0               ; 0-7
Weapons:        dc.b    0               ; 0 off, 1-3 = LaserType + 1
CheatUsed:      dc.b    0               ; this game had a cheat on
                even
ResEnd:
                ifgt    ResEnd-RES_LIMIT
                fail    "the resident part is over its space (RES_LIMIT)"
                endc
