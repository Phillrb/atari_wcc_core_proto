# AGENTS.md - Atari World Cup (WCC / Goal IV) FPGA Recreation

## Prime Directive

You are recreating Atari's 1974 arcade game "World Cup" (also known as "World Cup Football", "Coupe du Monde", "Goal IV") as a faithful VHDL FPGA implementation. The PCB is marked "WCC" and the manual is "TM-035". Your VHDL must closely mirror the original schematics so that every signal path is traceable back to the manual. Use explicit 74-series TTL IC instantiations for all logic - never use loose `and`, `or`, `not` operators where a documented IC exists for that function.

## Rules (Non-Negotiable)

1. **TTL fidelity is sacred.** Every logic operation must go through an explicit IC entity (`entity work.LS04`, `entity work.LS08`, etc.) matching the schematic. Never use behavioural VHDL shortcuts (`A and B`) for logic that is documented as a specific IC gate on the PCB.

2. **The manual is the source of truth.** [Goal_IV_TM-035.md](Goal_IV_TM-035.md) and the original PDF [Goal_IV_TM-035.pdf](Goal_IV_TM-035.pdf) define what to build. The schematic diagrams in [diagrams/](diagrams/) are the gold standard. If you cannot read a schematic clearly, ask your human operator to clarify connections or signal names.

3. **Don't trust pre-existing VHDL.** Inspect every file before relying on it. Some files have syntax errors, use the wrong instantiation style (`components_pkg` instead of direct entity), or have incorrect logic. Add testbench tests for any IC or circuit you use.

4. **Visual verification is mandatory.** Every change that can affect video output must produce a simulation snapshot. Run `cd sim && bash run_sim.sh`, inspect the resulting `frame_output.png`, and analyse the signals. For animations or multi-state changes, generate multiple frames and create a GIF. Never claim something "should work" without a screenshot proving it.

5. **Incremental development.** Build one circuit element at a time. Verify each with simulation before moving on. Do not wire up a complex circuit and hope it works.

6. **Git locally, don't push.** Commit working changes to git frequently, but do not push to remote until the human operator says so. Do not add yourself as co-author.

7. **Ask when uncertain.** If a schematic is ambiguous, a signal name is unclear, or a design choice could go multiple ways, ask the human operator rather than guessing.

---

## Project Structure

```
atari_wcc_core_proto/
  74LS/               # 74-series TTL IC models (LS00, LS02, LS04, LS08, etc.)
  IC/                 # Other IC models (IC9316, IC9314, IC9602, IC555, dff, jkff)
  diagrams/           # Schematic figures from TM-035 manual (PNG)
  docs/               # Build documentation, analysis, implementation notes
  sim/                # Simulation scripts and output (run_sim.sh, visualize.py, frame_output.png)
  testbench/          # VHDL testbenches (tb_atari_wcc.vhd, etc.)
  *.vhd               # Circuit implementation files (top level)
  Goal_IV_TM-035.md   # Manual (markdown, OCR-derived) - SOURCE OF TRUTH
  Goal_IV_TM-035.pdf  # Original manual PDF
  Goal_IV_TM-035_ocr.pdf  # OCR-enhanced PDF
```

Note: The project was consolidated from a `cross_display/` subdirectory into the top level. Any references to `cross_display/` in older docs are legacy.

---

## VHDL Style Conventions

Learn these from the existing working files (ComputerClock.vhd, HorizontalSync.vhd, VerticalSync.vhd, atari_wcc.vhd):

### Entity Instantiation
Always use **direct entity instantiation** (required for GHDL 0.37 mcode compatibility):
```vhdl
-- CORRECT:
F1: entity work.LS93
    port map( P1_CP1n => h1_i, ... );

-- WRONG (will compile but simulate as disconnected in GHDL):
F1: LS93
    port map( P1_CP1n => h1_i, ... );

-- WRONG (old style, do not use):
use work.components_pkg.ALL;
F1: LS93 port map( ... );
```

### Pin Naming
Port names encode both pin number and signal name: `P<pin>_<signal>`:
```vhdl
P1_A1   -- Pin 1, input A of gate 1
P3_Y1   -- Pin 3, output Y of gate 1
P12_Q0  -- Pin 12, Q output of counter stage 0
```

### IC Instance Naming
Use PCB grid location as the instance label where known (from the IC layout grid in README.md):
```vhdl
F1: entity work.LS93 ...   -- F1 on the PCB grid
C2: entity work.LS30 ...   -- C2 on the PCB grid
```
For circuits with unknown grid positions or test circuits, use descriptive prefixes:
```vhdl
IC_M5: entity work.LS86 ...
U_BALL: entity work.LS00 ...
```

