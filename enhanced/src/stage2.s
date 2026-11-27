;==============================================================================
; R-Type (Amiga, Electric Dreams 1989 - Factor 5 / Rainbow Arts)
; Stage-2 loader / credits sequence  -  ENHANCED: in the boot file, run by the bootblock
;
; ENHANCED: the files are read from the AmigaDOS disk with the 4489_byteloader
; and unpacked (ZX0) in place, in place of the original's LoadTracks; the
; file table the build tool writes into S2FileTable is copied into the game
; (GAME_FILETABLE) once the game program is loaded.  tools/build.py
; assembles it (with build/layout.i).
;
; Entry (from the bootblock):
;   D0 = MemBase   fast/slow memory block (64K aligned) or 0
;   D1 = MemLimit  end of that block
;   D2 = the drive booted from (0-3)
;
; Overview
; --------
;  * Unpacks the title picture + font ($A3C0 bytes, ZX0-packed in the boot
;    file just before stage 2) to $35FA0.  (Enhanced: the boot file is the
;    packed picture then stage 2, ending at $7A7A0 as the original's boot
;    read did; STAGE2_ORG and PIC_PACKED come from build/layout.i.)
;  * Enters supervisor mode via TRAP #0 and takes over the machine:
;    all DMA/interrupts off, own level-2 (keyboard) and level-3 (VBL) handlers,
;    stack at $40B60, a copper list showing a 320x200x5 screen at $35FA0.
;  * Runs a small state machine from the main loop, one state call each time
;    StateDelay frames have passed (VBL counter):
;      1 FadeInTitle    fade colours 0-31 up to TitlePalette
;      2 LoadGame       read the music (file FID_MUSIC -> $52300, copied to
;                       MemBase if present), start Chris Huelsbeck's title
;                       tune (replay at $52324 called from the VBL), then read
;                       the game: FID_GAMELOW -> $000A4 (and the file table
;                       copied into it), FID_GAMEMAIN -> $06000, and
;                       FID_RESIDENT -> RES_ORG (the cheats, resident.s)
;      3 FadeOutCredits fade colours 16-31 to black, clear the text window,
;                       install the credits text palette
;      4 Credits        type out the credits line by line, scrolling the
;                       text window up between lines (fire/key aborts)
;      5 FadeOutText    fade colours 16-31 to black, restore the picture
;                       under the text window
;      6 FadeInPicture  fade colours 16-31 back to TitlePalette
;      7 StartGame      jump to the game at $C0
;  * The VBL handler keeps running after the jump: the game sets the byte
;    pointed to by A0 (GameFadeFlag) and waits for it to clear; the handler
;    then fades the title out (one step every 6 frames), clears the flag and
;    switches bitplane/copper/blitter DMA off.
;
; The files (enhanced): read from their place on the AmigaDOS disk
; (S2FileTable) with the 4489_byteloader into an MFM buffer at TRACK_BUFFER
; ($32000, $1760 words), and unpacked in place (ZX0) - see LoadFile.
;==============================================================================

; --- Custom chips ------------------------------------------------------------
CUSTOM          equ     $DFF000
DMACONR         equ     $002
INTENAR         equ     $01C
INTREQR         equ     $01E
DSKPTH          equ     $020
DSKLEN          equ     $024
POTGO           equ     $034
BLTCON0         equ     $040
BLTCON1         equ     $042
BLTAFWM         equ     $044
BLTAPTH         equ     $050
BLTDPTH         equ     $054
BLTSIZE         equ     $058
BLTAMOD         equ     $064
BLTDMOD         equ     $066
BLTADAT         equ     $074
DSKSYNC         equ     $07E
COP1LCH         equ     $080
COPJMP1         equ     $088
DMACON          equ     $096
INTENA          equ     $09A
INTREQ          equ     $09C
ADKCON          equ     $09E
SPR0DATA        equ     $144

; --- CIAs --------------------------------------------------------------------
CIAA_PRA        equ     $BFE001         ; /FIR1 /FIR0 /RDY /TK0 /WPRO /CHNG
CIAA_SDR        equ     $BFEC01
CIAA_ICR        equ     $BFED01
CIAA_CRA        equ     $BFEE01
CIAB_PRB        equ     $BFD100         ; /MTR /SEL3-0 /SIDE DIR /STEP

; --- Memory map used here ----------------------------------------------------
BOOT_LOAD       equ     $6EFA0          ; where the bootblock put us
SCREEN          equ     $35FA0          ; 320x200, 5 planes
PLANE_SIZE      equ     $1F40           ; 40 bytes x 200 lines
FONT            equ     $3FBE0          ; 8x8 font, 5 planes x $180 bytes
SCREEN_END      equ     $40360          ; SCREEN + $A3C0 (picture + font)
STACK_TOP       equ     $40B60
TEXT_SAVE       equ     $35000          ; 5 x $320 bytes: picture under the
                                        ; text window
