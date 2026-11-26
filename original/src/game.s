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
; Status: first pass.  Every routine is separated from data and the main
; systems are named; most routines are not yet commented line by line.
; Remaining L_xxxxx / D_xxxxx labels are unnamed targets (L = code, D = data).
;==============================================================================

; --- Custom chips / CIAs -------------------------------------------------------
CUSTOM          equ     $DFF000
DMACONR         equ     $002
VHPOSR          equ     $006
JOY0DAT         equ     $00C
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
ScoreToAddEnd:
                dc.w    $0000,$5360
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
L_00122:
                move.l  d2,(MusicCopy).l
                move.w  d3,(CurrentTrack).l
L_0012E:
                move.l  (CacheBase).l,(D_05BC8).l
                bsr.w   LoadHighScores
                bsr.w   FormatScores
L_00140:
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
                move.l  #$6A40,(D_05160).l
                move.l  #Force_Idle,(ForceState).l
                clr.l   (Score).l
                clr.b   (ForceActive).l
L_00188:
                st.b    (TitleMusicOn).l
L_0018E:
                move.l  #Level3Int,($6C).w
L_00196:
                move.l  #Level4Int,($70).w
L_0019E:
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
                clr.w   (D_0539E).l
                clr.w   (EndSequence).l
                clr.b   (ShipMode).l
                st.b    (ShipHit).l
                clr.b   (Paused).l
                move.w  #$ECC1,$90(a6)
                bsr.w   PaletteBlack
                bsr.w   TitleSequence
                move.w  #$780,$9C(a6)
                move.w  #$8600,$9A(a6)
                bsr.w   TimerCheck
                move.l  (D_05764).l,d0
                lea.l   ($2C905).l,a0
                bsr.w   DrawDigits
                move.w  #$FCC1,$90(a6)
L_00218:
                moveq   #0,d0
                lea.l   ($2C8F9).l,a0
                bsr.w   DrawDigits
                clr.l   (Score).l
                clr.l   (Bonus).l
                addq.b  #$1,(D_04221).l
                clr.b   (D_0513C).l
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
                clr.b   (D_0420D).l
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
MainLoop:
                tst.b   (FrameReady).l
                bne.w   CheckEndOfGame
                movea.l (GameState).l,a0
                jmp     (a0)
St_LevelFadeIn:
                bsr.w   LevelFadeInStep
St_PlayStart:
                btst.b  #$6,(StageFlags).l
                beq.b   GameFrame
                move.l  #St_Playing,(GameState).l
St_Playing:
                tst.b   (ShipHit).l
                beq.b   .00372
                bsr.w   ShipDied
                bra.b   GameFrame
.00372:
                tst.b   (LevelComplete).l
                beq.b   .00380
                bsr.w   StageEndSequence
                bra.b   GameFrame
.00380:
                bsr.w   SpawnWaves
                bsr.w   ShipFire
GameFrame:
                bsr.w   UpdateScroll
                bsr.w   DrawMap
                lea.l   ($48C62).l,a5
                move.l  #$FFFF0000,$44(a6)
                move.l  #$FFFEFFFE,$62(a6)
                bsr.w   UpdateShots
                bsr.w   UpdateWaveBeam
                bsr.w   UpdateObjects
                bsr.w   UpdateEnemyBullets
                bsr.w   UpdateMissiles
                bsr.w   ShipHitsMap
                movea.l (LV_Frame).l,a0
                jsr     (a0)
                bsr.w   UpdateScore
FrameDone:
                st.b    (FrameReady).l
.003d0:
                tst.b   (Paused).l
                bne.b   .003d0
CheckEndOfGame:
                btst.b  #$3,(EndSequenceFlags).l
                beq.w   MainLoop
                bsr.w   ClearPlayfield
                lea.l   (D_056C8).l,a1
                bsr.w   SetPalette
                lea.l   (D_047A2).l,a4
                bsr.w   PrintList
                clr.l   (VblCount).l
L_00402:
                move.w  (D_05106).l,d0
                add.w   #$20D,d0
.0040c:
                cmp.w   (D_05106).l,d0
                bhi.b   .0040c
                clr.b   (JinglePlaying).l
                clr.b   (D_056FD).l
                move.w  #$F,$96(a6)
                moveq   #0,d7
                bra.w   NewGame
St_StageClear:
                btst.b  #$7,(StageFlags).l
                beq.b   FrameDone
                bsr.w   ClearPlayfield
                lea.l   (D_056C8).l,a1
                bsr.w   SetPalette
                move.w  #$1000,d1
                lea.l   (D_04748).l,a0
                move.b  (Level).l,d0
                add.b   #$31,d0
                move.b  d0,$C(a0)
                lea.l   ($2FC05).l,a1
                bsr.w   PrintString
                move.w  #$1000,d1
                lea.l   (D_04766).l,a0
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
                bne.w   L_0052A
                st.b    (ShipSpawned).l
                move.w  #$2,(ShipSpeed).l
                move.w  #$76,(ShipY).l
                clr.b   (StageFlags).l
                bsr.w   ResetShipWeapons
                tst.b   (NewLifeFlag).l
                bne.b   ShipRespawn
L_004C8:
                st.b    (NewLifeFlag).l
                move.b  #$3,(JingleState).l
                moveq   #10,d0
                moveq   #104,d1
                moveq   #-1,d2
                bsr.w   ObjAlloc
                move.l  #D_04252,$12(a0)
                move.l  #ObjUpd_FlyInShip,$6(a0)
                move.l  #D_0427A,$2A(a0)
                move.w  #$2D,$32(a0)
                bsr.w   ObjInsert
                move.b  #$1,(ShipMode).l
                st.b    (ShipAlive).l
                move.w  #$75,(ShipX).l
                move.b  #$10,(D_050F0).l
                move.l  #$6400,(D_05100).l
L_0052A:
                rts
ShipRespawn:
                clr.b   (ShipAlive).l
                clr.b   (ShipMode).l
                move.w  #$C8,(ShipX).l
                move.b  #$8,(D_050F0).l
                move.l  #$6200,(D_05100).l
                tst.b   (CheatMode).l
                bne.b   .00564
                subq.w  #$1,(Lives).l
                bra.w   DrawLives
.00564:
                moveq   #1,d0
                bra.w   AddScoreAlways
ResetShipWeapons:
                bsr.w   InitBits
                bsr.w   ResetMissiles
                clr.b   (D_04B5A).l
                clr.b   (ForceLevel).l
                clr.b   (ForceActive).l
                clr.w   (ForcePos).l
                move.l  #Force_Idle,(ForceState).l
                rts
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
                move.l  (LV_ScrollScript).l,(D_048D6).l
                clr.l   (D_048CE).l
                clr.w   (D_048D2).l
                clr.w   (D_048D4).l
                move.l  #St_LevelFadeIn,(GameState).l
                move.b  #$E,(D_0420A).l
                clr.b   (D_0420B).l
                movea.l (LV_Init).l,a0
                jsr     (a0)
                clr.b   (ShipHit).l
                clr.b   (D_04B5F).l
                clr.b   (SpaceKey).l
                clr.b   (D_0514C).l
                clr.b   (FireHeld).l
                clr.b   (BeamCharge).l
                st.b    (ScrollActive).l
                clr.w   (D_04918).l
                move.b  #$1,(MusicRequest).l
                rts
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
LevelFadeInStep:
                subq.b  #$1,(D_0420B).l
                bpl.b   .006ac
                move.b  #$2,(D_0420B).l
                movea.l (LV_Palette).l,a0
                bsr.w   PaletteFadeIn
                subq.b  #$1,(D_0420A).l
                bpl.b   .006ac
                st.b    (ShipAlive).l
                bset.b  #$6,(StageFlags).l
                lea.l   St_Playing(pc),a0
                tst.b   (ShipMode).l
                beq.b   .006a6
                lea.l   St_PlayStart(pc),a0
                bset.b  #$0,(StageFlags).l
                clr.b   (D_0420B).l
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
                moveq   #7,d0
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
                move.b  #$1E,(D_04209).l
                move.b  #$F,(D_0420A).l
                move.w  #$14,(ShipX).l
                move.w  (ScrollX).l,(Checkpoint).l
                rts
DeathWait:
                tst.b   (D_04209).l
                beq.b   .00770
                subq.b  #$1,(D_04209).l
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
                subq.b  #$1,(D_0420B).l
                bpl.b   .0076e
                move.b  #$2,(D_0420B).l
                bsr.w   PaletteFadeOut
                subq.b  #$1,(D_0420A).l
                bne.b   .0076e
                addq.l  #$4,a7
                bsr.w   PaletteBlack
                move.l  (VblCount).l,d0
                add.l   #$64,d0
.0079e:
                cmp.l   (VblCount).l,d0
                bhi.b   .0079e
                bra.w   StartLevel
StageEndSequence:
                tst.b   (D_0420D).l
                bne.b   .007d0
                bsr.w   ClearBeamMeter
                clr.b   (ShipAlive).l
                move.b  #$24,(D_0420A).l
                clr.b   (D_0420B).l
                st.b    (D_0420D).l
.007d0:
                subq.b  #$1,(D_0420B).l
                bpl.b   .00830
                move.b  #$2,(D_0420B).l
                subq.b  #$1,(D_0420A).l
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
                cmpi.b  #$F,(D_0420A).l
                bhi.b   .00830
                bra.w   PaletteFadeOut
.00830:
                rts

;==============================================================================
; Map access
;==============================================================================
; GetMapCell: d0,d1 = screen x,y -> a4 = map cell, Z clear if solid (bit 7)
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
                clr.w   (D_0539E).l
                lea.l   (D_056C8).l,a1
                bsr.w   SetPalette
                moveq   #0,d1
                lea.l   (D_04772).l,a0
                lea.l   ($2FA6D).l,a1
                bsr.w   PrintString
                lea.l   (D_04782).l,a0
                lea.l   ($3640D).l,a1
                bsr.w   PrintString
                lea.l   (D_04793).l,a0
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
                lea.l   (D_04702).l,a3
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
                move.w  (D_05106).l,d0
                add.w   #$32,d0
.00926:
                btst.b  #$7,(CIAA_PRA).l
                beq.b   .00944
                cmp.w   (D_05106).l,d0
                bhi.b   .00926
                dbra    d7,.008d8
.0093c:
                addq.l  #$4,a7
                moveq   #0,d7
                bra.w   NewGame
.00944:
                clr.l   (Score).l
                clr.l   (Bonus).l
                addq.b  #$1,(D_04221).l
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
CountBonus:
                lea.l   (D_0473E).l,a2
                move.l  #$20202020,(a2)
                move.l  #$20202020,$4(a2)
                move.l  (Bonus).l,d0
                lea.l   (D_04720).l,a1
.00a2c:
                cmp.l   (a1)+,d0
                bcc.b   .00a34
                addq.l  #$2,a1
                bra.b   .00a2c
.00a34:
                lea.l   ($31AF5).l,a5
                move.w  (a1),d7
                move.w  d7,d6
                move.b  #$12,(D_04210).l
.00a46:
                move.w  d7,d5
                lea.l   (D_04746).l,a2
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
                lea.l   (D_0473E).l,a0
                movea.l a5,a1
                bsr.w   PrintString
                st.b    (FrameReady).l
.00a8c:
                tst.b   (FrameReady).l
                bne.b   .00a8c
                subq.b  #$1,(D_04210).l
                bpl.b   .00a46
                move.b  #$12,(D_04210).l
                subq.w  #$1,d6
                cmp.w   #$FFFE,d6
                bne.b   .00a46
                clr.l   (Bonus).l
                rts

; AddScore: d0 = BCD points (ignored in cheat mode)
AddScore:
                tst.b   (CheatMode).l
                bne.b   L_00AF2
