# R-Type (Amiga) – how the game is organised

How the engine (`src/game.s`) and the level code fit together. Addresses are absolute. The sources themselves carry the detail: every routine has a header comment and the level code has line comments.

## The program files

| File | Load | What it is |
|---|---|---|
| `game_low_000a4.bin` (tracks 32–35) | `$000A4` | **The whole engine.** Atari ST style header, TEXT `$000C0–$041B3` (all code), DATA `$041B4–$05C65`, then work space to `$05DE3`. Source: `src/game.s` |
| `game_main_06000.bin` (tracks 36–62) | `$06000` | Graphics and sound data only: no code at all (sprites, bullets, explosions, font, HUD) |
| `shared_4a300.bin` (tracks 63–67) | `$4A300` | Title / high-score data plus the jingle player called at `$4A300`. Overwritten when a level loads |
| `levelN_a_4a2e4.bin` | `$4A2E4` | ST header + level table at `$4A300` + level-specific code and data |
| `levelN_b_4d300.bin` | `$4D300` | Decrunched: tile graphics (from `$4D300`), map, level graphics and the level's music player |
| `music_52300.bin` | `$52300` | Title music: TFMX replay + `smpl` + `mdat` (also extracted separately: `tfmx_player_52300.exe`, `smpl.rtypetitle`, `mdat.rtypetitle`; see `MUSIC.md`) |

### Atari ST heritage

The program and the level A files start with a GEMDOS executable header: `$601A`, then the TEXT, DATA, BSS and symbol sizes and the flags. In `game_low` the TEXT/DATA sizes (`$40F4`/`$1AB2`) match exactly where code stops and data starts. The Amiga version was clearly built from the ST code base, and the credits say "ST graphics by Mark Jones". It also explains the ST-style screen handling, for example the HUD addresses being byte offsets into planar buffers.

## Start-up (`Init`, `$0010E`)

1. Stack at `StackTop` (`$466E`). It stores stage 2's d0–d3 (cache base, cache limit, music copy, current track).
2. `LoadHighScores` (track 68), `FormatScores`, `LoadShared` (tracks 63–67 → `$4A300`).
3. Sets stage 2's fade flag and waits until stage 2's VBL handler has faded the title out.
4. `ClearScreens`, `InitHardware`; installs the interrupt handlers: level 2 = keyboard (`$DE4`), level 3 = VBL + copper (`$20FC`), level 4 = audio (`$3BD6`); copper list `CopperList` (`$52E8`).
5. `PalCheck` is a PAL-only check. It times one video frame with CIA-A timer B, synchronised by the TOD counter, which counts vertical syncs. A PAL frame takes about 14,188 E-clock ticks and passes; an NTSC frame (about 11,932) falls under the 13,090-tick limit, and the game hangs. It runs at the start of every game, so an NTSC Amiga gets as far as the title screen and stops when a game starts.
6. `TitleSequence`: the attract mode (title letters, "blast off and strike the evil bydo empire!", high-score table, credits) until fire is pressed.
7. `NewGame` → `LoadLevel`.

## Level loading (`LoadLevel`, `$0029A`)

From `LevelTable` (`$41B4`, 10 bytes per level): load part A to `$4A2E4` and part B to `$4CB00`, set `MapWidth` (`$F4`: the map row length in bytes), then `Decrunch` part B to `$4D300`.

### Level interface (`$4A300`)

The first TEXT bytes of each level A file are a table the engine reads directly:

