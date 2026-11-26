"""Python port of R-Type's decruncher at $3EFC (ByteKiller-style, backwards).

Crunched file layout (longs, big-endian):
  +0         crunched length L (offset from file start to end of stream)
  ...        bitstream longs, consumed backwards
  L-12       first bitstream long
  L-8        checksum (EOR of all stream longs must give 0 at the end)
  L-4        decrunched length
Output is written from dest+len downwards.
"""
import struct

def decrunch(src):
    L = struct.unpack('>I', src[0:4])[0]
    p = L                                    # a0 = start + (a0)
    def rd():
        nonlocal p
        p -= 4
        return struct.unpack('>I', src[p:p+4])[0]
    outlen = rd()
    out = bytearray(outlen)
    a2 = outlen
    d5 = rd()
    d0 = rd(); d5 ^= d0
    state = {'d0': d0, 'd5': d5}

    def bit():
        d0 = state['d0']
        c = d0 & 1
        d0 >>= 1
        if d0 == 0:                          # sentinel reached: refill
            n = rd()
            state['d5'] ^= n
            c = n & 1
            d0 = (n >> 1) | 0x80000000       # roxr with X=1
        state['d0'] = d0
        return c

    def bits(n):
        v = 0
        for _ in range(n):
            v = (v << 1) | bit()
        return v

    while a2 > 0:
        if bit() == 0:
            if bit() == 0:                   # 00: 1-8 literals
                cnt = bits(3) + 1
                for _ in range(cnt):
                    a2 -= 1; out[a2] = bits(8)
            else:                            # 01: 2-byte copy, 8-bit offset
                off = bits(8)
                for _ in range(2):
                    a2 -= 1; out[a2] = out[a2 + off]
        else:
            k = bits(2)
            if k == 3:                       # 111: 9-264 literals
                cnt = bits(8) + 9
                for _ in range(cnt):
                    a2 -= 1; out[a2] = bits(8)
            elif k == 2:                     # 110: n+1 copy, 12-bit offset
                cnt = bits(8) + 1
                off = bits(12)
                for _ in range(cnt):
                    a2 -= 1; out[a2] = out[a2 + off]
            else:                            # 100/101: 3/4-byte copy, 9/10-bit offset
                cnt = k + 3
                off = bits(9 + k)
                for _ in range(cnt):
                    a2 -= 1; out[a2] = out[a2 + off]
    return bytes(out), state['d5'] & 0xffffffff, L