TEXT_WINDOW     equ     $37710          ; plane 0 address of the 16x50 window
TEXT_CURSOR     equ     $37DA1          ; where each credits line is printed
TRACK_BUFFER    equ     $32000          ; raw MFM DMA buffer

MUSIC           equ     $52300          ; music + replay (FID_MUSIC)
MUSIC_END       equ     $71A3C          ; end of the part copied to MemBase
MUSIC_SIZE      equ     MUSIC_END-MUSIC ; $1F73C
MUSIC_PLAY      equ     MUSIC+$24       ; call once per frame
MUSIC_START     equ     MUSIC+$2C       ; d0 = song number
MUSIC_INIT      equ     MUSIC+$34       ; d0/d1 = data pointers
MUSIC_INIT_D0   equ     $6FD28          ; TFMX mdat ("TFMX-SONG" header)
MUSIC_INIT_D1   equ     $53768          ; TFMX smpl
; The music file is Chris Huelsbeck's TFMX: an AmigaDOS executable replay
; ($52300, hunk header still in place - code at $52320, jump table entries
; +4 play, +$C start song, +$14 init), then smpl ($53768) and mdat
; ($6FD28).  See docs/MUSIC.md.

GAME_LOW        equ     $000A4          ; the engine (FID_GAMELOW)
GAME_MAIN       equ     $06000          ; the $6000 block (FID_GAMEMAIN)
GAME_ENTRY      equ     $000C0

TRACK_BYTES     equ     $1750

;==============================================================================
                include "files.i"
                include "layout.i"      ; (build/: GAME_FILETABLE)

                org     STAGE2_ORG      ; (build/layout.i: so that it ends at $7A7A0)

;------------------------------------------------------------------------------
; Stage2Entry - from the bootblock (still in user mode, OS running)
;------------------------------------------------------------------------------
Stage2Entry:
                move.w  d2,BootDrive            ; the drive the disk is in
                move.l  d0,MemBase              ; music goes here if non-zero
                beq.b   .nofast
                addi.l  #MUSIC_SIZE,d0          ; free memory after the music
.nofast:        move.l  d0,CacheBase            ; -> game track cache start
                move.l  d1,MemLimit
        ; unpack the title picture + font (packed in the boot file, just
        ; before stage 2) to the screen, out of the way of the disk data
                lea     (PIC_PACKED).l,a0
                lea     (SCREEN).l,a1
                bsr.w   zx0_decompress
                move.w  #$FF00,(CUSTOM+POTGO).l ; joystick button 2 lines as outputs
                move.l  #Supervisor,($80).l     ; TRAP #0 vector
                trap    #0                      ; never returns

;------------------------------------------------------------------------------
; WaitVBL - poll for vertical blank (not called)
;------------------------------------------------------------------------------
WaitVBL:        move.l  d0,-(a7)
.wait:          move.w  (CUSTOM+INTREQR).l,d0
                andi.w  #$0020,d0
                beq.b   .wait
                move.w  #$0020,(CUSTOM+INTREQ).l
                move.l  (a7)+,d0
                rts

;------------------------------------------------------------------------------
; CheckAbort - any new key press or either fire button
;   out: d0 = -1 (N set) to abort, 0 otherwise.  d1 = keyboard state from
;        ReadKey (PrintLine relies on it being non-zero when no key is down)
;------------------------------------------------------------------------------
CheckAbort:     bsr.w   ReadKey
                tst.b   d0
                bne.b   .abort
                moveq   #0,d0
                btst.b  #6,(CIAA_PRA).l         ; port 0 fire / left mouse
                beq.b   .abort
                btst.b  #7,(CIAA_PRA).l         ; port 1 fire
                beq.b   .abort
                moveq   #0,d0
                rts
.abort:         moveq   #-1,d0
                rts

