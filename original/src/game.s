;==============================================================================
; R-Type (Amiga, Electric Dreams 1989 - Factor 5 / Rainbow Arts)
; Game program  -  tracks 32-35, loaded by stage 2 to $000A4
;
; Assembles byte-identical to files/game_low_000a4.bin ($5D40 bytes) with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -o game_low.bin src/game.s
;
; This is the whole game engine.  The $6000 block (tracks 36-62) is graphics
; and sound data only; per-level code and data are loaded to $4A2E4 (level A)
; and $4D300 (level B, crunched).  See docs/GAME.md.
;
; Status: every routine is separated from data, every label is named and
; every routine has a header comment; the core loop, interrupts, scrolling,
; objects, collisions, the ship and the weapons have line comments.  Local
; .xxxxx labels keep the address they were found at.
;==============================================================================

; --- Custom chips / CIAs -------------------------------------------------------
CUSTOM          equ     $DFF000
DMACONR         equ     $002
VHPOSR          equ     $006
JOY1DAT         equ     $00C          ; joystick port 2
INTREQR         equ     $01E
DMACON          equ     $096
INTENA          equ     $09A
INTREQ          equ     $09C
CIAA_PRA        equ     $BFE001
CIAA_DDRA       equ     $BFE201
CIAA_SDR        equ     $BFEC01
CIAA_ICR        equ     $BFED01
CIAA_CRA        equ     $BFEE01
CIAA_CRB        equ     $BFEF01
CIAB_PRB        equ     $BFD100
CIAB_DDRA       equ     $BFD200
CIAB_DDRB       equ     $BFD300
CIAB_ICR        equ     $BFDD00
CIAB_CRA        equ     $BFDE00
CIAB_CRB        equ     $BFDF00

; --- Memory map ----------------------------------------------------------------
SCREEN_A        equ     $2D1BA          ; double-buffered playfield
SCREEN_B        equ     $3AEBA
LEVEL_A         equ     $4A2E4          ; level part A (ST header + level code)
LEVEL_B_CRUNCHED equ    $4CB00
LEVEL_B         equ     $4D300          ; level part B, decrunched (tiles, ...)
MUSIC           equ     $52300
MUSIC_PLAY      equ     MUSIC+$24
MUSIC_START     equ     MUSIC+$2C
MUSIC_INIT      equ     MUSIC+$34
TRACK_BUFFER    equ     $7C400          ; raw MFM buffer

; --- The $6000 block (tracks 36-62): graphics and sound only ----------------
;   $06000-$064FF ship sprite frames      $06500-$069CF Bit sprite frames
;   $06A40-$0847F Force sprite frames (4 power levels, see UpdateForce)
;   $08480-$0873F 16x11 diagonal/vertical shots (ShotTypes 1-4)
;   $08740-$0B43F explosions (DefExplosion1/2)
;   $0B440-$10A4F large explosion         $10A50-$1248F ring burst
;   $12490-$1294F speed-up flash          $12950-$1564F anti-air laser (helix)
;   $15650-$15A4F 32x4 shot streams       $15A50-$17ACF POW Armor
;   $17AD0-$189CF power-up items          $189D0-$19B8F wave cannon shots
;   $19B90-$19D8F lasers                  $19D90-$1A2CF enemy bullets
;   $1A2D0-$1C2CF homing missiles (16 directions x 2 frames)
;   $1C2D0-$1C64F laser frames            $1C650-$1C689 POW Armor jump arc
;   $1C68A-$2C7AF sound effect samples
;   $2C7B0-$2CEB7 HUD bitplanes (3 x $258)
; Details: docs/GRAPHICS.md, rendered in gfx/engine_bobs.png and gfx/sprites_*

