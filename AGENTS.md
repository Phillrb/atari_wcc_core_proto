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
  IC/                 # Other IC models (IC9316, IC9314, IC9602, dff, jkff)
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

### Automated build and verification

Use `./scripts/build_and_test.py` for routine builds and verification; see
[docs/BUILD_AND_TEST.md](docs/BUILD_AND_TEST.md). It snapshots current sources,
builds, runs routing/timing guards and regressions, and writes `summary.txt` and
`report.json` in its printed run directory. Wait for that run rather than
reissuing individual commands or repeatedly dumping logs. Inspect its PNG and
GIF/contact sheet after `AUTOMATED_PASS`; visual review remains mandatory.
`--quick` has explicitly reduced coverage. When programming is requested, pass
the exact POF from the successful run to `scripts/program_as.py`.

### Running a Simulation
```bash
cd sim && bash run_sim.sh
```
This compiles all VHDL (74LS library, IC library, design files, testbench), runs GHDL for the configured duration, and calls `visualize.py` to produce `frame_output.png`.

### Run behaviour
The default capture is 650 ms, with testbench-driven coin/start and accelerated timer/serve generics. Override with `STOP_MS=900` (or similar); the safety limits remain 500 frames / 60 s. The visualizer produces `frame_output.png` (requires Pillow) and `gameplay.gif` (animated, all complete frames) when >2 frames are present.

### Output Files
| File | Purpose |
|------|---------|
| `sim/frame_data.txt` | Raw samples: `HSYNC VSYNC HBLANK VIDEO` at 7.142857 MHz |
| `sim/frame_output.png` | Paid-play frame (index 20, 2x scale, green phosphor) |
| `sim/gameplay.gif` | Animated GIF of all complete frames (1x scale, 100 ms/frame) |
| `sim/frame_output.ppm` | Written only when `--ppm` flag is passed to visualize.py |

### Current sim output (limitations)
Ball rendering is enabled. The board now boots into attract and uses Figure 8 coin/start control and Figure 12 serve timing. Coin1_I (pin 120) and Start1_I (pin 112) are active-low NO inputs with pull-ups and 5 ms debounce. Board games last two minutes, with three-second serve/catch timing; simulation supplies coin/start and accelerates these to 300 ms / 50 ms. See [docs/JAMMA_GAME_CONTROL.md](docs/JAMMA_GAME_CONTROL.md). The custom 13 ms serve process has been removed.

**Ball shape and STOP drift have been repaired.** The older claim that diagonal skew is unavoidable was superseded by measured counter timing and fitted hazards. The current implementation uses approved horizontal/vertical preset adaptations, registered A4/C4 carries and shared clock routing. See [horizontal STOP evidence](docs/CATCH_STOP_DIAGNOSIS.md) and [vertical fitted verification](docs/VERTICAL_BALL_TIMING.md). Do not reintroduce the old skew explanation as an implementation requirement.

### Board build (MaSTer clock and video)
For a real CRT, use the same clock and video stack as the **MaSTer** projects: 50 MHz board clock → PLL → **14.285714 MHz** (2/7 ratio; original nominal clock 14.318180 MHz), and MaSTer-style composite output (Sync + Video resistors). See [docs/MASTER_CLOCK_AND_VIDEO_ADOPTION.md](docs/MASTER_CLOCK_AND_VIDEO_ADOPTION.md). Use **atari_wcc_board** as the Quartus top and **Altera/clk_pll.vhd** for the PLL.

### Adding New Circuits to Simulation
1. Add `ghdl -a --std=93 "$ROOT/YourCircuit.vhd"` to `sim/run_sim.sh`
2. Instantiate in `atari_wcc.vhd` (the simulated core; Quartus uses the `atari_wcc_board` wrapper)
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

The IC library is exercised by circuit regressions and individual tests. Some older standalone testbenches still use component instantiation and are not included in current runners; auditing them is recorded in [the work queue](docs/IMPLEMENTATION_PLAN.md).

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
- Inspect each model and its actual test coverage before using it in a new path; existing circuit tests do not prove every IC mode.
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

**One-player mode is complete:** project-owner confirmation, 26 October 2026. Remaining timing and fidelity audits do not mean the mode is functionally unfinished. See [verification record](docs/VERIFICATION_STATUS.md).

