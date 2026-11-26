#!/usr/bin/env python3
"""Play the in-game music by running the game's own player code.

usage: python3 -I tools/render_music.py files/ OUTDIR [--seconds N] [--mp3]

Each level's music player (LV_Music in level B, docs/MUSIC.md) and the
shared jingle player are run in a 68000 emulator (machine68k, Musashi:
pip install machine68k), called once per 50 Hz frame exactly as the
engine's UpdateMusic / UpdateJingle do.  Writes to Paula's registers are
captured and mixed by a small Paula model: DMA on latches AUDxLC/AUDxLEN,
at the end of a sample the channel restarts from the registers (so a
"keep playing" row chains the loop sample on), period -> pitch at the PAL
clock, volume 0-64.

The TFMX title music is played the same way (init, start song 0, play
every VBL, as stage 2 does): title.mp3.

Songs played per player:
  tune0 / tune1   MusicRequest 1 / 2: the level's music on channels 0-1
                  (d3 = $FF, d1 = 0 / 1; channels 2-3 are left for the
                  sound effects)
  jingle0..2      JingleState 1-3: game over, stage clear, level start
                  (d4 = n<<8 | $FF, on all four channels)
  (shared, and level 8's ending player: called like UpdateJingle,
   d0 = $FF then 2)
Silent or identical results are skipped.  Output: 22050 Hz mono WAV (or
MP3 with --mp3, using ffmpeg).
"""
import os, struct, subprocess, sys, wave
import machine68k as m68

PAL = 3546895
RATE = 22050
PLAYERS = [('shared', 'shared_4a300.bin', 0x4A300, 0x4A300)] + \
    [(f'level{n}', f'level{n}_b_4d300.bin', 0x4D300, a) for n, a in
     [(1, 0x5CA38), (2, 0x5E948), (3, 0x634D0), (4, 0x52078),
      (5, 0x51A54), (6, 0x5C9A8), (7, 0x582A4), (8, 0x5C1FE)]] + \
    [('level8end', 'level8_b_4d300.bin', 0x4D300, 0x5F244)]
RET = 0x400                                      # stop #$2700 here

class Paula:
    def __init__(self, mem):
        self.mem = mem
        self.reg = [dict(lc=0, len=0, per=428, vol=0) for _ in range(4)]
        self.ch = [dict(on=False, ptr=0, left=0, pos=0.0) for _ in range(4)]
        self.dma = 0
    def w16(self, a, v):
        r = a & 0x1FF
        if r == 0x96:                            # DMACON
            old = self.dma
            if v & 0x8000:
                self.dma |= v & 15
            else:
                self.dma &= ~v & 15
            for c in range(4):
                if self.dma & (1 << c) and not old & (1 << c):
                    self.start(c)
                if not self.dma & (1 << c):
                    self.ch[c]['on'] = False
        elif 0xA0 <= r < 0xE0:
            c, o = (r - 0xA0) >> 4, (r - 0xA0) & 15
            g = self.reg[c]
            if o == 0:   g['lc'] = (g['lc'] & 0xFFFF) | (v << 16)
            elif o == 2: g['lc'] = (g['lc'] & 0xFFFF0000) | v
            elif o == 4: g['len'] = v
            elif o == 6: g['per'] = v
            elif o == 8: g['vol'] = min(v & 127, 64)
    def w32(self, a, v):
        self.w16(a, v >> 16); self.w16(a + 2, v & 0xFFFF)
    def start(self, c):
        g, ch = self.reg[c], self.ch[c]
        ch.update(on=True, ptr=g['lc'] & 0xFFFFE, left=(g['len'] or 0x10000) * 2, pos=0.0)
    def mix(self, n):
        out = [0.0] * n
        for c in range(4):
            ch, g = self.ch[c], self.reg[c]
            if not ch['on'] or g['per'] < 64:
                continue
            step = PAL / g['per'] / RATE
            vol = g['vol'] / 64.0
            for i in range(n):
                k = int(ch['pos'])
                if k >= ch['left']:
                    ch['pos'] -= ch['left']
                    ch['ptr'], ch['left'] = g['lc'] & 0xFFFFE, (g['len'] or 0x10000) * 2
                    k = int(ch['pos'])
                    if ch['left'] <= 2:          # a 1-word "stop" sample
                        break
                out[i] += self.mem.r8s(ch['ptr'] + k) * vol
                ch['pos'] += step
        return out

_MC = None
_PAULA = [None]

def machine(files, fn, base):
    """One emulator for everything (Musashi is a single global CPU, and its
    I/O hooks can only be set once): cleared and loaded for each run."""
    global _MC
    if _MC is None:
        _MC = m68.Machine(m68.CPUType.M68000, 1024)
        mem = _MC.mem
        beam = [0]
        def r16(a):                              # VHPOSR moves on, the rest reads 0
            if a & 0x1FF == 6:
                beam[0] = (beam[0] + 0x37) & 0xFFFF
                return beam[0]
            return 0
        mem.set_special_range_write_funcs(0xDF0000, 1, w8=lambda a, v: None,
                                          w16=lambda a, v: _PAULA[0].w16(a, v),
                                          w32=lambda a, v: _PAULA[0].w32(a, v))
        mem.set_special_range_read_funcs(0xDF0000, 1, r8=lambda a: r16(a & ~1) >> (0 if a & 1 else 8) & 255,
                                         r16=r16, r32=lambda a: (r16(a) << 16) | r16(a + 2))
        mem.set_invalid_func(lambda *args: None)  # the CIAs (the TFMX replay sets the filter LED)
    mem = _MC.mem
    mem.clear_block(0, 0x100000, 0)
    mem.w_block(base, open(os.path.join(files, fn), 'rb').read())
    mem.w16(RET, 0x4E72); mem.w16(RET + 2, 0x2700)
    _PAULA[0] = Paula(mem)
    return _MC, _PAULA[0]