;------------------------------------------------------------------------------
; Supervisor - TRAP #0 target: take over the hardware and run the sequence
;------------------------------------------------------------------------------
Supervisor:     move.w  #$2000,sr
                move.w  #$7FFF,(CUSTOM+DMACON).l
                move.w  #$7FFF,(CUSTOM+INTENA).l
                lea     (CUSTOM).l,a6
                clr.l   SPR0DATA+$00(a6)        ; blank all 8 sprites
                clr.l   SPR0DATA+$08(a6)
                clr.l   SPR0DATA+$10(a6)
                clr.l   SPR0DATA+$18(a6)
                clr.l   SPR0DATA+$20(a6)
                clr.l   SPR0DATA+$28(a6)
                clr.l   SPR0DATA+$30(a6)
                clr.l   SPR0DATA+$38(a6)
                move.l  #Level2Int,($68).l      ; keyboard
                move.l  #Level3Int,($6C).l      ; vertical blank
                movea.l #STACK_TOP,a7
                move.l  a7,SavedStack
                bsr.w   InitDisplay
                move.l  #CopperList,(CUSTOM+COP1LCH).l
                clr.w   (CUSTOM+COPJMP1).l
                move.w  #$83C0,(CUSTOM+DMACON).l ; DMAEN BPLEN COPEN BLTEN
                move.w  #$C028,(CUSTOM+INTENA).l ; INTEN VERTB PORTS
                bsr.w   SaveTextWindow

        ; --- main loop: call the current state every StateDelay frames ----
MainLoop:       clr.w   FrameCounter
                move.w  StateDelay,d0
.wait:          cmp.w   FrameCounter,d0
                bhi.b   .wait
                movea.l StateRoutine,a0
                jsr     (a0)
                bra.b   MainLoop

;------------------------------------------------------------------------------
; State 1: fade the whole title picture in
;------------------------------------------------------------------------------
St_FadeInTitle:
                move.l  #CopColours,FadeColours         ; colours 0-15
                bsr.w   FadeStep
                move.l  #CopColours+16*4,FadeColours    ; colours 16-31
                bsr.w   FadeStep
                cmpi.w  #15,d7                  ; all 16 reached target?
                bcs.b   .done
                move.l  #St_LoadGame,StateRoutine
                clr.w   StateDelay
.done:          rts

;------------------------------------------------------------------------------
; State 2: load music and game while the picture is shown
;------------------------------------------------------------------------------
St_LoadGame:
                moveq   #FID_MUSIC,d0           ; the music
                move.l  #MUSIC,d2
                bsr.w   LoadFile
                tst.l   MemBase                 ; extra memory? keep a copy
                beq.b   .nocopy                 ; of the music there
                lea     (MUSIC).l,a0
                movea.l MemBase,a1
                lea     (MUSIC_END).l,a2
.copy:          move.l  (a0)+,(a1)+
                cmpa.l  a0,a2
                bhi.b   .copy
.nocopy:        move.l  #MUSIC_INIT_D0,d0
                move.l  #MUSIC_INIT_D1,d1
                jsr     (MUSIC_INIT).l
                moveq   #0,d0                   ; song 0: title tune
                jsr     (MUSIC_START).l
                st.b    MusicOn                 ; VBL now calls the replay
                moveq   #FID_GAMELOW,d0         ; the game program -> $A4
                move.l  #GAME_LOW,d2
                bsr.w   LoadFile
                lea     S2FileTable,a0          ; give it the file table
                lea     (GAME_FILETABLE).l,a1
                move.w  #NFILES*FT_SIZE/4-1,d0
.ft:            move.l  (a0)+,(a1)+
                dbra    d0,.ft
                moveq   #FID_GAMEMAIN,d0        ; the $6000 graphics block
                move.l  #GAME_MAIN,d2
                bsr.w   LoadFile
                moveq   #FID_RESIDENT,d0        ; (enhanced) the cheats' hooks and
                move.l  #RES_ORG,d2             ; settings (resident.s, files.i)
                bsr.w   LoadFile
                move.l  #St_FadeOutCredits,StateRoutine
                move.l  #BlackPalette,FadeTarget
                move.b  #15,FadeCount
                move.w  #3,StateDelay
                rts

;------------------------------------------------------------------------------
; State 3: fade colours 16-31 out, prepare the text window
;------------------------------------------------------------------------------
St_FadeOutCredits:
                move.l  #CopColours+16*4,FadeColours
                bsr.w   FadeStep
                cmpi.w  #15,d7
                bcs.b   .done
                bsr.w   ClearTextWindow
                lea     TextPalette,a0          ; colours 16-31 = text palette
                lea     CopColours+16*4,a1
                moveq   #15,d0
.pal:           move.w  (a0)+,2(a1)
                addq.l  #4,a1
                dbra    d0,.pal
                move.l  #CreditsText,TextPtr
                move.l  #St_Credits,StateRoutine
.done:          rts

;------------------------------------------------------------------------------
; State 4: type the credits, one line then scroll the window up 9 pixels
;------------------------------------------------------------------------------
St_Credits:
                movea.l TextPtr,a0
                lea     (TEXT_CURSOR).l,a1
                moveq   #1,d2                   ; 1 frame per character
                bsr.w   PrintLine
                bmi.b   .end                    ; aborted
                addq.l  #1,a0                   ; skip the 0 terminator
                move.l  a0,TextPtr
                tst.b   (a0)                    ; $FF = end of text
                bmi.b   .end
                bsr.w   ScrollLine
                bmi.b   .end                    ; aborted
                bra.b   St_Credits
