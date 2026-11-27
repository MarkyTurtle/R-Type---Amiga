;==============================================================================
; R-Type (Amiga) - Chris Huelsbeck's TFMX replay (title music)
; files/tfmx_player_52300.exe: an AmigaDOS executable (HUNK_HEADER, one
; code hunk of $1444 bytes, HUNK_END) that sits on the disk at $52300,
; followed there by the samples (smpl, $53768) and the song (mdat, $6FD28).
;
; Assembles byte-identical with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -o tfmx.bin src/tfmx.s
;
; The code is position-independent.  The jump table at the start of the hunk:
;   +$00 TfmxEntry0 -> TfmxCommand    d0 = sub-command (not used by R-Type)
;   +$04 TfmxPlay                     every VBL
;   +$08 TfmxEntry2 -> TfmxStop       silence all channels
;   +$0C TfmxStartSong -> Tfmx_StartSong  d0 = song (starts on the next play)
;   +$10 TfmxEntry4 -> TfmxNote       d0 = note/macro/channel: a sound
;                                     effect through the macros
;   +$14 TfmxInit -> Tfmx_Init        d0 = mdat, d1 = smpl
;   +$18 TfmxEntry6 -> TfmxIrqOn      hook its own level 3 interrupt ($6C)
;   +$1C TfmxEntry7 -> TfmxIrqOff     put the old one back
;   +$20 TfmxEntry8 -> TfmxChannelOff d0 = channel
; R-Type uses init, start song and play (stage 2 calls play from its own
; VBL rather than TfmxIrqOn).  Tfmx_SongStart reads the song's first and
; last track step and its tempo from the mdat tables at $100/$140/$180.
;
; Commands are dispatched through three tables of offsets from TfmxBase:
; the code patches the target into a "jmp ($0).l" and jumps.
;   TrackCmds    track step commands ($EFFE n): stop, loop, speed
;   PatternCmds  pattern commands $F0-$F5: end, loop, cont, wait, stop, key up
;   MacroCmds    macro commands $00-$14: DMA off/on, sample begin and
;                length, wait, loop, cont, stop, add/set note, reset,
;                portamento, vibrato, add/set volume, envelope, loop until
;                key up, add begin/length, DMA off, end
; The names follow the usual TFMX command lists; this early replay has only
; the first commands of each.  The "CHfield0-2" strings mark its data
; blocks: TfmxVars, TfmxChannels (4 x 4 bytes interleaved per channel),
; TfmxTrack.  TfmxPeriods: the note period table.  DosName, SmplPath and
; MdatPath ("df1:smpl.rtypetitle.pck") are left from development, when the
; replay loaded the music from a second floppy.
;
; Traced from the jump table and the command tables; byte-identical.  The
; entry points and command handlers are named; the internal routines still
; have address labels.
;==============================================================================
                org     $52300
                dc.l    $000003F3,$00000000,$00000001,$00000000
                dc.l    $00000000,$00000511,$000003E9,$00000511
                org     $52320
TfmxBase:
                bra.w   TfmxCommand                             ; 52320
TfmxPlay:
                bra.w   TfmxPlayBody                             ; 52324
TfmxEntry2:
                bra.w   TfmxStop                             ; 52328
TfmxStartSong:
                bra.w   Tfmx_StartSong                             ; 5232C
TfmxEntry4:
                bra.w   TfmxNote                             ; 52330
TfmxInit:
                bra.w   Tfmx_Init                             ; 52334
TfmxEntry6:
                bra.w   TfmxIrqOn                             ; 52338
TfmxEntry7:
                bra.w   TfmxIrqOff                             ; 5233C
TfmxEntry8:
                bra.w   TfmxChannelOff                             ; 52340
; TfmxPlayBody - one tick: start a queued song, step the track and patterns, then run the macros
TfmxPlayBody:
                movem.l d0-d7/a0-a7,-(a7)                   ; 52344
                lea.l   TfmxVars(pc),a6                      ; 52348
                tst.w   $C(a6)                              ; 5234C
                bmi.w   .5235C                             ; 52350
                bsr.w   Tfmx_SongStart                             ; 52354
                bra.w   .52374                             ; 52358
.5235C:
                tst.w   $8(a6)                              ; 5235C
                beq.w   .52374                             ; 52360
                tst.w   $2E(a6)                             ; 52364
                beq.w   .52374                             ; 52368
                bsr.w   .5237A                             ; 5236C
                bsr.w   TfmxMacros                             ; 52370
.52374:
                movem.l (a7)+,d0-d7/a0-a7                   ; 52374
                rts                                         ; 52378
.5237A:
                movea.l $0(a6),a4                           ; 5237A
                lea.l   TfmxTrack(pc),a5                      ; 5237E
                tst.w   $2C(a6)                             ; 52382
                beq.w   .52392                             ; 52386
                subi.w  #$1,$2C(a6)                         ; 5238A
                rts                                         ; 52390
.52392:
                move.w  $6(a5),$2C(a6)                      ; 52392
                move.w  $1C0(a4),$8(a5)                     ; 52398
                move.w  $1C2(a4),$C(a5)                     ; 5239E
                move.w  $1C4(a4),$10(a5)                    ; 523A4
                move.w  $1C6(a4),$14(a5)                    ; 523AA
                move.w  $1C8(a4),$18(a5)                    ; 523B0
                move.w  $1CA(a4),$1C(a5)                    ; 523B6
                move.w  $1CC(a4),$20(a5)                    ; 523BC
                move.w  $1CE(a4),$24(a5)                    ; 523C2
                bsr.w   .523CE                             ; 523C8
                rts                                         ; 523CC
.523CE:
                tst.w   $2E(a6)                             ; 523CE
                beq.w   TfmxRts                             ; 523D2
                movea.l a5,a0                               ; 523D6
                clr.w   $A(a6)                              ; 523D8
                bsr.w   TfmxPatternChannel                             ; 523DC
                tst.w   $A(a6)                              ; 523E0
                bne.w   .523CE                             ; 523E4
                adda.l  #$4,a0                              ; 523E8
                bsr.w   TfmxPatternChannel                             ; 523EE
                tst.w   $A(a6)                              ; 523F2
                bne.w   .523CE                             ; 523F6
                adda.l  #$4,a0                              ; 523FA
                bsr.w   TfmxPatternChannel                             ; 52400
                tst.w   $A(a6)                              ; 52404
                bne.w   .523CE                             ; 52408
                adda.l  #$4,a0                              ; 5240C
                bsr.w   TfmxPatternChannel                             ; 52412
                tst.w   $A(a6)                              ; 52416
                bne.w   .523CE                             ; 5241A
                adda.l  #$4,a0                              ; 5241E
                bsr.w   TfmxPatternChannel                             ; 52424
                tst.w   $A(a6)                              ; 52428
                bne.w   .523CE                             ; 5242C
                adda.l  #$4,a0                              ; 52430
                bsr.w   TfmxPatternChannel                             ; 52436
                tst.w   $A(a6)                              ; 5243A
                bne.w   .523CE                             ; 5243E
                adda.l  #$4,a0                              ; 52442
                bsr.w   TfmxPatternChannel                             ; 52448
                tst.w   $A(a6)                              ; 5244C
                bne.w   .523CE                             ; 52450
                adda.l  #$4,a0                              ; 52454
                bsr.w   TfmxPatternChannel                             ; 5245A
                tst.w   $A(a6)                              ; 5245E
                bne.w   .523CE                             ; 52462
                rts                                         ; 52466
