#!/usr/bin/env python3
"""Render R-Type graphics from the extracted files to PNG.

usage: python3 -I tools/render_gfx.py files/ gfx/

Writes, per level: levelN_tiles.png (tile sheet, 16 per row, numbered by
position), levelN_map.png (the whole map, as the game draws it) and
levelN_bobs.png (every frame of each object definition found in the level's
DATA, one row per definition).  From the $6000 block: sprites_ship.png,
sprites_bits.png, sprites_force0-3.png (hardware sprites, 16 colours) and
engine_bobs.png (explosions, walker, power-ups... defined in the game
program itself).
Formats: docs/GRAPHICS.md.
"""
import os, struct, sys
from PIL import Image

TILE_BYTES = 128          # 16x16, 4 interleaved planes
LEVEL_TABLE = 0x41B4      # in game_low_000a4.bin (loaded at $A4)
A_BASE, B_BASE = 0x4A2E4, 0x4D300

def rgb(c):
    return (((c >> 8) & 15) * 17, ((c >> 4) & 15) * 17, (c & 15) * 17)

class Level:
    def __init__(self, files, n):
        self.n = n
        low = open(os.path.join(files, 'game_low_000a4.bin'), 'rb').read()
        e = LEVEL_TABLE - 0xA4 + (n - 1) * 10
        self.row_bytes = struct.unpack('>H', low[e + 8:e + 10])[0]   # "MapWidth"
        self.a = open(os.path.join(files, f'level{n}_a_4a2e4.bin'), 'rb').read()
        self.b = open(os.path.join(files, f'level{n}_b_4d300.bin'), 'rb').read()
        t = struct.unpack('>12I', self.a[0x1C:0x1C + 48])
        self.map_ptr, self.tiles_ptr, self.music = t[3], t[4], t[10]
        pal = self.read(t[2], 30)
        self.palette = [(0, 0, 0)] + [rgb(c) for c in struct.unpack('>15H', pal)]
        if self.map_ptr >= B_BASE + len(self.b):
            # level 4: LevelInit copies the map from $50F00 to $6EA6A
            self.map_src = 0x50F00
        else:
            self.map_src = self.map_ptr
        self.rows = 26 if n == 3 else 13
        self.cols = self.row_bytes // 2

    def read(self, addr, size):
        if A_BASE <= addr < A_BASE + len(self.a) and addr < 0x4CB00:
            return self.a[addr - A_BASE:addr - A_BASE + size]
        return self.b[addr - B_BASE:addr - B_BASE + size]

    def cells(self):
        m = self.read(self.map_src, self.row_bytes * self.rows)
        return [[struct.unpack('>H', m[r * self.row_bytes + c * 2:][:2])[0]
                 for c in range(self.cols)] for r in range(self.rows)]

    def tile(self, t):
        d = self.read(self.tiles_ptr + t * TILE_BYTES, TILE_BYTES)
        px = []
        for y in range(16):
            planes = [struct.unpack('>H', d[(y * 4 + p) * 2:][:2])[0] for p in range(4)]
            px.append([sum(((planes[p] >> (15 - x)) & 1) << p for p in range(4)) for x in range(16)])
        return px

def paste(im, px, ox, oy, pal):
    for y, row in enumerate(px):
        for x, v in enumerate(row):
            im.putpixel((ox + x, oy + y), pal[v])

