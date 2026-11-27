;==============================================================================
; Enhanced disk code: included by game.s in place of the original's track
; loader, track cache, ByteKiller decruncher and high-score track code
; ($3C3A-$41B3).  It must not outgrow that space (game.s checks), so that
; every label after it - and so every address the level files use - stays
; where the original has it.
;
; The disk is an ordinary AmigaDOS (FFS) disk.  Every file is stored in one
; piece, so a file is just an offset and a length on the disk, read with the
; 4489_byteloader.  FileTable (filled in by stage 2 from the table the build
; tool writes into it) gives each file id its offset, its length on the disk
; and, for a ZX0-packed file, how far past the destination it is loaded so
; that it can be unpacked in place (forwards).
;
;   FileTable entry (FT_SIZE = 12 bytes):
;     +0  offset on the disk
;     +4  length on the disk
;     +8  0 = stored as it is; else the unpacked length plus the margin
;         the in-place unpacking needs: the packed data is loaded so that it
;         ends there (dest + this), and unpacked to dest
;==============================================================================

; LoadTracksCached - kept as the name the original's callers use.
; LoadFile: d0.w = file id, d2.l = destination.  Every register is kept.
; With extra memory (CacheBase) a packed file is kept there after its first
; read, packed, and later loads unpack it straight from there.
LoadTracksCached:
LoadFile:
                movem.l d0-d7/a0-a6,-(a7)
                lea.l   (FileTable).l,a2
                move.w  d0,d3
                lsl.w   #2,d3                   ; d3 = id * 4: its cache slot
                mulu.w  #FT_SIZE,d0
                adda.w  d0,a2                   ; a2 = the file's entry
                movea.l d2,a3                   ; a3 = destination
                move.l  8(a2),d4                ; packed?
                beq.b   .stored
                lea.l   (a3,d4.l),a4            ; where the packed data goes:
                suba.l  4(a2),a4                ; ending at dest + margin
                tst.l   (CacheBase).l           ; extra memory?
                beq.b   .disk
                lea.l   (FileCache).l,a0
                adda.w  d3,a0                   ; a0 -> its cache slot
                move.l  (a0),d5
                bne.b   .unpack5                ; already there
                move.l  (CacheNext).l,d5
                move.l  d5,d6
                add.l   4(a2),d6
                cmp.l   (CacheLimit).l,d6       ; room for it?
                bhi.b   .disk
                move.l  d5,(a0)                 ; keep it
                move.l  d6,(CacheNext).l
                movea.l d5,a0
                bsr.b   ReadFile
.unpack5:       movea.l d5,a0
                bra.b   .unpack
.disk:          movea.l a4,a0
                bsr.b   ReadFile
                movea.l a4,a0
.unpack:        movea.l a3,a1
                bsr.w   zx0_decompress
                bra.b   .done
.stored:        movea.l a3,a0
                bsr.b   ReadFile
.done:          movem.l (a7)+,d0-d7/a0-a6
                rts

; ReadFile: a2 = file entry, a0 = where to.  Reads the file's bytes as they
; are on the disk.  Tried again until it works; after 8 failures in a row
; COLOR00 turns red while it goes on trying (the drive or the disk).
ReadFile:
                movem.l d0-d7/a0-a6,-(a7)
                moveq   #0,d7                   ; failures
.try:           movem.l d7/a0/a2,-(a7)
                move.l  (a2),d0                 ; offset
                move.l  4(a2),d1                ; length
                bsr.b   ByteLoad
                movem.l (a7)+,d7/a0/a2
                tst.l   d0
                beq.b   .ok
                addq.w  #1,d7
                cmp.w   #8,d7
                bcs.b   .try
                move.w  #$F00,(CUSTOM+$180).l
                bra.b   .try
.ok:            movem.l (a7)+,d0-d7/a0-a6
                rts

