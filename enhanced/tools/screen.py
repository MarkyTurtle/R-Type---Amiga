"""A small Amiga for running the enhanced game's title screens and menu in a 68000 emulator
(Unicorn), with the parts of the chips they use:
  - the blitter, area mode, run at once when BLTSIZE is written (the title letters are BOBs);
  - the frame: the main loop sets FrameReady and waits, and here each wait is one frame
    (the copper interrupt's swap of the two buffers, done in Python);
  - the joystick in port 2 (JOY1DAT, the fire button in CIA-A) and the keyboard's raw code.
The playfield shown is rendered to a PNG (the 320 x 208 view, the copper list's colours).

Not emulated: interrupts, sprites, audio, the disk (the files are copied into memory).

    from screen import Title
    t = Title(); t.frames(400); t.png('title.png')"""
import os, re, struct
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE, UC_HOOK_MEM_WRITE
from unicorn.m68k_const import (UC_CPU_M68K_M68000, UC_M68K_REG_A6, UC_M68K_REG_D0, UC_M68K_REG_A7, UC_M68K_REG_D7,
                                UC_M68K_REG_PC, UC_M68K_REG_SR)

HERE = os.path.dirname(os.path.abspath(__file__))
ENH = os.path.dirname(HERE)
BUILD = os.path.join(ENH, 'build')
FILES = os.path.join(os.path.dirname(ENH), 'original', 'files')
CUSTOM, CIAA_PRA = 0xDFF000, 0xBFE001
SCREEN_A, SCREEN_B, LINE = 0x2D1BA, 0x3AEBA, 0xD0
RET = 0x400                     # a 'stop' for TitleSequence and called routines to return to


def syms(lst):
    d = {}
    for line in open(os.path.join(BUILD, lst), errors='replace'):
        m = re.match(r'^([A-Za-z_]\w*)\s+[A-Z]:([0-9A-F]+)', line)
        if m:
            d[m.group(1)] = int(m.group(2), 16)
    return d


def minterm(mt, a, b, c):
    d = 0
    for i in range(8):
        if mt >> i & 1:
            d |= (a if i & 4 else ~a) & (b if i & 2 else ~b) & (c if i & 1 else ~c)
    return d & 0xFFFF


