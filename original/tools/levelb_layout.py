#!/usr/bin/env python3
"""Map out each level B file (decrunched, loaded at $4D300).

usage: python3 -I tools/levelb_layout.py files/

Marks what is known - tiles (up to the highest tile any map cell or
PatchMap block uses... approximated as the tile area up to the next
block), the map, the music player with its songs, patterns, sample and
period tables and samples, and the BOB graphics of every object
definition (all frames) - and prints the regions in address order with
the gaps between them.
"""
import os, struct, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import render_gfx as R
import music_tables as M

def code_refs(L, ts, end, reg, defs):
    """Level B addresses the level code uses as absolute operands (lea, move)."""
    import re
    code = M.disasm(L.a, R.A_BASE, 0x4A300, ts)
    gfx = {d['gfx'] for d in defs}
    out = set()
    for i in code:
        for m in re.finditer(r'\$([0-9a-f]{5})(?:\.l)?(?![0-9a-f(])', i.op_str):
            v = int(m.group(1), 16)
            if R.B_BASE <= v < end and v not in gfx and not any(a <= v < b for a, b, _ in reg):
                out.add(v)
    return sorted(out)

def main():
    files = sys.argv[1]
    for n in range(1, 9):
        L = R.Level(files, n)
        end = R.B_BASE + len(L.b)
        reg = []
        add = lambda a, b, what: reg.append((a, b, what)) if b > a else None
        cells = L.cells()
        ntiles = max(c & 0xFFF for row in cells for c in row if not c & 0x4000) + 1
        add(L.tiles_ptr, L.tiles_ptr + ntiles * R.TILE_BYTES, f'tiles 0-{ntiles - 1} (used by the map)')
        add(L.map_src, L.map_src + L.row_bytes * L.rows, f'map {L.cols}x{L.rows}')
        # music
        for name, fn, base, start in M.PLAYERS:
            if name.startswith(f'level{n}'):
                t = M.tables(L.b, R.B_BASE, start)
                k = (t['periods'] - t['sampletab']) // 8
                last = max(off + words * 2 for off, _, words in
                           (struct.unpack('>IHH', L.read(t['sampletab'] + s * 8, 8)) for s in range(k)))
                add(start, t['sampletab'], f'{name} player code, songs, patterns')
                add(t['sampletab'], t['samples'], 'sample table, period table')
                add(t['samples'], t['samples'] + last, f'{name} samples ({k})')
        # BOBs: each definition's graphics run up to the next known block
        ts, ds = struct.unpack('>II', L.a[2:10])
        defs = sorted((d for d in R.find_definitions(L, None, 0x4A300, 0x4A300 + ts + ds)
                       if d['gfx'] >= R.B_BASE), key=lambda d: d['gfx'])
        starts = sorted({a for a, _, _ in reg} | {d['gfx'] for d in defs} | {end})
        # tables the level code reads from level B (absolute longs in level A)
        refs = code_refs(L, ts, end, reg, defs)
        for d in defs:
            nxt = min(x for x in starts + refs if x > d['gfx'])
            k = (nxt - d['gfx']) // d['frame']
            add(d['gfx'], d['gfx'] + k * d['frame'], f'BOB {k} frames of {d["frame"]} (Def ${d["addr"]:05X})')
        for v in refs:
            if not any(a <= v < b for a, b, _ in reg):
                nxt = min([x for x in starts + refs if x > v] + [end])
                add(v, nxt, 'table read by the level code')
        reg.sort()
        pos = R.B_BASE
        print(f'level {n}: ${R.B_BASE:05X}-${end - 1:05X}')
        merged = []
        for a, b, w in reg:
            if merged and a <= merged[-1][1] and w == merged[-1][2] == 'table read by the level code':
                merged[-1] = (merged[-1][0], max(b, merged[-1][1]), w)
            else:
                merged.append((a, b, w))
        for a, b, w in merged:
            if a > pos:
                print(f'  ${pos:05X}-${a - 1:05X}  {a - pos:6d}  ?')
            print(f'  ${a:05X}-${b - 1:05X}  {b - a:6d}  {w}')
            pos = max(pos, b)
        if pos < end:
            print(f'  ${pos:05X}-${end - 1:05X}  {end - pos:6d}  ? (to the end)')

if __name__ == '__main__':
    main()
