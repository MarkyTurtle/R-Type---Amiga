#!/usr/bin/env python3
"""Build an R-Type disk image (WinUAE extended ADF) from files and sources.

usage: python3 -I tools/build_disk.py [--from-source] [--keep-mfm DIR] OUT.adf

Every file goes back on the track(s) it came from (docs/DISK_FORMAT.md):
  tracks 0-9    AmigaDOS sectors: bootblock + boot read (title gfx, stage 2)
  tracks 10-62  short $9521 tracks ($1750 bytes): music, game, $6000 block
  tracks 63-158 long $9521 tracks ($1998 bytes): shared file, levels
  track 68      high-score track ($4489), written with a VALID checksum
                and the default table from the game program, so saving
                works (the factory disk's placeholder never loads)
  track 159     unformatted
With --from-source the sources in src/ are assembled first (vasm, VASM
env) and replace the matching files: bootblock, stage 2, game program,
shared file and level A files.  The bootblock checksum is recomputed.

The output is the "UAE-1ADF" extended ADF: tracks 0-9 as AmigaDOS tracks,
the rest as raw MFM.  After writing, every raw track is decoded again
with the extractor's decoders and compared with its input (--keep-mfm
writes the raw tracks out as well).
"""
import argparse, os, struct, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

M = 0x55555555
SHORT, LONG = 0x1750, 0x1998
SHORT_BITS, LONG_BITS = 100064, 105344      # like the original tracks
VASM = os.environ.get('VASM', 'vasmm68k_mot')

# --- MFM encoding ------------------------------------------------------------
class Track:
    """Builds a raw MFM bitstream: data bits get clock bits, syncs go raw."""
    def __init__(self):
        self.cells = []
        self.prev = 0
    def raw(self, word, bits=16):
        for i in range(bits - 1, -1, -1):
            self.cells.append((word >> i) & 1)
        self.prev = self.cells[-1]
    def data_bits(self, value, n):
        for i in range(n - 1, -1, -1):
            d = (value >> i) & 1
            self.cells += [1 if (self.prev == 0 and d == 0) else 0, d]
            self.prev = d
    def data_long(self, raw_data_part):
        """One raw MFM long whose data bits are raw_data_part & $55555555."""
        v = 0
        for i in range(15, -1, -1):
            v = (v << 1) | ((raw_data_part >> (2 * i)) & 1)
        self.data_bits(v, 16)
    def gap(self, words):
        for _ in range(words):
            self.data_bits(0, 8)
    def finish(self, total_bits):
        if len(self.cells) > total_bits:
            raise ValueError(f'track too long: {len(self.cells)} > {total_bits}')
        while len(self.cells) < total_bits:
            self.data_bits(0, 1)
        b = bytearray()
        for i in range(0, total_bits, 8):
            v = 0
            for c in self.cells[i:i + 8]:
                v = (v << 1) | c
            b.append(v << (8 - len(self.cells[i:i + 8])) & 255)
        return bytes(b)

def odd_even(v):
    return (v >> 1) & M, v & M

def longs(data):
    return list(struct.unpack(f'>{len(data) // 4}I', data))

def short_track(data):
    """Stage-2 format: $9521, word, checksum, all odd longs, all even longs."""
    L = longs(data)
    odd = [odd_even(v)[0] for v in L]
    even = [odd_even(v)[1] for v in L]
    ck = 0
    for v in odd + even:
        ck ^= v
    t = Track(); t.gap(8); t.raw(0x9521)
    t.data_bits(0, 8)                          # the skipped word (one MFM word)
    t.data_long(ck & M)
    for v in odd + even:
        t.data_long(v)
    t.gap(4)
    return t.finish(SHORT_BITS)

def long_track(data):
    """Game format: $9521, word, (odd, even) pairs, checksum pair ^ $AAAAAAAA."""
    L = longs(data)
    pairs = [x for v in L for x in odd_even(v)]
    ck = 0
    for v in pairs:
        ck ^= v
    t = Track(); t.gap(8); t.raw(0x9521)
    t.data_bits(0, 8)                          # the skipped word (one MFM word)
    for v in pairs:
        t.data_long(v)
    for v in odd_even((ck & M) ^ 0xAAAAAAAA):
        t.data_long(v)
    t.gap(4)
    return t.finish(LONG_BITS)

def hiscore_track(table):
    """$4489, word, checksum pair (^ $12345678), zero pair, 100 (odd, even)."""
    L = longs(table.ljust(400, b'\0')[:400])
    pairs = [x for v in L for x in odd_even(v)]
    ck = 0
    for v in pairs:
        ck ^= v
    t = Track(); t.gap(8); t.raw(0x4489)
    t.data_bits(0, 8)                          # the skipped word (one MFM word)
    for v in odd_even((ck & M) ^ 0x12345678):
        t.data_long(v)
    t.data_long(0); t.data_long(0)
    for v in pairs:
        t.data_long(v)
    t.gap(4)
    return t.finish(SHORT_BITS)

def unformatted():
    t = Track(); return t.finish(SHORT_BITS)