**Current priorities and verification:** [work queue](docs/IMPLEMENTATION_PLAN.md) and [verification record](docs/VERIFICATION_STATUS.md). Acceleration and the credit lamp are implemented; latest-image hardware confirmation and timing coverage remain incomplete. See docs/HIT_ACCELERATION.md and docs/CREDIT_LED.md. The audible diagnostic image has owner-confirmed catching/kicking; the underlying build-sensitive fault remains unresolved.

The Goal IV game consists of the following integrated circuit groups. Each references a figure from TM-035 and has a schematic diagram in `diagrams/`.

### Phase 0: Foundation (DONE)
These are verified and working:

| Circuit | File | Figure | Status |
|---------|------|--------|--------|
| Computer Clock | ComputerClock.vhd | Fig 3 | Verified |
| Horizontal Sync | HorizontalSync.vhd | Fig 4 | Verified |
| Vertical Sync | VerticalSync.vhd | Fig 5 | Verified |
| Sync Summing | SyncSumming.vhd | Fig 6 | Verified |

Timing: 455 clocks/scanline, 313 lines/frame, approximately 50.16 Hz with the current board PLL (PAL-like raster).

### Phase 1: Static Video (DONE – schematic-accurate)

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Playfield | PlayfieldCircuit.vhd | Fig 9 | M5(LS86), N5(LS00), N4(LS27), H4(LS02), H6(LS10), J4(LS20), K4(LS107), C6(LS04) | Schematic-accurate: all logic via TTL. K4 is single LS107 (FF1=V, FF2=H). (A+B)n from H6 pin 8; (C+D)n via J4 gate 2; H4=LS02 NOR(V4,V8)→J4. Verified in sim. |

### Phase 2: Game Control Logic (INTEGRATED; ANALOG MODEL LIMITATIONS)

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Electronic Latch | ElectronicLatchCircuit.vhd | Fig 8 | A8(LS04), transistors Q1-Q3 | Integrated and tested; transistor latch remains a digital abstraction, with coin drive priority and power-on attract. |
| Credit | CreditCircuit.vhd | Fig 8 | A8(LS04), B8(LS74), C8(LS00), C9(LS02), A9(LS74) | Integrated and tested. B8 ripple wiring, C9 type and A9 clocks/preset corrected; board selects one game per coin. |
| Start | StartCircuit.vhd | Fig 8 | A8(LS04), C9(LS02), B9(LS74) | Integrated and tested. JAMMA adapter supplies settled switch state; C9/B9 control start and attract. |
| Game Select | GameSelectCircuit.vhd | Fig 10 | D9 contact latch (board adapter), C5(LS08) | Active-low GameSelect_I, synchronized/debounced; C5 gates selection with ATRCn. Runtime selector tested. |
| Time Line | TimeLineCircuit.vhd | Fig 8 | A2(LS10), N4(LS27), K1(LS74), D9(LS04), E9(555), J2(LS04) | Integrated with two-minute digital RC/555 timing and tested expiry/rearm. Existing timer window approximation remains; not fully pin-accurate. |
| Serve Timing | ServeTimingCircuit.vhd | Fig 12 | J5(9602), L5(LS74), H4(LS02) | Integrated and tested with pin-accurate IC9602 triggers and three-second board serve/catch delays. |

### Phase 3: Ball System (INTEGRATED; LATEST HARDWARE VERIFICATION OPEN)

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Vertical Direction & Speed | VerticalDirectionAndSpeed.vhd | Fig 14 | D7(9314), D6(LS74), C7(LS86), B7(LS02), F6(LS00), C6(LS04), A7(LS83) | Done. Wired into top-level. D7 MRn polarity fixed: `SERVEn=>serve_i`. A7 includes the approved 313-line speed/STOP adaptation; see docs/VERTICAL_BALL_313_LINE_ADAPTATION.md. |
| Horizontal Direction & Speed | HorizontalDirectionAndSpeed.vhd | Fig 15 | B6(IC9316), B5(LS83), A6(LS08), A5(LS86), B7(LS02), F6(LS00), C6(LS04), F5(LS08) | Integrated. Horizontal STOP preset 9 is an approved raster adaptation. D8 pin 9 now drives GOALIE_FWD_HIT; Figure 15 decoder wiring is corrected. Acceleration RTL and B6 local timing checks pass; hardware confirmation remains pending. |
| Ball Motion | BallMotionCircuit.vhd | Fig 16 | A4(IC9316), D4(IC9316), B4(IC9316), C4(IC9316), B3(LS107), A3(LS10)+A2(LS10 label for A3 gate 1), D3(LS08), C3(LS00), E3(LS04) | Integrated and tested. Figure 12 controls serve; A4/C4 registered carries and shared global routing address fitted hazards. Approved motion presets match the current raster. See docs/VERTICAL_BALL_TIMING.md. |
| Catch/Kick/Horizontal Direction | CatchKickHorizontalDirection.vhd | Fig 13 | E8(LS00), C8(LS00), D8(LS74), D5(LS74), C5(LS08), C9(LS02), K8(LS02), A8(LS04), D9(LS04) | Integrated. J5 ch1 STOP/STOPn via ServeTimingCircuit; sampled collisions, kick and timeout regressions pass. See docs/REAR_CATCH_TIMEOUT.md. |