; TfmxReadTrackStep - clear the per-channel state and read the current track step
TfmxReadTrackStep:
                movem.l d0-d7/a0-a7,-(a7)                   ; 52468
                clr.l   $68(a5)                             ; 5246C
                clr.l   $6C(a5)                             ; 52470
                clr.l   $70(a5)                             ; 52474
                clr.l   $74(a5)                             ; 52478
                clr.l   $78(a5)                             ; 5247C
                clr.l   $7C(a5)                             ; 52480
                clr.l   $80(a5)                             ; 52484
                clr.l   $84(a5)                             ; 52488
                move.w  #$FFFF,$4A(a5)                      ; 5248C
                move.w  #$FFFF,$4E(a5)                      ; 52492
                move.w  #$FFFF,$52(a5)                      ; 52498
                move.w  #$FFFF,$56(a5)                      ; 5249E
                move.w  #$FFFF,$5A(a5)                      ; 524A4
                move.w  #$FFFF,$5E(a5)                      ; 524AA
                move.w  #$FFFF,$62(a5)                      ; 524B0
                move.w  #$FFFF,$66(a5)                      ; 524B6
; TfmxTrackStep - decode a track step: point each channel at its pattern (track commands loop back here)
TfmxTrackStep:
                move.w  $4(a5),d0                           ; 524BC
                andi.l  #$1FF,d0                            ; 524C0
                asl.w   #$4,d0                              ; 524C6
                add.l   a4,d0                               ; 524C8
                addi.l  #$800,d0                            ; 524CA
                movea.l d0,a0                               ; 524D0
                movea.l a4,a1                               ; 524D2
                adda.l  #$400,a1                            ; 524D4
                move.w  (a0),d0                             ; 524DA
                cmp.w   #$F9FF,d0                           ; 524DC
                bcs.w   .5250E                             ; 524E0
                cmp.w   #$FA02,d0                           ; 524E4
                bcc.w   .5250E                             ; 524E8
                subi.w  #$FA00,d0                           ; 524EC
                asl.w   #$2,d0                              ; 524F0
                lea.l   TrackCmds(pc),a1                      ; 524F2
                move.l  (a1,d0.w),d0                        ; 524F6
                lea.l   TfmxBase(pc),a1                      ; 524FA
                add.l   a1,d0                               ; 524FE
                lea.l   .52508(pc),a1                      ; 52500
                move.l  d0,$2(a1)                           ; 52504
.52508:
                jmp     ($0).l                              ; 52508
.5250E:
                move.w  d0,$48(a5)                          ; 5250E
                bmi.w   .52528                             ; 52512
                ror.w   #$8,d0                              ; 52516
                andi.w  #$7F,d0                             ; 52518
                asl.w   #$2,d0                              ; 5251C
                move.l  (a1,d0.w),d0                        ; 5251E
                add.l   a4,d0                               ; 52522
                move.l  d0,$28(a5)                          ; 52524
.52528:
                move.w  $2(a0),d0                           ; 52528
                move.w  d0,$4C(a5)                          ; 5252C
                bmi.w   .52546                             ; 52530
                ror.w   #$8,d0                              ; 52534
                andi.w  #$7F,d0                             ; 52536
                asl.w   #$2,d0                              ; 5253A
                move.l  (a1,d0.w),d0                        ; 5253C
                add.l   a4,d0                               ; 52540
                move.l  d0,$2C(a5)                          ; 52542
.52546:
                move.w  $4(a0),d0                           ; 52546
                move.w  d0,$50(a5)                          ; 5254A
                bmi.w   .52564                             ; 5254E
                ror.w   #$8,d0                              ; 52552
                andi.w  #$7F,d0                             ; 52554
                asl.w   #$2,d0                              ; 52558
                move.l  (a1,d0.w),d0                        ; 5255A
                add.l   a4,d0                               ; 5255E
                move.l  d0,$30(a5)                          ; 52560
.52564:
                move.w  $6(a0),d0                           ; 52564
                move.w  d0,$54(a5)                          ; 52568
                bmi.w   .52582                             ; 5256C
                ror.w   #$8,d0                              ; 52570
                andi.w  #$7F,d0                             ; 52572
                asl.w   #$2,d0                              ; 52576
                move.l  (a1,d0.w),d0                        ; 52578
                add.l   a4,d0                               ; 5257C
                move.l  d0,$34(a5)                          ; 5257E
.52582:
                move.w  $8(a0),d0                           ; 52582
                move.w  d0,$58(a5)                          ; 52586
                bmi.w   .525A0                             ; 5258A
                ror.w   #$8,d0                              ; 5258E
                andi.w  #$7F,d0                             ; 52590
                asl.w   #$2,d0                              ; 52594
                move.l  (a1,d0.w),d0                        ; 52596
                add.l   a4,d0                               ; 5259A
                move.l  d0,$38(a5)                          ; 5259C
.525A0:
                move.w  $A(a0),d0                           ; 525A0
                move.w  d0,$5C(a5)                          ; 525A4
                bmi.w   .525BE                             ; 525A8
                ror.w   #$8,d0                              ; 525AC
                andi.w  #$7F,d0                             ; 525AE
                asl.w   #$2,d0                              ; 525B2
                move.l  (a1,d0.w),d0                        ; 525B4
                add.l   a4,d0                               ; 525B8
                move.l  d0,$3C(a5)                          ; 525BA
.525BE:
                move.w  $C(a0),d0                           ; 525BE
                move.w  d0,$60(a5)                          ; 525C2
                bmi.w   .525DC                             ; 525C6
                ror.w   #$8,d0                              ; 525CA
                andi.w  #$7F,d0                             ; 525CC
                asl.w   #$2,d0                              ; 525D0
                move.l  (a1,d0.w),d0                        ; 525D2
                add.l   a4,d0                               ; 525D6
                move.l  d0,$40(a5)                          ; 525D8
.525DC:
                move.w  $E(a0),d0                           ; 525DC
                move.w  d0,$64(a5)                          ; 525E0
                bmi.w   .525FA                             ; 525E4
                ror.w   #$8,d0                              ; 525E8
                andi.w  #$7F,d0                             ; 525EA
                asl.w   #$2,d0                              ; 525EE
                move.l  (a1,d0.w),d0                        ; 525F0
                add.l   a4,d0                               ; 525F4
                move.l  d0,$44(a5)                          ; 525F6
.525FA:
                movem.l (a7)+,d0-d7/a0-a7                   ; 525FA
                rts                                         ; 525FE
Track_Stop:
                clr.w   $2E(a6)                             ; 52600
                movem.l (a7)+,d0-d7/a0-a7                   ; 52604
                rts                                         ; 52608
Track_Loop:
                move.w  $2(a0),$4(a5)                       ; 5260A
                bra.w   TfmxTrackStep                             ; 52610
