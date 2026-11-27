;==============================================================================
; Enhanced disk code: included by game.s in place of the original's track
; loader, track cache, ByteKiller decruncher and high-score track code
; ($3C3A-$41B3).  It must not outgrow that space (game.s checks), so that
; every label after it - and so every address the level files use - stays
; where the original has it.
;
; The disk is an ordinary AmigaDOS disk in the old file system (OFS, DOS\0:
; the only one Kickstart 1.3 boots and reads).  Every file is stored in one
; run of blocks, so a file is a plain offset and length on the disk, read
; with the 4489_byteloader.  An OFS data block holds a 24-byte header and 488
; bytes of the file, so the run is read whole (512 bytes a block) and the
; headers squeezed out (OFSCompact): the file's bytes are moved up to end
; where they are wanted.  FileTable (filled in by stage 2 from the table the
; build tool writes into it) gives each file id:
;
;   FileTable entry (FT_SIZE = 12 bytes):
;     +0  the offset of its first block on the disk
;     +4  its length (the file's bytes, without the block headers)
;     +8  0 = stored as it is; else ZX0-packed, and this is the unpacked
;         length plus the margin unpacking in place needs: the packed data
;         is put to end at dest + this and unpacked forwards to dest
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
                move.l  4(a2),d4                ; d4 = its length
                move.l  8(a2),d5                ; packed: where it must end
                bne.b   .packed
                lea.l   (a3,d4.l),a4            ; stored: read in place
                bsr.b   ReadFile                ; (ending at dest + length)
                bra.b   .done
.packed:        lea.l   (a3,d5.l),a4            ; a4 = where the packed data ends
                tst.l   (CacheBase).l           ; extra memory?
                beq.b   .read
                lea.l   (FileCache).l,a0
                adda.w  d3,a0                   ; a0 -> its cache slot
                move.l  (a0),d5                 ; the end of its cached copy
                bne.b   .cached
                bsr.b   RawLength               ; d0 = its blocks' size
                move.l  (CacheNext).l,d5
                add.l   d0,d5                   ; room for its blocks?
                cmp.l   (CacheLimit).l,d5
                bhi.b   .read                   ; no: read it to its place
                move.l  d5,(a0)                 ; keep it: ending at d5
                move.l  d5,(CacheNext).l
                movea.l d5,a4
.read:          bsr.b   ReadFile
                bra.b   .unpack
.cached:        movea.l d5,a4
.unpack:        movea.l a4,a0                   ; unpack from its start
                suba.l  d4,a0
                movea.l a3,a1
                bsr.w   zx0_decompress
.done:          movem.l (a7)+,d0-d7/a0-a6
                rts

; RawLength: a2 = file entry -> d0 = its blocks' size on the disk (512 each),
; d1 = the number of blocks
RawLength:
                move.l  4(a2),d0
                add.l   #487,d0
                divu.w  #488,d0
                moveq   #0,d1
                move.w  d0,d1
                move.l  d1,d0
                lsl.l   #8,d0
                add.l   d0,d0
                rts

; ReadFile: a2 = file entry, a4 = where its bytes must end.  Reads its
; blocks (ending at a4) and squeezes the block headers out, so that the
; file's bytes end at a4.  A read that fails is tried again; after 8
; failures in a row COLOR00 turns red while it goes on trying.
ReadFile:
                movem.l d0-d7/a0-a6,-(a7)
                bsr.b   RawLength
                movea.l a4,a5
                suba.l  d0,a5                   ; a5 = where the blocks go
                moveq   #0,d7                   ; failures
.try:           movem.l d0-d1/d7/a2/a4-a5,-(a7)
                move.l  d0,d1                   ; length: the whole blocks
                move.l  (a2),d0                 ; offset
                movea.l a5,a0
                bsr.b   ByteLoad
                move.l  d0,d6
                movem.l (a7)+,d0-d1/d7/a2/a4-a5
                tst.l   d6
                beq.b   .ok
                addq.w  #1,d7
                cmp.w   #8,d7
                bcs.b   .try
                move.w  #$F00,(CUSTOM+$180).l
                bra.b   .try
.ok:            subq.w  #1,d1                   ; d1 = blocks - 1
                move.w  d1,d0
                mulu.w  #488,d1
                move.l  4(a2),d2
                sub.l   d1,d2                   ; d2 = bytes in the last block
                move.w  d0,d1
                ext.l   d1
                lsl.l   #8,d1
                add.l   d1,d1
                lea.l   24(a5,d1.l),a0          ; the last block's data
                adda.l  d2,a0                   ; its end
                movea.l a4,a1
                move.w  d2,d1
                bsr.b   OFSCompact
                movem.l (a7)+,d0-d7/a0-a6
                rts

; OFSCompact: a0 = the end of the last block's data, a1 = where the file
; must end, d0.w = blocks - 1, d1.w = bytes in the last block.  Moves each
; block's 488 bytes (the last one's d1) up, from the last block back, so
; that the file's bytes lie together ending at a1 (always an upward move).
OFSCompact:
.blk:           subq.w  #1,d1
.cp:            move.b  -(a0),-(a1)
                dbra    d1,.cp
                lea.l   -24(a0),a0              ; skip the block's header
                move.w  #488,d1
                dbra    d0,.blk
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
; High scores: the file FID_HISCORE, 404 bytes in one OFS data block: the
; table's 100 longs (HighScores, $190 bytes), then their EOR with $12345678
; as a checksum.  LoadHighScores copies the first 90 longs back, as the original
; did from track 68, only if the checksum is right.
;------------------------------------------------------------------------------
HS_LONGS        equ     $64
HS_BUF          equ     TRACK_BUFFER+$3000      ; past the byteloader's MFM buffer
                                                ; (its block is read from HS_BUF-$6C)

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
; and written.  The block never moves and keeps its OFS header (its checksum
; made right again), so the file system stays valid.
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
                movea.l a1,a5
                lea.l   24(a1),a1               ; its data, after the OFS header
                lea.l   (HighScores).l,a0
                moveq   #HS_LONGS-1,d1
.put:           move.l  (a0)+,(a1)+
                dbra    d1,.put
                lea.l   (HighScores).l,a0
                bsr.b   HSChecksum
                move.l  d0,(a1)
                clr.l   20(a5)                  ; the OFS block's checksum: its
                moveq   #0,d0                   ; 128 longs must add up to 0
                moveq   #127,d1
.sum:           add.l   (a5)+,d0
                dbra    d1,.sum
                neg.l   d0
                move.l  d0,20-512(a5)
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
