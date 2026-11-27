;==============================================================================
; The enhanced disk's file ids (the order of the files in FileTable).  The
; build tool (tools/build.py) writes each file's place on the disk into the
; table in stage 2, which copies it to the game's FileTable.
;==============================================================================
FID_BOOT        equ     0       ; title picture + font + stage 2 -> $6EFA0 (bootblock)
FID_MUSIC       equ     1       ; TFMX replay, smpl, mdat -> $52300
FID_GAMELOW     equ     2       ; the engine -> $A4
FID_GAMEMAIN    equ     3       ; the $6000 graphics block -> $6000
FID_SHARED      equ     4       ; title data and jingle player -> $4A300
FID_HISCORE     equ     5       ; the high-score block (512 bytes, stored)
FID_LEVEL1A     equ     6       ; level n part A -> $4A2E4: FID_LEVEL1A + n - 1
FID_LEVEL1B     equ     14      ; level n part B -> $4D300: FID_LEVEL1B + n - 1
NFILES          equ     22

FT_SIZE         equ     12      ; offset.l, length on the disk.l, unpacked end.l

WRITE_BUF       equ     $74000  ; SaveHighScores' MFM track (free at the title)
WRITE_GAP       equ     700     ; words of gap before sector 0
WRITE_WORDS     equ     WRITE_GAP+11*544+2
