#!/usr/bin/env python3
"""Build the enhanced R-Type disk: enhanced/build/rtype.adf, an ordinary AmigaDOS
disk (OFS, DOS\\0 - Kickstart 1.3 boots and reads only that) with every file
stored in one run of blocks.

  python3 -I enhanced/tools/build.py            (VASM = vasmm68k_mot, SALVADOR = salvador)

1. Assembles the enhanced engine (src/game.s, with src/disk.s) and reads where
   its FileTable is, then stage 2 (src/stage2.s), placed so that it ends at
   $7A7A0 with the packed title picture just before it (build/layout.i).
2. Takes the other files from original/files/ (byte-identical to the original
   sources): the music, the $6000 block, the shared title file, the level
   files (level A trimmed to the $281C bytes that survive the level B load;
   level B in its unpacked form).
3. Packs every file but the boot file and the high scores with salvador
   (ZX0, its default format, which unzx0_68000.s reads) and works out, by running the
   format here (unzx0), how far past its destination each one must be loaded
   to be unpacked in place: the packed data ends at dest + unpacked + margin.
   Each in-place load is checked against what must survive it.
4. Lays the disk out (tools/ofs.py): the boot file from block 2 (the bootblock
   reads it with trackdisk), then the rest; writes the file table into stage 2
   inside the boot file, assembles the bootblock (src/boot.s) with where the
   boot file's blocks go, and writes the image.  Every file's blocks are read
   to end where its bytes must end and the 24-byte OFS headers squeezed out
   (moving up), so each load is checked for its blocks too.
5. Checks the image: every file read back from its offset (and through the
   file system with amitools' xdftool, if installed) and unpacked again.
"""
import os, re, struct, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ofs

HERE = os.path.dirname(os.path.abspath(__file__))
ENH = os.path.dirname(HERE)
ROOT = os.path.dirname(ENH)
SRC, BUILD = os.path.join(ENH, 'src'), os.path.join(ENH, 'build')
ORIG = os.path.join(ROOT, 'original')
FILES = os.path.join(ORIG, 'files')
VASM = os.environ.get('VASM', 'vasmm68k_mot')
SALVADOR = os.environ.get('SALVADOR', 'salvador')



# ---------------------------------------------------------------------------
def assemble(src, out, extra=()):
    lst = out + '.lst'
    r = subprocess.run([VASM, '-Fbin', '-m68000', '-no-opt', '-quiet', '-I', SRC, '-I', BUILD,
                        '-I', os.path.join(ORIG, 'src'), *extra, '-L', lst, '-o', out, src],
                       capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stdout + r.stderr)
    syms = {}
    for line in open(lst, errors='replace'):
        m = re.match(r'^([A-Za-z_]\w*)\s+[A-Z]:([0-9A-F]+)', line)
        if m:
            syms[m.group(1)] = int(m.group(2), 16)
    return open(out, 'rb').read(), syms


def level_file(n):
    """level n, parts A and B assembled together from the original sources (LEVEL_AB):
    A at $4A2E4 up to LevelAEnd, then B -> (bytes, symbols)"""
    lv = os.path.join(ORIG, 'src', 'levels')
    src = os.path.join(BUILD, 'level%d_ab.s' % n)
    with open(src, 'w') as f:
        f.write('; level %d, parts A and B together (written by tools/build.py)\n'
                'LEVEL_AB        equ     1\n'
                '                include "level%d.s"\n'
                '                include "level%d_b.s"\n' % (n, n, n))
    data, syms = assemble(src, os.path.join(BUILD, 'level%d.bin' % n),
                          ('-I', lv, '-I', os.path.join(ORIG, 'files')))
    assert syms['LvEnd'] - 0x4A2E4 == len(data)
    return data, syms


def equates(path):
    v = {}
    for line in open(path):
        m = re.match(r'^(\w+)\s+equ\s+(\$?[0-9A-Fa-f]+|\w+(?:[+*]\w+)*)', line)
        if m:
            x = m.group(2)
            try:
                v[m.group(1)] = int(x[1:], 16) if x.startswith('$') else int(x)
            except ValueError:
                v[m.group(1)] = eval(x, {}, v)
    return v


