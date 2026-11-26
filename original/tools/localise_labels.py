#!/usr/bin/env python3
"""Turn generated L_xxxxx branch labels into local labels (editing helper).

usage: python3 -I tools/localise_labels.py src/levels/level1.s [...]

An L_xxxxx label becomes .xxxxx when it and every reference to it lie in
the same named routine (between two labels that are not L_/D_ labels), so
vasm's local-label scope is the same.  Labels used from other routines,
or from data, stay global for naming by hand.  The file is assembled
before and after; the output must stay identical.
"""
import os, re, subprocess, sys, tempfile

VASM = os.environ.get('VASM', 'vasmm68k_mot')
LABEL = re.compile(r'^([A-Za-z_]\w*):')

def assemble(path):
    out = tempfile.mktemp()
    d = os.path.dirname(os.path.abspath(path))
    subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', '-I', d, '-I', os.path.dirname(d),
                    '-o', out, path], check=True, capture_output=True)
    data = open(out, 'rb').read(); os.remove(out)
    return data

def main():
    for path in sys.argv[1:]:
        before = assemble(path)
        src = open(path).read()
        lines = src.split('\n')
        names = [LABEL.match(l).group(1) if LABEL.match(l) else None for l in lines]
        gen = {n for n in names if n and re.match(r'L_[0-9A-F]{5}$', n)}
        in_data = {n for n in gen if any(re.search(r'dc\.[bwl]\s.*\b%s\b' % n, l) for l in lines)}
        keep = set(in_data)                       # L_ labels that stay global
        while True:
            # vasm: every global label starts a new local scope
            scope, owner = None, []
            for n in names:
                if n and (not n in gen or n in keep):
                    scope = n
                owner.append(scope)
            where = {n: owner[i] for i, n in enumerate(names) if n in gen}
            bad = set()
            for i, l in enumerate(lines):
                code = l.split(';')[0]
                m = LABEL.match(code)
                if m:
                    code = code[m.end():]
                for n in re.findall(r'\bL_[0-9A-F]{5}\b', code):
                    if n in gen and n not in keep and (where[n] is None or owner[i] != where[n]):
                        bad.add(n)
            for n in gen - keep:
                if where[n] is None:
                    bad.add(n)
            if not bad:
                break
            keep |= bad
        local = sorted(gen - keep)
        defined = gen
        for n in local:
            src = re.sub(r'\b%s\b' % n, '.' + n[2:], src)
        open(path, 'w').write(src)
        if assemble(path) != before:
            open(path, 'w').write('\n'.join(lines))
            print(f'{path}: output changed - restored'); continue
        left = sorted(keep)
        print(f'{path}: {len(local)} labels made local, {len(left)} left: {" ".join(left)}')

if __name__ == '__main__':
    main()