# --- inputs ------------------------------------------------------------------
def bootblock_checksum(bb):
    bb = bytearray(bb); bb[4:8] = b'\0' * 4
    s = 0
    for (v,) in struct.iter_unpack('>I', bytes(bb)):
        s += v
        if s > 0xFFFFFFFF:
            s = (s & 0xFFFFFFFF) + 1
    bb[4:8] = struct.pack('>I', ~s & 0xFFFFFFFF)
    return bytes(bb)

def assemble(src, out):
    subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', '-I', os.path.join(ROOT, 'src'),
                    '-o', out, os.path.join(ROOT, src)], check=True)
    return open(out, 'rb').read()

def inputs(from_source):
    f = lambda n: open(os.path.join(ROOT, 'files', n), 'rb').read()
    d = {n: f(n) for n in os.listdir(os.path.join(ROOT, 'files')) if not n.endswith('.json')}
    if from_source:
        tmp = tempfile.mkdtemp()
        srcs = {'bootblock.bin': 'src/bootblock.s', 'stage2_79360.bin': 'src/stage2.s',
                'game_low_000a4.bin': 'src/game.s', 'shared_4a300.bin': 'src/shared.s'}
        srcs.update({f'level{n}_a_4a2e4.bin': f'src/levels/level{n}.s' for n in range(1, 9)})
        for name, src in srcs.items():
            d[name] = assemble(src, os.path.join(tmp, name))
        d['bootblock.bin'] = bootblock_checksum(d['bootblock.bin'])
    return d

def pad(data, size, what):
    if len(data) > size:
        raise ValueError(f'{what}: {len(data)} bytes, room for {size}')
    return data + bytes(size - len(data))

def layout(d):
    """track number -> ('dos', 5632 bytes) | ('short'|'long', data) | ..."""
    tracks = {}
    boot = pad(d['title_gfx_35fa0.bin'] + d['stage2_79360.bin'], 0xB800, 'boot read')
    dos = pad(pad(d['bootblock.bin'], 0x400, 'bootblock') + boot, 10 * 11 * 512, 'DOS area')
    for t in range(10):
        tracks[t] = ('dos', dos[t * 5632:(t + 1) * 5632])
    def put(kind, first, count, data, what):
        size = SHORT if kind == 'short' else LONG
        data = pad(data, count * size, what)
        for k in range(count):
            tracks[first + k] = (kind, data[k * size:(k + 1) * size])
    put('short', 10, 22, d['music_52300.bin'], 'music')
    put('short', 32, 4, d['game_low_000a4.bin'], 'game program')
    put('short', 36, 27, d['game_main_06000.bin'], '$6000 block')
    put('long', 63, 5, d['shared_4a300.bin'], 'shared file')
    low = d['game_low_000a4.bin']
    tracks[68] = ('hiscore', low[0x575C - 0xA4:0x575C - 0xA4 + 400])
    for n in range(8):
        ta, na, tb, nb, _ = struct.unpack('>5H', low[0x41B4 - 0xA4 + n * 10:][:10])
        put('long', ta, na, d[f'level{n + 1}_a_4a2e4.bin'], f'level {n + 1} A')
        put('long', tb, nb, d[f'level{n + 1}_b_4cb00.crunched'], f'level {n + 1} B')
    tracks[159] = ('none', b'')
    return tracks

# --- output ------------------------------------------------------------------
def encode(kind, data):
    return {'short': short_track, 'long': long_track, 'hiscore': hiscore_track}[kind](data) \
        if kind in ('short', 'long', 'hiscore') else unformatted()

def write_adf(path, tracks, keep):
    heads, blobs = [], []
    for t in range(160):
        kind, data = tracks[t]
        if kind == 'dos':
            blob, typ, bits = data, 0, len(data) * 8
        else:
            blob = encode(kind, data)
            typ, bits = 1, (SHORT_BITS if kind != 'long' else LONG_BITS)
            if keep:
                open(os.path.join(keep, f'trk_{t >> 1:02d}_{t & 1}.mfm'), 'wb').write(blob)
        heads.append(struct.pack('>HHII', 0, typ, len(blob), bits))
        blobs.append(blob)
    with open(path, 'wb') as f:
        f.write(b'UAE-1ADF' + struct.pack('>HH', 0, 160) + b''.join(heads) + b''.join(blobs))

def verify(tracks, mfmdir):
    from extract import Disk
    D = Disk(mfmdir)
    for t, (kind, data) in tracks.items():
        if kind == 'short':
            assert D.short_track(t) == data, f'track {t}'
        elif kind == 'long':
            assert D.long_track(t) == data, f'track {t}'
        elif kind == 'hiscore':
            got, ok = D.hiscore_track()
            assert ok and got == data.ljust(400, b'\0'), 'high-score track'

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--from-source', action='store_true')
    ap.add_argument('--keep-mfm')
    a = ap.parse_args()
    d = inputs(a.from_source)
    tracks = layout(d)
    keep = a.keep_mfm or tempfile.mkdtemp()
    os.makedirs(keep, exist_ok=True)
    write_adf(a.out, tracks, keep)
    verify(tracks, keep)
    print(f'{a.out}: 160 tracks written and verified '
          f'({"sources" if a.from_source else "extracted files"})')

if __name__ == '__main__':
    main()