AddScoreAlways:
                move.l  d0,(ScoreToAdd).l
                lea.l   (Bonus).l,a1
                lea.l   (ScoreToAddEnd).l,a2
                andi.w  #$FFEF,sr
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                lea.l   (ExtraLifePtr).l,a1
                lea.l   (ScoreToAddEnd).l,a2
                andi.w  #$FFEF,sr
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
                abcd.b  -(a2),-(a1)
L_00AF2:
                rts

; UpdateScore: redraw score, award extra lives
UpdateScore:
                move.l  (Score).l,d0
                cmp.l   (ScoreShown).l,d0
                beq.b   L_00B38
L_00B02:
                move.l  d0,(ScoreShown).l
                lea.l   ($2C8F9).l,a0
                bsr.b   DrawDigits
                movea.l (ExtraLifePtr).l,a0
                move.l  (a0)+,d1
                beq.b   L_00B38
                cmp.l   d1,d0
                bcs.b   L_00B38
                move.l  a0,(ExtraLifePtr).l
                cmpi.w  #$4,(Lives).l
                bge.b   L_00B38
                addq.w  #$1,(Lives).l
                bra.w   DrawLives
L_00B38:
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
                lea.l   (D_0470E).l,a1
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
                lea.l   (D_04B76).l,a0
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
InitMapOffsets:
                lea.l   (D_04D1A).l,a0
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
                lea.l   (D_04E6E).l,a0
                lea.l   (StackTop).l,a1
                bsr.b   .00d6c
                neg.l   d0
                lea.l   (D_04688).l,a1
.00d6c:
                move.w  (a1)+,d1
                bmi.b   .00d76
                move.l  d0,(a0,d1.w)
                bra.b   .00d6c
.00d76:
                rts

; TimerCheck: CIA timer measurement; hangs if the result is out of range
TimerCheck:
                lea.l   (CIAA_PRA).l,a5
                move.w  #$4000,$9A(a6)
                move.b  #$8,$F00(a5)
                moveq   #0,d0
                move.b  d0,$A00(a5)
                move.b  d0,$900(a5)
                move.b  d0,$800(a5)
                move.b  #$FF,$600(a5)
                move.b  #$FF,$700(a5)
                bsr.w   WaitTimer
                move.b  #$19,$F00(a5)
                bsr.w   WaitTimer
                move.b  #$8,$F00(a5)
                moveq   #0,d0
                move.b  $700(a5),d0
                lsl.w   #$8,d0
                move.b  $600(a5),d0
                move.w  #$C000,$9A(a6)
.00dca:
                cmp.w   #$CCDD,d0
                bhi.b   .00dca
                rts
WaitTimer:
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
                clr.w   (D_05136).l
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
UpdateScroll:
                tst.b   (ScrollActive).l
                beq.w   .00f04
                lea.l   (D_048D1).l,a0
                bsr.b   ScrollStep
                add.w   d0,(ScrollY).l
                subq.l  #$3,a0
                bsr.b   ScrollStep
                add.w   d0,(ScrollX).l
                subq.w  #$1,(D_048D4).l
                bpl.b   .00f04
                lea.l   (D_048E9).l,a2
                movea.l (D_048D6).l,a1
                move.w  (a1),d0
                bsr.b   SetScrollSpeed
                addq.l  #$3,a0
                move.w  $2(a1),d0
                bsr.b   SetScrollSpeed
                move.w  $4(a1),(D_048D4).l
                tst.w   $A(a1)
                bmi.b   .00f04
                addq.l  #$6,(D_048D6).l
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
                tst.b   (D_048CE).l
                bne.b   .00f48
                move.b  (D_048D0).l,d3
                ext.w   d3
                sub.w   d3,d0
.00f48:
                tst.b   (D_048D1).l
                bne.b   .00f5a
                move.b  (D_048D3).l,d3
                ext.w   d3
                sub.w   d3,d1
.00f5a:
                move.w  (a7)+,d3
.00f5c:
                rts

;==============================================================================
; Background: blit the visible 20x13 tiles
;==============================================================================
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
SpawnWaves:
                movea.l (WavePtr).l,a1
                move.w  (ScrollX).l,d0
                cmpi.b  #$2,(Level).l
                bne.b   .0105c
                addq.w  #$1,(D_04918).l
                move.w  (D_04918).l,d0
.0105c:
                cmp.w   (a1),d0
                bcs.b   .0107e
                move.l  $E(a1),d1
                bpl.b   .0106c
                move.l  #D_051FC,d1
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
                move.l  (ActiveObjects).l,d7
                move.l  #ActiveObjects,(PrevObject).l
L_010F6:
                tst.l   d7
                beq.w   L_0111C
                movea.l d7,a0
                move.l  $6(a0),d0
                beq.b   .01108
                movea.l d0,a3
                jsr     (a3)
.01108:
                bsr.b   ObjExplode
                bsr.w   ObjCollisions
                bsr.w   ObjAutoFire
NextObject:
                move.l  (a0),d7
                move.l  a0,(PrevObject).l
                bne.b   L_010F6
L_0111C:
                rts
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
                lea.l   (D_0491A).l,a3
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
                move.l  #$19D90,$A(a1)
                movem.w d0-d1,(a1)
                movem.w (ShipPos).l,d2-d3
                bsr.w   DirectionTo
                lsl.w   #$2,d0
                lea.l   (D_04B1A).l,a2
                move.w  (a2,d0.w),$4(a1)
                move.w  $2(a2,d0.w),$6(a1)
                rts
.01348:
                adda.l  #$E,a1
                dbra    d7,.01312
                rts
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
                add.w   (D_050FC).l,d1
                moveq   #20,d5
                move.w  (D_050FE).l,d6
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
                add.w   (D_05152).l,d0
                add.w   (D_05154).l,d1
                movem.w (D_05156).l,d5-d6
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
                lea.l   (D_04A1C).l,a2
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
                lea.l   (D_04A30).l,a1
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
                tst.b   (ShipAlive).l
                beq.b   .01500
                tst.b   $5(a0)
                bne.b   .01500
                tst.b   $28(a0)
                beq.b   .01502
                subq.b  #$1,$28(a0)
                btst.b  #$0,$28(a0)
                beq.b   .01500
                bset.b  #$0,$23(a0)
                moveq   #6,d0
                bra.w   PlaySound
.01500:
                rts
.01502:
                move.w  $A(a0),d3
                cmp.w   #$15E,d3
                bcc.b   .01500
                add.w   $16(a0),d3
                move.w  $C(a0),d4
                add.w   $18(a0),d4
                movem.w $1A(a0),a3-a4
                bsr.w   HitByForceOrShip
                btst.b  #$2,$23(a0)
                bne.b   .01500
                bsr.w   HitByMissiles
                bsr.w   HitByBits
                bsr.w   HitByLasers
                bsr.w   HitByShots
                rts
HitByShots:
                moveq   #13,d7
                lea.l   (D_04B90).l,a1
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
                cmp.w   #$D,d7
                bne.b   .01592
                move.w  $38(a1),d0
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
                cmp.w   #$C,d7
                bne.b   .015b0
                move.w  $24(a0),d0
                sub.w   $26(a0),d0
                cmp.w   #$5,d0
                bls.b   .015a8
                clr.w   (a1)
.015a8:
                moveq   #5,d0
                bsr.w   ObjDamage
                bra.b   .015d6
.015b0:
                cmp.w   #$A,d7
                bcs.b   .015ce
                move.w  $24(a0),d0
                sub.w   $26(a0),d0
                cmp.w   #$2,d0
                bls.b   .015c6
                clr.w   (a1)
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
HitByBits:
                move.b  (D_050F1).l,d7
                btst    #$0,d7
                beq.b   .015f4
                movem.w (D_0512E).l,d0-d1
                bsr.b   .01606
.015f4:
                btst    #$1,d7
                beq.b   .01604
                movem.w (D_05132).l,d0-d1
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
                sub.w   d3,d0
                bpl.b   .0163c
                neg.w   d0
                bra.b   .0163e
.0163c:
                move.w  a3,d5
.0163e:
                cmp.w   d5,d0
                bhi.b   .01654
                sub.w   d4,d1
                bpl.b   .0164a
                neg.w   d1
                bra.b   .0164c
.0164a:
                move.w  a4,d6
.0164c:
                cmp.w   d6,d1
                bhi.b   .01654
                moveq   #1,d0
                rts
.01654:
                moveq   #0,d0
                rts

; ObjDamage: d0 = damage
ObjDamage:
                move.w  $26(a0),d1
                add.w   d0,d1
                move.w  d1,$26(a0)
                tst.w   $24(a0)
                bmi.b   .016aa
                btst.b  #$1,$23(a0)
                beq.b   .01674
                bsr.w   ReleasePowerUp
.01674:
                cmp.w   $24(a0),d1
                bcs.b   .01698
                clr.b   $23(a0)
                move.b  #$1,$5(a0)
                clr.l   $6(a0)
                addq.l  #$8,a7
                movea.l $12(a0),a1
                move.l  $24(a1),d0
                beq.b   .016aa
                bra.w   AddScore
.01698:
                bset.b  #$0,$23(a0)
                move.b  #$3,$28(a0)
                moveq   #6,d0
                bra.w   PlaySound
.016aa:
                rts
HitByForceOrShip:
                movem.w (ForcePos).l,d0-d1
                sub.w   #$5F,d0
                sub.w   #$C,d1
                add.w   (D_05152).l,d0
                add.w   (D_05154).l,d1
                movem.w (D_05156).l,d5-d6
                bsr.w   BoxTest
                beq.b   .016dc
                moveq   #1,d0
                bsr.w   ObjDamage
.016dc:
                movem.w (ShipPos).l,d0-d1
                addq.w  #$5,d0
                add.w   (D_050FC).l,d1
                moveq   #16,d5
                move.w  (D_050FE).l,d6
                bsr.w   BoxTest
                beq.w   .0177e
                btst.b  #$3,$23(a0)
                beq.w   .0179c
                move.l  #$400,d0
                bsr.w   AddScore
                moveq   #8,d0
                bsr.w   PlaySound
                move.w  #$10,$A(a0)
                move.w  $1E(a0),d0
                cmp.w   #$3,d0
                beq.b   CollectSpeedUp
                cmp.w   #$4,d0
                bne.b   .01734
                st.b    (D_055A4).l
                rts
.01734:
                cmp.w   #$5,d0
                bne.b   .01758
                btst.b  #$0,(D_050F1).l
                bne.b   .0174e
                bset.b  #$0,(D_050F1).l
                rts
.0174e:
                bset.b  #$1,(D_050F1).l
                rts
.01758:
                move.b  d0,(D_04B5A).l
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
CollectSpeedUp:
                move.l  a0,-(a7)
                moveq   #5,d0
                moveq   #5,d1
                moveq   #-1,d2
                bsr.w   ObjAlloc
                move.l  #D_04252,$12(a0)
                move.l  #ObjUpd_SpeedFlash,$6(a0)
                move.l  #D_0427A,$2A(a0)
                move.w  #$6,$32(a0)
                bsr.w   ObjInsert
                movem.l (a7)+,a0
                cmpi.w  #$5,(ShipSpeed).l
                bcc.b   .017e6
                addq.w  #$1,(ShipSpeed).l
.017e6:
                rts
HitByLasers:
                move.b  (D_04B61).l,d2
                lea.l   (D_04DBA).l,a1
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
                subq.b  #$1,(D_04B5F).l
                moveq   #1,d0
                bsr.w   ObjDamage
.01826:
                addq.l  #$2,a1
                dbra    d7,.017f6
                rts
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
                lea.l   (D_04B7C).l,a0
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
                moveq   #0,d0
                bra.w   PlaySound
.018d2:
                subq.l  #$2,a0
                dbra    d7,.018a4
.018d8:
                rts