### Internal Signals (VHDL-93 out-port readback)
VHDL-93 does not allow reading `out` ports internally. Use `_i` suffix internal signals:
```vhdl
signal h1_i : STD_LOGIC;
...
H1 <= h1_i;  -- Drive output from internal signal
-- Now use h1_i wherever you need to read back H1
```

### Unused IC Pins
Connect unused inputs to safe defaults (`'0'` or `'1'`), unused outputs to `open`:
```vhdl
U_C8: entity work.LS00
    port map(
        P1_A1 => '1', P2_B1 => '1', P3_Y1 => open,  -- Gate 1 unused
        P9_A3 => B8_Q1, P10_B3 => B8_Q2, P8_Y3 => C8_8_out  -- Gate 3 used
    );
```

### File Headers
Each circuit file should have a comment block identifying:
- Circuit name and TM-035 figure number
- ICs used (by PCB grid position)
- Brief description of function
```vhdl
-- Playfield Circuit for Goal IV (WCC) - TM-035 Figure 9
-- ICs: M5(LS86), N5(LS00), N4(LS27), H4(LS02), H6(LS10), J4(LS20), K4(LS107), C6(LS04)
-- Generates field boundaries, goal boxes and goal openings.
```

---

## Simulation Pipeline

### Running a Simulation
```bash
cd sim && bash run_sim.sh
```
This compiles all VHDL (74LS library, IC library, design files, testbench), runs GHDL for the configured duration, and calls `visualize.py` to produce `frame_output.png`.

### Run behaviour
The testbench stops after 500 frames (or 60 s safety timeout); override with `STOP_MS=900` (or similar) to control run length. The visualizer produces `frame_output.png` (requires Pillow) and `gameplay.gif` (animated, all complete frames) when >2 frames are present.

### Output Files
| File | Purpose |
|------|---------|
| `sim/frame_data.txt` | Raw samples: `HSYNC VSYNC HBLANK VIDEO` at 7.159 MHz |
| `sim/frame_output.png` | Rendered still frame (second-to-last complete frame, 2x scale, green phosphor) |
| `sim/gameplay.gif` | Animated GIF of all complete frames (1x scale, 100 ms/frame) |
| `sim/frame_output.ppm` | Written only when `--ppm` flag is passed to visualize.py |

### Current sim output (limitations)
Ball rendering is **enabled** in `atari_wcc.vhd` (`VIDEO <= ... or (ball_i and hblankn_i)`). The serve process fires at t=13ms; the ball circuit takes ~19ms after serve to stabilise (B3_Q1 phase flip-flop needs D4 to first cycle to 15). Ball is visible from frame 5 onward (t>=80ms). The visualizer now picks the second-to-last frame to show a fully-stabilised ball position.

**Ball diagonal shape is hardware-accurate**: 374 active clocks per line (H=80..453) is not divisible by 8 (the C4 counter range), so the ball window drifts horizontally by 6px each scanline. This is inherent TTL behaviour masked by CRT phosphor persistence on the original hardware. No fix needed or possible without changing the counter architecture.

### Board build (MaSTer clock and video)
For a real CRT, use the same clock and video stack as the **MaSTer** projects: 50 MHz board clock → PLL → **14.318180 MHz**, and MaSTer-style composite output (Sync + Video resistors). See [docs/MASTER_CLOCK_AND_VIDEO_ADOPTION.md](docs/MASTER_CLOCK_AND_VIDEO_ADOPTION.md). Use **atari_wcc_board** as the Quartus top and **Altera/clk_pll.vhd** for the PLL.

### Adding New Circuits to Simulation
1. Add `ghdl -a --std=93 "$ROOT/YourCircuit.vhd"` to `sim/run_sim.sh`
2. Instantiate in `atari_wcc.vhd` (the simulation and Quartus top-level)
3. Wire the output into the VIDEO signal path
4. Run simulation and verify PNG output

### Multi-Frame / GIF Generation
`visualize.py` automatically generates `gameplay.gif` from all complete frames when >2 frames are present. Use `STOP_MS=2000` (or higher) in `run_sim.sh` to capture enough frames for a meaningful animation.

---

## GHDL Compatibility (Critical)

