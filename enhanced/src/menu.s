;==============================================================================
; R-Type (enhanced): the title menu
;==============================================================================
; Only needed on the title: the engine's LoadShared (resident.s, LoadTitle)
; loads it with the title file to MENU_ORG, at the top of memory, every time
; the title starts; in play that memory is free.  The cheats' hooks and the
; settings stay in memory in resident.s.  Assembled after the engine and
; resident.s, against their symbols (build/game_syms.i, written by
; tools/build.py).  The engine calls in through the jump table below.
;
; The title (St_TitleText) now types:
;       blast off and strike / the evil bydo empire!
;       start game  <
;       options
;       freeplay (or "cheats on", or "trainer" for the original's own)
;       credit 05
; Up / down choose, fire selects.  Any press on the credits or the
; high-score table goes to the title (it no longer starts a game), and fire
; while the text is typed finishes it at once.  A press keeps the title up
; for another 200 frames.
;
; The options page (no time-out): up / down choose, left / right change,
; fire changes too (and plays the sound, or leaves on EXIT):
;       infinite lives      off / on        CHEATB_LIVES
;       invincibility       off / on        CHEATB_INVINCIBLE
;       start stage         1-8             StartStage
;       full weapons        off / blue / red / yellow   (the Force at its
;                           strongest with that crystal's laser, both
;                           Bits and the missiles, at every ship start)
;       stage skip key n    off / on        CHEATB_SKIP (cheats.s)
;       sound effect        00-13           fire plays it
;       exit
; A game played with any of them on doesn't go into the high-score table
; (resident.s).
;==============================================================================

                include "files.i"
                include "game_syms.i"           ; the engine and resident.s

                org     MENU_ORG

; the jump table (MJ_FRAME, MJ_TITLETEXT in files.i)
                jmp     (MenuFrame).l
                jmp     (MenuTitleText).l

; input bits (MenuHeld, ReadInput)
IN_UP           equ     0
IN_DOWN         equ     1
IN_LEFT         equ     2
IN_RIGHT        equ     3
IN_FIRE         equ     4

; pages (MenuPage)
PG_ATTRACT      equ     0               ; credits, high scores, the title arriving
PG_TITLE        equ     1               ; the title's menu is up
PG_OPTIONS      equ     2

; the screen: SCREEN_A + line * $D0 + byte (DrawChar writes both screens)
SCR             macro
                dc.l    SCREEN_A+(\1)*$D0+(\2)
                endm
TITLE_X         equ     23              ; the title's items
TITLE_ARROW     equ     34
TITLE_Y0        equ     72              ; start game
TITLE_Y1        equ     86              ; options
OPT_X           equ     9               ; the options page: labels
OPT_VALUE       equ     30              ; values (6 characters)
OPT_ARROW       equ     37
OPT_Y           equ     72              ; first item, then OPT_DY apart
OPT_DY          equ     14
OPT_ITEMS       equ     7               ; the last is EXIT
OPT_SOUND       equ     5
NSOUNDS         equ     14              ; PlaySound 0-13

;==============================================================================
; MenuFrame: from TitleLoop, once a frame, before TitleDelay and TitleState
; (in place of the original's fire test).  Returns Z set to start a game
; (TitleLoop then leaves through AbortTitle); every register is kept, as
; the title's states keep pointers in them from frame to frame.
;==============================================================================
MenuFrame:
                movem.l d0-d7/a0-a6,-(a7)
                st.b    (MenuInTitle).l
                clr.b   (MenuFast).l
                bsr.w   ReadInput               ; d1 = new presses
                move.l  (TitleState).l,d2
                cmpi.l  #St_HighScore,d2        ; a new title sequence: name entry
                bne.b   .page                   ; first (EnterName reads the stick
                clr.b   (MenuPage).l            ; itself)
                bra.w   MenuNoStart
.page:
                move.b  (MenuPage).l,d3
                cmp.b   #PG_OPTIONS,d3
                beq.w   OptionsFrame
                cmp.b   #PG_TITLE,d3
                beq.b   TitleMenuFrame
; credits, high-score table, the title coming in: a press goes to the title
                tst.b   d1
                beq.w   MenuNoStart
                lea.l   (ToTitleStates).l,a0
.on_way:
                move.l  (a0)+,d0
                beq.b   .go
                cmp.l   d0,d2
                beq.w   MenuNoStart             ; on its way already
                bra.b   .on_way
.go:
                move.l  #St_ShowTitle,(TitleState).l
                move.b  #$F,(TitleFadeSteps).l
                clr.w   (TitleDelay).l
                bra.w   MenuNoStart

; the title's menu: start game / options
TitleMenuFrame:
                btst    #IN_FIRE,d1
                bne.b   .fire
                move.b  d1,d0
                and.b   #(1<<IN_UP)|(1<<IN_DOWN),d0
                beq.b   .idle
                eori.b  #1,(MenuItem).l         ; two items: up and down swap
                bsr.w   DrawTitleArrows
                bsr.w   KeepTitle
.idle:
                cmpi.l  #St_ShowCredits,(TitleState).l  ; time out: the title leaves
                bne.w   MenuNoStart
                tst.w   (TitleDelay).l
                bne.w   MenuNoStart
                clr.b   (MenuPage).l
                bra.w   MenuNoStart
.fire:
                tst.b   (MenuItem).l
                beq.b   MenuStart
                bsr.w   OpenOptions
                bra.w   MenuNoStart

MenuStart:
                movem.l (a7)+,d0-d7/a0-a6
                ori.b   #$04,ccr                ; Z: start the game
                rts
MenuNoStart:
                movem.l (a7)+,d0-d7/a0-a6
                andi.b  #$FB,ccr
                rts

; the states that lead to the title already
ToTitleStates:
                dc.l    St_ShowTitle,St_TitleStart,St_TitleLetters,St_TitleText,St_TitleWipe,0

; KeepTitle: a press on the title restarts its time-out (once the text is
; up; during the wipe TitleDelay paces the wipe)
KeepTitle:
                cmpi.l  #St_ShowCredits,(TitleState).l
                bne.b   .r
                move.w  #200,(TitleDelay).l
.r:             rts

; DrawTitleArrows: "<" beside the chosen item
DrawTitleArrows:
                lea.l   (TitleArrowPos).l,a2
                moveq   #0,d7
.next:
                lea.l   (TxtBlank1).l,a0
                cmp.b   (MenuItem).l,d7
                bne.b   .draw
                lea.l   (TxtArrow).l,a0
.draw:
                movea.l (a2)+,a1
                bsr.w   Print
                addq.b  #1,d7
                cmp.b   #2,d7
                bne.b   .next
                rts
TitleArrowPos:
                SCR     TITLE_Y0,TITLE_ARROW
                SCR     TITLE_Y1,TITLE_ARROW

; Print: a0 = text, a1 = screen, at once
Print:
                moveq   #0,d1
                jmp     (PrintString).l

;==============================================================================
; MenuTitleText: from St_TitleText, in place of lea TitleTextList,a4: the
; title's text with the menu, typed by PrintList as the original's was.
;==============================================================================
MenuTitleText:
                move.b  #PG_TITLE,(MenuPage).l
                clr.b   (MenuItem).l
                lea.l   (TxtFreeplay).l,a4
                tst.b   (CheatMode).l           ; the original's own trainer
                beq.b   .cheats
                lea.l   (TxtTrainer9).l,a4
                bra.b   .set
.cheats:
                jsr     (AnyCheat).l            ; (resident.s)
                beq.b   .set
                lea.l   (TxtCheatsOn).l,a4
.set:
                move.l  a4,(TitleListMode).l
                lea.l   (TitleList).l,a4
                rts

TitleList:
                SCR     40,23
                dc.l    TxtBlast
                SCR     49,23
                dc.l    TxtBydo
                SCR     TITLE_Y0,TITLE_X
                dc.l    TxtStartGame
                SCR     TITLE_Y0,TITLE_ARROW
                dc.l    TxtArrow
                SCR     TITLE_Y1,TITLE_X
                dc.l    TxtOptions
                SCR     110,33
TitleListMode:
                dc.l    TxtFreeplay
                SCR     125,33
                dc.l    MTxtCredit
                SCR     208,31
                dc.l    TxtIrem
                dc.l    -1,-1

;==============================================================================
; ReadInput: the joystick in port 2 -> d0 = held, d1 = new presses (IN_*);
; a held direction repeats after 20 frames, then every 5
;==============================================================================
ReadInput:
                moveq   #0,d0
                move.w  (CUSTOM+JOY1DAT).l,d2
                btst    #1,d2
                beq.b   .l
                bset    #IN_RIGHT,d0
.l:             btst    #9,d2
                beq.b   .ud
                bset    #IN_LEFT,d0
.ud:            move.w  d2,d3
                lsr.w   #1,d3
                eor.w   d2,d3                   ; bit 0 = down, bit 8 = up
                btst    #0,d3
                beq.b   .u
                bset    #IN_DOWN,d0
.u:             btst    #8,d3
                beq.b   .f
                bset    #IN_UP,d0
.f:             btst.b  #7,(CIAA_PRA).l
                bne.b   .new
                bset    #IN_FIRE,d0
.new:
                move.b  (MenuHeld).l,d1
                not.b   d1
                and.b   d0,d1                   ; pressed since the last frame
                move.b  d0,(MenuHeld).l
                move.b  d0,d2
                and.b   #$0F,d2                 ; directions held
                beq.b   .done
                move.b  d1,d3
                and.b   #$0F,d3
                bne.b   .first
                subq.b  #1,(MenuRepeat).l
                bne.b   .done
                move.b  #5,(MenuRepeat).l
                or.b    d2,d1
                rts
.first:
                move.b  #20,(MenuRepeat).l
.done:
                rts

;==============================================================================
; The options page
;==============================================================================
OpenOptions:
                move.b  #PG_OPTIONS,(MenuPage).l
                clr.b   (MenuItem).l
                jsr     (ClearPlayfield).l
                lea.l   (TextPalette).l,a1
                jsr     (SetPalette).l
                move.l  #MenuWait,(TitleState).l
                clr.w   (TitleDelay).l
                lea.l   (TxtOptionsHead).l,a0
                lea.l   (SCREEN_A+46*$D0+22).l,a1
                bsr.w   Print
                lea.l   (TxtHelp).l,a0
                lea.l   (SCREEN_A+200*$D0+9).l,a1
                bsr.w   Print
                moveq   #0,d7
.item:
                bsr.w   DrawOption
                addq.b  #1,d7
                cmp.b   #OPT_ITEMS,d7
                bne.b   .item
                rts

; the options page's TitleState: no time-out
MenuWait:
                clr.w   (TitleDelay).l
                jmp     (TitleNextFrame).l

OptionsFrame:
                moveq   #0,d7
                move.b  (MenuItem).l,d7
                btst    #IN_UP,d1
                beq.b   .down
                subq.b  #1,d7
                bpl.b   .move
                moveq   #OPT_ITEMS-1,d7
                bra.b   .move
.down:
                btst    #IN_DOWN,d1
                beq.b   .change
                addq.b  #1,d7
                cmp.b   #OPT_ITEMS,d7
                bne.b   .move
                moveq   #0,d7
.move:
                moveq   #0,d6
                move.b  (MenuItem).l,d6
                move.b  d7,(MenuItem).l
                exg     d6,d7
                bsr.w   DrawOption              ; the old item without its arrow
                move.b  d6,d7
                bsr.w   DrawOption
                bra.w   MenuNoStart
.change:
                moveq   #1,d5                   ; right or fire: on / next
                btst    #IN_RIGHT,d1
                bne.b   .do
                btst    #IN_FIRE,d1
                bne.b   .do
                moveq   #-1,d5
                btst    #IN_LEFT,d1
                beq.w   MenuNoStart
.do:
                add.w   d7,d7
                move.w  .jumps(pc,d7.w),d0
                lsr.w   #1,d7
                jsr     .jumps(pc,d0.w)
                bsr.w   DrawOption
                bra.w   MenuNoStart
.jumps:
                dc.w    OptLives-.jumps,OptInvincible-.jumps,OptStage-.jumps
                dc.w    OptWeapons-.jumps,OptSkip-.jumps,OptSound-.jumps,OptExit-.jumps

; each: d5 = +1 / -1, d1 = the presses, d7 = the item (kept)
OptLives:
                bchg.b  #CHEATB_LIVES,(CheatFlags).l
                rts
OptInvincible:
                bchg.b  #CHEATB_INVINCIBLE,(CheatFlags).l
                rts
OptSkip:
                bchg.b  #CHEATB_SKIP,(CheatFlags).l
                rts
OptStage:
                move.b  (StartStage).l,d0
                add.b   d5,d0
                and.b   #7,d0                   ; 8 stages, round and round
                move.b  d0,(StartStage).l
                rts
OptWeapons:
                move.b  (Weapons).l,d0
                add.b   d5,d0
                and.b   #3,d0                   ; off, blue, red, yellow
                move.b  d0,(Weapons).l
                rts
OptSound:
                btst    #IN_FIRE,d1
                bne.b   .play
                move.b  (SoundNum).l,d0
                add.b   d5,d0
                bpl.b   .lo
                moveq   #NSOUNDS-1,d0
.lo:            cmp.b   #NSOUNDS,d0
                bne.b   .set
                moveq   #0,d0
.set:           move.b  d0,(SoundNum).l
                rts
.play:
                moveq   #0,d0
                move.b  (SoundNum).l,d0
                jmp     (PlaySound).l
OptExit:
                btst    #IN_FIRE,d1             ; only fire leaves
                beq.b   .r
                addq.l  #4,a7                   ; (not back to OptionsFrame)
                clr.b   (MenuPage).l
                jsr     (ClearPlayfield).l
                move.l  #St_TitleStart,(TitleState).l   ; the letters fly in again
                clr.w   (TitleDelay).l
                bra.w   MenuNoStart
.r:             rts

; DrawOption: d7 = item (kept): its label, value and arrow
DrawOption:
                movem.l d5-d7,-(a7)
                moveq   #0,d0
                move.b  d7,d0
                mulu.w  #OPT_DY*$D0,d0
                cmp.b   #OPT_ITEMS-1,d7         ; EXIT a line further down
                bne.b   .y
                add.l   #OPT_DY*$D0,d0
.y:
                add.l   #SCREEN_A+OPT_Y*$D0,d0
                movea.l d0,a3                   ; the line
                lea.l   (OptLabels).l,a0
                move.w  d7,d1
                lsl.w   #2,d1
                movea.l (a0,d1.w),a0
                lea.l   OPT_X(a3),a1
                bsr.w   Print
                bsr.w   OptValue                ; a0 = the value's text
                lea.l   OPT_VALUE(a3),a1
                bsr.w   Print
                lea.l   (TxtBlank1).l,a0
                cmp.b   (MenuItem).l,d7
                bne.b   .arrow
                lea.l   (TxtArrow).l,a0
.arrow:
                lea.l   OPT_ARROW(a3),a1
                bsr.w   Print
                movem.l (a7)+,d5-d7
                rts

; OptValue: d7 = item -> a0 = its value, 6 characters
OptValue:
                lea.l   (TxtOff).l,a0
                cmp.b   #0,d7
                bne.b   .1
                btst.b  #CHEATB_LIVES,(CheatFlags).l
                bra.w   .onoff
.1:             cmp.b   #1,d7
                bne.b   .2
                btst.b  #CHEATB_INVINCIBLE,(CheatFlags).l
                bra.w   .onoff
.2:             cmp.b   #2,d7
                bne.b   .3
                lea.l   (TxtNumber).l,a0
                move.b  (StartStage).l,d0
                add.b   #'1',d0
                move.b  #' ',(a0)
                move.b  d0,1(a0)
                rts
.3:             cmp.b   #3,d7
                bne.b   .4
                moveq   #0,d0
                move.b  (Weapons).l,d0
                mulu.w  #7,d0
                lea.l   (TxtWeapons).l,a0
                adda.w  d0,a0
                rts
.4:             cmp.b   #4,d7
                bne.b   .5
                btst.b  #CHEATB_SKIP,(CheatFlags).l
                bra.w   .onoff
.5:             cmp.b   #OPT_SOUND,d7
                bne.b   .6
                lea.l   (TxtNumber).l,a0
                moveq   #0,d0
                move.b  (SoundNum).l,d0
                divu.w  #10,d0
                add.b   #'0',d0
                move.b  d0,(a0)
                swap    d0
                add.b   #'0',d0
                move.b  d0,1(a0)
                rts
.6:             lea.l   (TxtBlank6).l,a0
                rts
.onoff:
                beq.b   .off
                lea.l   (TxtOn).l,a0
.off:           rts


;==============================================================================
; Text (the font has a-z, 0-9 and . , - ! ?; "<" is an arrow)
;==============================================================================
TxtBlast:       dc.b    "blast off and strike",0
TxtBydo:        dc.b    "the evil bydo empire!",0
TxtStartGame:   dc.b    "start game",0
TxtOptions:     dc.b    "options",0
TxtFreeplay:    dc.b    " freeplay",0
TxtCheatsOn:    dc.b    "cheats on",0
TxtTrainer9:    dc.b    "  trainer",0
MTxtCredit:      dc.b    "credit 05",0
TxtIrem:        dc.b    "C 1987 by irem",0
TxtArrow:       dc.b    "<",0
TxtBlank1:      dc.b    " ",0
TxtOptionsHead: dc.b    "options",0
TxtHelp:        dc.b    "up down choose  fire left right set",0
TxtOff:         dc.b    "off   ",0
TxtOn:          dc.b    "on    ",0
TxtBlank6:      dc.b    "      ",0
TxtNumber:      dc.b    "00    ",0
TxtWeapons:     dc.b    "off   ",0
                dc.b    "blue  ",0
                dc.b    "red   ",0
                dc.b    "yellow",0
                even                    ; (a long table after the strings: an odd
                                        ;  address is an address error on a 68000)
OptLabels:      dc.l    TxtLives,TxtInvincible,TxtStage,TxtFull,TxtSkip,TxtSound,TxtExit
TxtLives:       dc.b    "infinite lives",0
TxtInvincible:  dc.b    "invincibility",0
TxtStage:       dc.b    "start stage",0
TxtFull:        dc.b    "full weapons",0
TxtSkip:        dc.b    "stage skip key n",0
TxtSound:       dc.b    "sound effect",0
TxtExit:        dc.b    "exit",0

;==============================================================================
; Menu state (reset each time the title loads it)
;==============================================================================
MenuPage:       dc.b    PG_ATTRACT
MenuItem:       dc.b    0
MenuRepeat:     dc.b    0
SoundNum:       dc.b    0
                even
MenuEnd:
                ifgt    MenuEnd-MENU_LIMIT
                fail    "the menu is over its space (MENU_LIMIT)"
                endc