.018da:
                move.b  (BeamCharge).l,d0
                btst.b  #$7,(CIAA_PRA).l
                beq.b   L_01914
                cmp.b   #$6,d0
                bls.b   .018f2
                bsr.b   FireWaveCannon
.018f2:
                clr.b   (FireHeld).l
                clr.b   (BeamCharge).l
ClearBeamMeter:
                clr.l   (D_04B72).l
                clr.w   (D_04B70).l
                moveq   #0,d0
                moveq   #0,d1
                moveq   #0,d2
                bra.w   DrawBeamMeter
L_01914:
                move.w  d0,d1
                cmp.b   #$18,d1
                bcc.b   .01938
                addq.b  #$1,(BeamCharge).l
                cmpi.b  #$6,(BeamCharge).l
                bne.b   .01932
                moveq   #9,d0
                bsr.w   PlaySound
.01932:
                move.w  d1,d0
                bra.w   ChargeBeam
.01938:
                moveq   #13,d0
                bsr.w   PlaySound
                bra.b   .01932
FireWaveCannon:
                lea.l   (D_04B90).l,a0
                lea.l   (D_04CA2).l,a1
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
                move.w  (a1)+,(D_04B62).l
                move.w  (a1)+,(D_04B64).l
                move.w  (a1)+,(D_04B66).l
                move.w  (a1)+,$38(a0)
                move.l  (a1)+,(D_04B68).l
                move.l  (a1)+,(D_04B6C).l
                moveq   #1,d0
                bra.w   PlaySound
.019a0:
                adda.l  #$1C,a1
                dbra    d7,.01952
                rts
UpdateShots:
                move.w  #$30,$60(a6)
                move.w  #$30,$66(a6)
                moveq   #9,d7
                lea.l   (D_04B88).l,a0
                lea.l   (D_04C3A).l,a3
.019c6:
                move.w  (a0),d5
                beq.b   .01a20
                move.w  $1C(a0),d6
                move.w  d5,d0
                move.w  d6,d1
                bsr.w   GetMapCell
                beq.b   .019e6
                bset.b  #$5,(a4)
                btst.b  #$4,(a4)
                beq.b   .01a18
                clr.w   (a4)
                bra.b   .01a18
.019e6:
                move.w  d5,d0
                move.w  d6,d3
                move.w  $38(a0),d2
                lsl.w   #$4,d2
                move.w  $6(a3,d2.w),d1
                movea.l $8(a3,d2.w),a1
                movea.l $C(a3,d2.w),a2
                bsr.b   BlitBob
                add.w   (a3,d2.w),d5
                add.w   $2(a3,d2.w),d6
                cmp.w   #$170,d5
                bcc.b   .01a18
                cmp.w   #$10,d6
                bcs.b   .01a18
                cmp.w   #$F0,d6
                bcs.b   .01a1a
.01a18:
                clr.w   d5
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
                move.w  (D_04B90).l,d6
                beq.w   .01b14
                move.w  (D_04BAC).l,d7
                movea.l (D_04B68).l,a1
                move.l  (D_04B6C).l,d0
                eori.b  #$FF,(D_04B60).l
                beq.b   .01a96
                adda.l  d0,a1
                adda.l  d0,a1
.01a96:
                movea.l a1,a2
                adda.l  d0,a2
                move.w  (D_04B64).l,$60(a6)
                move.w  (D_04B64).l,$66(a6)
                move.w  (D_04B66).l,d1
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
                move.w  (D_04B62).l,d0
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
                move.w  d6,(D_04B90).l
.01b14:
                move.w  #$2E,$60(a6)
                move.w  #$2E,$66(a6)
                lea.l   ($15650).l,a1
                lea.l   (D_04B8A).l,a0
                bsr.b   UpdateForceShot
                lea.l   ($15850).l,a1
                addq.w  #$2,a0
                bsr.b   UpdateForceShot
                bra.w   UpdateReflectBeam
UpdateForceShot:
                move.w  (a0),d6
                beq.b   .01ba4
                move.w  $1C(a0),d3
                move.w  d6,d0
                move.w  d3,d1
                moveq   #9,d5
                moveq   #20,d4
                tst.b   (D_04B5C).l
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
UpdateReflectBeam:
                move.w  (D_04B8E).l,d6
                beq.w   UpdateLasers
                move.w  (D_04BAA).l,d1
                move.w  #$2A,$60(a6)
                move.w  #$2A,$66(a6)
                moveq   #10,d5
                moveq   #46,d7
                moveq   #4,d2
                tst.b   (D_04B5C).l
                bpl.b   .01bd6
                neg.w   d2
                moveq   #14,d7
                neg.w   d5
.01bd6:
                move.w  d6,d0
                move.w  d1,d3
                move.w  (D_04BC6).l,d4
                add.w   d2,d4
                bmi.b   .01bee
                cmp.w   #$14,d4
                bls.b   .01bf0
                moveq   #0,d4
                bra.b   .01bf0
.01bee:
                moveq   #20,d4
.01bf0:
                move.w  d4,(D_04BC6).l
                lea.l   (D_04C8A).l,a0
                movea.l (a0,d4.w),a1
                movea.l a1,a2
                adda.l  #$3C0,a2
                move.w  d1,-(a7)
                move.w  #$1E05,d1
                bsr.w   BlitBob
                move.w  (a7)+,d1
                add.w   #$E,d1
                move.w  d6,d0
                add.w   d7,d0
                bsr.w   GetMapCell
                beq.b   .01c2e
                bset.b  #$5,(a4)
                btst.b  #$4,(a4)
                beq.b   .01c38
                clr.w   (a4)
.01c2e:
                add.w   d5,d6
                bmi.b   .01c38
                cmp.w   #$170,d6
                bcs.b   .01c3a
.01c38:
                clr.w   d6
.01c3a:
                move.w  d6,(D_04B8E).l
UpdateLasers:
                tst.b   (D_04B5F).l
                beq.w   .01d1c
                move.w  #$30,$60(a6)
                move.w  #$30,$66(a6)
                lea.l   (D_04DBA).l,a0
                moveq   #7,d7
                moveq   #0,d6
                tst.b   (D_04B61).l
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
                lea.l   (D_04D1A).l,a3
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
                moveq   #2,d0
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
                subq.b  #$1,(D_04B5F).l
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
                lea.l   (D_04E5E).l,a1
                lsl.w   #$2,d5
                movea.l (a1,d5.w),a1
                movea.l a1,a2
                adda.l  #$70,a2
                move.w  #$E02,d1
                bsr.w   BlitBob
                mulu.w  #$28,d6
                lea.l   (D_04E6E).l,a3
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
                subq.b  #$1,(D_04B5F).l
                bra.b   .01da0
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
                subq.b  #$1,(D_04B5F).l
L_01DDE:
                rts
FireForce:
                tst.b   (ForceActive).l
                beq.b   L_01DDE
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
                lea.l   (D_04B84).l,a0
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
                lea.l   (D_04B80).l,a0
                moveq   #1,d3
                moveq   #1,d7
                bsr.w   .0202e
                moveq   #2,d3
                moveq   #1,d7
                lea.l   (D_04B84).l,a0
                bsr.w   .0202e
                cmp.b   #$3,d6
                bne.b   .01e70
                moveq   #3,d3
                moveq   #0,d7
                moveq   #0,d2
                moveq   #4,d4
                moveq   #11,d5
                lea.l   (D_04B88).l,a0
                bsr.w   .0202e
                moveq   #0,d7
                moveq   #4,d3
                lea.l   (D_04B86).l,a0
                bra.w   .0202e
.01e70:
                rts
.01e72:
                tst.b   d6
                beq.b   .01e70
                move.b  d7,(D_04B5C).l
                move.b  (D_04B5A).l,d5
                bne.w   .01f0a
                tst.b   (D_04B5F).l
                bne.w   .01f08
                cmp.b   #$3,d6
                bne.b   .01ea2
                moveq   #3,d6
                move.b  #$8,(D_04B5F).l
                bra.b   .01eac
.01ea2:
                moveq   #1,d6
                move.b  #$4,(D_04B5F).l
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
                lea.l   (D_04DBA).l,a0
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
                clr.b   (D_04B61).l
.01f08:
                rts
.01f0a:
                cmp.b   #$1,d5
                beq.w   .01f88
                tst.b   (D_04B5F).l
                bne.b   .01f08
                move.b  #$8,(D_04B5F).l
                moveq   #3,d6
                lea.l   (D_04DBA).l,a0
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
                st.b    (D_04B61).l
                moveq   #4,d0
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
                moveq   #3,d0
                bsr.w   PlaySound
                move.w  (a7)+,d0
                cmp.b   #$2,d6
                bhi.b   .01fce
                add.w   d2,d0
                lea.l   (D_04B8A).l,a0
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
                btst.b  #$0,(D_050F1).l
                beq.b   .01ff4
                lea.l   (D_04B8A).l,a0
                movem.w (D_0512E).l,d0-d1
                addq.w  #$2,d1
                move.w  d4,-(a7)
                add.w   d4,d0
                bsr.b   .01fbe
                move.w  (a7)+,d4
.01ff4:
                btst.b  #$1,(D_050F1).l
                beq.b   .0200e
                addq.l  #$2,a0
                movem.w (D_05132).l,d0-d1
                addq.w  #$2,d1
                add.w   d4,d0
                bsr.b   .01fbe
.0200e:
                movem.w (a7)+,d0-d1/d3/d5
                lea.l   (D_04B8E).l,a0
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
ChargeBeam:
                move.l  (D_04B72).l,d5
                lsr.l   #$4,d5
                or.l    #$F0000000,d5
                move.l  d5,(D_04B72).l
                cmp.b   #$FF,d5
                bne.b   .02096
                moveq   #0,d5
                move.l  d5,(D_04B72).l
                addq.w  #$1,(D_04B70).l
                cmpi.w  #$3,(D_04B70).l
                blt.b   .02096
                subq.w  #$1,(D_04B70).l
                moveq   #-1,d5
                move.l  d5,(D_04B72).l
.02096:
                move.w  (D_04B70).l,d7
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
                lea.l   ($2C7E8).l,a0
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
                move.w  (CUSTOM+INTREQR).l,d0
                btst    #$4,d0
                bne.w   CopperInt
                btst    #$5,d0
                bne.b   .02118
                bra.w   .0218a
.02118:
                addq.l  #$1,(VblCount).l
                tst.b   (TitleMusicOn).l
                beq.b   .0212c
                jsr     (MUSIC_PLAY).l
.0212c:
                tst.b   (JinglePlaying).l
                beq.b   .02138
                bsr.w   UpdateJingle
.02138:
                tst.b   (MusicFadeReq).l
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
                bsr.w   UpdateMusic
                bsr.w   UpdateSound
                tst.b   (Paused).l
                bne.b   .0218a
                subq.w  #$1,(D_05138).l
                bmi.b   .0218a
                bsr.w   ShipControl
                bsr.w   UpdateBits
.0218a:
                move.w  #$60,(CUSTOM+INTREQ).l
                movem.l (a7)+,d0-d7/a0-a6
                rte
L_02198:
                rts

;==============================================================================
; Ship movement
;==============================================================================
ShipControl:
                tst.b   (ShipHit).l
                bne.b   L_02198
                tst.b   (ShipMode).l
                bmi.w   ShipAutoPilot
                bne.w   ShipFlyIn
                move.w  (CUSTOM+JOY0DAT).l,d0
                move.w  (ShipSpeed).l,d2
                move.w  d0,d1
                asl.w   #$1,d1
                eor.w   d0,d1
                btst    #$9,d0
                beq.b   .021da
                cmpi.w  #$96,(ShipX).l
                bls.b   .021f0
                sub.w   d2,(ShipX).l
                bra.b   .021f0
