"""Write an AmigaDOS Old File System (DOS\\0) floppy image (ADF) whose files are
each stored in one contiguous run of data blocks, so that a loader can read a
file's blocks as one plain offset and length on the disk (the game's
4489_byteloader) while the disk stays a normal disk that Workbench and the
shell can read - under Kickstart 1.3 too, which only boots DOS\\0 floppies
and only reads OFS ones.

An OFS data block is a 24-byte header (T_DATA, the file header block, the
block's number in the file, how many data bytes it holds, the next data block,
a checksum) and 488 bytes of the file.  So a file of n blocks is n * 512 bytes
on the disk, its data at 24 + 512 * i (488 bytes each, the last one short);
the loaders read the run and squeeze the headers out.  The file header blocks
(and the extension blocks of files over 72 blocks) are kept together in one
run after the root and bitmap blocks, out of the way of the data runs.

    disk = OFSDisk('R-TYPE')
    off = disk.add('boot', data, block=2)     # place a file at a given block
    off = disk.add('music', data)             # or at the next free run
    adf = disk.image(bootblock)               # 901,120 bytes

`add` returns the file's offset on the disk in bytes.  Block layout: 0-1 the
bootblock, 880 the root, 881 the bitmap, 882 on the headers (`HEADERS` of
them reserved), the data everywhere else.
"""
import struct, time

BSIZE, NBLOCKS, ROOT, BITMAP = 512, 1760, 880, 881
DATA = BSIZE - 24             # file bytes in an OFS data block
HT_SIZE = 72                    # hash table / data block pointers per block
T_HEADER, T_LIST, T_DATA = 2, 16, 8
ST_ROOT, ST_FILE = 1, -3 & 0xFFFFFFFF


def checksum(block):
    """the value for offset 20 that makes the block's longs sum to 0"""
    s = sum(struct.unpack('>128L', block)) & 0xFFFFFFFF
    return (-s) & 0xFFFFFFFF


def boot_checksum(bb):
    """the bootblock checksum (offset 4): add with carry over 1024 bytes, inverted"""
    s = 0
    for (v,) in struct.iter_unpack('>L', bb):
        s += v
        if s > 0xFFFFFFFF:
            s = (s & 0xFFFFFFFF) + 1
    return (~s) & 0xFFFFFFFF


def name_hash(name):
    h = len(name)
    for c in name.upper():
        h = (h * 13 + ord(c)) & 0x7FF
    return h % HT_SIZE


def amiga_date(t=None):
    """days since 1 Jan 1978, minutes, ticks"""
    t = time.time() if t is None else t
    s = int(t) - 252460800
    return s // 86400, (s % 86400) // 60, (s % 60) * 50