; ByteLoad: d0 = offset, d1 = length, a0 = destination, from the boot drive,
; through the MFM buffer at TRACK_BUFFER -> d0 = 0 if it worked.  Uses every
; register (the byteloader's interface).
ByteLoad:
                moveq   #0,d2
                move.w  (BootDrive).l,d2
                lea.l   (TRACK_BUFFER).l,a1
ByteLoader:
                include "byteloader.i"
                even

; Decrunch - the original unpacked level B here; LoadFile now unpacks every
; packed file itself, so this only reports success (d0 = 0) to LoadLevel.
Decrunch:
                moveq   #0,d0
                rts

;------------------------------------------------------------------------------
; High scores: the file FID_HISCORE, one 512-byte block: the table's 100
; longs (HighScores, $190 bytes), then their EOR with $12345678 as a
; checksum.  LoadHighScores copies the first 90 longs back, as the original
; did from track 68, only if the checksum is right.
;------------------------------------------------------------------------------
HS_LONGS        equ     $64
HS_BUF          equ     TRACK_BUFFER+$2F00      ; after the byteloader's MFM buffer

LoadHighScores:
                movem.l d0-d2/a0-a1,-(a7)
                moveq   #FID_HISCORE,d0
                move.l  #HS_BUF,d2
                bsr.w   LoadFile
                lea.l   (HS_BUF).l,a0
                bsr.b   HSChecksum
                cmp.l   (a0),d0                 ; a0 -> the stored checksum
                bne.b   .bad
                lea.l   (HS_BUF).l,a0
                lea.l   (HighScores).l,a1
                moveq   #$59,d1
.copy:          move.l  (a0)+,(a1)+
                dbra    d1,.copy
.bad:           movem.l (a7)+,d0-d2/a0-a1
                rts

; HSChecksum: a0 = 100 longs -> d0 = their EOR ^ $12345678, a0 past them
HSChecksum:
                move.l  #$12345678,d0
                moveq   #HS_LONGS-1,d1
.eor:           move.l  (a0)+,d2
                eor.l   d2,d0
                dbra    d1,.eor
                rts

; SaveHighScores: writes the table back into its block on the disk, unless
; the disk is write-protected.  The track holding the block is read (the
; byteloader leaves it decoded, its 11 sectors in order, at the start of its
; MFM buffer), the block replaced, and the whole track MFM-encoded again
; and written.  The block never moves, so the file system is not touched.
SaveHighScores:
                movem.l d0-d7/a0-a6,-(a7)
                lea.l   (FileTable+FID_HISCORE*FT_SIZE).l,a2
                move.l  (a2),d0                 ; the block's offset on the disk
                divu.w  #$1600,d0               ; d0 = track, high word = offset in it
                move.l  d0,d7
                mulu.w  #$1600,d0               ; the track's start
                moveq   #1,d1                   ; read (a byte of) it: the
                lea.l   (HS_BUF).l,a0           ; whole track ends up decoded
                move.l  d7,-(a7)                ; in TRACK_BUFFER
                bsr.w   ByteLoad
                move.l  (a7)+,d7
                tst.l   d0
                bne.w   .exit                   ; unreadable: leave it
                swap    d7
                lea.l   (TRACK_BUFFER).l,a1
                adda.w  d7,a1                   ; a1 -> the block in it
                lea.l   (HighScores).l,a0
                moveq   #HS_LONGS-1,d1
.put:           move.l  (a0)+,(a1)+
                dbra    d1,.put
                lea.l   (HighScores).l,a0
                bsr.b   HSChecksum
                move.l  d0,(a1)
                swap    d7                      ; d7 = the track
        ; --- MFM-encode the 11 sectors into WRITE_BUF -------------------------
                lea.l   (WRITE_BUF).l,a1
                move.w  #WRITE_GAP/2-1,d0       ; the gap: zero data bits
.gap:           clr.l   (a1)+                   ; (their clock bits are set
                dbra    d0,.gap                 ;  below, as for all data)
                lea.l   (TRACK_BUFFER).l,a3     ; the decoded sectors
                moveq   #0,d6                   ; sector
.sector:        clr.l   (a1)+                   ; two zero bytes,
                move.l  #$44894489,(a1)+        ; then the sync words
                moveq   #-1,d0                  ; info: format $FF, track,
                move.b  d7,d0                   ; sector, sectors to the gap
                lsl.l   #8,d0
                move.b  d6,d0
                lsl.l   #8,d0
                moveq   #11,d1
                sub.b   d6,d1
                move.b  d1,d0
                moveq   #0,d5                   ; header checksum
                bsr.w   PutLong                 ; (one long: odd, even)
                moveq   #3,d4                   ; label: 16 zero bytes,
.lab:           clr.l   (a1)+                   ; odd longs then even longs
                clr.l   (a1)+                   ; (zero data bits: the clock
                dbra    d4,.lab                 ;  bits are set below)
                move.l  d5,d0                   ; header checksum
                bsr.w   PutLong
                movea.l a1,a4                   ; the data checksum goes here
                addq.l  #8,a1
                moveq   #0,d5
                movea.l a1,a5                   ; odd halves
                lea.l   512(a1),a6              ; even halves
                moveq   #127,d4
.data:          move.l  (a3)+,d0
                move.l  d0,d1
                lsr.l   #1,d0
                andi.l  #$55555555,d0
                andi.l  #$55555555,d1
                move.l  d0,(a5)+
                move.l  d1,(a6)+
                eor.l   d0,d5
                eor.l   d1,d5
                dbra    d4,.data
                movea.l a6,a1                   ; after the even halves
                movea.l a1,a0
                movea.l a4,a1
                move.l  d5,d0
                bsr.w   PutLong                 ; the data checksum
                movea.l a0,a1
                addq.b  #1,d6
                cmp.b   #11,d6
                bcs.w   .sector
                clr.l   (a1)+                   ; a last gap long
        ; --- the clock bits ----------------------------------------------------
                lea.l   (WRITE_BUF).l,a0
                move.w  #WRITE_WORDS/2-1,d1
                moveq   #0,d2                   ; the previous long
.clock:         move.l  (a0),d0
                cmp.l   #$44894489,d0           ; the sync words stay as they are
                beq.b   .next
                andi.l  #$55555555,d0
                move.l  d0,d3
                add.l   d3,d3                   ; neighbour below
                move.l  d0,d4
                lsr.l   #1,d4                   ; neighbour above
                or.l    d4,d3
                ror.l   #1,d2                   ; the previous long's last bit
                andi.l  #$80000000,d2
                or.l    d2,d3
                not.l   d3
                andi.l  #$AAAAAAAA,d3
                or.l    d3,d0
                move.l  d0,(a0)
.next:          move.l  (a0)+,d2
                dbra    d1,.clock
        ; --- write the track ---------------------------------------------------
                lea.l   ($BFD100).l,a4
                move.b  #$FF,(a4)               ; all deselected, motor off
                bclr.b  #7,(a4)                 ; /MTR on
                moveq   #3,d0
                add.w   (BootDrive).l,d0
                bclr.b  d0,(a4)                 ; select the drive: motor on
                btst    #0,d7                   ; upper side for odd tracks
                beq.b   .side
                bclr.b  #2,(a4)
.side:          move.l  #$80000,d0              ; wait for /RDY (time-out)
.rdy:           btst.b  #5,($BFE001).l
                beq.b   .ready
                subq.l  #1,d0
                bne.b   .rdy
                bra.b   .off
.ready:         btst.b  #3,($BFE001).l          ; /WPRO low: write-protected
                beq.b   .off
                lea.l   (CUSTOM).l,a6
                move.w  #$8210,$96(a6)          ; disk DMA on
                move.w  #$4000,$24(a6)
                move.w  #$7F00,$9E(a6)          ; ADKCON: no word sync,
                move.w  #$9100,$9E(a6)          ; MFM, 2 us cells, no precomp
                move.w  #$0002,$9C(a6)
                move.l  #WRITE_BUF,$20(a6)
                move.w  #$C000+WRITE_WORDS,$24(a6)
                move.w  #$C000+WRITE_WORDS,$24(a6)
                move.l  #$100000,d0             ; wait for DSKBLK (time-out)
.blk:           btst.b  #1,$1F(a6)
                bne.b   .done
                subq.l  #1,d0
                bne.b   .blk
.done:          move.w  #$4000,$24(a6)
                move.w  #$0002,$9C(a6)
.off:           or.b    #$F9,(a4)               ; /MTR high, then select and
                and.b   #$87,(a4)               ; deselect every drive: motors
                or.b    #$78,(a4)               ; off (as the byteloader does)
.exit:          movem.l (a7)+,d0-d7/a0-a6
                rts

; PutLong: d0 -> odd bits then even bits at a1 (data bits only), into the
; checksum d5
PutLong:
                move.l  d0,d1
                lsr.l   #1,d0
                andi.l  #$55555555,d0
                andi.l  #$55555555,d1
                move.l  d0,(a1)+
                move.l  d1,(a1)+
                eor.l   d0,d5
                eor.l   d1,d5
                rts

; the ZX0 decompressor: a0 = packed data, a1 = destination (salvador's default format)
                include "unzx0.s"
