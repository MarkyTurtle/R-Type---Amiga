"""MFM helpers: bit access, sync search, Amiga odd/even decoding."""
import os, json

def load_bits(path):
    d = open(path, 'rb').read()
    return d

class Bits:
    def __init__(self, data):
        self.d = data
        self.n = len(data) * 8
        self.i = int.from_bytes(data, 'big')
    def word(self, pos, nbits=16):
        sh = self.n - pos - nbits
        if sh < 0:
            return None
        return (self.i >> sh) & ((1 << nbits) - 1)
    def find(self, pattern, nbits=16, start=0):
        out = []
        for p in range(start, self.n - nbits):
            if self.word(p, nbits) == pattern:
                out.append(p)
        return out
    def raw_longs(self, pos, count):
        return [self.word(pos + 32 * k, 32) for k in range(count)]

def odd_even_long(odd, even):
    return ((odd & 0x55555555) << 1) | (even & 0x55555555)

def decode_amigados_track(bits):
    """Return dict sector->(header info, 512 bytes, ok flags)."""
    B = Bits(bits)
    sectors = {}
    syncs = B.find(0x44894489, 32)
    for s in syncs:
        p = s + 32
        lw = B.raw_longs(p, 2 + 8 + 2 + 2 + 2 + 256)
        if None in lw:
            continue
        info = odd_even_long(lw[0], lw[1])
        fmt, trk, sec, left = info >> 24, (info >> 16) & 0xff, (info >> 8) & 0xff, info & 0xff
        hck = odd_even_long(lw[10], lw[11])
        dck = odd_even_long(lw[12], lw[13])
        hsum = 0
        for x in lw[0:10]:
            hsum ^= x
        hsum &= 0x55555555
        odd = lw[14:14 + 128]; even = lw[14 + 128:14 + 256]
        data = bytearray()
        dsum = 0
        for x in odd + even:
            dsum ^= x
        dsum &= 0x55555555
        for o, e in zip(odd, even):
            data += odd_even_long(o, e).to_bytes(4, 'big')
        sectors[sec] = dict(fmt=fmt, trk=trk, left=left, data=bytes(data),
                            hok=(hsum == hck), dok=(dsum == dck))
    return sectors
