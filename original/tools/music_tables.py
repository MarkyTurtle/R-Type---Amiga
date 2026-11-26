#!/usr/bin/env python3
"""Locate the in-game music tables and extract the samples as WAV.

usage: python3 -I tools/music_tables.py files/ music/

Each level's music player (LV_Music, in level B) and the shared jingle
player are variants of one sequencer (docs/MUSIC.md).  The tables are found
from the code that uses them: after the pattern multiply ('mulu') the
player loads, in order, the sample table, the sample data and the period
table.  Writes music/<player>_sNN.wav (8-bit, played at C-2 = period 428)
and prints the table addresses.
"""
import os, re, struct, sys, wave
import capstone

MD = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000)
PLAYERS = [('shared', 'shared_4a300.bin', 0x4A300, 0x4A300)] + \
    [(f'level{n}', f'level{n}_b_4d300.bin', 0x4D300, a) for n, a in
     [(1, 0x5CA38), (2, 0x5E948), (3, 0x634D0), (4, 0x52078),
      (5, 0x51A54), (6, 0x5C9A8), (7, 0x582A4), (8, 0x5C1FE)]] + \
    [('level8end', 'level8_b_4d300.bin', 0x4D300, 0x5F244)]

def pc_lea(i):
    if i.mnemonic.startswith('lea') and '(pc)' in i.op_str:
        return int(re.match(r'\$([0-9a-f]+)\(pc\)', i.op_str).group(1), 16)
    return None

def disasm(buf, base, start, length):
    """Linear disassembly that steps over words capstone can't decode
    (the players keep variables between their routines)."""
    out, a = [], start
    while a < start + length:
        got = list(MD.disasm(buf[a - base:start - base + length], a))
        out += got
        a = (got[-1].address + got[-1].size) if got else a
        a += 2 if not got or a < start + length else 0
    return out

def tables(buf, base, start):
    ins = disasm(buf, base, start, 0x500)
    k = next(n for n, i in enumerate(ins) if i.mnemonic.startswith('mulu'))
    after = [pc_lea(i) for i in ins[k:k + 40] if pc_lea(i)]
    sizes = sorted({int(m.group(1), 16) for i in ins[:k] for m in
                    [re.match(r'#\$([0-9a-f]+), \(a0\)$', i.op_str)] if m and i.mnemonic == 'move.w'
                    and int(m.group(1), 16) in (0x42, 0x62)})
    return dict(sampletab=after[0], samples=after[1], periods=after[2],
                pattern_sizes=sizes or [0x62], mulu=ins[k].op_str)

def main():
    files, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    for name, fn, base, start in PLAYERS:
        buf = open(os.path.join(files, fn), 'rb').read()
        t = tables(buf, base, start)
        n = (t['periods'] - t['sampletab']) // 8
        rd = lambda a, k: buf[a - base:a - base + k]
        written = 0
        for s in range(n):
            off, _, words = struct.unpack('>IHH', rd(t['sampletab'] + s * 8, 8))
            if words <= 1:
                continue
            data = rd(t['samples'] + off, words * 2)
            with wave.open(os.path.join(out, f'{name}_s{s:02d}.wav'), 'wb') as w:
                w.setnchannels(1); w.setsampwidth(1); w.setframerate(8287)
                w.writeframes(bytes((b + 128) & 255 for b in data))
            written += 1
        print(f"{name:7} player ${start:05X}  samples ${t['sampletab']:05X} ({n})  data ${t['samples']:05X}"
              f"  periods ${t['periods']:05X}  pattern ${'/$'.join(f'{x:X}' for x in t['pattern_sizes'])}"
              f"  mulu {t['mulu']}  -> {written} wav")

if __name__ == '__main__':
    main()