.021da:
                btst    #$1,d0
                beq.b   .021f0
                cmpi.w  #$1A0,(ShipX).l
                bhi.b   .021f0
                add.w   d2,(ShipX).l
.021f0:
                btst    #$9,d1
                beq.b   .02212
                cmpi.w  #$30,(ShipY).l
                bls.w   L_02234
                sub.w   d2,(ShipY).l
                move.b  #$FF,(D_050EF).l
                bra.b   ShipTilt
.02212:
                btst    #$1,d1
                beq.b   L_02234
                cmpi.w  #$DC,(ShipY).l
                bcc.w   L_02234
                add.w   d2,(ShipY).l
                move.b  #$1,(D_050EF).l
                bra.b   ShipTilt
L_02234:
                cmpi.b  #$8,(D_050F0).l
                bhi.b   .0224a
                beq.b   .02254
                move.b  #$1,(D_050EF).l
                bra.b   ShipTilt
.0224a:
                move.b  #$FF,(D_050EF).l
                bra.b   ShipTilt
.02254:
                clr.b   (D_050EF).l
ShipTilt:
                moveq   #0,d0
                move.b  (D_050F0).l,d0
                add.b   (D_050EF).l,d0
                bpl.b   .0226e
                moveq   #0,d0
                bra.b   .02276
.0226e:
                cmp.b   #$10,d0
                bls.b   .02276
                moveq   #16,d0
.02276:
                move.b  d0,(D_050F0).l
                lsr.b   #$2,d0
                lea.l   (D_05108).l,a0
                move.b  (a0,d0.w),d1
                ext.w   d1
                move.w  d1,(D_050FC).l
                move.b  $5(a0,d0.w),d1
                ext.w   d1
                move.w  d1,(D_050FE).l
                lsl.w   #$8,d0
                add.l   #$6000,d0
                move.l  d0,(D_05100).l
L_022AA:
                rts
ShipFlyIn:
                move.b  (StageFlags).l,d7
                btst    #$0,d7
                beq.b   L_022AA
                btst    #$2,d7
                bne.b   .022ee
                move.b  #$FF,(D_050EF).l
                lea.l   ShipTilt(pc),a0
                bsr.b   .02334
                addq.w  #$2,(ShipX).l
                cmpi.w  #$186,(ShipX).l
                bcs.b   L_022AA
                bset.b  #$2,(StageFlags).l
                move.b  #$F,(D_0420B).l
                rts
.022ee:
                btst    #$3,d7
                beq.b   .0231a
                lea.l   L_02234(pc),a0
                bsr.b   .02334
                subq.w  #$2,(ShipX).l
                cmpi.w  #$C8,(ShipX).l
                bhi.b   L_022AA
                bset.b  #$1,(StageFlags).l
                clr.b   (ShipMode).l
                rts
.0231a:
                subq.b  #$1,(D_0420B).l
                bpl.b   L_022AA
                bset.b  #$3,(StageFlags).l
                move.b  #$A,(D_0420B).l
                rts
.02334:
                subq.b  #$1,(D_0420B).l
                bpl.b   .02346
                move.b  #$4,(D_0420B).l
                jmp     (a0)
.02346:
                rts
ShipAutoPilot:
                move.b  (EndSequenceFlags).l,d0
                btst    #$0,d0
                beq.b   .023ac
                btst    #$2,d0
                beq.b   .0236a
                move.w  #$1C2,(D_050F2).l
                move.w  #$A,(D_050F4).l
.0236a:
                btst    #$7,d0
                bne.b   .023bc
                move.w  d0,-(a7)
                bsr.w   ResetShipWeapons
                move.w  (a7)+,d0
                clr.b   (ShipAlive).l
                move.w  #$82,(D_050F4).l
                move.w  #$C8,(D_050F2).l
                btst    #$1,d0
                beq.b   .023bc
                move.b  #$FF,(D_056FD).l
                st.b    (JinglePlaying).l
                bset.b  #$7,(EndSequenceFlags).l
                bra.b   .023bc
.023ac:
                move.w  #$10E,(D_050F2).l
                move.w  #$96,(D_050F4).l
.023bc:
                moveq   #0,d4
                movem.w (ShipX).l,d0-d1
                moveq   #-1,d2
                sub.w   (D_050F2).l,d0
                beq.b   .023de
                bpl.b   .023d6
                neg.w   d2
                neg.w   d0
.023d6:
                add.w   d2,(ShipX).l
                addq.w  #$1,d4
.023de:
                move.b  #$FF,(D_050EF).l
                moveq   #-1,d3
                sub.w   (D_050F4).l,d1
                beq.w   .02408
                bpl.b   .023fe
                neg.w   d3
                neg.w   d1
                neg.b   (D_050EF).l
.023fe:
                add.w   d3,(ShipY).l
                bra.w   ShipTilt
.02408:
                tst.b   d4
                bne.w   L_02234
                bset.b  #$7,(StageFlags).l
                bra.w   L_02234

;==============================================================================
; Bits (the two satellites)
;==============================================================================
InitBits:
                lea.l   ($6500).w,a0
                move.l  a0,(D_05118).l
                move.l  a0,(D_05122).l
                clr.b   (D_050F1).l
                clr.w   (D_05126).l
                clr.w   (D_0512A).l
                move.w  #$1E,(D_05128).l
                move.w  #$10E,(D_0512C).l
                clr.w   (D_05112).l
                clr.w   (D_0511C).l
                move.w  #$1,(D_05114).l
                move.w  #$1,(D_0511E).l
                lea.l   ($49342).l,a0
                moveq   #2,d0
.02470:
                move.w  #$1E,$6(a0)
                move.w  #$10E,$12(a0)
                clr.w   $C(a0)
                clr.w   (a0)+
                dbra    d0,.02470
                rts
UpdateBits:
                move.b  (D_050F1).l,d7
                lsr.b   #$1,d7
L_02490:
                bcc.b   .024ba
                lea.l   ($49342).l,a0
                lea.l   (D_05112).l,a1
                moveq   #-25,d2
                bsr.b   .024e8
                movem.w d2-d3,(D_05126).l
                sub.w   #$5F,d2
                sub.w   #$C,d3
                movem.w d2-d3,(D_0512E).l
.024ba:
                lsr.w   #$1,d7
                bcc.b   .024e6
                lea.l   ($4934E).l,a0
                lea.l   (D_0511C).l,a1
                moveq   #29,d2
                bsr.b   .024e8
                movem.w d2-d3,(D_0512A).l
                sub.w   #$5F,d2
                sub.w   #$C,d3
                movem.w d2-d3,(D_05132).l
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
CopperInt:
                lea.l   (CUSTOM).l,a6
                move.w  #$10,$9C(a6)
                bsr.w   SwapScreens
                bsr.w   UpdateForce
                lea.l   ($490A2).l,a0
                movea.l (D_05118).l,a1
                move.w  #$C,d3
                bsr.w   CopySprite
                lea.l   ($490D6).l,a0
                movea.l (D_05100).l,a1
                move.w  #$E,d3
                bsr.w   CopySprite
                lea.l   ($491F2).l,a0
                bsr.w   CopySprite
                lea.l   ($49112).l,a0
                movea.l (D_05122).l,a1
                move.w  #$C,d3
                bsr.w   CopySprite
                lea.l   ($490A2).l,a0
                movem.w (D_05126).l,d0-d1
                moveq   #12,d2
                move.w  #$A8,d3
                bsr.b   SetSprite
                lea.l   ($490D6).l,a0
                movem.w (ShipX).l,d0-d1
                move.b  (ShipAlive).l,d6
                bne.b   .025fe
                btst.b  #$1,(D_05107).l
                beq.b   .025fe
                moveq   #95,d0
.025fe:
                moveq   #14,d2
                bsr.b   SetSprite
                add.w   #$10,d0
                lea.l   ($491F2).l,a0
                bsr.b   SetSprite
                sub.w   #$6F,d0
                beq.b   .02620
                sub.w   #$C,d1
                movem.w d0-d1,(ShipPos).l
.02620:
                lea.l   ($49112).l,a0
                movem.w (D_0512A).l,d0-d1
                moveq   #12,d2
                bsr.b   SetSprite
                movem.l (a7)+,d0-d7/a0-a6
                rte

; SetSprite: d0,d1 = x,y  d2 = height  a0 = sprite
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
                subq.w  #$1,(D_05136).l
                tst.b   (FrameReady).l
                beq.b   .026d0
                tst.w   (D_05136).l
                bpl.b   .026d0
                bsr.b   SetBitplanes
                tst.b   (D_0513C).l
                beq.b   .026ba
                clr.w   (D_05136).l
                move.w  #$1,(D_05138).l
                bra.b   .026ca
.026ba:
                move.w  #$1,(D_05136).l
                move.w  #$2,(D_05138).l
.026ca:
                clr.b   (FrameReady).l
.026d0:
                rts
SetBitplanes:
                move.w  (ScrollBplcon1).l,(D_0539E).l
                lea.l   ($48BBA).l,a0
                move.w  (FineScrollY).l,d0
                lsl.w   #$2,d0
                move.l  (a0,d0.w),d0
                eori.b  #$FF,(D_0513B).l
                bne.b   .0270a
                add.l   #$2EBC0,d0
                move.l  #SCREEN_B,(DrawBuffer).l
                bra.b   .0271a
.0270a:
                add.l   #$3C8C0,d0
                move.l  #SCREEN_A,(DrawBuffer).l
.0271a:
                lea.l   (D_052F2).l,a0
                moveq   #3,d1
                moveq   #52,d2
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
UpdateForce:
                move.b  (ForceLevel).l,d0
                cmp.b   (D_05144).l,d0
                beq.b   .0275c
                move.b  d0,(D_05144).l
                clr.b   (D_05145).l
                move.l  #$1E0,(D_05160).l
.0275c:
                moveq   #0,d1
                move.b  (D_05144).l,d1
                move.w  d1,d2
                lsl.w   #$2,d2
                lea.l   (D_051CC).l,a0
                move.w  (a0,d2.w),(D_0514E).l
                move.w  $2(a0,d2.w),(D_05150).l
                lsl.w   #$1,d2
                lea.l   (D_051DC).l,a0
                lea.l   (a0,d2.w),a0
                movem.w (a0),d4-d7
                movem.w d4-d7,(D_05152).l
                tst.b   (ForceSide).l
                bmi.b   .027a0
                addq.w  #$4,d2
.027a0:
                lea.l   (D_051AC).l,a0
                move.w  (a0,d2.w),(D_0515A).l
                move.w  $2(a0,d2.w),(D_0515C).l
                lsl.w   #$4,d1
                lea.l   (D_0516C).l,a0
                move.w  $E(a0,d1.w),d5
                move.l  $8(a0,d1.w),d2
                move.l  d2,d4
                lsr.l   #$2,d2
                subq.b  #$1,(D_05145).l
                bpl.b   .02814
                move.b  $D(a0,d1.w),(D_05145).l
                move.l  (D_05160).l,d0
                tst.b   (D_05146).l
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
                move.l  d0,(D_05160).l
                moveq   #3,d1
                lea.l   (D_0533A).l,a0
                bsr.w   SetCopperPtrs
.02814:
                move.l  d2,d3
                movea.l (D_05160).l,a0
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
                add.w   (D_0514E).l,d0
                add.w   (D_05150).l,d1
                tst.b   (ShipAlive).l
                beq.b   .02860
                tst.b   (ForceSide).l
                bne.w   L_029E0
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
                addq.w  #$2,(D_0516A).l
                bra.b   .02914
.0290c:
                addq.w  #$4,d7
                subq.w  #$2,(D_0516A).l
.02914:
                movem.w (a7)+,d0-d1
                clr.b   (D_0514A).l
                bsr.w   GetMapCell
                movea.l a4,a3
                tst.w   d6
                beq.b   .0294a
                bpl.b   .0293a
                addq.l  #$2,a3
                bsr.w   L_029C2
                beq.b   .02970
                add.w   d6,(ForcePos).l
                bra.b   .02970