.end:           move.l  #St_FadeOutText,StateRoutine
                move.l  #BlackPalette,FadeTarget
                move.b  #15,FadeCount
                move.w  #2,StateDelay
                rts

;------------------------------------------------------------------------------
; State 5: fade the text out, put the picture back under the window
;------------------------------------------------------------------------------
St_FadeOutText:
                move.l  #CopColours+16*4,FadeColours
                bsr.w   FadeStep
                cmpi.w  #15,d7
                bcs.b   .done
                bsr.w   RestoreTextWindow
                move.l  #St_FadeInPicture,StateRoutine
                move.l  #TitlePalette,FadeTarget
                move.b  #15,FadeCount
                move.w  #3,StateDelay
.done:          rts

;------------------------------------------------------------------------------
; State 6: fade colours 16-31 back to the title palette
;------------------------------------------------------------------------------
St_FadeInPicture:
                move.l  #CopColours+16*4,FadeColours
                bsr.w   FadeStep
                cmpi.w  #15,d7
                bcs.b   .done
                move.l  #St_StartGame,StateRoutine
                clr.w   StateDelay
.done:          rts

;------------------------------------------------------------------------------
; State 7: start the game
;   d0 = first free byte of extra memory (after the music copy) or 0
;   d1 = end of extra memory
;   d2 = MemBase (music copy) or 0
;   d3 = current track under the head
;   a0 = GameFadeFlag (game sets it, VBL fades the title and clears it)
;------------------------------------------------------------------------------
St_StartGame:
                move.w  #$0008,(CUSTOM+INTENA).l ; keyboard interrupt off
                move.l  CacheBase,d0
                move.l  MemLimit,d1
                move.l  MemBase,d2
                move.w  BootDrive,d3            ; (the original: the head's track)
                lea     GameFadeFlag,a0
                jmp     (GAME_ENTRY).l

;------------------------------------------------------------------------------
; Blitter routines for the 128x50 text window (16 bytes of each 40-byte row)
;------------------------------------------------------------------------------
; ClearTextWindow - D = 0 (A channel off, BLTADAT = 0), 5 planes
ClearTextWindow:
                lea     (CUSTOM).l,a6
                move.l  #TEXT_WINDOW,d0
                move.w  #$01F0,BLTCON0(a6)      ; D only, D = A
                clr.w   BLTCON1(a6)
                move.l  #$FFFFFFFF,BLTAFWM(a6)
                move.w  #$0018,BLTDMOD(a6)      ; 40-16
                clr.w   BLTADAT(a6)
                move.w  #$8400,DMACON(a6)       ; blitter nasty on
                moveq   #4,d1
.plane:         move.l  d0,BLTDPTH(a6)
                move.w  #(50<<6)|8,BLTSIZE(a6)  ; $0C88: 50 lines x 8 words
.bw:            btst.b  #14,(CUSTOM+DMACONR).l    ; BBUSY (bit 14 mod 8 = bit 6)
                bne.b   .bw
                addi.l  #PLANE_SIZE,d0
                dbra    d1,.plane
                rts

; SaveTextWindow - copy the picture under the window to TEXT_SAVE
SaveTextWindow:
                lea     (CUSTOM).l,a6
                move.l  #TEXT_WINDOW,d0
                move.l  #TEXT_SAVE,d1
                move.w  #$09F0,BLTCON0(a6)      ; A -> D
                clr.w   BLTCON1(a6)
                move.l  #$FFFFFFFF,BLTAFWM(a6)
                move.w  #$0018,BLTAMOD(a6)
                clr.w   BLTDMOD(a6)
                move.w  #$8400,DMACON(a6)
                moveq   #4,d2
.plane:         move.l  d0,BLTAPTH(a6)
                move.l  d1,BLTDPTH(a6)
                move.w  #(50<<6)|8,BLTSIZE(a6)
.bw:            btst.b  #14,(CUSTOM+DMACONR).l
                bne.b   .bw
                addi.l  #PLANE_SIZE,d0
                addi.l  #$0320,d1               ; 16 x 50
                dbra    d2,.plane
                rts

; RestoreTextWindow - copy TEXT_SAVE back into the picture
RestoreTextWindow:
                lea     (CUSTOM).l,a6
                move.l  #TEXT_SAVE,d0
                move.l  #TEXT_WINDOW,d1
                move.w  #$09F0,BLTCON0(a6)
                clr.w   BLTCON1(a6)
                move.l  #$FFFFFFFF,BLTAFWM(a6)
                clr.w   BLTAMOD(a6)
                move.w  #$0018,BLTDMOD(a6)
                move.w  #$8400,DMACON(a6)
                moveq   #4,d2
.plane:         move.l  d0,BLTAPTH(a6)
                move.l  d1,BLTDPTH(a6)
                move.w  #(50<<6)|8,BLTSIZE(a6)
.bw:            btst.b  #14,(CUSTOM+DMACONR).l
                bne.b   .bw
                addi.l  #$0320,d0
                addi.l  #PLANE_SIZE,d1
                dbra    d2,.plane
                rts

; ScrollTextWindow - move the window up one pixel line (48 lines copied)
ScrollTextWindow:
                lea     (CUSTOM).l,a6
                move.l  #TEXT_WINDOW+$50,d0     ; source: 2 lines down
                move.l  #TEXT_WINDOW+$28,d1     ; dest:   1 line down
                move.w  #$09F0,BLTCON0(a6)
                clr.w   BLTCON1(a6)
                move.l  #$FFFFFFFF,BLTAFWM(a6)
                move.w  #$0018,BLTAMOD(a6)
                move.w  #$0018,BLTDMOD(a6)
                move.w  #$8400,DMACON(a6)
                moveq   #4,d2
.plane:         move.l  d0,BLTAPTH(a6)
                move.l  d1,BLTDPTH(a6)
                move.w  #(48<<6)|8,BLTSIZE(a6)  ; $0C08
.bw:            btst.b  #14,(CUSTOM+DMACONR).l
                bne.b   .bw
                addi.l  #PLANE_SIZE,d0
                addi.l  #PLANE_SIZE,d1
                dbra    d2,.plane
                rts

;------------------------------------------------------------------------------
; ScrollLine - scroll the window up 9 pixels, one per frame, then pause
;   out: d0 = -1 (N set) if aborted
;------------------------------------------------------------------------------
ScrollLine:     moveq   #8,d7
.line:          clr.w   FrameCounter
.wait:          cmpi.w  #1,FrameCounter
                bcs.b   .wait
                bsr.w   ScrollTextWindow
                bsr.w   CheckAbort
                bmi.b   .exit
                dbra    d7,.line
                clr.w   FrameCounter            ; pause 18 frames
.pause:         cmpi.w  #18,FrameCounter
                bcs.b   .pause
                moveq   #0,d0
.exit:          rts

;------------------------------------------------------------------------------
; InitDisplay - bitplane pointers into the copper list, first state
;------------------------------------------------------------------------------
InitDisplay:
                lea     CopBplPtrs,a1
                move.l  #SCREEN,d0
                move.w  #$00E0,d1               ; BPL1PTH
                moveq   #4,d2                   ; 5 planes
                move.l  #PLANE_SIZE,d3
                bsr.w   SetCopperPtrs
                move.l  #St_FadeInTitle,StateRoutine
                move.l  #TitlePalette,FadeTarget
                move.b  #15,FadeCount
                move.w  #4,StateDelay
                clr.b   MusicOn
                rts

;------------------------------------------------------------------------------
; Level2Int - CIA-A serial port: read the keyboard and handshake
;------------------------------------------------------------------------------
Level2Int:
                btst.b  #3,(CIAA_ICR).l         ; SP interrupt?
                beq.b   .exit
                move.l  d0,-(a7)
                move.b  (CIAA_SDR).l,d0
                move.b  d0,KeyRaw
                bset.b  #6,(CIAA_CRA).l         ; SPMODE output = handshake
                moveq   #54,d0
.hs:            dbra    d0,.hs
                bclr.b  #6,(CIAA_CRA).l
                move.l  (a7)+,d0
.exit:          move.w  #$0008,(CUSTOM+INTREQ).l
                rte

KeyLast:        dc.w    0               ; last key-down code reported
KeyRaw:         dc.b    0               ; raw byte from CIA-A SDR
                dc.b    0
                dc.w    0

;------------------------------------------------------------------------------
; ReadKey - out: d0 = new key-down code (0 if none / repeat / key-up)
;                d1 = decoded key byte (bit 7 = key up)
;------------------------------------------------------------------------------
ReadKey:        moveq   #0,d0
                moveq   #0,d1
                move.b  KeyRaw,d1
                not.b   d1                      ; keyboard sends inverted,
                ror.b   #1,d1                   ; rotated codes
                bmi.b   .store                  ; key up: forget last key
                cmp.w   KeyLast,d1
                beq.b   .exit                   ; still held
                move.b  d1,d0
.store:         move.w  d0,KeyLast
.exit:          rts

;------------------------------------------------------------------------------
; Level3Int - vertical blank: frame counter, music, game hand-over fade
;------------------------------------------------------------------------------
Level3Int:
                movem.l d0-d7/a0-a6,-(a7)
                move.w  (CUSTOM+INTREQR).l,d0
                move.w  d0,-(a7)
                btst    #5,d0                   ; VERTB?
                beq.w   .exit
                addq.w  #1,FrameCounter
                tst.b   MusicOn
                beq.b   .nomusic
                jsr     (MUSIC_PLAY).l
.nomusic:       tst.b   GameFadeFlag            ; game asked for fade out?
                bpl.b   .exit
                subq.b  #1,GameFadeTimer
                bpl.b   .exit
                move.b  #5,GameFadeTimer        ; one step every 6 frames
                move.l  #BlackPalette,FadeTarget
                move.b  #15,FadeCount
                move.l  #CopColours,FadeColours
                bsr.w   FadeStep
                move.l  #CopColours+16*4,FadeColours
                bsr.w   FadeStep
                cmpi.w  #15,d7
                bcs.b   .exit
                clr.b   GameFadeFlag            ; tell the game we're done
                move.w  #$01C0,(CUSTOM+DMACON).l ; bitplanes, copper, blitter off
.exit:          move.w  (a7)+,d0
                andi.w  #$0070,d0               ; (enhanced: only its own level 3 bits -
                move.w  d0,(CUSTOM+INTREQ).l    ;  the original's $7FFF cleared DSKBLK too,
                                                ;  which the byteloader waits for)
                movem.l (a7)+,d0-d7/a0-a6
                rte