class Title:
    """The engine (build/game_low.bin), the $6000 graphics block and the shared title file in
    memory, run from TitleSequence (d7 = 1: the files are there already)."""

    def __init__(self, extra=()):
        u = self.u = Uc(UC_ARCH_M68K, UC_MODE_BIG_ENDIAN)
        u.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        u.mem_map(0, 0x80000); u.mem_map(0xBFD000, 0x2000); u.mem_map(0xDFF000, 0x1000)
        self.g = syms('game_low.bin.lst')
        u.mem_write(0xA4, open(os.path.join(BUILD, 'game_low.bin'), 'rb').read())
        u.mem_write(0x6000, open(os.path.join(FILES, 'game_main_06000.bin'), 'rb').read())
        u.mem_write(0x4A300, open(os.path.join(FILES, 'shared_4a300.bin'), 'rb').read())
        for k in range(16):                     # InitHardware's line tables
            self.w32(0x48BBA + 4 * k, k * LINE)
        for k in range(272):
            self.w32(0x48C62 + 4 * k, k * LINE)
        for addr, data in extra:
            u.mem_write(addr, data)
        self.joy = ''                      # held: any of 'UDLR'
        self.fire = False
        self.frame = 0
        self.shown = SCREEN_A
        self.w32(self.g['DrawBuffer'], SCREEN_B)
        self.w8(CIAA_PRA, 0xFF)
        u.hook_add(UC_HOOK_MEM_WRITE, self._bltsize, begin=CUSTOM + 0x58, end=CUSTOM + 0x59)
        self.waits = {self.g['TitleLoop'], self.g['MainLoop']}
        u.hook_add(UC_HOOK_CODE, self._loop, begin=min(self.waits), end=max(self.waits))
        u.reg_write(UC_M68K_REG_SR, 0x2700)          # (first: it selects the stack pointer)
        u.reg_write(UC_M68K_REG_A6, CUSTOM)
        u.reg_write(UC_M68K_REG_A7, 0x466E)
        u.reg_write(UC_M68K_REG_D7, 1)
        self.pc = self.g['TitleSequence']
        self.w16(RET, 0x4E72); self.w16(RET + 2, 0x2700)       # stop #$2700
        sp = 0x466E - 4
        self.w32(sp, RET)                                    # TitleSequence returns here:
        u.reg_write(UC_M68K_REG_A7, sp)                      # a game is starting
        self.started = False
        self.sounds = []
        u.hook_add(UC_HOOK_CODE, self._ret, begin=RET, end=RET)
        u.hook_add(UC_HOOK_CODE, self._sound, begin=self.g['PlaySound'], end=self.g['PlaySound'])

    # memory
    def r8(self, a): return self.u.mem_read(a, 1)[0]
    def r16(self, a): return struct.unpack('>H', bytes(self.u.mem_read(a, 2)))[0]
    def r32(self, a): return struct.unpack('>L', bytes(self.u.mem_read(a, 4)))[0]
    def w8(self, a, v): self.u.mem_write(a, bytes([v & 0xFF]))
    def w16(self, a, v): self.u.mem_write(a, struct.pack('>H', v & 0xFFFF))
    def w32(self, a, v): self.u.mem_write(a, struct.pack('>L', v & 0xFFFFFFFF))
    def var(self, name, size=1):
        return {1: self.r8, 2: self.r16, 4: self.r32}[size](self.g[name])

    # input, as the hardware shows it
    def _input(self):
        j = self.joy
        right, left = 'R' in j, 'L' in j
        down, up = 'D' in j, 'U' in j
        v = (right << 1) | (left << 9) | ((down ^ right) << 0) | ((up ^ left) << 8)
        self.w16(CUSTOM + 0x0C, v)
        self.w8(CIAA_PRA, 0x7F if self.fire else 0xFF)

    # the blitter
    def _bltsize(self, uc, acc, addr, size, value, ud):
        if addr == CUSTOM + 0x58:
            self.blit(value & 0xFFFF)

    def blit(self, size):
        c16 = lambda r: self.r16(CUSTOM + r)
        con0, con1 = c16(0x40), c16(0x42)
        h = size >> 6 or 1024; w = size & 63 or 64
        use, ash, bsh, mt = con0 >> 8 & 15, con0 >> 12, con1 >> 12, con0 & 0xFF
        desc = bool(con1 & 2)
        fwm, lwm = c16(0x44), c16(0x46)
        ptr = {k: self.r32(CUSTOM + r) & 0x7FFFE for k, r in (('c', 0x48), ('b', 0x4C), ('a', 0x50), ('d', 0x54))}
        mod = {k: struct.unpack('>h', struct.pack('>H', c16(r)))[0]
               for k, r in (('c', 0x60), ('b', 0x62), ('a', 0x64), ('d', 0x66))}
        adat, bdat, cdat = c16(0x74), c16(0x72), c16(0x70)
        step = -2 if desc else 2
        olda = oldb = 0
        for y in range(h):
            for x in range(w):
                a = self.r16(ptr['a']) if use & 8 else adat
                if x == 0: a &= fwm
                if x == w - 1: a &= lwm
                b = self.r16(ptr['b']) if use & 4 else bdat
                c = self.r16(ptr['c']) if use & 2 else cdat
                if desc:
                    sa = ((a << ash) | (olda >> (16 - ash))) & 0xFFFF if ash else a
                    sb = ((b << bsh) | (oldb >> (16 - bsh))) & 0xFFFF if bsh else b
                else:
                    sa = (((olda << 16) | a) >> ash) & 0xFFFF
                    sb = (((oldb << 16) | b) >> bsh) & 0xFFFF
                olda, oldb = a, b
                if use & 1: self.w16(ptr['d'], minterm(mt, sa, sb, c))
                for k, bit in (('a', 8), ('b', 4), ('c', 2), ('d', 1)):
                    if use & bit: ptr[k] += step
            for k, bit in (('a', 8), ('b', 4), ('c', 2), ('d', 1)):
                if use & bit: ptr[k] += -mod[k] if desc else mod[k]

    def _ret(self, uc, addr, size, ud):
        self.started = True
        self.left = 0
        self.pc = addr
        uc.emu_stop()

    def _sound(self, uc, addr, size, ud):
        self.sounds.append(uc.reg_read(UC_M68K_REG_D0) & 0xFFFF)

    def call(self, addr, regs=(), sp=0x7FF00):
        """Run a routine (to its rts) outside the frame loop -> its d0 and SR"""
        ctx = self.u.context_save()
        sp -= 4
        self.w32(sp, RET + 4)
        self.w16(RET + 4, 0x4E72); self.w16(RET + 6, 0x2700)
        self.u.reg_write(UC_M68K_REG_A7, sp)
        for r, v in regs:
            self.u.reg_write(r, v)
        self.u.emu_start(addr, RET + 4, count=10_000_000)
        out = {r: self.u.reg_read(r) for r in (UC_M68K_REG_D0, UC_M68K_REG_SR)}
        self.u.context_restore(ctx)
        return out

    # frames
    def _loop(self, uc, addr, size, ud):
        if addr not in self.waits:
            return
        if self.r8(self.g['FrameReady']):          # a frame drawn: show it (SwapScreens)
            self.shown = self.r32(self.g['DrawBuffer'])
            self.w32(self.g['DrawBuffer'], SCREEN_A if self.shown == SCREEN_B else SCREEN_B)
            self.w8(self.g['FrameReady'], 0)
            self.w32(self.g['VblCount'], self.r32(self.g['VblCount']) + 1)
            self.frame += 1
            self.left -= 1
            self._input()
            if self.left <= 0:
                self.pc = addr
                uc.emu_stop()

    def frames(self, n, joy=None, fire=None):
        """Run n frames (with this input held, if given)."""
        if joy is not None: self.joy = joy
        if fire is not None: self.fire = fire
        self._input()
        self.left = n
        while self.left > 0 and not self.started:
            self.u.emu_start(self.pc, 0xFFFFFF, count=200_000_000)
            if not self.started:
                self.pc = self.u.reg_read(UC_M68K_REG_PC)
        return self

    def press(self, joy='', fire=False, hold=2, wait=6):
        self.frames(hold, joy, fire)
        return self.frames(wait, '', False)

    def text(self, line, byte, n, buf=None):
        """The characters at a screen position (matched against the font), or '?'."""
        buf = buf or self.shown
        font = self.u.mem_read(0x2CEB8, 0x300)
        cs = self.u.mem_read(self.g['CharSet'], 48)
        out = ''
        for k in range(n):
            a = buf + line * LINE + byte + k
            g0 = bytes(self.r8(a + r * LINE) for r in range(8))
            g1 = bytes(self.r8(a + 0x34 + r * LINE) for r in range(8))
            ch = '?'
            for i in range(48):
                if bytes(font[i * 8:i * 8 + 8]) == g0 and bytes(font[0x180 + i * 8:0x180 + i * 8 + 8]) == g1:
                    ch = chr(cs[i]); break
            out += ch
        return out

    def png(self, path, buf=None):
        from PIL import Image
        buf = buf or self.shown
        cols = [0] + [self.r16(self.g['CopColours'] + 4 * i) for i in range(15)]
        rgb = [((c >> 8 & 15) * 17, (c >> 4 & 15) * 17, (c & 15) * 17) for c in cols]
        img = Image.new('RGB', (320, 208))
        px = img.load()
        mem = bytes(self.u.mem_read(buf + 32 * LINE, 208 * LINE))
        for y in range(208):
            row = mem[y * LINE:(y + 1) * LINE]
            for x in range(320):
                byte, bit = 6 + (x >> 3), 7 - (x & 7)
                c = 0
                for p in range(4):
                    c |= (row[p * 0x34 + byte] >> bit & 1) << p
                px[x, y] = rgb[c]
        img = img.resize((640, 416), Image.NEAREST)
        img.save(path)