Track_Speed:
                move.w  $2(a0),$6(a5)                       ; 52614
                move.w  $2(a0),$2C(a6)                      ; 5261A
                addi.w  #$1,$4(a5)                          ; 52620
                bra.w   TfmxTrackStep                             ; 52626
TrackCmds:
                dc.l    Track_Stop-TfmxBase
                dc.l    Track_Loop-TfmxBase
                dc.l    Track_Speed-TfmxBase
; TfmxPatternChannel - one channel of pattern playback ($48: $80 off, $FF stopped, $FE waiting)
TfmxPatternChannel:
                cmpi.b  #$80,$48(a0)                        ; 52636
                beq.w   .52674                             ; 5263C
                cmpi.b  #$FF,$48(a0)                        ; 52640
                beq.w   TfmxRts                             ; 52646
                cmpi.b  #$FE,$48(a0)                        ; 5264A
                bne.w   .5266A                             ; 52650
                tst.w   $68(a0)                             ; 52654
                bne.w   TfmxRts                             ; 52658
                move.w  #$1,$68(a0)                         ; 5265C
                move.b  $49(a0),d0                          ; 52662
                bra.w   TfmxChannelOff                             ; 52666
.5266A:
                cmpi.b  #$FD,$48(a0)                        ; 5266A
                bne.w   .52674                             ; 52670
.52674:
                tst.w   $6A(a0)                             ; 52674
                beq.w   PatternStep                             ; 52678
                subi.w  #$1,$6A(a0)                         ; 5267C
                rts                                         ; 52682
; PatternStep - fetch and act on the next pattern note or command
PatternStep:
                move.w  $68(a0),d0                          ; 52684
                asl.w   #$2,d0                              ; 52688
                movea.l $28(a0),a1                          ; 5268A
                move.l  (a1,d0.w),$28(a6)                   ; 5268E
                cmpi.b  #$EF,$28(a6)                        ; 52694
                bcc.w   .526BA                             ; 5269A
                move.b  $49(a0),d0                          ; 5269E
                add.b   d0,$28(a6)                          ; 526A2
                move.l  $28(a6),d0                          ; 526A6
                tst.w   $8(a0)                              ; 526AA
                bne.w   .526B6                             ; 526AE
                bsr.w   TfmxNote                             ; 526B2
.526B6:
                bra.w   PatternNext                             ; 526B6
.526BA:
                cmpi.b  #$F5,$28(a6)                        ; 526BA
                bcc.w   PatternNext                             ; 526C0
                move.b  $28(a6),d0                          ; 526C4
                subi.b  #$F0,d0                             ; 526C8
                andi.l  #$FF,d0                             ; 526CC
                asl.l   #$2,d0                              ; 526D2
                lea.l   PatternCmds(pc),a1                      ; 526D4
                move.l  (a1,d0.w),d1                        ; 526D8
                lea.l   TfmxBase(pc),a1                      ; 526DC
                add.l   a1,d1                               ; 526E0
                lea.l   .526EA(pc),a1                      ; 526E2
                move.l  d1,$2(a1)                           ; 526E6
.526EA:
                jmp     ($0).l                              ; 526EA
; PatternNext - advance the pattern position and fetch again
PatternNext:
                addi.w  #$1,$68(a0)                         ; 526F0
                bra.w   PatternStep                             ; 526F6
; PatternAdvance - advance the pattern position and stop for this tick
PatternAdvance:
                addi.w  #$1,$68(a0)                         ; 526FA
                rts                                         ; 52700
Pat_End:
                move.w  $4(a5),d0                           ; 52702
                cmp.w   $2(a5),d0                           ; 52706
                bne.w   .52718                             ; 5270A
                move.w  $0(a5),$4(a5)                       ; 5270E
                bra.w   .5271E                             ; 52714
.52718:
                addi.w  #$1,$4(a5)                          ; 52718
.5271E:
                bsr.w   TfmxReadTrackStep                             ; 5271E
                move.w  #$1,$A(a6)                          ; 52722
                rts                                         ; 52728
Pat_Loop:
                tst.b   $4A(a0)                             ; 5272A
                beq.w   .52746                             ; 5272E
                cmpi.b  #$FF,$4A(a0)                        ; 52732
                beq.w   .52750                             ; 52738
                subi.b  #$1,$4A(a0)                         ; 5273C
                bra.w   .5275C                             ; 52742
.52746:
                move.b  #$FF,$4A(a0)                        ; 52746
                bra.w   PatternNext                             ; 5274C
.52750:
                move.b  $29(a6),d0                          ; 52750
                subi.b  #$1,d0                              ; 52754
                move.b  d0,$4A(a0)                          ; 52758
.5275C:
                move.w  $2A(a6),$68(a0)                     ; 5275C
                bra.w   PatternStep                             ; 52762
Pat_Cont:
                move.b  $29(a6),d0                          ; 52766
                andi.w  #$7F,d0                             ; 5276A
                move.b  d0,$48(a0)                          ; 5276E
                asl.w   #$2,d0                              ; 52772
                movea.l a4,a1                               ; 52774
                adda.l  #$400,a1                            ; 52776
                move.l  (a1,d0.w),d0                        ; 5277C
                add.l   a4,d0                               ; 52780
                move.l  d0,$28(a5)                          ; 52782
                move.w  $2A(a6),$68(a0)                     ; 52786
                bra.w   PatternStep                             ; 5278C
Pat_Wait:
                move.b  $29(a6),$6B(a0)                     ; 52790
                bra.w   PatternAdvance                             ; 52796
Pat_Stop:
                move.b  #$FF,$48(a0)                        ; 5279A
                rts                                         ; 527A0
Pat_KeyUp:
                move.l  $28(a6),d0                          ; 527A2
                tst.w   $8(a0)                              ; 527A6
                bne.w   .527B2                             ; 527AA
                bsr.w   TfmxNote                             ; 527AE
.527B2:
                bra.w   PatternNext                             ; 527B2
PatternCmds:
                dc.l    Pat_End-TfmxBase
                dc.l    Pat_Loop-TfmxBase
                dc.l    Pat_Cont-TfmxBase
                dc.l    Pat_Wait-TfmxBase
                dc.l    Pat_Stop-TfmxBase
                dc.l    Pat_KeyUp-TfmxBase
; TfmxMacros - run the macro, vibrato, portamento and envelope for all four channels
TfmxMacros:
                lea.l   TfmxVars(pc),a6                      ; 527CE
                lea.l   TfmxChannels(pc),a5                      ; 527D2
                lea.l   ($DFF0A0).l,a4                      ; 527D6
                bsr.w   .52810                             ; 527DC
                adda.l  #$4,a5                              ; 527E0
                adda.l  #$10,a4                             ; 527E6
                bsr.w   .52810                             ; 527EC
                adda.l  #$4,a5                              ; 527F0
                adda.l  #$10,a4                             ; 527F6
                bsr.w   .52810                             ; 527FC
                adda.l  #$4,a5                              ; 52800
                adda.l  #$10,a4                             ; 52806
                bra.w   .52810                             ; 5280C
.52810:
                tst.w   $2(a5)                              ; 52810
                beq.w   .5281C                             ; 52814
                bpl.w   .52828                             ; 52818
