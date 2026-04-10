# Atari WCC (Goal IV) – Implementation Plan

This document is the single reference for **how to properly implement** the project: order of work, what to fix first, and how phases depend on each other. It aligns with AGENTS.md (TTL fidelity, manual as source of truth, incremental development, visual verification).

---

## Goal

Faithfully recreate the Goal IV (World Cup) arcade game as a VHDL FPGA core: every logic path traceable to TM-035 schematics, using explicit 74-series (and other) IC instantiations. Output drives a CRT via the same clock/video stack as MaSTer (14.31818 MHz from PLL, composite out).

---

## Principles

1. **TTL fidelity** – No behavioural shortcuts for schematic-documented gates; use `entity work.LSxx` (or other ICs) everywhere the manual specifies an IC.
2. **Manual + diagrams** – Goal_IV_TM-035.md and `diagrams/` are the source of truth. Unclear connections → ask.
3. **Incremental** – One circuit (or one fix) at a time; simulate and inspect frame output before moving on.
4. **Visual verification** – Any change that affects video: run `sim/run_sim.sh`, check `frame_output.png` (or GIF for animation).
5. **Sim then board** – Simulation stays the primary verification; board build (atari_wcc_board + PLL) follows once the core is correct.

---

## Phase 0: Foundation — DONE

- Computer Clock, Horizontal Sync, Vertical Sync, Sync Summing are verified.
- 455 clocks/line, 313 lines/frame, 50.27 Hz (PAL).
- Top-level: atari_wcc (sim) / atari_wcc_board (board with PLL + MaSTer video).

No action except to keep these as the base when adding or changing circuits.

---

## Phase 1: Static Video — FIX BEFORE ADDING MORE

**Objective:** Playfield (field outline, center line, goal openings) must be schematic-accurate and visually correct.

| Task | What | Priority |
|------|------|----------|
| 1.1 | **Review PlayfieldCircuit.vhd vs Fig 9** – Replace any behavioural position logic (e.g. `to_integer()` on H/V) with explicit ICs (M5, N5, N4, H6, J4, K4, C6 per schematic). | High |
| 1.2 | Verify WINDOWS → goal openings (V 128..196) in sim; confirm reference rect and frame_output.png match docs. | High |

After 1.1–1.2, playfield is the solid base for all later video (ball, players, score).

---

## Phase 2: Game Control Logic — REVIEW THEN TRUST

These blocks exist but are not yet verified against schematics. Review before relying on them for ball/game logic.

| Circuit | File | Action |
|---------|------|--------|
| Electronic Latch | ElectronicLatchCircuit.vhd | Review Fig 8; confirm transistor latch model is adequate. |
| Credit | CreditCircuit.vhd | Review against Fig 8; TTL-only. |
| Start | StartCircuit.vhd | Review against Fig 8. |
| Game Select | GameSelectCircuit.vhd | Review Fig 10. |
| Time Line | TimeLineCircuit.vhd | Review Fig 8; 555 model. |
| Serve Timing | ServeTimingCircuit.vhd | Review Fig 12; one-shot model. |

No strict order; can be done in parallel or as needed when wiring into the top-level. Each review: schematic → pin list → VHDL; add a short doc note or header comment if behaviour is non-obvious.

---

## Phase 3: Ball System — LARGELY COMPLETE

**Objective:** Ball position, motion, and visibility driven by schematic-accurate circuits; ball rendering re-enabled in atari_wcc once correct.

| Task | What | Status |
|------|------|--------|
| 3.1 | **VerticalDirectionAndSpeed.vhd** – Fig 14. Direct entity instantiation, fixed adder connections. | **DONE** |
| 3.2 | **HorizontalDirectionAndSpeed.vhd** – Fig 15 (B6 IC9316, B5 LS83, A6 LS08, A5 LS86). | **DONE** |
| 3.3 | **BallMotionCircuit.vhd** – Fig 16. Vertical counters A4+D4 (HSYNCn), horizontal B4+C4 (CLOCK_7 gated by HBLANKn), B3 phase FFs, BALL window decode. | **DONE** |
| 3.4 | **CatchKickHorizontalDirection.vhd** – Fig 13 (E4, D5, F7, E6, F6, E5 IC9602, D8). | **DONE** |
| 3.5 | **WindowMissBounce.vhd** – Fig 19 (F5, F4, H5, E3). BounceController.vhd removed. | **DONE** |

