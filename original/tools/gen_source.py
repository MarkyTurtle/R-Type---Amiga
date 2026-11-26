#!/usr/bin/env python3
"""First-pass vasm source from a traced memory image (bootstrap helper only).

The generated file is the starting point for hand annotation; once edited it
is the source of truth and this script is not run again on it.
"""
import re, struct, sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from trace68k import Tracer

BRANCH = re.compile(r'^(b(ra|sr|hi|ls|cc|cs|ne|eq|vc|vs|pl|mi|ge|lt|gt|le)|db\w+)(\.[bsw])?$')

def generate(mem, lo, hi, entries, org, names=None, extra_labels=()):
    names = names or {}
    T = Tracer(mem, lo, hi)
    T.trace(entries)
    code = T.ins
    labels = set(entries) | set(extra_labels)
    hexnum = re.compile(r'\$([0-9a-f]+)')

    def inrange(v):
        return lo <= v < hi

    # labels from operands
    for a, i in code.items():
        mn = i.mnemonic.split('.')[0]
        op = i.op_str
        for m in re.finditer(r'\$([0-9a-f]+)(\.[lw]|\(pc\))', op):
            v = int(m.group(1), 16)
            if inrange(v): labels.add(v)
        if BRANCH.match(i.mnemonic) or mn in ('jsr', 'jmp'):
            m = re.search(r'\$([0-9a-f]+)$', op)
            if m and inrange(int(m.group(1), 16)): labels.add(int(m.group(1), 16))
        if mn in ('move', 'movea', 'pea', 'lea', 'cmpa') and i.mnemonic.endswith('.l'):
            m = re.match(r'#\$([0-9a-f]+),', op.replace(', ', ','))
            if m and inrange(int(m.group(1), 16)): labels.add(int(m.group(1), 16))
    # pointer longs in data that hit code starts
    ptrs = set()
    a = lo
    while a < hi - 3:
        if a not in T.owner and a % 2 == 0 and all((a + k) not in T.owner for k in range(4)) \
                and not any((a + k) in labels for k in (1, 2, 3)) and not any(p > a - 4 for p in ptrs if p < a):
            v = struct.unpack('>I', mem[a:a + 4])[0]
            if v in code:
                ptrs.add(a); labels.add(v)
        a += 2
    labels = {l for l in labels if inrange(l) and (l in code or l not in T.owner)}

    def name(v):
        if v in names: return names[v]
        return ('L_' if v in code else 'D_') + f'{v:05X}'

    def sym(v, keep):
        return name(v) if (inrange(v) and v in labels) else keep

    def fix(i):
        mn = i.mnemonic
        op = i.op_str.replace(', ', ',')
        base = mn.split('.')[0]
        op = re.sub(r'\$([0-9a-f]+)\.([lw])',
                    lambda m: f"({sym(int(m.group(1), 16), '$' + m.group(1).upper())}).{m.group(2)}", op)
        op = re.sub(r'\$([0-9a-f]+)\(pc\)',
                    lambda m: f"{sym(int(m.group(1), 16), '$' + m.group(1).upper())}(pc)", op)
        if BRANCH.match(mn) or base in ('jsr', 'jmp'):
            op = re.sub(r'\$([0-9a-f]+)$', lambda m: sym(int(m.group(1), 16), '$' + m.group(1).upper()), op)
        if base in ('move', 'movea', 'pea', 'lea', 'cmpa') and mn.endswith('.l'):
            op = re.sub(r'^#\$([0-9a-f]+),', lambda m: '#' + sym(int(m.group(1), 16), '$' + m.group(1).upper()) + ',', op)
        if base == 'moveq':
            op = re.sub(r'#\$([0-9a-f]+)', lambda m: '#' + str(int(m.group(1), 16) - 256 if int(m.group(1), 16) > 127 else int(m.group(1), 16)), op)
        if base in ('btst', 'bset', 'bclr', 'bchg') and re.search(r',d[0-7]$', op):
            mn = base
        op = re.sub(r'(?<![\w.])\$([0-9a-f]+)', lambda m: '$' + m.group(1).upper(), op)
        return mn, op

    out = [f'                org     ${org:X}']
    a = lo
    while a < hi:
        if a in labels:
            out.append(f'{name(a)}:')
        if a in code:
            i = code[a]
            mn, op = fix(i)
            out.append(f'                {mn:<8}{op:<36}; {a:05X}')
            a += i.size
        elif a in ptrs:
            v = struct.unpack('>I', mem[a:a + 4])[0]
            out.append(f'                dc.l    {name(v)}')
            a += 4
        else:
            n = a + 1
            while n < hi and n not in labels and n not in code and n not in ptrs and n - a < 16:
                n += 1
            chunk = mem[a:n]
            if len(chunk) % 2 or a % 2:
                out.append('                dc.b    ' + ','.join(f'${b:02X}' for b in chunk))
            else:
                out.append('                dc.w    ' + ','.join('$' + chunk[k:k + 2].hex().upper() for k in range(0, len(chunk), 2)))
            a = n
    return '\n'.join(out) + '\n', T
