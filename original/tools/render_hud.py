#!/usr/bin/env python3
"""Render the HUD and the game's fonts to PNG.

usage: python3 -I tools/render_hud.py files/ gfx/

  hud.png         the 3-plane HUD as it is in memory ($2C7B0, 320 x 15),
                  and again with a score, 5 lives and a full beam meter
                  drawn in the way DrawDigits / DrawLives / DrawBeamMeter do
  font_game.png   the 8x8 text font at $2CEB8 (2 planes, CharSet order)
  font_digits.png DigitFont: the HUD's 7-line score digits (in game.s)
All 2x size.  Colours: the copper list's HUD colours (COLOR01 is a
gradient in the game; drawn here as its brightest value), TextPalette for
the text font.
"""
import os, struct, sys
from PIL import Image

def rgb(c):
    return tuple(((c >> s) & 15) * 17 for s in (8, 4, 0))

HUD = 0x2C7B0
HUD_PAL = [0x000, 0xFFF, 0x999, 0xACD, 0xFFF, 0x89F, 0x00C, 0xE00]   # copper list
TEXT_PAL = [0x000, 0x28C, 0xFFF, 0x9BF]                              # TextPalette (COLOR01-03)

def main():
    files, out = sys.argv[1], sys.argv[2]
    blk = open(os.path.join(files, 'game_main_06000.bin'), 'rb').read()
    low = open(os.path.join(files, 'game_low_000a4.bin'), 'rb').read()
    mem = bytearray(0x2D1BA); mem[0x6000:0x6000 + len(blk)] = blk
    mem[0xA4:0xA4 + len(low)] = low
    sym = lambda name: int(name, 16)

    def hud_image(m):
        im = Image.new('RGB', (320, 15))
        for y in range(15):
            for x in range(320):
                b, bit = x >> 3, 7 - (x & 7)
                v = sum(((m[HUD + p * 0x258 + y * 40 + b] >> bit) & 1) << p for p in range(3))
                im.putpixel((x, y), rgb(HUD_PAL[v]))
        return im

    plain = hud_image(mem)
    # a filled-in HUD: score 123450, hi score 180000, 5 lives, full beam meter
    m = bytearray(mem)
    font = bytes(low[0x46BA - 0xA4:0x46BA - 0xA4 + 70])       # DigitFont
    def draw_digits(val, addr):
        for i, ch in enumerate('%06d' % val):
            for r in range(7):
                m[addr + i + r * 40] = font[int(ch) + r * 10]
    draw_digits(123450, 0x2C8F9)
    draw_digits(180000, 0x2C905)
    icon = bytes(low[0x470E - 0xA4:0x470E - 0xA4 + 18])        # LifeIcon
    for n in range(5):
        for r in range(6):
            a = 0x2C7DA + n + r * 40
            m[a], m[a + 0x258], m[a + 0x4B0] = icon[r], icon[6 + r], icon[12 + r]
    for r in range(5):
        for b in range(12):
            m[0x2C7E8 + r * 40 + b] = 0xFF
    filled = hud_image(m)
    sheet = Image.new('RGB', (320, 34), (40, 40, 40))
    sheet.paste(plain, (0, 0)); sheet.paste(filled, (0, 19))
    sheet.resize((640, 68), Image.NEAREST).save(os.path.join(out, 'hud.png'))

    # text font: 48 characters of 8 bytes, plane 1 $180 later
    f = Image.new('RGB', (48 * 9, 8), (40, 40, 40))
    for c in range(48):
        for r in range(8):
            p0, p1 = mem[0x2CEB8 + c * 8 + r], mem[0x2CEB8 + 0x180 + c * 8 + r]
            for x in range(8):
                v = ((p0 >> (7 - x)) & 1) | (((p1 >> (7 - x)) & 1) << 1)
                f.putpixel((c * 9 + x, r), rgb(TEXT_PAL[v]))
    f.resize((f.width * 2, 16), Image.NEAREST).save(os.path.join(out, 'font_game.png'))

    d = Image.new('RGB', (10 * 9, 7), (40, 40, 40))
    for c in range(10):
        for r in range(7):
            for x in range(8):
                if (font[c + r * 10] >> (7 - x)) & 1:
                    d.putpixel((c * 9 + x, r), (255, 255, 255))
                else:
                    d.putpixel((c * 9 + x, r), (0, 0, 0))
    d.resize((d.width * 2, 14), Image.NEAREST).save(os.path.join(out, 'font_digits.png'))
    print('written hud.png, font_game.png, font_digits.png')

if __name__ == '__main__':
    main()