Ball is re-enabled in atari_wcc. `serve_proc` fires at ~13 ms to place ball near centre. Ball renders as a slight diagonal due to hardware-accurate 374-clock active line (not divisible by 8); this matches real hardware behaviour.

---

## Phase 4: Players — SUBSTANTIALLY COMPLETE

**Objective:** Fig 11 – ramp generation, vertical window, mux, pattern generation; all TTL/schematic-accurate.

| Sub-circuit | File | Status |
|-------------|------|--------|
| Vertical Window Generator | PlayersVerticalWindow.vhd | **DONE** |
| Ramp Generator | PlayersRampGenerator.vhd | **DONE** |
| Solid Forwards (left team) | PlayersSolidForwards.vhd | **DONE** |
| Solid Defense / Goalie | PlayersSolidDefenseGoalie.vhd | **DONE** – VSYNCn reset added to fix frame drift at POSITION=0 |
| Striped Forwards | PlayersStripedForwards.vhd | **DONE** |
| Striped Defense / Goalie | PlayersStripedDefenseGoalie.vhd | **DONE** – same VSYNCn reset fix applied |
| Multiplexer | PlayersMultiplexer.vhd | **DONE** |
| Player Summing | PlayersSumming.vhd | **DONE** |
| Check Pattern Generator | (in PlayersSumming) | **DONE** |
| One Player Solid Def. Defeat | (in PlayersSumming) | **DONE** |
| Control Switch | (inline in atari_wcc) | **DONE** |

All players wired in atari_wcc.vhd and visible in simulation.

---

## Phase 5: Window / Bounce / Scoring / Sound

**Objective:** Hit (Fig 17), Moving Hole (Fig 18), Window/Miss/Bounce (Fig 19), Score (Fig 21), Sound (Fig 20).

| Task | What |
|------|------|
| 5.1 | **Hit Circuit** – Fig 17 (K6 LS08); simple AND. |
| 5.2 | **Moving Hole** – Fig 18 (1-player); F3, M1, J1, E3, K1, H1, L4, M4. |
| 5.3 | **Window/Miss/Bounce** – Fig 19 (done as part of Phase 3.5). |
| 5.4 | **Score Circuit** – Fig 21 (M2 LS48, M3/N3 LS153, K3 LS90, N2 LS107, J3/H2/K2/L2 LS00, J2 LS04, D3 LS08, L1 LS27, H3/N4/F3). LS48 already in 74LS. |
| 5.5 | **Sound Circuit** – Fig 20 (J9, M9, E5 IC9602, L8 LS00, E7 LS27). |

Order: 5.1–5.3 support game behaviour; 5.4–5.5 can follow or run in parallel once blocks are ready.

---

## Phase 6: Integration

- **Video Summing** – Fig 22: combine COMP_SYNC, SCORE, BALL, PADDLES per schematic (resistor network; in RTL, produce the same combined logic levels).
- **Top-level** – atari_wcc (and atari_wcc_board) wire all blocks; ensure one source of truth for each signal (no duplicate logic).
- **Board** – Quartus: atari_wcc_board + Altera/clk_pll.vhd, MaSTer pinout and composite circuit (see docs/MASTER_CLOCK_AND_VIDEO_ADOPTION.md).

---

## Suggested Order of Work (Summary)

1. ~~**Playfield**~~ – **DONE** (Phase 1).
2. ~~**Ball system**~~ – **DONE** (Phase 3).
3. ~~**Players**~~ – **DONE** (Phase 4).
4. **Game control** – Review Phase 2 circuits (Electronic Latch, Credit, Start, Time Line, Serve Timing). Wire into top-level and verify behaviour.
5. **Hit, Moving Hole, Score, Sound** – Phase 5.
6. **Video summing and top-level integration** – Phase 6.
7. **Board build** – PLL + atari_wcc_board + MaSTer video/pinout.

---

## Docs and References

- **AGENTS.md** – Rules, style, 74LS library, known bugs, “How to Approach a New Circuit”.
- **Goal_IV_TM-035.md** – Manual text; **diagrams/** – Schematic figures.
- **docs/MASTER_CLOCK_AND_VIDEO_ADOPTION.md** – 14.31818 MHz PLL and CRT output.
- **docs/PLAYFIELD_REFERENCE_AND_FRAME_OUTPUT.md** – Coordinates and frame layout.
- **README.md** – PCB IC grid and project layout.

Keeping this plan updated (e.g. ticking off phases or tasks as done) will give a clear “what’s next” for the project.