| Addr | Contents |
|---|---|
| `$4A300` | magic `$03011969` (in the shared file this is the jingle player's code) |
| `$4A304` LV_Waves | enemy wave list: `(scroll x.w, wave ptr.l)` |
| `$4A308` LV_Palette | 15 colours |
| `$4A30C` LV_Map | tile map (in level B) |
| `$4A310` LV_Tiles | tile graphics (`$4D300`) |
| `$4A314` LV_ScrollScript | scroll speed script (usually `$4A32C`) |
| `$4A318` LV_TileAnims | animated-tile routines (level 1 only) |
| `$4A31C` LV_MapPatches | map patch list (level 1 only) |
| `$4A320` LV_Frame | level routine called every frame |
| `$4A324` LV_Init | level start routine |
| `$4A328` LV_Music | music player inside level B |
| `$4A32C` | level 8: ending music; levels 1–7: start of the scroll script |

The level code calls back into the engine through the jump table at `$C2–$EA` (ObjInsert, ObjKillSelf, ObjCreate, ObjAlloc, Random, GetMapCell, FireEnemyBullet, DirectionTo, TurnTowards, AddScore, AdjustForScroll) and `$10A` (PlaySound), and it reads the shared variables at `$EE–$109` (ship position, scroll position, map row length…).

| Level | TEXT | DATA | LV_Frame | LV_Init | LV_Music |
|---|---|---|---|---|---|
| 1 | `$15E4` | `$9FA` | `$4B4E0` | `$4B4B2` | `$5CA38` |
| 2 | `$C14` | `$77C` | `$4A784` | `$4A754` | `$5E948` |
| 3 | `$10DC` | `$FB8` | `$4A760` | `$4A700` | `$634D0` |
| 4 | `$13A2` | `$7EE` | `$4B078` | `$4B052` | `$52078` |
| 5 | `$D10` | `$656` | `$4A918` | `$4A916` | `$51A54` |
| 6 | `$A2A` | `$266` | `$4A94C` | `$4A93A` | `$5C9A8` |
| 7 | `$149A` | `$9F8` | `$4B1DA` | `$4B16C` | `$582A4` |
| 8 | `$6B2` | `$6B6` | `$4A420` | `$4A3CE` | `$5C1FE` |

## The frame (`MainLoop` / `GameFrame`)

The main loop calls the routine in `GameState` (fade in → playing → stage clear …), then:

`UpdateScroll` → `DrawMap` (blits the 20×13 visible tiles into the back buffer) → `UpdateShots`, `UpdateWaveBeam`, `UpdateObjects`, `UpdateEnemyBullets`, `UpdateMissiles`, `ShipHitsMap` → `LV_Frame` → `UpdateScore`. It then sets `FrameReady` and waits.

The VBL (`Level3Int`) plays music, sound effects and jingles, reads the joystick (`ShipControl`) and moves the Bits. The **copper interrupt** (`CopperInt`) positions the hardware sprites used for the ship, the Force and the two Bits, and swaps the double buffers (`SwapScreens`: `SCREEN_A` `$2D1BA` / `SCREEN_B` `$3AEBA`) when a frame is ready. Everything else, enemies and shots included, is a blitter BOB drawn with `BlitBob` / `ObjAnimDraw`.

Controls: joystick in port 2. Fire taps for shots; holding fire charges the wave cannon (`ChargeBeam` / `DrawBeamMeter`). Button 2 or **Space** (`ReadFire2`) launches and recalls the Force. **P** pauses (keyboard interrupt).

## Frame pacing: 25 Hz game, 50 Hz ship

The main loop never waits for the vertical blank itself. It builds a frame into `DrawBuffer`, sets `FrameReady`, and spins until the copper interrupt has shown that frame; then it starts the next one.

- **`SwapScreens`** (called from the copper interrupt at line `$EC`) flips the buffers when a frame is ready and `FlipCountdown` has run out.
- **During play `Flip50Hz` is clear.** The countdown is reloaded with 1, so a flip can only happen every second VBL: the game logic and the BOBs run at a locked **25 Hz**.
- **The ship and the Bits move at 50 Hz.** They're hardware sprites, moved from the VBL (`ShipControl`, `UpdateBits`) up to `ShipUpdatesLeft` times per game frame (2 at 25 Hz) and positioned by the copper interrupt every frame. The player's own ship therefore moves at 50 Hz while everything else updates at 25 Hz.
- **The title and high-score screens set `Flip50Hz`** and run at 50 Hz.
- **Pause:** P toggles `Paused` from the keyboard interrupt. The main loop then stops after a complete frame, and unpausing resets the flip countdown.
- **Title music check:** the title tune is only started if `$52300` still begins with the TFMX file's hunk header (`$3F3`), i.e. if the music hasn't been overwritten by level data.

## Object system

See the comment block in `src/game.s` ("Object system") for the 62-byte object layout and the object-definition layout. There are 40 objects, a free list plus an active list sorted by priority, and each object has its own update routine pointer at `+6`. The level code creates its enemies through `ObjCreate` with a definition pointer.

## The ship

`ShipControl` runs from the VBL. It reads the joystick in port 2 (`JOY1DAT`: left = bit 9, right = bit 1, up = bit 9 ⊕ bit 8, down = bit 1 ⊕ bit 0) and moves the ship by `ShipSpeed` pixels within x `$96`–`$1A0` and y `$30`–`$DC`.

**Tilt:** moving up or down tilts the ship (`ShipTiltFrame` 0–16, drifting back to 8 = level when you let go). The tilt selects one of 5 sprite frames and also moves its hit box (`ShipTiltTable`).

**Scripted movement:** `ShipFlyIn` (level start: fly right to x `$186`, pause, back to x `$C8`) and `ShipAutoPilot` (stage end and the ending) steer it.

**Blinking:** while the ship isn't alive yet after a respawn, the copper interrupt hides it every other 2 VBLs.

## The Force

A state machine in `ForceState`, run from the copper interrupt (details in the comment above `Force_Idle`):

1. **Enter:** flies in from the left.
2. **Free:** parks at the screen edge away from the ship and drifts towards the ship's y.
3. **Return:** fire 2 (button 2 or Space, `ReadFire2`) calls it back.
4. **Docking:** touching the ship docks it at the front or the back (`ForceSide`). A powered-up Force (level 1) docked at the back becomes level 2, the rear-docked form with its own frames, and goes back to 1 when launched or reset.
5. **Launched:** fire 2 while docked launches it at 8 pixels a frame until it nears the edge, then it's free again.

`ForceLevel` is its power: 0 basic, 1 after a crystal, 2 the same docked at the back, 3 after a second crystal. The Force is four hardware sprites (SPR0–3) whose copper pointers are aimed straight at the frames in the `$6000` block (`UpdateForce`, table `ForceAnimTable`).

## Weapons and damage

**Fire button:** a tap fires a normal shot. Holding it charges the wave cannon (`ChargeBeam`, `BeamCharge`, meter in the HUD), released at one of four strengths (`WaveCannonShots`: charge 6/12/18/24 → 16×12 to 64×16 beams).

**The Force's weapon** (`FireForce`) depends on its state:
- **Free:** its own shots. Level 0 fires forward; level 1+ adds up-right and down-right; level 3 adds up and down (`ShotTypes`).
- **Docked:** set by the last crystal collected (`LaserType`, the crystal's frame number):
  - **0, blue: reflect laser.** Segments bounce off walls diagonally.
  - **1, red: anti-air laser.** The double helix.
  - **2, yellow: ground laser.** Segments crawl along floors and ceilings.

  The two segmented lasers use 4 segments, or 8 at Force level 3.

**Player shots** are 14 entries in parallel word arrays (x, y, hit box, type; see `HitByShots`):

| Entries | Weapon | Damage |
|---|---|---|
| 13 | wave cannon beam | its charge; carries on through enemies it doesn't kill |
| 12 | anti-air laser (helix) | 5 |
| 10–11 | shot streams | 2 |
| 0–9 | normal shots | 1, then removed |

**Collisions** (`ObjCollisions`, every object every frame, when on screen):
- the ship and the Force (touching the ship kills it, the Force damages the object)
- homing missiles, the Bits, the lasers, the shots

`BoxTest` is a simple distance test with separate left/right and up/down extents. `ObjDamage` adds the damage, and when it reaches the object's hit points (`$24`, usually the definition's; many bosses are made indestructible and count the damage themselves) the object explodes and the definition's score is added. Otherwise it flashes white for 3 frames (hit sound). Objects carrying a power-up release it when hit. Flag bit 2 makes an object immune to weapons, and hit points < 0 make it indestructible.

**Power-ups** (`HitByForceOrShip`): collecting one scores 400. Its frame number decides the effect: 0–2 blue/red/yellow crystal (sets `LaserType` and powers the Force up), 3 speed-up, 4 missiles, 5 a Bit.

**Homing missiles** (the M power-up): two are launched together on a fire press, with a 56-frame reload.
1. **Launch:** drift up or down.
2. **Forward:** fly right for 7 frames.
3. **Seek:** pick the nearest live enemy (one missile only above itself, the other only below).
4. **Home:** turn one of 16 directions towards it every 4th frame.

They explode on solid map cells.

**The Bits** trail the ship. Each VBL its position goes into a small ring buffer, and each Bit is placed at an older entry (25 pixels above or 29 below), which gives them their lagging movement.

**Enemy bullets:** 16 at most, aimed at the ship when fired (`FireEnemyBullet`, 16 directions). They're stopped by the map and the Force, and kill the ship on contact.

## Attract mode and credits

`TitleSequence` is a state machine in `TitleState`, run at 50 Hz. Each state fades the current screen out, then shows the next for `TitleDelay` frames. Fire on port 2 starts a game at any point.

1. **High score:** if the last game's score made the table, the player enters a name (`EnterName`: joystick up/down picks a character, fire takes it, up to 16 characters).
2. **Credits** (`TxtCredits`), for 200 frames.
3. **High-score table**, for 250 frames.
4. **Title:** the R-TYPE letters fly in as objects. Then the text: "blast off and strike the evil bydo empire!", "press fire to start", "freeplay" (or "trainer"), "C 1987 by irem". A 112-pixel-wide graphic from the shared file is wiped in 4 lines a frame. After 200 frames it goes back to the credits.

The credits in the program name the Amiga team:

| Role | Names |
|---|---|
| Design | Factor 5 (licensed from Irem by Electric Dreams, produced by Rainbow Arts) |
| Programming | Achim Möller, Holger Schmidt |
| Graphics | Lutz Osterkorn, Stefan Tsouparidis, Willi Baecker |
| Music | Darius Zendeh; title music Chris Huelsbeck |

(The boot loader's own credits, in `stage2.s`, also list Thomas Fanslau, Holger Schmidt and Willi Baecker for "tool coding", and Mark Jones for the ST graphics.)

The **ending text**, shown after level 8 (`TxtEnding`): "thanks to your brave fighting. the cosmos restored peace / the bydo empire was annihilated / to never scare people again. your name will remain in the universe forever."

## Hidden trainer

Enter **`sumita.`** as your high-score name. `CheatMode` (`$56FF`) is then set: no score, no lives lost, high scores not saved, and the title's "freeplay" line reads "trainer". The game hides both the name (`$E6EADAD2 >> 1` = "sumi", `$74612E20` = "ta. ") and the string pointer (stored halved). See `St_HighScore`.

## Level code (`src/levels/levelN.s`)

Each level A file is an ST program: a 28-byte header, then TEXT starting at `$4A300` and DATA straight after it. TEXT opens with the level interface table, then the level's data tables (wave list, palette, scroll script), then its code. DATA holds the object definitions, animation sequences and tables that the code and the engine's object system use. Whatever follows DATA in the file is unused padding to the track boundary.

| Level | TEXT tables | Code | DATA |
|---|---|---|---|
| 1 | `$4A300–$4A74D` | `$4A74E–$4B8E3` | `$4B8E4–$4C2DD` |
| 2 | `$4A300–$4A537` | `$4A538–$4AF13` | `$4AF14–$4B68F` |
| 3 | `$4A300–$4A6FF` | `$4A700–$4B3DB` | `$4B3DC–$4C393` |
| 4 | `$4A300–$4AA23` | `$4AA24–$4B6A1` | `$4B6A2–$4BE8F` |
| 5 | `$4A300–$4A807` | `$4A808–$4B00F` | `$4B010–$4B665` |
| 6 | `$4A300–$4A939` | `$4A93A–$4AD29` | `$4AD2A–$4AF8F` |
| 7 | `$4A300–$4A927` | `$4A928–$4B799` | `$4B79A–$4C191` |
| 8 | `$4A300–$4A3CD` | `$4A3CE–$4A971` | `$4A972–$4B067` (table at `$4A972`) |

The code was found by tracing from `LevelInit` and `LevelFrame` and from every pointer in DATA (enemy update and spawn routines are only reached that way). Levels 1, 4, 5 and 6 also contain a few routines that nothing calls: dead code left in the build. They are kept as code in the sources.

Engine calls in the level sources use the names in `src/engine.i` (for example `jsr (jt_ObjCreate).w`, `move.w (ShipPos).w,d0`).

## The stages

Enemies are named after the arcade's, matched by points, graphics and behaviour (labels `Def_<name>`, `Upd_<name>`, `Spawn_<name>`; pictures in [OBJECTS.md](OBJECTS.md)). Levels 4 and 7 reuse level 1's enemies with the same code, copied into each level file. Every boss is mostly map cells, which the level code rewrites (`PatchMap`) to animate it, plus one or more invisible target objects that take the hits.

| Stage | Enemies | Boss |
|---|---|---|
| 1 | Pata-Pata, Bug, P-Staff, Scant, Bink, Cancer, Shell (12 turrets round a control unit), Tabrok; Blasters (gun batteries built into the map, the tile animations) | Dobkeratops: tail of 16 segments, core takes 30 hits (6200 points). The scroll stops at the boss for 1250 frames (cut to 50 after 20 hits), then restarts and the boss advances; reaching the end of the map also completes the level |
| 2 | Gouger, Wick, the Worm (two heads, 7 eyes at 200 each), two Broods that release Zoids | Gomander: the eye opens and closes in the map, faster each time; core takes 30 hits (9000 points) |
| 3 | The battleship itself: gun towers, cannon pods, the main engine (three-way shots, breaks away), the laser tower, shooting hull parts, the rear tower | The Main Core in the engine room (10 hits); a timer ends the level when the ship has gone by |
| 4 | Level 1's Pata-Pata, Bug, P-Staff, Bink, Cancer; Cytron (builds cell walls), Geld (eats them) | The Compiler: three sections on their own paths, each with a core (30 hits, 5000 points) and a gun |
| 5 | Cancer, Slither (breaks apart when the head dies, splits when a body segment is shot), Pursuer, Cheetah and the Mid-phase Cheetah | Bellmite with 8 shells it throws at the ship one at a time (they fly back to their slots); 30 damage, 2000 points; the background loops |
| 6 | Dop containers on rails (hurt only from the core side), Bink, the Capsule | None: a queue of Dops at the end |
| 7 | Level 1's enemies, the Mid-phase Cheetah, Bold (70 hits, from behind), the Sonar, a crawler, collapsing buildings | Bronco (50 hits) with 5 garbage chutes that drop junk and enemies |
| 8 | Mikun, Win (immortal, homes in faster each time the core opens) | The Bydo (60 hits, 15000 points), then the ending: the R-9 escort and the ending text |

Every stage also has the POW Armor, the engine's default wave object, which carries the power-ups.

## Shared title file (`src/shared.s`)

`$4A300–$4A615` is a small position-independent sample sequencer (`JinglePlayer`) that drives all four audio channels; `$4A616` on is its state and data: the jingle sequence, `NoteTable` (`$4A78E`), `SampleTable` (`$4B430`), `PeriodTable` (`$4B480`) and the 8-bit samples (`$4B4D6` on). The engine calls it from the VBL (`UpdateJingle`) for the title and high-score screens. The in-game music players are separate: each one sits in its level's part B and is reached through `LV_Music`.

## Still to do

Everything is named and commented; what's left is tracked in [TODO.md](TODO.md).