;------------------------------------------------------------------------------
; SetCopperPtrs - write MOVE pairs for a list of chip pointers
;   a1 = copper list, d0 = first address, d1 = first register (xxxPTH),
;   d2 = count-1, d3 = step
;------------------------------------------------------------------------------
SetCopperPtrs:  movem.l d0-d3,-(a7)
.loop:          swap    d0
                move.w  d1,(a1)+
                move.w  d0,(a1)+                ; high word
                addq.w  #2,d1
                swap    d0
                move.w  d1,(a1)+
                move.w  d0,(a1)+                ; low word
                addq.w  #2,d1
                add.l   d3,d0
                dbra    d2,.loop
                movem.l (a7)+,d0-d3
                rts

;------------------------------------------------------------------------------
; FadeStep - move each colour in a copper colour list one step towards a
; target palette (each of R, G, B by 1)
;   FadeColours = copper list (MOVE pairs), FadeTarget = palette words,
;   FadeCount   = colours-1
;   out: d7 = number of colours that now match the target
;------------------------------------------------------------------------------
FadeStep:       moveq   #15,d0
                moveq   #0,d7
                moveq   #0,d1
                move.b  FadeCount,d1
                movea.l FadeTarget,a0
                movea.l FadeColours,a1
.colour:        moveq   #2,d2                   ; B, G, R
                moveq   #$0F,d5                 ; nibble mask
                moveq   #1,d6                   ; nibble step
