#!/usr/bin/env python3
"""Bootstrap the level B sources, and label level A's references into level B.

usage: python3 -I tools/gen_levelb.py N [--write]      (VASM = vasmm68k_mot)

Level B (files/levelN_b_4d300.bin, loaded to $4D300) is data plus the level's music player,
and the player only uses PC-relative addresses. So the source is the file in labelled
pieces: one `incbin` per block (tiles, map, music, BOB graphics of each object definition,
tables), split wherever level A points into it, with a label there.

Level A's pointers into B are found from its source and its object definitions:
  - the level interface ($4A30C map, $4A310 tiles, $4A328 music, level 8's $4A32C)
  - absolute operands in the code (`lea ($78FD8).l,a1`) and explicit `dc.l` values
  - each object definition's graphics field (+$0C), written as two words in the data
and replaced by the labels, so that A and B can be assembled together at any address.

Everything else in A that looks like an address in B is listed for review: code words,
hit boxes and animation tables that happen to fall in B's range. With --write the tool
writes src/levels/levelN_b.s and rewrites src/levels/levelN.s; run it once per level, then
the sources are the truth (tools/verify.py checks both byte for byte).
"""
import os, re, struct, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import render_gfx as R
import music_tables as M
VASM = os.environ.get('VASM', 'vasmm68k_mot')
B = 0x4D300
# Pointer tables whose targets the layout doesn't know as tables (level 2's Worm paths lie
# where tools/levelb_layout.py guessed more frames of the Worm's eye); found by review
PATH_TABLES = {2: ('WormFirstPath', 'WormPaths')}
DATA = re.compile(r'^(\s*)dc\.([bwl])\s+([^;]*?)\s*(;.*)?$')


def assemble(src, extra_inc=()):
    tmp = tempfile.mkdtemp()
    out, lst = os.path.join(tmp, 'a.bin'), os.path.join(tmp, 'a.lst')
    inc = sum((['-I', d] for d in (os.path.join(ROOT, 'src'), os.path.join(ROOT, 'files'), tmp) + tuple(extra_inc)), [])
    open(os.path.join(tmp, 'levelb_syms.i'), 'w').write('')
    r = subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', *inc, '-L', lst, '-o', out, src],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    return open(out, 'rb').read(), lst


def line_addresses(lst):
    """source line -> first address, from a vasm listing"""
    first = {}
    for line in open(lst, errors='replace'):
        m = re.match(r'^00:([0-9A-F]{8}) [0-9A-F]+\s+(\d+):', line)
        if m:
            first.setdefault(int(m.group(2)), int(m.group(1), 16))
    return first


def symbols(lst):
    out = {}
    for line in open(lst, errors='replace'):
        m = re.match(r'^([A-Za-z_]\w*)\s+A:([0-9A-F]+)', line)
        if m:
            out[m.group(1)] = int(m.group(2), 16)
    return out


def regions(L, defs, names, refs):
    """level B's blocks, as (start, end, kind, label) (see tools/levelb_layout.py)"""
    end = B + len(L.b)
    reg = []
    cells = L.cells()
    ntiles = max(c & 0xFFF for row in cells for c in row if not c & 0x4000) + 1
    reg.append((L.tiles_ptr, L.tiles_ptr + ntiles * R.TILE_BYTES, 'tiles 0-%d (used by the map)' % (ntiles - 1), 'LvTiles'))
    reg.append((L.map_src, L.map_src + L.row_bytes * L.rows, 'map %dx%d' % (L.cols, L.rows), 'LvMap'))
    for name, fn, base, start in M.PLAYERS:
        if name.startswith('level%d' % L.n):
            t = M.tables(L.b, B, start)
            k = (t['periods'] - t['sampletab']) // 8
            last = max(off + words * 2 for off, _, words in
                       (struct.unpack('>IHH', L.read(t['sampletab'] + s * 8, 8)) for s in range(k)))
            tag = 'End' if name.endswith('end') else ''
            reg.append((start, t['sampletab'], 'music player%s: code, variables, songs, patterns (PC-relative)'
                        % (' (the ending)' if tag else ''), 'LvMusic' + tag))
            reg.append((t['sampletab'], t['samples'], 'sample table (%d), period table' % k, 'LvMusic%sSamples' % tag))
            reg.append((t['samples'], t['samples'] + last, '%d samples' % k, 'LvMusic%sSampleData' % tag))
    refs = sorted(v for v in refs if not any(a <= v < b for a, b, _, _ in reg) and v not in {d['gfx'] for d in defs})
    starts = sorted({a for a, _, _, _ in reg} | {d['gfx'] for d in defs} | {end} | set(refs))
    for d in sorted(defs, key=lambda d: d['gfx']):
        if any(a == d['gfx'] for a, _, _, _ in reg):
            continue
        nxt = min(x for x in starts if x > d['gfx'])
        k = (nxt - d['gfx']) // d['frame']
        nm = names.get(d['addr'], 'Def_%05X' % d['addr'])
        reg.append((d['gfx'], d['gfx'] + k * d['frame'], 'BOB graphics: %d frames of %d bytes (%s)' % (k, d['frame'], nm),
                    'Gfx_' + nm[4:]))
    for v in refs:                           # tables the level code reads
        if not any(a <= v < b for a, b, _, _ in reg):
            nxt = min([x for x in starts if x > v] + [end])
            reg.append((v, nxt, 'table read by the level code', 'Tbl_%05X' % v))
    reg.sort()
    return reg