.0293a:
                subq.l  #$2,a3
                bsr.w   L_029C2
                beq.b   .02970
                add.w   d6,(ForcePos).l
                bra.b   .02970
.0294a:
                addq.l  #$2,a3
                bsr.b   L_029C2
                beq.b   .0295e
                subq.w  #$1,(ForcePos).l
                clr.b   (D_05143).l
                bra.b   .02970
.0295e:
                subq.l  #$4,a3
                bsr.b   L_029C2
                beq.b   .02970
                addq.w  #$1,(ForcePos).l
                clr.b   (D_05143).l
.02970:
                movea.l a4,a3
                tst.w   d7
                beq.b   .0299c
                bpl.b   .0298a
                adda.l  (MapRowBytes).l,a3
                bsr.b   L_029C2
                beq.b   .029c0
                add.w   d7,(D_0516A).l
                bra.b   .029c0
.0298a:
                suba.l  (MapRowBytes).l,a3
                bsr.b   L_029C2
                beq.b   .029c0
                add.w   d7,(D_0516A).l
                bra.b   .029c0
.0299c:
                adda.l  (MapRowBytes).l,a3
                bsr.b   L_029C2
                beq.b   .029ae
                subq.w  #$1,(D_0516A).l
                bra.b   .029c0
.029ae:
                movea.l a4,a3
                suba.l  (MapRowBytes).l,a3
                bsr.b   L_029C2
                beq.b   .029c0
                addq.w  #$1,(D_0516A).l
.029c0:
                rts
L_029C2:
                btst.b  #$7,(a3)
                beq.b   L_029DE
                bset.b  #$5,(a3)
                btst.b  #$4,(a3)
                beq.b   .029d6
                clr.w   (a3)
                rts
.029d6:
                move.b  #$FF,(D_0514A).l
L_029DE:
                rts
L_029E0:
                addq.w  #$3,d0
                bsr.w   GetMapCell
                movea.l a4,a3
                bsr.b   L_029C2
                adda.l  (MapRowBytes).w,a3
                bra.b   L_029C2
Force_Idle:
                tst.b   (ForceActive).l
                beq.b   L_029DE
                clr.b   (ForceLevel).l
                move.l  #$6A40,(D_05160).l
                move.b  #$1,(D_05146).l
                clr.b   (D_05144).l
                clr.b   (D_05145).l
Force_Reset:
                cmpi.b  #$2,(ForceLevel).l
                bne.b   .02a2c
                subq.b  #$1,(ForceLevel).l
.02a2c:
                clr.b   (D_0514A).l
                clr.b   (D_05143).l
                clr.b   (ForceSide).l
                clr.b   (D_0514B).l
                clr.b   (D_05149).l
                move.w  #$76,(ForcePos).l
                move.w  #$8A,(D_0516A).l
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
                move.b  #$1,(D_05143).l
                move.l  #Force_Free,(ForceState).l
.02aa0:
                rts
Force_Free:
                bsr.b   ForceCommon
                move.w  (ShipX).l,d0
                cmp.w   #$10E,d0
                bcs.b   .02ad2
                cmpi.b  #$1,(D_05143).l
                beq.b   .02afa
                clr.b   (D_05143).l
                move.w  #$C0,d0
                bsr.w   .02b58
                move.b  #$1,(D_05143).l
                bra.b   .02aec
.02ad2:
                tst.b   (D_05143).l
                bmi.b   .02afa
                clr.b   (D_05143).l
                move.w  #$152,d0
                bsr.b   .02b58
                st.b    (D_05143).l
.02aec:
                clr.b   (D_0514B).l
                clr.b   (D_05149).l
                rts
.02afa:
                moveq   #1,d2
                move.w  (ShipY).l,d1
                sub.w   (D_0516A).l,d1
                bpl.b   .02b10
                neg.w   d2
                neg.w   d7
                neg.w   d1
.02b10:
                cmp.w   #$4,d1
                bls.b   .02b48
                subq.b  #$1,(D_05149).l
                bpl.b   .02b32
                move.b  #$10,(D_05149).l
                move.b  d2,(D_0514B).l
                move.b  d2,(D_05146).l
.02b32:
                move.b  (D_0514B).l,d0
                ext.w   d0
                move.w  d0,d7
                addq.w  #$1,d7
                neg.w   d7
                add.w   d0,(D_0516A).l
                rts
.02b48:
                clr.b   (D_0514B).l
                move.b  #$10,(D_05149).l
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
                add.w   (D_05152).l,d0
                add.w   (D_05154).l,d1
                movem.w (D_05156).l,d5-d6
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
                moveq   #5,d0
                bra.w   PlaySound
.02c1a:
                rts
Force_Attached:
                move.w  (ShipX).l,d0
                add.w   (D_0515A).l,d0
                move.w  d0,(ForcePos).l
                move.w  (ShipY).l,d0
                add.w   (D_0515C).l,d0
                move.w  d0,(D_0516A).l
                bsr.w   ReadFire2
                beq.b   L_02C7E
                moveq   #8,d0
                tst.b   (ForceSide).l
                bpl.b   .02c52
                neg.w   d0
.02c52:
                move.w  d0,(D_0515E).l
                moveq   #5,d0
                bsr.w   PlaySound
                move.l  #Force_Launched,(ForceState).l
                clr.b   (ForceSide).l
                cmpi.b  #$2,(ForceLevel).l
                bne.b   L_02C7E
                subq.b  #$1,(ForceLevel).l
L_02C7E:
                rts
Force_Launched:
                move.w  (D_0515E).l,d0
                move.w  d0,d7
                neg.w   d7
                tst.b   (D_0514A).l
                bne.b   L_02CBE
                move.w  (ForcePos).l,d1
                add.w   d0,d1
                move.w  d1,(ForcePos).l
Force_Bounds:
                cmp.w   #$86,d1
                bls.b   L_02CAC
                cmp.w   #$1A6,d1
                bcs.b   L_02C7E
L_02CAC:
                clr.b   (D_05143).l
                move.l  #Force_Free,(ForceState).l
                rts
L_02CBE:
                moveq   #0,d7
                bra.b   L_02CAC
ForceFollowY:
                moveq   #1,d1
                moveq   #-2,d7
                move.w  (ShipY).l,d0
                sub.w   (D_0516A).l,d0
                bpl.b   .02cda
                neg.w   d1
                neg.w   d7
                neg.w   d0
.02cda:
                cmp.w   #$2,d0
                bcs.b   .02ce8
                add.w   d1,(D_0516A).l
                rts
.02ce8:
                moveq   #0,d7
                rts

; ReadFire2: joystick button 2 or Space
ReadFire2:
                move.w  #$FF00,$34(a6)
                move.w  $16(a6),d0
                tst.b   (D_0514C).l
                beq.b   .02d14
                btst    #$E,d0
                beq.b   .02d34
                tst.b   (SpaceKey).l
                bne.b   .02d34
                clr.b   (D_0514C).l
                rts
.02d14:
                btst    #$E,d0
                beq.b   .02d22
                tst.b   (SpaceKey).l
                beq.b   .02d34
.02d22:
                tst.b   (ShipAlive).l
                beq.b   .02d32
                move.b  #$1,(D_0514C).l
.02d32:
                rts
.02d34:
                moveq   #0,d0
                rts

;==============================================================================
; Power-up carriers and walkers
;==============================================================================
ReleasePowerUp:
                move.l  a0,-(a7)
                moveq   #0,d3
                move.b  $32(a0),d3
                movem.w $A(a0),d0-d1
                moveq   #-1,d2
                lea.l   (D_05288).l,a2
                bsr.w   ObjCreate
                bset.b  #$3,$23(a0)
                move.b  d3,$1F(a0)
                clr.b   $22(a0)
                bset.b  #$2,$23(a0)
                jsr     (ObjInsert).l
                movea.l (a7)+,a0
                moveq   #8,d0
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
SpawnWalker:
                move.w  $2(a1),d0
                move.w  $4(a1),d1
                moveq   #1,d2
                jsr     (ObjCreate).l
                bset.b  #$1,$23(a0)
                move.b  $7(a1),$32(a0)
                move.l  #D_05233,$2A(a0)
                move.b  $9(a1),$33(a0)
                bpl.b   .02dc4
                move.l  #D_0522E,$2A(a0)
.02dc4:
                move.b  #$2B,$34(a0)
                move.l  #Walker_Walk,$36(a0)
                move.b  #$2,$4(a0)
                jmp     (ObjInsert).l
ObjUpd_Walker:
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
Walker_Walk:
                lea.l   ($1C650).l,a1
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
                move.l  #Walker_Walk,$36(a0)
                lea.l   (D_05233).l,a1
                tst.b   $33(a0)
                bpl.b   .02ed2
                lea.l   (D_0522E).l,a1
.02ed2:
                move.l  a1,$2A(a0)
                move.b  #$10,$34(a0)
                move.w  #$3,$1E(a0)
                clr.b   $20(a0)
                bra.w   Walker_Walk
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
                lea.l   (D_05224).l,a1
                bra.b   .02f5a
.02f54:
                lea.l   (D_05229).l,a1
.02f5a:
                move.l  a1,$2A(a0)
                rts

;==============================================================================
; Homing missiles
;==============================================================================
ResetMissiles:
                clr.b   (D_055A4).l
                clr.b   (D_055AA).l
                clr.w   (D_055A8).l
                clr.l   (D_0556C).l
                clr.l   (D_05588).l
                rts
UpdateMissiles:
                tst.b   (D_055AA).l
                bne.b   .02f96
                tst.w   (D_055A8).l
                beq.b   .02f96
                subq.w  #$1,(D_055A8).l
.02f96:
                lea.l   (D_0556C).l,a0
                bsr.b   .02fa4
                lea.l   (D_05588).l,a0
.02fa4:
                move.l  (a0),d0
                beq.w   .03048
                movea.l d0,a1
                jsr     (a1)
                movem.w $4(a0),d6-d7
                move.w  d6,d0
                move.w  d7,d1
                add.w   #$F,d0
                addq.w  #$8,d1
                bsr.w   GetMapCell
                beq.b   .02ff2
                clr.l   (a0)
                subq.b  #$1,(D_055AA).l
                move.w  d6,d0
                move.w  d7,d1
                addq.w  #$8,d0
                moveq   #-1,d2
                jsr     (jt_ObjAlloc).w
                move.b  #$1,$5(a0)
                move.b  #$1,$21(a0)
                clr.l   $6(a0)
                move.b  #$A,$4(a0)
                jmp     (jt_ObjInsert).w
.02ff2:
                move.w  $C(a0),d0
                eori.w  #$FFFF,$E(a0)
                beq.b   .03002
                add.w   #$10,d0
.03002:
                lsl.w   #$2,d0
                lea.l   (D_0546C).l,a1
                movea.l (a1,d0.w),a1
                movea.l a1,a2
                adda.l  #$80,a2
                move.w  d6,d0
                bmi.b   .0302a
                cmp.w   #$170,d0
                bhi.b   .0302a
                move.w  d7,d3
                bmi.b   .0302a
                cmp.w   #$F2,d3
                bcs.b   .03034
.0302a:
                clr.l   (a0)
                subq.b  #$1,(D_055AA).l
                rts
.03034:
                move.w  #$30,$60(a6)
                move.w  #$30,$66(a6)
                move.w  #$1002,d1
                bra.w   BlitBob
