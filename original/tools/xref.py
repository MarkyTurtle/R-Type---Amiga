#!/usr/bin/env python3
"""Cross-reference for a source: who reads and writes each label.

usage: python3 -I tools/xref.py src/game.s [PATTERN]

For every label matching PATTERN (a regex, default ^D_ = unnamed data)
prints the routines (nearest preceding non-local, non-L_/D_ label) that
use it, marking writes (W: destination operand, clr/st/addq... on it) and
reads (R).  Useful for naming variables: a byte only ever written with
st/clr and tested elsewhere is a flag, and so on.
"""
import re, sys
from collections import defaultdict

WRITE_ONLY = ('clr', 'st', 'sf', 'move', 'movea', 'lea', 'pea')
RMW = ('add', 'addq', 'addi', 'sub', 'subq', 'subi', 'not', 'neg', 'eor', 'eori',
       'or', 'ori', 'and', 'andi', 'bset', 'bclr', 'bchg', 'lsl', 'lsr', 'asl', 'asr')

def main():
    path = sys.argv[1]
    pat = re.compile(sys.argv[2] if len(sys.argv) > 2 else r'^D_')
    lines = open(path).read().split('\n')
    labels = [m.group(1) for l in lines for m in [re.match(r'^([A-Za-z_]\w*):', l)] if m]
    wanted = {l for l in labels if pat.search(l)}
    uses = defaultdict(lambda: defaultdict(set))
    routine = None
    for l in lines:
        m = re.match(r'^([A-Za-z_]\w*):', l)
        if m and not re.match(r'^[DL]_', m.group(1)):
            routine = m.group(1)
        code = l.split(';', 1)[0].strip()
        if not code or code.startswith('dc.') or code.endswith(':'):
            continue
        parts = code.split(None, 1)
        if len(parts) < 2:
            continue
        mn, ops = parts[0].lower(), parts[1]
        base = mn.split('.')[0]
        # split operands at top-level commas
        depth, cur, opl = 0, '', []
        for ch in ops:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            if ch == ',' and depth == 0:
                opl.append(cur); cur = ''
            else:
                cur += ch
        opl.append(cur)
        for k, op in enumerate(opl):
            for name in re.findall(r'\b([A-Za-z_]\w*)\b', op):
                if name not in wanted:
                    continue
                last = k == len(opl) - 1
                if base in ('lea', 'pea') or op.strip().startswith('#'):
                    kind = 'A'                      # address taken
                elif last and len(opl) > 1 and base in WRITE_ONLY:
                    kind = 'W'
                elif last and (base in RMW or (len(opl) == 1 and base in ('clr', 'st', 'sf', 'not', 'neg', 'addq', 'subq'))):
                    kind = 'RW' if base not in ('clr', 'st', 'sf') else 'W'
                elif len(opl) == 1 and base in ('clr', 'st', 'sf'):
                    kind = 'W'
                else:
                    kind = 'R'
                uses[name][routine].add(kind)
    for name in labels:
        if name in wanted:
            u = uses.get(name, {})
            desc = '; '.join(f"{r}:{''.join(sorted(k))}" for r, k in sorted(u.items(), key=lambda x: str(x[0])))
            print(f'{name:<14} {desc or "(no code references)"}')

if __name__ == '__main__':
    main()
