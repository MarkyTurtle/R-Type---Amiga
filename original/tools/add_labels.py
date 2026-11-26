#!/usr/bin/env python3
"""Insert labels at given addresses in a vasm source (editing helper).

usage: python3 -I tools/add_labels.py src/game.s ADDR=Name[:comment] ...
       (ADDR in hex, e.g. 493A=DefExplosion1:"small explosion, 6 frames")

Assembles the file with a listing to find the line holding each address.
If the address is in the middle of a dc.b/dc.w/dc.l line, the line is
split there.  Existing references written as D_xxxxx / L_xxxxx for that
address are renamed too.  The file is rewritten in place, then assembled
again and compared with the original output (it must stay identical).
"""
import os, re, subprocess, sys, tempfile

VASM = os.environ.get('VASM', 'vasmm68k_mot')

def assemble(path, listing=None):
    out = tempfile.mktemp()
    d = os.path.dirname(os.path.abspath(path))
    cmd = [VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', '-I', d, '-I', os.path.dirname(d), '-o', out]
    if listing:
        cmd += ['-L', listing]
    subprocess.run(cmd + [path], check=True, capture_output=True)
    data = open(out, 'rb').read(); os.remove(out)
    return data

def line_addresses(listing):
    """source line number -> address of its first byte (lines that emit)."""
    res = {}
    for l in open(listing, errors='replace'):
        m = re.match(r'^\d\d:([0-9A-F]{8}) \S*\s*\t\s*(\d+):', l)
        if m:
            res.setdefault(int(m.group(2)), int(m.group(1), 16))
    return res

SIZE = {'b': 1, 'w': 2, 'l': 4}

def main():
    path = sys.argv[1]
    wanted = []
    for arg in sys.argv[2:]:
        a, rest = arg.split('=', 1)
        name, _, comment = rest.partition(':')
        wanted.append((int(a, 16), name, comment.strip('"')))
    before = assemble(path)
    lst = tempfile.mktemp()
    assemble(path, lst)
    addr = line_addresses(lst); os.remove(lst)
    lines = open(path).read().split('\n')
    starts = sorted((a, n) for n, a in addr.items())
    edits = {}
    for target, name, comment in wanted:
        # the emitting line whose start is the greatest <= target
        best = max(((a, n) for a, n in starts if a <= target), default=None)
        if best is None:
            sys.exit(f'{target:X}: not in file')
        a, n = best
        idx = n - 1
        src = lines[idx]
        cm = f'; {comment}\n' if comment else ''
        existing = re.compile(rf'^[DL]_{target:05X}:$', re.M)
        if existing.search('\n'.join(lines)):
            # already labelled: rename it (below) and put the comment above
            for j, l in enumerate(lines):
                if existing.match(l):
                    lines[j] = cm + l
            continue
        if a == target:
            edits[idx] = edits.get(idx, '') + f'{cm}{name}:\n'
            continue
        m = re.match(r'^(\s+)dc\.([bwl])\s+([^;]*?)(\s*;.*)?$', src)
        if not m:
            sys.exit(f'{target:X}: inside a non-data line {n}: {src.strip()}')
        ind, sz, vals = m.group(1), m.group(2), [v.strip() for v in m.group(3).split(',')]
        k, rem = divmod(target - a, SIZE[sz])
        if rem or k >= len(vals):
            sys.exit(f'{target:X}: not on an element boundary of line {n}')
        lines[idx] = f'{ind}dc.{sz}    ' + ','.join(vals[:k]) + '\n' + cm + f'{name}:\n' + \
            f'{ind}dc.{sz}    ' + ','.join(vals[k:])
    for idx, text in edits.items():
        lines[idx] = text + lines[idx]
    s = '\n'.join(lines)
    for target, name, _ in wanted:
        s = re.sub(rf'\b[DL]_{target:05X}\b', name, s)
    s = re.sub(r'^(\s+dc\.[bwl]\s+)\n', '', s, flags=re.M)
    open(path, 'w').write(s)
    after = assemble(path)
    if after != before:
        sys.exit('ERROR: output changed - check the edits')
    print(f'{len(wanted)} labels added, output identical')

if __name__ == '__main__':
    main()
