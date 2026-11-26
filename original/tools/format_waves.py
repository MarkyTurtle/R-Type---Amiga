#!/usr/bin/env python3
"""Rewrite a level's checkpoint and wave lists one entry per line (editing helper).

usage: python3 -I tools/format_waves.py src/levels/level1.s [...]

Between the WaveList: and LevelPalette: labels a level holds
  - the checkpoint list: 6-byte entries (scroll x.w, wave list position.l),
    highest first, ending with the scroll-x 0 entry, and
  - the wave list: $12-byte entries (trigger.w, x.w, y.w, 8 bytes of
    parameters for the spawn routine, definition.l; a negative definition
    means the POW Armor), followed by an end marker that is never reached.
The checkpoint targets get labels (Waves, WavesFrom_xxxx), definitions and
parameter pointers are written with their labels where the source has one.
The file is assembled before and after; the output must stay identical.
"""
import os, re, struct, subprocess, sys, tempfile

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

def symbols(listing):
    syms = {}
    for l in open(listing, errors='replace'):
        m = re.match(r'^([0-9A-F]{8}) (\S+)$', l)
        if m:
            syms.setdefault(int(m.group(1), 16), []).append(m.group(2))
    return syms

def main():
    for path in sys.argv[1:]:
        lst = tempfile.mktemp()
        img = assemble(path, lst)
        syms = symbols(lst); os.remove(lst)
        addr = {n: a for a, ns in syms.items() for n in ns}
        org = addr['LevelHeader']
        rd = lambda a, n: img[a - org:a - org + n]
        w = lambda a: struct.unpack('>H', rd(a, 2))[0]
        L = lambda a: struct.unpack('>L', rd(a, 4))[0]
        def name(v, prefer=('Def_', 'D_', '')):
            for n in syms.get(v, []):
                if n.startswith(prefer):
                    return n
            return None
        start, end = addr['WaveList'], addr['LevelPalette']
        a, cps = start, []
        while True:
            cps.append((w(a), L(a + 2))); a += 6
            if cps[-1][0] == 0:
                break
        waves = a
        src0 = open(path).read()
        if min(t for _, t in cps) != waves:
            print(f'{path}: wave list does not follow the checkpoints - skipped'); continue
        labels = {waves: 'Waves'}
        for sx, t in cps:
            if t != waves:
                labels.setdefault(t, f'WavesFrom_{sx:04X}')
        out = ['; Checkpoint list (LV_Waves): scroll x reached, where to resume in the',
               '; wave list.  Highest first; the 0 entry is the level start.',
               'WaveList:']
        for sx, t in cps:
            out.append(f'                dc.w    ${sx:04X}')
            out.append(f'                dc.l    {labels[t]}')
        out += ['; Wave list: trigger (scroll x; level 3: frame count), x, y, 8 bytes',
                '; for the spawn routine, definition (-1 = POW Armor, the default).']
        a = waves
        while a + 0x12 <= end:
            if a in labels:
                out.append(labels[a] + ':')
            trig, x, y = w(a), w(a + 2), w(a + 4)
            p1, p2 = L(a + 6), L(a + 10)
            d = L(a + 14)
            if d == 0xFFFFFFFF:
                dn, what = '$FFFFFFFF', 'POW Armor'
            else:
                dn = name(d) or f'${d:08X}'
                what = ''
            ps = [name(p, ('',)) if org <= p < org + len(img) and name(p, ('',)) else f'${p:08X}'
                  for p in (p1, p2)]
            line = f'                dc.w    ${trig:04X},${x:04X},${y:04X}'
            out.append(line)
            out.append(f'                dc.l    {ps[0]},{ps[1]},{dn}'.ljust(51) + (f' ; {what}' if what else ''))
            a += 0x12
        if a < end:
            out.append('                dc.w    ' + ','.join(f'${w(b):04X}' for b in range(a, end, 2))
                       + '   ; end: never reached')
        src = open(path).read()
        i0 = src.index('\nWaveList:\n') + 1
        # keep any comment block directly above WaveList: with the new one
        i1 = src.index('\nLevelPalette:\n') + 1
        new = src[:i0] + '\n'.join(out) + '\n' + src[i1:]
        new = re.sub(r'\n(; Checkpoint list \(LV_Waves\).*\n.*\n)(?=; Checkpoint list)', '\n', new)
        open(path, 'w').write(new)
        if assemble(path) != img:
            open(path, 'w').write(src)
            print(f'{path}: output changed - restored'); continue
        print(f'{path}: {len(cps)} checkpoints, {(a - waves) // 0x12} waves')

if __name__ == '__main__':
    main()
