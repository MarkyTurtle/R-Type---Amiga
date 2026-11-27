"""The title menu and the cheats (src/menu.s), run in the emulator of tools/screen.py: the
engine, the graphics and the title file in memory, the menu at MENU_ORG, the title sequence
from its start.  Each case starts from the same saved moment (the title's text typed).

  python3 -I enhanced/tools/test_menu.py      (after build.py; --png DIR saves the screens)"""
import copy, os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from screen import Title, BUILD, RET
from unicorn.m68k_const import UC_M68K_REG_A7, UC_M68K_REG_D0, UC_M68K_REG_SR

fails = 0


def check(ok, what):
    global fails
    print(('ok    ' if ok else 'FAIL  ') + what)
    fails += not ok


def main():
    png = sys.argv[sys.argv.index('--png') + 1] if '--png' in sys.argv else None
    menu = open(os.path.join(BUILD, 'menu.bin'), 'rb').read()
    lay = {}
    for line in open(os.path.join(os.path.dirname(BUILD), 'src', 'files.i')):
        p = line.split()
        if len(p) >= 3 and p[1] == 'equ' and p[2].startswith('$'):
            lay[p[0]] = int(p[2][1:], 16)
        elif len(p) >= 3 and p[1] == 'equ' and p[2].startswith('MENU_ORG+'):
            lay[p[0]] = lay['MENU_ORG'] + int(p[2][9:])
    ORG = lay['MENU_ORG']
    t = Title(extra=[(ORG, menu)])
    g = t.g
    m = {}                                           # the menu's symbols
    import re
    for line in open(os.path.join(BUILD, 'menu.bin.lst'), errors='replace'):
        r = re.match(r'^([A-Za-z_]\w*)\s+[A-Z]:([0-9A-F]+)', line)
        if r:
            m[r.group(1)] = int(r.group(2), 16)
    state = lambda: t.var('TitleState', 4)
    flags = lambda: t.r8(g['CheatFlags'])

    # the title, typed out
    t.frames(330)
    check(not t.started and t.text(72, 23, 10) == 'start game' and t.text(86, 23, 7) == 'options'
          and t.text(72, 34, 1) == '<' and t.text(110, 33, 9) == ' freeplay',
          'the title: start game (chosen), options, freeplay')
    if png: t.png(os.path.join(png, 'title.png'))
    mem = bytes(t.u.mem_read(0, 0x80000)); ctx = t.u.context_save()
    keep = {k: copy.copy(v) for k, v in t.__dict__.items() if k not in ('u', 'g')}

    def load():
        t.u.mem_write(0, mem); t.u.context_restore(ctx)
        t.__dict__.update({k: copy.copy(v) for k, v in keep.items()})

    t.press('', True)
    check(t.started, 'fire on start game: the game starts (TitleSequence returns)')
    load(); t.press('D')
    check(t.text(72, 34, 1) == ' ' and t.text(86, 34, 1) == '<', 'down: options chosen')
    load(); t.press('U'); t.press('U')
    check(t.text(72, 34, 1) == '<', 'up twice: start game again')
    load(); left = t.var('TitleDelay', 2)
    t.frames(left - 20); t.press('D'); t.frames(100)
    check(t.text(86, 23, 7) == 'options' and not t.started,
          'a press keeps the title up past its 200 frames')
    load(); t.frames(t.var('TitleDelay', 2) + 100)
    check(t.r8(m['MenuPage']) == 0 and state() == g['St_ShowHighScores'], 'left alone, the title times out to the credits')
    t.press('', True)
    check(not t.started and state() in (g['St_ShowTitle'], g['St_TitleStart'], g['St_TitleLetters']),
          'fire on the credits goes back to the title (not a game)')

    # the options page
    load(); t.press('D'); t.press('', True)
    check(t.r8(m['MenuPage']) == 2 and t.text(46, 22, 7) == 'options' and t.text(72, 9, 14) == 'infinite lives'
          and t.text(72, 30, 3) == 'off' and t.text(72, 37, 1) == '<', 'options: the page, infinite lives chosen')
    if png: t.png(os.path.join(png, 'options.png'))
    t.frames(400)
    check(t.r8(m['MenuPage']) == 2 and not t.started, 'options: no time-out')
    t.press('R')
    check(flags() & 2 and t.text(72, 30, 3) == 'on ', 'right: infinite lives on')
    t.press('', True)
    check(not flags() & 2, 'fire: off again')
    t.press('D'); t.press('', True)
    check(flags() & 4 and t.text(86, 30, 2) == 'on', 'invincibility on')
    t.press('D'); t.press('L')
    check(t.r8(m['StartStage']) == 7 and t.text(100, 31, 1) == '8', 'start stage: left from 1 is 8')
    t.press('R'); t.press('R')
    check(t.r8(m['StartStage']) == 1 and t.text(100, 31, 1) == '2', 'start stage: right twice is 2')
    t.press('D'); t.press('R'); t.press('R')
    check(t.r8(m['Weapons']) == 2 and t.text(114, 30, 3) == 'red', 'full weapons: red')
    t.press('D'); t.press('R')
    check(flags() & 1 and t.text(128, 30, 2) == 'on', 'stage skip key on')
    t.press('D'); t.press('R'); t.press('R'); t.press('R')
    check(t.r8(m['SoundNum']) == 3 and t.text(142, 30, 2) == '03', 'sound effect: 03')
    t.sounds = []; t.press('', True)
    check(t.sounds == [3], 'fire plays it (PlaySound 3)')
    t.press('L'); t.press('L'); t.press('L'); t.press('L')
    check(t.r8(m['SoundNum']) == 13, 'sound effect: left from 00 is 13')
    if png: t.png(os.path.join(png, 'options_set.png'))
    t.press('D', hold=1, wait=2); t.press('D', hold=1, wait=2)
    check(t.r8(m['MenuItem']) == 0, 'down from exit: back to the top')
    t.press('U'); t.press('R')
    check(t.r8(m['MenuPage']) == 2, 'right on exit does nothing')
    t.press('', True)
    check(t.r8(m['MenuPage']) == 0 and state() in (g['St_TitleStart'], g['St_TitleLetters']), 'fire on exit: the title again')
    t.frames(330)
    check(t.text(110, 33, 9) == 'cheats on' and t.r8(m['MenuPage']) == 1, 'the title says cheats on')
    moves = []
    for _ in range(60):
        t.frames(1, 'D'); moves.append(t.r8(m['MenuItem']))
    flips = sum(a != b for a, b in zip(moves, moves[1:]))
    check(7 <= flips <= 10, 'down held for 60 frames: a move, then repeats after 20 frames, every 5 (%d)' % (flips + 1))

    # fire while the text is typed: the rest at once, and no game
    t2 = Title(extra=[(ORG, menu)])
    t2.frames(120)
    t2.frames(60, '', True)
    check(not t2.started and t2.text(208, 31, 14) == 'C 1987 by irem' and t2.r8(m['MenuPage']) == 1,
          'fire held while the title types: done at once, no game')
    t2.frames(5, '', True)
    check(not t2.started, 'the held fire is not a press for the menu')
    t2.frames(3, '', False); t2.press('', True)
    check(t2.started, 'released and pressed again: the game starts')

    # the cheats' hooks
    load()
    for st in range(8):
        t.w8(m['StartStage'], st); t.w8(g['CheatFlags'], 0); t.w8(m['Weapons'], 0)
        t.call(lay['MJ_NEWGAME'])
        ok = t.r8(g['Level']) == st and t.r32(g['LevelTablePtr']) == g['LevelTable'] + 10 * st
        if not ok: break
    check(ok, 'NewGame: Level and LevelTablePtr from the start stage (1-8)')
    t.w8(m['StartStage'], 0); t.call(lay['MJ_NEWGAME'])
    check(t.r8(m['CheatUsed']) == 0, '... a game without cheats counts')
    t.w8(g['CheatFlags'], 1); t.call(lay['MJ_NEWGAME'])
    check(t.r8(m['CheatUsed']) != 0, '... with one (here the stage skip), it does not')
    t.w32(g['Score'], 123456)
    r = t.call(lay['MJ_SCORE'])
    check(r[UC_M68K_REG_D0] == 0, 'St_HighScore: no score for the table after cheating')
    t.w8(g['CheatFlags'], 0); t.call(lay['MJ_NEWGAME']); r = t.call(lay['MJ_SCORE'])
    check(r[UC_M68K_REG_D0] == 123456, '... the score otherwise')
    for f, want in ((0, 4), (2, 5)):
        t.w8(g['CheatFlags'], f); t.w16(g['Lives'], 5); t.call(lay['MJ_LOSELIFE'])
        check(t.r16(g['Lives']) == want, 'ShipRespawn: %s' % ('a life lost' if f == 0 else 'infinite lives: none lost'))
    for f, want in ((0, 0xFF), (4, 0)):
        t.w8(g['CheatFlags'], f); t.w8(g['ShipHit'], 0); t.call(lay['MJ_SHIPHIT'])
        check(t.r8(g['ShipHit']) == want, 'a deadly touch: %s' % ('ShipHit set' if f == 0 else 'invincible: not set'))

    def weapons(ret):
        for k in ('ForceActive', 'ForceLevel', 'BitsFlags', 'MissilesEnabled', 'LaserType'):
            t.w8(g[k], 0)
        # jumped to from ResetShipWeapons: the return address on the stack is its caller's
        ctx = t.u.context_save()
        t.w32(0x7FE00, ret)
        t.u.reg_write(UC_M68K_REG_A7, 0x7FE00)
        t.u.emu_start(lay['MJ_WEAPONS'], ret, count=100_000)
        t.u.context_restore(ctx)
        return [t.r8(g[k]) for k in ('ForceActive', 'ForceLevel', 'BitsFlags', 'MissilesEnabled', 'LaserType')], t.r32(g['ForceState'])
    t.w8(m['Weapons'], 3)
    w, fs = weapons(g['SpawnShipArmed'])
    check(w == [0xFF, 3, 3, 0xFF, 2] and fs == g['Force_Reset'],
          'full weapons (yellow) at a ship start: the Force at level 3 coming in, both Bits, missiles, laser 2')
    w, fs = weapons(g['SpawnShipArmed'] + 0x100)
    check(w == [0, 0, 0, 0, 0] and fs == g['Force_Idle'], '... not from the other callers (a death, the ending)')
    t.w8(m['Weapons'], 0)
    w, fs = weapons(g['SpawnShipArmed'])
    check(w == [0, 0, 0, 0, 0] and fs == g['Force_Idle'], '... nor with it off')

    print('%d failed' % fails if fails else 'all passed')
    sys.exit(1 if fails else 0)


if __name__ == '__main__':
    main()