.5281C:
                bsr.w   TfmxVibrato                             ; 5281C
                bsr.w   TfmxPortamento                             ; 52820
                bsr.w   TfmxEnvelope                             ; 52824
.52828:
                bsr.w   TfmxMacroChannel                             ; 52828
; TfmxRts - shared rts for early exits
TfmxRts:
                rts                                         ; 5282C
; TfmxMacroChannel - one channel of macro playback (a5 channel, a4 Paula registers)
TfmxMacroChannel:
                tst.w   $2(a5)                              ; 5282E
                beq.w   TfmxRts                             ; 52832
                bmi.w   MacroWait                             ; 52836
                clr.w   $40(a5)                             ; 5283A
                clr.w   $42(a5)                             ; 5283E
                move.w  #$FFFF,$2(a5)                       ; 52842
                move.w  #$FFFF,$62(a5)                      ; 52848
; MacroWait - count down a macro wait before running the next step
MacroWait:
                tst.w   $42(a5)                             ; 5284E
                beq.w   MacroStep                             ; 52852
                subi.w  #$1,$42(a5)                         ; 52856
                rts                                         ; 5285C
; MacroStep - fetch the next macro command and jump through MacroCmds
MacroStep:
                movea.l $30(a5),a0                          ; 5285E
                move.w  $40(a5),d0                          ; 52862
                asl.w   #$2,d0                              ; 52866
                move.l  (a0,d0.w),$28(a6)                   ; 52868
                move.b  $28(a6),d0                          ; 5286E
                andi.w  #$FF,d0                             ; 52872
                cmp.w   #$15,d0                             ; 52876
                bcc.w   MacroAdvance                             ; 5287A
                asl.w   #$2,d0                              ; 5287E
                lea.l   MacroCmds(pc),a0                      ; 52880
                move.l  (a0,d0.w),d1                        ; 52884
                lea.l   TfmxBase(pc),a0                      ; 52888
                add.l   a0,d1                               ; 5288C
                lea.l   .52896(pc),a0                      ; 5288E
                move.l  d1,$2(a0)                           ; 52892
.52896:
                jmp     ($0).l                              ; 52896
; MacroAdvance - advance the macro position and stop for this tick
MacroAdvance:
                addi.w  #$1,$40(a5)                         ; 5289C
                rts                                         ; 528A2
; MacroNext - advance the macro position and run the next command now
MacroNext:
                addi.w  #$1,$40(a5)                         ; 528A4
                bra.w   MacroWait                             ; 528AA
Mac_DmaOffReset:
                move.w  $52(a5),($DFF096).l                 ; 528AE
                clr.b   $70(a5)                             ; 528B6
                clr.b   $92(a5)                             ; 528BA
                clr.w   $C0(a5)                             ; 528BE
                bra.w   MacroNext                             ; 528C2
Mac_DmaOn:
                move.w  $50(a5),($DFF096).l                 ; 528C6
                bra.w   MacroNext                             ; 528CE
Mac_SetBegin:
                move.l  $28(a6),d0                          ; 528D2
                andi.l  #$FFFFFF,d0                         ; 528D6
                add.l   $4(a6),d0                           ; 528DC
                move.l  d0,$B0(a5)                          ; 528E0
                move.l  d0,$0(a4)                           ; 528E4
                bra.w   MacroNext                             ; 528E8
Mac_SetLen:
                move.w  $2A(a6),$D0(a5)                     ; 528EC
                move.w  $2A(a6),$4(a4)                      ; 528F2
                bra.w   MacroNext                             ; 528F8
Mac_Wait:
                move.w  $2A(a6),$42(a5)                     ; 528FC
                bra.w   MacroAdvance                             ; 52902
Mac_Loop:
                tst.b   $62(a5)                             ; 52906
                beq.w   .52922                             ; 5290A
                cmpi.b  #$FF,$62(a5)                        ; 5290E
                beq.w   .5292C                             ; 52914
                subi.b  #$1,$62(a5)                         ; 52918
                bra.w   .52938                             ; 5291E
.52922:
                move.b  #$FF,$62(a5)                        ; 52922
                bra.w   MacroAdvance                             ; 52928
.5292C:
                move.b  $29(a6),d0                          ; 5292C
                subi.b  #$1,d0                              ; 52930
                move.b  d0,$62(a5)                          ; 52934
.52938:
                move.w  $2A(a6),$40(a5)                     ; 52938
                bra.w   MacroStep                             ; 5293E
Mac_Cont:
                move.b  $29(a6),d0                          ; 52942
                andi.l  #$FF,d0                             ; 52946
                movea.l $0(a6),a0                           ; 5294C
                asl.w   #$2,d0                              ; 52950
                adda.l  d0,a0                               ; 52952
                movea.l $600(a0),a0                         ; 52954
                add.l   $0(a6),d0                           ; 52958
                move.l  d0,$30(a5)                          ; 5295C
                move.w  $2A(a6),$40(a5)                     ; 52960
                clr.w   $42(a5)                             ; 52966
                move.w  #$FFFF,$2(a5)                       ; 5296A
                move.w  #$FFFF,$62(a5)                      ; 52970
                bra.w   TfmxMacroChannel                             ; 52976
Mac_Stop:
                clr.w   $2(a5)                              ; 5297A
                rts                                         ; 5297E
Mac_AddNote:
                move.b  $29(a6),d0                          ; 52980
                add.b   $11(a5),d0                          ; 52984
                andi.w  #$FF,d0                             ; 52988
                asl.w   #$1,d0                              ; 5298C
                lea.l   TfmxPeriods(pc),a0                      ; 5298E
                move.w  $22(a5),d1                          ; 52992
                ext.w   d1                                  ; 52996
                move.w  (a0,d0.w),d0                        ; 52998
                add.w   d1,d0                               ; 5299C
                add.w   $2A(a6),d0                          ; 5299E
                move.w  d0,$A0(a5)                          ; 529A2
                tst.w   $C0(a5)                             ; 529A6
                bne.w   MacroAdvance                             ; 529AA
                move.w  d0,$6(a4)                           ; 529AE
                bra.w   MacroAdvance                             ; 529B2
Mac_SetNote:
                move.b  $29(a6),d0                          ; 529B6
                andi.w  #$FF,d0                             ; 529BA
                asl.w   #$1,d0                              ; 529BE
                lea.l   TfmxPeriods(pc),a0                      ; 529C0
                move.w  (a0,d0.w),d0                        ; 529C4
                add.w   $2A(a6),d0                          ; 529C8
                move.w  d0,$A0(a5)                          ; 529CC
                tst.w   $C0(a5)                             ; 529D0
                bne.w   MacroAdvance                             ; 529D4
                move.w  d0,$6(a4)                           ; 529D8
                bra.w   MacroAdvance                             ; 529DC
Mac_Portamento:
                move.b  $29(a6),$82(a5)                     ; 529E0
                move.b  #$1,$83(a5)                         ; 529E6
                move.w  $2A(a6),$C0(a5)                     ; 529EC
                move.w  $A0(a5),$C2(a5)                     ; 529F2
                bra.w   MacroNext                             ; 529F8
