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
FID_RESIDENT    equ     22      ; the cheats' hooks -> RES_ORG (stage 2, once)
FID_MENU        equ     23      ; the title menu -> MENU_ORG (with the title file)
NFILES          equ     24

FT_SIZE         equ     12      ; offset.l, length on the disk.l, unpacked end.l

WRITE_BUF       equ     $74000  ; SaveHighScores' MFM track (free at the title)
WRITE_GAP       equ     700     ; words of gap before sector 0
WRITE_WORDS     equ     WRITE_GAP+11*544+2

;==============================================================================
; The cheats and the title menu.
;   resident.s -> RES_ORG, loaded once by stage 2: the cheats' hooks and the
;     settings, in the gap between the object table and the level file at
;     $4A2E4.  (The table is 41 objects, $4935A-$49D47: InitObjects links 40
;     and then clears the next field of a 41st at $49D0A, which becomes the
;     last free object.)
;   menu.s -> MENU_ORG, loaded with the title file every time the title
;     starts (LoadShared): the title menu, at the top of memory, which is free
;     during play (as is the byte loader's MFM buffer between loads).
; The engine reaches them through these jump-table entries (jmp (xxx).l).
;==============================================================================
RES_ORG         equ     $49D48
RES_LIMIT       equ     $4A2E4
MENU_ORG        equ     $7F600
MENU_LIMIT      equ     $80000
MJ_FRAME        equ     MENU_ORG+0      ; TitleLoop, every frame: Z set = start the game
MJ_TITLETEXT    equ     MENU_ORG+6      ; St_TitleText: a4 = the title's text list
MJ_PRINTFIRE    equ     RES_ORG+0       ; PrintString: fire speeds the typing up
MJ_NEWGAME      equ     RES_ORG+6       ; NewGame: the start stage
MJ_LOSELIFE     equ     RES_ORG+12      ; ShipRespawn: infinite lives
MJ_SHIPHIT      equ     RES_ORG+18      ; the three ship deaths: invincibility
MJ_WEAPONS      equ     RES_ORG+24      ; ResetShipWeapons (jmp): full weapons
MJ_SCORE        equ     RES_ORG+30      ; St_HighScore: no table entry after cheating
MJ_LOADTITLE    equ     RES_ORG+36      ; LoadShared (jmp): the title file and the menu

; CheatFlags (in the engine, cheats.s): one bit per cheat
CHEATB_SKIP     equ     0               ; N skips the stage
CHEATB_LIVES    equ     1               ; infinite lives
CHEATB_INVINCIBLE equ   2               ; the ship can't be killed
