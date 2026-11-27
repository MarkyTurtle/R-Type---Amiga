#!/usr/bin/env python3
"""Add line comments to the sources without retyping the code (editing helper).

usage:
  python3 -I tools/line_comments.py apply SPEC FILE.s
  python3 -I tools/line_comments.py propagate [--loose] FROM.s TO.s [...]

apply: SPEC has one comment per line, `Anchor[+n]  comment`, where Anchor
is a label in FILE (a routine name or a local label such as .4A872) and
n counts instructions after it (0 = the first, the default).  Blank
lines and lines starting with # are ignored.  The comment replaces any
comment already on that line; a comment of `-` removes it.

propagate: a routine in TO gets the line comments of the routine with
the same name in FROM when both have the same instructions (local labels
and 5+ digit hex addresses are ignored in the comparison, so copies of
an enemy at another load address still match).  Routines that differ
are listed and left alone.  With --loose, a routine of the same length
that differs in a few lines gets the comments of its matching lines, and
the differing lines are printed for commenting by hand.  With --sync,
matching lines also lose comments that FROM no longer has.

Only comments change, so the assembled output stays identical; run
tools/verify.py afterwards.
"""
import re, sys

COL = 48
LABEL = re.compile(r'^(\.?[A-Za-z_0-9]\w*):')
GLOBAL = re.compile(r'^([A-Za-z_]\w*):')

def is_insn(line):
    return re.match(r'^\s+[a-z]', line) is not None

def split(line):
    """code part, comment part (without ';'), ignoring ';' inside quotes."""
    q = False
    for i, c in enumerate(line):
        if c in '"\'':
            q = not q
        elif c == ';' and not q:
            return line[:i].rstrip(), line[i + 1:].strip()
    return line.rstrip('\n').rstrip(), None

def with_comment(line, text):
    code, _ = split(line.rstrip('\n'))
    return code.ljust(COL - 1) + ' ; ' + text + '\n'

def apply(spec, path):
    lines = open(path).readlines()
    where = {}
    for i, l in enumerate(lines):
        m = LABEL.match(l)
        if m:
            if m.group(1) in where:
                where[m.group(1)] = None          # ambiguous
            else:
                where[m.group(1)] = i
    errors = 0
    for s in open(spec):
        s = s.rstrip('\n')
        if not s.strip() or s.lstrip().startswith('#'):
            continue
        key, text = (s.split(None, 1) + ['-'])[:2]
        anchor, _, n = key.partition('+')
        n = int(n or 0)
        i = where.get(anchor)
        if i is None:
            print('no unique label', anchor); errors += 1; continue
        k = -1
        while k < n:
            i += 1
            if i >= len(lines) or GLOBAL.match(lines[i]):
                break
            if is_insn(lines[i]):
                k += 1
        if k != n:
            print('past the routine:', key); errors += 1; continue
        if text.strip() == '-':
            lines[i] = split(lines[i].rstrip('\n'))[0] + '\n'
        else:
            lines[i] = with_comment(lines[i], text.strip())
    open(path, 'w').writelines(lines)
    return errors

def routines(lines):
    """instruction lines per routine (data lines are left out: their
    comments describe values that differ between levels)."""
    out, cur = {}, None
    for i, l in enumerate(lines):
        m = GLOBAL.match(l)
        if m:
            cur = m.group(1); out[cur] = []
        elif cur and is_insn(l) and not re.match(r'\s+dc\.', l):
            out[cur].append(i)
    return out

def norm(line, locals_):
    code, _ = split(line)
    code = re.sub(r'\.[0-9A-F]{5}\b', lambda m: '.L%d' % locals_.setdefault(m.group(0), len(locals_)), code)
    code = re.sub(r'\$[0-9A-F]{5,}', '$ADDR', code)
    return ' '.join(code.split())

def propagate(src, dst, loose=False, sync=False):
    sl = open(src).readlines(); dl = open(dst).readlines()
    sr, dr = routines(sl), routines(dl)
    copied, differ = 0, []
    for name, si in sr.items():
        if name not in dr or not any(split(sl[i])[1] for i in si):
            continue
        di = dr[name]
        a, b = {}, {}
        ns, nd = [norm(sl[i], a) for i in si], [norm(dl[i], b) for i in di]
        if ns != nd:
            if not loose or len(ns) != len(nd):
                differ.append(name); continue
            for x, y, j in zip(ns, nd, di):
                if x != y:
                    print('  %s line %d: %s' % (name, j + 1, dl[j].strip()))
        for i, j, x, y in zip(si, di, ns, nd):
            c = split(sl[i])[1]
            if c and x == y and split(dl[j])[1] != c:
                dl[j] = with_comment(dl[j], c)
            elif sync and not c and x == y and split(dl[j])[1]:
                print('  %s line %d: removed "%s"' % (name, j + 1, split(dl[j])[1]))
                dl[j] = split(dl[j])[0] + '\n'
        copied += 1
    open(dst, 'w').writelines(dl)
    print('%s: %d routines from %s%s' % (dst, copied, src,
          ('; differ: ' + ' '.join(differ)) if differ else ''))

if __name__ == '__main__':
    if len(sys.argv) == 4 and sys.argv[1] == 'apply':
        sys.exit(1 if apply(sys.argv[2], sys.argv[3]) else 0)
    elif len(sys.argv) >= 4 and sys.argv[1] == 'propagate':
        args = sys.argv[2:]
        opts = set()
        while args[0].startswith('--'):
            opts.add(args.pop(0))
        for d in args[1:]:
            propagate(args[0], d, '--loose' in opts, '--sync' in opts)
    else:
        sys.exit(__doc__)