Mac_Vibrato:
                move.b  $29(a6),d0                          ; 529FC
                andi.b  #$FE,d0                             ; 52A00
                move.b  d0,$92(a5)                          ; 52A04
                lsr.b   #$1,d0                              ; 52A08
                move.b  d0,$93(a5)                          ; 52A0A
                move.b  $2B(a6),$80(a5)                     ; 52A0E
                move.b  #$1,$81(a5)                         ; 52A14
                tst.w   $C0(a5)                             ; 52A1A
                bne.w   MacroNext                             ; 52A1E
                move.w  $A0(a5),$6(a4)                      ; 52A22
                clr.w   $90(a5)                             ; 52A28
                bra.w   MacroNext                             ; 52A2C
Mac_AddVolume:
                move.w  $20(a5),d0                          ; 52A30
                asl.w   #$1,d0                              ; 52A34
                add.w   $20(a5),d0                          ; 52A36
                add.w   $2A(a6),d0                          ; 52A3A
                move.w  d0,$8(a4)                           ; 52A3E
                move.b  d0,$60(a5)                          ; 52A42
                bra.w   MacroNext                             ; 52A46
Mac_SetVolume:
                move.w  $2A(a6),$8(a4)                      ; 52A4A
                move.b  $2B(a6),$60(a5)                     ; 52A50
                bra.w   MacroNext                             ; 52A56
Mac_Envelope:
                move.b  $2A(a6),$70(a5)                     ; 52A5A
                move.b  $29(a6),$73(a5)                     ; 52A60
                move.b  $2A(a6),$71(a5)                     ; 52A66
                move.b  $2B(a6),$72(a5)                     ; 52A6C
                bra.w   MacroNext                             ; 52A72
Mac_LoopKeyUp:
                bra.w   MacroAdvance                             ; 52A76
Mac_AddBegin:
                move.w  $2A(a6),d0                          ; 52A7A
                ext.l   d0                                  ; 52A7E
                move.l  $B0(a5),d1                          ; 52A80
                add.l   d0,d1                               ; 52A84
                move.l  d1,$B0(a5)                          ; 52A86
                move.l  d1,$0(a4)                           ; 52A8A
                bra.w   MacroNext                             ; 52A8E
Mac_AddLen:
                move.w  $2A(a6),d0                          ; 52A92
                move.w  $D0(a5),d1                          ; 52A96
                add.w   d0,d1                               ; 52A9A
                move.w  d1,$D0(a5)                          ; 52A9C
                move.w  d1,$4(a4)                           ; 52AA0
                bra.w   MacroNext                             ; 52AA4
Mac_Reset:
                clr.b   $70(a5)                             ; 52AA8
                clr.b   $92(a5)                             ; 52AAC
                clr.w   $C0(a5)                             ; 52AB0
                bra.w   MacroNext                             ; 52AB4
Mac_DmaOff:
                move.w  $52(a5),($DFF096).l                 ; 52AB8
                bra.w   MacroNext                             ; 52AC0
Mac_End:
                clr.w   $2(a5)                              ; 52AC4
                rts                                         ; 52AC8
MacroCmds:
                dc.l    Mac_DmaOffReset-TfmxBase
                dc.l    Mac_DmaOn-TfmxBase
                dc.l    Mac_SetBegin-TfmxBase
                dc.l    Mac_SetLen-TfmxBase
                dc.l    Mac_Wait-TfmxBase
                dc.l    Mac_Loop-TfmxBase
                dc.l    Mac_Cont-TfmxBase
                dc.l    Mac_Stop-TfmxBase
                dc.l    Mac_AddNote-TfmxBase
                dc.l    Mac_SetNote-TfmxBase
                dc.l    Mac_Reset-TfmxBase
                dc.l    Mac_Portamento-TfmxBase
                dc.l    Mac_Vibrato-TfmxBase
                dc.l    Mac_AddVolume-TfmxBase
                dc.l    Mac_SetVolume-TfmxBase
                dc.l    Mac_Envelope-TfmxBase
                dc.l    Mac_LoopKeyUp-TfmxBase
                dc.l    Mac_AddBegin-TfmxBase
                dc.l    Mac_AddLen-TfmxBase
                dc.l    Mac_DmaOff-TfmxBase
                dc.l    Mac_End-TfmxBase
; TfmxVibrato - vibrato: add delta $80 to offset $90 each tick, negate the delta every $92 ticks
TfmxVibrato:
                tst.b   $92(a5)                             ; 52B1E
                beq.w   TfmxRts                             ; 52B22
                move.b  $80(a5),d0                          ; 52B26
                ext.w   d0                                  ; 52B2A
                add.w   d0,$90(a5)                          ; 52B2C
                move.w  $90(a5),d0                          ; 52B30
                add.w   $A0(a5),d0                          ; 52B34
                tst.w   $C0(a5)                             ; 52B38
                bne.w   .52B44                             ; 52B3C
                move.w  d0,$6(a4)                           ; 52B40
.52B44:
                subi.b  #$1,$93(a5)                         ; 52B44
                bne.w   TfmxRts                             ; 52B4A
                move.b  $92(a5),$93(a5)                     ; 52B4E
                eori.b  #$FF,$80(a5)                        ; 52B54
                addi.b  #$1,$80(a5)                         ; 52B5A
                rts                                         ; 52B60
; TfmxPortamento - portamento: slide the period from $A0 towards the target $C2
TfmxPortamento:
                tst.w   $C0(a5)                             ; 52B62
                beq.w   TfmxRts                             ; 52B66
                subi.b  #$1,$83(a5)                         ; 52B6A
                bne.w   TfmxRts                             ; 52B70
                move.b  $82(a5),$83(a5)                     ; 52B74
                move.w  $A0(a5),d1                          ; 52B7A
                move.w  $C2(a5),d0                          ; 52B7E
                cmp.w   d1,d0                               ; 52B82
                beq.w   TfmxRts                             ; 52B84
                bcs.w   .52BAC                             ; 52B88
                sub.w   $C0(a5),d0                          ; 52B8C
                cmp.w   d1,d0                               ; 52B90
                beq.w   .52B9A                             ; 52B92
                bcc.w   .52BA2                             ; 52B96
.52B9A:
                clr.w   $C0(a5)                             ; 52B9A
                move.w  $A0(a5),d0                          ; 52B9E
.52BA2:
                move.w  d0,$C2(a5)                          ; 52BA2
                move.w  d0,$6(a4)                           ; 52BA6
                rts                                         ; 52BAA
.52BAC:
                add.w   $C0(a5),d0                          ; 52BAC
                cmp.w   d1,d0                               ; 52BB0
                beq.w   .52B9A                             ; 52BB2
                bcc.w   .52B9A                             ; 52BB6
                bra.w   .52BA2                             ; 52BBA
; TfmxEnvelope - envelope: every $70 ticks step volume $60 by $73 towards $72, then stop
TfmxEnvelope:
                tst.b   $70(a5)                             ; 52BBE
                beq.w   TfmxRts                             ; 52BC2
                tst.b   $71(a5)                             ; 52BC6
                beq.w   .52BD6                             ; 52BCA
                subi.b  #$1,$71(a5)                         ; 52BCE
                rts                                         ; 52BD4
