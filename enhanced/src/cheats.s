;==============================================================================
; Cheats (enhanced)
;==============================================================================
; CheatFlags holds one bit per cheat (CHEATB_*, files.i), set on the title
; menu's options page (menu.s).  The other cheats are in menu.s.

; CheatKeys: called from Level2Int with d0 = the raw key code (bit 7 set on
; release).  It returns with the flags of "cmp.b #KEY_P,d0", which is the test
; it replaces there, so Level2Int goes on to pause only for P.
;
; N with the skip on, in normal play (not during the intro, the stage-end
; sequence, a death or the continue screen) and before the last stage, sets
; LevelComplete, as killing the boss does: the ship flies off, the stage bonus
; is counted and the next stage loads.  (A game with it on gets no high-score
; place: see CheatScore in menu.s.)
KEY_N           equ     $36
KEY_P           equ     $19

CheatKeys:
                cmp.b   #KEY_N,d0
                bne.b   .done
                btst.b  #CHEATB_SKIP,(CheatFlags).l
                beq.b   .done
                cmpi.l  #St_Playing,(GameState).l
                bne.b   .done
                cmpi.b  #7,(Level).l            ; stage 8: its ending is its own code
                beq.b   .done
                st.b    (LevelComplete).l
.done:
                cmp.b   #KEY_P,d0
                rts

CheatFlags:
                dc.b    0
                even