.03048:
                tst.b   (D_055A4).l
                beq.b   L_030B6
                tst.b   (ShipAlive).l
                beq.b   L_030B6
                tst.w   (D_055A8).l
                bne.b   L_030B6
                btst.b  #$7,(CIAA_PRA).l
                bne.b   L_030B6
                movem.w (ShipPos).l,d0-d1
                addq.w  #$5,d0
                movem.w d0-d1,$4(a0)
                move.b  #$9,$18(a0)
                clr.l   $8(a0)
                move.w  #$4,$C(a0)
                move.l  #$E0008,$10(a0)
                move.l  #$C0006,$14(a0)
                move.l  #Missile_Launch,(a0)
                tst.b   $19(a0)
                bmi.b   L_030B6
                move.b  #$2,(D_055AA).l
                move.w  #$38,(D_055A8).l
L_030B6:
                rts
Missile_Launch:
                move.b  $19(a0),d0
                ext.w   d0
                add.w   d0,$6(a0)
                subq.b  #$1,$18(a0)
                bpl.b   L_030B6
                move.l  #Missile_Forward,(a0)
                move.b  #$6,$18(a0)
                rts
Missile_Forward:
                addq.w  #$6,$4(a0)
                subq.b  #$1,$18(a0)
                bpl.b   L_030B6
                move.l  #Missile_Seek,(a0)
                rts
Missile_Seek:
                movem.w $4(a0),d6-d7
                move.w  #$FFFF,(D_055A6).l
                move.l  (ActiveObjects).l,d0
                beq.b   .03150
.030fe:
                movea.l d0,a1
                movem.w $A(a1),d0-d1
                moveq   #0,d4
                sub.w   d6,d0
                bpl.b   .0310e
                neg.w   d0
.0310e:
                sub.w   d7,d1
                bpl.b   .03116
                neg.w   d1
                moveq   #1,d4
.03116:
                add.w   d1,d0
                cmp.w   (D_055A6).l,d0
                bhi.b   .0313c
                cmp.b   $1A(a0),d4
                bne.b   .0313c
                tst.b   $5(a1)
                bne.b   .0313c
                tst.w   $24(a1)
                bmi.b   .0313c
                move.w  d0,(D_055A6).l
                move.l  a1,$8(a0)
.0313c:
                move.l  (a1),d0
                bne.b   .030fe
                move.l  $8(a0),d0
                beq.b   .03150
                clr.b   $18(a0)
                move.l  #Missile_Home,(a0)
.03150:
                addq.w  #$6,$4(a0)
                rts
Missile_Home:
                movea.l $8(a0),a1
                move.w  $A(a1),d2
                beq.b   .031a0
                tst.b   $5(a1)
                bne.b   .031a0
                subq.b  #$1,$18(a0)
                bpl.b   .031a0
                move.b  #$3,$18(a0)
                movem.w $4(a0),d0-d1
                move.w  $C(a1),d3
                bsr.w   DirectionTo
                move.w  $C(a0),d1
                bsr.w   TurnTowards
                move.w  d1,$C(a0)
                lsl.w   #$3,d1
                lea.l   (D_054EC).l,a1
                movem.l (a1,d1.w),d4-d5
                movem.l d4-d5,$10(a0)
.031a0:
                move.w  $C(a0),d0
                lsl.w   #$2,d0
                lea.l   (D_0542C).l,a1
                movem.w (a1,d0.w),d1-d2
                add.w   d1,$4(a0)
                add.w   d2,$6(a0)
                rts
HitByMissiles:
                tst.b   (D_055A4).l
                beq.b   .031d4
                lea.l   (D_0556C).l,a1
                bsr.b   .031d6
                lea.l   (D_05588).l,a1
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
                subq.b  #$1,(D_055AA).l
                moveq   #1,d0
                bra.w   ObjDamage

;==============================================================================
; Attract mode: title, high scores, demo
;==============================================================================
TitleSequence:
                move.l  a7,(TitleStack).l
                clr.b   (CheatMode).l
                clr.b   (D_056FE).l
                tst.w   d7
                bne.b   .03220
                bsr.w   LoadShared
                bsr.w   RestoreMusic
.03220:
                clr.w   (FineScrollX).l
                clr.w   (FineScrollY).l
                clr.w   (D_056F6).l
                move.l  #St_HighScore,(TitleState).l
TitleLoop:
                tst.b   (FrameReady).l
                bne.b   TitleLoop
                btst.b  #$7,(CIAA_PRA).l
                beq.w   AbortTitle
                tst.w   (D_056F6).l
                beq.b   .03262
                subq.w  #$1,(D_056F6).l
                bra.w   TitleNextFrame
.03262:
                movea.l (TitleState).l,a1
                jmp     (a1)
St_TitleFadeOut:
                bsr.w   PaletteFadeOut
                move.w  #$4,(D_056F6).l
                subq.b  #$1,(D_056F3).l
                bpl.w   TitleNextFrame
                bsr.w   ClearPlayfield
                lea.l   (D_056AA).l,a1
                bsr.w   SetPalette
                lea.l   (D_05962).l,a4
                bsr.w   PrintList
                move.w  #$C8,(D_056F6).l
                move.l  #St_ScoresFadeOut,(TitleState).l
                move.b  #$F,(D_056F3).l
                bra.w   TitleNextFrame
St_ScoresFadeOut:
                bsr.w   PaletteFadeOut
                move.w  #$4,(D_056F6).l
                subq.b  #$1,(D_056F3).l
                bpl.w   TitleNextFrame
                bsr.w   ClearPlayfield
                lea.l   (D_056C8).l,a1
                bsr.w   SetPalette
                bsr.w   DrawScoreTable
                move.w  #$FA,(D_056F6).l
                move.b  #$F,(D_056F3).l
                move.l  #St_CreditsFadeOut,(TitleState).l
                bra.w   TitleNextFrame
St_CreditsFadeOut:
                bsr.w   PaletteFadeOut
                move.w  #$4,(D_056F6).l
                subq.b  #$1,(D_056F3).l
                bpl.w   TitleNextFrame
                bsr.w   ClearPlayfield
St_TitleStart:
                bsr.w   InitTitleLetters
                lea.l   (D_056AA).l,a1
                bsr.w   SetPalette
                move.l  #St_TitleLetters,(TitleState).l
St_TitleLetters:
                bsr.w   DrawTitle
                tst.b   (D_056F2).l
                beq.w   TitleNextFrame
                move.l  #St_TitleText,(TitleState).l
                bra.w   TitleNextFrame
St_TitleText:
                bsr.w   DrawTitle
                lea.l   (TitleTextList).l,a4
                bsr.w   PrintList
                move.l  #St_TitleWipe,(TitleState).l
                move.b  #$D,(D_056F3).l
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
                move.w  #$2,(D_056F6).l
                subq.b  #$1,(D_056F3).l
                bne.b   TitleNextFrame
                move.w  #$C8,(D_056F6).l
                move.l  #St_TitleFadeOut,(TitleState).l
                move.b  #$F,(D_056F3).l
TitleNextFrame:
                st.b    (FrameReady).l
                bra.w   TitleLoop
InitTitleLetters:
                cmpi.l  #$3F3,(MUSIC).l
                bne.b   .033de
                st.b    (TitleMusicOn).l
.033de:
                bsr.w   InitObjects
                st.b    (D_0513C).l
                clr.b   (D_056F2).l
                move.b  #$1,(D_056F4).l
                moveq   #6,d7
                lea.l   (D_055AC).l,a4
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
                move.l  #D_055E4,$2A(a0)
                move.l  (a4)+,$12(a0)
                move.l  (a4)+,$34(a0)
                bsr.w   ObjInsert
                dbra    d7,.033fe
                rts
DrawTitle:
                move.w  (D_056F8).l,d0
                move.w  #$2A1A,d1
                bsr.w   ClearLines
                move.w  (D_056FA).l,d0
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
                st.b    (D_0513C).l
                lea.l   (D_056C8).l,a1
                bsr.w   SetPalette
                move.l  (Score).l,d0
                bsr.w   InsertScore
                move.l  a0,-(a7)
                beq.b   .0357a
                move.b  #$FF,(D_056FD).l
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
                move.b  #$F,(D_056F3).l
                move.l  #St_CreditsFadeOut,(TitleState).l
                move.b  #$1,(D_056FD).l
                st.b    (D_056FE).l
                bra.w   TitleNextFrame
.0357a:
                st.b    (D_056FE).l
                addq.l  #$4,a7
                move.l  #St_TitleStart,(TitleState).l
                bra.w   TitleNextFrame
ObjUpd_TitleLetter:
                tst.b   $32(a0)
                beq.w   .03622
                move.w  $C(a0),d0
                tst.b   $32(a0)
                bpl.b   .035aa
                move.w  d0,(D_056FA).l
                bra.b   .035b0
.035aa:
                move.w  d0,(D_056F8).l
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
                st.b    (D_056F4).l
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
                tst.b   (D_056F4).l
                bne.b   .03620
                addq.w  #$3,$C(a0)
                subq.b  #$1,$38(a0)
                bne.b   .03620
                clr.l   $6(a0)
                st.b    (D_056F2).l
.03620:
                rts
.03622:
                move.w  $C(a0),(D_056FA).l
                tst.b   (D_056F4).l
                bpl.b   .03620
                addq.w  #$6,$A(a0)
                addq.w  #$3,$C(a0)
                cmpi.w  #$96,$C(a0)
                bcs.b   .03620
                clr.b   (D_056F4).l
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
                lea.l   (D_057C8).l,a1
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
FormatScores:
                lea.l   (HighScores).l,a1
                lea.l   (D_05700).l,a2
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
EnterName:
                move.l  a0,-(a7)
                lea.l   (D_0573C).l,a0
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
                tst.b   (D_056FE).l
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
                move.b  (D_056FD).l,d0
                move.b  #$2,(D_056FD).l
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
                clr.b   (D_056FE).l
                bra.w   ClearPlayfield
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
                beq.b   L_03AE4
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
                bne.b   L_03AE4
                clr.b   (MusicRequest).l
L_03AE4:
                rts

; PlaySound: d0 = effect number (priority-based on two channels)
PlaySound:
                tst.b   (JingleState).l
                bne.b   L_03AE4
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
L_03B3C:
                rts
UpdateSound:
                lea.l   (SoundChannels).l,a6
                lea.l   (CUSTOM+$0C0).l,a5
                bsr.w   UpdateChannel
                addq.l  #$8,a6
                adda.w  #$10,a5
UpdateChannel:
                move.b  $2(a6),d0
                bmi.b   L_03B3C
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
                lea.l   (D_05B00).l,a6
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
L_03CD4:
                move.l  d2,(LoadDest).l
                movem.l d0-d7/a0-a6,-(a7)
                bsr.w   ReadTrack
                bsr.w   DecodeTrack
                movem.l (a7)+,d0-d7/a0-a6
                add.l   #$1998,d2
L_03CF0:
                moveq   #0,d0
                move.w  (CurrentTrack).l,d0
                addq.w  #$1,d0
                bsr.w   SeekTrack
                subq.w  #$1,d1
                bne.b   L_03CD4
                bra.w   MotorOff
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
; LevelTable: 8 x (track,count -> $4A2E4; track,count -> $4CB00; map width)
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
D_04209:
                dc.b    $00
D_0420A:
                dc.b    $00
D_0420B:
                dc.b    $00
SpaceKey:
                dc.b    $00
D_0420D:
                dc.b    $00
Continues:
                dc.b    $00
Paused:
                dc.b    $00
D_04210:
                dc.w    $0000
Score:
                dc.w    $0000,$0000
Bonus:
                dc.w    $0000,$0000
ExtraLifePtr:
                dc.w    $0000,$0000
ScoreShown:
                dc.b    $00,$00,$00
D_04221:
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
D_04252:
                dc.w    $1303,$002E,$0260,$0003,$FFFF,$0000,$0001,$2490
                dc.w    $0000,$0130,$0000,$427A,$0000,$427E,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