.52BD6:
                move.b  $70(a5),$71(a5)                     ; 52BD6
                move.b  $72(a5),d0                          ; 52BDC
                cmp.b   $60(a5),d0                          ; 52BE0
                bcc.w   .52C0E                             ; 52BE4
                move.b  $73(a5),d1                          ; 52BE8
                sub.b   d1,$60(a5)                          ; 52BEC
                cmp.b   $60(a5),d0                          ; 52BF0
                bpl.w   .52BFC                             ; 52BF4
                bcs.w   .52C1E                             ; 52BF8
.52BFC:
                move.b  $72(a5),d0                          ; 52BFC
                andi.w  #$FF,d0                             ; 52C00
                move.w  d0,$8(a4)                           ; 52C04
                clr.b   $70(a5)                             ; 52C08
                rts                                         ; 52C0C
.52C0E:
                move.b  $73(a5),d1                          ; 52C0E
                add.b   d1,$60(a5)                          ; 52C12
                cmp.b   $60(a5),d0                          ; 52C16
                bcs.w   .52BFC                             ; 52C1A
.52C1E:
                move.b  $60(a5),d0                          ; 52C1E
                andi.w  #$FF,d0                             ; 52C22
                move.w  d0,$8(a4)                           ; 52C26
                rts                                         ; 52C2A
TfmxNote:
                movem.l d0-d7/a0-a7,-(a7)                   ; 52C2C
                lea.l   TfmxVars(pc),a6                      ; 52C30
                lea.l   TfmxChannels(pc),a5                      ; 52C34
                move.w  d0,d1                               ; 52C38
                ror.w   #$8,d1                              ; 52C3A
                move.w  d1,d2                               ; 52C3C
                andi.w  #$3,d1                              ; 52C3E
                asl.w   #$2,d1                              ; 52C42
                adda.w  d1,a5                               ; 52C44
                cmp.l   #$30000000,d0                       ; 52C46
                bcs.w   .52C5E                             ; 52C4C
                clr.b   $62(a5)                             ; 52C50
                move.w  #$FFFF,$2(a5)                       ; 52C54
                bra.w   .52C9C                             ; 52C5A
.52C5E:
                move.b  d0,$23(a5)                          ; 52C5E
                ror.w   #$4,d2                              ; 52C62
                andi.w  #$F,d2                              ; 52C64
                move.b  d2,$21(a5)                          ; 52C68
                swap    d0                                  ; 52C6C
                move.b  d0,$13(a5)                          ; 52C6E
                moveq   #0,d2                               ; 52C72
                move.b  d0,d2                               ; 52C74
                ror.w   #$8,d0                              ; 52C76
                move.b  d0,$11(a5)                          ; 52C78
                movea.l $0(a6),a0                           ; 52C7C
                asl.w   #$2,d2                              ; 52C80
                adda.l  d2,a0                               ; 52C82
                movea.l $600(a0),a1                         ; 52C84
                adda.l  $0(a6),a1                           ; 52C88
                move.l  a1,$30(a5)                          ; 52C8C
                move.w  #$1,$0(a5)                          ; 52C90
                move.w  #$1,$2(a5)                          ; 52C96
.52C9C:
                movem.l (a7)+,d0-d7/a0-a7                   ; 52C9C
                rts                                         ; 52CA0
TfmxChannelOff:
                movem.l a5,-(a7)                            ; 52CA2
                lea.l   TfmxChannels(pc),a5                      ; 52CA6
                andi.w  #$3,d0                              ; 52CAA
                asl.w   #$2,d0                              ; 52CAE
                adda.w  d0,a5                               ; 52CB0
                move.w  $52(a5),($DFF096).l                 ; 52CB2
                clr.w   $2(a5)                              ; 52CBA
                movem.l (a7)+,a5                            ; 52CBE
                rts                                         ; 52CC2
Tfmx_StartSong:
                move.l  a6,-(a7)                            ; 52CC4
                lea.l   TfmxVars(pc),a6                      ; 52CC6
                move.w  d0,$C(a6)                           ; 52CCA
                movea.l (a7)+,a6                            ; 52CCE
                rts                                         ; 52CD0
Tfmx_SongStart:
                bsr.w   TfmxStop                             ; 52CD2
                lea.l   TfmxTrack(pc),a5                      ; 52CD6
                movea.l $0(a6),a4                           ; 52CDA
                move.w  $C(a6),d0                           ; 52CDE
                andi.l  #$1F,d0                             ; 52CE2
                asl.l   #$1,d0                              ; 52CE8
                adda.l  d0,a4                               ; 52CEA
                move.w  $100(a4),$4(a5)                     ; 52CEC
                move.w  $100(a4),$0(a5)                     ; 52CF2
                move.w  $140(a4),$2(a5)                     ; 52CF8
                move.w  $180(a4),$6(a5)                     ; 52CFE
                movea.l $0(a6),a4                           ; 52D04
                bsr.w   TfmxReadTrackStep                             ; 52D08
                clr.w   $A(a6)                              ; 52D0C
                move.w  #$1,$2E(a6)                         ; 52D10
                clr.w   $2C(a6)                             ; 52D16
                bset.b  #$1,($BFE001).l                     ; 52D1A
                move.w  #$FFFF,$C(a6)                       ; 52D22
                rts                                         ; 52D28
TfmxStop:
                move.l  a6,-(a7)                            ; 52D2A
                lea.l   TfmxVars(pc),a6                      ; 52D2C
                clr.w   $2E(a6)                             ; 52D30
                clr.w   ($DFF0A8).l                         ; 52D34
                clr.w   ($DFF0B8).l                         ; 52D3A
                clr.w   ($DFF0C8).l                         ; 52D40
                clr.w   ($DFF0D8).l                         ; 52D46
                move.w  #$F,($DFF096).l                     ; 52D4C
                lea.l   TfmxChannels(pc),a6                      ; 52D54
                clr.w   $2(a6)                              ; 52D58
                clr.w   $6(a6)                              ; 52D5C
                clr.w   $A(a6)                              ; 52D60
                clr.w   $E(a6)                              ; 52D64
                movea.l (a7)+,a6                            ; 52D68
                rts                                         ; 52D6A
Tfmx_Init:
                move.l  a6,-(a7)                            ; 52D6C
                lea.l   TfmxVars(pc),a6                      ; 52D6E
                move.l  d0,$0(a6)                           ; 52D72
                move.l  d1,$4(a6)                           ; 52D76
                move.w  #$1,$8(a6)                          ; 52D7A
                movea.l (a7)+,a6                            ; 52D80
                rts                                         ; 52D82
TfmxIrqOn:
                movem.l a0/a6,-(a7)                         ; 52D84
                lea.l   TfmxVars(pc),a6                      ; 52D88
                move.l  ($6C).l,$10(a6)                     ; 52D8C
                lea.l   TfmxOldIntJmp(pc),a0                      ; 52D94
                move.l  $10(a6),$2(a0)                      ; 52D98
                lea.l   TfmxLevel3Int(pc),a0                      ; 52D9E
                move.l  a0,($6C).l                          ; 52DA2
                movem.l (a7)+,a0/a6                         ; 52DA8
                rts                                         ; 52DAC
