;==============================================================================
; R-Type (Amiga) enhanced - the bootblock of the AmigaDOS (OFS, DOS\0) disk
; (Kickstart 1.3 boots only DOS\0 floppies)
;
; As the original (original/src/bootblock.s), with the OS still running:
;  1. bitplane/copper DMA off, COLOR00 black
;  2. the largest block of fast/slow memory for the game's file cache
;     (AvailMem/AllocMem, MemBase 64K aligned, MemLimit its end)
;  3. the drive booted from: trackdisk.device's units 3..0 are opened in turn
;     (an IORequest on the stack) until one is the boot IORequest's unit (DF0
;     if none is).  Kickstart 1.3 boots only from DF0; 2.0 and later from any
;     drive (the early startup menu).  Every later read (stage 2, the game)
;     uses that drive.
;  4. reads the boot file (the packed title picture + font, then stage 2)
;     with trackdisk CMD_READ: its blocks - stored in one run from block 2 -
;     go to BOOT_RAW, so that they end at $7A7A0 (where the original's boot
;     read ended), then the motor off, and the OFS block headers are
;     squeezed out: the file's bytes moved up to end at $7A7A0
;  5. jumps to stage 2 (STAGE2_ORG) with d0 = MemBase, d1 = MemLimit,
;     d2 = the drive
;
; BOOT_RAW, BOOT_BLOCKS, BOOT_LAST (bytes in its last block) and STAGE2_ORG
; come from the build (build/layout.i).
;==============================================================================
                include "layout.i"

_LVOAllocMem    equ     -198
_LVOAvailMem    equ     -216
_LVODoIO        equ     -456
_LVOOpenDevice  equ     -444
MEMF_FAST       equ     $00004
MEMF_LARGEST    equ     $20000
IO_DEVICE       equ     $14
IO_UNIT         equ     $18
IO_COMMAND      equ     $1C
IO_LENGTH       equ     $24
IO_DATA         equ     $28
IO_OFFSET       equ     $2C
CMD_READ        equ     2
TD_MOTOR        equ     9
DMACON          equ     $DFF096
COLOR00         equ     $DFF180
BOOT_LOAD_OFS   equ     $400            ; block 2
BOOT_END        equ     $7A7A0          ; the boot file ends here

                org     0
                dc.b    "DOS",0         ; OFS
                dc.l    0               ; checksum (the build tool)
                dc.l    880             ; root block

BootEntry:
                move.w  #$0180,DMACON           ; bitplane and copper DMA off
                clr.w   COLOR00
                movea.l a1,a5                   ; the boot IORequest
        ; --- memory for the game's cache, as the original -------------------
                movea.l ($4).l,a6
                move.l  #MEMF_FAST|MEMF_LARGEST,d1
                jsr     _LVOAvailMem(a6)
                move.l  d0,d6                   ; size
                move.l  #MEMF_FAST,d1
                jsr     _LVOAllocMem(a6)        ; -> address (0: none)
                add.l   d0,d6                   ; MemLimit
                clr.w   d0
                move.l  d0,d5                   ; MemBase (64K aligned) or 0
        ; --- the drive booted from (as the GnG enhanced bootblock) ----------
                movea.l IO_UNIT(a5),a3          ; the boot unit
                movea.l IO_DEVICE(a5),a4
                movea.l $A(a4),a4               ; the device's name
                lea     -$30(a7),a7             ; an IORequest
                moveq   #3,d7
.unit:          movea.l a4,a0
                movea.l a7,a1
                move.l  d7,d0
                moveq   #0,d1
                movem.l d5-d7/a3-a5,-(a7)
                jsr     _LVOOpenDevice(a6)
                movem.l (a7)+,d5-d7/a3-a5
                tst.b   d0
                bne.b   .next
                cmpa.l  IO_UNIT(a7),a3          ; the one booted from?
                beq.b   .found
.next:          dbra    d7,.unit
                moveq   #0,d7                   ; none: DF0
.found:         lea     $30(a7),a7
        ; --- read the boot file ---------------------------------------------
                movea.l a5,a1
                move.w  #CMD_READ,IO_COMMAND(a1)
                move.l  #BOOT_RAW,IO_DATA(a1)
                move.l  #BOOT_BLOCKS*512,IO_LENGTH(a1)
                move.l  #BOOT_LOAD_OFS,IO_OFFSET(a1)
                movem.l d5-d7,-(a7)
                jsr     _LVODoIO(a6)
                movea.l a5,a1
                move.w  #TD_MOTOR,IO_COMMAND(a1)
                clr.l   IO_LENGTH(a1)           ; motor off
                jsr     _LVODoIO(a6)
                movem.l (a7)+,d5-d7
        ; --- the block headers out: each block's bytes moved up -------------
                lea     BOOT_RAW+(BOOT_BLOCKS-1)*512+24+BOOT_LAST,a0
                lea     BOOT_END,a1
                move.w  #BOOT_BLOCKS-1,d0
                move.w  #BOOT_LAST,d1
.blk:           subq.w  #1,d1
.cp:            move.b  -(a0),-(a1)
                dbra    d1,.cp
                lea     -24(a0),a0              ; skip the block's header
                move.w  #488,d1
                dbra    d0,.blk
                move.l  d5,d0                   ; MemBase
                move.l  d6,d1                   ; MemLimit
                move.l  d7,d2                   ; the drive
                jmp     STAGE2_ORG

                ifgt    *-1024
                fail    "the bootblock is over 1024 bytes"
                endc
                dcb.b   1024-*,0