### Phase 4: Players (Solid + Striped Forwards, Defense, Goalie – Fig 11)

| Sub-circuit | File | Status |
|-------------|------|--------|
| Vertical Window Generator | PlayersVerticalWindow.vhd | Done. M6(LS92), D6(LS74), F6, H6(LS10), J6(LS27), L6(LS86). TEAM, GOALIE, DEFENSEMENn, Q, Qn, BLIP, PLAYER_WINDOWn. Uniform spacing correction: J6 NOR inputs changed from (Q2,Q1) to (Q1 XOR Q2, Q3) for symmetric 48px column gaps; L6 gates 2&3 changed from Q3 to Q2 for correct TEAM/DEFENSEMENn. Adapted BLIP is guarded with H8 to prevent catch retriggering; this layout remains a fidelity-audit item. |
| Ramp Generator | PlayersRampGenerator.vhd | Done. Digital ramp; LS00 charge enable; RAMP_VALUE(9:0) for comparators. |
| Multiplexer | PlayersMultiplexer.vhd | Done. L7, H7(LS153). Select TEAM, Qn; B1–E4 → PP2, PP3, PP4, SYMBOL. |
| Check Pattern / One-Player Defeat / Player Summing | PlayersSumming.vhd | Done. E6(XOR H1,V1), F6(NAND TEAM), J2, J1, M1(LS08), K6(LS08) → **PADDLES**. |
| Solid Forwards | PlayersSolidForwards.vhd | Done. Comparator, clock-driven M9(IC9602) PULSE_WIDTH_CLKS=66, K8(LS02), K7(IC9316), J8(LS04) → E2,B2,C2,D2. See SPI travel regression for measured positions. |
| Solid Defense/Goalie | PlayersSolidDefenseGoalie.vhd | Done. 555 model, M7(9316), H8(LS107), E6/K6/J6/L8/J8 → E1,B1,C1,D1. E1 gated by GOALIE so goalie column = middle segment only, defensemen column = top+bottom. SEGMENT_GAP=18 (~1/3 playfield between defensemen). |
| Striped Forwards | PlayersStripedForwards.vhd | Done. J9(IC9602 ch2), K8(LS02), N7(IC9316), J8(LS04) → E3,B3,C3,D3. Same structure as solid (comparator, one-shot, differentiator, NOR, counter). |
| Striped Defense/Goalie | PlayersStripedDefenseGoalie.vhd | Done. H9(555), J8, J7(9316), F7(LS107), E8, L6, K6, J6 → E4,B4,C4,D4. Fixed: goalie/defensemen column swap via goalie_segment XNOR GOALIE gating; 555 timing constants tuned (INITIAL_GAP=83, SEGMENT_GAP=5, SEGMENT_LEN=29) to match solid defense vertical layout. |

See [docs/PLAYERS_CIRCUIT_FIG11.md](docs/PLAYERS_CIRCUIT_FIG11.md) for pin-level breakdown.

