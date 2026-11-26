#!/usr/bin/env python3
"""Rebuild the AmigaDOS area (cyls 0-4) as an ADF fragment; report sector health."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from mfmlib import decode_amigados_track
mfm, out = sys.argv[1], sys.argv[2]
img = bytearray(80*2*11*512)
for t in range(5):
    for s in range(2):
        tn = t*2+s
        secs = decode_amigados_track(open(f'{mfm}/trk_{t:02d}_{s}.mfm','rb').read())
        bad = [k for k,v in secs.items() if not (v['hok'] and v['dok'])]
        print(f'track {tn}: {len(secs)} sectors, bad={bad}, trk ids={sorted(set(v["trk"] for v in secs.values()))}')
        for k,v in secs.items():
            if k < 11:
                off = (tn*11+k)*512; img[off:off+512] = v['data']
open(out,'wb').write(img[:10*11*512])
