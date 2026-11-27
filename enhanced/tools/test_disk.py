#!/usr/bin/env python3
"""Run the enhanced disk code in a 68000 emulator (Unicorn) against the built disk
(enhanced/build/rtype.adf, tools/build.py), with tools/floppy.py as the drive:

  1. the bootblock (src/boot.s): Kickstart's call with exec stubbed (AvailMem,
     AllocMem, OpenDevice, DoIO as Python hooks): the boot file at $6EFA0, the
     jump to stage 2 with MemBase / MemLimit / the drive (booted from DF0 and
     from DF1);
  2. stage 2's LoadFile (src/stage2.s): the music, the engine and the $6000
     block, each unpacked in place, with stage 2 and the title picture in memory
     around them;
  3. the engine's LoadFile (src/disk.s): every file, with and without extra
     memory (the second load of a file then comes from the cache, no disk read);
  4. LoadHighScores / SaveHighScores: the default table read back; a changed
     table saved (the track written back is decoded and its checksums checked;
     the other sectors of the track are unchanged) and read back; a damaged
     block keeps the table as it is.

  python3 -I enhanced/tools/test_disk.py
"""
import os, re, struct, sys
from unicorn import Uc, UC_ARCH_M68K, UC_MODE_BIG_ENDIAN, UC_HOOK_CODE
from unicorn.m68k_const import (UC_CPU_M68K_M68000, UC_M68K_REG_A1, UC_M68K_REG_A6, UC_M68K_REG_A7,
                                UC_M68K_REG_D0, UC_M68K_REG_D1, UC_M68K_REG_D2, UC_M68K_REG_PC)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import floppy

HERE = os.path.dirname(os.path.abspath(__file__))
ENH = os.path.dirname(HERE)
BUILD = os.path.join(ENH, 'build')
FILES = os.path.join(os.path.dirname(ENH), 'original', 'files')
SLOW = 0xC00000
RET = 0x400                     # a 'stop' the routines return to
fails = 0


def syms(lst):
    d = {}
    for line in open(os.path.join(BUILD, lst), errors='replace'):
        m = re.match(r'^([A-Za-z_]\w*)\s+[A-Z]:([0-9A-F]+)', line)
        if m:
            d[m.group(1)] = int(m.group(2), 16)
    return d


def check(ok, what):
    global fails
    print(('ok    ' if ok else 'FAIL  ') + what)
    fails += not ok


class Machine:
    def __init__(self, adf, unit=0, slow=False):
        u = self.u = Uc(UC_ARCH_M68K, UC_MODE_BIG_ENDIAN)
        u.ctl_set_cpu_model(UC_CPU_M68K_M68000)
        u.mem_map(0, 0x80000); u.mem_map(0xBFD000, 0x2000); u.mem_map(0xDFF000, 0x1000)
        if slow:
            u.mem_map(SLOW, 0x80000)
        self.w16(RET, 0x4E72); self.w16(RET + 2, 0x2700)       # stop #$2700
        self.adf = bytearray(adf)
        self.fd = WritingFloppy(self, self.adf, unit=unit)
    def r8(self, a): return self.u.mem_read(a, 1)[0]
    def r16(self, a): return struct.unpack('>H', bytes(self.u.mem_read(a, 2)))[0]
    def r32(self, a): return struct.unpack('>L', bytes(self.u.mem_read(a, 4)))[0]
    def w8(self, a, v): self.u.mem_write(a, bytes([v & 0xFF]))
    def w16(self, a, v): self.u.mem_write(a, struct.pack('>H', v & 0xFFFF))
    def w32(self, a, v): self.u.mem_write(a, struct.pack('>L', v & 0xFFFFFFFF))
    def mem(self, a, n): return bytes(self.u.mem_read(a, n))

    def call(self, pc, regs=(), sp=0x7FF00, limit=400_000_000):
        u = self.u
        sp -= 4
        self.w32(sp, RET)
        u.reg_write(UC_M68K_REG_A7, sp)
        for r, v in regs:
            u.reg_write(r, v)
        u.emu_start(pc, RET, count=limit)
        return u.reg_read(UC_M68K_REG_PC)