| Issue | Fix |
|-------|-----|
| No default component binding | Use `entity work.X port map(...)` everywhere |
| Cannot read `out` ports | Use `_i` suffix internal signals + concurrent assign to outputs |
| `clk'event and clk='1'` treats `'U'->'1'` as edge | Use `rising_edge(clk)` instead |
| Chained NAND bug | `not(A and B and C)` not `((A nand B) nand C)` |
| VHDL standard | Always compile with `--std=93` |

---

## 74LS IC Library

All 74-series ICs listed below have been validated (testbenches and/or simulation).

### Available (in `74LS/`)
| IC | Type | File | Notes |
|----|------|------|-------|
| LS00 | Quad 2-input NAND | LS00.vhd | |
| LS02 | Quad 2-input NOR | LS02.vhd | |
| LS04 | Hex Inverter | LS04.vhd | |
| LS08 | Quad 2-input AND | LS08.vhd | |
| LS10 | Triple 3-input NAND | LS10.vhd | Fixed: uses `not(A and B and C)` |
| LS20 | Dual 4-input NAND | LS20.vhd | Fixed: uses `not(A and B and C and D)` |
| LS27 | Triple 3-input NOR | LS27.vhd | |
| LS30 | 8-input NAND | LS30.vhd | Fixed: uses `not(A and B and ... and H)` |
| LS74 | Dual D Flip-Flop | LS74.vhd | |
| LS83 | 4-bit Binary Adder | LS83.vhd | Behavioural (no internal ICs) |
| LS86 | Quad 2-input XOR | LS86.vhd | |
| LS90 | Decade Counter | LS90.vhd | |
| LS92 | Divide-by-12 Counter | LS92.vhd | |
| LS93 | 4-bit Binary Counter | LS93.vhd | Fixed: MR polarity `MR1 and MR2` |
| LS107 | Dual JK Flip-Flop | LS107.vhd | |
| LS153 | Dual 4-to-1 Mux | LS153.vhd | |
| LS48 | BCD-to-7-Segment Decoder | LS48.vhd | PCB M2; for score circuit |

### Needed (not yet implemented)
| IC | Type | PCB Location | Notes |
|----|------|-------------|-------|
| *(none)* | | | |

### Other ICs (in `IC/`)
| IC | Type | File |
|----|------|------|
| IC9314 | 4-bit Latch | IC9314.vhd |
| IC9316 | 4-bit Presettable Counter | IC9316.vhd |
| IC9602 | Dual Retriggerable Monostable | IC9602.vhd |
| dff | D Flip-Flop primitive | dff.vhd |
| jkff | JK Flip-Flop primitive | jkff.vhd |

### Quality Notes
- All 74LS ICs in the library have been validated; you can rely on them for new circuits.
- The chained NAND bug was fixed in LS10/LS20/LS30.
- LS93 MR polarity was fixed (`MR1 and MR2`, not `MR1 nand MR2`).
- jkff.vhd uses `rising_edge(clk)` (fixed from `clk'event and clk='1'`).

---

## Bugs Found and Fixed (Reference)

These bugs were discovered during simulation bring-up. Be aware of them when writing new code or reviewing existing files:

1. **Chained NAND**: `((A nand B) nand C)` != `not(A and B and C)`. Fixed in LS10/LS20/LS30.
2. **JK FF rising edge**: `clk'event and clk='1'` treats `'U'->'1'` at time 0 as an edge. Use `rising_edge(clk)`.
3. **LS93 MR polarity**: `MR <= MR1 and MR2` (both HIGH = reset). Not NAND.
4. **H counter aliasing**: 4-bit counters repeat after H=255 in a 455-clock line. Gate VIDEO with H256n.
5. **HorizontalSync port-name mismatches**: LS30 single-gate uses `P1_A` not `P1_A1`; LS00 pin 8 is output `P8_Y3` not input `P8_A3`; LS74 port is `P4_SET1n` not `P4_PRE1n`.

---

## Circuit Implementation Plan

**Full plan (what to do in what order):** [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md).

The Goal IV game consists of the following circuits, listed in recommended implementation order. Each references a figure from TM-035 and has a schematic diagram in `diagrams/`.

### Phase 0: Foundation (DONE)
These are verified and working:

| Circuit | File | Figure | Status |
|---------|------|--------|--------|
| Computer Clock | ComputerClock.vhd | Fig 3 | Verified |
| Horizontal Sync | HorizontalSync.vhd | Fig 4 | Verified |
| Vertical Sync | VerticalSync.vhd | Fig 5 | Verified |
| Sync Summing | SyncSumming.vhd | Fig 6 | Verified |