D_0427A:
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
StackTop:
                dc.w    $001A,$0042,$0060,$00BA,$00CE,$00F6,$015A,$01A0
                dc.w    $01D2,$01FA,$0236,$025E,$FFFF
D_04688:
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
D_04702:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
D_0470E:
                dc.w    $0818,$4040,$6828,$1020,$4040,$6828,$3838,$3C3C
                dc.w    $3C28
D_04720:
                dc.w    $0010,$0000,$0005,$0001,$0000,$0004,$0000,$1000
                dc.w    $0003,$0000,$0100,$0002,$0000,$0000,$0000
D_0473E:
                dc.w    $2020,$2020,$2020,$2020
D_04746:
                dc.w    $0000
D_04748:
                dc.w    $7320,$7420,$6120,$6720,$6520,$2020,$7820,$2020
                dc.w    $6320,$6C20,$6520,$6120,$7220,$6520,$6400
D_04766:
                dc.w    $7374,$6167,$6520,$7363,$6F72,$6500
D_04772:
                dc.w    $6320,$6F20,$6E20,$7420,$6920,$6E20,$7520,$6500
D_04782:
                dc.w    $7075,$7368,$2066,$6972,$6520,$6275,$7474,$6F6E
                dc.b    $00
D_04793:
                dc.b    $63,$20,$72,$20,$65,$20,$64,$20,$69,$20,$74,$20,$20,$78,$00
D_047A2:
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
D_048CE:
                dc.w    $0000
D_048D0:
                dc.b    $00
D_048D1:
                dc.b    $00
D_048D2:
                dc.b    $00
D_048D3:
                dc.b    $00
D_048D4:
                dc.w    $0000
D_048D6:
                dc.w    $0000,$0000,$00FC,$FDFE,$FFFF,$FFFF,$FFFF,$FFFF
                dc.b    $FF,$FF,$FF
D_048E9:
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
D_04918:
                dc.w    $0000
D_0491A:
                dc.w    $0000,$493A,$0000,$000E,$0000,$4972,$0000,$000C
                dc.w    $0000,$49A8,$0000,$001A,$0000,$49EC,$0000,$0006
                dc.w    $1E03,$002E,$03C0,$0000,$FFFF,$0000,$0000,$8740
                dc.w    $0000,$01E0,$0000,$4962,$0000,$427E,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0001,$0001,$0202,$0303
                dc.w    $0404,$0405,$0505,$05FF,$1E03,$002E,$03C0,$0000
                dc.w    $FFFF,$0000,$0000,$9DC0,$0000,$01E0,$0000,$499A
                dc.w    $0000,$427E,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0001,$0001,$0102,$0203,$0304,$0405,$05FF,$3304
                dc.w    $002C,$0990,$0000,$FFFF,$0000,$0000,$B440
                dc.l    L_004C8
                dc.w    $0000,$49D0,$0000,$427E,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0001,$0201,$0102,$0203,$0304,$0405
                dc.w    $0506,$0607,$0708,$0805,$0506,$0607,$0708,$08FF
                dc.w    $1E03,$002E,$03C0,$0001,$FFFF,$0000,$0001,$0A50
                dc.w    $0000,$01E0,$0000,$4A14,$0000,$427E,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$06FF
D_04A1C:
                dc.w    $000F,$0E0D,$0C08,$090A,$0B0C,$0001,$0203,$0408
                dc.w    $0706,$0504
D_04A30:
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
D_04B1A:
                dc.w    $0000,$FFFD,$0002,$FFFD,$0003,$FFFD,$0003,$FFFE
                dc.w    $0004,$0000,$0003,$0002,$0003,$0003,$0002,$0003
                dc.w    $0000,$0003,$FFFE,$0003,$FFFD,$0003,$FFFD,$0002
                dc.w    $FFFC,$0000,$FFFD,$FFFE,$FFFD,$FFFD,$FFFE,$FFFD
D_04B5A:
                dc.w    $0000
D_04B5C:
                dc.b    $00
FireHeld:
                dc.b    $00
BeamCharge:
                dc.b    $00
D_04B5F:
                dc.b    $00
D_04B60:
                dc.b    $00
D_04B61:
                dc.b    $00
D_04B62:
                dc.w    $0000
D_04B64:
                dc.w    $0000
D_04B66:
                dc.w    $0000
D_04B68:
                dc.w    $0000,$0000
D_04B6C:
                dc.w    $0000,$0000
D_04B70:
                dc.w    $0000
D_04B72:
                dc.w    $0000,$0000
D_04B76:
                dc.w    $0000,$0000,$0000
D_04B7C:
                dc.w    $0000,$0000
D_04B80:
                dc.w    $0000,$0000
D_04B84:
                dc.w    $0000
D_04B86:
                dc.w    $0000
D_04B88:
                dc.w    $0000
D_04B8A:
                dc.w    $0000,$0000
D_04B8E:
                dc.w    $0000
D_04B90:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000
D_04BAA:
                dc.w    $0000
D_04BAC:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000
D_04BC6:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$000C,$000C
                dc.w    $000C,$000C,$0000,$0000,$0000,$0000,$0004,$0004
                dc.w    $0000,$0000,$0000,$0000,$0004,$0004,$0004,$0004
                dc.w    $0000,$0000,$0000,$0000,$000B,$000B,$0000,$0000
                dc.w    $0000,$0000
D_04C3A:
                dc.w    $0010,$0000
                dc.l    L_00402
                dc.w    $0000,$4E1E,$0000,$4E3E,$000C,$FFF4
                dc.l    L_00B02
                dc.w    $0000,$8480,$0000,$84D8,$000C,$000C
                dc.l    L_00B02
                dc.w    $0000,$8530,$0000,$8588,$0000,$FFF4
                dc.l    L_00B02
                dc.w    $0000,$85E0,$0000,$8638,$0000,$000C
                dc.l    L_00B02
                dc.w    $0000,$8690,$0000,$86E8
D_04C8A:
                dc.w    $0001,$2950,$0001,$30D0,$0001,$3850,$0001,$3FD0
                dc.w    $0001,$4750,$0001,$4ED0
D_04CA2:
                dc.w    $0018,$000B,$0001,$0007,$0002,$0036,$000C,$0008
                dc.w    $002A,$1005,$000B,$0001,$9390,$0000,$0200,$0012
                dc.w    $0010,$0001,$0003,$0003,$002B,$0009,$0008,$002C
                dc.w    $0E04,$0009,$0001,$8E50,$0000,$0150,$000C,$0011
                dc.w    $0003,$000A,$0002,$0016,$0008,$0006,$002E,$0C03
                dc.w    $0007,$0001,$8B50
                dc.l    GameEntry
                dc.w    $0006,$001B,$0003,$0002,$0001,$000D,$000A,$0006
                dc.w    $0030,$0C02,$0005,$0001,$89D0,$0000,$0060
D_04D1A:
                dc.w    $000F,$FFF1,$0000,$FFFF,$FE72,$0010,$0000,$0003
                dc.w    $0000,$0002,$0000,$FFF0,$0001,$FFFF,$FE70,$0000
                dc.w    $0000,$0002,$0000,$0000,$FFF1,$FFF1,$0001,$FFFF
                dc.w    $FE6E,$FFF0,$0000,$0002,$FFFF,$FFFE,$0000,$FFF0
                dc.w    $0000,$FFFF,$FE70,$0000,$0000,$0003,$0000,$0000
                dc.w    $FFF1,$000F,$0002
                dc.l    L_0018E
                dc.w    $FFF0,$0000,$0001,$FFFF,$FFFE,$0000,$0010,$0003
                dc.w    $0000,$0190,$0000,$0000,$0000,$0000,$0000,$000F
                dc.w    $000F,$0003,$0000,$0192,$0010,$0000,$0000,$0000
                dc.w    $0002,$0000,$0010,$0002,$0000,$0190,$0000,$0000
                dc.w    $0001,$0000,$0000
D_04DBA:
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
D_04E5E:
                dc.w    $0001,$C2D0,$0001,$C3B0,$0001,$C490,$0001,$C570
D_04E6E:
                dc.w    $0000,$FFF2,$0000,$FFFF,$FDE8,$000E,$0000,$0001
                dc.w    $0000,$0002,$0000,$000E,$0002
                dc.l    L_00218
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$0000,$FFF2,$0000
                dc.w    $FFFF,$FDE8,$000E,$0000,$0001,$0000,$0002,$0000
                dc.w    $000E,$0002
                dc.l    L_00218
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$000E,$0000,$0001
                dc.w    $0000,$0002,$0000,$000E,$0002
                dc.l    L_00218
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$0000,$0000,$FFFF
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$000E,$0000
                dc.w    $0001,$0000,$0002,$0000,$FFF2,$0000,$FFFF,$FDE8
                dc.w    $0000,$0000,$FFFF,$0000,$0000,$0000,$0000,$FFFF
                dc.w    $0000,$0000,$0000,$000E,$0002
                dc.l    L_00218
                dc.w    $000E,$0000,$0001,$0000,$0002,$0000,$FFF2,$0000
                dc.w    $FFFF,$FDE8,$0000,$0000,$FFFF,$0000,$0000,$0000
                dc.w    $000E,$0002
                dc.l    L_00218
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
D_050EF:
                dc.b    $00
D_050F0:
                dc.b    $00
D_050F1:
                dc.b    $00
D_050F2:
                dc.w    $0000
D_050F4:
                dc.w    $0000
ShipSpeed:
                dc.w    $0000
ShipX:
                dc.w    $0000
ShipY:
                dc.w    $0000
D_050FC:
                dc.w    $0000
D_050FE:
                dc.w    $0000
D_05100:
                dc.w    $0000,$0000
VblCount:
                dc.w    $0000
D_05106:
                dc.b    $00
D_05107:
                dc.b    $00
D_05108:
                dc.w    $0505,$0404,$0406,$0606,$0606
D_05112:
                dc.w    $0000
D_05114:
                dc.w    $0000,$0000
D_05118:
                dc.w    $0000,$0000
D_0511C:
                dc.w    $0000
D_0511E:
                dc.w    $0000,$0000
D_05122:
                dc.w    $0000,$0000
D_05126:
                dc.w    $0000
D_05128:
                dc.w    $0000
D_0512A:
                dc.w    $0000
D_0512C:
                dc.w    $0000
D_0512E:
                dc.w    $0000,$0000
D_05132:
                dc.w    $0000,$0000
D_05136:
                dc.w    $0000
D_05138:
                dc.w    $0000
FrameReady:
                dc.b    $00
D_0513B:
                dc.b    $00
D_0513C:
                dc.w    $0000
DrawBuffer:
                dc.w    $0000,$0000
ForceLevel:
                dc.b    $00
D_05143:
                dc.b    $00
D_05144:
                dc.b    $00
D_05145:
                dc.b    $00
D_05146:
                dc.b    $00
ForceActive:
                dc.b    $00
ForceSide:
                dc.b    $00
D_05149:
                dc.b    $00
D_0514A:
                dc.b    $00
D_0514B:
                dc.b    $00
D_0514C:
                dc.w    $0000
D_0514E:
                dc.w    $0000
D_05150:
                dc.w    $0000
D_05152:
                dc.w    $0000
D_05154:
                dc.w    $0000
D_05156:
                dc.w    $0000,$0000
D_0515A:
                dc.w    $0000
D_0515C:
                dc.w    $0000
D_0515E:
                dc.w    $0000
D_05160:
                dc.w    $0000,$0000
ForceState:
                dc.w    $0000,$0000
ForcePos:
                dc.w    $0000
D_0516A:
                dc.w    $0000
D_0516C:
                dc.w    $0000,$6A40,$0000,$6F40,$0000,$0100,$0003,$000E
                dc.w    $0000,$7040,$0000,$7630,$0000,$0130,$0003,$0011
                dc.w    $0000,$7760,$0000,$7D50,$0000,$0130,$0003,$0011
                dc.w    $0000,$7E80,$0000,$8300,$0000,$0180,$0004,$0016
