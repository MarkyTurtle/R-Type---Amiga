#!/usr/bin/env python3
"""Assemble the sources and check they are byte-identical to the original files
(by SHA-1, using files/manifest.json).

usage: python3 -I tools/verify.py            (vasmm68k_mot on PATH, or set VASM)
"""
import hashlib, json, os, subprocess, sys, tempfile
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VASM = os.environ.get('VASM', 'vasmm68k_mot')

PAIRS = [
    ('src/bootblock.s', 'files/bootblock.bin'),
    ('src/stage2.s',    'files/stage2_79360.bin'),
    ('src/game.s',      'files/game_low_000a4.bin'),
    ('src/shared.s',    'files/shared_4a300.bin'),
    ('src/tfmx.s',      'files/tfmx_player_52300.exe'),
] + [p for n in range(1, 9) for p in (
    [(f'src/levels/level{n}_b.s', f'files/level{n}_b_4d300.bin')]
    if os.path.exists(os.path.join(ROOT, f'src/levels/level{n}_b.s')) else []) +
      [(f'src/levels/level{n}.s', f'files/level{n}_a_4a2e4.bin')]]


def labels_include(lst, out):
    """levelN_b.i: level B's labels as equates, for assembling level A on its own
    (level A refers to B by label; assembled together, LEVEL_AB, it needs none)"""
    import re
    with open(out, 'w') as f:
        f.write('; level B\'s labels (written by tools/verify.py from its listing)\n')
        for line in open(lst, errors='replace'):
            m = re.match(r'^([A-Za-z_]\w*)\s+A:([0-9A-F]+)', line)
            if m:
                f.write('%-24s equ $%s\n' % (m.group(1), m.group(2)))

def main():
    ok = True
    manifest = json.load(open(os.path.join(ROOT, 'files', 'manifest.json')))
    with tempfile.TemporaryDirectory() as tmp:
        for src, ref in PAIRS:
            out = os.path.join(tmp, os.path.basename(ref))
            lst = out + '.lst'
            r = subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet',
                                '-I', os.path.join(ROOT, 'src'), '-I', os.path.join(ROOT, 'files'),
                                '-I', tmp, '-L', lst, '-o', out,
                                os.path.join(ROOT, src)], capture_output=True, text=True)
            if src.endswith('_b.s') and not r.returncode:
                labels_include(lst, os.path.join(tmp, os.path.basename(src)[:-2] + '.i'))
            if r.returncode:
                print(f'FAIL  {src}: assembler error\n{r.stdout}{r.stderr}'); ok = False; continue
            # compare against the SHA-1 recorded in files/manifest.json
            want = next(f['sha1'] for f in manifest if f['name'] == os.path.basename(ref))
            same = hashlib.sha1(open(out, 'rb').read()).hexdigest() == want
            print(f"{'OK  ' if same else 'DIFF'}  {src} -> {ref}")
            ok &= same
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