.gun:           move.w  (a0),d3
                move.w  2(a1),d4
                and.w   d5,d3
                and.w   d5,d4
                cmp.w   d3,d4
                beq.b   .next
                bhi.b   .down
                add.w   d6,2(a1)
                bra.b   .next
.down:          sub.w   d6,2(a1)
.next:          lsl.w   #4,d5
                lsl.w   #4,d6
                dbra    d2,.gun
                move.w  (a0),d3
                cmp.w   2(a1),d3
                bne.b   .notyet
                addq.w  #1,d7
.notyet:        addq.l  #2,a0
                addq.l  #4,a1
                dbra    d1,.colour
                rts

;------------------------------------------------------------------------------
; PrintLine - type a 0-terminated string with a "_" cursor
;   a0 = text, a1 = screen position, d2 = frames per character
;   out: N set / d0 = -1 if aborted, a0 -> terminator
;------------------------------------------------------------------------------
PrintLine:      tst.b   (a0)
                beq.w   .exit
                bsr.w   CheckAbort
                bmi.b   .exit
                tst.w   d1
                beq.b   .nocursor
                move.b  #'_',d0                 ; cursor in this cell
                bsr.w   DrawChar
                clr.w   FrameCounter
.wait:          cmp.w   FrameCounter,d2
                bhi.b   .wait
.nocursor:      move.b  (a0)+,d0                ; then the real character
                bsr.w   DrawChar
                addq.l  #1,a1
                bra.b   PrintLine
.exit:          rts

;------------------------------------------------------------------------------
; DrawChar - draw an 8x8, 5-plane character
;   d0 = ASCII, a1 = screen byte address (plane 0)
;   Characters not in CharMap map to the entry after the table (blank).
;------------------------------------------------------------------------------
DrawChar:       movem.l a0-a1,-(a7)
                lea     CharMap,a0