# ---------------------------------------------------------------------------
# ZX0 (salvador's default format), exactly as unzx0_68000.s reads it.  Returns the data
# and, for in-place unpacking, the margin: how many bytes past the unpacked end
# the packed data must reach so that no write lands on a byte not yet read.
def unzx0(src):
    """unzx0_68000.s, register for register: d1 the bit queue (with its stop bit),
    d2 the last offset.  Returns (data, margin)."""
    out = bytearray()
    pos = 0
    d1 = 0x80                   # moveq #-128,d1
    d2 = 0xFFFFFFFF             # moveq #-1,d2
    worst = None                # max over writes of (bytes written - bytes read)

    def add_d1():               # add.b d1,d1 -> carry
        nonlocal d1
        c = d1 >> 7
        d1 = (d1 << 1) & 0xFF
        return c

    def elias_loop(d0):         # .elias_loop / .elias_bt
        nonlocal d1, pos
        while True:
            c = add_d1()
            if d1 == 0:         # bne.s .got_bit not taken: refill
                b = src[pos]; pos += 1
                c, d1 = b >> 7, ((b << 1) | c) & 0xFF      # addx.b d1,d1 (X = c)
            if c:               # .got_bit: bcs.s .got_elias
                return d0
            d0 = ((d0 << 1) | add_d1()) & 0xFFFFFFFF      # .elias_bt: add.b, addx.l

    def put(b):
        nonlocal worst
        w = len(out) - pos
        worst = w if worst is None or w > worst else worst
        out.append(b)

    def copy_match(n):          # n bytes from dest + d2 (negative)
        off = d2 - (1 << 32)
        for _ in range(n):
            put(out[len(out) + off])

    state = 'literals'
    while True:
        if state == 'literals':
            for _ in range(elias_loop(1)):
                put(src[pos]); pos += 1
            state = 'get_offset' if add_d1() else 'rep_match'
        elif state == 'rep_match':
            copy_match(elias_loop(1))
            state = 'literals' if not add_d1() else 'get_offset'
        else:
            d0 = elias_loop(0xFFFFFFFE)
            d0 = (d0 & 0xFFFFFF00) | ((d0 + 1) & 0xFF)      # addq.b #1,d0
            if d0 & 0xFF == 0:
                break
            d2 = (d2 & 0xFFFF0000) | (d0 & 0xFFFF)          # move.w d0,d2
            d2 = (d2 & 0xFFFF0000) | ((d2 << 8) & 0xFFFF)   # lsl.w #8,d2
            d2 = (d2 & 0xFFFFFF00) | src[pos]; pos += 1     # move.b (a0)+,d2
            lenbit = d2 & 1                                 # asr.l #1,d2
            d2 = (d2 >> 1) | (d2 & 0x80000000)
            n = 1 if lenbit else elias_loop(((1 << 1) | add_d1()) & 0xFFFFFFFF)
            copy_match(n + 1)
            state = 'literals' if not add_d1() else 'get_offset'
    margin = max(0, (worst or 0) + 1 - (len(out) - len(src)))
    return bytes(out), margin


def pack(data, name):
    with tempfile.TemporaryDirectory() as t:
        a, b = os.path.join(t, 'in'), os.path.join(t, 'out')
        open(a, 'wb').write(data)
        r = subprocess.run([SALVADOR, a, b], capture_output=True, text=True)
        if r.returncode:
            sys.exit('salvador failed on %s: %s' % (name, r.stderr))
        packed = open(b, 'rb').read()
    back, margin = unzx0(packed)
    if back != data:
        sys.exit('%s: unzx0 does not give the data back' % name)
    return packed, margin


# ---------------------------------------------------------------------------
def read_ofs(adf, offset, length):
    """a file's bytes from its run of OFS blocks, as the loaders take them"""
    n = ofs.OFSDisk.nblocks(length)
    run = adf[offset:offset + 512 * n]
    return b''.join(run[k * 512 + 24:k * 512 + 512] for k in range(n))[:length]