TfmxIrqOff:
                move.l  a6,-(a7)                            ; 52DAE
                lea.l   TfmxVars(pc),a6                      ; 52DB0
                move.l  $10(a6),($6C).l                     ; 52DB4
                movea.l (a7)+,a6                            ; 52DBC
                rts                                         ; 52DBE
TfmxCommand:
                subq.w  #$1,d0                              ; 52DC0
                beq.w   .52E12                             ; 52DC2
.52DC6:
                cmpi.b  #$22,(a0)+                          ; 52DC6
                bne.w   .52DC6                             ; 52DCA
                lea.l   TfmxVars(pc),a6                      ; 52DCE
                bsr.w   TfmxParsePaths                             ; 52DD2
                tst.l   d0                                  ; 52DD6
                beq.w   .52E12                             ; 52DD8
                move.w  #$0,d0                              ; 52DDC
                bsr.w   Tfmx_StartSong                             ; 52DE0
                bsr.w   TfmxIrqOn                             ; 52DE4
                move.w  #$1,$8(a6)                          ; 52DE8
.52DEE:
                btst.b  #$6,($BFE001).l                     ; 52DEE
                beq.w   .52DEE                             ; 52DF6
                btst.b  #$7,($BFE001).l                     ; 52DFA
                bne.w   .52DEE                             ; 52E02
                bsr.w   TfmxIrqOff                             ; 52E06
                bsr.w   TfmxStop                             ; 52E0A
                bsr.w   TfmxFreeFiles                             ; 52E0E
.52E12:
                clr.l   d0                                  ; 52E12
                rts                                         ; 52E14
TfmxLevel3Int:
                dc.w    $48E7,$FFFF,$3039,$00DF,$F01E,$0240,$0020,$6700
                dc.w    $0006,$6100,$F51A,$4CDF,$FFFF
TfmxOldIntJmp:
                dc.w    $4EF9,$0000,$0000
; TfmxParsePaths - find the mdat./smpl. names on the command line and build both paths
TfmxParsePaths:
                lea.l   MdatPath(pc),a1                      ; 52E36
                lea.l   SmplPath(pc),a2                      ; 52E3A
.52E3E:
                cmpi.b  #$6D,(a0)                           ; 52E3E
                bne.w   .52E7C                             ; 52E42
                cmpi.b  #$64,$1(a0)                         ; 52E46
                bne.w   .52E7C                             ; 52E4C
                cmpi.b  #$61,$2(a0)                         ; 52E50
                bne.w   .52E7C                             ; 52E56
                cmpi.b  #$74,$3(a0)                         ; 52E5A
                bne.w   .52E7C                             ; 52E60
                move.b  (a0)+,(a1)+                         ; 52E64
                move.b  (a0)+,(a1)+                         ; 52E66
                move.b  (a0)+,(a1)+                         ; 52E68
                move.b  (a0)+,(a1)+                         ; 52E6A
                move.b  #$73,(a2)+                          ; 52E6C
                move.b  #$6D,(a2)+                          ; 52E70
                move.b  #$70,(a2)+                          ; 52E74
                move.b  #$6C,(a2)+                          ; 52E78
.52E7C:
                cmpi.b  #$22,(a0)                           ; 52E7C
                beq.w   .52E8C                             ; 52E80
                move.b  (a0),(a1)+                          ; 52E84
                move.b  (a0)+,(a2)+                         ; 52E86
                bra.w   .52E3E                             ; 52E88