def main():
    n = int(sys.argv[1])
    write = '--write' in sys.argv
    srcpath = os.path.join(ROOT, 'src', 'levels', 'level%d.s' % n)
    src = open(srcpath).read().split('\n')
    abin, lst = assemble(srcpath)
    names = {v: k for k, v in symbols(lst).items()}
    first = line_addresses(lst)
    L = R.Level(os.path.join(ROOT, 'files'), n)
    end = B + len(L.b)
    inB = lambda v: B <= v <= end            # (level 4's map copy is at the end of B)
    ts, ds = struct.unpack('>II', L.a[2:10])
    defs = [d for d in R.find_definitions(L, None, 0x4A300, 0x4A300 + ts + ds) if B <= d['gfx'] < end]
    refs = set()                             # absolute operands in the code
    for ln, text in enumerate(src, 1):
        body = text.split(';')[0]
        if body.strip() and not DATA.match(text):
            for m in re.finditer(r'\$([0-9A-Fa-f]{5,8})\b', body):
                if inB(int(m.group(1), 16)):
                    refs.add(int(m.group(1), 16))
    reg = regions(L, defs, names, refs)
    rd = lambda a: struct.unpack('>L', abin[a - 0x4A2E4:a - 0x4A2E4 + 4])[0]

    aend = 0x4A300 + ts + ds                 # the end of A's TEXT and DATA: padding after it
    region_of = lambda v: max((r for r in reg if r[0] <= v < r[1]), default=None, key=lambda r: r[0])

    # level A's pointers into B: address in A -> value
    ptrs = {}
    for a in (0x4A30C, 0x4A310, 0x4A328) + ((0x4A32C,) if n == 8 else ()):
        if inB(rd(a)):
            ptrs[a] = rd(a)
    code_refs = []                           # (line, text, value)
    for ln, text in enumerate(src, 1):
        body = text.split(';')[0]
        if not body.strip() or ln not in first:
            continue
        dm = DATA.match(text)
        for m in re.finditer(r'\$([0-9A-Fa-f]{5,8})\b', body):
            v = int(m.group(1), 16)
            if not inB(v):
                continue
            if dm and dm.group(2) == 'l':
                r = region_of(v)                 # a table, or the start of a block
                if r and r[0] != v and not r[2].startswith('table'):
                    continue                     # (inside tiles, map, music or graphics:
                toks = [t.strip() for t in dm.group(3).split(',')]   #  a parameter)
                k = next(i for i, t in enumerate(toks) if t.lstrip('$').upper().lstrip('0') == m.group(1).upper().lstrip('0'))
                ptrs[first[ln] + 4 * k] = v
            elif not dm:
                code_refs.append((ln, m.group(0), v))
                hit = [a for a in range(first[ln], first[ln] + 10, 2) if rd(a) == v]
                ptrs[hit[0]] = v
    for d in defs:
        ptrs[d['addr'] + 0x0C] = d['gfx']
    # other longs in the data that point into a table, the map or at a block's start (path
    # tables, PatchMap blocks); the list is printed for review, with per-level overrides
    data_lines = sorted((a0, ln) for ln, a0 in first.items())
    import bisect
    dstarts = [a for a, _ in data_lines]
    def data_line(a):
        i = bisect.bisect_right(dstarts, a) - 1
        return data_lines[i][1] if i >= 0 else None
    labels_at = {}
    for ln, t in enumerate(src, 1):
        m = re.match(r'^([A-Za-z_]\w*):', t)
        if m:
            labels_at[ln] = m.group(1)
    def label_of(ln):
        while ln > 0 and ln not in labels_at:
            ln -= 1
        return labels_at.get(ln, '')
    found = []
    for a in range(0x4A300, aend - 3, 2):
        v = rd(a)
        ln = data_line(a)
        if a in ptrs or not inB(v) or ln is None or not DATA.match(src[ln - 1]):
            continue
        r = region_of(v)
        if not ((r and (r[3] == 'LvMap' or r[2].startswith('table'))) or label_of(ln) in PATH_TABLES.get(n, ())):
            continue
        found.append(a)
        ptrs[a] = v
    print('data pointers found by their target (review):')
    for a in found:
        ln = data_line(a)
        print('  $%05X -> $%05X  L%d: %s' % (a, rd(a), ln, src[ln - 1].strip()[:80]))

    # the blocks again, now with every pointer's target as a possible block start (so a
    # BOB block ends where a table it was guessed to run into begins)
    reg = regions(L, defs, names, refs | {v for v in ptrs.values()
                                         if not (region_of(v) and region_of(v)[3] in ('LvMap', 'LvTiles'))})
    # labels in B
    lab = {}
    for a, b, what, name in reg:
        lab[a] = name
    lab[end] = 'LvEnd'
    for v in sorted(set(ptrs.values())):
        if v in lab:
            continue
        r = region_of(v)
        if r and r[3] in ('LvMap', 'LvTiles'):
            continue                         # LvMap+offset
        lab[v] = 'Tbl_%05X' % v
    def expr(v):
        if v in lab:
            return lab[v]
        r = region_of(v)
        return '%s+$%X' % (r[3], v - r[0])

    # report
    print('level %d: B $%05X-$%05X, %d pointers from A into B, %d labels in B' % (n, B, end - 1, len(ptrs), len(lab)))
    for a in sorted(ptrs):
        print('  $%05X -> $%05X  %s' % (a, ptrs[a], expr(ptrs[a])))
    rest = [(a, rd(a)) for a in range(0x4A300, min(0x4CB00, 0x4A2E4 + len(abin)) - 3, 2) if B <= rd(a) < end and a not in ptrs]
    print('%d other longs in A that fall in B (for review):' % len(rest))
    owner = {}
    for ln, a0 in first.items():
        owner[a0] = ln
    lines_sorted = sorted(first.items(), key=lambda x: x[1])
    import bisect
    starts = [a for _, a in lines_sorted]
    for a, v in rest:
        i = bisect.bisect_right(starts, a) - 1
        ln = lines_sorted[i][0]
        print('  $%05X $%05X  L%d: %s' % (a, v, ln, src[ln - 1].strip()[:80]))
    if not write:
        return

    # level B's source
    pts = sorted(set(lab) | {B, end} | {r[1] for r in reg})
    out = [';' + '=' * 78,
           '; R-Type (Amiga) - level %d data (level part B)' % n,
           '; Loaded to $4D300 ($%05X-$%05X); files/level%d_b_4d300.bin, byte for byte.' % (B, end - 1, n),
           ';',
           '; Data, and the level\'s music player, which only uses PC-relative addresses: so',
           '; the file is here in labelled pieces (incbin), split at every place level A',
           '; points to.  Level A (level%d.s) refers to it by these labels, so A and B can be' % n,
           '; assembled together at any address.  Blocks (docs/levelb_layout.txt):',
           ';', '; first written by tools/gen_levelb.py; the source of truth from then on.',
           ';' + '=' * 78,
           '                ifnd    LEVEL_AB',
           '                org     $4D300',
           '                endc', '']
    comment = {r[0]: r[2] for r in reg}
    for k, a in enumerate(pts[:-1]):
        b = pts[k + 1]
        if a in comment:
            out.append('; $%05X-$%05X: %s' % (a, [r for r in reg if r[0] == a][0][1] - 1, comment[a]))
        elif not region_of(a):
            out.append('; $%05X-$%05X: (not used by the code that is known)' % (a, b - 1))
        if a in lab:
            out.append('%s:' % lab[a])
        out.append('                incbin  "level%d_b_4d300.bin",$%X,$%X' % (n, a - B, b - a))
    out.append('LvEnd:' + ('                                  ; LevelInit copies the map here' if n == 4 else ''))
    out.append('')
    open(os.path.join(ROOT, 'src', 'levels', 'level%d_b.s' % n), 'w').write('\n'.join(out))

    # level A: the pointers by label
    new = list(src)
    for ln, text, v in code_refs:
        new[ln - 1] = new[ln - 1].replace(text, expr(v), 1)
    # data: rewrite token by token (a long may be two dc.w tokens, four dc.b, or span lines)
    toks = []                                # [line, size, addr, text]
    for ln, text in enumerate(new, 1):
        dm = DATA.match(text)
        if dm and ln in first:
            size = {'b': 1, 'w': 2, 'l': 4}[dm.group(2)]
            a = first[ln]
            for t in dm.group(3).split(','):
                toks.append([ln, size, a, t.strip()]); a += size
    byaddr = {t[2]: i for i, t in enumerate(toks)}
    changed = set()
    if aend in byaddr:
        i = byaddr[aend]
        changed.add(toks[i][0])
        toks[i][3] = '@END@' + toks[i][3]
    for a, v in ptrs.items():
        if a not in byaddr:
            continue                         # (code operands, done above)
        i = byaddr[a]
        changed.add(toks[i][0])
        if toks[i][1] == 4:
            toks[i][3] = expr(v); continue
        cov, j = 0, i
        while cov < 4:
            cov += toks[j][1]; j += 1
        assert cov == 4, 'pointer at $%05X does not end on a token boundary' % a
        toks[i] = [toks[i][0], 4, a, expr(v)]
        for k in range(i + 1, j):
            changed.add(toks[k][0])
            toks[k] = None
    byline = {}
    for t in toks:
        if t:
            byline.setdefault(t[0], []).append(t)
    for ln, text in enumerate(new, 1):
        dm = DATA.match(text)
        if not (dm and ln in first and ln in changed):
            continue
        ts_ = byline.get(ln, [])
        size = {'b': 1, 'w': 2, 'l': 4}[dm.group(2)]
        runs = []
        for t in ts_:
            s = 4 if (t[1] == 4 and size != 4) else size
            if t[3].startswith('@END@'):
                runs.append(['END', None])
                t[3] = t[3][5:]
                runs.append([s, [t[3]]])
                continue
            if runs and runs[-1][0] == s and not (s == 4 and size != 4):
                runs[-1][1].append(t[3])
            else:
                runs.append([s, [t[3]]])
        d = {1: 'b', 2: 'w', 4: 'l'}
        if size == 4 and not any(t[3].startswith('@END@') for t in ts_):   # a dc.l line: only its values change
            body = '%sdc.l    %s' % (dm.group(1), ','.join(t[3] for t in ts_))
            new[ln - 1] = (body.ljust(40) + ' ' + dm.group(4)) if dm.group(4) else body
            continue
        pieces = [('@END@' if s == 'END' else '%sdc.%s    %s' % (dm.group(1), d[s], ','.join(v))) for s, v in runs]
        if dm.group(4) and pieces:
            pieces[0] = pieces[0].ljust(40) + ' ' + dm.group(4)
        new[ln - 1] = '\n'.join(pieces) if pieces else None
    new = [x for x in new if x is not None]
    txt = '\n'.join(new)
    if '@END@' in txt:                       # A's end: B follows here when assembled together
        head, tail = txt.split('@END@', 1)
        tail = tail.lstrip('\n').rstrip('\n')
        txt = (head + 'LevelAEnd:                               ; (the end of TEXT and DATA)\n'
               '                ifnd    LEVEL_AB                ; on its own: the padding to the end\n'
               '                                                ;  of its tracks, byte for byte\n'
               + tail + '\n                endc\n')
    inc = ('                ifnd    LEVEL_AB\n'
           '                include "level%d_b.i"           ; level B\'s labels (tools/verify.py writes it\n'
           '                endc                            ;  from level%d_b.s)\n' % (n, n))
    txt = txt.replace('                include "engine.i"\n', '                include "engine.i"\n' + inc, 1)
    open(srcpath, 'w').write(txt)
    print('wrote src/levels/level%d_b.s, rewrote src/levels/level%d.s' % (n, n))


if __name__ == '__main__':
    main()