D_051AC:
                dc.w    $FFED,$0000,$0018,$0001,$0000,$0000,$001A,$0001
                dc.w    $FFE0,$FFFE,$0000,$0000,$FFE7,$FFFC,$0014,$FFFD
D_051CC:
                dc.w    $000A,$0006,$0007,$0008,$0000,$0000,$0011,$000B
D_051DC:
                dc.w    $0000,$0000,$0015,$000E,$0000,$0000,$0015,$0011
                dc.w    $000C,$0000,$0014,$0011,$0005,$0001,$0017,$0014
D_051FC:
                dc.w    $1A03,$002E,$0340,$0003,$0001,$0000,$0001,$5A50
                dc.w    $0000,$01A0,$0000,$5224,$0000,$5238
                dc.l    ObjUpd_Walker
                dc.l    SpawnWalker
                dc.w    $0000,$0200
D_05224:
                dc.b    $01,$00,$02,$00,$FF
D_05229:
                dc.b    $03,$05,$04,$05,$FF
D_0522E:
                dc.b    $07,$FF,$00,$06,$FF
D_05233:
                dc.b    $09,$FF,$00,$08,$FF,$00,$03,$00,$04,$00,$12,$00,$16,$00,$02,$00
                dc.b    $07,$00,$15,$00,$12,$00,$02,$00,$07,$00,$15,$00,$11,$00,$03,$00
                dc.b    $07,$00,$15,$00,$12,$00,$03,$00,$07,$00,$14,$00,$12,$00,$03,$00
                dc.b    $05,$00,$13,$00,$14,$00,$06,$00,$01,$00,$11,$00,$18,$00,$02,$00
                dc.b    $01,$00,$16,$00,$12,$00,$04,$00,$01,$00,$10,$00,$18,$00,$02,$00
                dc.b    $01,$00,$16,$00,$12
D_05288:
                dc.w    $1403,$002E,$0280,$0000,$FFFF,$0000,$0001,$7AD0
                dc.l    L_00140
                dc.w    $0000,$52B0,$0000,$52B8
                dc.l    ObjUpd_ScrollOff
                dc.w    $0000,$0000,$0000,$0000,$0001,$0203,$0405,$FF00
                dc.w    $0000,$0000,$0013,$0010,$0000,$0000,$0013,$0010
                dc.w    $0000,$0000,$0013,$0010,$0000,$0000,$0013,$0014
                dc.w    $0000,$0000,$0013,$0011,$0002,$0004,$000E,$000B
CopperList:
                dc.w    $0180,$0000,$0100,$0000,$00E0
D_052F2:
                dc.l    jt_TurnTowards
                dc.w    $0000,$00E4
                dc.l    jt_AddScore
                dc.w    $0000,$00E8
                dc.l    jt_AdjustForScroll
                dc.w    $0000,$00EC,$0000,$00EE,$0000,$00F0,$0000,$00F2
                dc.w    $0000,$0130,$0004,$0132,$90A2,$0134,$0004,$0136
                dc.w    $914A,$0138,$0004,$013A,$91F2,$013C,$0004,$013E
                dc.w    $929A,$0120
D_0533A:
                dc.l    L_00122
                dc.w    $0004,$0124,$0000,$0126,$0004,$0128,$0000,$012A
                dc.w    $0004,$012C
                dc.l    L_0012E
                dc.w    $0004,$0108,$00A8,$010A,$00A8,$0182
CopColours:
                dc.w    $0000,$0184,$0000,$0186
                dc.l    L_00188
                dc.w    $0000,$018A,$0000,$018C
                dc.l    L_0018E
                dc.w    $0000,$0190,$0000,$0192,$0000,$0194
                dc.l    L_00196
                dc.w    $0000,$0198,$0000,$019A,$0000,$019C
                dc.l    L_0019E
                dc.w    $0000,$0102
D_0539E:
                dc.w    $0000,$0104,$0024,$0100,$4200,$EC01,$FFFE,$009C
                dc.w    $8010,$0100,$0000,$0102,$0000,$00E0,$0002,$00E2
                dc.w    $C7B0,$00E4,$0002,$00E6,$CA08,$00E8,$0002,$00EA
                dc.w    $CC60,$0108
                dc.l    jt_PlaySound
                dc.w    $0000,$0184,$0999,$0186,$0ACD,$0188,$0FFF,$018A
                dc.w    $089F,$018C,$000C,$018E,$0E00,$ED01,$FFFE,$0100
                dc.w    $3200,$EE01,$FFFE,$0182,$0006,$EF01,$FFFE,$0182
                dc.w    $000A,$F001,$FFFE,$0182,$000E,$F101,$FFFE,$0182
                dc.w    $000A,$F201,$FFFE,$0182,$0006,$F301,$FFFE,$0182
                dc.w    $0FFF,$FFFF,$FFFE
D_0542C:
                dc.w    $0000,$FFFA,$0004,$FFFA,$0006,$FFFA,$0006,$FFFC
                dc.w    $0006,$0000,$0006,$0004,$0006,$0006,$0004,$0006
                dc.w    $0000,$0006,$FFFC,$0006,$FFFA,$0006,$FFFA,$0004
                dc.w    $FFFA,$0000,$FFFA,$FFFC,$FFFA,$FFFA,$FFFC,$FFFA
D_0546C:
                dc.w    $0001,$A2D0,$0001,$A3D0,$0001,$A4D0,$0001,$A5D0
                dc.w    $0001,$A6D0,$0001,$A7D0,$0001,$A8D0,$0001,$A9D0
                dc.w    $0001,$AAD0,$0001,$ABD0,$0001,$ACD0,$0001,$ADD0
                dc.w    $0001,$AED0,$0001,$AFD0,$0001,$B0D0,$0001,$B1D0
                dc.w    $0001,$B2D0,$0001,$B3D0,$0001,$B4D0,$0001,$B5D0
                dc.w    $0001,$B6D0,$0001,$B7D0,$0001,$B8D0,$0001,$B9D0
                dc.w    $0001,$BAD0,$0001,$BBD0,$0001,$BCD0,$0001,$BDD0
                dc.w    $0001,$BED0,$0001,$BFD0,$0001,$C0D0,$0001,$C1D0
D_054EC:
                dc.w    $0005,$0000,$0006,$000B,$0004,$0001,$0009,$000A
                dc.w    $0006,$0001,$0009,$000A,$0004,$0003,$000C,$0007
                dc.w    $0005,$0005,$000B,$0006,$0005,$0005,$000A,$0008
                dc.w    $0005,$0005,$0009,$000A,$0005,$0004,$0008,$000B
                dc.w    $0005,$0006,$0006,$000A,$0001,$0004,$0008,$000B
                dc.w    $0001,$0005,$000A,$0009,$0001,$0004,$000A,$0008
                dc.w    $0000,$0005,$000B,$0006,$0001,$0002,$000A,$0008
                dc.w    $0002,$0001,$0009,$000A,$0004,$0001,$0008,$000B
D_0556C:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$00FE,$0100
D_05588:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0002,$0000
D_055A4:
                dc.w    $0000
D_055A6:
                dc.w    $0000
D_055A8:
                dc.w    $0000
D_055AA:
                dc.w    $0000
D_055AC:
                dc.w    $0000,$55E6,$0000,$0000,$0000,$5602,$0005,$0E62
                dc.w    $0000,$561E,$0005,$0E8F,$0000,$563A,$0005,$0EBC
                dc.w    $0000,$5656,$0005,$0EE9,$0000,$5672,$0005,$0F16
                dc.w    $0000,$568E,$0000,$0000
D_055E4:
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
D_056AA:
                dc.w    $028C,$0FFF,$00FF,$0FEF,$0B9F,$095F,$0B7F,$0000
                dc.w    $0DBF,$00D9,$00B9,$0097,$0077,$0FFF,$0000
D_056C8:
                dc.w    $028C,$0FFF,$09BF,$005F,$000B,$095F,$0B7F,$0000
                dc.w    $0DBF,$00D9,$00B9,$0097,$0077,$0FFF,$0000
TitleState:
                dc.w    $0000,$0000
MusicCopy:
                dc.w    $0000,$0000
TitleStack:
                dc.w    $0000,$0000
D_056F2:
                dc.b    $00
D_056F3:
                dc.b    $00
D_056F4:
                dc.b    $00
TitleMusicOn:
                dc.b    $00
D_056F6:
                dc.w    $0000
D_056F8:
                dc.w    $0000
D_056FA:
                dc.w    $0000
JinglePlaying:
                dc.b    $00
D_056FD:
                dc.b    $00
D_056FE:
                dc.b    $00
CheatMode:
                dc.b    $00
D_05700:
                dc.b    $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$20
CharSet:
                dc.b    $61,$62,$63,$64,$65,$66,$67,$68,$69,$6A,$6B,$6C,$6D,$6E,$6F,$70
                dc.b    $71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$30,$31,$32,$33,$34,$35
                dc.b    $36,$37,$38,$39,$2E,$2C,$2D,$5F,$21,$3F,$48,$43,$3C,$53,$45,$20
                dc.b    $00
D_0573C:
                dc.w    $706C,$6561,$7365,$2065,$6E74,$6572,$2079,$6F75
                dc.w    $7220,$6E61,$6D65,$2070,$6C61,$7965,$7220,$3100
HighScores:
                dc.l    L_02490
                dc.w    $0000,$57D4
D_05764:
                dc.w    $0018,$0000,$0000,$30C0,$0000,$57EC,$0017,$0000
                dc.l    L_03CF0
                dc.w    $0000,$5804,$0016,$0000,$0000,$4920,$0000,$581C
                dc.w    $0015,$0000,$0000,$5550,$0000,$5834,$0009,$0000
                dc.w    $0000,$6180,$0000,$584C,$0007,$0000,$0000,$6DB0
                dc.w    $0000,$5864,$0005,$0000,$0000,$79E0,$0000,$587C
                dc.w    $0004,$0000,$0000,$8610,$0000,$5894,$0003,$5000
D_057C8:
                dc.w    $0000,$9240,$0000,$58AC,$0003,$0000,$6163,$6869
                dc.w    $6D20,$6D6F,$6C6C,$6572,$2020,$2020,$0030,$3030
                dc.w    $3030,$3000,$686F,$6C67,$6572,$2073,$6368,$6D69
                dc.w    $6474,$2020,$0030,$3030,$3030,$3000,$6C75,$747A
                dc.w    $206F,$7374,$6572,$6B6F,$726E,$2020,$0030,$3030
                dc.w    $3030,$3000,$7374,$6566,$616E,$2074,$736F,$7570
                dc.w    $6172,$692E,$0030,$3030,$3030,$3000,$7769,$6C6C
                dc.w    $6920,$6261,$6563,$6B65,$7220,$2020,$0030,$3030
                dc.w    $3030,$3000,$6461,$7269,$7573,$207A,$656E,$6465
                dc.w    $6820,$2020,$0030,$3030,$3030,$3000,$7465,$7574
                dc.w    $2077,$6569,$6465,$6D61,$6E6E,$2020,$0030,$3030
                dc.w    $3030,$3000,$726F,$6265,$7274,$2067,$7261,$756C
                dc.w    $6963,$6820,$0030,$3030,$3030,$3000,$7468,$6F6D
                dc.w    $6173,$2066,$616E,$736C,$6175,$2020,$0030,$3030
                dc.w    $3030,$3000,$6865,$696B,$6F20,$7363,$6872,$6F65
                dc.w    $6465,$7220,$0030,$3030,$3030,$3000
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
D_05962:
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
SoundChannels:
                dc.w    $0000,$FF00,$0004,$0200
D_05B00:
                dc.w    $0000,$FF00,$0008,$0400
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
D_05BC8:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
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