class WritingFloppy(floppy.Floppy):
    """floppy.Floppy, and a write DMA (DSKLEN bit 14) decoded into the disk:
    every sector found after a $4489 sync, its header and data checksums checked."""
    def __init__(self, *a, **k):
        super().__init__(*a, **k)
        self.writes = []

    def _dsklen(self, uc, acc, addr, size, value, ud):
        v = value & 0xFFFF
        if not v & 0x4000 or not v & 0x8000:
            return super()._dsklen(uc, acc, addr, size, value, ud)
        if not self.armed:
            self.armed = True; return
        self.armed = False
        if not (self.sel and self.motor):
            return
        n, ptr = v & 0x3FFF, self.m.r32(0xDFF020) & 0x1FFFFE
        words = struct.unpack('>%dH' % n, self.m.mem(ptr, n * 2))
        t = self.cyl * 2 + self.side
        got = self.decode(words, t)
        self.writes.append((t, sorted(got)))
        for s, data in got.items():
            off = (t * 11 + s) * 512
            self.adf[off:off + 512] = data
        self.cache.pop(t, None)
        self.m.w16(0xDFF01E, self.m.r16(0xDFF01E) | 0x0002)

    @staticmethod
    def decode(words, track):
        M = 0x55555555
        longs = lambda i, k: [(words[i + 2 * j] << 16 | words[i + 2 * j + 1]) for j in range(k)]
        mfm_ok = all(not (w & (w << 1) & 0xFFFF) for w in words)  # no two 1 bits in a row
        assert mfm_ok, 'the written MFM has adjacent 1 bits'
        out = {}
        i = 0
        while i < len(words) - 540:
            if words[i] == 0x4489 and words[i + 1] == 0x4489:
                b = i + 2
                info = longs(b, 2)
                inf = ((info[0] & M) << 1) | (info[1] & M)
                fmt, trk, sec, gap = inf >> 24, inf >> 16 & 0xFF, inf >> 8 & 0xFF, inf & 0xFF
                hdr = longs(b, 10)
                hck = 0
                for x in hdr:
                    hck ^= x & M
                hc = longs(b + 20, 2)
                assert ((hc[0] & M) << 1 | (hc[1] & M)) == hck, 'header checksum'
                dc = longs(b + 24, 2)
                odd, even = longs(b + 28, 128), longs(b + 28 + 256, 128)
                dck = 0
                for x in odd + even:
                    dck ^= x & M
                assert ((dc[0] & M) << 1 | (dc[1] & M)) == dck, 'data checksum'
                assert fmt == 0xFF and trk == track and gap == 11 - sec, 'sector info'
                out[sec] = b''.join(struct.pack('>L', ((o & M) << 1) | (e & M)) for o, e in zip(odd, even))
                i += 544
            else:
                i += 1
        return out


def expected():
    rd = lambda n: open(os.path.join(FILES, n), 'rb').read()
    exp = {1: (0x52300, rd('music_52300.bin')), 2: (0xA4, open(os.path.join(BUILD, 'game_low.bin'), 'rb').read()),
           3: (0x6000, rd('game_main_06000.bin')), 4: (0x4A300, rd('shared_4a300.bin'))}
    for n in range(8):
        exp[6 + n] = (0x4A2E4, rd('level%d_a_4a2e4.bin' % (n + 1))[:0x4CB00 - 0x4A2E4])
        exp[14 + n] = (0x4D300, rd('level%d_b_4d300.bin' % (n + 1)))
    return exp


