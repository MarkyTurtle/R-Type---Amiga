#!/usr/bin/env python3
"""Check that a level's parts A and B can be assembled together anywhere (relocated).

usage: python3 -I tools/check_levelab.py [N ...]      (VASM = vasmm68k_mot; default: every
                                                       level that has a levelN_b.s)

For each level:
  1. A on its own, against B's labels moved by $1000: every long that changes must change by
     exactly $1000 (a pointer into B), and nothing else may change. Prints how many.
  2. A and B together (LEVEL_AB), B straight after A's TEXT and DATA: A's bytes are the
     original's except for those pointers, now pointing into the moved B; B's bytes are the
     original level B file's, unchanged (B holds no pointers of its own).
"""
import os, re, struct, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
VASM = os.environ.get('VASM', 'vasmm68k_mot')
DELTA = 0x1000


def asm(src_text, tmp, name, incs=()):
    p = os.path.join(tmp, name + '.s')
    open(p, 'w').write(src_text)
    out, lst = os.path.join(tmp, name + '.bin'), os.path.join(tmp, name + '.lst')
    r = subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', '-I', os.path.join(ROOT, 'src'),
                        '-I', os.path.join(ROOT, 'src', 'levels'), '-I', os.path.join(ROOT, 'files'),
                        '-I', tmp, *sum((['-I', i] for i in incs), []), '-L', lst, '-o', out, p],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    syms = {}
    for line in open(lst, errors='replace'):
        m = re.match(r'^([A-Za-z_]\w*)\s+A:([0-9A-F]+)', line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return open(out, 'rb').read(), syms


def check(n):
    ok = True
    tmp = tempfile.mkdtemp()
    orig_a = open(os.path.join(ROOT, 'files', 'level%d_a_4a2e4.bin' % n), 'rb').read()
    orig_b = open(os.path.join(ROOT, 'files', 'level%d_b_4d300.bin' % n), 'rb').read()
    _, bsyms = asm('                include "level%d_b.s"\n' % n, tmp, 'b')
    # 1. A against B's labels moved
    with open(os.path.join(tmp, 'level%d_b.i' % n), 'w') as f:
        for k, v in bsyms.items():
            f.write('%s equ $%X\n' % (k, v + DELTA))
    a2, asyms = asm('                include "level%d.s"\n' % n, tmp, 'a')
    diff = [i for i in range(len(orig_a)) if a2[i] != orig_a[i]]
    longs, k = [], 0
    while k < len(orig_a) - 3:
        if (struct.unpack_from('>L', a2, k)[0] - struct.unpack_from('>L', orig_a, k)[0]) & 0xFFFFFFFF == DELTA:
            longs.append(k); k += 4
        else:
            k += 2
    covered = {k + d for k in longs for d in range(4)}
    stray = [i for i in diff if i not in covered]
    print('level %d: %d pointers into B in A' % (n, len(longs)))
    if stray:
        print('  FAIL: A changes that are not pointers into B at', ', '.join('$%05X' % (0x4A2E4 + i) for i in stray[:8]))
        ok = False
    # 2. together
    both, syms = asm('LEVEL_AB        equ     1\n                include "level%d.s"\n'
                     '                include "level%d_b.s"\n' % (n, n), tmp, 'ab')
    aend, bstart = syms['LevelAEnd'], syms['LvTiles']
    b_off = bstart - 0x4A2E4
    same_b = both[b_off:b_off + len(orig_b)] == orig_b
    print('  together: A $4A2E4-$%05X, B $%05X-$%05X (%d bytes nearer than $4D300)%s'
          % (aend - 1, bstart, bstart + len(orig_b) - 1, 0x4D300 - bstart, '' if same_b else '  FAIL: B differs'))
    a_part = both[:aend - 0x4A2E4]
    moved = bstart - 0x4D300
    bad = []
    for k in longs:
        v0 = struct.unpack_from('>L', orig_a, k)[0]
        if struct.unpack_from('>L', a_part, k)[0] != v0 + moved:
            bad.append(k)
    other = [i for i in range(len(a_part)) if a_part[i] != orig_a[i] and i not in covered]
    if bad or other:
        print('  FAIL: A differs outside its pointers into B' if other else '  FAIL: a pointer not moved')
        ok = False
    return ok and same_b


def main():
    ns = [int(a) for a in sys.argv[1:]] or [n for n in range(1, 9) if os.path.exists(
        os.path.join(ROOT, 'src', 'levels', 'level%d_b.s' % n))]
    ok = all([check(n) for n in ns])
    print('all passed' if ok else 'FAILED')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
