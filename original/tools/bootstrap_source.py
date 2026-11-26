#!/usr/bin/env python3
"""One-off helper: turn a binary into a first-pass vasm (Motorola) source.

The output is a starting point for hand annotation - it is not part of the
build. usage:
  bootstrap_source.py bin base out.s CODE_START-CODE_END [CODE_START-CODE_END ...]
Everything outside the code ranges is emitted as dc.w/dc.b data.
"""
import re, sys, capstone

def main():
    path, base, out = sys.argv[1], int(sys.argv[2], 0), sys.argv[3]
    ranges = [tuple(int(x, 0) for x in r.split('-')) for r in sys.argv[4:]]
    data = open(path, 'rb').read()
    end = base + len(data)
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000)

    def in_code(a):
        return any(s <= a < e for s, e in ranges)

    # pass 1: decode instructions, gather label targets
    ins_at = {}
    for s, e in ranges:
        p = s
        while p < e:
            got = list(md.disasm(data[p - base:e - base], p, count=1))
            if not got:
                raise SystemExit(f'cannot decode at {p:x}')
            i = got[0]
            ins_at[p] = i
            p += i.size
    labels = set()
    hexnum = re.compile(r'\$([0-9a-f]+)')
    for a, i in ins_at.items():
        for m in hexnum.finditer(i.op_str):
            v = int(m.group(1), 16)
            if base <= v < end and (i.mnemonic.startswith(('b', 'db', 'j', 'lea', 'pea', 'move', 'cmp', 'sub', 'add', 'tst', 'clr', 'st', 'not', 'and', 'or', 'eor'))):
                labels.add(v)
    labels |= {s for s, _ in ranges}

    def name(v):
        return f'L_{v:05X}'

    def fix(i):
        op = i.op_str.replace(', ', ',')
        mn = i.mnemonic
        def sub(m):
            v = int(m.group(1), 16)
            return name(v) if (base <= v < end) else '$' + m.group(1).upper()
        # absolute .l / .w operands -> (x).l form
        op = re.sub(r'\$([0-9a-f]+)\.([lw])', lambda m: f'({sub(m)}).{m.group(2)}', op)
        # pc relative
        op = re.sub(r'\$([0-9a-f]+)\(pc\)', lambda m: f'{sub(m)}(pc)', op)
        # branch targets
        if mn.startswith(('b', 'db')) and not mn.startswith(('btst', 'bset', 'bclr', 'bchg')):
            op = re.sub(r'\$([0-9a-f]+)$', lambda m: sub(m), op)
        # immediates pointing inside the image
        op = re.sub(r'#\$([0-9a-f]+)', lambda m: '#' + sub(m), op)
        op = re.sub(r'\$([0-9a-f]+)', lambda m: '$' + m.group(1).upper(), op)
        if mn == 'moveq':
            op = re.sub(r'#\$([0-9A-F]+)', lambda m: '#' + str(int(m.group(1), 16) - 256 if int(m.group(1), 16) > 127 else int(m.group(1), 16)), op)
        if mn.split('.')[0] in ('btst', 'bset', 'bclr', 'bchg') and re.search(r',d[0-7]$', op):
            mn = mn.split('.')[0]               # register form is long-only
        return mn, op

    lines = []
    a = base
    while a < end:
        if a in labels:
            lines.append(f'{name(a)}:')
        if in_code(a):
            i = ins_at[a]
            mn, op = fix(i)
            lines.append(f'                {mn:<8}{op:<32}; {a:05X} {i.bytes.hex()}')
            a += i.size
        else:
            # data until next label/code
            n = a + 1
            while n < end and n not in labels and not in_code(n) and n - a < 16:
                n += 1
            chunk = data[a - base:n - base]
            if len(chunk) % 2 or a % 2:
                lines.append('                dc.b    ' + ','.join(f'${b:02X}' for b in chunk) + f'  ; {a:05X}')
            else:
                ws = [chunk[k:k + 2].hex().upper() for k in range(0, len(chunk), 2)]
                lines.append('                dc.w    ' + ','.join('$' + w for w in ws) + f'  ; {a:05X}')
            a = n
    open(out, 'w').write('\n'.join(lines) + '\n')

if __name__ == '__main__':
    main()
