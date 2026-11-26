#!/usr/bin/env python3
"""Decode R-Type custom tracks (sync $9521, $1750 bytes, odd/even split).

Format as read by the loader at $79A50:
  $9521 (DSKSYNC, not stored) | 1 word skipped | checksum long (odd/even? -> masked raw)
  | $5D4 odd longs | $5D4 even longs
checksum = EOR of all $BA8 raw data longs, masked $55555555.
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mfmlib import Bits

M = 0x55555555
NL = 0x5d4

def decode(path):
    B = Bits(open(path, 'rb').read())
    res = []
    for s in B.find(0x9521, 16):
        p = s + 16                      # first word stored after sync
        nxt = B.word(p)
        ck = B.word(p + 16, 32)
        if ck is None: continue
        raw = B.raw_longs(p + 48, 2 * NL)
        if None in raw: continue
        x = 0
        for v in raw: x ^= v
        ok = (x & M) == (ck & M)
        data = bytearray()
        for o, e in zip(raw[:NL], raw[NL:]):
            data += (((o & M) << 1) | (e & M)).to_bytes(4, 'big')
        res.append(dict(pos=s, next=nxt, ok=ok, data=bytes(data)))
    return res

if __name__ == '__main__':
    mfm, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    report = []
    img = bytearray()
    for t in range(160):
        cyl, side = t >> 1, t & 1
        f = f'{mfm}/trk_{cyl:02d}_{side}.mfm'
        if t < 10 or not os.path.exists(f):
            report.append((t, 'dos' if t < 10 else 'missing')); img += bytes(0x1750); continue
        r = decode(f)
        good = [x for x in r if x['ok']]
        if good:
            img += good[0]['data']
            report.append((t, f"ok syncs={len(r)} next=${good[0]['next']:04x} pos={good[0]['pos']}"))
        else:
            img += bytes(0x1750)
            report.append((t, f"FAIL syncs={len(r)}"))
    open(os.path.join(out, 'custom_tracks.bin'), 'wb').write(img)
    for t, s in report: print(t, s)