Timing: 455 clocks/scanline, 313 lines/frame, 50.27 Hz (PAL).

### Phase 1: Static Video (DONE – schematic-accurate)

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Playfield | PlayfieldCircuit.vhd | Fig 9 | M5(LS86), N5(LS00), N4(LS27), H4(LS02), H6(LS10), J4(LS20), K4(LS107), C6(LS04) | Schematic-accurate: all logic via TTL. K4 is single LS107 (FF1=V, FF2=H). (A+B)n from H6 pin 8; (C+D)n via J4 gate 2; H4=LS02 NOR(V4,V8)→J4. Verified in sim. |

### Phase 2: Game Control Logic (PARTIALLY DONE - NEEDS REVIEW)

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Electronic Latch | ElectronicLatchCircuit.vhd | Fig 8 | A8(LS04), transistors Q1-Q3 | Exists, models transistor latch as FF. Review needed. |
| Credit | CreditCircuit.vhd | Fig 8 | A8(LS04), B8(LS74), C8(LS00), C9(LS27), A9(LS74) | Exists. Review needed. |
| Start | StartCircuit.vhd | Fig 8 | A8(LS04), C9(LS02), B9(LS74) | Exists. Review needed. |
| Game Select | GameSelectCircuit.vhd | Fig 10 | D9(LS74 half), C5(LS08) | Exists. Review needed. |
| Time Line | TimeLineCircuit.vhd | Fig 8 | A2(LS10), N4(LS27), K1(LS74), D9(LS04), E9(555), J2(LS04) | Exists, 555 modelled digitally. Review needed. |
| Serve Timing | ServeTimingCircuit.vhd | Fig 12 | J5(9602), L5(LS74), H4(LS02) | Exists, one-shot modelled as counter. Review needed. |

### Phase 3: Ball System (DONE)

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Vertical Direction & Speed | VerticalDirectionAndSpeed.vhd | Fig 14 | D7(9314), D6(LS74), C7(LS86), B7(LS02), F6(LS00), C6(LS04), A7(LS83) | Done. Wired into top-level. D7 MRn polarity fixed: `SERVEn=>serve_i`. A7 adder connections verified against schematic. |
| Horizontal Direction & Speed | HorizontalDirectionAndSpeed.vhd | Fig 15 | B6(IC9316), B5(LS83), A6(LS08), A5(LS86), B7(LS02), F6(LS00), C6(LS04), F5(LS08) | Done. Wired into top-level. Idle in sim (BALL='0'). |
| Ball Motion | BallMotionCircuit.vhd | Fig 16 | A4(IC9316), D4(IC9316), B4(IC9316), C4(IC9316), B3(LS107), A3(LS10)+A2(LS10 label for A3 gate 1), D3(LS08), C3(LS00), E3(LS04) | Done. Schematic-verified. D4 preset=12(1100), C4 preset=8(1000). Ball visible in sim. Serve process fires at 13ms; ball stabilises ~19ms later. Diagonal shape is hardware-accurate (374 active px/line not divisible by 8). |
| Catch/Kick/Horizontal Direction | CatchKickHorizontalDirection.vhd | Fig 13 | E8(LS00), C8(LS00), D8(LS74), D5(LS74), C5(LS08), C9(LS02), K8(LS02), A8(LS04), D9(LS04) | Done. J5 ch1 STOP/STOPn via ServeTimingCircuit. Idle in sim (BALL='0', HIT='0'). |

### Phase 4: Players (Solid + Striped Forwards, Defense, Goalie – Fig 11)