.find:          cmp.b   (a0),d0
                beq.b   .found
                tst.b   (a0)+
                bne.b   .find
                subq.l  #1,a0                   ; not found: use the 0 entry
.found:         move.l  a0,d0
                subi.l  #CharMap,d0             ; index
                lsl.w   #3,d0                   ; x 8 bytes
                lea     (FONT).l,a0
                adda.l  d0,a0
                moveq   #7,d0
.row:           move.b  0(a0),0(a1)
                move.b  $180(a0),PLANE_SIZE*1(a1)
                move.b  $300(a0),PLANE_SIZE*2(a1)
                move.b  $480(a0),PLANE_SIZE*3(a1)
                move.b  $600(a0),PLANE_SIZE*4(a1)
                addq.l  #1,a0
                adda.l  #40,a1
                dbra    d0,.row
                movem.l (a7)+,a0-a1
                rts

;==============================================================================
; Track loader
;==============================================================================
;------------------------------------------------------------------------------
; LoadFile - d0 = file id, d2 = destination.  The file's blocks (OFS: a
;   24-byte header and 488 bytes of the file each) are read so that they end
;   where the file must end - dest + its length, or for a packed file dest +
;   its unpacked end - and the headers squeezed out (OFSCompact); a packed
;   file is then unpacked forwards to dest.  A read that fails is tried
;   again; after 8 failures COLOR00 turns red while it keeps trying.
;------------------------------------------------------------------------------
LoadFile:       movem.l d0-d7/a0-a6,-(a7)
                lea     S2FileTable,a2
                mulu.w  #FT_SIZE,d0
                adda.w  d0,a2
                movea.l d2,a3                   ; destination
                move.l  4(a2),d4                ; its length
                move.l  8(a2),d5                ; packed: where it must end
                bne.b   .end
                move.l  d4,d5                   ; stored: dest + length
.end:           lea     (a3,d5.l),a4            ; a4 = where its bytes end
                move.l  d4,d0                   ; its blocks
                add.l   #487,d0
                divu.w  #488,d0
                moveq   #0,d6
                move.w  d0,d6                   ; d6 = blocks
                move.l  d6,d1
                lsl.l   #8,d1
                add.l   d1,d1                   ; d1 = their size on the disk
                movea.l a4,a5
                suba.l  d1,a5                   ; a5 = where they are read to
                moveq   #0,d7                   ; failures
.try:           movem.l d1/d4/d6-d7/a2-a5,-(a7)
                move.l  (a2),d0                 ; offset
                moveq   #0,d2
                move.w  BootDrive,d2
                movea.l a5,a0
                lea     (TRACK_BUFFER).l,a1     ; $1760 words of MFM buffer
                bsr.w   ByteLoader
                move.l  d0,d3
                movem.l (a7)+,d1/d4/d6-d7/a2-a5
                tst.l   d3
                beq.b   .ok
                addq.w  #1,d7
                cmp.w   #8,d7
                bcs.b   .try
                move.w  #$F00,(CUSTOM+$180).l
                bra.b   .try
.ok:            subq.w  #1,d6                   ; blocks - 1
                move.w  d6,d0
                mulu.w  #488,d6
                move.l  d4,d2
                sub.l   d6,d2                   ; d2 = bytes in the last block
                moveq   #0,d1
                move.w  d0,d1
                lsl.l   #8,d1
                add.l   d1,d1
                lea     24(a5,d1.l),a0          ; the end of the last block's data
                adda.l  d2,a0
                movea.l a4,a1
                move.w  d2,d1
                bsr.b   OFSCompact
                tst.l   8(a2)                   ; packed?
                beq.b   .done
                movea.l a4,a0                   ; unpack from its start
                suba.l  d4,a0
                movea.l a3,a1
                bsr.w   zx0_decompress
.done:          movem.l (a7)+,d0-d7/a0-a6
                rts

; OFSCompact: a0 = the end of the last block's data, a1 = where the file
; must end, d0.w = blocks - 1, d1.w = bytes in the last block: each block's
; bytes moved up, from the last back, to lie together ending at a1.
OFSCompact:
.blk:           subq.w  #1,d1
.cp:            move.b  -(a0),-(a1)
                dbra    d1,.cp
                lea     -24(a0),a0              ; skip the block's header
                move.w  #488,d1
                dbra    d0,.blk
                rts

; the 4489_byteloader: d0 = offset, d1 = length, d2 = drive, a0 = destination,
; a1 = MFM buffer -> d0 = 0 if it worked; uses every register
ByteLoader:
                include "byteloader.i"
                even
