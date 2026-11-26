#!/usr/bin/env python3
"""Extract every file from the R-Type (Amiga) IPF image.

usage: python3 -I tools/extract.py disk/R-Type.ipf files/

R-Type's disk has no filesystem. Files are defined by the loaders:
  * bootblock      - trackdisk read of $B800 bytes from offset $400 -> $6EFA0
  * stage-2 loader - $79A50: "short" tracks (sync $9521, $1750 bytes) 10-62
  * game loader    - $3CC8 : "long"  tracks (sync $9521, $1998 bytes) 63-158
  * high scores    - $3FA2 : track 68, sync $4489, 100 longs, chk ^ $12345678
"""
import hashlib, json, os, struct, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from mfmlib import Bits, decode_amigados_track
from decrunch import decrunch

M = 0x55555555
SHORT, LONG = 0x1750, 0x1998

def oe(o, e):
    return ((o & M) << 1) | (e & M)

class Disk:
    def __init__(self, mfmdir):
        self.dir = mfmdir
    def bits(self, t):
        return Bits(open(f'{self.dir}/trk_{t >> 1:02d}_{t & 1}.mfm', 'rb').read())

    def dos_area(self):
        img = bytearray(10 * 11 * 512)
        for t in range(10):
            secs = decode_amigados_track(open(f'{self.dir}/trk_{t >> 1:02d}_{t & 1}.mfm', 'rb').read())
            assert len(secs) == 11 and all(s['hok'] and s['dok'] for s in secs.values()), t
            for k, s in secs.items():
                img[(t * 11 + k) * 512:(t * 11 + k + 1) * 512] = s['data']
        return bytes(img)

    def short_track(self, t):
        """Stage-2 loader format ($79A9A): skip word, chk, $5D4 odd longs, $5D4 even longs."""
        B = self.bits(t)
        p = B.find(0x9521)[0] + 32               # skip sync + 1 word
        ck = B.word(p, 32) & M
        raw = B.raw_longs(p + 32, 2 * (SHORT // 4))
        x = 0
        for v in raw: x ^= v
        assert x & M == ck, f'short track {t} checksum'
        n = SHORT // 4
        return b''.join(oe(raw[i], raw[n + i]).to_bytes(4, 'big') for i in range(n))

    def long_track(self, t):
        """Game loader format ($3D06): skip word, $666 (odd,even) pairs, chk pair (^$AAAAAAAA)."""
        B = self.bits(t)
        p = B.find(0x9521)[0] + 32
        raw = B.raw_longs(p, 2 * (LONG // 4) + 2)
        x = 0
        for v in raw[:-2]: x ^= v
        assert (x & M) ^ 0xAAAAAAAA == oe(raw[-2], raw[-1]), f'long track {t} checksum'
        return b''.join(oe(raw[i], raw[i + 1]).to_bytes(4, 'big') for i in range(0, 2 * (LONG // 4), 2))

    def hiscore_track(self):
        """$3FA2: sync $4489, skip word, chk pair, 2 skipped longs, $5A..$64 (odd,even) pairs."""
        B = self.bits(68)
        p = B.find(0x4489)[0] + 32
        raw = B.raw_longs(p, 4 + 200)
        ck = oe(raw[0], raw[1]) ^ 0x12345678
        x = 0
        for v in raw[4:204]: x ^= v
        data = b''.join(oe(raw[i], raw[i + 1]).to_bytes(4, 'big') for i in range(4, 204, 2))
        # The mastered track only holds 209 data bytes after the sync, so this
        # checksum fails on an original disk: the game keeps its defaults at $575C.
        return data, (x & M) == ck

def main():
    ipf, out = sys.argv[1], sys.argv[2]
    mfm = os.path.join(out, '_mfm')
    subprocess.run([sys.executable, '-I', os.path.join(HERE, 'ipf2mfm.py'), ipf, mfm], check=True)
    D = Disk(mfm)
    files = []
    def emit(name, data, **info):
        open(os.path.join(out, name), 'wb').write(data)
        files.append(dict(name=name, size=len(data), sha1=hashlib.sha1(data).hexdigest(), **info))

    dos = D.dos_area()
    emit('bootblock.bin', dos[:0x400], source='cyl 0 sectors 0-1', load='$7xxxx (exec)', note='DOS\\0 bootblock')
    boot = dos[0x400:0x400 + 0xB800]
    emit('boot_6efa0.bin', boot, source='DOS blocks 2-93', load='$6EFA0',
         note='whole bootblock read (title gfx + stage-2 loader)')
    emit('title_gfx_35fa0.bin', boot[:0xA3C0], load='$35FA0 (copied from $6EFA0)',
         note='title picture 320x200x5 ($1F40/plane) + font at $3FBE0 ($780)')
    emit('stage2_79360.bin', boot[0xA3C0:], load='$79360', note='stage-2 loader / intro credits')

    def shorts(a, n): return b''.join(D.short_track(t) for t in range(a, a + n))
    def longs(a, n):  return b''.join(D.long_track(t) for t in range(a, a + n))

    emit('music_52300.bin', shorts(10, 22), tracks='10-31', load='$52300', note='music + replay (copied to fast RAM if present, $1F73C used)')
    emit('game_low_000a4.bin', shorts(32, 4), tracks='32-35', load='$000A4', note='game low code: entry $C0, disk/decrunch routines')
    emit('game_main_06000.bin', shorts(36, 27), tracks='36-62', load='$06000', note='game main code/data')
    emit('shared_4a300.bin', longs(63, 5), tracks='63-67', load='$4A300', note='loaded by $3A0E at start-up')
    hs, hs_ok = D.hiscore_track()
    emit('hiscore_trk68.bin', hs, tracks='68', load='$575C', checksum_ok=hs_ok,
         note='high-score save track (factory placeholder - fails checksum, defaults used)')

    mem = bytearray(0x6000); low = shorts(32, 4); mem[0xA4:0xA4 + len(low)] = low
    tab = 0x41B4
    for lv in range(8):
        ta, na, tb, nb, extra = struct.unpack('>5H', mem[tab + lv * 10: tab + lv * 10 + 10])
        a = longs(ta, na)
        emit(f'level{lv + 1}_a_4a2e4.bin', a, tracks=f'{ta}-{ta + na - 1}', load='$4A2E4',
             note=f'effective size $281C (overlapped by part B); $F4 <- ${extra:X}')
        b = longs(tb, nb)
        emit(f'level{lv + 1}_b_4cb00.crunched', b, tracks=f'{tb}-{tb + nb - 1}', load='$4CB00')
        dec, ck, L = decrunch(b)
        assert ck == 0, f'level {lv + 1} decrunch checksum'
        emit(f'level{lv + 1}_b_4d300.bin', dec, load='$4D300', note=f'decrunched from ${L:X} bytes')

    json.dump(files, open(os.path.join(out, 'manifest.json'), 'w'), indent=1)
    for f in files:
        print(f"{f['name']:<28} {f['size']:>7}  {f.get('tracks', ''):<7} {f['load']}")

if __name__ == '__main__':
    main()
