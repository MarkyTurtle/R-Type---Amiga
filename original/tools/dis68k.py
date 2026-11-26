#!/usr/bin/env python3
"""Quick 68000 disassembly listing: dis68k.py file offset length loadaddr"""
import sys, capstone
f, off, ln, base = sys.argv[1], int(sys.argv[2],0), int(sys.argv[3],0), int(sys.argv[4],0)
d = open(f,'rb').read()[off:off+ln]
md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000)
pos = 0
while pos < len(d):
    got = False
    for ins in md.disasm(d[pos:], base+pos):
        print(f"{ins.address:08x}  {ins.bytes.hex():<20} {ins.mnemonic:<8} {ins.op_str}")
        pos += ins.size; got = True
    if pos < len(d):
        print(f"{base+pos:08x}  {d[pos:pos+2].hex():<20} dc.w     ${d[pos:pos+2].hex()}"); pos += 2