class OFSDisk:
    HEADERS = 64                # blocks reserved for file headers and extension blocks

    def __init__(self, name, date=None):
        self.name = name
        self.date = amiga_date(date)
        self.used = [False] * NBLOCKS
        for b in (0, 1, ROOT, BITMAP):
            self.used[b] = True
        self.hdr_next = BITMAP + 1
        for b in range(self.hdr_next, self.hdr_next + self.HEADERS):
            self.used[b] = True
        self.blocks = {}        # block -> 512 bytes
        self.files = []         # (name, header block, first data block, length)

    def _run(self, n, start=None):
        """the first run of n free blocks (from start, if given)"""
        b = 2 if start is None else start
        while b + n <= NBLOCKS:
            if all(not self.used[x] for x in range(b, b + n)):
                return b
            if start is not None:
                raise ValueError('blocks %d-%d are not free' % (b, b + n - 1))
            b += 1
        raise ValueError('no room for %d blocks' % n)

    def _hdr_block(self):
        if self.hdr_next >= BITMAP + 1 + self.HEADERS:
            raise ValueError('out of header blocks')
        b = self.hdr_next
        self.hdr_next += 1
        return b

    @staticmethod
    def nblocks(length):
        return max(1, (length + DATA - 1) // DATA)

    def add(self, name, data, block=None):
        n = self.nblocks(len(data))
        first = self._run(n, block)
        header = self._hdr_block()
        for i in range(n):
            self.used[first + i] = True
            part = data[i * DATA:(i + 1) * DATA]
            blk = bytearray(BSIZE)
            struct.pack_into('>6L', blk, 0, T_DATA, header, i + 1, len(part),
                             first + i + 1 if i + 1 < n else 0, 0)
            blk[24:24 + len(part)] = part
            struct.pack_into('>L', blk, 20, checksum(blk))
            self.blocks[first + i] = bytes(blk)
        data_blocks = list(range(first, first + n))
        # the header holds the first 72 block pointers, extension blocks the rest
        chunks = [data_blocks[i:i + HT_SIZE] for i in range(0, n, HT_SIZE)] or [[]]
        exts = [self._hdr_block() for _ in chunks[1:]]
        for k, chunk in enumerate(chunks):
            key = header if k == 0 else exts[k - 1]
            blk = bytearray(BSIZE)
            struct.pack_into('>L', blk, 0, T_HEADER if k == 0 else T_LIST)
            struct.pack_into('>L', blk, 4, key)
            struct.pack_into('>L', blk, 8, len(chunk))          # high_seq
            struct.pack_into('>L', blk, 16, chunk[0] if chunk else 0)
            for i, d in enumerate(chunk):                       # table, from the end
                struct.pack_into('>L', blk, 24 + (HT_SIZE - 1 - i) * 4, d)
            if k == 0:
                struct.pack_into('>L', blk, BSIZE - 188, len(data))   # byte size
                struct.pack_into('>3L', blk, BSIZE - 92, *self.date)
                nm = name.encode('latin-1')[:30]
                blk[BSIZE - 80] = len(nm)
                blk[BSIZE - 79:BSIZE - 79 + len(nm)] = nm
            struct.pack_into('>L', blk, BSIZE - 12, ROOT if k == 0 else header)   # parent
            struct.pack_into('>L', blk, BSIZE - 8, exts[k] if k < len(exts) else 0)
            struct.pack_into('>L', blk, BSIZE - 4, ST_FILE)
            struct.pack_into('>L', blk, 20, checksum(blk))
            self.blocks[key] = bytes(blk)
        self.files.append((name, header, first, len(data)))
        return first * BSIZE

    def rewrite(self, name, data):
        """new contents for a file, of the same number of blocks and length"""
        fname, header, first, length = next(f for f in self.files if f[0] == name)
        assert len(data) == length, 'rewrite: the length must stay the same'
        n = self.nblocks(length)
        for i in range(n):
            blk = bytearray(self.blocks[first + i])
            part = data[i * DATA:(i + 1) * DATA]
            blk[24:24 + len(part)] = part
            struct.pack_into('>L', blk, 20, 0)
            struct.pack_into('>L', blk, 20, checksum(blk))
            self.blocks[first + i] = bytes(blk)

    def image(self, bootblock):
        root = bytearray(BSIZE)
        struct.pack_into('>L', root, 0, T_HEADER)
        struct.pack_into('>L', root, 12, HT_SIZE)
        chains = {}
        for name, header, _, _ in self.files:
            chains.setdefault(name_hash(name), []).append(header)
        for h, hdrs in chains.items():
            struct.pack_into('>L', root, 24 + h * 4, hdrs[0])
            for a, b in zip(hdrs, hdrs[1:]):       # hash chain (offset BSIZE-16)
                blk = bytearray(self.blocks[a])
                struct.pack_into('>L', blk, BSIZE - 16, b)
                struct.pack_into('>L', blk, 20, 0)
                struct.pack_into('>L', blk, 20, checksum(blk))
                self.blocks[a] = bytes(blk)
        struct.pack_into('>l', root, BSIZE - 200, -1)          # bitmap valid
        struct.pack_into('>L', root, BSIZE - 196, BITMAP)
        for off in (BSIZE - 92, BSIZE - 40, BSIZE - 28):       # dates
            struct.pack_into('>3L', root, off, *self.date)
        nm = self.name.encode('latin-1')[:30]
        root[BSIZE - 80] = len(nm)
        root[BSIZE - 79:BSIZE - 79 + len(nm)] = nm
        struct.pack_into('>L', root, BSIZE - 4, ST_ROOT)
        struct.pack_into('>L', root, 20, checksum(root))
        self.blocks[ROOT] = bytes(root)
        for b in range(self.hdr_next, BITMAP + 1 + self.HEADERS):   # unused header room
            if b not in self.blocks:
                self.used[b] = False
        bm = bytearray(BSIZE)                                  # bit set = free
        for b in range(2, NBLOCKS):
            if not self.used[b]:
                i = b - 2
                w = i // 32
                v = struct.unpack_from('>L', bm, 4 + w * 4)[0] | (1 << (i % 32))
                struct.pack_into('>L', bm, 4 + w * 4, v)
        s = sum(struct.unpack('>128L', bm)) & 0xFFFFFFFF      # checksum at 0
        struct.pack_into('>L', bm, 0, (-s) & 0xFFFFFFFF)
        self.blocks[BITMAP] = bytes(bm)
        img = bytearray(NBLOCKS * BSIZE)
        bb = bytearray(bootblock.ljust(1024, b'\0'))
        struct.pack_into('>L', bb, 4, 0)
        struct.pack_into('>L', bb, 4, boot_checksum(bb))
        img[0:1024] = bb
        for b, d in self.blocks.items():
            img[b * BSIZE:(b + 1) * BSIZE] = d
        return bytes(img)

    def free_blocks(self):
        return self.used.count(False)