| Sub-circuit | File | Status |
|-------------|------|--------|
| Vertical Window Generator | PlayersVerticalWindow.vhd | Done. M6(LS92), D6(LS74), F6, H6(LS10), J6(LS27), L6(LS86). TEAM, GOALIE, DEFENSEMENn, Q, Qn, BLIP, PLAYER_WINDOWn. Uniform spacing correction: J6 NOR inputs changed from (Q2,Q1) to (Q1 XOR Q2, Q3) for symmetric 48px column gaps; L6 gates 2&3 changed from Q3 to Q2 for correct TEAM/DEFENSEMENn. |
| Ramp Generator | PlayersRampGenerator.vhd | Done. Digital ramp; LS00 charge enable; RAMP_VALUE(9:0) for comparators. |
| Multiplexer | PlayersMultiplexer.vhd | Done. L7, H7(LS153). Select TEAM, Qn; B1–E4 → PP2, PP3, PP4, SYMBOL. |
| Check Pattern / One-Player Defeat / Player Summing | PlayersSumming.vhd | Done. E6(XOR H1,V1), F6(NAND TEAM), J2, J1, M1(LS08), K6(LS08) → **PADDLES**. |
| Solid Forwards | PlayersSolidForwards.vhd | Done. Comparator, M9(IC9602) PULSE_WIDTH=70, K8(LS02), K7(IC9316), J8(LS04) → E2,B2,C2,D2. Vertical spacing 70 scanlines. |
| Solid Defense/Goalie | PlayersSolidDefenseGoalie.vhd | Done. 555 model, M7(9316), H8(LS107), E6/K6/J6/L8/J8 → E1,B1,C1,D1. E1 gated by GOALIE so goalie column = middle segment only, defensemen column = top+bottom. SEGMENT_GAP=18 (~1/3 playfield between defensemen). |
| Striped Forwards | PlayersStripedForwards.vhd | Done. J9(IC9602 ch2), K8(LS02), N7(IC9316), J8(LS04) → E3,B3,C3,D3. Same structure as solid (comparator, one-shot, differentiator, NOR, counter). |
| Striped Defense/Goalie | PlayersStripedDefenseGoalie.vhd | Done. H9(555), J8, J7(9316), F7(LS107), E8, L6, K6, J6 → E4,B4,C4,D4. Fixed: goalie/defensemen column swap via goalie_segment XNOR GOALIE gating; 555 timing constants tuned (INITIAL_GAP=83, SEGMENT_GAP=5, SEGMENT_LEN=29) to match solid defense vertical layout. |

See [docs/PLAYERS_CIRCUIT_FIG11.md](docs/PLAYERS_CIRCUIT_FIG11.md) for pin-level breakdown.

### Phase 5: Window/Bounce/Scoring

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Hit Circuit | PlayersSumming.vhd | Fig 17 | K6(LS08) gate 4 | Done. BALL AND PADDLES → HIT. Uses spare K6 gate 4 (pins 12,13,11) in PlayersSumming. Wired to CatchKick. |
| Moving Hole | - | Fig 18 | F3(LS02), M1(LS08), J1(LS00), E3(LS04), K1(LS74), H1(LS107), L4(IC9316), M4(IC9316) | Not yet implemented. 1-player mode only. |
| Window/Miss/Bounce | WindowMissBounce.vhd | Fig 19 | F5(LS08), F4(LS02), H5(LS02), E3(LS04) | Done. Window circuit (2P: V64→goal openings at V=128-191), bounce (V_BOUNCE, H_BOUNCE, BOUNCEn), miss (MISS=H_BOUNCE AND WINDOWS). Idle (BALLn='1'). WINDOWS→PlayfieldCircuit, H_BOUNCE→CatchKick. PlayfieldCircuit exports (A+B)n, (C+D)n for bounce inputs. |
| Score Circuit | - | Fig 21 | M2(LS48), M3(LS153), N3(LS153), K3(LS90), N2(LS107), J3(LS00), H2(LS00), K2(LS00), L2(LS00), J2(LS04), D3(LS08), L1(LS27), H3(LS02), N4(LS27), F3(LS02) | Not yet implemented. |
| Sound Circuit | SoundCircuit.vhd | Fig 20 | J9(IC9602), M9(IC9602), E5(IC9602), L8(LS00), E7(LS20) | Implemented and simulated. Pin-accurate 9602 mode, adjustable M9 timing estimates; board Audio1_O on pin 71. See docs/SOUND_CIRCUIT_FIG20.md. |

### Phase 6: Integration

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Video Summing | - | Fig 22 | Resistor network (R56, R63, R64, R65, C24) | Not yet implemented. Combines COMP_SYNC + SCORE + BALL + PADDLES. |
| Top-Level | atari_wcc.vhd | - | - | Simulation and Quartus top. Clock, sync, playfield (with goal openings via WindowMissBounce), ball (enabled, serve_proc delays 13ms), players (vertical window, ramp, mux, summing; Solid + Striped Forwards, Solid + Striped Defense/Goalie → PADDLES enabled), hit circuit (K6), window/miss/bounce (Fig 19), catch/kick/horiz dir (Fig 13), horiz dir & speed (Fig 15). |

---

## PCB IC Layout Grid

