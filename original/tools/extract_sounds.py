#!/usr/bin/env python3
"""Write R-Type's sound effects as WAV files.

usage: python3 -I tools/extract_sounds.py files/ sfx/

SoundTable ($5B08 in the game program): 14 entries of 12 bytes
  +0.l sample address ($6000 block)  +4.w length (words)  +6.w period
  +8.w volume (0-64)  +$A.b 0  +$B.b priority
Samples are signed 8-bit; the WAVs are 8-bit unsigned mono at the PAL
playback rate (3546895 / period).  See docs/MUSIC.md.
"""
import os, struct, sys, wave

NAMES = ['ship_shot', 'wave_cannon', 'reflect_laser_bounce', 'anti_air_laser', 'ground_laser',
         'force_docks', 'enemy_hit', 'ship_explodes', 'power_up', 'beam_charged',
         'explosion_0', 'explosion_1', 'explosion_2', 'explosion_3']
PAL_CLOCK = 3546895

def main():
    files, out = sys.argv[1], sys.argv[2]
    os.makedirs(out, exist_ok=True)
    low = open(os.path.join(files, 'game_low_000a4.bin'), 'rb').read()
    blk = open(os.path.join(files, 'game_main_06000.bin'), 'rb').read()
    for i, name in enumerate(NAMES):
        e = 0x5B08 + i * 12 - 0xA4
        addr, words, period, vol, _, pri = struct.unpack('>IHHHBB', low[e:e + 12])
        data = blk[addr - 0x6000:addr - 0x6000 + words * 2]
        fn = os.path.join(out, f'{i:02d}_{name}.wav')
        with wave.open(fn, 'wb') as w:
            w.setnchannels(1); w.setsampwidth(1); w.setframerate(PAL_CLOCK // period)
            w.writeframes(bytes((b + 128) & 255 for b in data))
        print(f'{i:2d} {name:<15} ${addr:05X} {words * 2:5d} bytes  {PAL_CLOCK // period} Hz  vol {vol}  pri {pri}')

if __name__ == '__main__':
    main()