.52E8C:
                clr.b   (a1)+                               ; 52E8C
                clr.b   (a2)+                               ; 52E8E
                lea.l   DosName(pc),a1                      ; 52E90
                move.l  a6,-(a7)                            ; 52E94
                movea.l ($4).l,a6                           ; 52E96
                jsr     -$198(a6)                           ; 52E9C
                movea.l (a7)+,a6                            ; 52EA0
                tst.l   d0                                  ; 52EA2
                beq.w   .53096                             ; 52EA4
                move.l  d0,$14(a6)                          ; 52EA8
                lea.l   SmplPath(pc),a0                      ; 52EAC
                move.l  a0,d1                               ; 52EB0
                move.l  #$FFFFFFFE,d2                       ; 52EB2
                movem.l a5-a6,-(a7)                         ; 52EB8
                lea.l   TfmxVars(pc),a5                      ; 52EBC
                movea.l $14(a5),a6                          ; 52EC0
                jsr     -$54(a6)                            ; 52EC4
                movem.l (a7)+,a5-a6                         ; 52EC8
                move.l  d0,$1C(a6)                          ; 52ECC
                move.l  d0,d1                               ; 52ED0
                lea.l   TfmxFib(pc),a0                      ; 52ED2
                move.l  a0,d2                               ; 52ED6
                movem.l a5-a6,-(a7)                         ; 52ED8
                lea.l   TfmxVars(pc),a5                      ; 52EDC
                movea.l $14(a5),a6                          ; 52EE0
                jsr     -$66(a6)                            ; 52EE4
                movem.l (a7)+,a5-a6                         ; 52EE8
                lea.l   TfmxFib(pc),a0                      ; 52EEC
                move.l  $7C(a0),$20(a6)                     ; 52EF0
                move.l  $1C(a6),d1                          ; 52EF6
                movem.l a5-a6,-(a7)                         ; 52EFA
                lea.l   TfmxVars(pc),a5                      ; 52EFE
                movea.l $14(a5),a6                          ; 52F02
                jsr     -$5A(a6)                            ; 52F06
                movem.l (a7)+,a5-a6                         ; 52F0A
                move.l  $20(a6),d0                          ; 52F0E
                move.l  #$2,d1                              ; 52F12
                move.l  a6,-(a7)                            ; 52F18
                movea.l ($4).l,a6                           ; 52F1A
                jsr     -$C6(a6)                            ; 52F20
                movea.l (a7)+,a6                            ; 52F24
                tst.l   d0                                  ; 52F26
                beq.w   .53096                             ; 52F28
                move.l  d0,$4(a6)                           ; 52F2C
                lea.l   SmplPath(pc),a0                      ; 52F30
                move.l  a0,d1                               ; 52F34
                move.l  #$3ED,d2                            ; 52F36
                movem.l a5-a6,-(a7)                         ; 52F3C
                lea.l   TfmxVars(pc),a5                      ; 52F40
                movea.l $14(a5),a6                          ; 52F44
                jsr     -$1E(a6)                            ; 52F48
                movem.l (a7)+,a5-a6                         ; 52F4C
                tst.l   d0                                  ; 52F50
                beq.w   .53096                             ; 52F52
                move.l  d0,$18(a6)                          ; 52F56
                move.l  d0,d1                               ; 52F5A
                move.l  $4(a6),d2                           ; 52F5C
                move.l  $20(a6),d3                          ; 52F60
                movem.l a5-a6,-(a7)                         ; 52F64
                lea.l   TfmxVars(pc),a5                      ; 52F68
                movea.l $14(a5),a6                          ; 52F6C
                jsr     -$2A(a6)                            ; 52F70
                movem.l (a7)+,a5-a6                         ; 52F74
                move.l  $18(a6),d1                          ; 52F78
                movem.l a5-a6,-(a7)                         ; 52F7C
                lea.l   TfmxVars(pc),a5                      ; 52F80
                movea.l $14(a5),a6                          ; 52F84
                jsr     -$24(a6)                            ; 52F88
                movem.l (a7)+,a5-a6                         ; 52F8C
                lea.l   MdatPath(pc),a0                      ; 52F90
                move.l  a0,d1                               ; 52F94
                move.l  #$FFFFFFFE,d2                       ; 52F96
                movem.l a5-a6,-(a7)                         ; 52F9C
                lea.l   TfmxVars(pc),a5                      ; 52FA0
                movea.l $14(a5),a6                          ; 52FA4
                jsr     -$54(a6)                            ; 52FA8
                movem.l (a7)+,a5-a6                         ; 52FAC
                move.l  d0,$1C(a6)                          ; 52FB0
                move.l  d0,d1                               ; 52FB4
                lea.l   TfmxFib(pc),a0                      ; 52FB6
                move.l  a0,d2                               ; 52FBA
                movem.l a5-a6,-(a7)                         ; 52FBC
                lea.l   TfmxVars(pc),a5                      ; 52FC0
                movea.l $14(a5),a6                          ; 52FC4
                jsr     -$66(a6)                            ; 52FC8
                movem.l (a7)+,a5-a6                         ; 52FCC
                lea.l   TfmxFib(pc),a0                      ; 52FD0
                move.l  $7C(a0),$24(a6)                     ; 52FD4
                move.l  $1C(a6),d1                          ; 52FDA
                movem.l a5-a6,-(a7)                         ; 52FDE
                lea.l   TfmxVars(pc),a5                      ; 52FE2
                movea.l $14(a5),a6                          ; 52FE6
                jsr     -$5A(a6)                            ; 52FEA
                movem.l (a7)+,a5-a6                         ; 52FEE
                move.l  $24(a6),d0                          ; 52FF2
                move.l  #$2,d1                              ; 52FF6
                move.l  a6,-(a7)                            ; 52FFC
                movea.l ($4).l,a6                           ; 52FFE
                jsr     -$C6(a6)                            ; 53004
                movea.l (a7)+,a6                            ; 53008
                tst.l   d0                                  ; 5300A
                beq.w   .53096                             ; 5300C
                move.l  d0,$0(a6)                           ; 53010
                lea.l   MdatPath(pc),a0                      ; 53014
                move.l  a0,d1                               ; 53018
                move.l  #$3ED,d2                            ; 5301A
                movem.l a5-a6,-(a7)                         ; 53020
                lea.l   TfmxVars(pc),a5                      ; 53024
                movea.l $14(a5),a6                          ; 53028
                jsr     -$1E(a6)                            ; 5302C
                movem.l (a7)+,a5-a6                         ; 53030
                tst.l   d0                                  ; 53034
                beq.w   .53096                             ; 53036
                move.l  d0,$18(a6)                          ; 5303A
                move.l  d0,d1                               ; 5303E
                move.l  $0(a6),d2                           ; 53040
                move.l  $24(a6),d3                          ; 53044
                movem.l a5-a6,-(a7)                         ; 53048
                lea.l   TfmxVars(pc),a5                      ; 5304C
                movea.l $14(a5),a6                          ; 53050
                jsr     -$2A(a6)                            ; 53054
                movem.l (a7)+,a5-a6                         ; 53058
                move.l  $18(a6),d1                          ; 5305C
                movem.l a5-a6,-(a7)                         ; 53060
                lea.l   TfmxVars(pc),a5                      ; 53064
                movea.l $14(a5),a6                          ; 53068
                jsr     -$24(a6)                            ; 5306C
                movem.l (a7)+,a5-a6                         ; 53070
                movea.l $14(a6),a1                          ; 53074
                move.l  a6,-(a7)                            ; 53078
                movea.l ($4).l,a6                           ; 5307A
                jsr     -$19E(a6)                           ; 53080
                movea.l (a7)+,a6                            ; 53084
                bsr.w   TfmxFlash                             ; 53086
                move.w  #$1,$8(a6)                          ; 5308A
                move.l  #$1,d0                              ; 53090
.53096:
                rts                                         ; 53096
; TfmxFreeFiles - FreeMem the loaded mdat and smpl files
TfmxFreeFiles:
                movea.l $4(a6),a1                           ; 53098
                move.l  $20(a6),d0                          ; 5309C
                move.l  a6,-(a7)                            ; 530A0
                movea.l ($4).l,a6                           ; 530A2
                jsr     -$D2(a6)                            ; 530A8
                movea.l (a7)+,a6                            ; 530AC
                movea.l $0(a6),a1                           ; 530AE
                move.l  $24(a6),d0                          ; 530B2
                move.l  a6,-(a7)                            ; 530B6
                movea.l ($4).l,a6                           ; 530B8
                jsr     -$D2(a6)                            ; 530BE
                movea.l (a7)+,a6                            ; 530C2
                rts                                         ; 530C4
; TfmxFlash - flash COLOR00 through every colour (load done)
TfmxFlash:
                move.l  d0,-(a7)                            ; 530C6
                move.w  #$FFF,d0                            ; 530C8
.530CC:
                move.w  d0,($DFF180).l                      ; 530CC
                dbra    d0,.530CC                          ; 530D2
                move.l  (a7)+,d0                            ; 530D6
                rts                                         ; 530D8
                dc.w    $4348,$6669,$656C,$6430
TfmxVars:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$FFFF,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$4348,$6669,$656C,$6431
TfmxChannels:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $8201,$0001,$8202,$0002,$8204,$0004,$8208,$0008
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $4348,$6669,$656C,$6432
TfmxTrack:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000
TfmxPeriods:
                dc.w    $06AE,$064E,$05F4,$059E,$054D,$0501,$04B9,$0475
                dc.w    $0435,$03F9,$03C0,$038C,$0358,$032A,$02FC,$02D0
                dc.w    $02A8,$0282,$025E,$023B,$021B,$01FD,$01E0,$01C6
                dc.w    $01AC,$0194,$017D,$0168,$0154,$0140,$012F,$011E
                dc.w    $010E,$00FE,$00F0,$00E3,$00D6,$00CA,$00BF,$00B4
                dc.w    $00AA,$00A0,$0097,$008F,$0087,$007F,$0078,$0071
                dc.w    $0000
; TfmxFib - FileInfoBlock for Lock/Examine (fib_Size at $7C gives the file length)
TfmxFib:
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
DosName:
                dc.w    $646F,$732E,$6C69,$6272,$6172,$7900
SmplPath:
                dc.w    $6466,$313A,$736D,$706C,$2E72,$7479,$7065,$7469
                dc.w    $746C,$652E,$7063,$6B00,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
MdatPath:
                dc.w    $6466,$313A,$6D64,$6174,$2E72,$7479,$7065,$7469
                dc.w    $746C,$652E,$7063,$6B00,$0000,$0000,$0000,$0000
                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
                dc.l    $000003F2