Reference for mapping ICs to PCB grid positions. See README.md for the full grid with links to VHDL files. M2 is 74LS48 (BCD-to-7-segment decoder), available in `74LS/LS48.vhd` and validated.

---

## Known Issues in Existing Files

| File | Issue |
|------|-------|
| `VerticalDirectionAndSpeed.vhd` | Done. Wired into top-level. D7 MRn polarity fixed (SERVEn=>serve_i). Compiles clean. |
| `HorizontalDirectionAndSpeed.vhd` | Done. Compiles clean, wired into top-level. Idle in sim (BALL='0'). No open issues. |
| `CatchKickHorizontalDirection.vhd` | Done. Wired into top-level. Idle in sim (BALL='0', HIT='0'). No open issues. |
| `PlayfieldCircuit.vhd` | Schematic-accurate as of last update. No open issues. |
| `PlayersSolidForwards.vhd` | Done (M9/K8/K7/J8). PULSE_WIDTH_CLKS=70 for vertical spacing. |
| `PlayersSolidDefenseGoalie.vhd` | Done; E1 gated by GOALIE for correct columns. VSYNCn reset added to 555 phase_count (POSITION=0 means comparator always '1', so reset path needs explicit VSYNC gate). |
| `PlayersStripedForwards.vhd` | Done. J9(9602 ch2), K8(LS02), N7(9316), J8(LS04) → E3,B3,C3,D3. |
| `PlayersStripedDefenseGoalie.vhd` | Done; goalie/defensemen column swap fixed; 555 timing tuned to match solid defense. VSYNCn reset added to 555 phase_count (same POSITION=0 issue as solid side). |
| `PlayersVerticalWindow.vhd` | Done; uniform spacing correction applied. No open issues. |
| `WindowMissBounce.vhd` | Done. Goal openings visible in sim. Bounce/miss idle (BALLn='1'). No open issues. |
| `tb_cross_top.vhd` | Removed. Simulation uses `tb_atari_wcc.vhd` with `atari_wcc.vhd` as top. |
| Players (Fig 11) | **All sub-circuits implemented and verified.** Horizontal columns symmetric (48px uniform spacing). Vertical defender spacing matches between solid and striped teams. |

---

## Timing Reference

| Parameter | Value |
|-----------|-------|
| Master clock | 14.318 MHz |
| Pixel clock (CLOCK_7) | 7.159 MHz |
| Clocks per scanline | 455 |
| Scanlines per frame | 313 (PAL) |
| Frame rate | 50.27 Hz |
| HSYNC pulse | 32 clocks |
| HBLANK period | 81 clocks |
| Active video per line | 374 clocks |
| H counter reset at | H454 (256+128+64+4+2) |
| V counter reset at | V312 (256+32+16+8) |

---

## Playfield Dimensions (Reference Coordinates)

```
0, 140 to 144,     404 to 408, 548
 ______________________________   0
|    ______________________    |
|   |  __________________  |   |  80 to 84
|   | |                  | |   |
|   |_|                  |_|   |  128
|                              |
|                              |  162
|    _                    _    |
|   | |                  | |   |  196
|   | |__________________| |   |
|   |______________________|   |  240 to 244
|______________________________|
                                  324
```

Goal openings in side walls between V=128 and V=196 (controlled by WINDOWS signal).

---

## How to Approach a New Circuit

1. **Read the manual section** for that circuit in [Goal_IV_TM-035.md](Goal_IV_TM-035.md)
2. **Study the schematic diagram** in [diagrams/](diagrams/) (e.g., `9_Playfield_Circuit.png` for Figure 9)
3. **If the schematic is unclear**, ask the human operator to clarify pin connections or signal names
4. **Identify all ICs** by their PCB grid position and type (cross-reference with the IC layout grid in README.md)
5. **Create the VHDL file** following the style conventions above
6. **Wire into the top-level** (`atari_wcc.vhd`)
7. **Update `sim/run_sim.sh`** to compile the new file
8. **Run simulation** and capture `frame_output.png`
9. **Document** what the circuit does and how it connects, in the file header and in `docs/` if complex
10. **Commit** the working change to git (locally)

---

## What NOT to Do

- Do not use behavioural `and`/`or`/`not`/`xor` for logic that has a documented IC on the schematic
- Do not use `components_pkg` or component declarations - always direct entity instantiation
- Do not commit broken or untested VHDL
- Do not push to remote without explicit permission
- Do not assume any existing VHDL file is correct without inspecting it
- Do not skip visual verification after changes that affect video output
- Do not add yourself as git co-author
