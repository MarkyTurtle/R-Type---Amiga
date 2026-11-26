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
] + [(f'src/levels/level{n}.s', f'files/level{n}_a_4a2e4.bin') for n in range(1, 9)] + [
]

def main():
    ok = True
    manifest = json.load(open(os.path.join(ROOT, 'files', 'manifest.json')))
    with tempfile.TemporaryDirectory() as tmp:
        for src, ref in PAIRS:
            out = os.path.join(tmp, os.path.basename(ref))
            r = subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet',
                                '-I', os.path.join(ROOT, 'src'), '-o', out,
                                os.path.join(ROOT, src)], capture_output=True, text=True)
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
