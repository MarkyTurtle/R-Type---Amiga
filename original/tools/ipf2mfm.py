#!/usr/bin/env python3
"""Decode a CAPS/SPS IPF image into raw MFM track bitstreams.

Writes one file per track: <outdir>/trk_TT_S.mfm (bytes of MFM cells, MSB first)
plus index.json describing each track (bit length, block count, encoder).

Gap streams are not reproduced exactly - gaps are filled with MFM-encoded 0x00
(0xAAAA pattern) of the documented length, which is fine for analysis/loading.
"""
import json, os, struct, sys

def mfm_encode_bits(data_bits, prev):
    """data_bits: list of 0/1 data bits -> list of MFM cells. prev = last cell bit."""
    out = []
    for b in data_bits:
        clk = 1 if (prev == 0 and b == 0) else 0
        out += [clk, b]
        prev = b
    return out, prev

def bytes_to_bits(bs, nbits=None):
    bits = []
    for x in bs:
        for i in range(7, -1, -1):
            bits.append((x >> i) & 1)
    return bits if nbits is None else bits[:nbits]

def parse(path):
    d = open(path, 'rb').read()
    p = 0
    imges = {}
    datas = {}
    while p < len(d):
        typ = d[p:p+4]
        ln = struct.unpack('>I', d[p+4:p+8])[0]
        if typ == b'IMGE':
            f = struct.unpack('>14I', d[p+12:p+12+56])
            rec = dict(track=f[0], side=f[1], density=f[2], signal=f[3], trackBytes=f[4],
                       startBytePos=f[5], startBitPos=f[6], dataBits=f[7], gapBits=f[8],
                       trackBits=f[9], blockCount=f[10], encoder=f[11], trackFlags=f[12],
                       dataKey=f[13])
            imges[rec['dataKey']] = rec
            p += ln
        elif typ == b'DATA':
            length, bitsize, crc, key = struct.unpack('>4I', d[p+12:p+28])
            datas[key] = d[p+28:p+28+length]
            p += ln + length
        else:
            p += ln
    return imges, datas

def decode_track(img, extra):
    nb = img['blockCount']
    cells = []
    prev = 0
    for b in range(nb):
        bd = struct.unpack('>8I', extra[b*32:b*32+32])
        dataBits, gapBits = bd[0], bd[1]
        blockFlags, gapDefault, dataOffset = bd[5], bd[6], bd[7]
        in_bits = bool(blockFlags & 4)
        blk = []
        q = dataOffset
        while True:
            hdr = extra[q]; q += 1
            typ = hdr & 0x1f; sz = hdr >> 5
            if typ == 0:
                break
            n = int.from_bytes(extra[q:q+sz], 'big'); q += sz
            nbits = n if in_bits else n * 8
            nbytes = (nbits + 7) // 8
            payload = extra[q:q+nbytes]; q += nbytes
            bits = bytes_to_bits(payload, nbits)
            if typ in (1, 4):          # sync / raw: already MFM cells
                blk += bits
                prev = bits[-1] if bits else prev
            elif typ == 2:             # data: encode to MFM
                enc, prev = mfm_encode_bits(bits, prev)
                blk += enc
            elif typ == 3:             # gap marker inside data stream
                enc, prev = mfm_encode_bits(bits, prev)
                blk += enc
            elif typ == 5:             # fuzzy (weak) bits: zero-fill
                enc, prev = mfm_encode_bits([0]*nbits, prev)
                blk += enc
        cells += blk
        # gap: fill with encoded zeros to gapBits cells
        g = gapBits // 2
        enc, prev = mfm_encode_bits([0]*g, prev)
        cells += enc
    return cells

def main():
    src, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    imges, datas = parse(src)
    index = []
    for key, img in sorted(imges.items(), key=lambda kv: (kv[1]['track'], kv[1]['side'])):
        extra = datas[key]
        name = f"trk_{img['track']:02d}_{img['side']}.mfm"
        if img['blockCount'] == 0:
            index.append(dict(img, file=None)); continue
        cells = decode_track(img, extra)
        # pack
        b = bytearray()
        for i in range(0, len(cells) - 7, 8):
            v = 0
            for c in cells[i:i+8]:
                v = (v << 1) | c
            b.append(v)
        open(os.path.join(outdir, name), 'wb').write(b)
        index.append(dict(img, file=name, cells=len(cells)))
    json.dump(index, open(os.path.join(outdir, 'index.json'), 'w'), indent=1)
    print(f"{len(index)} tracks")

if __name__ == '__main__':
    main()