def call(mc, entry, **regs):
    mem, cpu = mc.mem, mc.cpu
    mem.w32(0, 0x80000); mem.w32(4, entry)
    cpu.pulse_reset()                            # leaves the STOP state; PC <- vector 1
    for k in range(8):                           # a clean register set every call
        cpu.w_reg(getattr(m68.Register, f'D{k}'), 0)
        if k < 7:
            cpu.w_reg(getattr(m68.Register, f'A{k}'), 0)
    for r, v in regs.items():
        cpu.w_reg(getattr(m68.Register, r.upper()), v & 0xFFFFFFFF)
    cpu.w_reg(m68.Register.A7, 0x7FFFC); mem.w32(0x7FFFC, RET)
    for _ in range(500):
        cpu.execute(4000)
        if cpu.r_pc() in (RET + 4, RET):
            break
    return cpu.r_reg(m68.Register.D0) & 0xFF, cpu.r_reg(m68.Register.D4) & 0xFF

def run_title(files, seconds):
    """The TFMX title music: init (d0 = mdat, d1 = smpl), start song 0, then
    the play routine every VBL - as stage 2 does."""
    mc, paula = machine(files, 'music_52300.bin', 0x52300)
    call(mc, 0x52334, d0=0x6FD28, d1=0x53768)
    call(mc, 0x5232C, d0=0)
    s = []
    for f in range(seconds * 50):
        call(mc, 0x52324)
        s += paula.mix(RATE // 50)
    return s

def run(name, fn, base, entry, files, kind, n, seconds):
    mc, paula = machine(files, fn, base)
    c = lambda **r: call(mc, entry, **r)
    samples, frames = [], seconds * 50
    per_frame = RATE // 50
    for f in range(frames):
        if kind == 'shared':
            d0, _ = c(d0=0xFF if f == 0 else 2)
            done = d0 == 0 and f > 0
        elif kind == 'tune':
            d0, _ = c(d1=n if f == 0 else 2, d3=0xFFFF if f == 0 else 2)
            done = d0 == 0 and f > 0
        else:
            _, d4 = c(d4=(n << 8) | 0xFF if f == 0 else 1)
            done = d4 & 0x80 and f > 0
        samples += paula.mix(per_frame)
        if done:
            samples += paula.mix(RATE // 2)
            break
    return samples

NAMES = {'tune0': 'music', 'tune1': 'boss', 'jingle0': 'gameover', 'jingle1': 'stageclear',
         'jingle2': 'start'}

def main():
    import hashlib
    files, out = sys.argv[1], sys.argv[2]
    seconds = int(sys.argv[sys.argv.index('--seconds') + 1]) if '--seconds' in sys.argv else 90
    mp3 = '--mp3' in sys.argv
    os.makedirs(out, exist_ok=True)
    seen, index = {}, []
    def save(fname, s):
        pcm = struct.pack('<%dh' % len(s), *(max(-32767, min(32767, int(x * 32767 / 128 / 3))) for x in s))
        path = os.path.join(out, fname + '.wav')
        with wave.open(path, 'wb') as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(pcm)
        if mp3:
            subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', path, '-b:a', '48k',
                            path[:-4] + '.mp3'], check=True)
            os.remove(path)
        return pcm
    s = run_title(files, max(seconds, 120))
    save('title', s)
    index.append(('tfmx', 'title', f'title ({len(s) / RATE:.1f} s)'))
    for name, fn, base, entry in PLAYERS:
        if name in ('shared', 'level8end'):        # called like UpdateJingle: d0 = $FF, then 2
            jobs = [('shared', 'shared', 0)]
        else:
            jobs = [(f'tune{k}', 'tune', k) for k in range(2)] + [(f'jingle{k}', 'jingle', k) for k in range(3)]
        for label, kind, n in jobs:
            s = run(name, fn, base, entry, files, kind, n, seconds)
            if max((abs(x) for x in s), default=0) < 1:
                index.append((name, label, 'silent')); continue
            pcm = struct.pack('<%dh' % len(s), *(max(-32767, min(32767, int(x * 32767 / 128 / 3))) for x in s))
            h = hashlib.md5(pcm).hexdigest()
            if h in seen:
                index.append((name, label, 'same as ' + seen[h])); continue
            fname = ('ending' if name == 'level8end' else 'highscore' if name == 'shared'
                     else f'{name}_music' if label == 'tune0' else NAMES[label])
            seen[h] = fname
            save(fname, s)
            index.append((name, label, f'{fname} ({len(s) / RATE:.1f} s)'))
    for row in index:
        print('%-10s %-8s %s' % row)

if __name__ == '__main__':
    main()