; --- Level interface: table at $4A300 (start of level A's TEXT) ----------------
LV_Entry        equ     $4A300          ; shared file: jingle player code
                                        ; level files: magic $03011969
LV_Waves        equ     $4A304          ; -> enemy wave list (scroll pos, ptr)
LV_Palette      equ     $4A308          ; -> 15 colours
LV_Map          equ     $4A30C          ; -> tile map
LV_Tiles        equ     $4A310          ; -> tile graphics (level B)
LV_ScrollScript equ     $4A314          ; -> scroll speed script
LV_TileAnims    equ     $4A318          ; -> animated-tile routines
LV_MapPatches   equ     $4A31C          ; -> map patch list (or 0)
LV_Frame        equ     $4A320          ; -> per-frame level routine
LV_Init         equ     $4A324          ; -> level start routine
LV_Music        equ     $4A328          ; -> music player (inside level B)
LV_EndMusic     equ     $4A32C          ; -> ending music (level 8 only; in
                                        ;    levels 1-7 the scroll script
                                        ;    starts here instead)

                org     $A4

;==============================================================================
; Atari ST style program header ($601A). The Amiga build keeps
; the ST executable layout: TEXT $000C0-$041B3, DATA $041B4-$05C65.
;==============================================================================
ProgramHeader:
                bra.b   GameEntry               ; $601A
                dc.l    $000040F4               ; TEXT size  ($000C0-$041B3)
                dc.l    $00001AB2               ; DATA size  ($041B4-$05C65)
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
                dc.l    $000000C0               ; load/entry address
                dc.w    $0001                   ; absolute: no relocation

;==============================================================================
; Entry point and jump table (used by the level code at $4A300+)
;==============================================================================
; GameEntry: from stage 2: d0 cache base, d1 limit, d2 music copy, d3 track, a0 fade flag
GameEntry:
                bra.b   Init
jt_ObjInsert:
                bra.w   ObjInsert
jt_ObjKillSelf:
                bra.w   ObjKillSelf
jt_ObjCreate:
                bra.w   ObjCreate
jt_ObjAlloc:
                bra.w   ObjAlloc
jt_Random:
                bra.w   Random
jt_GetMapCell:
                bra.w   GetMapCell
jt_FireEnemyBullet:
                bra.w   FireEnemyBullet
jt_DirectionTo:
                bra.w   DirectionTo
jt_TurnTowards:
                bra.w   TurnTowards
jt_AddScore:
                bra.w   AddScore
jt_AdjustForScroll:
                bra.w   AdjustForScroll

;==============================================================================
; Variables shared with the level code
;==============================================================================
ShipPos:
                dc.w    $0000,$0000
; MapRowBytes.l ($F2) and MapWidth.w ($F4) overlap: NewGame clears the long,
; LoadLevel writes the level table's value to MapWidth, so MapRowBytes = the
; map row length in bytes (2 per cell).  Level 1: 536 bytes = 268 tiles.
MapRowBytes:
                dc.w    $0000
MapWidth:
                dc.w    $0208
ScrollX:
                dc.w    $0000
ScrollActive:
                dc.b    $00
LevelComplete:
                dc.b    $00
ScoreToAdd:
                dc.w    $0000,$0000
ScoreToAddEnd:                          ; (end of ScoreToAdd, for ABCD)
PalettePtr:                             ; -> the copper list's COLOR01 move: level
                dc.l    CopColours-2            ; code flashes colours through it
ScrollY:
                dc.w    $0000
MusicFadeReq:
                dc.b    $00
ShipMode:
                dc.b    $00
MusicRequest:
                dc.b    $00
JingleState:
                dc.b    $00
EndSequence:
                dc.b    $00
EndSequenceFlags:
                dc.b    $00
jt_PlaySound:
                bra.w   PlaySound

;==============================================================================
; Start-up
;==============================================================================
Init:
                lea.l   (StackTop).l,a7
                move.l  a0,-(a7)
                move.l  d0,(CacheBase).l
                move.l  d1,(CacheLimit).l
                move.l  d2,(MusicCopy).l
                move.w  d3,(CurrentTrack).l
                move.l  (CacheBase).l,(CacheNext).l
                bsr.w   LoadHighScores
                bsr.w   FormatScores
                bsr.w   LoadShared
                movea.l (a7)+,a0
                st.b    (a0)
.00148:
                tst.b   (a0)
                bne.b   .00148
                moveq   #1,d7
                bsr.w   ClearScreens
                bsr.w   InitHardware
                move.l  #Level2Int,($68).w
                move.l  #SCREEN_A,(DrawBuffer).l
                move.l  #$6A40,(ForceFrame).l      ; Force sprite frames ($6000 block)
                move.l  #Force_Idle,(ForceState).l
                clr.l   (Score).l
                clr.b   (ForceActive).l
                st.b    (TitleMusicOn).l
                move.l  #Level3Int,($6C).w
                move.l  #Level4Int,($70).w
                move.l  #CopperList,$80(a6)
                clr.w   $88(a6)
                move.w  #$87F0,$96(a6)
                move.w  #$3FCF,$9C(a6)
                move.w  #$C038,$9A(a6)
                move.w  #$2000,sr

;==============================================================================
; Attract mode / new game
;==============================================================================
NewGame:
                clr.w   (ScrollBplcon1).l
                clr.w   (CopBplcon1).l
                clr.w   (EndSequence).l
                clr.b   (ShipMode).l
                st.b    (ShipHit).l
                clr.b   (Paused).l
                move.w  #$ECC1,$90(a6)
                bsr.w   PaletteBlack
                bsr.w   TitleSequence
                move.w  #$780,$9C(a6)
                move.w  #$8600,$9A(a6)
                bsr.w   PalCheck
                move.l  (TopScore).l,d0
                lea.l   ($2C905).l,a0
                bsr.w   DrawDigits
                move.w  #$FCC1,$90(a6)
                moveq   #0,d0
                lea.l   ($2C8F9).l,a0
                bsr.w   DrawDigits
                clr.l   (Score).l
                clr.l   (Bonus).l
                addq.b  #$1,(GamesPlayed).l
                clr.b   (Flip50Hz).l
                clr.w   (EndSequence).l
                move.l  #ExtraLifeTable,(ExtraLifePtr).l
                clr.l   (ScoreToAdd).l
                clr.l   (MapRowBytes).l
                clr.b   (NewLifeFlag).l
                clr.b   (Level).l
                clr.b   (ShipSpawned).l
                clr.b   (ShipAlive).l
                clr.w   (MusicRequest).l
                clr.b   (MusicFadeReq).l
                move.l  #LevelTable,(LevelTablePtr).l
                move.b  #$4,(Continues).l
                move.w  #$1,(Lives).l
                bsr.w   DrawLives

;==============================================================================
; Level load and (re)start
;==============================================================================
; LoadLevel: load level from LevelTablePtr: A part, B part, decrunch
LoadLevel:
                movea.l (LevelTablePtr).l,a4
                movem.w (a4)+,d0-d1
                move.l  #LEVEL_A,d2
                bsr.w   LoadTracksCached
                movem.w (a4)+,d0-d1
                move.l  #LEVEL_B_CRUNCHED,d2
                bsr.w   LoadTracksCached
                move.w  (a4)+,(MapWidth).l
                move.l  a4,(LevelTablePtr).l
                lea.l   (LEVEL_B).l,a1
                lea.l   (LEVEL_B_CRUNCHED).l,a0
                bsr.w   Decrunch
                move.l  (MapRowBytes).l,d0
                bsr.w   PaletteBlack
                bsr.w   BuildMapRows
                bsr.w   InitMapOffsets
                clr.b   (ShipHit).l
                clr.b   (ShipMode).l
                clr.w   (ScrollX).l
                clr.w   (Checkpoint).l
                clr.w   (ScrollY).l
                clr.b   (ScrollActive).l
                clr.b   (LevelComplete).l
                clr.b   (StageEndStarted).l
                clr.b   (StageFlags).l
                clr.b   (Paused).l
StartLevel:
                bsr.w   ClearPlayfield
                bsr.w   InitObjects
                bsr.w   SpawnShip
                bsr.w   ApplyMapPatches
                bsr.w   InitLevelScroll

;==============================================================================
; Main loop: one game frame, then wait for the VBL to swap
;==============================================================================
; Frame pacing.  The main loop never waits for the VBL itself: it builds a
; frame into DrawBuffer, sets FrameReady and spins until the copper interrupt
; (SwapScreens) has shown it.  During play Flip50Hz is clear, so a flip can
; only happen every second VBL: the game is locked to 25 Hz.  The ship and
; the Bits are hardware sprites moved from the VBL (ShipControl, UpdateBits)
; twice per game frame, so they still move smoothly at 50 Hz.  The title and
; high-score screens set Flip50Hz and run at 50 Hz.
MainLoop:
                tst.b   (FrameReady).l              ; last frame still waiting to be shown?
                bne.w   CheckEndOfGame              ; yes: don't draw over it, just loop
                movea.l (GameState).l,a0            ; current state: fade-in / playing / ...
                jmp     (a0)                        ; every state ends up in GameFrame
St_LevelFadeIn:
                bsr.w   LevelFadeInStep
St_PlayStart:
                btst.b  #$6,(StageFlags).l          ; intro finished (ship in control)?
                beq.b   GameFrame
                move.l  #St_Playing,(GameState).l   ; then switch to normal play
St_Playing:
                tst.b   (ShipHit).l                 ; set by bullet/enemy/map collisions
                beq.b   .00372
                bsr.w   ShipDied                    ; explosion, lives, restart at checkpoint
                bra.b   GameFrame
.00372:
                tst.b   (LevelComplete).l           ; set by the level code (boss dead)
                beq.b   .00380
                bsr.w   StageEndSequence            ; ship flies off, bonus, next level
                bra.b   GameFrame
.00380:
                bsr.w   SpawnWaves                  ; start enemy waves due at this scroll position
                bsr.w   ShipFire                    ; fire button: shots, wave cannon charge
GameFrame:
                bsr.w   UpdateScroll                ; advance ScrollX/ScrollY by the scroll script
                bsr.w   DrawMap                     ; redraw all 20x13 background tiles
                lea.l   ($48C62).l,a5               ; a5 = screen line offset table for BlitBob
                move.l  #$FFFF0000,$44(a6)          ; BLTAFWM/LWM: last word masked off (shift word)
                move.l  #$FFFEFFFE,$62(a6)          ; BLTBMOD/AMOD = -2: source 1 word narrower
                bsr.w   UpdateShots                 ; ship shots + Force shots
                bsr.w   UpdateWaveBeam              ; charged beam, shot streams, anti-air laser
                bsr.w   UpdateObjects               ; every enemy: its routine, explosion, hits, firing, draw
                bsr.w   UpdateEnemyBullets          ; 16 aimed bullets
                bsr.w   UpdateMissiles              ; homing missiles
                bsr.w   ShipHitsMap                 ; ship against solid map cells
                movea.l (LV_Frame).l,a0             ; level-specific work for this frame
                jsr     (a0)
                bsr.w   UpdateScore                 ; HUD score and extra lives
FrameDone:
                st.b    (FrameReady).l              ; frame complete: CopperInt flips to it
.003d0:
                tst.b   (Paused).l                  ; P pauses here, after a whole frame
                bne.b   .003d0
CheckEndOfGame:
                btst.b  #$3,(EndSequenceFlags).l    ; game finished (after level 8)?
                beq.w   MainLoop
                bsr.w   ClearPlayfield              ; yes: end text, wait, back to the title
                lea.l   (TextPalette).l,a1
                bsr.w   SetPalette
                lea.l   (TxtEnding).l,a4
                bsr.w   PrintList
                clr.l   (VblCount).l
                move.w  (VblCountLo).l,d0
                add.w   #$20D,d0
.0040c:
                cmp.w   (VblCountLo).l,d0
                bhi.b   .0040c
                clr.b   (JinglePlaying).l
                clr.b   (JingleCmd).l
                move.w  #$F,$96(a6)
                moveq   #0,d7
                bra.w   NewGame
; St_StageClear: "stage N cleared" and "stage score", then CountBonus
; rolls the bonus up digit by digit; when the jingle ends the next level
; loads.
St_StageClear:
                btst.b  #$7,(StageFlags).l
                beq.b   FrameDone
                bsr.w   ClearPlayfield
                lea.l   (TextPalette).l,a1
                bsr.w   SetPalette
                move.w  #$1000,d1
                lea.l   (TxtStageCleared).l,a0
                move.b  (Level).l,d0
                add.b   #$31,d0
                move.b  d0,$C(a0)
                lea.l   ($2FC05).l,a1
                bsr.w   PrintString
                move.w  #$1000,d1
                lea.l   (TxtStageScore).l,a0
                lea.l   ($31AEA).l,a1
                bsr.w   PrintString
                bsr.w   CountBonus
.0047e:
                st.b    (FrameReady).l
                tst.b   (JingleState).l
                bne.b   .0047e
                addq.b  #$1,(Level).l
                bra.w   LoadLevel

;==============================================================================
; Ship spawn, death and stage-end sequences
;==============================================================================
SpawnShip:
                tst.b   (ShipSpawned).l
                bne.w   SpawnShipDone
                st.b    (ShipSpawned).l
                move.w  #$2,(ShipSpeed).l
                move.w  #$76,(ShipY).l
                clr.b   (StageFlags).l
                bsr.w   ResetShipWeapons
                tst.b   (NewLifeFlag).l
                bne.b   ShipRespawn
                st.b    (NewLifeFlag).l
                move.b  #$3,(JingleState).l
                moveq   #10,d0
                moveq   #104,d1
                moveq   #-1,d2
                bsr.w   ObjAlloc
                move.l  #DefSpeedFlash,$12(a0)
                move.l  #ObjUpd_FlyInShip,$6(a0)
                move.l  #SpeedFlashAnim,$2A(a0)
                move.w  #$2D,$32(a0)
                bsr.w   ObjInsert
                move.b  #$1,(ShipMode).l
                st.b    (ShipAlive).l
                move.w  #$75,(ShipX).l
                move.b  #$10,(ShipTiltFrame).l
                move.l  #$6400,(ShipSpriteFrame).l
SpawnShipDone:
                rts
; ShipRespawn: a new ship at x $C8, level tilt, one life fewer (and the
; HUD redrawn).  In cheat mode no life is lost; instead 1 point is added,
; so the score counts the deaths.
ShipRespawn:
                clr.b   (ShipAlive).l
                clr.b   (ShipMode).l
                move.w  #$C8,(ShipX).l
                move.b  #$8,(ShipTiltFrame).l
                move.l  #$6200,(ShipSpriteFrame).l
                tst.b   (CheatMode).l
                bne.b   .00564
                subq.w  #$1,(Lives).l
                bra.w   DrawLives
.00564:
                moveq   #1,d0
                bra.w   AddScoreAlways
; ResetShipWeapons: after a death - no Bits, missiles, laser or Force.
ResetShipWeapons:
                bsr.w   InitBits
                bsr.w   ResetMissiles
                clr.b   (LaserType).l
                clr.b   (ForceLevel).l
                clr.b   (ForceActive).l
                clr.w   (ForcePos).l
                move.l  #Force_Idle,(ForceState).l
                rts
; LV_Waves is the CHECKPOINT list: 6-byte entries (scroll x.w, wave list.l),
; highest first, ending with the scroll-x 0 entry (level start).  On a
; restart the first entry at or below Checkpoint gives the new ScrollX and
; the wave list position.
InitLevelScroll:
                movea.l (LV_Waves).l,a0
.0059c:
                move.w  (a0),d0
                beq.b   .005ac
                cmp.w   (Checkpoint).l,d0
                bls.b   .005ac
                addq.l  #$6,a0
                bra.b   .0059c
.005ac:
                move.w  d0,(ScrollX).l
                move.l  $2(a0),(WavePtr).l
                move.l  (LV_ScrollScript).l,(ScrollScriptPtr).l
                clr.l   (ScrollXTimer).l
                clr.w   (ScrollYRate).l
                clr.w   (ScrollScriptTimer).l
                move.l  #St_LevelFadeIn,(GameState).l
                move.b  #$E,(FadeSteps).l
                clr.b   (ShipIntroTimer).l
                movea.l (LV_Init).l,a0
                jsr     (a0)
                clr.b   (ShipHit).l
                clr.b   (LaserCount).l
                clr.b   (SpaceKey).l
                clr.b   (Fire2Latch).l
                clr.b   (FireHeld).l
                clr.b   (BeamCharge).l
                st.b    (ScrollActive).l
                clr.w   (WaveFrameCounter).l
                move.b  #$1,(MusicRequest).l
                rts
; Map patches (LV_MapPatches): (x.w, y.w, tile.w) ... until x < 0.
; Written into the map at level start (level 1 only).
ApplyMapPatches:
                move.l  (LV_MapPatches).l,d0
                beq.b   .00656
                movea.l d0,a0
                movea.l (LV_Map).l,a1
.00640:
                move.w  (a0)+,d0
                bmi.b   .00656
                lsl.w   #$1,d0
                move.w  (a0)+,d1
                mulu.w  (MapWidth).l,d1
                add.w   d0,d1
                move.w  (a0)+,(a1,d1.w)
                bra.b   .00640
.00656:
                rts
; LevelFadeInStep: fades the level palette in, one step every 3 frames.
; When done the ship is live and the game goes to St_Playing, or to
; St_PlayStart (the fly-in, StageFlags bit 0) at the start of a level.
LevelFadeInStep:
                subq.b  #$1,(ShipIntroTimer).l
                bpl.b   .006ac
                move.b  #$2,(ShipIntroTimer).l
                movea.l (LV_Palette).l,a0
                bsr.w   PaletteFadeIn
                subq.b  #$1,(FadeSteps).l
                bpl.b   .006ac
                st.b    (ShipAlive).l
                bset.b  #$6,(StageFlags).l
                lea.l   St_Playing(pc),a0
                tst.b   (ShipMode).l
                beq.b   .006a6
                lea.l   St_PlayStart(pc),a0
                bset.b  #$0,(StageFlags).l
                clr.b   (ShipIntroTimer).l
.006a6:
                move.l  a0,(GameState).l
.006ac:
                rts
ShipDied:
                tst.b   (ShipSpawned).l
                beq.w   DeathWait
                clr.b   (MusicRequest).l
                clr.b   (JingleState).l
                clr.b   (MusicFadeReq).l
                move.w  #$F,$96(a6)
                moveq   #7,d0                       ; sound: ship explodes
                bsr.w   PlaySound
                bsr.w   ClearBeamMeter
                bsr.w   ResetShipWeapons
                clr.b   (ShipSpawned).l
                clr.b   (ShipAlive).l
                movem.w (ShipPos).l,d0-d1
                moveq   #-1,d2
                bsr.w   ObjAlloc
                clr.l   $6(a0)
                move.b  #$3,$21(a0)
                move.b  #$1,$5(a0)
                move.b  #$14,$4(a0)
                bsr.w   ObjInsert
                clr.w   (ForcePos).l
                clr.b   (ForceActive).l
                move.b  #$1E,(DeathTimer).l
                move.b  #$F,(FadeSteps).l
                move.w  #$14,(ShipX).l
                move.w  (ScrollX).l,(Checkpoint).l
                rts
; DeathWait (St_Dead): after the ship explodes, DeathTimer (30 frames)
; runs down.  With no lives left the game-over jingle plays and GameOver
; follows; otherwise the palette fades out over FadeSteps (15) steps, one
; every 3 frames, and after 2 more seconds of black the level restarts
; from the last checkpoint (StartLevel).
DeathWait:
                tst.b   (DeathTimer).l
                beq.b   .00770
                subq.b  #$1,(DeathTimer).l
                bne.b   .0076e
                tst.w   (Lives).l
                bpl.b   .0076e
                move.b  #$1,(JingleState).l
.00762:
                tst.b   (JingleState).l
                bne.b   .00762
                bra.w   GameOver
.0076e:
                rts
.00770:
                subq.b  #$1,(ShipIntroTimer).l
                bpl.b   .0076e
                move.b  #$2,(ShipIntroTimer).l
                bsr.w   PaletteFadeOut
                subq.b  #$1,(FadeSteps).l
                bne.b   .0076e
                addq.l  #$4,a7
                bsr.w   PaletteBlack
                move.l  (VblCount).l,d0
                add.l   #$64,d0
.0079e:
                cmp.l   (VblCount).l,d0
                bhi.b   .0079e
                bra.w   StartLevel
; StageEndSequence: the boss is dead.  The beam meter is cleared and the
; ship taken out of play, then over 36 steps (one every 3 frames) the
; palette fades out (the last 15 steps).  Then: autopilot (ShipMode -1),
; the stage-clear jingle, music off, and St_StageClear shows the bonus.
StageEndSequence:
                tst.b   (StageEndStarted).l
                bne.b   .007d0
                bsr.w   ClearBeamMeter
                clr.b   (ShipAlive).l
                move.b  #$24,(FadeSteps).l
                clr.b   (ShipIntroTimer).l
                st.b    (StageEndStarted).l
.007d0:
                subq.b  #$1,(ShipIntroTimer).l
                bpl.b   .00830
                move.b  #$2,(ShipIntroTimer).l
                subq.b  #$1,(FadeSteps).l
                bne.b   .00822
                bsr.w   PaletteBlack
                bclr.b  #$7,(StageFlags).l
                move.b  #$FF,(ShipMode).l
                move.l  #St_StageClear,(GameState).l
                move.w  #$F,$96(a6)
                move.b  #$2,(JingleState).l
                clr.b   (MusicRequest).l
                clr.b   (MusicFadeReq).l
                rts
.00822:
                cmpi.b  #$F,(FadeSteps).l
                bhi.b   .00830
                bra.w   PaletteFadeOut
.00830:
                rts

;==============================================================================
; Map access
;==============================================================================
; GetMapCell: d0,d1 = screen x,y -> a4 = map cell, Z clear if solid (bit 7)
; x,y are screen coordinates: the map origin is at x=$30, y=$20 (the
; off-screen margins), each cell 16x16 pixels.
GetMapCell:
                lea.l   ($48BFA).l,a4
                add.w   (ScrollY).l,d1
                sub.w   #$20,d1
                bmi.b   .0086a
                lsr.w   #$2,d1
                and.w   #$FFFC,d1
                movea.l (a4,d1.w),a4
                add.w   (ScrollX).l,d0
                sub.w   #$30,d0
                bmi.b   .0086a
                lsr.w   #$3,d0
                and.l   #$FFFE,d0
                adda.l  d0,a4
                btst.b  #$7,(a4)
                rts
.0086a:
                moveq   #0,d0
                rts

;==============================================================================
; Game over / continue
;==============================================================================
GameOver:
                bsr.w   PaletteBlack
                bsr.w   ClearPlayfield
                tst.b   (Continues).l
                beq.w   .0093c
                clr.w   (ScrollBplcon1).l
                clr.w   (CopBplcon1).l
                lea.l   (TextPalette).l,a1
                bsr.w   SetPalette
                moveq   #0,d1
                lea.l   (TxtContinue).l,a0
                lea.l   ($2FA6D).l,a1
                bsr.w   PrintString
                lea.l   (TxtPushFire).l,a0
                lea.l   ($3640D).l,a1
                bsr.w   PrintString
                lea.l   (TxtCredit).l,a0
                move.b  (Continues).l,d0
                add.b   #$30,d0
                move.b  d0,$D(a0)
                lea.l   ($3744E).l,a1
                bsr.w   PrintString
                moveq   #9,d7
.008d8:
                lea.l   (DigitFont).l,a4
                lea.l   ($317B1).l,a1
                moveq   #6,d4
.008e6:
                move.b  (a4,d7.w),d6
                moveq   #7,d5
                lea.l   (BigDigitLine).l,a3
                movea.l a3,a0
.008f4:
                move.b  #$20,(a3)
                lsl.b   #$1,d6
                bcc.b   .00900
                move.b  #$30,(a3)
.00900:
                addq.l  #$1,a3
                dbra    d5,.008f4
                moveq   #0,d1
                movea.l a1,a2
                bsr.w   PrintString
                adda.l  #$A,a4
                lea.l   $820(a2),a1
                dbra    d4,.008e6
                move.w  (VblCountLo).l,d0
                add.w   #$32,d0
.00926:
                btst.b  #$7,(CIAA_PRA).l
                beq.b   .00944
                cmp.w   (VblCountLo).l,d0
                bhi.b   .00926
                dbra    d7,.008d8
.0093c:
                addq.l  #$4,a7
                moveq   #0,d7
                bra.w   NewGame
.00944:
                clr.l   (Score).l
                clr.l   (Bonus).l
                addq.b  #$1,(GamesPlayed).l
                move.l  #ExtraLifeTable,(ExtraLifePtr).l
                clr.l   (ScoreToAdd).l
                clr.b   (ShipSpawned).l
                clr.b   (ShipAlive).l
                clr.w   (MusicRequest).l
                clr.b   (MusicFadeReq).l
                subq.b  #$1,(Continues).l
                move.w  #$2,(Lives).l
                bsr.w   DrawLives
                bsr.w   PaletteBlack
                bra.w   StartLevel

;==============================================================================
; Palette fades (copper colour list at CopColours)
;==============================================================================
PaletteBlack:
                moveq   #14,d0
                lea.l   (CopColours).l,a0
.009a0:
                clr.w   (a0)
                addq.l  #$4,a0
                dbra    d0,.009a0
                rts

; PaletteFadeIn: a0 = target palette, one step
PaletteFadeIn:
                moveq   #14,d0
                lea.l   (CopColours).l,a1
.009b2:
                move.w  (a1),d2
                move.w  (a0)+,d3
                moveq   #1,d4
                moveq   #2,d5
.009ba:
                move.w  d2,d6
                move.w  d3,d7
                and.w   #$F,d6
                and.w   #$F,d7
                cmp.b   d7,d6
                bcc.b   .009cc
                add.w   d4,(a1)
.009cc:
                lsl.w   #$4,d4
                lsr.w   #$4,d2
                lsr.w   #$4,d3
                dbra    d5,.009ba
                addq.l  #$4,a1
                dbra    d0,.009b2
                rts

; PaletteFadeOut: one step towards black
PaletteFadeOut:
                lea.l   (CopColours).l,a0
                moveq   #14,d5
.009e6:
                move.w  (a0),d4
                clr.w   d2
                moveq   #1,d7
                moveq   #2,d3
.009ee:
                move.w  d4,d0
                and.w   #$F,d0
                beq.w   .009fa
                or.w    d7,d2
.009fa:
                lsr.w   #$4,d4
                lsl.w   #$4,d7
                dbra    d3,.009ee
                sub.w   d2,(a0)
                addq.l  #$4,a0
                dbra    d5,.009e6
                rts

;==============================================================================
; Score
;==============================================================================
; CountBonus: shows Bonus in BonusText, rolling the digits: the number of
; digits comes from BonusDigitsTable; every 18 frames one more digit
; (from the right) stops on its real value while the others show random
; digits.
CountBonus:
                lea.l   (BonusText).l,a2
                move.l  #$20202020,(a2)
                move.l  #$20202020,$4(a2)
                move.l  (Bonus).l,d0
                lea.l   (BonusDigitsTable).l,a1
.00a2c:
                cmp.l   (a1)+,d0
                bcc.b   .00a34
                addq.l  #$2,a1
                bra.b   .00a2c
.00a34:
                lea.l   ($31AF5).l,a5
                move.w  (a1),d7
                move.w  d7,d6
                move.b  #$12,(BonusRollDelay).l
.00a46:
                move.w  d7,d5
                lea.l   (BonusTextEnd).l,a2
                move.l  (Bonus).l,d4
.00a54:
                move.l  d4,d0
                cmp.w   d5,d6
                bge.b   .00a66
                and.b   #$F,d0
                add.b   #$30,d0
                move.b  d0,-(a2)
                bra.b   .00a72
.00a66:
                moveq   #10,d0
                bsr.w   Random
                add.b   #$30,d0
                move.b  d0,-(a2)
.00a72:
                lsr.l   #$4,d4
                dbra    d5,.00a54
                moveq   #0,d1
                lea.l   (BonusText).l,a0
                movea.l a5,a1
                bsr.w   PrintString
                st.b    (FrameReady).l
.00a8c:
                tst.b   (FrameReady).l
                bne.b   .00a8c
                subq.b  #$1,(BonusRollDelay).l
                bpl.b   .00a46
                move.b  #$12,(BonusRollDelay).l
                subq.w  #$1,d6
                cmp.w   #$FFFE,d6
                bne.b   .00a46
                clr.l   (Bonus).l
                rts

; AddScore: d0 = BCD points (ignored in cheat mode)
AddScore:
                tst.b   (CheatMode).l
                bne.b   AddScoreDone
; AddScoreAlways: d0 = BCD points.  Score += d0, then Bonus += d0 (the
; stage score), 4-byte ABCD chains; each lea points just past its target.
AddScoreAlways:
                move.l  d0,(ScoreToAdd).l
                lea.l   (Bonus).l,a1                ; = end of Score
                lea.l   (ScoreToAddEnd).l,a2
                andi.w  #$FFEF,sr
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                lea.l   (ExtraLifePtr).l,a1         ; = end of Bonus
                lea.l   (ScoreToAddEnd).l,a2
                andi.w  #$FFEF,sr
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
AddScoreDone:
                rts

; UpdateScore: redraw score, award extra lives
UpdateScore:
                move.l  (Score).l,d0
                cmp.l   (ScoreShown).l,d0
                beq.b   UpdateScoreDone
                move.l  d0,(ScoreShown).l
                lea.l   ($2C8F9).l,a0
                bsr.b   DrawDigits
                movea.l (ExtraLifePtr).l,a0
                move.l  (a0)+,d1
                beq.b   UpdateScoreDone
                cmp.l   d1,d0
                bcs.b   UpdateScoreDone
                move.l  a0,(ExtraLifePtr).l
                cmpi.w  #$4,(Lives).l
                bge.b   UpdateScoreDone
                addq.w  #$1,(Lives).l
                bra.w   DrawLives
UpdateScoreDone:
                rts

; DrawDigits: d0 = 6-digit BCD, a0 = screen
DrawDigits:
                movem.l d0-d4,-(a7)
                moveq   #5,d1
                lsl.l   #$8,d0
                moveq   #0,d2
                moveq   #0,d3
                lea.l   (DigitFont).l,a3
.00b4c:
                roxl.l  #$1,d0
                roxl.b  #$1,d2
                roxl.l  #$1,d0
                roxl.b  #$1,d2
                roxl.l  #$1,d0
                roxl.b  #$1,d2
                roxl.l  #$1,d0
                roxl.b  #$1,d2
                and.w   #$F,d2
                bne.b   .00b66
                tst.w   d1
                bne.b   .00b68
.00b66:
                moveq   #1,d3
.00b68:
                movea.l a3,a1
                adda.l  d2,a1
                movea.l a0,a2
                moveq   #6,d4
.00b70:
                tst.w   d3
                bne.b   .00b78
                clr.b   (a2)
                bra.b   .00b7a
.00b78:
                move.b  (a1),(a2)
.00b7a:
                adda.l  #$28,a2
                adda.l  #$A,a1
                dbra    d4,.00b70
                addq.l  #$1,a0
                dbra    d1,.00b4c
                movem.l (a7)+,d0-d4
                rts
; DrawLives: clears the 5 icon positions in the HUD ($2C7DA, 3 planes
; $258 apart, 40-byte lines) and draws Lives+1 ship icons (LifeIcon: 6
; lines x 3 planes, one byte wide).
DrawLives:
                moveq   #4,d0
                lea.l   ($2C7DA).l,a0
.00b9e:
                moveq   #5,d1
                movea.l a0,a1
.00ba2:
                clr.b   (a1)
                clr.b   $258(a1)
                clr.b   $4B0(a1)
                adda.l  #$28,a1
                dbra    d1,.00ba2
                addq.l  #$1,a0
                dbra    d0,.00b9e
                move.w  (Lives).l,d0
                bmi.b   .00bf2
                lea.l   ($2C7DA).l,a0
.00bca:
                moveq   #5,d1
                movea.l a0,a2
                lea.l   (LifeIcon).l,a1
.00bd4:
                move.b  $C(a1),$4B0(a2)
                move.b  $6(a1),$258(a2)
                move.b  (a1)+,(a2)
                adda.l  #$28,a2
                dbra    d1,.00bd4
                addq.l  #$1,a0
                dbra    d0,.00bca
.00bf2:
                rts

;==============================================================================
; Object system
;
; 40 objects of $3E bytes at $4935A, kept on a free list (FreeObjects) and an
; active list sorted by priority (ActiveObjects).  Known fields:
;   $00.l next          $04.b priority      $05.b state (0 alive, 1 start
;   $06.l update routine (0 = none)          explosion, $FF exploding)
;   $0A.w x             $0C.w y             $0E.l current frame graphics
;   $12.l definition    $16-$1C hit box     $1E.w animation index
;   $20.b anim timer    $21.b explosion type / timer
;   $22.b anim advance  $23.b flags: 0 flash, 1 carries power-up,
;                                    2 no collision, 3 is a power-up
;   $24.w hit points (-1 = indestructible)  $26.w damage taken
;   $28.b hit-flash timer                   $2A.l animation sequence
;   $2E.w fire rate     $30.w fire timer    $32+  routine-specific
; Definition ($12): $00 blit size, $02 modulo, $04 frame bytes, $07 anim
;   speed, $0A fire rate, $0C graphics, $10 mask offset, $14 animation,
;   $18 hit boxes, $1C update routine, $20 spawn routine, $24 score (BCD)
;==============================================================================
InitObjects:
                clr.l   (ActiveObjects).l
                lea.l   ($4935A).l,a0
                move.l  a0,(FreeObjects).l
                moveq   #39,d0
.00c08:
                adda.l  #$3E,a0
                move.l  a0,-$3E(a0)
                dbra    d0,.00c08
                clr.l   (a0)
                moveq   #13,d0
                lea.l   (ShotX).l,a0
.00c20:
                clr.w   (a0)+
                dbra    d0,.00c20
                moveq   #15,d0
                lea.l   (EnemyBullets).l,a0
.00c2e:
                clr.w   (a0)
                adda.l  #$E,a0
                dbra    d0,.00c2e
                rts
; $48BFA: 26 pointers to the start of each map row (LV_Map + n*MapRowBytes)
BuildMapRows:
                movea.l (LV_Map).l,a0
                lea.l   ($48BFA).l,a1
                moveq   #25,d7
.00c4a:
                move.l  a0,(a1)+
                adda.l  (MapRowBytes).l,a0
                dbra    d7,.00c4a
                rts

;==============================================================================
; Hardware set-up
;==============================================================================
; Row tables: $48BBA = 16 x line offset (FineScrollY), $48C62 = 272 x line
; offset ($D0 per line) used by every BOB blit (a5).
; Sprite colours (COLOR16-31) come from SpriteColours.
InitHardware:
                lea.l   (CUSTOM).l,a6
                move.l  #$2C91FCC1,$8E(a6)
                move.l  #$3800D0,$92(a6)
                move.w  #$8000,$98(a6)
                move.b  #$C0,(CIAB_DDRA).l
                move.b  #$FF,(CIAB_DDRB).l
                move.b  #$3,(CIAA_DDRA).l
                move.b  #$1F,(CIAB_ICR).l
                move.b  #$1F,(CIAA_ICR).l
                move.b  #$88,(CIAA_ICR).l
                andi.b  #$FE,(CIAB_CRA).l
                andi.b  #$FE,(CIAB_CRB).l
                andi.b  #$FE,(CIAA_CRA).l
                andi.b  #$FE,(CIAA_CRB).l
                lea.l   $1A0(a6),a1
                lea.l   (SpriteColours).l,a2
                moveq   #15,d0
.00cd0:
                move.w  (a2)+,(a1)+
                dbra    d0,.00cd0
                lea.l   ($48BBA).l,a0
                clr.l   d0
                moveq   #15,d1
.00ce0:
                move.l  d0,(a0)+
                add.l   #$D0,d0
                dbra    d1,.00ce0
                lea.l   ($48C62).l,a0
                clr.l   d0
                move.w  #$10F,d1
.00cf8:
                move.l  d0,(a0)+
                add.l   #$D0,d0
                dbra    d1,.00cf8
                rts
ClearScreens:
                lea.l   ($2D1BA).l,a0
.00d0c:
                clr.l   (a0)+
                cmpa.l  #$4935A,a0
                bcs.b   .00d0c
                rts
; InitMapOffsets: patches the laser move tables for this level's map width.
; ReflectLaserMoves gets +/-MapRowBytes (and +/-2 for the diagonals) as the
; map offsets of its moves; GroundLaserMoves gets +MapRowBytes at the
; offsets listed in GroundLaserRowDown and -MapRowBytes at GroundLaserRowUp.
InitMapOffsets:
                lea.l   (ReflectLaserMoves).l,a0
                move.l  (MapRowBytes).l,d0
                move.l  d0,d1
                move.l  d0,$6A(a0)
                move.l  d0,$92(a0)
                addq.l  #$2,d0
                move.l  d0,$7E(a0)
                subq.l  #$4,d0
                move.l  d0,$56(a0)
                neg.l   d1
                move.l  d1,$42(a0)
                move.l  d1,$1A(a0)
                subq.l  #$2,d1
                move.l  d1,$2E(a0)
                addq.l  #$4,d1
                move.l  d1,$6(a0)
                move.l  (MapRowBytes).l,d0
                lea.l   (GroundLaserMoves).l,a0
                lea.l   (GroundLaserRowDown).l,a1
                bsr.b   .00d6c
                neg.l   d0
                lea.l   (GroundLaserRowUp).l,a1
.00d6c:
                move.w  (a1)+,d1
                bmi.b   .00d76
                move.l  d0,(a0,d1.w)
                bra.b   .00d6c
.00d76:
                rts

; PalCheck: a PAL-only check, run at the start of every game.  It times one
; video frame with CIA-A timer B: the CIA-A TOD counter is clocked by
; vertical sync, so WaitTodTick waits for a frame boundary, the timer runs
; ($FFFF down, E clock) until the next one, and d0 = what is left.
;   PAL   709,379 Hz / 50 = 14,188 ticks -> d0 ~ $C893  (passes)
;   NTSC  715,909 Hz / 60 = 11,932 ticks -> d0 ~ $D163  (hangs)
; Anything shorter than 13,090 ticks (a refresh above ~54 Hz) leaves
; d0 > $CCDD and the game locks up in the loop with interrupts back on.
; WaitTodTick also gives up if the timer passes $8000, so a missing TOD
; doesn't hang it.
PalCheck:
                lea.l   (CIAA_PRA).l,a5
                move.w  #$4000,$9A(a6)          ; INTENA: master off
                move.b  #$8,$F00(a5)            ; CRB: timer B one-shot, stopped; TOD writes set the clock
                moveq   #0,d0
                move.b  d0,$A00(a5)             ; TOD = 0 (hi stops it, lo restarts it)
                move.b  d0,$900(a5)
                move.b  d0,$800(a5)
                move.b  #$FF,$600(a5)           ; timer B latch = $FFFF
                move.b  #$FF,$700(a5)
                bsr.w   WaitTodTick             ; sync to a frame boundary
                move.b  #$19,$F00(a5)           ; CRB: load and start timer B (one-shot)
                bsr.w   WaitTodTick             ; one frame later
                move.b  #$8,$F00(a5)            ; stop it
                moveq   #0,d0
                move.b  $700(a5),d0             ; d0 = ticks left
                lsl.w   #$8,d0
                move.b  $600(a5),d0
                move.w  #$C000,$9A(a6)          ; INTENA: master on
.00dca:
                cmp.w   #$CCDD,d0               ; frame too short (not PAL): hang
                bhi.b   .00dca
                rts
WaitTodTick:
                move.b  $800(a5),d0
.00dd6:
                cmp.b   $800(a5),d0
                bne.b   .00de2
                tst.b   $700(a5)
                bmi.b   .00dd6
.00de2:
                rts

;==============================================================================
; Keyboard interrupt: Space = fire 2, P = pause
;==============================================================================
Level2Int:
                move.l  d0,-(a7)
                btst.b  #$3,(CIAA_ICR).l
                bne.b   .00dfc
.00df0:
                move.l  (a7)+,d0
                move.w  #$8,(CUSTOM+INTREQ).l
                rte
.00dfc:
                movem.l d1-d7/a0-a6,-(a7)
                move.b  (CIAA_SDR).l,d0
                ori.b   #$40,(CIAA_CRA).l
                not.b   d0
                ror.b   #$1,d0
                cmp.b   #$40,d0
                bne.b   .00e20
                st.b    (SpaceKey).l
                bra.b   .00e44
.00e20:
                cmp.b   #$C0,d0
                bne.b   .00e2e
                clr.b   (SpaceKey).l
                bra.b   .00e44
.00e2e:
                cmp.b   #$19,d0
                bne.b   .00e44
                eori.b  #$FF,(Paused).l
                bne.b   .00e44
                clr.w   (FlipCountdown).l
.00e44:
                moveq   #55,d0
.00e46:
                dbra    d0,.00e46
                movem.l (a7)+,d1-d7/a0-a6
                andi.b  #$BF,(CIAA_CRA).l
                bra.b   .00df0

;==============================================================================
; Random numbers
;==============================================================================
; Random: d0 = range -> d0 = 0..range-1
Random:
                movem.l d1-d2,-(a7)
                move.l  (RandomSeed).l,d1
                add.l   d1,d1
                bhi.b   .00e76
                move.w  (CUSTOM+VHPOSR).l,d2
                swap    d2
                move.w  (CUSTOM+VHPOSR).l,d2
                eor.l   d2,d1
.00e76:
                move.l  d1,(RandomSeed).l
                and.l   #$FFFF,d1
                and.l   #$FFFF,d0
                divu.w  d0,d1
                swap    d1
                move.w  d1,d0
                movem.l (a7)+,d1-d2
                rts

;==============================================================================
; Object routines
;==============================================================================
ObjUpd_FlyInShip:
                tst.w   $32(a0)
                bpl.b   .00ea8
                addq.w  #$4,$A(a0)
                cmpi.w  #$DC,$A(a0)
                bhi.w   ObjKillSelf
.00ea8:
                subq.w  #$1,$32(a0)
                rts

;==============================================================================
; Scrolling
;==============================================================================
; Scroll script (LV_ScrollScript): 6-byte entries
;   x speed.w, y speed.w, duration.w (frames)
; An entry is followed until its duration runs out; if the NEXT entry has a
; negative duration the current one repeats for ever (end marker).
; Speeds index the table at $48E9: table[n] = pixels per step and
; table[15+|n|] = extra frames to wait between steps (n < 0 = other way):
;   n = 0 stopped, 1..10: 1 pixel every 12-n frames, 11: 1 pixel a frame,
;   12/13/14: 2/3/4 pixels a frame.
; Only level 3 scrolls vertically.
UpdateScroll:
                tst.b   (ScrollActive).l            ; scrolling stops for bosses / stage end
                beq.w   .00f04
                lea.l   (ScrollYTimer).l,a0         ; y: timer, rate, step
                bsr.b   ScrollStep
                add.w   d0,(ScrollY).l              ; step this frame (0 if waiting)
                subq.l  #$3,a0                      ; x: the same three bytes before it
                bsr.b   ScrollStep
                add.w   d0,(ScrollX).l
                subq.w  #$1,(ScrollScriptTimer).l   ; current script entry finished?
                bpl.b   .00f04
                lea.l   (ScrollSpeedTable).l,a2
                movea.l (ScrollScriptPtr).l,a1      ; next entry: x speed, y speed, frames
                move.w  (a1),d0
                bsr.b   SetScrollSpeed
                addq.l  #$3,a0
                move.w  $2(a1),d0
                bsr.b   SetScrollSpeed
                move.w  $4(a1),(ScrollScriptTimer).l
                tst.w   $A(a1)                      ; following entry's duration < 0: hold this one
                bmi.b   .00f04
                addq.l  #$6,(ScrollScriptPtr).l
.00f04:
                rts
ScrollStep:
                clr.w   d0
                subq.b  #$1,(a0)
                bpl.b   .00f16
                move.b  $1(a0),(a0)
                move.b  $2(a0),d0
                ext.w   d0
.00f16:
                rts
SetScrollSpeed:
                move.b  (a2,d0.w),$2(a0)
                tst.w   d0
                bpl.b   .00f24
                neg.w   d0
.00f24:
                move.b  $F(a2,d0.w),$1(a0)
                rts

; AdjustForScroll: d0,d1 -= this frame's scroll
AdjustForScroll:
                tst.b   (ScrollActive).l
                beq.b   .00f5c
                move.w  d3,-(a7)
                tst.b   (ScrollXTimer).l
                bne.b   .00f48
                move.b  (ScrollXStep).l,d3
                ext.w   d3
                sub.w   d3,d0
.00f48:
                tst.b   (ScrollYTimer).l
                bne.b   .00f5a
                move.b  (ScrollYStep).l,d3
                ext.w   d3
                sub.w   d3,d1
.00f5a:
                move.w  (a7)+,d3
.00f5c:
                rts

;==============================================================================
; Background: blit the visible 20x13 tiles
;==============================================================================
; Redraws the whole visible background every frame: 20 x 13 tiles.
; Map cell (one word, LV_Map, MapRowBytes bytes per row, rows via $48BFA):
;   bits 0-11  tile number
;   bit 15     solid: GetMapCell tests it.  The ship, the Force, the POW
;              Armor, shots, lasers and the Bits collide with solid cells.
;   bit 14     animated: bits 0-3 select a routine in LV_TileAnims (called
;              by DrawMap).  A solid animated cell stops the reflect laser
;              without a bounce, and the wave beam passes through it.
;   bit 13     hit: set by shots, the wave beam, the lasers, the Force and
;              the Bits when they touch the (solid) cell.  The tile routine
;              reads it - level 1's animated blocks clear themselves and
;              their neighbour when hit.
;   bit 12     destructible: shots, the Force, the Bits, the shot streams
;              and the anti-air laser clear the cell to 0 at once; the wave
;              beam clears it and carries on.  Some level objects (level 4)
;              clear destructible cells they touch too.
; Tile (LV_Tiles + n*128): 16x16 pixels, 4 interleaved planes = 64 words,
;   copied with one A->D blit (BLTSIZE $1001: 64 lines x 1 word,
;   D modulo $32 = 52-2 for the interleaved screen).
; Coarse scroll = which map column is drawn first (ScrollX/16), fine scroll
; = BPLCON1 (ScrollX & 15); vertically the same with FineScrollY lines.
DrawMap:
                move.w  #$32,$66(a6)
                clr.w   $64(a6)
                move.l  #$FFFFFFFF,$44(a6)
                clr.w   $42(a6)
                move.w  #$9F0,$40(a6)
                moveq   #0,d0
                move.w  (ScrollX).l,d0
                move.w  d0,d1
                and.w   #$F,d1
                move.w  d1,(FineScrollX).l
                neg.w   d1
                add.w   #$F,d1
                move.w  d1,d2
                lsl.w   #$4,d1
                or.w    d2,d1
                move.w  d1,(ScrollBplcon1).l
                lsr.w   #$3,d0
                and.w   #$FFFE,d0
                movea.l (DrawBuffer).l,a1
                adda.l  #$1A06,a1
                movea.l (LV_Tiles).l,a3
                move.w  (ScrollY).l,d2
                move.w  d2,d3
                and.w   #$F,d3
                move.w  d3,(FineScrollY).l
                lsr.w   #$2,d2
                and.w   #$FFFC,d2
                lea.l   ($48BFA).l,a0
                movea.l (a0,d2.w),a0
                adda.l  d0,a0
                movea.l (MapRowBytes).l,a2
                suba.l  #$28,a2
                moveq   #12,d3
.00fea:
                moveq   #19,d2
.00fec:
                moveq   #0,d1
                move.w  (a0)+,d1
                btst    #$E,d1
                beq.b   .0100a
                move.w  d1,d7
                and.w   #$F,d7
                lsl.w   #$2,d7
                movea.l (LV_TileAnims).l,a4
                movea.l (a4,d7.w),a4
                jsr     (a4)
.0100a:
                and.w   #$FFF,d1
                lsl.l   #$7,d1
                movea.l a3,a4
                adda.l  d1,a4
                bsr.w   WaitBlit
                move.l  a1,$54(a6)
                move.l  a4,$50(a6)
                move.w  #$1001,$58(a6)
                addq.l  #$2,a1
                dbra    d2,.00fec
                adda.l  #$CD8,a1
                adda.l  a2,a0
                dbra    d3,.00fea
                rts

;==============================================================================
; Enemy waves
;==============================================================================
; Wave list (from the checkpoint entry): $12-byte entries
;   $00.w scroll x to trigger at (level 3: a frame counter instead)
;   $02.w x, $04.w y, $06.. $0D parameters for the spawn routine
;   $0E.l object definition (negative = default $051FC)
; The definition's spawn routine ($20) is called with a1 = entry, a2 = def.
SpawnWaves:
                movea.l (WavePtr).l,a1
                move.w  (ScrollX).l,d0
                cmpi.b  #$2,(Level).l
                bne.b   .0105c
                addq.w  #$1,(WaveFrameCounter).l
                move.w  (WaveFrameCounter).l,d0
.0105c:
                cmp.w   (a1),d0
                bcs.b   .0107e
                move.l  $E(a1),d1
                bpl.b   .0106c
                move.l  #DefPowArmor,d1
.0106c:
                movea.l d1,a2
                movea.l $20(a2),a3
                jsr     (a3)
                addi.l  #$12,(WavePtr).l
.0107e:
                rts

;==============================================================================
; Object list: allocation, update, drawing
;==============================================================================
; ObjAlloc: d0,d1 = x,y  d2 = hit points -> a0
ObjAlloc:
                bsr.w   ObjPoolPop
                clr.w   $4(a0)
                clr.w   $1E(a0)
                clr.w   $20(a0)
                clr.w   $26(a0)
                clr.b   $23(a0)
                clr.b   $28(a0)
                clr.w   $2E(a0)
                clr.w   $30(a0)
                st.b    $22(a0)
                move.w  d2,$24(a0)
                move.w  d0,$A(a0)
                move.w  d1,$C(a0)
                rts

; ObjCreate: as ObjAlloc, a2 = object definition
ObjCreate:
                bsr.b   ObjAlloc
                move.l  a2,$12(a0)
                move.l  $1C(a2),$6(a0)
                move.l  $14(a2),$2A(a0)
                move.w  $A(a2),$2E(a0)
                beq.b   .010e4
                move.l  d0,-(a7)
                moveq   #75,d0
                bsr.w   Random
                add.w   d0,$2E(a0)
                move.w  $2E(a0),$30(a0)
                move.l  (a7)+,d0
.010e4:
                rts
UpdateObjects:
                move.l  (ActiveObjects).l,d7        ; walk the active list (sorted by priority)
                move.l  #ActiveObjects,(PrevObject).l
UpdateObjectsLoop:
                tst.l   d7
                beq.w   UpdateObjectsDone
                movea.l d7,a0
                move.l  $6(a0),d0                   ; object's own routine (movement, AI)
                beq.b   .01108
                movea.l d0,a3
                jsr     (a3)
.01108:
                bsr.b   ObjExplode                  ; explosion animation if dying, else draw
                bsr.w   ObjCollisions               ; against shots, beam, Force, Bits, ship
                bsr.w   ObjAutoFire                 ; fire at the ship when its timer runs out
NextObject:
                move.l  (a0),d7
                move.l  a0,(PrevObject).l
                bne.b   UpdateObjectsLoop
UpdateObjectsDone:
                rts
; State $05: 0 = alive (just draw), 1 = killed this frame, $FF = exploding.
; On the first explosion frame the object is switched to an explosion
; definition from ExplosionTypes (8 bytes per type: definition.l, +7 frame
; count), chosen by its explosion type ($21 & 3), and sound 10 + type is
; played.  It is removed (ObjKillSelf) when the animation has run out.
ObjExplode:
                tst.b   $5(a0)
                beq.b   ObjAnimDraw
                bmi.b   .0116a
                clr.w   $2E(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                st.b    $22(a0)
                st.b    $5(a0)
                move.b  $21(a0),d0
                and.w   #$3,d0
                move.w  d0,d1
                add.w   #$A,d0
                bsr.w   PlaySound
                lsl.w   #$3,d1
                lea.l   (ExplosionTypes).l,a3
                move.b  $7(a3,d1.w),$21(a0)
                movea.l (a3,d1.w),a3
                move.l  $14(a3),$2A(a0)
                move.l  a3,$12(a0)
                bra.b   ObjAnimDraw
.0116a:
                tst.b   $20(a0)
                bne.b   ObjAnimDraw
                subq.b  #$1,$21(a0)
                bpl.b   ObjAnimDraw
                jmp     (ObjKillSelf).l
; BOB drawing (cookie cut).  The object definition (a1 = $12(a0)) gives:
;   $00.w BLTSIZE   (height = lines x 4 planes, width in words incl. the
;                    extra word for shifting)
;   $02.w C/D modulo for the interleaved screen (52 - width*2)
;   $04.w bytes per frame          $07.b frames per animation step
;   $08.w hit points ($0A.w fire rate)
;   $0C.l graphics (frame 0)       $10.l mask offset (mask follows graphics)
;   $14.l animation sequence: frame numbers, negative = loop to start
;   $18.l hit boxes: 4 words per frame, copied to object $16-$1C
;   $1C.l update routine           $20.l spawn routine (waves)
; Graphics are interleaved like the screen (each line: plane 0-3).  The mask
; is one plane repeated for each plane line.  Minterm $CA: D = A.B + /A.C
; (A = mask, B = graphics, C = background).  While the hit-flash bit is set
; the mask is also used as B, drawing the whole shape in colour 15.
ObjAnimDraw:
                movea.l $12(a0),a1
                subq.b  #$1,$20(a0)
                bpl.b   .011d8
                move.b  $7(a1),$20(a0)
                move.w  $1E(a0),d0
                movea.l $2A(a0),a3
                moveq   #0,d1
                move.b  (a3,d0.w),d1
                bpl.b   .011a0
                clr.w   d0
                move.b  (a3),d1
.011a0:
                tst.b   $22(a0)
                beq.b   .011a8
                addq.w  #$1,d0
.011a8:
                move.w  d0,$1E(a0)
                move.w  d1,d0
                lsl.w   #$3,d0
                movea.l $18(a1),a3
                move.w  (a3,d0.w),$16(a0)
                move.w  $2(a3,d0.w),$18(a0)
                move.w  $4(a3,d0.w),$1A(a0)
                move.w  $6(a3,d0.w),$1C(a0)
                mulu.w  $4(a1),d1
                add.l   $C(a1),d1
                move.l  d1,$E(a0)
.011d8:
                move.w  $A(a0),d0
                add.w   (FineScrollX).l,d0
                bmi.b   .0124c
                cmp.w   #$170,d0
                bhi.b   .0124c
                move.w  $C(a0),d3
                add.w   (FineScrollY).l,d3
                bsr.w   BlitShift
                lsl.w   #$2,d3
                move.l  (a5,d3.w),d3
                add.l   d0,d3
                add.l   (DrawBuffer).l,d3
                move.w  $2(a1),d1
                move.w  (a1),d2
                bsr.w   WaitBlit
                move.w  d1,$60(a6)
                move.w  d1,$66(a6)
                move.w  d4,$42(a6)
                or.w    #$FCA,d4
                move.w  d4,$40(a6)
                move.l  d3,$54(a6)
                move.l  d3,$48(a6)
                movea.l $E(a0),a2
                move.l  a2,$4C(a6)
                adda.l  $10(a1),a2
                move.l  a2,$50(a6)
                bclr.b  #$0,$23(a0)
                beq.b   .01248
                move.l  a2,$4C(a6)
.01248:
                move.w  d2,$58(a6)
.0124c:
                rts
BlitShift:
                ror.w   #$4,d0
                move.w  d0,d4
                and.w   #$F000,d4
                and.l   #$FFF,d0
                lsl.w   #$1,d0
                rts
WaitBlit:
                btst.b  #$6,$2(a6)
                bne.b   WaitBlit
                rts
; ObjPoolPop: a0 = the next free object (0 if none), off FreeObjects.
ObjPoolPop:
                move.l  d0,-(a7)
                move.l  (FreeObjects).l,d0
                beq.b   .0127e
                movea.l d0,a0
                move.l  (a0),d0
                move.l  d0,(FreeObjects).l
.0127e:
                move.l  (a7)+,d0
                rts
ObjUnlink:
                clr.w   $A(a0)
                movea.l (PrevObject).l,a1
                move.l  (a0),(a1)
                move.l  (FreeObjects).l,(a0)
                move.l  a0,(FreeObjects).l
                movea.l a1,a0
                rts

; ObjKillSelf: (from an object routine) remove it, continue the list
ObjKillSelf:
                addq.l  #$4,a7
                bsr.b   ObjUnlink
                bra.w   NextObject

; ObjInsert: insert a0 into the active list by priority (byte 4)
ObjInsert:
                movem.l d0-d1/a0-a2,-(a7)
                move.l  (ActiveObjects).l,d0
                beq.b   .012d0
                move.b  $4(a0),d1
                movea.l d0,a1
                cmp.b   $4(a1),d1
                bls.b   .012da
.012be:
                movea.l d0,a1
                move.l  (a1),d0
                beq.b   .012e4
                movea.l d0,a2
                cmp.b   (a2),d1
                bhi.b   .012be
                move.l  a2,(a0)
                move.l  a0,(a1)
                bra.b   .012e8
.012d0:
                move.l  a0,(ActiveObjects).l
                clr.l   (a0)
                bra.b   .012e8
.012da:
                move.l  a1,(a0)
                move.l  a0,(ActiveObjects).l
                bra.b   .012e8
.012e4:
                clr.l   (a0)
                move.l  a0,(a1)
.012e8:
                movem.l (a7)+,d0-d1/a0-a2
                rts
; ObjAutoFire: if the object has a fire rate ($2E), counts its fire timer
; ($30) down and fires an enemy bullet at the ship each time it runs out.
ObjAutoFire:
                move.w  $2E(a0),d6
                beq.w   .01308
                subq.w  #$1,$30(a0)
                bpl.b   .01308
                move.w  d6,$30(a0)
                movem.w $A(a0),d0-d1
                bra.b   FireEnemyBullet
.01308:
                rts

;==============================================================================
; Enemy bullets
;==============================================================================
; FireEnemyBullet: d0,d1 = start, aimed at the ship
FireEnemyBullet:
                moveq   #15,d7
                lea.l   (EnemyBullets).l,a1
.01312:
                tst.w   (a1)
                bne.b   .01348
                clr.w   $8(a1)
                move.l  #$19D90,$A(a1)          ; enemy bullet graphics
                movem.w d0-d1,(a1)
                movem.w (ShipPos).l,d2-d3
                bsr.w   DirectionTo
                lsl.w   #$2,d0
                lea.l   (BulletVelocities).l,a2
                move.w  (a2,d0.w),$4(a1)
                move.w  $2(a2,d0.w),$6(a1)
                rts
.01348:
                adda.l  #$E,a1
                dbra    d7,.01312
                rts
; UpdateEnemyBullets: 16 bullets of $0E bytes (EnemyBullets):
;   +0 x  +2 y  +4 dx  +6 dy  +8.b hit state  +$A.l frame graphics
; A bullet flies straight on (velocity from BulletVelocities, by the
; direction to the ship when fired) and is drawn as a 16x14 BOB.  It dies
; when it leaves the screen.  Hitting the ship kills it; hitting a solid
; map cell or the Force starts a 4-frame burst (+8 counts it, the frame
; pointer steps by $E0) - the Force absorbs bullets.
UpdateEnemyBullets:
                move.w  #$30,$60(a6)
                move.w  #$30,$66(a6)
                moveq   #15,d7
                lea.l   (EnemyBullets).l,a3
.01368:
                move.w  (a3),d2
                beq.w   .01450
                move.w  $2(a3),d3
                move.b  $8(a3),d4
                bne.w   .01422
                move.w  d2,d0
                move.w  d3,d1
                addq.w  #$8,d0
                addq.w  #$7,d1
                bsr.w   GetMapCell
                bne.w   .01422
                movem.l d3-d4/a3,-(a7)
                move.w  d3,d4
                move.w  d2,d3
                addq.w  #$5,d3
                addq.w  #$4,d4
                movea.w #$6,a3
                movea.w a3,a4
                movem.w (ShipPos).l,d0-d1
                addq.w  #$3,d0
                add.w   (ShipHitboxY).l,d1
                moveq   #20,d5
                move.w  (ShipHitboxH).l,d6
                bsr.w   BoxTest
                beq.b   .013ce
                tst.b   (ShipAlive).l
                beq.b   .013c8
                st.b    (ShipHit).l
.013c8:
                movem.l (a7)+,d3-d4/a3
                bra.b   .01436
.013ce:
                movem.w (ForcePos).l,d0-d1
                sub.w   #$5F,d0
                sub.w   #$C,d1
                add.w   (ForceHitbox).l,d0
                add.w   (ForceHitboxY).l,d1
                movem.w (ForceHitboxSize).l,d5-d6
                bsr.w   BoxTest
                movem.l (a7)+,d3-d4/a3
                bne.b   .01422
                cmp.w   #$20,d2
                bcs.b   .01436
                cmp.w   #$170,d2
                bhi.b   .01436
                cmp.w   #$10,d3
                bcs.b   .01436
                cmp.w   #$E0,d3
                bhi.b   .01436
                add.w   $4(a3),d2
                add.w   $6(a3),d3
                movem.w d2-d3,(a3)
                bra.b   .0143a
.01422:
                addi.l  #$E0,$A(a3)
                addq.b  #$1,d4
                move.b  d4,$8(a3)
                cmp.b   #$4,d4
                bls.b   .0143a
.01436:
                clr.w   (a3)
                bra.b   .01450
.0143a:
                move.w  d2,d0
                movea.l $A(a3),a1
                movea.l a1,a2
                adda.l  #$70,a2
                move.w  #$E02,d1
                bsr.w   BlitBob
.01450:
                adda.l  #$E,a3
                dbra    d7,.01368
                rts

;==============================================================================
; Direction helpers
;==============================================================================
; DirectionTo: (d0,d1) -> (d2,d3): d0 = direction 0-15
DirectionTo:
                movem.l d1-d3/d5-d6/a1,-(a7)
                lea.l   (DirectionOctants).l,a2
                sub.w   d3,d1
                bpl.b   .0146e
                neg.w   d1
                addq.l  #$5,a2
.0146e:
                sub.w   d2,d0
                beq.b   .014a0
                bpl.b   .0147c
                neg.w   d0
                adda.l  #$A,a2
.0147c:
                and.l   #$FFFF,d1
                lsl.l   #$4,d1
                lsl.l   #$5,d1
                divu.w  d0,d1
                lea.l   (SlopeThresholds).l,a1
                clr.w   d0
.01490:
                cmp.w   (a1),d1
                bhi.b   .014a0
                addq.w  #$2,a1
                addq.w  #$1,d0
                cmp.w   #$5,d0
                bne.b   .01490
                moveq   #4,d0
.014a0:
                move.b  (a2,d0.w),d0
                movem.l (a7)+,d1-d3/d5-d6/a1
                rts

; TurnTowards: d1 = direction turned one step towards d0
TurnTowards:
                sub.w   d1,d0
                bpl.b   .014b6
                cmp.w   #$FFF8,d0
                blt.b   .014bc
                bra.b   .014c0
.014b6:
                cmp.w   #$8,d0
                bhi.b   .014c0
.014bc:
                addq.w  #$1,d1
                bra.b   .014c2
.014c0:
                subq.w  #$1,d1
.014c2:
                tst.w   d1
                bpl.b   .014ca
                moveq   #15,d1
                rts
.014ca:
                cmp.w   #$F,d1
                bls.b   .014d2
                clr.w   d1
.014d2:
                rts

;==============================================================================
; Collisions
;==============================================================================
ObjCollisions:
                tst.b   (ShipAlive).l               ; no collisions while the ship is dead
                beq.b   .01500
                tst.b   $5(a0)                      ; already dying
                bne.b   .01500
                tst.b   $28(a0)                     ; hit-flash running: just blink
                beq.b   .01502
                subq.b  #$1,$28(a0)
                btst.b  #$0,$28(a0)
                beq.b   .01500
                bset.b  #$0,$23(a0)                 ; draw white this frame
                moveq   #6,d0                       ; sound: enemy hit
                bra.w   PlaySound
.01500:
                rts
.01502:
                move.w  $A(a0),d3
                cmp.w   #$15E,d3                    ; only when on screen
                bcc.b   .01500
                add.w   $16(a0),d3                  ; d3,d4 = hit box centre, a3/a4 = extents
                move.w  $C(a0),d4
                add.w   $18(a0),d4
                movem.w $1A(a0),a3-a4
                bsr.w   HitByForceOrShip            ; touching the ship kills it; the Force hurts
                btst.b  #$2,$23(a0)                 ; flag 2: immune to weapons
                bne.b   .01500
                bsr.w   HitByMissiles
                bsr.w   HitByBits
                bsr.w   HitByLasers
                bsr.w   HitByShots
                rts
HitByShots:
                moveq   #13,d7                      ; 14 player shots, parallel word arrays:
                lea.l   (WaveBeamX).l,a1            ; x +0, y +$1C, box +$54/$70/$8C/$A8, type +$38
.01544:
                move.w  (a1),d0
                beq.w   .015d6
                move.w  $1C(a1),d1
                add.w   $54(a1),d0
                add.w   $70(a1),d1
                move.w  $8C(a1),d5
                move.w  $A8(a1),d6
                bsr.w   BoxTest
                beq.b   .015d6
                cmp.w   #$D,d7                      ; 13: wave cannon beam
                bne.b   .01592
                move.w  $38(a1),d0                  ; its power (charge level)
                move.w  d0,d2
                move.w  $24(a0),d1
                bmi.b   .01588
                sub.w   $26(a0),d1
                sub.w   d1,d0
                beq.b   .01588
                bmi.b   .01588
                move.w  d0,$38(a0)
                move.w  d1,d0
                bra.b   .0158c
.01588:
                move.w  d2,d0
                clr.w   (a1)
.0158c:
                bsr.w   ObjDamage
                bra.b   .015d6
.01592:
                cmp.w   #$C,d7                      ; 12: anti-air laser (helix) - 5 damage,
                bne.b   .015b0
                move.w  $24(a0),d0
                sub.w   $26(a0),d0
                cmp.w   #$5,d0                      ; carries on if that kills the target
                bls.b   .015a8
                clr.w   (a1)
.015a8:
                moveq   #5,d0
                bsr.w   ObjDamage
                bra.b   .015d6
.015b0:
                cmp.w   #$A,d7                      ; 10-11: shot streams - 2 damage
                bcs.b   .015ce
                move.w  $24(a0),d0
                sub.w   $26(a0),d0
                cmp.w   #$2,d0
                bls.b   .015c6
                clr.w   (a1)                        ; 0-9: normal shots - 1 damage, gone
.015c6:
                moveq   #2,d0
                bsr.w   ObjDamage
                bra.b   .015d6
.015ce:
                clr.w   (a1)
                moveq   #1,d0
                bsr.w   ObjDamage
.015d6:
                subq.l  #$2,a1
                dbra    d7,.01544
                rts
; HitByBits: each owned Bit (an 8x8 box at its centre) does 1 damage to
; the object and also hits the map cell under it (bits 13/12, see DrawMap).
HitByBits:
                move.b  (BitsFlags).l,d7
                btst    #$0,d7
                beq.b   .015f4
                movem.w (UpperBitHitPos).l,d0-d1
                bsr.b   .01606
.015f4:
                btst    #$1,d7
                beq.b   .01604
                movem.w (LowerBitHitPos).l,d0-d1
                bsr.b   .01606
.01604:
                rts
.01606:
                movem.w d0-d1/a4,-(a7)
                addq.w  #$4,d0
                addq.w  #$4,d1
                bsr.w   GetMapCell
                beq.b   .01620
                bset.b  #$5,(a4)
                btst.b  #$4,(a4)
                beq.b   .01620
                clr.w   (a4)
.01620:
                movem.w (a7)+,d0-d1/a4
                moveq   #7,d5
                moveq   #7,d6
                bsr.b   BoxTest
                beq.b   .01632
                moveq   #1,d0
                bra.w   ObjDamage
.01632:
                rts

; BoxTest: d0,d1 vs d3,d4 with sizes -> d0 = 1 if overlapping
BoxTest:
                sub.w   d3,d0                       ; dx: left of the target uses d5, right a3
                bpl.b   .0163c
                neg.w   d0
                bra.b   .0163e
.0163c:
                move.w  a3,d5
.0163e:
                cmp.w   d5,d0
                bhi.b   .01654
                sub.w   d4,d1                       ; dy: above uses d6, below a4
                bpl.b   .0164a
                neg.w   d1
                bra.b   .0164c
.0164a:
                move.w  a4,d6
.0164c:
                cmp.w   d6,d1
                bhi.b   .01654
                moveq   #1,d0                       ; overlap
                rts
.01654:
                moveq   #0,d0
                rts

; ObjDamage: d0 = damage
ObjDamage:
                move.w  $26(a0),d1
                add.w   d0,d1                       ; accumulate damage
                move.w  d1,$26(a0)
                tst.w   $24(a0)                     ; hit points < 0: indestructible
                bmi.b   .016aa
                btst.b  #$1,$23(a0)                 ; carrier: release its power-up
                beq.b   .01674
                bsr.w   ReleasePowerUp
.01674:
                cmp.w   $24(a0),d1                  ; destroyed?
                bcs.b   .01698
                clr.b   $23(a0)
                move.b  #$1,$5(a0)                  ; start the explosion
                clr.l   $6(a0)                      ; no more AI
                addq.l  #$8,a7                      ; drop out of the whole collision check
                movea.l $12(a0),a1
                move.l  $24(a1),d0                  ; definition's score (BCD)
                beq.b   .016aa
                bra.w   AddScore
.01698:
                bset.b  #$0,$23(a0)                 ; not yet: flash white
                move.b  #$3,$28(a0)
                moveq   #6,d0                       ; sound: enemy hit
                bra.w   PlaySound
.016aa:
                rts
; The Force touching an object: 1 damage.  The ship touching it: a power-up
; (flag bit 3) is collected - 400 points, sound 8, and by its frame:
; 0/1/2 blue/red/yellow crystal = LaserType (and the Force gets stronger:
; first crystal level 1, or 2 if docked at the back; later ones level 3),
; 3 speed-up, 4 missiles, 5 a Bit (upper first, then lower).  Anything else
; kills the ship.
HitByForceOrShip:
                movem.w (ForcePos).l,d0-d1
                sub.w   #$5F,d0
                sub.w   #$C,d1
                add.w   (ForceHitbox).l,d0
                add.w   (ForceHitboxY).l,d1
                movem.w (ForceHitboxSize).l,d5-d6
                bsr.w   BoxTest
                beq.b   .016dc
                moveq   #1,d0
                bsr.w   ObjDamage
.016dc:
                movem.w (ShipPos).l,d0-d1
                addq.w  #$5,d0
                add.w   (ShipHitboxY).l,d1
                moveq   #16,d5
                move.w  (ShipHitboxH).l,d6
                bsr.w   BoxTest
                beq.w   .0177e
                btst.b  #$3,$23(a0)
                beq.w   .0179c
                move.l  #$400,d0
                bsr.w   AddScore
                moveq   #8,d0                       ; sound: power-up
                bsr.w   PlaySound
                move.w  #$10,$A(a0)
                move.w  $1E(a0),d0
                cmp.w   #$3,d0
                beq.b   CollectSpeedUp
                cmp.w   #$4,d0
                bne.b   .01734
                st.b    (MissilesEnabled).l
                rts
.01734:
                cmp.w   #$5,d0
                bne.b   .01758
                btst.b  #$0,(BitsFlags).l
                bne.b   .0174e
                bset.b  #$0,(BitsFlags).l
                rts
.0174e:
                bset.b  #$1,(BitsFlags).l
                rts
.01758:
                move.b  d0,(LaserType).l
                tst.b   (ForceActive).l
                beq.b   .01794
                tst.b   (ForceLevel).l
                bne.b   .0178a
                tst.b   (ForceSide).l
                bpl.b   .01780
                move.b  #$2,(ForceLevel).l
.0177e:
                rts
.01780:
                move.b  #$1,(ForceLevel).l
                rts
.0178a:
                move.b  #$3,(ForceLevel).l
                rts
.01794:
                st.b    (ForceActive).l
                rts
.0179c:
                st.b    (ShipHit).l
                rts
; CollectSpeedUp: the S power-up.  Shows the speed-up flash beside the
; ship and raises ShipSpeed by one, to at most 5.
CollectSpeedUp:
                move.l  a0,-(a7)
                moveq   #5,d0
                moveq   #5,d1
                moveq   #-1,d2
                bsr.w   ObjAlloc
                move.l  #DefSpeedFlash,$12(a0)
                move.l  #ObjUpd_SpeedFlash,$6(a0)
                move.l  #SpeedFlashAnim,$2A(a0)
                move.w  #$6,$32(a0)
                bsr.w   ObjInsert
                movem.l (a7)+,a0
                cmpi.w  #$5,(ShipSpeed).l
                bcc.b   .017e6
                addq.w  #$1,(ShipSpeed).l
.017e6:
                rts
; HitByLasers: the 8 laser segments (LaserSegments) against the object's
; box (8x8, or 12x12 for the ground laser).  A segment that hits is used
; up (LaserCount) and does 1 damage.
HitByLasers:
                move.b  (GroundLaserActive).l,d2
                lea.l   (LaserSegments).l,a1
                moveq   #7,d7
.017f6:
                move.w  (a1),d0
                beq.b   .01826
                move.w  $14(a1),d1
                tst.b   d2
                beq.b   .0180a
                addq.w  #$2,d0
                addq.w  #$2,d1
                moveq   #11,d5
                bra.b   .01810
.0180a:
                addq.w  #$7,d0
                addq.w  #$7,d1
                moveq   #7,d5
.01810:
                move.w  d5,d6
                bsr.w   BoxTest
                beq.b   .01826
                clr.w   (a1)
                subq.b  #$1,(LaserCount).l
                moveq   #1,d0
                bsr.w   ObjDamage
.01826:
                addq.l  #$2,a1
                dbra    d7,.017f6
                rts
; ShipHitsMap: the ship's nose (x+18, y+6) in a solid map cell kills it.
ShipHitsMap:
                tst.b   (ShipAlive).l
                beq.b   .01850
                movem.w (ShipPos).l,d0-d1
                add.w   #$12,d0
                addq.w  #$6,d1
                bsr.w   GetMapCell
                beq.b   .01850
                st.b    (ShipHit).l
.01850:
                rts
; ObjUpd_SpeedFlash: the speed-up flash sits behind the ship for $32
; frames, then removes itself.
ObjUpd_SpeedFlash:
                movem.w (ShipPos).l,d0-d1
                sub.w   #$20,d0
                subq.w  #$3,d1
                movem.w d0-d1,$A(a0)
                subq.w  #$1,$32(a0)
                bpl.b   .01872
                jmp     (ObjKillSelf).l
.01872:
                rts

;==============================================================================
; Player weapons: shots, wave cannon, lasers
;==============================================================================
ShipFire:
                tst.b   (ShipAlive).l
                beq.b   .01890
                tst.b   (FireHeld).l
                bne.w   .018da
                btst.b  #$7,(CIAA_PRA).l
                beq.b   .01892
.01890:
                rts
.01892:
                st.b    (FireHeld).l
                bsr.w   FireForce
                moveq   #3,d7
                lea.l   (ShotX3).l,a0
.018a4:
                tst.w   (a0)
                bne.b   .018d2
                movem.w (ShipPos).l,d0-d1
                add.w   #$1B,d0
                addq.w  #$6,d1
                move.w  d0,(a0)
                move.w  d1,$1C(a0)
                tst.b   (ForceSide).l
                beq.b   .018cc
                tst.b   (ForceLevel).l
                bne.b   .018d8
.018cc:
                moveq   #0,d0                       ; sound: ship shot
                bra.w   PlaySound
.018d2:
                subq.l  #$2,a0
                dbra    d7,.018a4
.018d8:
                rts
.018da:
                move.b  (BeamCharge).l,d0
                btst.b  #$7,(CIAA_PRA).l
                beq.b   ShipFireHeld
                cmp.b   #$6,d0
                bls.b   .018f2
                bsr.b   FireWaveCannon
.018f2:
                clr.b   (FireHeld).l
                clr.b   (BeamCharge).l
ClearBeamMeter:
                clr.l   (BeamMeterBits).l
                clr.w   (BeamMeterLevel).l
                moveq   #0,d0
                moveq   #0,d1
                moveq   #0,d2
                bra.w   DrawBeamMeter
ShipFireHeld:
                move.w  d0,d1
                cmp.b   #$18,d1
                bcc.b   .01938
                addq.b  #$1,(BeamCharge).l
                cmpi.b  #$6,(BeamCharge).l
                bne.b   .01932
                moveq   #9,d0                       ; sound: beam charged
                bsr.w   PlaySound
.01932:
                move.w  d1,d0
                bra.w   ChargeBeam
.01938:
                moveq   #13,d0                      ; sound: explosion 3 / beam fully charged
                bsr.w   PlaySound
                bra.b   .01932
FireWaveCannon:
                lea.l   (WaveBeamX).l,a0
                lea.l   (WaveCannonShots).l,a1
                and.w   #$FF,d0
                moveq   #3,d7
.01952:
                cmp.w   (a1)+,d0
                bcs.b   .019a0
                movem.w (ShipPos).l,d0-d1
                add.w   (a1)+,d0
                add.w   (a1)+,d1
                move.w  d0,(a0)
                move.w  d1,$1C(a0)
                move.w  (a1)+,$54(a0)
                move.w  (a1)+,$70(a0)
                move.w  (a1)+,$8C(a0)
                move.w  (a1)+,$A8(a0)
                move.w  (a1)+,(WaveBeamMapOfs).l
                move.w  (a1)+,(WaveBeamModulo).l
                move.w  (a1)+,(WaveBeamBltsize).l
                move.w  (a1)+,$38(a0)
                move.l  (a1)+,(WaveBeamGfx).l
                move.l  (a1)+,(WaveBeamFrameSize).l
                moveq   #1,d0                       ; sound: wave cannon
                bra.w   PlaySound
.019a0:
                adda.l  #$1C,a1
                dbra    d7,.01952
                rts
; UpdateShots: player shot slots 0-9 (the ship's and the free Force's),
; from ShotsX (slot 9) down.  A shot in a solid map cell hits it and dies;
; otherwise it is drawn (ShotTypes), moved, and dies at the screen edge.
UpdateShots:
                move.w  #$30,$60(a6)                ; C/D modulo: 52 - 4 bytes
                move.w  #$30,$66(a6)
                moveq   #9,d7
                lea.l   (ShotsX).l,a0
                lea.l   (ShotTypes).l,a3
.019c6:
                move.w  (a0),d5                     ; x (0 = free slot)
                beq.b   .01a20
                move.w  $1C(a0),d6                  ; y
                move.w  d5,d0
                move.w  d6,d1
                bsr.w   GetMapCell
                beq.b   .019e6
                bset.b  #$5,(a4)                    ; solid cell: mark it hit
                btst.b  #$4,(a4)
                beq.b   .01a18
                clr.w   (a4)                        ; destructible: gone
                bra.b   .01a18
.019e6:
                move.w  d5,d0
                move.w  d6,d3
                move.w  $38(a0),d2                  ; shot type
                lsl.w   #$4,d2
                move.w  $6(a3,d2.w),d1              ; BLTSIZE
                movea.l $8(a3,d2.w),a1              ; graphics
                movea.l $C(a3,d2.w),a2              ; mask
                bsr.b   BlitBob
                add.w   (a3,d2.w),d5                ; move by dx, dy
                add.w   $2(a3,d2.w),d6
                cmp.w   #$170,d5                    ; off screen?
                bcc.b   .01a18
                cmp.w   #$10,d6
                bcs.b   .01a18
                cmp.w   #$F0,d6
                bcs.b   .01a1a
.01a18:
                clr.w   d5                          ; free the slot
.01a1a:
                move.w  d6,$1C(a0)
                move.w  d5,(a0)
.01a20:
                subq.l  #$2,a0
                dbra    d7,.019c6
                rts

; BlitBob: cookie-cut blit, d0,d3 = x,y  a1 = gfx  a2 = mask  d1 = size
BlitBob:
                add.w   (FineScrollX).l,d0
                add.w   (FineScrollY).l,d3
                bsr.w   BlitShift
                lsl.w   #$2,d3
                move.l  (a5,d3.w),d3
                add.l   d0,d3
                add.l   (DrawBuffer).l,d3
                bsr.w   WaitBlit
                move.w  d4,$42(a6)
                or.w    #$FCA,d4
                move.w  d4,$40(a6)
                move.l  a2,$50(a6)
                move.l  d3,$54(a6)
                move.l  d3,$48(a6)
                move.l  a1,$4C(a6)
                move.w  d1,$58(a6)
                rts
UpdateWaveBeam:
                move.w  (WaveBeamX).l,d6
                beq.w   .01b14
                move.w  (WaveBeamY).l,d7
                movea.l (WaveBeamGfx).l,a1
                move.l  (WaveBeamFrameSize).l,d0
                eori.b  #$FF,(WaveBeamToggle).l
                beq.b   .01a96
                adda.l  d0,a1
                adda.l  d0,a1
.01a96:
                movea.l a1,a2
                adda.l  d0,a2
                move.w  (WaveBeamModulo).l,$60(a6)
                move.w  (WaveBeamModulo).l,$66(a6)
                move.w  (WaveBeamBltsize).l,d1
                move.w  d6,d0
.01ab2:
                move.w  d7,d3
                bsr.w   BlitBob
                move.w  d6,d0
                move.w  d7,d1
                addq.w  #$7,d1
                bsr.w   GetMapCell
                beq.b   .01ada
                move.b  (a4),d0
                btst    #$4,d0
                beq.b   .01ad0
                clr.w   (a4)
                bra.b   .01ada
.01ad0:
                btst    #$6,d0
                beq.b   .01b0c
                bset.b  #$5,(a4)
.01ada:
                move.w  (WaveBeamMapOfs).l,d0
                move.b  (a4,d0.w),d1
                btst    #$7,d1
                beq.b   .01b02
                btst    #$4,d1
                beq.b   .01af6
                clr.w   (a4,d0.w)
                bra.b   .01b02
.01af6:
                btst    #$6,d1
                beq.b   .01b0c
                bset.b  #$5,(a4,d0.w)
.01b02:
                add.w   #$E,d6
                cmp.w   #$170,d6
                bcs.b   .01b0e
.01b0c:
                clr.w   d6
.01b0e:
                move.w  d6,(WaveBeamX).l
.01b14:
                move.w  #$2E,$60(a6)
                move.w  #$2E,$66(a6)
                lea.l   ($15650).l,a1           ; shot stream A graphics
                lea.l   (BitShotX).l,a0
                bsr.b   UpdateShotStream
                lea.l   ($15850).l,a1
                addq.w  #$2,a0
                bsr.b   UpdateShotStream
                bra.w   UpdateAntiAirLaser
; 32x4 shot streams ($15650 and $15850, 2 frames of $80 each, plus a
; mirrored pair $100 on for firing backwards).  Like all player shots, a
; hit on a map cell sets bit 13 of the cell (bit 5 of its high byte); a
; cell with bit 12 set is destroyed (cleared to 0).
UpdateShotStream:
                move.w  (a0),d6
                beq.b   .01ba4
                move.w  $1C(a0),d3
                move.w  d6,d0
                move.w  d3,d1
                moveq   #9,d5
                moveq   #20,d4
                tst.b   (LaserSide).l
                bpl.b   .01b5e
                adda.l  #$100,a1
                moveq   #-16,d4
                neg.w   d5
.01b5e:
                add.w   d4,d0
                bsr.w   GetMapCell
                beq.b   .01b72
                bset.b  #$5,(a4)
                btst.b  #$4,(a4)
                beq.b   .01ba0
                clr.w   (a4)
.01b72:
                move.w  d6,d0
                eori.w  #$FFFF,$38(a0)
                beq.b   .01b82
                adda.l  #$80,a1
.01b82:
                movea.l a1,a2
                adda.l  #$40,a2
                move.w  #$403,d1
                bsr.w   BlitBob
                add.w   d5,d6
                cmp.w   #$10,d6
                bcs.b   .01ba0
                cmp.w   #$170,d6
                bcs.b   .01ba2
.01ba0:
                clr.w   d6
.01ba2:
                move.w  d6,(a0)
.01ba4:
                rts
; UpdateAntiAirLaser: the red crystal's laser, the double helix, in shot
; slot 12.  A 64x30 BOB (6 frames, AntiAirLaserFrame steps 4 bytes a
; frame through AntiAirLaserFrames, backwards when fired to the rear)
; moving 10 pixels a frame.  Its front end (x+46, or x+14 backwards; y+14)
; hits map cells: it ends on a solid cell, but destroys destructible
; ones and carries on.  At the screen edge it ends too.  Then UpdateLasers handles the other two lasers.
UpdateAntiAirLaser:
                move.w  (AntiAirLaserX).l,d6        ; not fired: the segment lasers
                beq.w   UpdateLasers
                move.w  (AntiAirLaserY).l,d1
                move.w  #$2A,$60(a6)                ; C/D modulo: 52 - 10 bytes
                move.w  #$2A,$66(a6)
                moveq   #10,d5                      ; speed
                moveq   #46,d7                      ; front end, x offset
                moveq   #4,d2                       ; frame step
                tst.b   (LaserSide).l               ; fired backwards:
                bpl.b   .01bd6
                neg.w   d2
                moveq   #14,d7
                neg.w   d5
.01bd6:
                move.w  d6,d0
                move.w  d1,d3
                move.w  (AntiAirLaserFrame).l,d4    ; next frame (0-20, wraps)
                add.w   d2,d4
                bmi.b   .01bee
                cmp.w   #$14,d4
                bls.b   .01bf0
                moveq   #0,d4
                bra.b   .01bf0
.01bee:
                moveq   #20,d4
.01bf0:
                move.w  d4,(AntiAirLaserFrame).l
                lea.l   (AntiAirLaserFrames).l,a0
                movea.l (a0,d4.w),a1
                movea.l a1,a2
                adda.l  #$3C0,a2                    ; mask follows the graphics
                move.w  d1,-(a7)
                move.w  #$1E05,d1                   ; 30 lines, 5 words
                bsr.w   BlitBob
                move.w  (a7)+,d1
                add.w   #$E,d1
                move.w  d6,d0
                add.w   d7,d0
                bsr.w   GetMapCell                  ; front end in a solid cell?
                beq.b   .01c2e
                bset.b  #$5,(a4)                    ; mark it hit
                btst.b  #$4,(a4)
                beq.b   .01c38                      ; not destructible: the laser ends
                clr.w   (a4)                        ; destroy it if destructible
.01c2e:
                add.w   d5,d6                       ; move on
                bmi.b   .01c38
                cmp.w   #$170,d6
                bcs.b   .01c3a
.01c38:
                clr.w   d6                          ; off screen: gone
.01c3a:
                move.w  d6,(AntiAirLaserX).l
; The two segmented lasers (LaserSegments: 8 parallel word arrays, x +0,
; y +$14, steps left +$28, delay +$3C, direction +$50):
;   blue reflect laser: 16x16 segments ($19B90, 2 frames: diagonal up /
;     down).  Each step tries the moves in ReflectLaserMoves for its
;     direction (4 x 10 bytes: dx, dy, new direction, map offset.l) until
;     one isn't solid - i.e. it bounces off walls (sound 2).  A solid
;     animated cell (map bit 14) is marked hit and stops it instead.  75 steps ($4B) then it is gone.
;   yellow ground laser (GroundLaserActive): 16x14 segments
;     (GroundLaserFrames), moves from GroundLaserMoves chosen so that it
;     keeps to solid surfaces - it crawls along the floor and ceiling.
UpdateLasers:
                tst.b   (LaserCount).l
                beq.w   .01d1c
                move.w  #$30,$60(a6)
                move.w  #$30,$66(a6)
                lea.l   (LaserSegments).l,a0
                moveq   #7,d7
                moveq   #0,d6
                tst.b   (GroundLaserActive).l
                bne.w   .01d1e
.01c6a:
                move.w  (a0),d0
                beq.w   .01d16
                move.w  $14(a0),d1
                bsr.w   AdjustForScroll
                move.w  d0,(a0)
                tst.w   $3C(a0)
                beq.b   .01c88
                subq.w  #$1,$3C(a0)
                bra.w   .01d16
.01c88:
                move.w  d1,d3
                movem.w d0-d1,-(a7)
                move.w  #$1002,d1
                lea.l   ($19B90).l,a1
                move.w  $50(a0),d6
                btst    #$0,d6
                beq.b   .01ca8
                adda.l  #$100,a1
.01ca8:
                movea.l a1,a2
                adda.l  #$80,a2
                bsr.w   BlitBob
                lea.l   (ReflectLaserMoves).l,a3
                mulu.w  #$28,d6
                adda.l  d6,a3
                movem.w (a7),d0-d1
                addq.w  #$7,d0
                addq.w  #$7,d1
                bsr.w   GetMapCell
                movem.w (a7)+,d2-d3
.01cd0:
                move.w  d2,d0
                move.w  d3,d1
                movea.l a4,a1
                add.w   (a3)+,d0
                add.w   (a3)+,d1
                move.w  (a3)+,d6
                adda.l  (a3)+,a1
                btst.b  #$7,(a1)
                beq.b   .01cf8
                btst.b  #$6,(a1)
                beq.b   .01cf0
                bset.b  #$5,(a1)
                bra.b   .01d0e
.01cf0:
                moveq   #2,d0                       ; sound: reflect laser bounce
                bsr.w   PlaySound
                bra.b   .01cd0
.01cf8:
                subq.w  #$1,$28(a0)
                bmi.b   .01d0e
                bsr.w   ClipLaser
                move.w  d0,(a0)
                move.w  d1,$14(a0)
                move.w  d6,$50(a0)
                bra.b   .01d16
.01d0e:
                clr.w   (a0)
                subq.b  #$1,(LaserCount).l
.01d16:
                addq.w  #$2,a0
                dbra    d7,.01c6a
.01d1c:
                rts
.01d1e:
                move.w  (a0),d0
                beq.w   .01daa
                move.w  $14(a0),d1
                bsr.w   AdjustForScroll
                move.w  d0,(a0)
                tst.w   $3C(a0)
                beq.b   .01d3c
                subq.w  #$1,$3C(a0)
                bra.w   .01daa
.01d3c:
                move.w  d1,d3
                movem.w d0-d1,-(a7)
                move.w  $50(a0),d6
                move.w  d6,d5
                lea.l   (GroundLaserFrames).l,a1
                lsl.w   #$2,d5
                movea.l (a1,d5.w),a1
                movea.l a1,a2
                adda.l  #$70,a2
                move.w  #$E02,d1
                bsr.w   BlitBob
                mulu.w  #$28,d6
                lea.l   (GroundLaserMoves).l,a3
                adda.l  d6,a3
                move.w  $28(a0),d6
                adda.l  d6,a3
                movem.w (a7),d0-d1
                addq.w  #$7,d0
                addq.w  #$7,d1
                bsr.w   GetMapCell
                movem.w (a7)+,d2-d3
.01d86:
                move.w  d2,d0
                move.w  d3,d1
                movea.l a4,a1
                add.w   (a3)+,d0
                add.w   (a3)+,d1
                move.w  (a3)+,d6
                bmi.b   .01db2
                adda.l  (a3)+,a1
                btst.b  #$7,(a1)
                bne.b   .01d86
                bsr.w   ClipLaser
.01da0:
                move.w  d0,(a0)
                move.w  d1,$14(a0)
                move.w  d6,$50(a0)
.01daa:
                addq.w  #$2,a0
                dbra    d7,.01d1e
                rts
.01db2:
                clr.w   d0
                subq.b  #$1,(LaserCount).l
                bra.b   .01da0
; ClipLaser: d0,d1 = a laser segment's position; outside the play area it
; is removed (d0 = 0, LaserCount - 1).
ClipLaser:
                cmp.w   #$26,d0
                blt.b   .01dd6
                cmp.w   #$170,d0
                bhi.b   .01dd6
                cmp.w   #$10,d1
                blt.b   .01dd6
                cmp.w   #$E0,d1
                bhi.b   .01dd6
                rts
.01dd6:
                clr.w   d0
                subq.b  #$1,(LaserCount).l
FireForceDone:
                rts
; Called with every fire-button press.  What the Force fires:
;   free (ForceSide 0): its own shots (ShotTypes) - level 0: one forward
;      shot; level 1+: up-right and down-right; level 3: also up and down
;   docked (ForceSide +/-1, level 1+): by LaserType, the colour of the
;      last crystal collected (set in HitByForceOrShip):
;        1    red: anti-air laser, the double helix (sound 3)
;        0    blue: reflect laser - segments bounce off walls diagonally
;        2    yellow: ground laser - segments crawl along surfaces
;        0/2  use LaserSegments - 4 segments at levels
;             1-2, 8 at level 3; the ground laser sets GroundLaserActive (sound 4)
;      fired forwards or backwards by the docking side (LaserSide).
FireForce:
                tst.b   (ForceActive).l
                beq.b   FireForceDone
                movem.w (ForcePos).l,d0-d1
                sub.w   #$5F,d0
                sub.w   #$C,d1
                move.b  (ForceLevel).l,d6
                move.b  (ForceSide).l,d7
                bne.w   .01e72
                addq.w  #$4,d1
                add.w   #$A,d0
                tst.b   d6
                bne.b   .01e26
                lea.l   (ShotX7).l,a0
                moveq   #0,d3
                moveq   #3,d7
                moveq   #0,d2
                moveq   #12,d4
                moveq   #4,d5
                bra.w   .0202e
.01e26:
                moveq   #2,d2
                moveq   #8,d4
                moveq   #9,d5
                lea.l   (ShotX5).l,a0
                moveq   #1,d3
                moveq   #1,d7
                bsr.w   .0202e
                moveq   #2,d3
                moveq   #1,d7
                lea.l   (ShotX7).l,a0
                bsr.w   .0202e
                cmp.b   #$3,d6
                bne.b   .01e70
                moveq   #3,d3
                moveq   #0,d7
                moveq   #0,d2
                moveq   #4,d4
                moveq   #11,d5
                lea.l   (ShotsX).l,a0
                bsr.w   .0202e
                moveq   #0,d7
                moveq   #4,d3
                lea.l   (ShotX8).l,a0
                bra.w   .0202e
.01e70:
                rts
.01e72:
                tst.b   d6
                beq.b   .01e70
                move.b  d7,(LaserSide).l
                move.b  (LaserType).l,d5
                bne.w   .01f0a
                tst.b   (LaserCount).l
                bne.w   .01f08
                cmp.b   #$3,d6
                bne.b   .01ea2
                moveq   #3,d6
                move.b  #$8,(LaserCount).l
                bra.b   .01eac
.01ea2:
                moveq   #1,d6
                move.b  #$4,(LaserCount).l
.01eac:
                movem.w (ShipPos).l,d0-d1
                tst.b   d7
                bmi.b   .01ec2
                moveq   #0,d4
                moveq   #3,d5
                add.w   #$1E,d0
                bra.b   .01eca
.01ec2:
                moveq   #1,d4
                moveq   #2,d5
                add.w   #$FFEC,d0
.01eca:
                lea.l   (LaserSegments).l,a0
                moveq   #0,d3
.01ed2:
                move.w  d1,$14(a0)
                move.w  #$4B,$28(a0)
                move.w  d3,$3C(a0)
                move.w  d4,$50(a0)
                move.w  d1,$1C(a0)
                move.w  #$4B,$30(a0)
                move.w  d3,$44(a0)
                move.w  d5,$58(a0)
                move.w  d0,$8(a0)
                move.w  d0,(a0)+
                addq.w  #$1,d3
                dbra    d6,.01ed2
                clr.b   (GroundLaserActive).l
.01f08:
                rts
.01f0a:
                cmp.b   #$1,d5
                beq.w   .01f88
                tst.b   (LaserCount).l
                bne.b   .01f08
                move.b  #$8,(LaserCount).l
                moveq   #3,d6
                lea.l   (LaserSegments).l,a0
                movem.w (ShipPos).l,d0-d1
                tst.b   d7
                bpl.b   .01f40
                sub.w   #$10,d0
                movea.w #$140,a1
                bra.b   .01f46
.01f40:
                add.w   #$1E,d0
                suba.w  a1,a1
.01f46:
                movea.w a1,a2
                adda.w  #$A0,a2
                moveq   #0,d3
.01f4e:
                move.w  d1,$14(a0)
                move.w  d3,$3C(a0)
                move.w  a1,$28(a0)
                clr.w   $50(a0)
                move.w  d1,$1C(a0)
                move.w  d3,$44(a0)
                move.w  a2,$30(a0)
                move.w  #$2,$58(a0)
                move.w  d0,$8(a0)
                move.w  d0,(a0)+
                addq.w  #$1,d3
                dbra    d6,.01f4e
                st.b    (GroundLaserActive).l
                moveq   #4,d0                       ; sound: ground laser
                bra.w   PlaySound
.01f88:
                tst.b   d7
                bpl.b   .01f96
                moveq   #4,d5
                moveq   #-48,d3
                moveq   #-18,d2
                moveq   #-28,d4
                bra.b   .01f9e
.01f96:
                moveq   #20,d5
                moveq   #16,d3
                moveq   #15,d2
                moveq   #2,d4
.01f9e:
                move.w  d0,-(a7)
                moveq   #3,d0                       ; sound: anti-air laser
                bsr.w   PlaySound
                move.w  (a7)+,d0
                cmp.b   #$2,d6
                bhi.b   .01fce
                add.w   d2,d0
                lea.l   (BitShotX).l,a0
                bsr.b   .01fbe
                add.w   #$C,d1
                addq.l  #$2,a0
.01fbe:
                tst.w   (a0)
                bne.b   .01fcc
                clr.w   d2
                clr.w   d3
                moveq   #20,d4
                moveq   #4,d5
                bra.b   .02032
.01fcc:
                rts
.01fce:
                movem.w d0-d1/d3/d5,-(a7)
                btst.b  #$0,(BitsFlags).l
                beq.b   .01ff4
                lea.l   (BitShotX).l,a0
                movem.w (UpperBitHitPos).l,d0-d1
                addq.w  #$2,d1
                move.w  d4,-(a7)
                add.w   d4,d0
                bsr.b   .01fbe
                move.w  (a7)+,d4
.01ff4:
                btst.b  #$1,(BitsFlags).l
                beq.b   .0200e
                addq.l  #$2,a0
                movem.w (LowerBitHitPos).l,d0-d1
                addq.w  #$2,d1
                add.w   d4,d0
                bsr.b   .01fbe
.0200e:
                movem.w (a7)+,d0-d1/d3/d5
                lea.l   (AntiAirLaserX).l,a0
                tst.w   (a0)
                bne.b   .01fcc
                subq.w  #$5,d1
                add.w   d3,d0
                bpl.b   .02024
                moveq   #0,d0
.02024:
                move.w  d5,d3
                moveq   #2,d2
                moveq   #58,d4
                moveq   #26,d5
                bra.b   .02032
.0202e:
                tst.w   (a0)
                bne.b   .0204e
.02032:
                move.w  d3,$38(a0)
                move.w  d0,(a0)
                move.w  d1,$1C(a0)
                move.w  d2,$54(a0)
                move.w  d2,$70(a0)
                move.w  d4,$8C(a0)
                move.w  d5,$A8(a0)
                rts
.0204e:
                subq.l  #$2,a0
                dbra    d7,.0202e
                rts
; ChargeBeam: one step of the beam meter while fire is held.  The meter
; is 3 longs of pixels (DrawBeamMeter): BeamMeterBits fills the current
; long 4 pixels at a time from the left; when it is full BeamMeterLevel
; moves to the next long, and at level 2 it stays full.
ChargeBeam:
                move.l  (BeamMeterBits).l,d5
                lsr.l   #$4,d5
                or.l    #$F0000000,d5
                move.l  d5,(BeamMeterBits).l
                cmp.b   #$FF,d5
                bne.b   .02096
                moveq   #0,d5
                move.l  d5,(BeamMeterBits).l
                addq.w  #$1,(BeamMeterLevel).l
                cmpi.w  #$3,(BeamMeterLevel).l
                blt.b   .02096
                subq.w  #$1,(BeamMeterLevel).l
                moveq   #-1,d5
                move.l  d5,(BeamMeterBits).l
.02096:
                move.w  (BeamMeterLevel).l,d7
                bne.b   .020a6
                move.l  d5,d0
                moveq   #0,d1
                moveq   #0,d2
                bra.b   DrawBeamMeter
.020a6:
                cmp.b   #$1,d7
                bne.b   .020b4
                moveq   #-1,d0
                move.l  d5,d1
                moveq   #0,d2
                bra.b   DrawBeamMeter
.020b4:
                moveq   #-1,d0
                moveq   #-1,d1
                move.l  d5,d2
DrawBeamMeter:
                lea.l   ($2C7E8).l,a0           ; HUD: beam meter position
                move.l  d0,(a0)
                move.l  d0,$28(a0)
                move.l  d0,$50(a0)
                move.l  d0,$78(a0)
                move.l  d0,$A0(a0)
                move.l  d1,$4(a0)
                move.l  d1,$2C(a0)
                move.l  d1,$54(a0)
                move.l  d1,$7C(a0)
                move.l  d1,$A4(a0)
                move.l  d2,$8(a0)
                move.l  d2,$30(a0)
                move.l  d2,$58(a0)
                move.l  d2,$80(a0)
                move.l  d2,$A8(a0)
                rts

;==============================================================================
; Level 3 interrupt: VBL and copper
;==============================================================================
Level3Int:
                movem.l d0-d7/a0-a6,-(a7)
                move.w  (CUSTOM+INTREQR).l,d0       ; which level 3 source?
                btst    #$4,d0                      ; COPER: copper interrupt at line $EC
                bne.w   CopperInt                   ; -> sprites and buffer swap
                btst    #$5,d0                      ; VERTB
                bne.b   .02118
                bra.w   .0218a
.02118:
                addq.l  #$1,(VblCount).l            ; 50 Hz frame counter
                tst.b   (TitleMusicOn).l            ; TFMX title tune playing?
                beq.b   .0212c
                jsr     (MUSIC_PLAY).l              ; TFMX replay
.0212c:
                tst.b   (JinglePlaying).l           ; title/high-score jingle?
                beq.b   .02138
                bsr.w   UpdateJingle
.02138:
                tst.b   (MusicFadeReq).l            ; music fade requested (-1 start, 1 waiting)
                beq.b   .0216a
                bpl.b   .02154
                move.b  #$FF,(MusicRequest).l
                move.b  #$1,(MusicFadeReq).l
                bra.b   .0216a
.02154:
                tst.b   (MusicRequest).l
                bne.b   .0216a
                move.b  #$2,(MusicRequest).l
                clr.b   (MusicFadeReq).l
.0216a:
                bsr.w   UpdateMusic                 ; level music (LV_Music)
                bsr.w   UpdateSound                 ; start queued sound effects
                tst.b   (Paused).l
                bne.b   .0218a
                subq.w  #$1,(ShipUpdatesLeft).l     ; ship moves once per VBL, at most
                bmi.b   .0218a
                bsr.w   ShipControl                 ; joystick -> ship position (50 Hz even when
                bsr.w   UpdateBits                  ; the game frame runs at 25 Hz)
.0218a:
                move.w  #$60,(CUSTOM+INTREQ).l      ; acknowledge VERTB and BLIT
                movem.l (a7)+,d0-d7/a0-a6
                rte
ShipNoControl:
                rts

;==============================================================================
; Ship movement
;==============================================================================
ShipControl:
                tst.b   (ShipHit).l                 ; no control while exploding
                bne.b   ShipNoControl
                tst.b   (ShipMode).l                ; -1: stage-end autopilot, 1: fly-in
                bmi.w   ShipAutoPilot
                bne.w   ShipFlyIn
                move.w  (CUSTOM+JOY1DAT).l,d0       ; joystick in port 2
                move.w  (ShipSpeed).l,d2            ; pixels per VBL (speed-ups add to it)
                move.w  d0,d1
                asl.w   #$1,d1                      ; up = bit 9 ^ bit 8, down = bit 1 ^ bit 0
                eor.w   d0,d1
                btst    #$9,d0                      ; left
                beq.b   .021da
                cmpi.w  #$96,(ShipX).l              ; left limit
                bls.b   .021f0
                sub.w   d2,(ShipX).l
                bra.b   .021f0
.021da:
                btst    #$1,d0                      ; right
                beq.b   .021f0
                cmpi.w  #$1A0,(ShipX).l             ; right limit
                bhi.b   .021f0
                add.w   d2,(ShipX).l
.021f0:
                btst    #$9,d1                      ; up
                beq.b   .02212
                cmpi.w  #$30,(ShipY).l              ; top limit
                bls.w   ShipTiltLevel
                sub.w   d2,(ShipY).l
                move.b  #$FF,(ShipTiltInput).l      ; tilt towards frame 0 (nose up)
                bra.b   ShipTilt
.02212:
                btst    #$1,d1                      ; down
                beq.b   ShipTiltLevel
                cmpi.w  #$DC,(ShipY).l              ; bottom limit
                bcc.w   ShipTiltLevel
                add.w   d2,(ShipY).l
                move.b  #$1,(ShipTiltInput).l       ; tilt towards frame 16
                bra.b   ShipTilt
ShipTiltLevel:
                cmpi.b  #$8,(ShipTiltFrame).l       ; no vertical input: drift back to level (8)
                bhi.b   .0224a
                beq.b   .02254
                move.b  #$1,(ShipTiltInput).l
                bra.b   ShipTilt
.0224a:
                move.b  #$FF,(ShipTiltInput).l
                bra.b   ShipTilt
.02254:
                clr.b   (ShipTiltInput).l
; Ship frames: $6000 + n*$100, n = 0..4 (tilt; 2 = level).  Each frame is
; 4 sprites of 14 lines ($40 bytes): left pair (SPR4/5), right pair (SPR6/7).
ShipTilt:
                moveq   #0,d0
                move.b  (ShipTiltFrame).l,d0
                add.b   (ShipTiltInput).l,d0        ; tilt frame 0..16
                bpl.b   .0226e
                moveq   #0,d0
                bra.b   .02276
.0226e:
                cmp.b   #$10,d0
                bls.b   .02276
                moveq   #16,d0
.02276:
                move.b  d0,(ShipTiltFrame).l
                lsr.b   #$2,d0                      ; -> sprite frame 0..4
                lea.l   (ShipTiltTable).l,a0
                move.b  (a0,d0.w),d1
                ext.w   d1
                move.w  d1,(ShipHitboxY).l          ; hit box follows the tilt
                move.b  $5(a0,d0.w),d1
                ext.w   d1
                move.w  d1,(ShipHitboxH).l
                lsl.w   #$8,d0                      ; frame * $100
                add.l   #$6000,d0               ; ship sprite frames
                move.l  d0,(ShipSpriteFrame).l
ShipTiltDone:
                rts
; Level start: StageFlags bit 0 = intro running.  The ship flies right to
; x $186 (bit 2), waits ShipIntroTimer (bit 3), flies back to x $C8 and
; gets control (bit 1, ShipMode 0).  Tilt changes every 5th VBL.
ShipFlyIn:
                move.b  (StageFlags).l,d7
                btst    #$0,d7
                beq.b   ShipTiltDone
                btst    #$2,d7
                bne.b   .022ee
                move.b  #$FF,(ShipTiltInput).l
                lea.l   ShipTilt(pc),a0
                bsr.b   .02334
                addq.w  #$2,(ShipX).l
                cmpi.w  #$186,(ShipX).l
                bcs.b   ShipTiltDone
                bset.b  #$2,(StageFlags).l
                move.b  #$F,(ShipIntroTimer).l
                rts
.022ee:
                btst    #$3,d7
                beq.b   .0231a
                lea.l   ShipTiltLevel(pc),a0
                bsr.b   .02334
                subq.w  #$2,(ShipX).l
                cmpi.w  #$C8,(ShipX).l
                bhi.b   ShipTiltDone
                bset.b  #$1,(StageFlags).l
                clr.b   (ShipMode).l
                rts
.0231a:
                subq.b  #$1,(ShipIntroTimer).l
                bpl.b   ShipTiltDone
                bset.b  #$3,(StageFlags).l
                move.b  #$A,(ShipIntroTimer).l
                rts
.02334:
                subq.b  #$1,(ShipIntroTimer).l
                bpl.b   .02346
                move.b  #$4,(ShipIntroTimer).l
                jmp     (a0)
.02346:
                rts
; Autopilot (ShipMode < 0): the ship steers itself to AutoPilotX/Y, one
; pixel per VBL on each axis.  Target: ($10E,$96) at a normal stage end
; (EndSequenceFlags bit 0 clear); in the final ending ($C8,$82) with
; weapons reset, then ($1C2,$A) once bit 7 is set (bit 1 starts the
; ending jingle).  StageFlags bit 7 is set when the target is reached.
ShipAutoPilot:
                move.b  (EndSequenceFlags).l,d0
                btst    #$0,d0
                beq.b   .023ac
                btst    #$2,d0
                beq.b   .0236a
                move.w  #$1C2,(AutoPilotX).l
                move.w  #$A,(AutoPilotY).l
.0236a:
                btst    #$7,d0
                bne.b   .023bc
                move.w  d0,-(a7)
                bsr.w   ResetShipWeapons
                move.w  (a7)+,d0
                clr.b   (ShipAlive).l
                move.w  #$82,(AutoPilotY).l
                move.w  #$C8,(AutoPilotX).l
                btst    #$1,d0
                beq.b   .023bc
                move.b  #$FF,(JingleCmd).l
                st.b    (JinglePlaying).l
                bset.b  #$7,(EndSequenceFlags).l
                bra.b   .023bc
.023ac:
                move.w  #$10E,(AutoPilotX).l
                move.w  #$96,(AutoPilotY).l
.023bc:
                moveq   #0,d4
                movem.w (ShipX).l,d0-d1
                moveq   #-1,d2
                sub.w   (AutoPilotX).l,d0
                beq.b   .023de
                bpl.b   .023d6
                neg.w   d2
                neg.w   d0
.023d6:
                add.w   d2,(ShipX).l
                addq.w  #$1,d4
.023de:
                move.b  #$FF,(ShipTiltInput).l
                moveq   #-1,d3
                sub.w   (AutoPilotY).l,d1
                beq.w   .02408
                bpl.b   .023fe
                neg.w   d3
                neg.w   d1
                neg.b   (ShipTiltInput).l
.023fe:
                add.w   d3,(ShipY).l
                bra.w   ShipTilt
.02408:
                tst.b   d4
                bne.w   ShipTiltLevel
                bset.b  #$7,(StageFlags).l
                bra.w   ShipTiltLevel

;==============================================================================
; Bits (the two satellites)
;==============================================================================
; Bit frames: 11 of $70 bytes from $6500 to $69CF (one attached pair of 12
; lines each), cycled to make the Bits spin.
InitBits:
                lea.l   ($6500).w,a0
                move.l  a0,(UpperBitFrame).l
                move.l  a0,(LowerBitFrame).l
                clr.b   (BitsFlags).l
                clr.w   (UpperBitPos).l
                clr.w   (LowerBitPos).l
                move.w  #$1E,(UpperBitY).l
                move.w  #$10E,(LowerBitY).l
                clr.w   (UpperBitTrail).l
                clr.w   (LowerBitTrail).l
                move.w  #$1,(UpperBitTrailOut).l
                move.w  #$1,(LowerBitTrailOut).l
                lea.l   ($49342).l,a0
                moveq   #2,d0
.02470:
                move.w  #$1E,$6(a0)
                move.w  #$10E,$12(a0)
                clr.w   $C(a0)
                clr.w   (a0)+
                dbra    d0,.02470
                rts
; The Bits trail the ship: every VBL the ship's position is written into a
; small ring buffer ($49342 upper, $4934E lower; head/tail/timer in
; UpperBitTrail/LowerBitTrail) and each Bit is placed at an older entry,
; 25 pixels above / 29 below the ship (y clamped to $22-$10E).  BitsFlags
; bit 0/1 = upper/lower Bit owned.  UpperBitHitPos/LowerBitHitPos are the
; same positions in game coordinates, for collisions.
UpdateBits:
                move.b  (BitsFlags).l,d7
                lsr.b   #$1,d7
                bcc.b   .024ba
                lea.l   ($49342).l,a0
                lea.l   (UpperBitTrail).l,a1
                moveq   #-25,d2
                bsr.b   .024e8
                movem.w d2-d3,(UpperBitPos).l
                sub.w   #$5F,d2
                sub.w   #$C,d3
                movem.w d2-d3,(UpperBitHitPos).l
.024ba:
                lsr.w   #$1,d7
                bcc.b   .024e6
                lea.l   ($4934E).l,a0
                lea.l   (LowerBitTrail).l,a1
                moveq   #29,d2
                bsr.b   .024e8
                movem.w d2-d3,(LowerBitPos).l
                sub.w   #$5F,d2
                sub.w   #$C,d3
                movem.w d2-d3,(LowerBitHitPos).l
.024e6:
                rts
.024e8:
                move.w  (a1),d0
                bsr.w   .02562
                move.w  d0,(a1)
                lsl.w   #$1,d0
                move.w  (ShipX).l,d1
                addq.w  #$5,d1
                move.w  d1,(a0,d0.w)
                move.w  (ShipY).l,d1
                add.w   d2,d1
                move.w  d1,$6(a0,d0.w)
                addq.w  #$1,(a1)
                move.w  $2(a1),d0
                bsr.b   .02562
                move.w  d0,$2(a1)
                lsl.w   #$1,d0
                move.w  (a0,d0.w),d2
                move.w  $6(a0,d0.w),d3
                cmp.w   #$22,d3
                bcc.b   .02528
                moveq   #34,d3
.02528:
                cmp.w   #$10E,d3
                bls.b   .02532
                move.w  #$10E,d3
.02532:
                addq.w  #$1,$2(a1)
                move.w  d2,d4
                move.w  d3,d5
                subq.w  #$1,$4(a1)
                bpl.b   .02560
                move.w  #$3,$4(a1)
                movea.l $6(a1),a0
                adda.l  #$70,a0
                cmpa.l  #$69D0,a0
                bls.b   .0255c
                lea.l   ($6500).w,a0
.0255c:
                move.l  a0,$6(a1)
.02560:
                rts
.02562:
                cmp.w   #$3,d0
                bcs.b   .0256a
                clr.w   d0
.0256a:
                rts

;==============================================================================
; Copper interrupt: hardware sprites for ship, bits and Force
;==============================================================================
; Copper interrupt at line $EC (end of the playfield).  Hardware sprites:
; channels 4-7 as attached pairs (16 colours, COLOR16-31), reused down the
; screen by chaining several sprites in one channel:
;   $490A2 upper Bit   $490D6 ship, left half   $49112 lower Bit  (SPR4/5)
;   $491F2 ship, right half                                       (SPR6/7)
; The attached partner of each sprite is $A8 bytes further on.  SPR0-3 show
; the Force: UpdateForce points them straight at its frames in the $6000
; block (two attached pairs = 32 pixels wide).
CopperInt:
                lea.l   (CUSTOM).l,a6
                move.w  #$10,$9C(a6)                ; acknowledge COPER
                bsr.w   SwapScreens                 ; flip buffers if a frame is ready
                bsr.w   UpdateForce                 ; Force: animate, aim SPR0-3, run its state
                lea.l   ($490A2).l,a0               ; upper Bit into SPR4/5 (13 longs)
                movea.l (UpperBitFrame).l,a1
                move.w  #$C,d3
                bsr.w   CopySprite
                lea.l   ($490D6).l,a0               ; ship left half, chained below it
                movea.l (ShipSpriteFrame).l,a1
                move.w  #$E,d3
                bsr.w   CopySprite
                lea.l   ($491F2).l,a0               ; ship right half into SPR6/7
                bsr.w   CopySprite
                lea.l   ($49112).l,a0               ; lower Bit, chained in SPR4/5
                movea.l (LowerBitFrame).l,a1
                move.w  #$C,d3
                bsr.w   CopySprite
                lea.l   ($490A2).l,a0
                movem.w (UpperBitPos).l,d0-d1       ; now the positions:
                moveq   #12,d2
                move.w  #$A8,d3
                bsr.b   SetSprite
                lea.l   ($490D6).l,a0
                movem.w (ShipX).l,d0-d1
                move.b  (ShipAlive).l,d6            ; while respawning the ship blinks:
                bne.b   .025fe
                btst.b  #$1,(VblCountLoByte).l      ; every other 2 VBLs ...
                beq.b   .025fe
                moveq   #95,d0                      ; ... it is put off-screen
.025fe:
                moveq   #14,d2
                bsr.b   SetSprite
                add.w   #$10,d0                     ; right half 16 pixels on
                lea.l   ($491F2).l,a0
                bsr.b   SetSprite
                sub.w   #$6F,d0                     ; ship x in game coordinates
                beq.b   .02620
                sub.w   #$C,d1
                movem.w d0-d1,(ShipPos).l           ; -> ShipPos for the game and levels
.02620:
                lea.l   ($49112).l,a0
                movem.w (LowerBitPos).l,d0-d1
                moveq   #12,d2
                bsr.b   SetSprite
                movem.l (a7)+,d0-d7/a0-a6
                rte

; SetSprite: d0,d1 = x,y  d2 = height  a0 = sprite
; Builds SPRxPOS/SPRxCTL from x,y,height; the second control word (d3 bytes
; on) gets the ATTACH bit (bit 7).
SetSprite:
                movem.w d0-d1,-(a7)
                clr.w   d5
                move.w  d1,d4
                lsl.w   #$8,d4
                bcc.b   .02648
                bset    #$1,d5
.02648:
                lsr.w   #$1,d0
                roxl.w  #$1,d5
                move.b  d0,d4
                add.w   d2,d1
                lsl.w   #$8,d1
                bcc.b   .02658
                bset    #$1,d5
.02658:
                or.w    d1,d5
                swap    d4
                move.w  d5,d4
                move.l  d4,(a0)
                bset    #$7,d4
                move.l  d4,(a0,d3.w)
                movem.w (a7)+,d0-d1
                rts
; Sprite data layout used for the ship, Bits and Force (in the $6000 block):
;   control long, h lines of (plane A word, plane B word), end long
;   = 4 + h*4 + 4 bytes; the attached partner (planes 2/3) follows directly.
; CopySprite copies d3+1 longs (control + lines) for both sprites of a pair,
; skipping the end long of each.
CopySprite:
                moveq   #1,d1
                movea.l a0,a2
.02672:
                move.w  d3,d2
.02674:
                move.l  (a1)+,(a0)+
                dbra    d2,.02674
                adda.l  #$A8,a2
                movea.l a2,a0
                addq.l  #$4,a1
                dbra    d1,.02672
                rts

;==============================================================================
; Double buffering
;==============================================================================
SwapScreens:
                subq.w  #$1,(FlipCountdown).l       ; VBLs to wait before the next flip
                tst.b   (FrameReady).l              ; a finished frame waiting?
                beq.b   .026d0
                tst.w   (FlipCountdown).l           ; and enough VBLs since the last flip?
                bpl.b   .026d0
                bsr.b   SetBitplanes                ; show it, draw into the other buffer
                tst.b   (Flip50Hz).l                ; title/high scores: every VBL
                beq.b   .026ba
                clr.w   (FlipCountdown).l           ; 50 Hz: flip again next VBL
                move.w  #$1,(ShipUpdatesLeft).l     ; one ship update per frame
                bra.b   .026ca
.026ba:
                move.w  #$1,(FlipCountdown).l       ; game: 25 Hz, skip one VBL
                move.w  #$2,(ShipUpdatesLeft).l     ; two ship updates per frame
.026ca:
                clr.b   (FrameReady).l              ; main loop may draw the next frame
.026d0:
                rts
; Display layout (see docs/GRAPHICS.md)
;   Playfield: 4 bitplanes, INTERLEAVED.  Each screen line is 4 x 52 bytes
;   ($D0): plane 0..3 one after the other, 52 bytes = 416 pixels so that the
;   320-pixel view can scroll over a 16-pixel tile margin.  BPLxMOD = $A8
;   (= 3*52 + 52-40).  A buffer is 272 lines ($DD00 bytes); the view starts
;   32 lines and 6 bytes in ($1A06), plus FineScrollY lines.
;   SCREEN_A $2D1BA / SCREEN_B $3AEBA: the copper shows one while the game
;   draws into the other (DrawBuffer).  Fine horizontal scroll is BPLCON1.
SetBitplanes:
                move.w  (ScrollBplcon1).l,(CopBplcon1).l; fine x scroll into the copper list
                lea.l   ($48BBA).l,a0
                move.w  (FineScrollY).l,d0          ; fine y scroll = start line 0-15
                lsl.w   #$2,d0
                move.l  (a0,d0.w),d0
                eori.b  #$FF,(BufferToggle).l       ; alternate the two buffers
                bne.b   .0270a
                add.l   #$2EBC0,d0                  ; show SCREEN_A + $1A06 ...
                move.l  #SCREEN_B,(DrawBuffer).l    ; ... and draw into SCREEN_B
                bra.b   .0271a
.0270a:
                add.l   #$3C8C0,d0                  ; show SCREEN_B + $1A06 ...
                move.l  #SCREEN_A,(DrawBuffer).l    ; ... and draw into SCREEN_A
.0271a:
                lea.l   (CopBplPtrs).l,a0
                moveq   #3,d1
                moveq   #52,d2                      ; planes are interleaved: 52 bytes apart
; SetCopperPtrs: a0 = copper pointer pair(s), d0 = address, d1 = count-1,
; d2 = step: writes the high and low words of each pointer.
SetCopperPtrs:
                move.w  d0,$4(a0)
                swap    d0
                move.w  d0,(a0)
                swap    d0
                add.l   d2,d0
                addq.l  #$8,a0
                dbra    d1,SetCopperPtrs
                rts

;==============================================================================
; The Force
;==============================================================================
; Force animation table at $516C: 16 bytes per Force level
;   +0.l first frame  +4.l last frame  +8.l frame size  +$D.b frames per
;   step  +$E.w height.  Level 0: $6A40-$6F40 ($100, 14 lines), 1: $7040-
;   $7630 ($130, 17), 2: $7760-$7D50 ($130, 17), 3: $7E80-$8300 ($180, 22).
; A frame = 4 sprites (two attached pairs), size/4 bytes each; the copper's
; SPR0-3 pointers are aimed at them (SetCopperPtrs) - no copying.
UpdateForce:
                move.b  (ForceLevel).l,d0
                cmp.b   (ForceAnimLevel).l,d0
                beq.b   .0275c
                move.b  d0,(ForceAnimLevel).l
                clr.b   (ForceAnimTimer).l
                move.l  #$1E0,(ForceFrame).l
.0275c:
                moveq   #0,d1
                move.b  (ForceAnimLevel).l,d1
                move.w  d1,d2
                lsl.w   #$2,d2
                lea.l   (ForceSpriteOffsets).l,a0
                move.w  (a0,d2.w),(ForceOfsX).l
                move.w  $2(a0,d2.w),(ForceOfsY).l
                lsl.w   #$1,d2
                lea.l   (ForceHitboxes).l,a0
                lea.l   (a0,d2.w),a0
                movem.w (a0),d4-d7
                movem.w d4-d7,(ForceHitbox).l
                tst.b   (ForceSide).l
                bmi.b   .027a0
                addq.w  #$4,d2
.027a0:
                lea.l   (ForceDockOffsets).l,a0
                move.w  (a0,d2.w),(ForceDockOfsX).l
                move.w  $2(a0,d2.w),(ForceDockOfsY).l
                lsl.w   #$4,d1
                lea.l   (ForceAnimTable).l,a0
                move.w  $E(a0,d1.w),d5
                move.l  $8(a0,d1.w),d2
                move.l  d2,d4
                lsr.l   #$2,d2
                subq.b  #$1,(ForceAnimTimer).l
                bpl.b   .02814
                move.b  $D(a0,d1.w),(ForceAnimTimer).l
                move.l  (ForceFrame).l,d0
                tst.b   (ForceAnimDir).l
                bpl.b   .027ea
                neg.l   d4
.027ea:
                add.l   d4,d0
                move.l  (a0,d1.w),d4
                move.l  $4(a0,d1.w),d3
                cmp.l   d4,d0
                bcc.b   .027fc
                move.l  d3,d0
                bra.b   .02802
.027fc:
                cmp.l   d3,d0
                bls.b   .02802
                move.l  d4,d0
.02802:
                move.l  d0,(ForceFrame).l
                moveq   #3,d1
                lea.l   (CopForceSprites).l,a0
                bsr.w   SetCopperPtrs
.02814:
                move.l  d2,d3
                movea.l (ForceFrame).l,a0
                movem.w (ForcePos).l,d0-d1
                move.w  d5,d2
                bsr.w   SetSprite
                adda.l  d3,a0
                adda.l  d3,a0
                add.w   #$10,d0
                bsr.w   SetSprite
                moveq   #0,d6
                moveq   #0,d7
                movea.l (ForceState).l,a0
                jsr     (a0)
                movem.w (ForcePos).l,d0-d1
                cmp.w   #$1C6,d0
                bhi.b   .02856
                cmp.w   #$66,d0
                bhi.b   .02862
.02856:
                tst.b   (ForceActive).l
                bne.w   Force_Reset
.02860:
                rts
.02862:
                sub.w   #$5F,d0
                sub.w   #$C,d1
                add.w   (ForceOfsX).l,d0
                add.w   (ForceOfsY).l,d1
                tst.b   (ShipAlive).l
                beq.b   .02860
                tst.b   (ForceSide).l
                bne.w   ForceDockedTouch
                movem.w d0-d1,-(a7)
                tst.w   d6
                beq.b   .02898
                bmi.b   .02898
                sub.w   #$40,d0
                bra.b   .0289c
.02898:
                add.w   #$40,d0
.0289c:
                move.w  d1,d4
                bsr.w   GetMapCell
                beq.w   .02914
                movea.l a4,a1
                movea.l a1,a2
                sub.w   #$20,d4
                lsr.w   #$4,d4
                move.w  d4,d3
                moveq   #9,d0
.028b4:
                cmp.w   #$1,d3
                bls.b   .028d8
                subq.w  #$1,d3
                suba.l  (MapRowBytes).l,a1
                btst.b  #$7,(a1)
                bne.b   .028d8
                btst.b  #$7,$2(a1)
                bne.b   .028d8
                btst.b  #$7,$4(a1)
                beq.b   .0290c
.028d8:
                cmp.w   #$B,d4
                bcc.b   .028fc
                addq.w  #$1,d4
                adda.l  (MapRowBytes).l,a2
                btst.b  #$7,(a2)
                bne.b   .028fc
                btst.b  #$7,$2(a2)
                bne.b   .028fc
                btst.b  #$7,$4(a2)
                beq.b   .02902
.028fc:
                dbra    d0,.028b4
                bra.b   .02914
.02902:
                subq.w  #$4,d7
                addq.w  #$2,(ForceY).l
                bra.b   .02914
.0290c:
                addq.w  #$4,d7
                subq.w  #$2,(ForceY).l
.02914:
                movem.w (a7)+,d0-d1
                clr.b   (ForceHalt).l
                bsr.w   GetMapCell
                movea.l a4,a3
                tst.w   d6
                beq.b   .0294a
                bpl.b   .0293a
                addq.l  #$2,a3
                bsr.w   ForceTouchCell
                beq.b   .02970
                add.w   d6,(ForcePos).l
                bra.b   .02970
.0293a:
                subq.l  #$2,a3
                bsr.w   ForceTouchCell
                beq.b   .02970
                add.w   d6,(ForcePos).l
                bra.b   .02970
.0294a:
                addq.l  #$2,a3
                bsr.b   ForceTouchCell
                beq.b   .0295e
                subq.w  #$1,(ForcePos).l
                clr.b   (ForceParkSide).l
                bra.b   .02970
.0295e:
                subq.l  #$4,a3
                bsr.b   ForceTouchCell
                beq.b   .02970
                addq.w  #$1,(ForcePos).l
                clr.b   (ForceParkSide).l
.02970:
                movea.l a4,a3
                tst.w   d7
                beq.b   .0299c
                bpl.b   .0298a
                adda.l  (MapRowBytes).l,a3
                bsr.b   ForceTouchCell
                beq.b   .029c0
                add.w   d7,(ForceY).l
                bra.b   .029c0
.0298a:
                suba.l  (MapRowBytes).l,a3
                bsr.b   ForceTouchCell
                beq.b   .029c0
                add.w   d7,(ForceY).l
                bra.b   .029c0
.0299c:
                adda.l  (MapRowBytes).l,a3
                bsr.b   ForceTouchCell
                beq.b   .029ae
                subq.w  #$1,(ForceY).l
                bra.b   .029c0
.029ae:
                movea.l a4,a3
                suba.l  (MapRowBytes).l,a3
                bsr.b   ForceTouchCell
                beq.b   .029c0
                addq.w  #$1,(ForceY).l
.029c0:
                rts
ForceTouchCell:
                btst.b  #$7,(a3)
                beq.b   ForceTouchDone
                bset.b  #$5,(a3)
                btst.b  #$4,(a3)
                beq.b   .029d6
                clr.w   (a3)
                rts
.029d6:
                move.b  #$FF,(ForceHalt).l
ForceTouchDone:
                rts
ForceDockedTouch:
                addq.w  #$3,d0
                bsr.w   GetMapCell
                movea.l a4,a3
                bsr.b   ForceTouchCell
                adda.l  (MapRowBytes).w,a3
                bra.b   ForceTouchCell
; Force state machine (ForceState, run from the copper interrupt):
;   Force_Idle      not collected yet (ForceActive clear)
;   Force_Reset     -> Force_Enter: flies in from the left to x $C0
;   Force_Free      parks at the screen edge away from the ship (x $C0 or
;                   $152, ForceParkSide) and drifts towards the ship's y
;   Force_Return    fire 2 while free: comes back to the ship
;   ForceHitsShip   touching the ship docks it: ForceSide 1 = front,
;                   -1 = back.  Docking at the back turns level 1 into
;                   level 2 (the rear-docked Force has its own frames)
;   Force_Attached  follows the ship (ForceDockOfsX/Y); fire 2 launches it
;   Force_Launched  flies off at 8 pixels/frame (ForceLaunchSpeed, sign by
;                   side) until x $86 or $1A6, then Force_Free again
; ForcePos/ForceY are its position; ForceHitbox* its collision box.
Force_Idle:
                tst.b   (ForceActive).l
                beq.b   ForceTouchDone
                clr.b   (ForceLevel).l
                move.l  #$6A40,(ForceFrame).l      ; Force sprite frames ($6000 block)
                move.b  #$1,(ForceAnimDir).l
                clr.b   (ForceAnimLevel).l
                clr.b   (ForceAnimTimer).l
Force_Reset:
                cmpi.b  #$2,(ForceLevel).l
                bne.b   .02a2c
                subq.b  #$1,(ForceLevel).l
.02a2c:
                clr.b   (ForceHalt).l
                clr.b   (ForceParkSide).l
                clr.b   (ForceSide).l
                clr.b   (ForceYDir).l
                clr.b   (ForceYTimer).l
                move.w  #$76,(ForcePos).l
                move.w  #$8A,(ForceY).l
                move.l  #Force_Enter,(ForceState).l
                rts
ForceCommon:
                bsr.w   ReadFire2
                beq.b   .02a76
                move.l  #Force_Return,(ForceState).l
.02a76:
                bra.w   ForceHitsShip
Force_Enter:
                bsr.b   ForceCommon
                moveq   #-4,d6
                addq.w  #$2,(ForcePos).l
                cmpi.w  #$C0,(ForcePos).l
                bcs.b   .02aa0
                move.b  #$1,(ForceParkSide).l
                move.l  #Force_Free,(ForceState).l
.02aa0:
                rts
; Force_Free: the Force on its own.  It parks at the screen edge away
; from the ship - x $C0 when the ship is right of $10E, else x $152
; (ForceParkSide 1 / -1, 2 pixels a frame) - and then follows the ship's
; y, re-deciding the direction every 16 frames, 1 pixel a frame (it stops
; within 4 pixels).
Force_Free:
                bsr.b   ForceCommon
                move.w  (ShipX).l,d0
                cmp.w   #$10E,d0
                bcs.b   .02ad2
                cmpi.b  #$1,(ForceParkSide).l
                beq.b   .02afa
                clr.b   (ForceParkSide).l
                move.w  #$C0,d0
                bsr.w   .02b58
                move.b  #$1,(ForceParkSide).l
                bra.b   .02aec
.02ad2:
                tst.b   (ForceParkSide).l
                bmi.b   .02afa
                clr.b   (ForceParkSide).l
                move.w  #$152,d0
                bsr.b   .02b58
                st.b    (ForceParkSide).l
.02aec:
                clr.b   (ForceYDir).l
                clr.b   (ForceYTimer).l
                rts
.02afa:
                moveq   #1,d2
                move.w  (ShipY).l,d1
                sub.w   (ForceY).l,d1
                bpl.b   .02b10
                neg.w   d2
                neg.w   d7
                neg.w   d1
.02b10:
                cmp.w   #$4,d1
                bls.b   .02b48
                subq.b  #$1,(ForceYTimer).l
                bpl.b   .02b32
                move.b  #$10,(ForceYTimer).l
                move.b  d2,(ForceYDir).l
                move.b  d2,(ForceAnimDir).l
.02b32:
                move.b  (ForceYDir).l,d0
                ext.w   d0
                move.w  d0,d7
                addq.w  #$1,d7
                neg.w   d7
                add.w   d0,(ForceY).l
                rts
.02b48:
                clr.b   (ForceYDir).l
                move.b  #$10,(ForceYTimer).l
                rts
.02b58:
                moveq   #-3,d6
                moveq   #2,d1
                sub.w   (ForcePos).l,d0
                bpl.b   .02b6a
                neg.w   d1
                neg.w   d6
                neg.w   d0
.02b6a:
                cmp.w   #$4,d0
                bcs.b   .02b7a
                add.w   d1,(ForcePos).l
                addq.l  #$4,a7
                rts
.02b7a:
                moveq   #0,d6
                rts
; Force_Return: fire 2 while free - the Force flies back to the ship, 1
; pixel a frame on each axis, and docks on touching it (ForceHitsShip).
Force_Return:
                bsr.w   ForceFollowY
                moveq   #1,d1
                moveq   #-2,d6
                move.w  (ShipX).l,d0
                addq.w  #$4,d0
                sub.w   (ForcePos).l,d0
                bpl.b   .02b9c
                neg.w   d1
                neg.w   d6
                neg.w   d0
.02b9c:
                cmp.w   #$3,d0
                bcs.b   .02baa
                add.w   d1,(ForcePos).l
                bra.b   ForceHitsShip
.02baa:
                moveq   #0,d6
ForceHitsShip:
                move.w  d6,-(a7)
                movem.w (ForcePos).l,d0-d1
                add.w   (ForceHitbox).l,d0
                add.w   (ForceHitboxY).l,d1
                movem.w (ForceHitboxSize).l,d5-d6
                movem.w (ShipX).l,d3-d4
                movea.w #$12,a3
                movea.w #$8,a4
                bsr.w   BoxTest
                movem.w (a7)+,d6
                beq.b   .02c1a
                addq.w  #$6,d3
                cmp.w   (ForcePos).l,d3
                bhi.b   .02bf2
                moveq   #1,d1
                bra.b   .02c04
.02bf2:
                moveq   #-1,d1
                cmpi.b  #$1,(ForceLevel).l
                bne.b   .02c04
                addq.b  #$1,(ForceLevel).l
.02c04:
                move.b  d1,(ForceSide).l
                move.l  #Force_Attached,(ForceState).l
                moveq   #5,d0                       ; sound: Force docks
                bra.w   PlaySound
.02c1a:
                rts
Force_Attached:
                move.w  (ShipX).l,d0
                add.w   (ForceDockOfsX).l,d0
                move.w  d0,(ForcePos).l
                move.w  (ShipY).l,d0
                add.w   (ForceDockOfsY).l,d0
                move.w  d0,(ForceY).l
                bsr.w   ReadFire2
                beq.b   ForceStateDone
                moveq   #8,d0
                tst.b   (ForceSide).l
                bpl.b   .02c52
                neg.w   d0
.02c52:
                move.w  d0,(ForceLaunchSpeed).l
                moveq   #5,d0                       ; sound: Force docks
                bsr.w   PlaySound
                move.l  #Force_Launched,(ForceState).l
                clr.b   (ForceSide).l
                cmpi.b  #$2,(ForceLevel).l
                bne.b   ForceStateDone
                subq.b  #$1,(ForceLevel).l
ForceStateDone:
                rts
Force_Launched:
                move.w  (ForceLaunchSpeed).l,d0
                move.w  d0,d7
                neg.w   d7
                tst.b   (ForceHalt).l
                bne.b   ForceHaltedToFree
                move.w  (ForcePos).l,d1
                add.w   d0,d1
                move.w  d1,(ForcePos).l
Force_Bounds:
                cmp.w   #$86,d1
                bls.b   ForceToFree
                cmp.w   #$1A6,d1
                bcs.b   ForceStateDone
ForceToFree:
                clr.b   (ForceParkSide).l
                move.l  #Force_Free,(ForceState).l
                rts
ForceHaltedToFree:
                moveq   #0,d7
                bra.b   ForceToFree
; ForceFollowY: move ForceY 1 pixel towards the ship's y (d7 = the step
; for the map test).
ForceFollowY:
                moveq   #1,d1
                moveq   #-2,d7
                move.w  (ShipY).l,d0
                sub.w   (ForceY).l,d0
                bpl.b   .02cda
                neg.w   d1
                neg.w   d7
                neg.w   d0
.02cda:
                cmp.w   #$2,d0
                bcs.b   .02ce8
                add.w   d1,(ForceY).l
                rts
.02ce8:
                moveq   #0,d7
                rts

; ReadFire2: joystick button 2 or Space
ReadFire2:
                move.w  #$FF00,$34(a6)
                move.w  $16(a6),d0
                tst.b   (Fire2Latch).l
                beq.b   .02d14
                btst    #$E,d0
                beq.b   .02d34
                tst.b   (SpaceKey).l
                bne.b   .02d34
                clr.b   (Fire2Latch).l
                rts
.02d14:
                btst    #$E,d0
                beq.b   .02d22
                tst.b   (SpaceKey).l
                beq.b   .02d34
.02d22:
                tst.b   (ShipAlive).l
                beq.b   .02d32
                move.b  #$1,(Fire2Latch).l
.02d32:
                rts
.02d34:
                moveq   #0,d0
                rts

;==============================================================================
; Power-up carriers: the POW Armor
;==============================================================================
; Object flags ($23): bit 0 hit flash, bit 1 carrier (releases a power-up
; when hit, see ObjDamage), bit 2 immune to weapons, bit 3 power-up item
; (collected by the ship, see HitByForceOrShip).
; ReleasePowerUp: a0 = the carrier.  Creates a DefPowerUp object at its
; position showing item $32(a0) (0-2 laser crystals, 3 speed, 4 missiles,
; 5 Bit), immune to weapons; it scrolls off with the map (ObjUpd_ScrollOff).
ReleasePowerUp:
                move.l  a0,-(a7)
                moveq   #0,d3
                move.b  $32(a0),d3
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (DefPowerUp).l,a2
                bsr.w   ObjCreate
                bset.b  #$3,$23(a0)
                move.b  d3,$1F(a0)
                clr.b   $22(a0)
                bset.b  #$2,$23(a0)
                jsr     (ObjInsert).l
                movea.l (a7)+,a0
                moveq   #8,d0                       ; sound: power-up
                bra.w   PlaySound
ObjUpd_ScrollOff:
                tst.b   (ScrollActive).l
                beq.b   .02d8e
                subq.w  #$1,$A(a0)
                cmpi.w  #$10,$A(a0)
                bhi.b   .02d8e
                jmp     (ObjKillSelf).l
.02d8e:
                rts
; The POW Armor (DefPowArmor, 32x26, 1 hit point, 200 points) is the
; default wave object (wave entries with a negative definition).  Wave
; parameters: $07 = the power-up it carries, $09 = direction (signed x
; step: negative walks left).  It is a carrier (flag bit 1).
; States ($36):
;   PowArmor_Jump  x += direction, y += the jump arc at $1C650 (58 signed
;                  steps, index $34: spawned at $2B = falling, a jump
;                  starts at $10).  Probes the map ahead of its leading
;                  foot: solid ground just below -> lands and walks; a
;                  tile in the way ->
;   .02e74         sliding down: 2 pixels down and 1 left a frame until
;                  its feet meet the map, then it lands.
;   .02ea0         walking: 2 pixels a frame.  A tile ahead turns it round
;                  with a jump; no solid ground ahead makes it jump off.
; .02f20 snaps y to the tile row and selects the walk animation;
; .02f0c gives the probe x (4 pixels left of it, or 29 right).
; Frames: 0-5 walking (left 1,0,2,0 / right 3,5,4,5), 6/7 and 8/9 jumping
; (take-off, then in the air).  It dies when it leaves the screen area.
SpawnPowArmor:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                moveq   #1,d2
                jsr     (ObjCreate).l
                bset.b  #$1,$23(a0)
                move.b  $7(a1),$32(a0)
                move.l  #PowArmorJumpRight,$2A(a0)
                move.b  $9(a1),$33(a0)
                bpl.b   .02dc4
                move.l  #PowArmorJumpLeft,$2A(a0)
.02dc4:
                move.b  #$2B,$34(a0)
                move.l  #PowArmor_Jump,$36(a0)
                move.b  #$2,$4(a0)
                jmp     (ObjInsert).l
ObjUpd_PowArmor:
                cmpi.w  #$10,$C(a0)
                bcs.b   .02dfe
                cmpi.w  #$E0,$C(a0)
                bcc.b   .02dfe
                cmpi.w  #$10,$A(a0)
                bcs.b   .02dfe
                cmpi.w  #$172,$A(a0)
                bls.b   .02e04
.02dfe:
                jmp     (ObjKillSelf).l
.02e04:
                movea.l $12(a0),a2
                movea.l $36(a0),a1
                jmp     (a1)
PowArmor_Jump:
                lea.l   ($1C650).l,a1           ; jump arc: 58 signed y steps
                movem.w $A(a0),d0-d1
                move.b  $33(a0),d2
                ext.w   d2
                add.w   d2,d0
                moveq   #0,d4
                move.b  $34(a0),d4
                move.b  (a1,d4.w),d3
                ext.w   d3
                add.w   d3,d1
                addq.w  #$1,d4
                cmp.w   #$39,d4
                bls.b   .02e3a
                clr.w   d4
.02e3a:
                move.b  d4,$34(a0)
                movem.w d0-d1,$A(a0)
                bsr.w   .02f0c
                addq.w  #$6,d1
                bsr.w   GetMapCell
                beq.b   .02e5a
                move.l  #.02e74,$36(a0)
.02e58:
                rts
.02e5a:
                move.l  (MapRowBytes).l,d0
                adda.l  d0,a4
                btst.b  #$7,(a4)
                beq.b   .02e58
                move.l  #.02ea0,$36(a0)
                bra.w   .02f20
.02e74:
                movem.w $A(a0),d0-d1
                bsr.w   .02f0c
                add.w   #$17,d1
                bsr.w   GetMapCell
                beq.b   .02e96
                move.l  #.02ea0,$36(a0)
                bsr.w   .02f20
                bra.b   .02ea0
.02e96:
                addq.w  #$2,$C(a0)
                subq.w  #$1,$A(a0)
                rts
.02ea0:
                movem.w $A(a0),d0-d1
                bsr.w   .02f0c
                add.w   #$F,d1
                bsr.w   GetMapCell
                beq.b   .02eea
                neg.b   $33(a0)
.02eb8:
                move.l  #PowArmor_Jump,$36(a0)
                lea.l   (PowArmorJumpRight).l,a1
                tst.b   $33(a0)
                bpl.b   .02ed2
                lea.l   (PowArmorJumpLeft).l,a1
.02ed2:
                move.l  a1,$2A(a0)
                move.b  #$10,$34(a0)
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                bra.w   PowArmor_Jump
.02eea:
                move.l  (MapRowBytes).l,d0
                adda.l  d0,a4
                btst.b  #$7,(a4)
                beq.b   .02eb8
                tst.b   $33(a0)
                bpl.b   .02f06
                addi.w  #$FFFE,$A(a0)
                rts
.02f06:
                addq.w  #$2,$A(a0)
                rts
.02f0c:
                tst.b   $33(a0)
                bpl.w   .02f1a
                add.w   #$FFFC,d0
                rts
.02f1a:
                add.w   #$1D,d0
                rts
.02f20:
                move.w  $C(a0),d0
                move.w  d0,d1
                and.w   #$FFF0,d0
                and.w   #$8,d1
                beq.b   .02f34
                add.w   #$10,d0
.02f34:
                sub.w   #$B,d0
                move.w  d0,$C(a0)
                clr.b   $20(a0)
                clr.w   $1E(a0)
                tst.b   $33(a0)
                bpl.w   .02f54
                lea.l   (PowArmorWalkLeft).l,a1
                bra.b   .02f5a
.02f54:
                lea.l   (PowArmorWalkRight).l,a1
.02f5a:
                move.l  a1,$2A(a0)
                rts

;==============================================================================
; Homing missiles
;==============================================================================
; Homing missiles (the M power-up sets MissilesEnabled): two slots,
; Missile1/Missile2, $1C bytes each: +0.l state routine (0 = free), +4 x,y,
; +$C direction 0-15, +$E animation toggle (frame = direction + 16 on
; alternate frames), +8.l target object, +$10 hit-box offset x,y, +$14 size
; w,h, +$18.b state timer, +$19.b launch y drift (signed), +$1A.b seek half
; (0 above, 1 below).  Both are launched together from the ship when fire is
; pressed and MissileReload ($38 frames) has run out; MissilesInFlight
; counts them.  A missile that reaches a solid map cell becomes an explosion
; object; one that leaves the screen is freed.
ResetMissiles:
                clr.b   (MissilesEnabled).l
                clr.b   (MissilesInFlight).l
                clr.w   (MissileReload).l
                clr.l   (Missile1).l
                clr.l   (Missile2).l
                rts
UpdateMissiles:
                tst.b   (MissilesInFlight).l        ; reload counts down only while
                bne.b   .02f96
                tst.w   (MissileReload).l
                beq.b   .02f96
                subq.w  #$1,(MissileReload).l       ; both are gone
.02f96:
                lea.l   (Missile1).l,a0
                bsr.b   .02fa4
                lea.l   (Missile2).l,a0
.02fa4:
                move.l  (a0),d0                     ; state routine
                beq.w   .03048                      ; free: maybe launch
                movea.l d0,a1
                jsr     (a1)                        ; run the state
                movem.w $4(a0),d6-d7
                move.w  d6,d0
                move.w  d7,d1
                add.w   #$F,d0
                addq.w  #$8,d1
                bsr.w   GetMapCell                  ; nose in a solid cell?
                beq.b   .02ff2
                clr.l   (a0)                        ; yes: free the slot
                subq.b  #$1,(MissilesInFlight).l
                move.w  d6,d0
                move.w  d7,d1
                addq.w  #$8,d0
                moveq   #-1,d2
                jsr     (jt_ObjAlloc).w             ; and leave an explosion object
                move.b  #$1,$5(a0)
                move.b  #$1,$21(a0)
                clr.l   $6(a0)
                move.b  #$A,$4(a0)
                jmp     (jt_ObjInsert).w
.02ff2:
                move.w  $C(a0),d0                   ; frame = direction,
                eori.w  #$FFFF,$E(a0)               ; +16 on alternate frames
                beq.b   .03002
                add.w   #$10,d0
.03002:
                lsl.w   #$2,d0
                lea.l   (MissileFrames).l,a1
                movea.l (a1,d0.w),a1
                movea.l a1,a2
                adda.l  #$80,a2                     ; mask follows the graphics
                move.w  d6,d0                       ; off screen: freed
                bmi.b   .0302a
                cmp.w   #$170,d0
                bhi.b   .0302a
                move.w  d7,d3
                bmi.b   .0302a
                cmp.w   #$F2,d3
                bcs.b   .03034
.0302a:
                clr.l   (a0)
                subq.b  #$1,(MissilesInFlight).l
                rts
.03034:
                move.w  #$30,$60(a6)
                move.w  #$30,$66(a6)
                move.w  #$1002,d1                   ; 16x16, 2 words
                bra.w   BlitBob
.03048:
                tst.b   (MissilesEnabled).l         ; launch: M collected,
                beq.b   MissilesDone
                tst.b   (ShipAlive).l               ; ship alive,
                beq.b   MissilesDone
                tst.w   (MissileReload).l           ; reloaded,
                bne.b   MissilesDone
                btst.b  #$7,(CIAA_PRA).l            ; and fire pressed
                bne.b   MissilesDone
                movem.w (ShipPos).l,d0-d1
                addq.w  #$5,d0
                movem.w d0-d1,$4(a0)
                move.b  #$9,$18(a0)                 ; 9 frames of launch drift
                clr.l   $8(a0)                      ; no target yet
                move.w  #$4,$C(a0)                  ; direction 4 = right
                move.l  #$E0008,$10(a0)             ; hit box at +14,+8,
                move.l  #$C0006,$14(a0)             ; 12x6
                move.l  #Missile_Launch,(a0)
                tst.b   $19(a0)                     ; after the second missile:
                bmi.b   MissilesDone
                move.b  #$2,(MissilesInFlight).l
                move.w  #$38,(MissileReload).l
MissilesDone:
                rts
; Missile states: Launch - drift up/down for 9 frames; Forward - 6 pixels
; right for 7 frames; Seek - pick the nearest live, destructible enemy
; (|dx|+|dy|, MissileBestDist), one missile only above, the other only
; below, flying on until one is found; Home - every 4th frame turn one of
; 16 directions towards it (DirectionTo, TurnTowards) and move by
; MissileVelocities; if the target dies the missile flies straight on.
Missile_Launch:
                move.b  $19(a0),d0
                ext.w   d0
                add.w   d0,$6(a0)
                subq.b  #$1,$18(a0)
                bpl.b   MissilesDone
                move.l  #Missile_Forward,(a0)
                move.b  #$6,$18(a0)
                rts
Missile_Forward:
                addq.w  #$6,$4(a0)
                subq.b  #$1,$18(a0)
                bpl.b   MissilesDone
                move.l  #Missile_Seek,(a0)
                rts
Missile_Seek:
                movem.w $4(a0),d6-d7
                move.w  #$FFFF,(MissileBestDist).l  ; no candidate yet
                move.l  (ActiveObjects).l,d0
                beq.b   .03150
.030fe:
                movea.l d0,a1                       ; each active object:
                movem.w $A(a1),d0-d1
                moveq   #0,d4                       ; d4 = 0 above / 1 below
                sub.w   d6,d0
                bpl.b   .0310e
                neg.w   d0
.0310e:
                sub.w   d7,d1
                bpl.b   .03116
                neg.w   d1
                moveq   #1,d4
.03116:
                add.w   d1,d0                       ; distance |dx| + |dy|
                cmp.w   (MissileBestDist).l,d0      ; nearer than the best,
                bhi.b   .0313c
                cmp.b   $1A(a0),d4                  ; in this missile's half,
                bne.b   .0313c
                tst.b   $5(a1)                      ; alive,
                bne.b   .0313c
                tst.w   $24(a1)                     ; and destructible
                bmi.b   .0313c
                move.w  d0,(MissileBestDist).l
                move.l  a1,$8(a0)                   ; new target
.0313c:
                move.l  (a1),d0
                bne.b   .030fe
                move.l  $8(a0),d0
                beq.b   .03150
                clr.b   $18(a0)
                move.l  #Missile_Home,(a0)          ; found one: home in
.03150:
                addq.w  #$6,$4(a0)                  ; fly on right meanwhile
                rts
Missile_Home:
                movea.l $8(a0),a1
                move.w  $A(a1),d2                   ; target gone or dying:
                beq.b   .031a0
                tst.b   $5(a1)                      ; just fly straight on
                bne.b   .031a0
                subq.b  #$1,$18(a0)                 ; steer every 4th frame
                bpl.b   .031a0
                move.b  #$3,$18(a0)
                movem.w $4(a0),d0-d1
                move.w  $C(a1),d3
                bsr.w   DirectionTo                 ; direction to the target,
                move.w  $C(a0),d1
                bsr.w   TurnTowards                 ; turn one step towards it
                move.w  d1,$C(a0)
                lsl.w   #$3,d1
                lea.l   (MissileHitboxes).l,a1      ; hit box for this direction
                movem.l (a1,d1.w),d4-d5
                movem.l d4-d5,$10(a0)
.031a0:
                move.w  $C(a0),d0
                lsl.w   #$2,d0
                lea.l   (MissileVelocities).l,a1    ; move along the direction
                movem.w (a1,d0.w),d1-d2
                add.w   d1,$4(a0)
                add.w   d2,$6(a0)
                rts
; HitByMissiles: the two homing missiles against the object's box; a
; missile that hits is freed and does 1 damage.
HitByMissiles:
                tst.b   (MissilesEnabled).l
                beq.b   .031d4
                lea.l   (Missile1).l,a1
                bsr.b   .031d6
                lea.l   (Missile2).l,a1
                bsr.b   .031d6
.031d4:
                rts
.031d6:
                tst.l   (a1)
                beq.b   .031d4
                movem.w $4(a1),d0-d1
                add.w   $10(a1),d0
                add.w   $12(a1),d1
                movem.w $14(a1),d5-d6
                bsr.w   BoxTest
                beq.b   .031d4
                clr.l   (a1)
                subq.b  #$1,(MissilesInFlight).l
                moveq   #1,d0
                bra.w   ObjDamage

;==============================================================================
; Attract mode: title, high scores, demo
;==============================================================================
; Attract mode, a state machine in TitleState run at 50 Hz (Flip50Hz).
; Each state fades the current screen out over TitleFadeSteps, then shows
; the next one for TitleDelay frames:
;   St_HighScore      first: enter the last game's score into the table
;   St_ShowCredits    TxtCredits (Amiga team: Factor 5, Rainbow Arts,
;                     programmers, artists, musicians) - 200 frames
;   St_ShowHighScores DrawScoreTable - 250 frames
;   St_ShowTitle      InitTitleLetters: the R-TYPE letters fly in as
;                     objects (St_TitleLetters until TitleLettersDone),
;                     then St_TitleText prints TitleTextList ("blast off
;                     and strike the evil bydo empire!", "press fire to
;                     start", "freeplay"/"trainer", "C 1987 by irem") and
;                     St_TitleWipe copies a 112-pixel wide graphic from the
;                     shared file ($50282) into both screens, 4 lines a
;                     frame - then 200 frames and back to the credits
; Fire on port 2 at any point -> AbortTitle -> the game.
TitleSequence:
                move.l  a7,(TitleStack).l
                clr.b   (CheatMode).l
                clr.b   (TitleAbort).l
                tst.w   d7
                bne.b   .03220
                bsr.w   LoadShared
                bsr.w   RestoreMusic
.03220:
                clr.w   (FineScrollX).l
                clr.w   (FineScrollY).l
                clr.w   (TitleDelay).l
                move.l  #St_HighScore,(TitleState).l
; TitleLoop: one attract-mode frame - waits for the frame to be shown,
; leaves for the game on fire, counts TitleDelay down, otherwise runs the
; current TitleState.
TitleLoop:
                tst.b   (FrameReady).l
                bne.b   TitleLoop
                btst.b  #$7,(CIAA_PRA).l
                beq.w   AbortTitle
                tst.w   (TitleDelay).l
                beq.b   .03262
                subq.w  #$1,(TitleDelay).l
                bra.w   TitleNextFrame
.03262:
                movea.l (TitleState).l,a1
                jmp     (a1)
St_ShowCredits:
                bsr.w   PaletteFadeOut
                move.w  #$4,(TitleDelay).l
                subq.b  #$1,(TitleFadeSteps).l
                bpl.w   TitleNextFrame
                bsr.w   ClearPlayfield
                lea.l   (TitlePalette).l,a1
                bsr.w   SetPalette
                lea.l   (TxtCredits).l,a4
                bsr.w   PrintList                   ; credits screen
                move.w  #$C8,(TitleDelay).l
                move.l  #St_ShowHighScores,(TitleState).l
                move.b  #$F,(TitleFadeSteps).l
                bra.w   TitleNextFrame
St_ShowHighScores:
                bsr.w   PaletteFadeOut
                move.w  #$4,(TitleDelay).l
                subq.b  #$1,(TitleFadeSteps).l
                bpl.w   TitleNextFrame
                bsr.w   ClearPlayfield
                lea.l   (TextPalette).l,a1
                bsr.w   SetPalette
                bsr.w   DrawScoreTable
                move.w  #$FA,(TitleDelay).l
                move.b  #$F,(TitleFadeSteps).l
                move.l  #St_ShowTitle,(TitleState).l
                bra.w   TitleNextFrame
St_ShowTitle:
                bsr.w   PaletteFadeOut
                move.w  #$4,(TitleDelay).l
                subq.b  #$1,(TitleFadeSteps).l
                bpl.w   TitleNextFrame
                bsr.w   ClearPlayfield
St_TitleStart:
                bsr.w   InitTitleLetters
                lea.l   (TitlePalette).l,a1
                bsr.w   SetPalette
                move.l  #St_TitleLetters,(TitleState).l
St_TitleLetters:
                bsr.w   DrawTitle
                tst.b   (TitleLettersDone).l
                beq.w   TitleNextFrame
                move.l  #St_TitleText,(TitleState).l
                bra.w   TitleNextFrame
St_TitleText:
                bsr.w   DrawTitle
                lea.l   (TitleTextList).l,a4
                bsr.w   PrintList
                move.l  #St_TitleWipe,(TitleState).l
                move.b  #$D,(TitleFadeSteps).l
                lea.l   ($37C63).l,a2
                lea.l   ($45963).l,a3
                lea.l   ($50282).l,a0
St_TitleWipe:
                moveq   #3,d0
.0337e:
                moveq   #13,d1
.03380:
                move.b  (a0),(a2)+
                move.b  (a0)+,(a3)+
                dbra    d1,.03380
                adda.l  #$26,a2
                adda.l  #$26,a3
                dbra    d0,.0337e
                move.w  #$2,(TitleDelay).l
                subq.b  #$1,(TitleFadeSteps).l
                bne.b   TitleNextFrame
                move.w  #$C8,(TitleDelay).l
                move.l  #St_ShowCredits,(TitleState).l
                move.b  #$F,(TitleFadeSteps).l
TitleNextFrame:
                st.b    (FrameReady).l
                bra.w   TitleLoop
; InitTitleLetters: starts the title music if the TFMX file is still at
; MUSIC ($3F3 = hunk header), then creates the 7 R-TYPE letter objects
; (TitleLetterList: definition, slide-in path) at x $17A.
InitTitleLetters:
                cmpi.l  #$3F3,(MUSIC).l
                bne.b   .033de
                st.b    (TitleMusicOn).l
.033de:
                bsr.w   InitObjects
                st.b    (Flip50Hz).l
                clr.b   (TitleLettersDone).l
                move.b  #$1,(TitleLetterPhase).l
                moveq   #6,d7
                lea.l   (TitleLetterList).l,a4
.033fe:
                move.w  #$17A,d0
                move.w  #$64,d1
                bsr.w   ObjAlloc
                move.b  d7,$32(a0)
                bne.b   .03422
                move.b  #$1,$4(a0)
                move.w  #$2B,$A(a0)
                move.w  #$0,$C(a0)
.03422:
                clr.b   $33(a0)
                cmp.w   #$5,d7
                bne.b   .03432
                move.w  #$6E,$C(a0)
.03432:
                move.l  #ObjUpd_TitleLetter,$6(a0)
                move.l  #TitleLetterAnim,$2A(a0)
                move.l  (a4)+,$12(a0)
                move.l  (a4)+,$34(a0)
                bsr.w   ObjInsert
                dbra    d7,.033fe
                rts
; DrawTitle: the title screen's frame: clears the band the letters
; moved through (TitleWipeTop/Bottom), then runs and draws the letter
; objects.
DrawTitle:
                move.w  (TitleWipeTop).l,d0
                move.w  #$2A1A,d1
                bsr.w   ClearLines
                move.w  (TitleWipeBottom).l,d0
                move.w  #$51A,d1
                bsr.w   ClearLines
                lea.l   ($48C62).l,a5
                move.l  #$FFFF0000,$44(a6)
                move.w  #$FFFE,$64(a6)
                move.w  #$FFFE,$62(a6)
                move.l  (ActiveObjects).l,d7
.03490:
                tst.l   d7
                beq.w   .034aa
                movea.l d7,a0
                move.l  $6(a0),d0
                beq.b   .034a2
                movea.l d0,a3
                jsr     (a3)
.034a2:
                bsr.w   ObjAnimDraw
                move.l  (a0),d7
                bne.b   .03490
.034aa:
                rts
; ClearLines: d0 = first line, d1 = BLTSIZE; blitter-clears whole
; interleaved lines of DrawBuffer.
ClearLines:
                clr.l   $44(a6)
                movea.l (DrawBuffer).l,a0
                mulu.w  #$D0,d0
                adda.l  d0,a0
                move.l  a0,$54(a6)
                clr.w   $66(a6)
                clr.w   $74(a6)
                clr.w   $42(a6)
                move.w  #$1F0,$40(a6)
                move.w  d1,$58(a6)
.034d6:
                btst.b  #$6,$2(a6)
                bne.b   .034d6
                rts

;==============================================================================
; High-score table and name entry
;==============================================================================
St_HighScore:
                bsr.w   ClearPlayfield
                st.b    (FrameReady).l
                st.b    (Flip50Hz).l
                lea.l   (TextPalette).l,a1
                bsr.w   SetPalette
                move.l  (Score).l,d0
                bsr.w   InsertScore
                move.l  a0,-(a7)
                beq.b   .0357a
                move.b  #$FF,(JingleCmd).l
                st.b    (JinglePlaying).l
                bsr.w   DrawScoreTable
                movea.l (a7),a0
                bsr.w   EnterName
                movea.l (a7)+,a0
                movea.l $4(a0),a0
        ; --- hidden trainer: high-score name "sumita. " ---------------------
        ; The name is hidden as $E6EADAD2>>1 = "sumi" and $74612E20 = "ta. ".
        ; CheatMode: no score (AddScore), no lives lost (ShipRespawn), scores
        ; not saved, and the title's "freeplay" line becomes "trainer".
                move.l  #$E6EADAD2,d0
                lsr.l   #$1,d0                  ; "sumi"
                cmp.l   (a0),d0
                bne.b   .03552
                cmpi.l  #$74612E20,$4(a0)       ; "ta. "
                bne.b   .03552
                st.b    (CheatMode).l
                move.l  #TxtTrainer/2,d0        ; pointer hidden as half its value
                add.l   d0,d0
                move.l  d0,(TitleTextFreeplay).l
                bra.b   .03556
.03552:
                bsr.w   SaveHighScores
.03556:
                move.b  #$F,(TitleFadeSteps).l
                move.l  #St_ShowTitle,(TitleState).l
                move.b  #$1,(JingleCmd).l
                st.b    (TitleAbort).l
                bra.w   TitleNextFrame
.0357a:
                st.b    (TitleAbort).l
                addq.l  #$4,a7
                move.l  #St_TitleStart,(TitleState).l
                bra.w   TitleNextFrame
; One R-TYPE title letter (an object): slides in from the right at 5
; pixels a frame to x $46, waits, then drops into place; the last one sets
; TitleLettersDone.
ObjUpd_TitleLetter:
                tst.b   $32(a0)
                beq.w   .03622
                move.w  $C(a0),d0
                tst.b   $32(a0)
                bpl.b   .035aa
                move.w  d0,(TitleWipeBottom).l
                bra.b   .035b0
.035aa:
                move.w  d0,(TitleWipeTop).l
.035b0:
                tst.b   $33(a0)
                bmi.b   .03604
                beq.b   .035ea
                move.l  $34(a0),d0
                beq.b   .035d2
                movea.l d0,a1
                move.b  (a1)+,d0
                move.l  a1,$34(a0)
                and.w   #$FF,d0
                add.w   #$46,d0
                move.w  d0,$A(a0)
.035d2:
                subq.b  #$1,$38(a0)
                bne.b   .035e8
                st.b    $33(a0)
                move.b  #$10,$38(a0)
                st.b    (TitleLetterPhase).l
.035e8:
                rts
.035ea:
                subq.w  #$5,$A(a0)
                cmpi.w  #$46,$A(a0)
                bhi.b   .03602
                move.b  #$1,$33(a0)
                move.b  #$2D,$38(a0)
.03602:
                rts
.03604:
                tst.b   (TitleLetterPhase).l
                bne.b   .03620
                addq.w  #$3,$C(a0)
                subq.b  #$1,$38(a0)
                bne.b   .03620
                clr.l   $6(a0)
                st.b    (TitleLettersDone).l
.03620:
                rts
.03622:
                move.w  $C(a0),(TitleWipeBottom).l
                tst.b   (TitleLetterPhase).l
                bpl.b   .03620
                addq.w  #$6,$A(a0)
                addq.w  #$3,$C(a0)
                cmpi.w  #$96,$C(a0)
                bcs.b   .03620
                clr.b   (TitleLetterPhase).l
                st.b    $32(a0)
                st.b    $33(a0)
                move.b  #$10,$38(a0)
                rts

; SetPalette: a1 = 15 colours
SetPalette:
                moveq   #14,d0
                lea.l   (CopColours).l,a0
.03660:
                move.w  (a1)+,(a0)
                addq.l  #$4,a0
                dbra    d0,.03660
                rts
ClearPlayfield:
                lea.l   ($2D1BA).l,a0
.03670:
                clr.l   (a0)+
                cmpa.l  #$48BBA,a0
                bcs.b   .03670
                rts
; InsertScore: d0 = score.  Finds its place in HighScores (a0 = entry,
; or 0 if it doesn't qualify), moves the lower entries down (the last
; name buffer is reused for the new entry), blanks the name and falls
; into FormatScores.
InsertScore:
                lea.l   (HighScores).l,a0
                moveq   #9,d1
.03684:
                cmp.l   $8(a0),d0
                bcc.b   .03698
                adda.l  #$C,a0
                dbra    d1,.03684
                suba.l  a0,a0
                rts
.03698:
                lea.l   (LowestScoreEntry).l,a1
                move.l  $4(a1),d2
                lea.l   -$C(a1),a0
                bra.b   .036c0
.036a8:
                move.l  $4(a0),$4(a1)
                move.l  $8(a0),$8(a1)
                suba.l  #$C,a0
                suba.l  #$C,a1
.036c0:
                dbra    d1,.036a8
                adda.l  #$C,a0
                move.l  d2,$4(a0)
                move.l  d0,$8(a0)
                movea.l d2,a1
                move.l  #$20202020,(a1)+
                move.l  #$20202020,(a1)+
                move.l  #$20202020,(a1)+
                move.l  #$20202020,(a1)+
; FormatScores: writes each entry's score as text after its name
; (name + $11), leading zeros as spaces.
FormatScores:
                lea.l   (HighScores).l,a1
                lea.l   (ScoreDigitChars).l,a2
                moveq   #9,d0
.036fa:
                movea.l $4(a1),a3
                adda.l  #$11,a3
                move.l  $8(a1),d1
                lsl.l   #$8,d1
                moveq   #5,d3
                move.b  #$20,(a2)
.03710:
                rol.l   #$4,d1
                move.l  d1,d2
                and.w   #$F,d2
                beq.b   .0371e
                move.b  #$30,(a2)
.0371e:
                move.b  (a2,d2.w),(a3)+
                dbra    d3,.03710
                adda.l  #$C,a1
                dbra    d0,.036fa
                rts
; DrawScoreTable: for each entry, a 12-line strip from the level B
; graphics ($50832/$50862) behind the line on both screens, then the
; score text and the name.
DrawScoreTable:
                lea.l   (HighScores).l,a4
                lea.l   ($50862).l,a3
                moveq   #9,d7
.03740:
                movea.l (a4),a1
                movea.l a1,a2
                adda.l  #$3AEC2,a2
                adda.l  #$2D1C2,a1
                lea.l   ($50832).l,a0
                moveq   #11,d0
.03758:
                move.l  (a0),(a1)
                move.l  (a0),(a2)
                move.l  (a3),$4(a1)
                move.l  (a3),$4(a2)
                move.l  $210(a0),$34(a1)
                move.l  $210(a0),$34(a2)
                move.l  $210(a3),$38(a1)
                move.l  $210(a3),$38(a2)
                move.l  $420(a0),$68(a1)
                move.l  $420(a0),$68(a2)
                move.l  $420(a3),$6C(a1)
                move.l  $420(a3),$6C(a2)
                addq.l  #$4,a0
                addq.l  #$4,a3
                adda.l  #$D0,a1
                adda.l  #$D0,a2
                dbra    d0,.03758
                movea.l (a4),a1
                adda.l  #$2D36C,a1
                movea.l $4(a4),a0
                adda.l  #$11,a0
                move.w  #$1000,d1
                bsr.w   PrintString
                movea.l $4(a4),a0
                addq.l  #$4,a1
                move.w  #$1000,d1
                bsr.w   PrintString
                adda.l  #$C,a4
                dbra    d7,.03740
                rts
; High-score name entry: joystick up/down (ReadNameInput 1/2) steps
; through CharSet (47 entries), fire (3) takes the character.  Entries
; $2C/$2D/$2E are rub out / space / end.  Up to 16 characters.  (The name
; "sumita. " switches the trainer on - see St_HighScore.)
EnterName:
                move.l  a0,-(a7)
                lea.l   (TxtEnterName).l,a0
                lea.l   ($37E05).l,a1
                move.w  #$1000,d1
                bsr.w   PrintString
                movea.l (a7)+,a4
                movea.l $4(a4),a3
                movea.l a3,a0
                movea.l (a4),a1
                adda.l  #$2D376,a1
                movem.l a0-a1,-(a7)
                move.b  #$61,(a3)
                moveq   #0,d1
                bsr.w   PrintString
                movem.l (a7)+,a0-a1
                lea.l   (CharSet).l,a2
                moveq   #0,d7
.0381c:
                move.w  #$7000,d0
.03820:
                nop
                nop
                nop
                nop
                dbra    d0,.03820
.0382c:
                bsr.w   ReadNameInput
                tst.w   d0
                beq.b   .0382c
                cmp.b   #$1,d0
                bne.b   .03858
                addq.b  #$1,d7
                cmp.b   #$2E,d7
                bls.b   .03844
                moveq   #0,d7
.03844:
                move.b  (a2,d7.w),(a3)
                movem.l a0-a1,-(a7)
                moveq   #0,d1
                bsr.w   PrintString
                movem.l (a7)+,a0-a1
                bra.b   .0381c
.03858:
                cmp.b   #$2,d0
                bne.b   .03878
                subq.w  #$1,d7
                bpl.b   .03864
                moveq   #46,d7
.03864:
                move.b  (a2,d7.w),(a3)
                movem.l a0-a1,-(a7)
                moveq   #0,d1
                bsr.w   PrintString
                movem.l (a7)+,a0-a1
                bra.b   .0381c
.03878:
                cmp.b   #$3,d0
                bne.b   .0382c
                cmp.b   #$2C,d7
                bne.b   .03894
                move.l  a3,d0
                sub.l   $4(a4),d0
                beq.b   .0382c
                move.b  #$20,(a3)
                subq.l  #$1,a3
                bra.b   .038c8
.03894:
                cmp.b   #$2D,d7
                bne.b   .038a4
                move.b  #$20,(a3)+
                move.b  #$20,d6
                bra.b   .038b8
.038a4:
                cmp.b   #$2E,d7
                bne.b   .038b0
                move.b  #$20,(a3)
                rts
.038b0:
                move.b  (a2,d7.w),(a3)+
                move.b  (a2,d7.w),d6
.038b8:
                move.l  a3,d0
                sub.l   $4(a4),d0
                cmp.w   #$F,d0
                ble.w   .038c8
                rts
.038c8:
                move.b  (a2,d7.w),(a3)
                movem.l a0-a1,-(a7)
                moveq   #0,d1
                bsr.w   PrintString
                movem.l (a7)+,a0-a1
                moveq   #-1,d0
                bra.w   .03820
; ReadNameInput: name entry input.  Fire (debounced) -> 3, joystick
; port 1 vertical (JOY1DAT) -> 1 or 2, nothing -> 0.
ReadNameInput:
                btst.b  #$7,(CIAA_PRA).l
                bne.b   .0390c
                move.w  #$2800,d1
.038ee:
                nop
                dbra    d1,.038ee
.038f4:
                btst.b  #$7,(CIAA_PRA).l
                beq.b   .038f4
                move.w  #$2800,d1
.03902:
                nop
                dbra    d1,.03902
                moveq   #3,d0
                rts
.0390c:
                clr.w   $36(a6)
                move.w  $C(a6),d0
                beq.b   .03922
                and.w   #$FF,d0
                bne.b   .03920
                moveq   #1,d0
                rts
.03920:
                moveq   #2,d0
.03922:
                rts

;==============================================================================
; Text
;==============================================================================
PrintList:
                move.l  (a4)+,d0
                bmi.b   .03934
                movea.l d0,a1
                movea.l (a4)+,a0
                move.w  #$2000,d1
                bsr.b   PrintString
                bra.b   PrintList
.03934:
                rts

; PrintString: typewriter print, fire aborts the attract mode
PrintString:
                btst.b  #$7,(CIAA_PRA).l
                bne.b   .03952
                tst.b   (TitleAbort).l
                beq.b   .03952
                movea.l (TitleStack).l,a7
                bra.w   AbortTitle
.03952:
                tst.b   (a0)
                beq.b   .03970
                tst.w   d1
                beq.b   .03968
                moveq   #95,d0
                bsr.w   DrawChar
                move.w  d1,d0
.03962:
                nop
                dbra    d0,.03962
.03968:
                move.b  (a0)+,d0
                bsr.b   DrawChar
                addq.l  #$1,a1
                bra.b   PrintString
.03970:
                rts
; DrawChar: d0 = character, a1 = screen byte.  Looks it up in CharSet
; (unknown characters print as the last one) and copies the 8x8 font
; ($2CEB8, 2 planes $180 apart) into planes 0 and 1 of both screens,
; clearing planes 2 and 3.
DrawChar:
                movem.l d0/a0-a2,-(a7)
                lea.l   (CharSet).l,a0
.0397c:
                cmp.b   (a0),d0
                beq.b   .03986
                tst.b   (a0)+
                bne.b   .0397c
                subq.l  #$2,a0
.03986:
                suba.l  #$570B,a0
                move.l  a0,d0
                lsl.w   #$3,d0
                lea.l   ($2CEB8).l,a0
                adda.l  d0,a0
                moveq   #7,d0
                movea.l a1,a2
                adda.l  #$DD00,a2
.039a2:
                move.b  (a0),(a1)
                move.b  (a0)+,(a2)
                move.b  $17F(a0),$34(a1)
                move.b  $17F(a0),$34(a2)
                clr.b   $68(a1)
                clr.b   $9C(a1)
                clr.b   $68(a2)
                clr.b   $9C(a2)
                adda.l  #$D0,a1
                adda.l  #$D0,a2
                dbra    d0,.039a2
                movem.l (a7)+,d0/a0-a2
                rts

;==============================================================================
; Music and sound effects
;==============================================================================
UpdateJingle:
                move.b  (JingleCmd).l,d0
                move.b  #$2,(JingleCmd).l
                ext.w   d0
                btst.b  #$1,(EndSequenceFlags).l
                beq.b   .039fc
                movea.l (LV_EndMusic).l,a1
                jsr     (a1)
                bra.b   .03a02
.039fc:
                jsr     (LV_Entry).l
.03a02:
                tst.b   d0
                bne.b   .03a0c
                clr.b   (JinglePlaying).l
.03a0c:
                rts

; LoadShared: tracks 63-67 -> $4A300
LoadShared:
                move.l  #$4A300,d2
                moveq   #63,d0
                moveq   #5,d1
                bra.w   LoadTracksCached
AbortTitle:
                clr.b   (TitleMusicOn).l
                move.w  #$F,$96(a6)
                clr.b   (TitleAbort).l
                bra.w   ClearPlayfield
; RestoreMusic: the title music.  If a copy was kept in fast/slow RAM
; (MusicCopy, from stage 2) it is copied back to MUSIC ($52300, $1FBD0
; bytes) and
; the TFMX player restarted (mdat $6FD28, smpl $53768); otherwise MUSIC is
; marked as overwritten so the title stays silent.
RestoreMusic:
                move.l  (MusicCopy).l,d0
                beq.b   .03a66
                movea.l d0,a1
                lea.l   (MUSIC).l,a0
                move.w  #$7EF3,d0
.03a46:
                move.l  (a1)+,(a0)+
                dbra    d0,.03a46
                move.l  #$6FD28,d0
                move.l  #$53768,d1
                jsr     (MUSIC_INIT).l
                moveq   #0,d0
                jmp     (MUSIC_START).l
.03a66:
                clr.l   (MUSIC).l
                rts
; UpdateMusic: drives the level's music player (LV_Music, called with
; d0 = 0).  JingleState > 0 starts jingle JingleState-1 (d4 = n<<8|$FF),
; < 0 keeps it going until the player reports the end; otherwise
; MusicRequest starts song n-1 (positive, d3 = -1) or fades (negative).
UpdateMusic:
                move.b  (JingleState).l,d4
                beq.b   .03aa8
                bmi.b   .03a8e
                subq.b  #$1,d4
                lsl.w   #$8,d4
                move.b  #$FF,d4
                clr.b   (MusicFadeReq).l
                st.b    (JingleState).l
                bra.b   .03a90
.03a8e:
                moveq   #1,d4
.03a90:
                moveq   #0,d0
                moveq   #0,d3
                movea.l (LV_Music).l,a0
                jsr     (a0)
                tst.b   d4
                bpl.b   .03aa6
                clr.b   (JingleState).l
.03aa6:
                rts
.03aa8:
                moveq   #0,d1
                moveq   #0,d4
                move.b  (MusicRequest).l,d1
                beq.b   UpdateMusicDone
                bmi.b   .03ac4
                subq.w  #$1,d1
                moveq   #-1,d3
                move.b  #$FE,(MusicRequest).l
                bra.b   .03ad0
.03ac4:
                neg.b   d1
                move.w  d1,d3
                move.b  #$FE,(MusicRequest).l
.03ad0:
                moveq   #0,d0
                movea.l (LV_Music).l,a0
                jsr     (a0)
                tst.b   d0
                bne.b   UpdateMusicDone
                clr.b   (MusicRequest).l
UpdateMusicDone:
                rts

; PlaySound: d0 = effect number (priority-based on two channels)
; Queue effect d0 on whichever channel holds the lower-priority sound (or
; not at all if both are busy with higher priorities).  Ignored while a
; jingle plays.  UpdateSound starts queued effects from the VBL.
PlaySound:
                tst.b   (JingleState).l
                bne.b   UpdateMusicDone
                movem.l d1-d2/a0-a1,-(a7)
                lea.l   (SoundTable).l,a0
                move.w  d0,d1
                move.w  d1,d2
                lsl.w   #$3,d1
                lsl.w   #$2,d2
                add.w   d2,d1
                move.w  $A(a0,d1.w),d1
                lea.l   (SoundChannels).l,a0
                lea.l   $8(a0),a1
                move.b  $1(a0),d2
                cmp.b   d2,d1
                bcs.b   .03b28
                cmp.b   $1(a1),d1
                bcs.b   .03b30
                cmp.b   $1(a1),d2
                bcs.b   .03b30
                movea.l a1,a0
                bra.b   .03b30
.03b28:
                cmp.b   $1(a1),d1
                bcs.b   .03b38
                movea.l a1,a0
.03b30:
                move.b  d0,$2(a0)
                move.b  d1,$1(a0)
.03b38:
                movem.l (a7)+,d1-d2/a0-a1
PlaySoundDone:
                rts
UpdateSound:
                lea.l   (SoundChannels).l,a6
                lea.l   (CUSTOM+$0C0).l,a5
                bsr.w   UpdateChannel
                addq.l  #$8,a6
                adda.w  #$10,a5
; UpdateChannel: a6 = SoundChannels entry, a5 = Paula channel.  Starts a
; queued effect (+2) from SoundTable: pointer, length, period, volume,
; priority; then enables its audio interrupt and DMA.  Level4Int stops it
; once it has played once.
UpdateChannel:
                move.b  $2(a6),d0
                bmi.b   PlaySoundDone
                tst.b   (a6)
                beq.b   .03b76
                bmi.b   .03b76
                move.w  $4(a6),(CUSTOM+DMACON).l
                move.w  $6(a6),(CUSTOM+INTENA).l
                move.b  #$FF,(a6)
                rts
.03b76:
                lea.l   (SoundTable).l,a0
                and.w   #$FF,d0
                move.w  d0,d1
                lsl.w   #$3,d1
                lsl.w   #$2,d0
                add.w   d1,d0
                move.l  (a0,d0.w),(a5)
                move.w  $4(a0,d0.w),$4(a5)
                move.w  $6(a0,d0.w),$6(a5)
                move.w  $8(a0,d0.w),$8(a5)
                move.b  $B(a0,d0.w),$1(a6)
                move.w  $6(a6),d0
                move.w  d0,(CUSTOM+INTREQ).l
                or.w    #$8000,d0
                move.w  d0,(CUSTOM+INTENA).l
                move.b  #$FF,$2(a6)
                clr.b   $3(a6)
                move.b  #$1,(a6)
                move.w  $4(a6),d0
                or.w    #$8000,d0
                move.w  d0,(CUSTOM+DMACON).l
                rts

; Level4Int: audio interrupts for channels 2 and 3
; Audio interrupts: the first one after a start means Paula has latched
; the sample; the second means it has played once - then DMA and the
; interrupt for that channel are switched off (one-shot effects).
Level4Int:
                movem.l d0-d1/a6,-(a7)
                move.w  (CUSTOM+INTREQR).l,d0
                and.w   #$600,d0
                tst.b   (JingleState).l
                bne.b   .03c08
                btst    #$9,d0
                beq.b   .03bfa
                lea.l   (SoundChannels).l,a6
                bsr.b   AudioIntChannel
.03bfa:
                btst    #$A,d0
                beq.b   .03c08
                lea.l   (SoundChannel3).l,a6
                bsr.b   AudioIntChannel
.03c08:
                move.w  d0,(CUSTOM+INTREQ).l
                movem.l (a7)+,d0-d1/a6
                rte
AudioIntChannel:
                tst.b   $3(a6)
                beq.b   .03c32
                move.w  $4(a6),(CUSTOM+DMACON).l
                move.w  $6(a6),(CUSTOM+INTENA).l
                clr.b   (a6)
                clr.b   $1(a6)
                rts
.03c32:
                move.b  #$1,$3(a6)
                rts

;==============================================================================
; Disk: track loader, cache, decruncher, high-score track
;==============================================================================
; LoadTracksCached: d0 = track, d1 = count, d2 = dest
LoadTracksCached:
                tst.l   (CacheBase).l
                beq.w   LoadTracks
                lea.l   (TrackCache).l,a0
                moveq   #17,d3
.03c4c:
                cmp.w   (a0),d0
                bne.b   .03c5c
                cmp.w   $2(a0),d1
                bne.b   .03c5c
                move.l  $4(a0),d3
                bra.b   .03cb6
.03c5c:
                addq.l  #$8,a0
                dbra    d3,.03c4c
                lea.l   (TrackCache).l,a0
                moveq   #17,d3
.03c6a:
                tst.w   $2(a0)
                beq.b   .03c7a
                addq.l  #$8,a0
                dbra    d3,.03c6a
                bra.w   LoadTracks
.03c7a:
                move.l  d1,d3
                mulu.w  #$666,d3
                and.l   #$FFFF,d3
                lsl.l   #$2,d3
                add.l   $4(a0),d3
                cmp.l   (CacheLimit).l,d3
                bcs.b   .03c98
                bra.w   LoadTracks
.03c98:
                move.l  d3,$C(a0)
                movem.l d0-d2/a0,-(a7)
                move.l  $4(a0),d2
                bsr.w   LoadTracks
                movem.l (a7)+,d0-d2/a0
                move.w  d0,(a0)
                move.w  d1,$2(a0)
                move.l  $4(a0),d3
.03cb6:
                mulu.w  #$666,d1
                subq.w  #$1,d1
                movea.l d3,a0
                movea.l d2,a1
.03cc0:
                move.l  (a0)+,(a1)+
                dbra    d1,.03cc0
                rts
LoadTracks:
                bsr.w   MotorOn
                bsr.w   SeekTrack
                move.w  d1,d3
                movea.l d2,a1
LoadTracksNext:
                move.l  d2,(LoadDest).l
                movem.l d0-d7/a0-a6,-(a7)
                bsr.w   ReadTrack
                bsr.w   DecodeTrack
                movem.l (a7)+,d0-d7/a0-a6
                add.l   #$1998,d2
                moveq   #0,d0
                move.w  (CurrentTrack).l,d0
                addq.w  #$1,d0
                bsr.w   SeekTrack
                subq.w  #$1,d1
                bne.b   LoadTracksNext
                bra.w   MotorOff
; DecodeTrack: a long custom track in TRACK_BUFFER -> LoadDest.
; $1998 bytes as $666 (odd, even) MFM long pairs, then the checksum pair:
; EOR of all $CCC raw longs AND $55555555, XOR $AAAAAAAA (the rol of
; $55555555).  On a bad checksum it steps the head away and back and
; reads the track again (forever).
DecodeTrack:
                lea.l   (TRACK_BUFFER+2).l,a0
                movea.l (LoadDest).l,a1
                movea.l a0,a2
                moveq   #0,d0
                move.w  #$CCB,d2
                move.l  #$55555555,d6
.03d20:
                move.l  (a0)+,d1
                eor.l   d1,d0
                dbra    d2,.03d20
                and.l   d6,d0
                rol.l   #$1,d6
                eor.l   d6,d0
                move.l  d0,d6
                move.l  (a0)+,d0
                move.l  (a0)+,d1
                and.l   #$55555555,d1
                and.l   #$55555555,d0
                lsl.l   #$1,d0
                or.l    d1,d0
                cmp.l   d0,d6
                bne.b   .03d6a
                move.l  #$665,d6
.03d4e:
                move.l  (a2)+,d0
                move.l  (a2)+,d1
                and.l   #$55555555,d0
                and.l   #$55555555,d1
                lsl.l   #$1,d0
                or.l    d1,d0
                move.l  d0,(a1)+
                dbra    d6,.03d4e
                rts
.03d6a:
                move.w  (CurrentTrack).l,d0
                addq.w  #$2,d0
                bsr.w   SeekTrack
                move.w  (CurrentTrack).l,d0
                subq.w  #$2,d0
                bsr.w   SeekTrack
                bsr.w   ReadTrack
                bra.w   DecodeTrack
; ReadTrack: DMA read of $19AC words with word sync (SyncWord, $9521 on
; the game's tracks) into TRACK_BUFFER; waits for DSKBLK.
ReadTrack:
                move.l  (SyncWord).l,d7
                swap    d7
                move.w  d7,$7E(a6)
                move.w  #$7F00,$9E(a6)
                move.w  #$9500,$9E(a6)
                move.l  #TRACK_BUFFER,$20(a6)
                move.w  #$99AC,$24(a6)
                move.w  #$99AC,$24(a6)
.03db6:
                move.w  $1E(a6),d7
                and.w   #$2,d7
                beq.b   .03db6
                move.w  #$2,$9C(a6)
                move.w  #$4000,$24(a6)
                rts
; MotorOn / MotorOff: switch DriveUnit's motor (CIA-B PRB: /MTR is
; latched when the drive's /SEL goes low).
MotorOn:
                move.l  d0,-(a7)
                bclr.b  #$7,(CIAB_PRB).l
                nop
                nop
                ori.b   #$78,(CIAB_PRB).l
                move.w  (DriveUnit).l,d0
                addq.w  #$3,d0
                bclr.b  d0,(CIAB_PRB).l
                bsr.w   StepDelay
                bsr.b   WaitDiskReady
                move.l  (a7)+,d0
                rts
MotorOff:
                move.l  d0,-(a7)
                bset.b  #$7,(CIAB_PRB).l
                nop
                nop
                ori.b   #$78,(CIAB_PRB).l
                move.w  (DriveUnit).l,d0
                addq.w  #$3,d0
                bclr.b  d0,(CIAB_PRB).l
                bsr.w   StepDelay
                move.l  (a7)+,d0
                rts
WaitDiskReady:
                btst.b  #$5,(CIAA_PRA).l
                bne.b   WaitDiskReady
                rts
; SeekTrack: d0 = track (cylinder * 2 + side).  Selects the side, then
; steps the head to the cylinder; the first call seeks track 0 first.
SeekTrack:
                movem.l d0-d1,-(a7)
                move.w  (CurrentTrack).l,d1
                bpl.b   .03e46
                bsr.w   SeekZero
                clr.w   d1
.03e46:
                bset.b  #$2,(CIAB_PRB).l
                btst    #$0,d0
                beq.b   .03e60
                nop
                nop
                bclr.b  #$2,(CIAB_PRB).l
.03e60:
                move.w  d0,(CurrentTrack).l
                lsr.w   #$1,d0
                lsr.w   #$1,d1
                cmp.w   d0,d1
                beq.b   .03e8a
                sub.w   d0,d1
                bmi.b   .03e7e
.03e72:
                bsr.b   StepOut
                bsr.b   StepDelay
                bsr.b   WaitDiskReady
                subq.w  #$1,d1
                bne.b   .03e72
                bra.b   .03e8a
.03e7e:
                neg.w   d1
.03e80:
                bsr.b   StepIn
                bsr.b   StepDelay
                bsr.b   WaitDiskReady
                subq.w  #$1,d1
                bne.b   .03e80
.03e8a:
                movem.l (a7)+,d0-d1
                rts
; SeekZero: step out until the drive reports track 0 (CIA-A PRA bit 4).
SeekZero:
                btst.b  #$4,(CIAA_PRA).l
                beq.b   .03ea2
                bsr.b   StepOut
                bsr.b   StepDelay
                bsr.b   WaitDiskReady
                bra.b   SeekZero
.03ea2:
                clr.w   (CurrentTrack).l
                rts
StepOut:
                bset.b  #$1,(CIAB_PRB).l
                bclr.b  #$0,(CIAB_PRB).l
                nop
                nop
                nop
                bset.b  #$0,(CIAB_PRB).l
                rts
StepIn:
                bclr.b  #$1,(CIAB_PRB).l
                bclr.b  #$0,(CIAB_PRB).l
                nop
                nop
                nop
                bset.b  #$0,(CIAB_PRB).l
                rts
StepDelay:
                movem.w d0,-(a7)
                move.w  #$4000,d0
.03ef2:
                dbra    d0,.03ef2
                movem.w (a7)+,d0
                rts

; Decrunch: a0 = crunched, a1 = dest -> d0 = 0 if the checksum is good
; Crunched file: +0.l length L, stream longs read backwards, L-8 checksum,
; L-4 decrunched length.  Codes: 00+3 bits n+1 literals | 01+8 off: copy 2
; | 100+9 off: copy 3 | 101+10 off: copy 4 | 110+8 n,12 off: copy n+1
; | 111+8 n: n+9 literals.  (tools/decrunch.py is an exact port.)
Decrunch:
                adda.l  (a0),a0
                movea.l -(a0),a2
                adda.l  a1,a2
                move.l  -(a0),d5
                move.l  -(a0),d0
                eor.l   d0,d5
.03f08:
                lsr.l   #$1,d0
                bne.b   .03f0e
                bsr.b   DecrunchRefill
.03f0e:
                bcs.b   .03f42
                moveq   #8,d1
                moveq   #1,d3
                lsr.l   #$1,d0
                bne.b   .03f1a
                bsr.b   DecrunchRefill
.03f1a:
                bcs.b   .03f68
                moveq   #3,d1
                clr.w   d4
.03f20:
                bsr.b   GetBits
                move.w  d2,d3
                add.w   d4,d3
.03f26:
                moveq   #7,d1
.03f28:
                lsr.l   #$1,d0
                bne.b   .03f2e
                bsr.b   DecrunchRefill
.03f2e:
                roxl.l  #$1,d2
                dbra    d1,.03f28
                move.b  d2,-(a2)
                dbra    d3,.03f26
                bra.b   .03f74
.03f3c:
                moveq   #8,d1
                moveq   #8,d4
                bra.b   .03f20
.03f42:
                moveq   #2,d1
                bsr.b   GetBits
                cmp.b   #$2,d2
                blt.b   .03f5e
                cmp.b   #$3,d2
                beq.b   .03f3c
                moveq   #8,d1
                bsr.b   GetBits
                move.w  d2,d3
                move.w  #$C,d1
                bra.b   .03f68
.03f5e:
                move.w  #$9,d1
                add.w   d2,d1
                addq.w  #$2,d2
                move.w  d2,d3
.03f68:
                bsr.b   GetBits
.03f6a:
                subq.w  #$1,a2
                move.b  (a2,d2.w),(a2)
                dbra    d3,.03f6a
.03f74:
                cmpa.l  a2,a1
                blt.b   .03f08
                move.l  d5,d0
                rts
DecrunchRefill:
                move.l  -(a0),d0
                eor.l   d0,d5
                move.w  #$10,ccr
                roxr.l  #$1,d0
                rts
; GetBits: d1 = n -> d2 = the next n bits of the crunched stream.
GetBits:
                subq.w  #$1,d1
                clr.w   d2
.03f8c:
                lsr.l   #$1,d0
                bne.b   .03f9a
                move.l  -(a0),d0
                eor.l   d0,d5
                move.w  #$10,ccr
                roxr.l  #$1,d0
.03f9a:
                roxl.l  #$1,d2
                dbra    d1,.03f8c
                rts
; LoadHighScores: read track 68 (sync $4489, up to 6 tries) into
; HighScores.  Layout after the sync word: checksum (odd/even longs,
; XOR $12345678), a spare pair, then 90 longs as odd/even pairs.  The
; checksum is the EOR of the 200 raw data longs AND $55555555.  A bad
; checksum keeps the built-in table (the factory disk's track 68 is a
; placeholder that never passes, so scores only load once saved).
LoadHighScores:
                bsr.w   MotorOn
                moveq   #68,d0
                bsr.w   SeekTrack
                moveq   #5,d7
.03fae:
                bsr.w   ReadScoreTrack
                lea.l   (TRACK_BUFFER+2).l,a0
                move.l  (a0)+,d0
                move.l  (a0)+,d1
                and.l   #$55555555,d0
                and.l   #$55555555,d1
                lsl.l   #$1,d0
                or.l    d1,d0
                eori.l  #$12345678,d0
                move.l  d0,d6
                addq.l  #$8,a0
                movea.l a0,a1
                move.w  #$C7,d2
                moveq   #0,d0
.03fde:
                move.l  (a0)+,d1
                eor.l   d1,d0
                dbra    d2,.03fde
                and.l   #$55555555,d0
                cmp.l   d6,d0
                bne.b   .0401a
                movea.l a1,a0
                lea.l   (HighScores).l,a1
                move.w  #$59,d2
.03ffc:
                move.l  (a0)+,d0
                move.l  (a0)+,d1
                and.l   #$55555555,d0
                and.l   #$55555555,d1
                lsl.l   #$1,d0
                or.l    d1,d0
                move.l  d0,(a1)+
                dbra    d2,.03ffc
                bra.w   MotorOff
.0401a:
                dbra    d7,.03fae
                bra.w   MotorOff
; SaveHighScores: builds track 68 in TRACK_BUFFER and writes it, unless
; the disk is write-protected (CIA-A PRA bit 3).  $AAAA fill, 1000 bytes
; of gap, sync $4489 + $2AAA, checksum and a zero long, then 100 longs of
; HighScores as odd/even MFM pairs (EncodeLong).  Not called in cheat mode.
SaveHighScores:
                bsr.w   MotorOn
                btst.b  #$3,(CIAA_PRA).l
                beq.w   .040b4
                moveq   #68,d0
                bsr.w   SeekTrack
                lea.l   (TRACK_BUFFER).l,a1
                move.w  #$BB7,d0
.04042:
                move.l  #$AAAAAAAA,(a1)+
                dbra    d0,.04042
                lea.l   (TRACK_BUFFER+$3E8).l,a1
                move.l  #$44892AAA,(a1)+
                move.l  #$AAAAAAAA,(a1)+
                move.l  #$AAAAAAAA,(a1)+
                move.l  #$AAAAAAAA,(a1)+
                move.l  #$AAAAAAAA,(a1)+
                movea.l a1,a2
                lea.l   (HighScores).l,a0
                move.w  #$63,d4
.0407c:
                move.l  (a0)+,d0
                bsr.w   EncodeLong
                dbra    d4,.0407c
                movea.l a2,a0
                move.w  #$C7,d2
                moveq   #0,d0
.0408e:
                move.l  (a0)+,d1
                eor.l   d1,d0
                dbra    d2,.0408e
                lea.l   -$10(a2),a1
                and.l   #$55555555,d0
                eori.l  #$12345678,d0
                bsr.w   EncodeLong
                moveq   #0,d0
                bsr.w   EncodeLong
                bsr.w   WriteScoreTrack
.040b4:
                bra.w   MotorOff
; ReadScoreTrack: DMA read with word sync $4489 into TRACK_BUFFER ($300
; words), waiting for the drive to be ready and the DSKBLK interrupt.
ReadScoreTrack:
                lea.l   (CUSTOM).l,a6
                move.w  #$8210,$96(a6)
                move.w  #$7FFF,$9E(a6)
                move.w  #$9500,$9E(a6)
                move.w  #$4489,$7E(a6)
                move.w  #$4000,$24(a6)
                move.l  #TRACK_BUFFER,$20(a6)
.040e4:
                btst.b  #$5,(CIAA_PRA).l
                bne.b   .040e4
                move.w  #$8300,$24(a6)
.040f4:
                move.w  #$8300,$24(a6)
.040fa:
                andi.w  #$2,$1E(a6)
                beq.b   .040fa
                move.w  #$2,$9C(a6)
                move.w  #$4000,$24(a6)
                rts
; WriteScoreTrack: DMA write of TRACK_BUFFER ($194E words, MFM with
; precompensation off) starting at the index pulse (CIA-B ICR FLG), with a
; time-out.
WriteScoreTrack:
                lea.l   (CUSTOM).l,a6
                move.w  #$7FFF,$9E(a6)
                move.w  #$9100,$9E(a6)
                move.w  #$4000,$24(a6)
                move.w  #$2,$9C(a6)
                move.l  #TRACK_BUFFER,$20(a6)
                move.b  (CIAB_ICR).l,d7
.0413c:
                move.b  (CIAB_ICR).l,d7
                btst    #$4,d7
                beq.b   .0413c
                move.w  #$D94E,$24(a6)
                move.w  #$D94E,$24(a6)
                move.l  #$FFFFF,d7
.0415a:
                andi.w  #$2,$1E(a6)
                bne.b   .0416e
                subq.l  #$1,d7
                bne.b   .0415a
                move.w  #$4000,$24(a6)
                rts
.0416e:
                move.w  #$4000,$24(a6)
                move.w  #$2,$9C(a6)
                rts
; EncodeLong: d0 -> two MFM longs at (a1)+: odd bits, then even bits.
; Clock bits are set between two zero data bits, and the first clock bit
; is cleared if the previous MFM bit was a 1.
EncodeLong:
                move.l  d0,d3
                lsr.l   #$1,d0
                bsr.b   .04188
                move.l  d3,d0
                bsr.b   .04188
                rts
.04188:
                and.l   #$55555555,d0
                move.l  d0,d2
                eori.l  #$55555555,d2
                move.l  d2,d1
                lsl.l   #$1,d2
                lsr.l   #$1,d1
                bset    #$1F,d1
                and.l   d2,d1
                or.l    d1,d0
                btst.b  #$0,-$1(a1)
                beq.b   .041b0
                bclr    #$1F,d0
.041b0:
                move.l  d0,(a1)+
                rts

;==============================================================================
; DATA segment
;==============================================================================
; LevelTable: 8 x (track,count -> $4A2E4; track,count -> $4CB00; map row length in BYTES)
LevelTable:
                dc.w    $0045,$0002,$0047,$000D,$0218,$0054,$0001,$0055
                dc.w    $000D,$0168,$0062,$0002,$0064,$000B,$0088,$006F
                dc.w    $0002,$0071,$0009,$0158,$007A,$0001,$007B,$0008
                dc.w    $01A4,$0083,$0001,$0084,$0005,$0148,$0089,$0002
                dc.w    $008B,$000A,$0134,$0095,$0001,$0096,$0009,$0176
NewLifeFlag:
                dc.b    $00
Level:
                dc.b    $00
ShipSpawned:
                dc.b    $00
ShipAlive:
                dc.b    $00
ShipHit:
                dc.b    $00
DeathTimer:
                dc.b    $00
FadeSteps:
                dc.b    $00
ShipIntroTimer:
                dc.b    $00
SpaceKey:
                dc.b    $00
StageEndStarted:
                dc.b    $00
Continues:
                dc.b    $00
Paused:
                dc.b    $00
BonusRollDelay:
                dc.w    $0000
Score:
                dc.w    $0000,$0000
Bonus:
                dc.w    $0000,$0000
ExtraLifePtr:
                dc.w    $0000,$0000
ScoreShown:
                dc.b    $00,$00,$00
GamesPlayed:
                dc.b    $00
LevelTablePtr:
                dc.w    $0000,$0000
Lives:
                dc.w    $0000
GameState:
                dc.w    $0000,$0000
RandomSeed:
                dc.w    $0000,$0000
Checkpoint:
                dc.w    $0000
SpriteColours:
                dc.w    $0000,$0FFF,$0444,$0777,$0999,$0BBB,$0DDD,$0333
                dc.w    $0F33,$0F90,$0C00,$0FD0,$004D,$006F,$04AF,$0000
; object definition: speed-up flash, 2 frames ($12490)
DefSpeedFlash:
                dc.w    $1303,$002E,$0260,$0003,$FFFF,$0000,$0001,$2490
                dc.w    $0000,$0130,$0000,$427A,$0000,$427E,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
SpeedFlashAnim:
                dc.w    $0001,$FF00,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
StackTop:                               ; the stack grows down from here
; InitMapOffsets: offsets into GroundLaserMoves that get +MapRowBytes
; (GroundLaserRowDown) and -MapRowBytes (GroundLaserRowUp), $FFFF ends
GroundLaserRowDown:
                dc.w    $001A,$0042,$0060,$00BA,$00CE,$00F6,$015A,$01A0
                dc.w    $01D2,$01FA,$0236,$025E,$FFFF
GroundLaserRowUp:
                dc.w    $0006,$002E,$006A,$00B0,$00E2,$010A,$0146,$01AA
                dc.w    $01BE,$01F0,$024A,$0272,$FFFF
ExtraLifeTable:
                dc.w    $0005,$0000,$0015,$0000,$0025,$0000,$0040,$0000
                dc.w    $0060,$0000,$0000,$0000
DigitFont:
                dc.w    $7E10,$FEFE,$84FE,$FEFE,$7EFE,$C210,$0202,$8480
                dc.w    $8002,$8282,$8210,$0202,$8480,$8002,$8282,$8210
                dc.w    $FEFE,$84FE,$FE02,$FEFE,$8210,$8002,$FE02,$8202
                dc.w    $8202,$8610,$8002,$0402,$8202,$8202,$FE10,$FEFE
                dc.w    $04FE,$FE02,$FEFE,$0000
BigDigitLine:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
LifeIcon:
                dc.w    $0818,$4040,$6828,$1020,$4040,$6828,$3838,$3C3C
                dc.w    $3C28
BonusDigitsTable:
                dc.w    $0010,$0000,$0005,$0001,$0000,$0004,$0000,$1000
                dc.w    $0003,$0000,$0100,$0002,$0000,$0000,$0000
BonusText:
                dc.w    $2020,$2020,$2020,$2020
BonusTextEnd:
                dc.w    $0000
TxtStageCleared:
                dc.w    $7320,$7420,$6120,$6720,$6520,$2020,$7820,$2020
                dc.w    $6320,$6C20,$6520,$6120,$7220,$6520,$6400
TxtStageScore:
                dc.w    $7374,$6167,$6520,$7363,$6F72,$6500
TxtContinue:
                dc.w    $6320,$6F20,$6E20,$7420,$6920,$6E20,$7520,$6500
TxtPushFire:
                dc.w    $7075,$7368,$2066,$6972,$6520,$6275,$7474,$6F6E
                dc.b    $00
TxtCredit:
                dc.b    $63,$20,$72,$20,$65,$20,$64,$20,$69,$20,$74,$20,$20,$78,$00
; Ending text, shown when the game is finished after level 8
; (CheckEndOfGame): screen position.l, string.l pairs, $FFFFFFFF ends.
TxtEnding:
                dc.w    $0002,$EE34,$0000,$47EE,$0002,$FA64,$0000,$480D
                dc.w    $0003,$0694,$0000,$4827,$0003,$12C4,$0000,$4847
                dc.w    $0003,$1EF4,$0000,$4864,$0003,$2B24,$0000,$4881
                dc.w    $0003,$3754,$0000,$4893,$0003,$4384,$0000,$48B2
                dc.w    $0003,$745D,$0000,$48BE,$FFFF,$FFFF,$7468,$616E
                dc.w    $6B73,$2074,$6F20,$796F,$7572,$2062,$7261,$7665
                dc.w    $2066,$6967,$6874,$696E,$672E,$0074,$6865,$2063
                dc.w    $6F73,$6D6F,$7320,$7265,$7374,$6F72,$6564,$2070
                dc.w    $6561,$6365,$0074,$6865,$2062,$7964,$6F20,$656D
                dc.w    $7069,$7265,$2077,$6173,$2061,$6E6E,$6968,$696C
                dc.w    $6174,$6564,$0074,$6F20,$6E65,$7665,$7220,$7363
                dc.w    $6172,$6520,$7065,$6F70,$6C65,$2061,$6761,$696E
                dc.w    $2E00,$796F,$7572,$206E,$616D,$6520,$7769,$6C6C
                dc.w    $2072,$656D,$6169,$6E20,$696E,$2074,$6865,$0075
                dc.w    $6E69,$7665,$7273,$6520,$666F,$7265,$7665,$722E
                dc.w    $0074,$6861,$6E6B,$2079,$6F75,$2066,$6F72,$2070
                dc.w    $6C61,$7969,$6E67,$2074,$6865,$2067,$616D,$6500
                dc.w    $746F,$2074,$6865,$2065,$6E64,$2E00,$6661,$6374
                dc.w    $6F72,$2035,$0000
FineScrollX:
                dc.w    $0000
FineScrollY:
                dc.w    $0000
ScrollBplcon1:
                dc.w    $0000
ScrollXTimer:
                dc.w    $0000
ScrollXStep:
                dc.b    $00
ScrollYTimer:
                dc.b    $00
ScrollYRate:
                dc.b    $00
ScrollYStep:
                dc.b    $00
ScrollScriptTimer:
                dc.w    $0000
ScrollScriptPtr:
                dc.w    $0000,$0000,$00FC,$FDFE,$FFFF,$FFFF,$FFFF,$FFFF
                dc.b    $FF,$FF,$FF
ScrollSpeedTable:
                dc.b    $00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$03,$04,$00
                dc.b    $0A,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00,$00,$00,$00,$00
WavePtr:
                dc.w    $0000,$0000
PrevObject:
                dc.w    $0000,$0000
FreeObjects:
                dc.w    $0000,$0000
ActiveObjects:
                dc.w    $0000,$0000
WaveFrameCounter:
                dc.w    $0000
ExplosionTypes:
                dc.w    $0000,$493A,$0000,$000E,$0000,$4972,$0000,$000C
                dc.w    $0000,$49A8,$0000,$001A,$0000,$49EC,$0000,$0006
; object definition: explosion, 6 frames ($08740)
DefExplosion1:
                dc.w    $1E03,$002E,$03C0,$0000,$FFFF,$0000,$0000,$8740
                dc.w    $0000,$01E0,$0000,$4962,$0000,$427E,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0001,$0001,$0202,$0303
                dc.w    $0404,$0405,$0505,$05FF
; object definition: explosion, 6 frames ($09DC0)
DefExplosion2:
                dc.w    $1E03,$002E,$03C0,$0000
                dc.w    $FFFF,$0000,$0000,$9DC0,$0000,$01E0,$0000,$499A
                dc.w    $0000,$427E,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0001,$0001,$0102,$0203,$0304,$0405,$05FF
; object definition: large explosion, 48x51, 9 frames ($0B440)
DefExplosionLarge:
                dc.w    $3304
                dc.w    $002C,$0990,$0000,$FFFF,$0000,$0000,$B440
                dc.l    $000004C8
                dc.w    $0000,$49D0,$0000,$427E,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0001,$0201,$0102,$0203,$0304,$0405
                dc.w    $0506,$0607,$0708,$0805,$0506,$0607,$0708,$08FF
; object definition: ring burst, 7 frames ($10A50)
DefRingBurst:
                dc.w    $1E03,$002E,$03C0,$0001,$FFFF,$0000,$0001,$0A50
                dc.w    $0000,$01E0,$0000,$4A14,$0000,$427E,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$06FF
DirectionOctants:
                dc.w    $000F,$0E0D,$0C08,$090A,$0B0C,$0001,$0203,$0408
                dc.w    $0706,$0504
SlopeThresholds:
                dc.w    $0600,$02FE,$0156,$00AA,$0000
EnemyBullets:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
BulletVelocities:
                dc.w    $0000,$FFFD,$0002,$FFFD,$0003,$FFFD,$0003,$FFFE
                dc.w    $0004,$0000,$0003,$0002,$0003,$0003,$0002,$0003
                dc.w    $0000,$0003,$FFFE,$0003,$FFFD,$0003,$FFFD,$0002
                dc.w    $FFFC,$0000,$FFFD,$FFFE,$FFFD,$FFFD,$FFFE,$FFFD
LaserType:
                dc.w    $0000
LaserSide:
                dc.b    $00
FireHeld:
                dc.b    $00
BeamCharge:
                dc.b    $00
LaserCount:
                dc.b    $00
WaveBeamToggle:
                dc.b    $00
GroundLaserActive:
                dc.b    $00
WaveBeamMapOfs:
                dc.w    $0000
WaveBeamModulo:
                dc.w    $0000
WaveBeamBltsize:
                dc.w    $0000
WaveBeamGfx:
                dc.w    $0000,$0000
WaveBeamFrameSize:
                dc.w    $0000,$0000
BeamMeterLevel:
                dc.w    $0000
BeamMeterBits:
                dc.w    $0000,$0000
; Player shots: 14 slots in parallel word arrays, $1C bytes apart:
;   x +0 (0 = free), y +$1C, type +$38, hit box x/y +$54/+$70,
;   size w/h +$8C/+$A8
; Slots 0-3 the ship's shots (ShipFire, from ShotX3 down), 4-9 the free
; Force's (ShotX5/ShotX7/ShotX8/ShotsX), 10-11 the Bits' shot streams
; (BitShotX), 12 the anti-air laser (AntiAirLaserX), 13 the wave cannon
; beam (WaveBeamX).  HitByShots tests all 14.
ShotX:
                dc.w    $0000,$0000,$0000
ShotX3:
                dc.w    $0000,$0000
ShotX5:
                dc.w    $0000,$0000
ShotX7:
                dc.w    $0000
ShotX8:
                dc.w    $0000
ShotsX:
                dc.w    $0000
BitShotX:
                dc.w    $0000,$0000
AntiAirLaserX:
                dc.w    $0000
WaveBeamX:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000
AntiAirLaserY:
                dc.w    $0000
WaveBeamY:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000
AntiAirLaserFrame:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$000C,$000C
                dc.w    $000C,$000C,$0000,$0000,$0000,$0000,$0004,$0004
                dc.w    $0000,$0000,$0000,$0000,$0004,$0004,$0004,$0004
                dc.w    $0000,$0000,$0000,$0000,$000B,$000B,$0000,$0000
                dc.w    $0000,$0000
; Ship shot types (UpdateShots, type = shot $38): 16 bytes each
;   +0.w dx  +2.w dy  +4.l BLTSIZE  +8.l graphics  +$C.l mask
;   0: normal shot, 16x4, graphics in this file at $4E1E
;   1-4: 16x11 shots up-right, down-right, up, down ($08480-$0873F)
ShotTypes:
                dc.w    $0010,$0000
                dc.l    $00000402               ; BLTSIZE: 4 lines x 4 planes, 2 words
                dc.w    $0000,$4E1E,$0000,$4E3E,$000C,$FFF4
                dc.l    $00000B02               ; BLTSIZE: 11 lines x 4 planes, 2 words
                dc.w    $0000,$8480,$0000,$84D8,$000C,$000C
                dc.l    $00000B02               ; BLTSIZE: 11 lines x 4 planes, 2 words
                dc.w    $0000,$8530,$0000,$8588,$0000,$FFF4
                dc.l    $00000B02               ; BLTSIZE: 11 lines x 4 planes, 2 words
                dc.w    $0000,$85E0,$0000,$8638,$0000,$000C
                dc.l    $00000B02               ; BLTSIZE: 11 lines x 4 planes, 2 words
                dc.w    $0000,$8690,$0000,$86E8
; anti-air laser (red crystal), the double helix: 6 x $780 from $12950 (UpdateAntiAirLaser)
AntiAirLaserFrames:
                dc.w    $0001,$2950,$0001,$30D0,$0001,$3850,$0001,$3FD0
                dc.w    $0001,$4750,$0001,$4ED0
; wave cannon shot sizes by charge ($189D0-$19B8F) (FireWaveCannon)
; Wave cannon, 4 records of $1E bytes, highest charge first:
;   +0 charge needed  +2 dx  +4 dy  +6..+$D hit box  +$E map test offset
;   +$10 modulo  +$12 BLTSIZE  +$14 type  +$16.l graphics  +$1A.l frame size
;   charge 24: 64x16 ($19390)  18: 48x14 ($18E50)  12: 32x12 ($18B50)
;   6: 16x12 ($189D0).  Two frames alternate (graphics, graphics + 2*size),
;   mask at + size.
WaveCannonShots:
                dc.w    $0018,$000B,$0001,$0007,$0002,$0036,$000C,$0008
                dc.w    $002A,$1005,$000B,$0001,$9390,$0000,$0200,$0012
                dc.w    $0010,$0001,$0003,$0003,$002B,$0009,$0008,$002C
                dc.w    $0E04,$0009,$0001,$8E50,$0000,$0150,$000C,$0011
                dc.w    $0003,$000A,$0002,$0016,$0008,$0006,$002E,$0C03
                dc.w    $0007,$0001,$8B50
                dc.l    $000000C0
                dc.w    $0006,$001B,$0003,$0002,$0001,$000D,$000A,$0006
                dc.w    $0030,$0C02,$0005,$0001,$89D0,$0000,$0060
ReflectLaserMoves:
                dc.w    $000F,$FFF1,$0000,$FFFF,$FE72,$0010,$0000,$0003
                dc.w    $0000,$0002,$0000,$FFF0,$0001,$FFFF,$FE70,$0000
                dc.w    $0000,$0002,$0000,$0000,$FFF1,$FFF1,$0001,$FFFF
                dc.w    $FE6E,$FFF0,$0000,$0002,$FFFF,$FFFE,$0000,$FFF0
                dc.w    $0000,$FFFF,$FE70,$0000,$0000,$0003,$0000,$0000
                dc.w    $FFF1,$000F,$0002
                dc.l    $0000018E
                dc.w    $FFF0,$0000,$0001,$FFFF,$FFFE,$0000,$0010,$0003
                dc.w    $0000,$0190,$0000,$0000,$0000,$0000,$0000,$000F
                dc.w    $000F,$0003,$0000,$0192,$0010,$0000,$0000,$0000
                dc.w    $0002,$0000,$0010,$0002,$0000,$0190,$0000,$0000
                dc.w    $0001,$0000,$0000
LaserSegments:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0006,$019E,$0006,$019E,$04CF,$ACCF
                dc.w    $04CF,$ACCF,$04CF,$ACCF,$04CF,$ACCF,$0006,$019E
                dc.w    $0006,$019E,$019E,$019E,$019E,$019E,$ACCF,$ACCF
                dc.w    $ACCF,$ACCF,$ACCF,$ACCF,$ACCF,$ACCF,$019E,$019E
                dc.w    $019E,$019E
; ground laser (yellow crystal) frames: 4 x $E0 from $1C2D0 (UpdateLasers)
GroundLaserFrames:
                dc.w    $0001,$C2D0,$0001,$C3B0,$0001,$C490,$0001,$C570
GroundLaserMoves:
                dc.w    $0000,$FFF2,$0000,$FFFF,$FDE8,$000E,$0000,$0001
                dc.w    $0000,$0002,$0000,$000E,$0002
                dc.l    $00000218
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$0000,$FFF2,$0000
                dc.w    $FFFF,$FDE8,$000E,$0000,$0001,$0000,$0002,$0000
                dc.w    $000E,$0002
                dc.l    $00000218
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$000E,$0000,$0001
                dc.w    $0000,$0002,$0000,$000E,$0002
                dc.l    $00000218
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$0000,$0000,$FFFF
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$000E,$0000
                dc.w    $0001,$0000,$0002,$0000,$FFF2,$0000,$FFFF,$FDE8
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$0000,$0000,$FFFF
                dc.w    $0000,$0000,$0000,$000E,$0002
                dc.l    $00000218
                dc.w    $000E,$0000,$0001,$0000,$0002,$0000,$FFF2,$0000
                dc.w    $FFFF,$FDE8,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $000E,$0002
                dc.l    $00000218
                dc.w    $000E,$0000,$0001,$0000,$0002,$0000,$FFF2,$0000
                dc.w    $FFFF,$FDE8,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$FFF2,$0000,$0000,$0000
                dc.w    $FFF2,$0000,$0003,$FFFF,$FFFE,$0000,$000E,$0002
                dc.w    $0000,$0000,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$FFF2,$0000,$0003,$FFFF,$FFFE
                dc.w    $0000,$000E,$0002,$0000,$0000,$0000,$0000,$FFFF
                dc.w    $0000,$0000,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $FFF2,$0000,$0000,$0000,$FFF2,$0000,$0003,$FFFF
                dc.w    $FFFE,$0000,$000E,$0002,$0000,$0000,$0000,$0000
                dc.w    $FFFF,$0000,$0000,$FFF2,$0000,$0003,$FFFF,$FFFE
                dc.w    $0000,$FFF2,$0000,$0000,$0000,$0000,$0000,$FFFF
                dc.w    $0000,$0000,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$000E,$0002,$0000,$0000
                dc.w    $FFF2,$0000,$0003,$FFFF,$FFFE,$0000,$FFF2,$0000
                dc.w    $0000,$0000,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $000E,$0002,$0000,$0000,$FFF2,$0000,$0003,$FFFF
                dc.w    $FFFE,$0000,$FFF2,$0000,$0000,$0000,$0000,$0000
                dc.w    $FFFF,$0000,$0000
StageFlags:
                dc.b    $00
ShipTiltInput:
                dc.b    $00
ShipTiltFrame:
                dc.b    $00
BitsFlags:
                dc.b    $00
AutoPilotX:
                dc.w    $0000
AutoPilotY:
                dc.w    $0000
ShipSpeed:
                dc.w    $0000
ShipX:
                dc.w    $0000
ShipY:
                dc.w    $0000
ShipHitboxY:
                dc.w    $0000
ShipHitboxH:
                dc.w    $0000
ShipSpriteFrame:
                dc.w    $0000,$0000
VblCount:
                dc.w    $0000
VblCountLo:
                dc.b    $00
VblCountLoByte:
                dc.b    $00
ShipTiltTable:
                dc.w    $0505,$0404,$0406,$0606,$0606
UpperBitTrail:
                dc.w    $0000
UpperBitTrailOut:
                dc.w    $0000,$0000
UpperBitFrame:
                dc.w    $0000,$0000
LowerBitTrail:
                dc.w    $0000
LowerBitTrailOut:
                dc.w    $0000,$0000
LowerBitFrame:
                dc.w    $0000,$0000
UpperBitPos:
                dc.w    $0000
UpperBitY:
                dc.w    $0000
LowerBitPos:
                dc.w    $0000
LowerBitY:
                dc.w    $0000
UpperBitHitPos:
                dc.w    $0000,$0000
LowerBitHitPos:
                dc.w    $0000,$0000
FlipCountdown:
                dc.w    $0000
ShipUpdatesLeft:
                dc.w    $0000
FrameReady:
                dc.b    $00
BufferToggle:
                dc.b    $00
Flip50Hz:
                dc.w    $0000
DrawBuffer:
                dc.w    $0000,$0000
ForceLevel:
                dc.b    $00
ForceParkSide:
                dc.b    $00
ForceAnimLevel:
                dc.b    $00
ForceAnimTimer:
                dc.b    $00
ForceAnimDir:
                dc.b    $00
ForceActive:
                dc.b    $00
ForceSide:
                dc.b    $00
ForceYTimer:
                dc.b    $00
ForceHalt:
                dc.b    $00
ForceYDir:
                dc.b    $00
Fire2Latch:
                dc.w    $0000
ForceOfsX:
                dc.w    $0000
ForceOfsY:
                dc.w    $0000
ForceHitbox:
                dc.w    $0000
ForceHitboxY:
                dc.w    $0000
ForceHitboxSize:
                dc.w    $0000,$0000
ForceDockOfsX:
                dc.w    $0000
ForceDockOfsY:
                dc.w    $0000
ForceLaunchSpeed:
                dc.w    $0000
ForceFrame:
                dc.w    $0000,$0000
ForceState:
                dc.w    $0000,$0000
ForcePos:
                dc.w    $0000
ForceY:
                dc.w    $0000
ForceAnimTable:
                dc.w    $0000,$6A40,$0000,$6F40,$0000,$0100,$0003,$000E
                dc.w    $0000,$7040,$0000,$7630,$0000,$0130,$0003,$0011
                dc.w    $0000,$7760,$0000,$7D50,$0000,$0130,$0003,$0011
                dc.w    $0000,$7E80,$0000,$8300,$0000,$0180,$0004,$0016
ForceDockOffsets:
                dc.w    $FFED,$0000,$0018,$0001,$0000,$0000,$001A,$0001
                dc.w    $FFE0,$FFFE,$0000,$0000,$FFE7,$FFFC,$0014,$FFFD
ForceSpriteOffsets:
                dc.w    $000A,$0006,$0007,$0008,$0000,$0000,$0011,$000B
ForceHitboxes:
                dc.w    $0000,$0000,$0015,$000E,$0000,$0000,$0015,$0011
                dc.w    $000C,$0000,$0014,$0011,$0005,$0001,$0017,$0014
; object definition: POW Armor (power-up carrier), 10 frames ($15A50) - default wave object
DefPowArmor:
                dc.w    $1A03,$002E,$0340,$0003,$0001,$0000,$0001,$5A50
                dc.w    $0000,$01A0,$0000,$5224,$0000,$5238
                dc.l    ObjUpd_PowArmor
                dc.l    SpawnPowArmor
                dc.w    $0000,$0200
PowArmorWalkLeft:
                dc.b    $01,$00,$02,$00,$FF
PowArmorWalkRight:
                dc.b    $03,$05,$04,$05,$FF
PowArmorJumpLeft:
                dc.b    $07,$FF,$00,$06,$FF
PowArmorJumpRight:
                dc.b    $09,$FF,$00,$08,$FF,$00,$03,$00,$04,$00,$12,$00,$16,$00,$02,$00
                dc.b    $07,$00,$15,$00,$12,$00,$02,$00,$07,$00,$15,$00,$11,$00,$03,$00
                dc.b    $07,$00,$15,$00,$12,$00,$03,$00,$07,$00,$14,$00,$12,$00,$03,$00
                dc.b    $05,$00,$13,$00,$14,$00,$06,$00,$01,$00,$11,$00,$18,$00,$02,$00
                dc.b    $01,$00,$16,$00,$12,$00,$04,$00,$01,$00,$10,$00,$18,$00,$02,$00
                dc.b    $01,$00,$16,$00,$12
; object definition: power-up items - blue/red/yellow laser crystal, speed, missiles, bit ($17AD0)
DefPowerUp:
                dc.w    $1403,$002E,$0280,$0000,$FFFF,$0000,$0001,$7AD0
                dc.l    $00000140
                dc.w    $0000,$52B0,$0000,$52B8
                dc.l    ObjUpd_ScrollOff
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$FF00
                dc.w    $0000,$0000,$0013,$0010,$0000,$0000,$0013,$0010
                dc.w    $0000,$0000,$0013,$0010,$0000,$0000,$0013,$0014
                dc.w    $0000,$0000,$0013,$0011,$0002,$0004,$000E,$000B
; Copper list.  COLOR00, bitplanes off, BPL1-4 pointers (SetBitplanes),
; SPR4-7 pointers, SPR0-3 (the Force, set by UpdateForce), modulos $A8,
; COLOR01-15 (playfield palette), BPLCON1 (fine scroll), BPLCON2 = $24
; (sprites in front), BPLCON0 = $4200 (4 planes).
; Line $EC: copper interrupt.  Line $ED: HUD - 3 planes ($3200), non
; interleaved 40-byte lines at $2C7B0/$2CA08/$2CC60 ($258 each, 15 lines),
; its own colours, then COLOR01 changes on lines $EE-$F3 (gradient).
CopperList:
                dc.w    $0180,$0000             ; COLOR00
                dc.w    $0100,$0000             ; BPLCON0
                dc.w    $00E0                   ; BPL1PTH
CopBplPtrs:
                dc.w    $0000
                dc.w    $00E2,$0000             ; BPL1PTL
                dc.w    $00E4,$0000             ; BPL2PTH
                dc.w    $00E6,$0000             ; BPL2PTL
                dc.w    $00E8,$0000             ; BPL3PTH
                dc.w    $00EA,$0000             ; BPL3PTL
                dc.w    $00EC,$0000             ; BPL4PTH
                dc.w    $00EE,$0000             ; BPL4PTL
                dc.w    $00F0,$0000             ; BPL5PTH
                dc.w    $00F2,$0000             ; BPL5PTL
                dc.w    $0130,$0004             ; SPR4PTH
                dc.w    $0132,$90A2             ; SPR4PTL
                dc.w    $0134,$0004             ; SPR5PTH
                dc.w    $0136,$914A             ; SPR5PTL
                dc.w    $0138,$0004             ; SPR6PTH
                dc.w    $013A,$91F2             ; SPR6PTL
                dc.w    $013C,$0004             ; SPR7PTH
                dc.w    $013E,$929A             ; SPR7PTL
                dc.w    $0120                   ; SPR0PTH
CopForceSprites:
                dc.w    $0000
                dc.w    $0122,$0004             ; SPR0PTL
                dc.w    $0124,$0000             ; SPR1PTH
                dc.w    $0126,$0004             ; SPR1PTL
                dc.w    $0128,$0000             ; SPR2PTH
                dc.w    $012A,$0004             ; SPR2PTL
                dc.w    $012C,$0000             ; SPR3PTH
                dc.w    $012E,$0004             ; SPR3PTL
                dc.w    $0108,$00A8             ; BPL1MOD
                dc.w    $010A,$00A8             ; BPL2MOD
                dc.w    $0182                   ; COLOR01
CopColours:
                dc.w    $0000
                dc.w    $0184,$0000             ; COLOR02
                dc.w    $0186,$0000             ; COLOR03
                dc.w    $0188,$0000             ; COLOR04
                dc.w    $018A,$0000             ; COLOR05
                dc.w    $018C,$0000             ; COLOR06
                dc.w    $018E,$0000             ; COLOR07
                dc.w    $0190,$0000             ; COLOR08
                dc.w    $0192,$0000             ; COLOR09
                dc.w    $0194,$0000             ; COLOR10
                dc.w    $0196,$0000             ; COLOR11
                dc.w    $0198,$0000             ; COLOR12
                dc.w    $019A,$0000             ; COLOR13
                dc.w    $019C,$0000             ; COLOR14
                dc.w    $019E,$0000             ; COLOR15
                dc.w    $0102                   ; BPLCON1
CopBplcon1:
                dc.w    $0000
                dc.w    $0104,$0024             ; BPLCON2
                dc.w    $0100,$4200             ; BPLCON0
                dc.w    $EC01,$FFFE             ; wait for line $EC
                dc.w    $009C,$8010             ; INTREQ: copper interrupt (CopperInt)
                dc.w    $0100,$0000             ; BPLCON0: blank while the HUD is set up
                dc.w    $0102,$0000             ; BPLCON1
                dc.w    $00E0,$0002             ; BPL1PTH: HUD planes, 40-byte lines
                dc.w    $00E2,$C7B0             ; BPL1PTL
                dc.w    $00E4,$0002             ; BPL2PTH
                dc.w    $00E6,$CA08             ; BPL2PTL
                dc.w    $00E8,$0002             ; BPL3PTH
                dc.w    $00EA,$CC60             ; BPL3PTL
                dc.w    $0108,$0000             ; BPL1MOD
                dc.w    $010A,$0000             ; BPL2MOD
                dc.w    $0184,$0999             ; COLOR02
                dc.w    $0186,$0ACD             ; COLOR03
                dc.w    $0188,$0FFF             ; COLOR04
                dc.w    $018A,$089F             ; COLOR05
                dc.w    $018C,$000C             ; COLOR06
                dc.w    $018E,$0E00             ; COLOR07
                dc.w    $ED01,$FFFE             ; wait for line $ED
                dc.w    $0100,$3200             ; BPLCON0: 3 planes (HUD)
                                                ; then a COLOR01 gradient:
                dc.w    $EE01,$FFFE             ; wait for line $EE
                dc.w    $0182,$0006             ; COLOR01
                dc.w    $EF01,$FFFE             ; wait for line $EF
                dc.w    $0182,$000A             ; COLOR01
                dc.w    $F001,$FFFE             ; wait for line $F0
                dc.w    $0182,$000E             ; COLOR01
                dc.w    $F101,$FFFE             ; wait for line $F1
                dc.w    $0182,$000A             ; COLOR01
                dc.w    $F201,$FFFE             ; wait for line $F2
                dc.w    $0182,$0006             ; COLOR01
                dc.w    $F301,$FFFE             ; wait for line $F3
                dc.w    $0182,$0FFF             ; COLOR01
                dc.w    $FFFF,$FFFE             ; end of list
MissileVelocities:
                dc.w    $0000,$FFFA,$0004,$FFFA,$0006,$FFFA,$0006,$FFFC
                dc.w    $0006,$0000,$0006,$0004,$0006,$0006,$0004,$0006
                dc.w    $0000,$0006,$FFFC,$0006,$FFFA,$0006,$FFFA,$0004
                dc.w    $FFFA,$0000,$FFFA,$FFFC,$FFFA,$FFFA,$FFFC,$FFFA
; homing missile frames: 16 directions x 2 animation frames (+16), $100 each, from $1A2D0 (UpdateMissiles)
MissileFrames:
                dc.w    $0001,$A2D0,$0001,$A3D0,$0001,$A4D0,$0001,$A5D0
                dc.w    $0001,$A6D0,$0001,$A7D0,$0001,$A8D0,$0001,$A9D0
                dc.w    $0001,$AAD0,$0001,$ABD0,$0001,$ACD0,$0001,$ADD0
                dc.w    $0001,$AED0,$0001,$AFD0,$0001,$B0D0,$0001,$B1D0
                dc.w    $0001,$B2D0,$0001,$B3D0,$0001,$B4D0,$0001,$B5D0
                dc.w    $0001,$B6D0,$0001,$B7D0,$0001,$B8D0,$0001,$B9D0
                dc.w    $0001,$BAD0,$0001,$BBD0,$0001,$BCD0,$0001,$BDD0
                dc.w    $0001,$BED0,$0001,$BFD0,$0001,$C0D0,$0001,$C1D0
MissileHitboxes:
                dc.w    $0005,$0000,$0006,$000B,$0004,$0001,$0009,$000A
                dc.w    $0006,$0001,$0009,$000A,$0004,$0003,$000C,$0007
                dc.w    $0005,$0005,$000B,$0006,$0005,$0005,$000A,$0008
                dc.w    $0005,$0005,$0009,$000A,$0005,$0004,$0008,$000B
                dc.w    $0005,$0006,$0006,$000A,$0001,$0004,$0008,$000B
                dc.w    $0001,$0005,$000A,$0009,$0001,$0004,$000A,$0008
                dc.w    $0000,$0005,$000B,$0006,$0001,$0002,$000A,$0008
                dc.w    $0002,$0001,$0009,$000A,$0004,$0001,$0008,$000B
Missile1:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$00FE,$0100
Missile2:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0002,$0000
MissilesEnabled:
                dc.w    $0000
MissileBestDist:
                dc.w    $0000
MissileReload:
                dc.w    $0000
MissilesInFlight:
                dc.w    $0000
TitleLetterList:
                dc.w    $0000,$55E6,$0000,$0000,$0000,$5602,$0005,$0E62
                dc.w    $0000,$561E,$0005,$0E8F,$0000,$563A,$0005,$0EBC
                dc.w    $0000,$5656,$0005,$0EE9,$0000,$5672,$0005,$0F16
                dc.w    $0000,$568E,$0000,$0000
TitleLetterAnim:
                dc.w    $00FF,$2A04,$002C,$07E0,$0000,$0000,$0000,$0004
                dc.w    $D792,$0000,$03F0,$0000,$0000,$0000,$56AA,$1A03
                dc.w    $002E,$0340,$0000,$0000,$0000,$0004,$FEF2,$0000
                dc.w    $01A0,$0000,$0000,$0000,$56AA,$2A04,$002C,$07E0
                dc.w    $0000,$0000,$0000,$0004,$DF72,$0000,$03F0,$0000
                dc.w    $0000,$0000,$56AA,$2A04,$002C,$07E0,$0000,$0000
                dc.w    $0000,$0004,$E752,$0000,$03F0,$0000,$0000,$0000
                dc.w    $56AA,$2A04,$002C,$07E0,$0000,$0000,$0000,$0004
                dc.w    $EF32,$0000,$03F0,$0000,$0000,$0000,$56AA,$2A04
                dc.w    $002C,$07E0,$0000,$0000,$0000,$0004,$F712,$0000
                dc.w    $03F0,$0000,$0000,$0000,$56AA,$0502,$0030,$0050
                dc.w    $0000,$0000,$0000,$0005,$0232,$0000,$0028,$0000
                dc.w    $0000,$0000,$56AA
TitlePalette:
                dc.w    $028C,$0FFF,$00FF,$0FEF,$0B9F,$095F,$0B7F,$0000
                dc.w    $0DBF,$00D9,$00B9,$0097,$0077,$0FFF,$0000
TextPalette:
                dc.w    $028C,$0FFF,$09BF,$005F,$000B,$095F,$0B7F,$0000
                dc.w    $0DBF,$00D9,$00B9,$0097,$0077,$0FFF,$0000
TitleState:
                dc.w    $0000,$0000
MusicCopy:
                dc.w    $0000,$0000
TitleStack:
                dc.w    $0000,$0000
TitleLettersDone:
                dc.b    $00
TitleFadeSteps:
                dc.b    $00
TitleLetterPhase:
                dc.b    $00
TitleMusicOn:
                dc.b    $00
TitleDelay:
                dc.w    $0000
TitleWipeTop:
                dc.w    $0000
TitleWipeBottom:
                dc.w    $0000
JinglePlaying:
                dc.b    $00
JingleCmd:
                dc.b    $00
TitleAbort:
                dc.b    $00
CheatMode:
                dc.b    $00
ScoreDigitChars:
                dc.b    $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$20
CharSet:
                dc.b    $61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70
                dc.b    $71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$30,$31,$32,$33,$34,$35
                dc.b    $36,$37,$38,$39,$2E,$2C,$2D,$5F,$21,$3F,$48,$43,$3C,$53,$45,$20
                dc.b    $00
TxtEnterName:
                dc.w    $706C,$6561,$7365,$2065,$6E74,$6572,$2079,$6F75
                dc.w    $7220,$6E61,$6D65,$2070,$6C61,$7965,$7220,$3100
; High-score table (LoadHighScores/SaveHighScores keep it on track 68).
; 10 entries, best first, 12 bytes each: screen offset of the line on the
; score screen.l, name.l, score.l (6-digit BCD).  The default table names
; the Amiga conversion team.
HighScores:
                dc.l    $00002490,HighScoreText+0*24,$00180000
                dc.l    $000030C0,HighScoreText+1*24,$00170000
                dc.l    $00003CF0,HighScoreText+2*24,$00160000
                dc.l    $00004920,HighScoreText+3*24,$00150000
                dc.l    $00005550,HighScoreText+4*24,$00090000
                dc.l    $00006180,HighScoreText+5*24,$00070000
                dc.l    $00006DB0,HighScoreText+6*24,$00050000
                dc.l    $000079E0,HighScoreText+7*24,$00040000
                dc.l    $00008610,HighScoreText+8*24,$00035000
                dc.l    $00009240,HighScoreText+9*24,$00030000
TopScore        equ     HighScores+8            ; best score (shown on the HUD)
LowestScoreEntry equ    HighScores+9*12
; Names: 16 characters and a 0, then the score as text (FormatScores) and a 0.
HighScoreText:
                dc.b    "achim moller    ",0,"000000",0
                dc.b    "holger schmidt  ",0,"000000",0
                dc.b    "lutz osterkorn  ",0,"000000",0
                dc.b    "stefan tsoupari.",0,"000000",0
                dc.b    "willi baecker   ",0,"000000",0
                dc.b    "darius zendeh   ",0,"000000",0
                dc.b    "teut weidemann  ",0,"000000",0
                dc.b    "robert graulich ",0,"000000",0
                dc.b    "thomas fanslau  ",0,"000000",0
                dc.b    "heiko schroeder ",0,"000000",0
TitleTextList:
                dc.w    $0002,$F251,$0000,$58F8,$0002,$F9A1,$0000,$590D
                dc.w    $0003,$0C51,$0000,$5923,$0003,$1FDC
TitleTextFreeplay:
                dc.w    $0000,$5937,$0003,$376B,$0000,$5948,$0003,$7AD9
                dc.w    $0000,$5952,$FFFF,$FFFF,$626C,$6173,$7420,$6F66
                dc.w    $6620,$616E,$6420,$7374,$7269,$6B65,$0074,$6865
                dc.w    $2065,$7669,$6C20,$6279,$646F,$2065,$6D70,$6972
                dc.w    $6521,$0070,$7265,$7373,$2066,$6972,$6520,$746F
                dc.w    $2073,$7461,$7274,$0066,$7265,$6570,$6C61,$7900
TxtTrainer:
                dc.w    $7472,$6169,$6E65,$7200,$6372,$6564,$6974,$2030
                dc.w    $3500,$4320,$3139,$3837,$2062,$7920,$6972,$656D
                dc.w    $0000
TxtCredits:
                dc.w    $0002,$EBC4,$0000,$59B6,$0002,$F4B2,$0000,$59D8
                dc.w    $0002,$FDA8,$0000,$59FE,$0003,$16D3,$0000,$5A17
                dc.w    $0003,$1EF3,$0000,$5A35,$0003,$35B3,$0000,$5A55
                dc.w    $0003,$3EA3,$0000,$5A75,$0003,$4793,$0000,$5A99
                dc.w    $0003,$5D83,$0000,$5AB8,$0003,$7783,$0000,$5AD7
                dc.w    $FFFF,$FFFF,$722D,$7479,$7065,$2061,$6D69,$6761
                dc.w    $2064,$6573,$6967,$6E65,$6420,$6279,$2066,$6163
                dc.w    $746F,$7220,$3500,$6C69,$6365,$6E73,$6564,$2066
                dc.w    $726F,$6D20,$6972,$656D,$2062,$7920,$656C,$6563
                dc.w    $7472,$6963,$2064,$7265,$616D,$7300,$7072,$6F64
                dc.w    $7563,$6564,$2062,$7920,$7261,$696E,$626F,$7720
                dc.w    $6172,$7473,$0070,$726F,$6772,$616D,$6D65,$6420
                dc.w    $2062,$7920,$2020,$6163,$6869,$6D20,$6D6F,$6C6C
                dc.w    $6572,$0020,$2020,$2020,$2020,$2020,$2020,$2020
                dc.w    $2020,$2020,$686F,$6C67,$6572,$2073,$6368,$6D69
                dc.w    $6474,$0020,$2067,$7261,$7068,$6963,$7320,$2062
                dc.w    $7920,$2020,$6C75,$747A,$206F,$7374,$6572,$6B6F
                dc.w    $726E,$0020,$2020,$2020,$2020,$2020,$2020,$2020
                dc.w    $2020,$2020,$7374,$6566,$616E,$2074,$736F,$7570
                dc.w    $6172,$6964,$6973,$0020,$2020,$2020,$2020,$2020
                dc.w    $2020,$2020,$2020,$2020,$7769,$6C6C,$6920,$6261
                dc.w    $6563,$6B65,$7200,$2020,$2020,$206D,$7573,$6963
                dc.w    $2020,$6279,$2020,$2064,$6172,$6975,$7320,$7A65
                dc.w    $6E64,$6568,$0074,$6974,$6C65,$206D,$7573,$6963
                dc.w    $2062,$7920,$2020,$6368,$7269,$7320,$6875,$656C
                dc.w    $7362,$6563,$6B00
; Two effect channels (audio channels 2 and 3), 8 bytes each:
;   +0.b state (0 idle, 1 started, $FF playing)  +1.b priority of the sound
;   +2.b requested effect (-1 none)  +3.b audio-interrupt count
;   +4.w DMACON bit  +6.w INTENA/INTREQ bit
SoundChannels:
                dc.w    $0000,$FF00,$0004,$0200
; second sound effect channel (audio channel 3)
SoundChannel3:
                dc.w    $0000,$FF00,$0008,$0400
; Sound effects: 14 entries of 12 bytes (samples in the $6000 block)
;   +0.l sample  +4.w length (words)  +6.w period  +8.w volume  +$A.b 0
;   +$B.b priority.  All are period 428 (8287 Hz), played once.
;    0 ship shot   1 wave cannon   2 reflect laser bounce   3 anti-air laser
;    4 ground laser   5 Force docks
;    6 enemy hit   7 ship explodes 8 power-up  9 beam charged
;   10-13 explosion types 0-3 (13 also repeats while the beam is full)
; WAVs: sfx/ (tools/extract_sounds.py)
SoundTable:
                dc.w    $0001,$C68A,$03B6,$01AC,$0028,$0014,$0001,$CDF6
                dc.w    $0817,$01AC,$0037,$0019,$0001,$DE24,$0C8E,$01AC
                dc.w    $0034,$0014,$0001,$F740,$0EF8,$01AC,$0033,$0014
                dc.w    $0002,$1530,$0AB1,$01AC,$0038,$0014,$0002,$2A92
                dc.w    $0AEF,$01AC,$0034,$0019,$0002,$4070,$010F,$01AC
                dc.w    $003C,$0015,$0002,$428E,$0EF3,$01AC,$0040,$001E
                dc.w    $0002,$6074,$0B1C,$01AC,$003C,$001C,$0002,$76AC
                dc.w    $0E57,$01AC,$0032,$0017,$0002,$935A,$090D,$01AC
                dc.w    $002A,$0015,$0002,$A574,$07C0,$01AC,$0029,$0015
                dc.w    $0002,$B4F4,$095E,$01AC,$0037,$0016,$0002,$8DFA
                dc.w    $02B0,$01AC,$0032,$0017
DriveUnit:
                dc.w    $0000
CurrentTrack:
                dc.w    $FFFF
SyncWord:
                dc.w    $9521,$2AAA
LoadDest:
                dc.w    $0007,$C400
CacheBase:
                dc.w    $0000,$0000
CacheLimit:
                dc.w    $0000,$0000
TrackCache:
                dc.w    $0000,$0000
CacheNext:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
