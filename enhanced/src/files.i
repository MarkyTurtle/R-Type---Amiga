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
FID_MENU        equ     22      ; the title menu and the cheats -> MENU_ORG (stage 2)
NFILES          equ     23

FT_SIZE         equ     12      ; offset.l, length on the disk.l, unpacked end.l

WRITE_BUF       equ     $74000  ; SaveHighScores' MFM track (free at the title)
WRITE_GAP       equ     700     ; words of gap before sector 0
WRITE_WORDS     equ     WRITE_GAP+11*544+2

;==============================================================================
; The title menu and the cheats (src/menu.s).  Stage 2 loads them once, above
; itself, where nothing else goes: the level files end below $7965E, the
; byte loader's MFM buffer starts at $7C400.  The engine reaches them through
; this jump table (each entry a jmp (xxx).l).
;==============================================================================
MENU_ORG        equ     $7A7A0
MENU_LIMIT      equ     $7C400
MJ_FRAME        equ     MENU_ORG+0      ; TitleLoop, every frame: Z set = start the game
MJ_TITLETEXT    equ     MENU_ORG+6      ; St_TitleText: a4 = the title's text list
MJ_PRINTFIRE    equ     MENU_ORG+12     ; PrintString: fire speeds the typing up
MJ_NEWGAME      equ     MENU_ORG+18     ; NewGame: the start stage
MJ_LOSELIFE     equ     MENU_ORG+24     ; ShipRespawn: infinite lives
MJ_SHIPHIT      equ     MENU_ORG+30     ; the three ship deaths: invincibility
MJ_WEAPONS      equ     MENU_ORG+36     ; ResetShipWeapons (jmp): full weapons
MJ_SCORE        equ     MENU_ORG+42     ; St_HighScore: no table entry after cheating

; CheatFlags (in the engine, cheats.s): one bit per cheat
CHEATB_SKIP     equ     0               ; N skips the stage
CHEATB_LIVES    equ     1               ; infinite lives
CHEATB_INVINCIBLE equ   2               ; the ship can't be killed