def main():
    adf = open(os.path.join(BUILD, 'rtype.adf'), 'rb').read()
    boot = open(os.path.join(BUILD, 'boot.bin'), 'rb').read()
    g, s2 = syms('game_low.bin.lst'), syms('stage2.bin.lst')
    table = boot[s2['S2FileTable'] - 0x6EFA0:][:22 * 12]
    exp = expected()

    # 1. the bootblock -------------------------------------------------------------
    for unit in (0, 1):
        m = Machine(adf, unit=unit)
        bb = adf[:1024]
        m.u.mem_write(0x20000, bb)
        EXEC, BOOTREQ, NAME, DEVICE = 0x1000, 0x1300, 0x1200, 0x1100
        UNITS = [0x1400 + 0x40 * k for k in range(4)]
        m.w32(4, EXEC)
        stubs = {EXEC - 216: 'AvailMem', EXEC - 198: 'AllocMem', EXEC - 444: 'OpenDevice', EXEC - 456: 'DoIO'}
        for a in stubs:
            m.w16(a, 0x4E75)                                       # rts
        m.u.mem_write(NAME, b'trackdisk.device\0')
        m.w32(DEVICE + 0xA, NAME)
        m.w32(BOOTREQ + 0x14, DEVICE); m.w32(BOOTREQ + 0x18, UNITS[unit])
        calls = []
        def hook(uc, addr, size, ud):
            name = stubs.get(addr)
            if not name:
                return
            d0, d1, a1 = (uc.reg_read(r) for r in (UC_M68K_REG_D0, UC_M68K_REG_D1, UC_M68K_REG_A1))
            calls.append(name)
            if name == 'AvailMem': uc.reg_write(UC_M68K_REG_D0, 0x80000)
            if name == 'AllocMem': uc.reg_write(UC_M68K_REG_D0, 0xC01230)
            if name == 'OpenDevice':
                ok = d0 in (0, 1)                                  # DF0 and DF1 connected
                if ok: m.w32(a1 + 0x18, UNITS[d0])
                uc.reg_write(UC_M68K_REG_D0, 0 if ok else 0xFF)
            if name == 'DoIO':
                cmd, ln, data, off = m.r16(a1 + 0x1C), m.r32(a1 + 0x24), m.r32(a1 + 0x28), m.r32(a1 + 0x2C)
                if cmd == 2:
                    m.u.mem_write(data, adf[off:off + ln])
                uc.reg_write(UC_M68K_REG_D0, 0)
        h = m.u.hook_add(UC_HOOK_CODE, hook)
        m.w16(0x79360, 0x4E72); m.w16(0x79362, 0x2700)             # stop at stage 2's entry
        m.u.reg_write(UC_M68K_REG_A1, BOOTREQ); m.u.reg_write(UC_M68K_REG_A6, EXEC)
        m.u.reg_write(UC_M68K_REG_A7, 0x7FF00)
        m.u.emu_start(0x2000C, 0x79360, count=2_000_000)
        r = [m.u.reg_read(x) for x in (UC_M68K_REG_PC, UC_M68K_REG_D0, UC_M68K_REG_D1, UC_M68K_REG_D2)]
        loaded = m.mem(0x6EFA0, len(boot))
        check(r[0] == 0x79360 and r[1] == 0xC00000 and r[2] == 0xC81230 and r[3] == unit
              and loaded[:0x79360 - 0x6EFA0] == boot[:0x79360 - 0x6EFA0],
              'bootblock from DF%d: boot file at $6EFA0, stage 2 entered with MemBase $%X, MemLimit $%X, drive %d'
              % (unit, r[1], r[2], r[3]))

    # 2. stage 2 ------------------------------------------------------------------
    m = Machine(adf)
    m.u.mem_write(0x6EFA0, boot)
    m.w16(s2['BootDrive'], 0)
    lo, hi = s2['ByteLoader'], s2['zx0_decompress']
    m.fd.ranges = [(lo, hi)]
    for fid in (1, 2, 3):
        dest, data = exp[fid]
        m.call(s2['LoadFile'], [(UC_M68K_REG_D0, fid), (UC_M68K_REG_D2, dest)], sp=0x40B60)
        now = m.mem(0x79360, len(boot) - 0xA3C0)
        state = s2['zx0_decompress'] - 2 - 0x79360           # the byteloader's own state word
        changed = [k for k in range(len(now)) if now[k] != boot[0xA3C0 + k] and k not in (state, state + 1)
                   and not s2['BootDrive'] - 0x79360 <= k < s2['BootDrive'] - 0x79360 + 2]
        check(m.mem(dest, len(data)) == data, 'stage 2 LoadFile %d -> $%X: unpacked in place' % (fid, dest))
        check(not changed, '... stage 2 intact%s' % ('' if not changed else ' (changed at +$%X)' % changed[0]))

    # 3. the engine's LoadFile ----------------------------------------------------------
    for slow in (False, True):
        m = Machine(adf, slow=slow)
        m.u.mem_write(0xA4, exp[2][1])
        m.u.mem_write(g['FileTable'], table)
        m.fd.ranges = [(g['ByteLoader'], g['Decrunch'])]
        if slow:
            m.w32(g['CacheBase'], SLOW); m.w32(g['CacheNext'], SLOW); m.w32(g['CacheLimit'], SLOW + 0x80000)
        for rnd in (1, 2):
            for fid in sorted(exp):
                if fid in (1, 2, 3):
                    continue
                dest, data = exp[fid]
                m.u.mem_write(dest, b'\x55' * len(data))
                before = m.fd.reads
                m.call(g['LoadFile'], [(UC_M68K_REG_D0, fid), (UC_M68K_REG_D2, dest)])
                ok = m.mem(dest, len(data)) == data
                cached = slow and rnd == 2
                if cached:
                    ok = ok and m.fd.reads == before
                if not ok or fid in (4, 6, 14, 21):
                    check(ok, 'engine LoadFile %d -> $%X%s%s' % (fid, dest, ' (extra memory)' if slow else '',
                                                                ', from the cache' if cached else ''))
        if slow:
            check(m.r32(g['CacheNext']) - SLOW == sum(struct.unpack_from('>L', table, k * 12 + 4)[0]
                                                      for k in exp if k not in (1, 2, 3)),
                  'the cache holds every packed file once')

    # 3b. LoadLevel's loads, from LevelTable, for every level -----------------------
    m = Machine(adf)
    m.u.mem_write(0xA4, exp[2][1])
    m.u.mem_write(g['FileTable'], table)
    m.fd.ranges = [(g['ByteLoader'], g['Decrunch'])]
    lst = open(os.path.join(BUILD, 'game_low.bin.lst'), errors='replace').read()
    after = int(re.search(r'00:([0-9A-F]{8}) [0-9A-F]+\s+\d+:\s+bsr\.w\s+Decrunch', lst).group(1), 16) + 4
    for n in range(8):
        m.w32(g['LevelTablePtr'], g['LevelTable'] + 10 * n)
        m.u.mem_write(0x4A2E4, b'\x55' * 0x2B000)
        m.u.reg_write(UC_M68K_REG_A7, 0x7FF00)
        m.u.emu_start(g['LoadLevel'], after, count=400_000_000)
        a, b = exp[6 + n][1], exp[14 + n][1]
        row = struct.unpack_from('>H', exp[2][1], g['LevelTable'] + 10 * n + 8 - 0xA4)[0]
        check(m.mem(0x4A2E4, len(a)) == a and m.mem(0x4D300, len(b)) == b and m.r16(g['MapWidth']) == row
              and m.r32(g['LevelTablePtr']) == g['LevelTable'] + 10 * (n + 1),
              'LoadLevel, level %d: part A at $4A2E4, part B at $4D300, MapWidth $%X' % (n + 1, row))

    # 4. high scores ----------------------------------------------------------------
    m = Machine(adf)
    m.u.mem_write(0xA4, exp[2][1])
    m.u.mem_write(g['FileTable'], table)
    m.fd.ranges = [(g['ByteLoader'], g['Decrunch'])]
    hs = g['HighScores']
    default = m.mem(hs, 400)
    m.u.mem_write(hs, bytes(400))
    m.call(g['LoadHighScores'])
    check(m.mem(hs, 360) == default[:360], 'LoadHighScores: the default table from the disk')
    new = bytes((i * 7 + 3) & 0xFF for i in range(400))
    m.u.mem_write(hs, new)
    hs_off = struct.unpack_from('>L', table, 5 * 12)[0]
    trk = hs_off // 5632
    before = bytes(m.adf[trk * 5632:(trk + 1) * 5632])
    m.call(g['SaveHighScores'])
    after = bytes(m.adf[trk * 5632:(trk + 1) * 5632])
    blk = hs_off - trk * 5632
    check(m.fd.writes == [(trk, list(range(11)))] and after[blk:blk + 400] == new
          and after[:blk] == before[:blk] and after[blk + 512:] == before[blk + 512:],
          'SaveHighScores: track %d written (11 sectors, checksums right), only the block changed' % trk)
    m.u.mem_write(hs, bytes(400))
    m.call(g['LoadHighScores'])
    check(m.mem(hs, 360) == new[:360], 'LoadHighScores: the saved table read back')
    m.adf[hs_off + 10] ^= 0xFF                                   # a damaged block
    m.fd.cache.clear()
    m.u.mem_write(hs, default)
    m.call(g['LoadHighScores'])
    check(m.mem(hs, 400) == default, 'LoadHighScores: a damaged block leaves the table alone')
    print('%d failed' % fails if fails else 'all passed')
    sys.exit(1 if fails else 0)


if __name__ == '__main__':
    main()