def render_level(files, out, n):
    L = Level(files, n)
    cells = L.cells()
    used = sorted({c & 0xFFF for row in cells for c in row})
    ntiles = used[-1] + 1
    cache = {t: L.tile(t) for t in range(ntiles)}
    per = 16
    sheet = Image.new('RGB', (per * 17, ((ntiles + per - 1) // per) * 17), (40, 0, 40))
    for t in range(ntiles):
        paste(sheet, cache[t], (t % per) * 17, (t // per) * 17, L.palette)
    sheet.save(os.path.join(out, f'level{n}_tiles.png'))
    im = Image.new('RGB', (L.cols * 16, L.rows * 16))
    for r, row in enumerate(cells):
        for c, v in enumerate(row):
            paste(im, cache[v & 0xFFF], c * 16, r * 16, L.palette)
    im.save(os.path.join(out, f'level{n}_map.png'))
    solid = sum(1 for row in cells for v in row if v & 0x8000)
    anim = sum(1 for row in cells for v in row if v & 0x4000)
    return dict(level=n, cols=L.cols, rows=L.rows, map=f'${L.map_ptr:05X}', tiles=ntiles,
                tiles_end=f'${L.tiles_ptr + ntiles * TILE_BYTES:05X}', solid=solid, animated=anim)

# --- BOBs ------------------------------------------------------------------
def find_definitions(L, mem_read, lo, hi):
    """Object definitions in a level's TEXT/DATA (see DATA_FORMATS.md)."""
    out = []
    for p in range(lo, hi - 0x28, 2):
        d = L.read(p, 0x1C)
        bs, mod, fs = struct.unpack('>HHH', d[:6])
        g, mo, an, hb = struct.unpack('>IIII', d[12:28])
        h, w = bs >> 6, bs & 63
        if fs and mo * 2 == fs and 0 < w <= 8 and h and h % 4 == 0 and mod == 52 - w * 2 \
                and (0x6000 <= g < 0x2D1BA or B_BASE <= g < B_BASE + len(L.b)) \
                and lo <= an < hi and lo <= hb < hi:
            out.append(dict(addr=p, lines=h // 4, words=w - 1, frame=fs, gfx=g, mask=mo, anim=an))
    return out

def bob_frame(data, lines, words, mask_ofs):
    """Interleaved BOB: each line = plane 0-3, 'words' wide; mask follows."""
    px = []
    for y in range(lines):
        row = []
        for wd in range(words):
            planes = [struct.unpack('>H', data[((y * 4 + p) * words + wd) * 2:][:2])[0] for p in range(4)]
            mask = struct.unpack('>H', data[mask_ofs + (y * 4 * words + wd) * 2:][:2])[0]
            for x in range(16):
                b = 15 - x
                row.append(sum(((planes[p] >> b) & 1) << p for p in range(4)) if (mask >> b) & 1 else None)
        px.append(row)
    return px

def render_bobs(files, out, n, low6000):
    L = Level(files, n)
    ts, ds = struct.unpack('>II', L.a[2:10])
    lo, hi = 0x4A300, 0x4A300 + ts + ds
    defs = find_definitions(L, None, lo, hi)
    # known block starts in the level B file: cap each definition's frames at
    # the next one (animation sequences can hold values that aren't frames)
    starts = sorted({d['gfx'] for d in defs} | {L.map_ptr, L.map_src, L.music, B_BASE + len(L.b)})
    rows = []
    for d in defs:
        nxt = min([a for a in starts if a > d['gfx']] or [d['gfx'] + 64 * d['frame']])
        seq = L.read(d['anim'], 64)
        frames = []
        for b in seq:
            if b >= 0x80: break
            frames.append(b)
        nfr = (max(frames) + 1) if frames else 1
        nfr = max(1, min(nfr, (nxt - d['gfx']) // d['frame']))
        imgs = []
        for f in range(min(nfr, 32)):
            a = d['gfx'] + f * d['frame']
            data = low6000[a:a + d['frame']] if a < 0x2D1BA else L.read(a, d['frame'])
            if len(data) < d['frame']:
                break                       # runs past the loaded data
            imgs.append(bob_frame(data, d['lines'], d['words'], d['mask']))
        if not imgs:
            continue
        rows.append((d, imgs))
    if not rows:
        return []
    W = max(sum(len(fr[0]) + 2 for fr in r[1]) for r in rows) + 2
    H = sum(max(len(fr) for fr in r[1]) + 3 for r in rows)
    sheet = Image.new('RGB', (W, H), (60, 0, 60))
    y = 1
    for d, imgs in rows:
        x = 1
        for fr in imgs:
            for yy, row in enumerate(fr):
                for xx, v in enumerate(row):
                    if v is not None:
                        sheet.putpixel((x + xx, y + yy), L.palette[v])
            x += len(fr[0]) + 2
        y += max(len(fr) for fr in imgs) + 3
    sheet.save(os.path.join(out, f'level{n}_bobs.png'))
    return [f"${d['addr']:05X}: {d['words']*16}x{d['lines']} x{len(i)} gfx ${d['gfx']:05X}" for d, i in rows]

# --- hardware sprites -------------------------------------------------------
def sprite_pair(data, a, h):
    """Attached pair at a: sprite A (ctl, h lines, end) then sprite B."""
    size = 4 + h * 4 + 4
    px = []
    for y in range(h):
        pa = struct.unpack('>HH', data[a + 4 + y * 4:][:4])
        pb = struct.unpack('>HH', data[a + size + 4 + y * 4:][:4])
        px.append([(((pa[0] >> (15 - x)) & 1) | (((pa[1] >> (15 - x)) & 1) << 1)
                    | (((pb[0] >> (15 - x)) & 1) << 2) | (((pb[1] >> (15 - x)) & 1) << 3)) for x in range(16)])
    return px, size * 2

def render_sprites(files, out):
    low = open(os.path.join(files, 'game_low_000a4.bin'), 'rb').read()
    blk = open(os.path.join(files, 'game_main_06000.bin'), 'rb').read()
    mem = bytearray(0x2D1BA); mem[0x6000:0x6000 + len(blk)] = blk
    sc = struct.unpack('>16H', low[0x4232 - 0xA4:0x4232 - 0xA4 + 32])
    pal = [None] + [rgb(c) for c in sc[1:]]          # colour 16 = transparent
    def sheet(name, frames, h, wide):
        im = Image.new('RGB', (len(frames) * (16 * wide + 4) + 4, h * 1 + 8), (60, 0, 60))
        for i, a in enumerate(frames):
            for half in range(wide):
                px, sz = sprite_pair(mem, a + half * (4 + h * 4 + 4) * 2, h)
                for y, row in enumerate(px):
                    for x, v in enumerate(row):
                        if v:
                            im.putpixel((4 + i * (16 * wide + 4) + half * 16 + x, 4 + y), pal[v])
        im = im.resize((im.width * 3, im.height * 3), Image.NEAREST)
        im.save(os.path.join(out, name))
    sheet('sprites_ship.png', [0x6000 + i * 0x100 for i in range(5)], 14, 2)
    sheet('sprites_bits.png', [0x6500 + i * 0x70 for i in range(11)], 12, 1)
    force = []
    for lvl in range(4):
        e = 0x516C + lvl * 16 - 0xA4
        f0, f1, sz = struct.unpack('>III', low[e:e + 12])
        h = struct.unpack('>H', low[e + 14:e + 16])[0]
        sheet(f'sprites_force{lvl}.png', list(range(f0, f1 + 1, sz)), h, 2)
        force.append((lvl, f0, f1, sz, h))
    return force

def render_engine_bobs(files, out, low6000):
    """Object definitions in the game program's DATA (explosions, walker,
    power-ups, speed-up flash), drawn with level 1's palette."""
    low = open(os.path.join(files, 'game_low_000a4.bin'), 'rb').read()
    R = lambda a, n: low[a - 0xA4:a - 0xA4 + n]
    pal = Level(files, 1).palette
    defs = []
    for p in range(0x41B4, 0x5C66 - 0x28, 2):
        bs, mod, fs = struct.unpack('>HHH', R(p, 6))
        g, mo, an = struct.unpack('>III', R(p + 12, 12))
        h, w = bs >> 6, bs & 63
        if fs and mo * 2 == fs and 0 < w <= 8 and h and h % 4 == 0 and mod == 52 - w * 2 \
                and 0x6000 <= g < 0x2D1BA:
            defs.append((p, h // 4, w - 1, fs, g, mo, an))
    starts = sorted({d[4] for d in defs} | {0x12950, 0x189D0})
    rows, info = [], []
    for p, lines, words, fs, g, mo, an in defs:
        frames = [b for b in R(an, 32) if b < 0x80]
        nxt = min(a for a in starts if a > g)
        n = max(1, min(max(frames) + 1 if frames else 1, (nxt - g) // fs))
        rows.append([bob_frame(low6000[g + i * fs:g + (i + 1) * fs], lines, words, mo) for i in range(n)])
        info.append(f'${p:05X}: {words * 16}x{lines} x{n} gfx ${g:05X}-${g + n * fs - 1:05X}')
    W = max(sum(len(f[0]) + 2 for f in r) for r in rows) + 2
    H = sum(len(r[0]) + 3 for r in rows)
    im = Image.new('RGB', (W, H), (60, 0, 60))
    y = 1
    for r in rows:
        x = 1
        for f in r:
            for yy, row in enumerate(f):
                for xx, v in enumerate(row):
                    if v is not None:
                        im.putpixel((x + xx, y + yy), pal[v])
            x += len(f[0]) + 2
        y += len(r[0]) + 3
    im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(os.path.join(out, 'engine_bobs.png'))
    return info

def render_engine_weapons(files, out, low6000):
    """Shots, beams, lasers, bullets and missiles drawn by dedicated code
    (sizes from the BlitBob calls in game.s), level 1's palette."""
    low = open(os.path.join(files, 'game_low_000a4.bin'), 'rb').read()
    mem = bytearray(low6000)
    mem[0xA4:0xA4 + len(low)] = low                      # engine data ($4E1E)
    pal = Level(files, 1).palette
    def strip(gfx, lines, words, stride, mask, n):
        return [bob_frame(bytes(mem[gfx + i * stride:gfx + i * stride + 2 * mask]), lines, words, mask)
                for i in range(n)]
    groups = [
        ('ship shot', strip(0x4E1E, 4, 1, 0x40, 0x20, 1)),
        ('diagonal/vertical shots', strip(0x8480, 11, 1, 0xB0, 0x58, 4)),
        ('shot stream A (fwd, back)', strip(0x15650, 4, 2, 0x80, 0x40, 4)),
        ('shot stream B (fwd, back)', strip(0x15850, 4, 2, 0x80, 0x40, 4)),
        ('reflect laser', strip(0x12950, 30, 4, 0x780, 0x3C0, 6)),
        ('lasers', strip(0x19B90, 16, 1, 0x100, 0x80, 2)),
        ('laser frames', strip(0x1C2D0, 14, 1, 0xE0, 0x70, 4)),
        ('enemy bullets', strip(0x19D90, 14, 1, 0xE0, 0x70, 6)),
        ('homing missiles', strip(0x1A2D0, 16, 1, 0x100, 0x80, 32)),
    ]
    for k in range(4):                                   # wave cannon by charge
        r = 0x4CA2 - 0xA4 + k * 0x1E                    # $1E-byte records
        bs = struct.unpack('>H', low[r + 0x12:r + 0x14])[0]
        g, fs = struct.unpack('>II', low[r + 0x16:r + 0x1E])
        groups.append((f'wave cannon {k}', strip(g, (bs >> 6) // 4, (bs & 63) - 1, 2 * fs, fs, 2)))
    W = max(sum(len(f[0]) + 2 for f in fr) for _, fr in groups) + 2
    H = sum(max(len(f) for f in fr) + 3 for _, fr in groups)
    im = Image.new('RGB', (W, H), (60, 0, 60))
    y = 1
    for _, fr in groups:
        x = 1
        for f in fr:
            for yy, row in enumerate(f):
                for xx, v in enumerate(row):
                    if v is not None:
                        im.putpixel((x + xx, y + yy), pal[v])
            x += len(f[0]) + 2
        y += max(len(f) for f in fr) + 3
    im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(os.path.join(out, 'engine_weapons.png'))
    return [name for name, _ in groups]

def main():
    files, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    blk = open(os.path.join(files, 'game_main_06000.bin'), 'rb').read()
    low6000 = bytearray(0x2D1BA); low6000[0x6000:0x6000 + len(blk)] = blk
    for n in range(1, 9):
        print(render_level(files, out, n))
        for line in render_bobs(files, out, n, low6000):
            print('   ', line)
    print(render_sprites(files, out))
    for line in render_engine_bobs(files, out, low6000):
        print('   ', line)
    print(render_engine_weapons(files, out, low6000))

if __name__ == '__main__':
    main()