def main():
    os.makedirs(BUILD, exist_ok=True)
    fid = equates(os.path.join(SRC, 'files.i'))
    # 1. the engine, then stage 2 placed to end at $7A7A0 after the packed picture
    game, gsyms = assemble(os.path.join(SRC, 'game.s'), os.path.join(BUILD, 'game_low.bin'))
    # resident.s against the engine's symbols, then menu.s against both (labels and
    # equates from the listings, without what files.i defines)
    def symfile(lsts):
        with open(os.path.join(BUILD, 'game_syms.i'), 'w') as f:
            f.write('; symbols for resident.s and menu.s (written by tools/build.py)\n')
            seen = set(fid)
            for lst in lsts:
                for line in open(os.path.join(BUILD, lst), errors='replace'):
                    m = re.match(r'^([A-Za-z_]\w*)\s+[AE]:([0-9A-F]+)\s*$', line)
                    if m and m.group(1) not in seen:
                        seen.add(m.group(1))
                        f.write('%-24s equ $%s\n' % (m.group(1), m.group(2)))
    symfile(['game_low.bin.lst'])
    resident, _ = assemble(os.path.join(SRC, 'resident.s'), os.path.join(BUILD, 'resident.bin'))
    symfile(['game_low.bin.lst', 'resident.bin.lst'])
    menu, _ = assemble(os.path.join(SRC, 'menu.s'), os.path.join(BUILD, 'menu.bin'))
    rd = lambda n: open(os.path.join(FILES, n), 'rb').read()
    picture = rd('boot_6efa0.bin')[:0xA3C0]                         # title picture + font
    pic_packed, _ = pack(picture, 'picture')
    BOOT_END = 0x7A7A0

    def layout(org, boot_blocks=1, boot_last=0):
        open(os.path.join(BUILD, 'layout.i'), 'w').write(
            'GAME_FILETABLE  equ     $%X\nSTAGE2_ORG      equ     $%X\nPIC_PACKED      equ     $%X\n'
            'BOOT_RAW        equ     $%X\nBOOT_BLOCKS     equ     %d\nBOOT_LAST       equ     %d\n'
            % (gsyms['FileTable'], org, org - len(pic_packed), BOOT_END - 512 * boot_blocks,
               boot_blocks, boot_last))

    org = 0x79360
    for _ in range(4):                                              # until its size settles
        layout(org)
        stage2, ssyms = assemble(os.path.join(SRC, 'stage2.s'), os.path.join(BUILD, 'stage2.bin'))
        new_org = BOOT_END - len(stage2)
        if new_org == org:
            break
        org = new_org & ~1
    assert org + len(stage2) == BOOT_END, 'stage 2 does not end at $7A7A0'

    # 2. the files: id -> (name, data, destination, packed?)
    boot = bytearray(pic_packed + stage2)
    hs = bytearray(0x194)                                           # the default table + checksum
    hs[0:0x190] = game[0x575C - 0xA4:0x575C - 0xA4 + 0x190]
    ck = 0x12345678
    for (v,) in struct.iter_unpack('>L', bytes(hs[0:0x190])):
        ck ^= v
    struct.pack_into('>L', hs, 0x190, ck)
    files = {
        fid['FID_BOOT']: ('boot', bytes(boot), org - len(pic_packed), False),
        fid['FID_MUSIC']: ('music', rd('music_52300.bin'), 0x52300, True),
        fid['FID_GAMELOW']: ('game', game, 0xA4, True),
        fid['FID_GAMEMAIN']: ('graphics', rd('game_main_06000.bin'), 0x6000, True),
        fid['FID_SHARED']: ('title', rd('shared_4a300.bin'), 0x4A300, True),
        fid['FID_HISCORE']: ('highscores', bytes(hs), None, False),
        fid['FID_RESIDENT']: ('cheats', resident, fid['RES_ORG'], True),
        fid['FID_MENU']: ('menu', menu, fid['MENU_ORG'], True),
    }
    levels = {}
    for n in range(1, 9):
        data, lsyms = level_file(n)
        levels[n] = lsyms
        files[fid['FID_LEVEL1'] + n - 1] = ('level%d' % n, data, 0x4A2E4, True)
        # what each level uses above its file: level 4's LevelInit copies its map to LvEnd
        top = lsyms['LvEnd'] + (13 * 0x158 if n == 4 else 0)
        assert top <= 0x7C400, 'level %d reaches the MFM buffer' % n
        levels[n] = top
    assert sorted(files) == list(range(fid['NFILES']))

    # 3. pack, and check each in-place unpacking against what must survive it
    stored = {}
    report = []
    for i in sorted(files):
        name, data, dest, packed = files[i]
        if packed:
            p, margin = pack(data, name)
            stored[i] = (p, len(data) + margin)
        else:
            stored[i] = (data, 0)
        p, end = stored[i]
        if packed:
            top = dest + end
            limits = {'music': org,                # stage 2 runs above it
                      'game': 0x6000,              # the $6000 block follows
                      'graphics': 0x32000,         # stage 2's MFM buffer
                      'title': 0x52300,
                      'cheats': fid['RES_LIMIT'],  # the level file
                      'menu': fid['MENU_LIMIT'],   # the end of chip memory (512K)
                      }.get(name, 0x7C400 if name.startswith('level') else 0x4D300)  # (the MFM buffer)
            if top > limits:
                sys.exit('%s: the packed data would end at $%X, over $%X' % (name, top, limits))
            raw = top - 512 * ofs.OFSDisk.nblocks(len(p))
            floor = {'cheats': 0x4935A}.get(name, dest)  # (stage 2 loads it before the
            if raw < floor:                        #  engine sets its object table up)
                sys.exit('%s: its blocks would start at $%X, below $%X' % (name, raw, floor))
        report.append((i, name, len(data), len(p), end - len(data) if end else None, dest))

    # 4. the disk
    disk = ofs.OFSDisk('R-Type')
    offsets = {}
    offsets[fid['FID_BOOT']] = disk.add('boot', stored[fid['FID_BOOT']][0], block=2)
    for i in sorted(files):
        if i != fid['FID_BOOT']:
            offsets[i] = disk.add(files[i][0], stored[i][0])
    table = b''.join(struct.pack('>3L', offsets[i], len(stored[i][0]), stored[i][1])
                     for i in sorted(files))
    t = ssyms['S2FileTable'] - (org - len(pic_packed))
    boot[t:t + len(table)] = table
    # the boot file again in its final form (the same length), then the bootblock
    disk.rewrite('boot', bytes(boot))
    n = ofs.OFSDisk.nblocks(len(boot))
    layout(org, n, len(boot) - 488 * (n - 1))
    if BOOT_END - 512 * n < 0x6EFA0:
        sys.exit("the boot file's blocks start at $%X, below the original's boot read" % (BOOT_END - 512 * n))
    bootblock, _ = assemble(os.path.join(SRC, 'boot.s'), os.path.join(BUILD, 'bootblock.bin'))
    adf = disk.image(bootblock)
    out = os.path.join(BUILD, 'rtype.adf')
    open(out, 'wb').write(adf)
    open(os.path.join(BUILD, 'boot.bin'), 'wb').write(bytes(boot))

    # 5. check it
    for i in sorted(files):
        name, data, dest, packed = files[i]
        p, end = stored[i]
        got = read_ofs(adf, offsets[i], len(p))
        if i == fid['FID_BOOT']:
            assert got == bytes(boot), 'boot file'
            continue
        if packed:
            got = unzx0(got)[0]
        if got != data:
            sys.exit('%s: read back wrong' % name)
    xdf = subprocess.run(['xdftool', out, 'list'], capture_output=True, text=True)
    if xdf.returncode == 0:
        with tempfile.TemporaryDirectory() as tdir:
            for i in sorted(files):
                name = files[i][0]
                f = os.path.join(tdir, name)
                subprocess.run(['xdftool', out, 'read', name, f], check=True, capture_output=True)
                want = bytes(boot) if i == fid['FID_BOOT'] else stored[i][0]
                if open(f, 'rb').read() != want:
                    sys.exit('xdftool reads %s differently' % name)
        chk = subprocess.run(['xdftool', out, 'info'], capture_output=True, text=True).stdout
    print('%-4s %-11s %9s %9s %7s  %s' % ('id', 'file', 'bytes', 'on disk', 'margin', 'offset'))
    for i, name, n, p, m, dest in report:
        print('%-4d %-11s %9d %9d %7s  $%05X' % (i, name, n, p, '-' if m is None else m, offsets[i]))
    used = sum(len(stored[i][0]) for i in files)
    print('free above each level in play: ' + ', '.join('%d: $%05X %.1fK' % (n, t, (0x80000 - t) / 1024)
                                                     for n, t in levels.items()))
    print('files %d bytes on disk; %d blocks free (%d KB)' % (used, disk.free_blocks(), disk.free_blocks() // 2))
    print('wrote %s%s' % (os.path.relpath(out, ROOT), ' (xdftool: files read back through the file system)' if xdf.returncode == 0 else ''))


if __name__ == '__main__':
    main()