### Phase 5: Window/Bounce/Scoring

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Hit Circuit | PlayersSumming.vhd | Fig 17 | K6(LS08) gate 4 | Done. BALL AND PADDLES → HIT. Uses spare K6 gate 4 (pins 12,13,11) in PlayersSumming. Wired to CatchKick. |
| Moving Hole | MovingHoleCircuit.vhd | Fig 18 | F3(LS02), M1(LS08), J1(LS00), E3(LS04), K1(LS74), H1(LS107 original mode), L4(IC9316), M4(IC9316) | Owner-approved 313-line adaptation (22 October 2026): 6/8 presets and top-level LS74 boundary sampling. Repeated reversals and 16-line width verified in RTL; FPGA timing remains unverified. See docs/MOVING_HOLE_FIG18.md. |
| Window/Miss/Bounce | WindowMissBounce.vhd | Fig 19 | F5(LS08), F4(LS02), H5(LS02), E3(LS04) | Done. Window circuit (2P: V64→goal openings at V=128-191), bounce (V_BOUNCE, H_BOUNCE, BOUNCEn), miss (MISS=H_BOUNCE AND WINDOWS). Active in gameplay. WINDOWS→PlayfieldCircuit, H_BOUNCE→CatchKick. PlayfieldCircuit exports (A+B)n, (C+D)n for bounce inputs. |
| Score Circuit | ScoreCircuit.vhd | Fig 21 | M2(LS48), M3/N3(LS153), K3/L3(LS90), N2(LS107), J3(LS00), F2(LS86), H2/K2/L2(LS10), J2/E3(LS04), D3(LS08), L1(LS30), H3/N4(LS27), H5/F3(LS02) | Implemented and integrated. RTL and fitted timing regressions pass; Q0 global clock routing corrects the 9-to-12 rollover fault. Project owner confirmed goal counting works properly on FPGA on 18 October 2026. See [score verification](docs/SCORE_ROLLOVER_TIMING.md). |
| Sound Circuit | SoundCircuit.vhd | Fig 20 | J9(IC9602), M9(IC9602), E5(IC9602), L8(LS00), E7(LS20) | Implemented and simulated. Pin-accurate 9602 mode, adjustable M9 timing estimates; board Audio1_O on pin 71. See docs/SOUND_CIRCUIT_FIG20.md. |

### Phase 6: Integration

| Circuit | File | Figure | ICs | Status |
|---------|------|--------|-----|--------|
| Video Summing | - | Fig 22 | Resistor network (R56, R63, R64, R65, C24) | MaSTer/Sprint2 board composite output is implemented. Exact recreation of the original Figure 22 resistor network remains fidelity work. |
| Top-Level | atari_wcc.vhd | - | - | Simulated core under the atari_wcc_board Quartus wrapper. Clock, sync, playfield (with goal openings via WindowMissBounce), ball (enabled, Figure 8 coin/start/attract and Figure 12 serve timing), players (vertical window, ramp, mux, summing; Solid + Striped Forwards, Solid + Striped Defense/Goalie → PADDLES enabled), hit circuit (K6), window/miss/bounce (Fig 19), catch/kick/horiz dir (Fig 13), horiz dir & speed (Fig 15). |

---

## PCB IC Layout Grid

Reference for mapping ICs to PCB grid positions. See README.md for the full grid with links to VHDL files. M2 is 74LS48 (BCD-to-7-segment decoder), available in `74LS/LS48.vhd` and validated.

---

## Open Issues and Model Boundaries

The [work queue](docs/IMPLEMENTATION_PLAN.md) is the authoritative task list.

| Area | Current limitation |
|------|--------------------|
| `atari_wcc.vhd` / Figure 15 | Acceleration is implemented and tested; confirm progressive rally speed and goal reset on the latest image. |
| FPGA timing | Ball/score/speed local timing checks pass; event-clock, crossing and I/O coverage remains incomplete. The 32-unconstrained-clock count belongs to the 22 October baseline. |
| Catch/kick | Diagnostic LED connection changed physical behavior across fits; root cause unresolved. Retain the confirmed diagnostic connection while investigating. |
| Figure 18 | Repeated reversals pass RTL; specific fitted timing and commit/hash-linked hardware sweep evidence remain open. |
| Figure 11 | Uniform spacing and BLIP guards are FPGA adaptations. Analog ramp/555 timing and layout fidelity need calibration/audit. |
| Figures 8/20/22 | Digital analog models, sound duration estimates and substitute composite resistor network remain documented fidelity boundaries. |
| Older IC tests | Some use component instantiation and are absent from runners; audit before relying on their coverage. |

---

## Timing Reference

| Parameter | Value |
|-----------|-------|
| Master clock | 14.285714 MHz board/sim; original nominal 14.318180 MHz |
| Pixel clock (CLOCK_7) | 7.142857 MHz board/sim |
| Clocks per scanline | 455 |
| Scanlines per frame | 313 (PAL) |
| Frame rate | Approximately 50.16 Hz at the board clock |
| HSYNC pulse | 32 clocks |
| Ball counter enabled edges per line | 375 (measured CLOCK_7 rising edges with HBLANKn high; see STOP diagnosis) |
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
