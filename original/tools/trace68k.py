#!/usr/bin/env python3
"""Recursive-descent code tracer for a flat 68000 memory image.

Library + CLI.  Follows bra/bcc/dbcc/bsr/jsr/jmp to absolute or PC-relative
targets; stops at rts/rte/rtr/jmp (an)/illegal.  Extra entry points can be
given (vectors, jump tables, pointers found by hand).
"""
import re, sys, json, capstone

STOP = {'rts', 'rte', 'rtr', 'illegal', 'stop'}

class Tracer:
    def __init__(self, mem, lo, hi):
        self.mem, self.lo, self.hi = mem, lo, hi
        self.md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000)
        self.ins = {}          # addr -> capstone insn
        self.owner = {}        # byte addr -> insn start
        self.refs = {}         # target -> set(from)
        self.bad = []

    def decode(self, a):
        if a in self.ins:
            return self.ins[a]
        got = list(self.md.disasm(self.mem[a:min(a + 10, self.hi)], a, count=1))
        if not got:
            return None
        i = got[0]
        if i.mnemonic in ('dc.w',):
            return None
        return i

    def trace(self, entries):
        todo = list(entries)
        while todo:
            a = todo.pop()
            while self.lo <= a < self.hi and a % 2 == 0:
                if a in self.ins:
                    break
                if a in self.owner:            # jumps into the middle of an insn
                    self.bad.append(('overlap', a)); break
                i = self.decode(a)
                if i is None:
                    self.bad.append(('undecodable', a)); break
                self.ins[a] = i
                for k in range(i.size):
                    self.owner[a + k] = a
                mn = i.mnemonic
                base = mn.split('.')[0]
                tgt = self.target(i)
                if tgt is not None:
                    self.refs.setdefault(tgt, set()).add(a)
                if base in STOP:
                    break
                if base in ('bra', 'jmp'):
                    if tgt is not None:
                        todo.append(tgt)
                    break
                if (base.startswith('b') and base not in ('btst', 'bset', 'bclr', 'bchg')) or base.startswith('db') or base in ('jsr',):
                    if tgt is not None:
                        todo.append(tgt)
                a += i.size

    def target(self, i):
        base = i.mnemonic.split('.')[0]
        op = i.op_str
        if base in ('jsr', 'jmp'):
            m = re.fullmatch(r'\$([0-9a-f]+)(\.[lw])?', op)
            if m: return int(m.group(1), 16)
            m = re.fullmatch(r'\$([0-9a-f]+)\(pc\)', op)
            if m: return int(m.group(1), 16)
            return None
        if (base.startswith('b') and base not in ('btst', 'bset', 'bclr', 'bchg')) or base.startswith('db'):
            m = re.search(r'\$([0-9a-f]+)$', op)
            if m: return int(m.group(1), 16)
        return None

    def gaps(self):
        out = []
        a = self.lo
        while a < self.hi:
            if a in self.owner:
                a += 1; continue
            s = a
            while a < self.hi and a not in self.owner:
                a += 1
            out.append((s, a))
        return out
