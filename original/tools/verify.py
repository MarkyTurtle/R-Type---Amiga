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
]

def main():
    ok = True
    manifest = json.load(open(os.path.join(ROOT, 'files', 'manifest.json')))
    with tempfile.TemporaryDirectory() as tmp:
        for src, ref in PAIRS:
            out = os.path.join(tmp, os.path.basename(ref))
            r = subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', '-o', out,
                                os.path.join(ROOT, src)], capture_output=True, text=True)
            if r.returncode:
                print(f'FAIL  {src}: assembler error\n{r.stdout}{r.stderr}'); ok = False; continue
            # compare against the SHA-1 in files/manifest.json, so this works
            # without the extracted (copyrighted) binaries being present
            want = next(f['sha1'] for f in manifest if f['name'] == os.path.basename(ref))
            same = hashlib.sha1(open(out, 'rb').read()).hexdigest() == want
            print(f"{'OK  ' if same else 'DIFF'}  {src} -> {ref}")
            ok &= same
    sys.exit(0 if ok else 1)

if __name__ == '__main__':
    main()
