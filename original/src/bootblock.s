;==============================================================================
; R-Type (Amiga, Electric Dreams 1989) - Bootblock
;
; Assembles byte-identical to the original (1024 bytes) with:
;   vasmm68k_mot -Fbin -m68000 -no-opt -o bootblock.bin src/bootblock.s
;
; What it does
; ------------
; Kickstart loads the two boot sectors into a buffer and calls this code with
; A6 = ExecBase and A1 = the trackdisk IOStdReq that read the bootblock.
;
;  1. Turns off bitplane/copper DMA and blacks the screen (COLOR00 = 0).
;  2. Grabs the largest block of non-chip memory for the game to use as a
;     track/music cache (e.g. A500 trapdoor "slow" RAM at $C00000):
;       size  = AvailMem(MEMF_FAST|MEMF_LARGEST)
;       addr  = AllocMem(size, MEMF_FAST)       (0 if there is none)
;     MemBase  = addr with the low word cleared (64K aligned, e.g. $C00000)
;     MemLimit = addr + size                    (end of the block)
;  3. Reads $B800 bytes (92 blocks) from disk byte offset $400 (block 2 on)
;     to the fixed address $6EFA0 using trackdisk CMD_READ, then stops the
;     motor (TD_MOTOR, length 0).
;  4. Jumps to the stage-2 loader at $79360 with
;       D0 = MemBase   (0 when there is no fast/slow memory)
;       D1 = MemLimit  (end of that memory)
;     The OS is never returned to.
;
; The $B800 bytes read land at $6EFA0-$7A79F:
;   $6EFA0-$7935F  title picture (5 x $1F40 planes) + font  -> copied to $35FA0
;   $79360-$7A79F  stage-2 loader (see src/stage2.s)
;==============================================================================

; --- Exec ---------------------------------------------------------------------
_LVOAllocMem    equ     -198            ; -$C6
_LVOAvailMem    equ     -216            ; -$D8
_LVODoIO        equ     -456            ; -$1C8
MEMF_CHIP       equ     $00002
MEMF_FAST       equ     $00004
MEMF_LARGEST    equ     $20000

; --- IOStdReq offsets ---------------------------------------------------------
IO_COMMAND      equ     $1C
IO_LENGTH       equ     $24
IO_DATA         equ     $28
IO_OFFSET       equ     $2C
CMD_READ        equ     2
TD_MOTOR        equ     9

; --- Hardware -----------------------------------------------------------------
DMACON          equ     $DFF096
COLOR00         equ     $DFF180

; --- Load parameters ----------------------------------------------------------
BOOT_LOAD_ADDR  equ     $6EFA0          ; destination of the boot read
BOOT_LOAD_LEN   equ     $B800           ; 92 blocks
BOOT_LOAD_OFS   equ     $400            ; starts at block 2
STAGE2_ENTRY    equ     $79360          ; = BOOT_LOAD_ADDR + $A3C0

;==============================================================================
                org     0               ; position independent (PC-relative)

bb_Header:      dc.b    "DOS",0         ; disk type
bb_Checksum:    dc.l    $2C0F49FA       ; bootblock checksum
bb_RootBlock:   dc.l    880             ; standard root block pointer (unused)

;------------------------------------------------------------------------------
bb_Entry:
                move.w  #$0180,DMACON           ; DMA off: bitplanes + copper
                clr.w   COLOR00                 ; black background
                move.l  a1,-(a7)                ; save trackdisk IORequest
                lea     bb_Vars(pc),a5

        ; --- memory configuration for stage 2 -----------------------------
                movea.l ($4).l,a6               ; ExecBase (absolute long form)
                move.l  #MEMF_FAST|MEMF_LARGEST,d1
                jsr     _LVOAvailMem(a6)        ; d0 = largest free fast block
                move.l  d0,bb_MemLimit-bb_Vars(a5)  ; remember its size
                move.l  #MEMF_FAST,d1
                jsr     _LVOAllocMem(a6)        ; allocate all of it -> d0 = addr
                add.l   d0,bb_MemLimit-bb_Vars(a5)  ; limit = addr + size
                clr.w   d0                      ; round address down to 64K
                move.l  d0,(a5)                 ; bb_MemBase

        ; --- read the title picture and stage-2 loader --------------------
                movea.l (a7)+,a1                ; trackdisk IORequest
                move.w  #CMD_READ,IO_COMMAND(a1)
                move.l  #BOOT_LOAD_ADDR,IO_DATA(a1)
                move.l  #BOOT_LOAD_LEN,IO_LENGTH(a1)
                move.l  #BOOT_LOAD_OFS,IO_OFFSET(a1)
                jsr     _LVODoIO(a6)

                move.w  #TD_MOTOR,IO_COMMAND(a1)
                clr.l   IO_LENGTH(a1)           ; length 0 = motor off
                jsr     _LVODoIO(a6)

        ; --- hand over to stage 2 -----------------------------------------
                move.l  0(a5),d0                ; bb_MemBase (coded with a 0 disp)
                move.l  bb_MemLimit-bb_Vars(a5),d1
                jmp     STAGE2_ENTRY

;------------------------------------------------------------------------------
bb_Vars:
bb_MemBase:     dc.l    0               ; fast/slow memory base (64K aligned) or 0
bb_MemLimit:    dc.l    0               ; end of the allocated fast/slow block

                dcb.b   1024-*,0        ; pad to two sectors