; the ZX0 decompressor: a0 = packed data, a1 = destination (salvador's default format)
                include "unzx0.s"

;==============================================================================
; Variables
;==============================================================================
BootDrive:      dc.w    0               ; the drive booted from (bootblock)
FadeTarget:     dc.l    0               ; palette to fade towards
FadeColours:    dc.l    0               ; copper colour MOVEs being faded
SavedStack:     dc.l    0
StateRoutine:   dc.l    0
TextPtr:        dc.l    0
CacheBase:      dc.l    0               ; -> game d0
MemLimit:       dc.l    0               ; -> game d1
MemBase:        dc.l    0               ; -> game d2
FrameCounter:   dc.w    0
StateDelay:     dc.w    0
GameFadeFlag:   dc.b    0               ; set by the game: fade title out
GameFadeTimer:  dc.b    1
FadeCount:      dc.b    0               ; colours-1
MusicOn:        dc.b    0

;------------------------------------------------------------------------------
; Character set order of the font at $3FBE0 (index = position)
;------------------------------------------------------------------------------
CharMap:        dc.b    "abcdefghijklmnopqrstuvwxyz0123456789.,-_!?HC<SE "
                dc.b    0

;------------------------------------------------------------------------------
; Credits: 0-terminated lines, $FF ends the list
;------------------------------------------------------------------------------
CreditsText:    dc.b    "   electric   ",0
                dc.b    "    dreams    ",0
                dc.b    "   presents   ",0
                dc.b    "              ",0
                dc.b    "    r-type    ",0
                dc.b    "              ",0
                dc.b    "amiga  version",0
                dc.b    " developed by ",0
                dc.b    "   factor 5   ",0
                dc.b    "              ",0
                dc.b    " produced  by ",0
                dc.b    " rainbow arts ",0
                dc.b    "              ",0
                dc.b    "              ",0
                dc.b    " title  music ",0
                dc.b    "    chris     ",0
                dc.b    "  huelsbeck   ",0
                dc.b    "              ",0
                dc.b    "              ",0
                dc.b    "  game music  ",0
                dc.b    "    darius    ",0
                dc.b    "    zendeh    ",0
                dc.b    "              ",0
                dc.b    "              ",0
                dc.b    " tool  coding ",0
                dc.b    "thomas fanslau",0
                dc.b    "holger schmidt",0
                dc.b    "willi  baecker",0
                dc.b    "              ",0
                dc.b    "              ",0
                dc.b    "st graphics by",0
                dc.b    "  mark jones  ",0
                dc.b    "              ",0
                dc.b    "              ",0
                dc.b    "  thanks to   ",0
                dc.b    " rob  hylands ",0
                dc.b    "     and      ",0
                dc.b    " karl jeffery ",0
                dc.b    "              ",0
                dc.b    $FF,0

;------------------------------------------------------------------------------
; Copper list
;------------------------------------------------------------------------------
CopperList:     dc.w    $0092,$0038             ; DDFSTRT
                dc.w    $0094,$00D0             ; DDFSTOP
                dc.w    $008E,$2C81             ; DIWSTRT
                dc.w    $0090,$F4C1             ; DIWSTOP (200 lines)
                dc.w    $0104,$0024             ; BPLCON2
                dc.w    $0108,$0000             ; BPL1MOD
                dc.w    $010A,$0000             ; BPL2MOD
                dc.w    $0100,$5200             ; BPLCON0: 5 planes, colour
                dc.w    $0102,$0000             ; BPLCON1
CopColours:
COLREG          set     $0180
                rept    32
                dc.w    COLREG,$0000            ; COLOR00-31, start black
COLREG          set     COLREG+2
                endr
CopBplPtrs:     dcb.w   5*4,0                   ; BPL1PTH..BPL5PTL (InitDisplay)
                dc.w    $FFFF,$FFFE

;------------------------------------------------------------------------------
; Palettes
;------------------------------------------------------------------------------
TitlePalette:   dc.w    $0000,$0005,$0339,$077D,$09BF,$0FFF,$0530,$0950
                dc.w    $0B90,$0FD0,$0050,$0590,$09D0,$0700,$0B03,$0F35
BlackPalette:   dcb.w   32,0
TextPalette:    dc.w    $0000,$0227,$055A,$077D,$09BF,$0FFF,$0530,$0950
                dc.w    $0B90,$0FD0,$0050,$0590,$09D0,$0700,$0B03,$0F35

;==============================================================================
; The file table: written here by tools/build.py once the disk is laid out
; (NFILES entries of FT_SIZE: offset, length on the disk, unpacked end or 0).
;==============================================================================
                even
S2FileTable:
                dcb.b   NFILES*FT_SIZE,0
