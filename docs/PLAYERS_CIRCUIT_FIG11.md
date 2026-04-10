# Players Circuit (Figure 11) – Breakdown and Implementation Plan

The Players Circuit (TM-035 Figure 11) is described in the manual as a collection of sub-circuits. This document breaks them down for schematic-accurate VHDL implementation. The manual section starts at **Goal_IV_TM-035.md § "Players Circuit"** and the schematic is **diagrams/11_Players_Circuit.png**.

---

## Overview: Sub-Circuits

| # | Sub-Circuit | Manual Section | Purpose |
|---|-------------|----------------|---------|
| 0 | **Vertical Window Generator** | First (before Ramp) | Generates TEAM, GOALIE, DEFENSEMEN, Q and vertical window timing (when each player type is active on screen). |
| 1 | **Ramp Generator** | § Ramp Generator | Analog ramp (256V, V ENABLE, pot R26); used by forwards/defensemen comparators for vertical position. |
| 2 | **Control Switch** | § Control Switch | Enables front-panel player pots in PLAY, disables in ATTRACT (Q7, D9-6, ATRC). |
| 3 | **Solid Forwards** | § Forwards Circuits | Pot → comparator N9-12 → one-shot M9 → NOR K8-1, counter K7, inverter J8-6 → **E2** and segment data. |
| 4 | **Solid Defense / Goalie** | § Defensemen/Goalie Circuits | Pot → comparator N9-10 → 555 N8-3 → inverters J8-2/4, counter M7, FFs H8, NAND L8-8, XOR E6-3, AND K6-8 → **E1**. |
| 5 | **Striped / Checked Forwards** | (same as Forwards, other side) | Same structure as Solid Forwards but different pot and one-shot (e.g. J9) → **E3**. |
| 6 | **Striped / Checked Defense** | (same as Defensemen, other side) | Same structure as Solid Defense but checked team → **E4**. |
| 7 | **Multiplexer** | § Multiplexer Circuit | L7 and H7 (74LS153). Select by TEAM and Q; route counter outputs (B1–B4, C1–C4) and player symbols (E1–E4). |
| 8 | **Check Pattern Generator** | § Check Pattern Generator | E6-6 (XOR), F6-6 (NAND). 1V and 1H → checked appearance for right team. |
| 9 | **One Player Solid Defensemen Defeat** | § One Player Solid… | J2-2, J1-6, M1-6. In 1-player mode, suppress solid defensemen symbol. |
|10 | **Player Summing** | § Player Summing Circuit | K6-6 (AND). Player symbol + check pattern → **PADDLES** to hit circuit and video. |

Below we detail **your 7** (Ramp, Control Switch, Solid Forwards, Solid Defense, Striped Forwards, Striped Defense, Multiplexer) plus **Vertical Window** and **Check Pattern** so the full chain is clear.

---

## 1. Vertical Window Generator

**Purpose:** Decides *when* during each scanline each player (goalie, defensemen, forwards) is in the “vertical window” and which team (TEAM) and state (GOALIE, DEFENSEMEN, Q).

**Components (manual):**
- NAND: F6-3, H6-12, H6-6
- Negative-true AND: J6-6
- XOR: L6-6, L6-3, L6-8
- Flip-flop: D6-8
- Waveform generator: **M6** – “specially wired counter” driven by **8H**, reset by **H RESET**. Produces four waveforms **A, B, C, D** per line.

**Signals produced:**
- **TEAM** – to kick circuit, check pattern, multiplexer, F6-3
- **GOALIE** – to defensemen circuits
- **DEFENSEMEN** – to kick circuit and one-player defensemen defeat
- **Q** – to multiplexer and F6-3

**Behaviour (short):**
- When H ENABLE and V ENABLE go high, H6-12 goes low. When B and C from M6 are low at that time, J6-6 goes high. That is NANDed with 4H and 8H to form vertical window for goalies, defensemen, forwards.
- Left team windows start at 152H (goalie), 200H (defensemen), 296H (forwards); right team at 392H, 344H, 248H. Each window 4H wide.
- 1 PLAYER mode: when TEAM high, F6-3 low → H6-6 inhibited → only right team’s forwards/defensemen/goalie windows suppressed.

**PCB (README):** F6=LS00, H6=LS10, J6=LS27, L6=LS86, D6=LS74. M6 is described as a counter (8H clock, H RESET); part number must be confirmed from schematic (e.g. 9316 or divider).

---

## 2. Ramp Generator

**Purpose:** Sawtooth ramp for vertical positioning; comparators in forwards/defensemen compare pot voltage to this ramp.

**Components:** Transistor Q6, 256V, “V ENABLE * !128V”, potentiometer R26 (RAMP ADJ), C8, R23, etc.

**Behaviour:** When (V ENABLE and !128V) is low, C8 charges via R26/R23 → ramp up. When 256V goes high, Q6 turns on, discharges C8 → ramp ends. R26 sets ramp scope (goalie symmetry).

**FPGA note:** **Done.** `PlayersRampGenerator.vhd`: digital ramp (LS00 for charge enable; 10-bit counter; RAMP_VALUE for comparators). Wired in atari_wcc. Original analog: free-running counter or phase accumulator driven by pixel/V clock, reset when 256V (or equivalent) goes high; “position” = count or scaled value for comparator threshold.

---

## 3. Control Switch

**Purpose:** Enable (PLAY) or disable (ATTRACT) front-panel player-position controls.

**Components:** Transistor Q7, inverter **D9-6**, diode CR7. **ATRC** = attract (low in attract, high in play).

**Behaviour:** Play: ATRC high → D9-6 low → Q7 on, CR7 forward-biased → controls enabled. Attract: ATRC low → D9-6 high → Q7 off → controls inoperable.

**FPGA note:** Purely control logic. “Controls enabled” can be a digital signal derived from ATRC (e.g. use pot/position inputs only when ATRC high).

---

## 4. Solid Forwards (left team)

**Purpose:** Position solid forwards on screen and provide segment data (D2, C2, B2) to vertical speed circuit. Output **E2** (top solid forward symbol) and later bottom solid forward.

**Components (manual):**
- Comparator **N9-12** (op-amp – not in 74LS; model as threshold compare).
- One-shot **M9-10/9** (IC9602).
- **NOR K8-1** (74LS02).
- Counter **K7** (manual: “counter K7”; schematic may show 9316 – confirm on diagram).
- Inverter **J8-6** (LS04).
- Differentiators R39–C21, R40–C22 (edge detection from one-shot).

**Flow:**
- Ramp vs solid FORWARDS pot at N9-12 → when equal, N9-12 high → triggers M9.
- M9 produces +ve and −ve pulses → differentiated → NOR K8-1 low → presets K7 to 0. When spikes decay, K8-1 high → K7 counts **H SYNC**.
- At 15, K7 pin 15 high → J8-6 low → K7 stops (pin 7). While counting, J8-6 high = **E2** (to multiplexer). D2, C2, B2 from K7 to vertical speed.
- Trailing edge of M9 → K8-1 low again → K7 re-initialized → then counts again for *bottom* solid forward. R41 adjusts M9 pulse width (spacing between top and bottom).

**PCB:** M9=9602, K8=LS02, J8=LS04. K7: README grid says K7=153 (mux); manual says counter – need schematic to confirm (often 9316 for this role).

---

## 5. Solid Defense / Goalie (left team)

**Purpose:** Position solid defensemen and goalie; output **E1** and segment data D1, C1, B1.

**Components:**
- Comparator **N9-10** (op-amp).
- Stable multivibrator **N8-3** (555).
- Inverters **J8-2**, **J8-4** (LS04).
- Counter **M7** (9316 per README).
- Flip-flops **H8-3/2**, **H8-5/6** (LS107).
- **NAND L8-8** (LS00 or LS27 – check schematic).
- **XOR E6-3** (LS86).
- **AND K6-8** (LS08).
- Negative-true AND **J6-8** (e.g. LS27 or gate in J6).

**Flow (condensed):**
- Ramp = DEFENSEMEN pot at N9-10 → N9-10 high → enables 555 N8-3.
- N8 pin 3 high → J8-2 low → M7 preset to 0, L8-8 inhibited. N8 pin 3 low → M7 counts H SYNC, L8-8 low → E6-3 and K6-8 high → **E1**.
- At 15, M7 pin 15 high → J8-4 low → M7 stop, clock H8-3/2 and H8-5/6. H8-3 Q high, L8-8 high → J6-8 low (end of top defenseman). Then goalie phase; then bottom defenseman. **GOALIE** = high during goalie symbol, low during defensemen.

**PCB:** N8=555, M7=9316, H8=LS107, J8=9316 (row 7 – J8 is 9316), L8=LS00, E6=LS86, K6=LS08, J6=LS27.

---

## 6. Striped / Checked Forwards

Same as Solid Forwards but:
- Input: “5K STRIPED FORWARDS” pot.
- One-shot likely **J9** (9602) instead of M9.
- Counter may be shared or separate (schematic will show).
- Output: **E3**.

---

## 7. Striped / Checked Defense

Same as Solid Defense/Goalie but for checked team:
- Input: “5K STRIPED DEFENSE MEN” pot.
- Output: **E4**.

---

## 8. Multiplexer Circuit

**Done.** `PlayersMultiplexer.vhd`: L7 and H7 (LS153). Select S1=TEAM, S0=Qn (D6 pin 8). L7: B1–B4→PP2, C1–C4→PP3. H7: D1–D4→PP4, E1–E4→SYMBOL (to M1 pin 5); H7 pin 15=PLAYER_WINDOWn (enable when low). Wired in atari_wcc; B1–E4 tied to 0 until forwards/defensemen exist.

**Purpose:** Route the correct counter outputs (B1–B4, C1–C4) to vertical speed and the correct player symbol (E1–E4) to the one-player defeat and summing, based on who is on screen.

**Components:** **L7** and **H7** (74LS153 dual 4:1 mux).

**Inputs (manual):**
- **L7:** B1, B2, B3, B4, C1, C2, C3, C4 (from defensemen/goalie and forwards counters).
- **H7:** D1, D2, D3, D4 from counters and player symbols **E1, E2, E3, E4**.
- **Select:** TEAM and **Q** from vertical window generator.

**Outputs:** L7 and H7 outputs feed “C4-2 ONE PLAYER” and vertical speed; with player vertical window, TEAM and Q place each player at the right position on screen.

**PCB:** L7=LS153, H7=LS153 (README).

---

## 9. Check Pattern Generator

**Components:** **E6-6** (XOR), **F6-6** (NAND). Inputs: **1V**, **1H**; TEAM.

**Behaviour:** XOR(1V, 1H) then NAND with TEAM. TEAM inhibits for left team, enables for right team so right team’s players get a 1H-rate check pattern (alternate lines on/off).

---

## 10. One Player Solid Defensemen Defeat

**Components:** Inverter **J2-2**, negative-true OR **J1-6**, AND **M1-6**. Inputs: ONE PLAYER, DEFENSEMEN, solid defensemen symbol (from mux/summing path).

**Behaviour:** 1-player + defensemen window → J1-6 low → M1-6 inhibits solid defensemen symbol. 2-player → J1-6 high → M1-6 passes symbol.

---

## 11. Player Summing Circuit

**Done.** `PlayersSumming.vhd`: E6 (XOR H1,V1), F6 (NAND TEAM, E6_out), J2 (inv DEFENSEMENn), J1 (NAND for one-player defeat), M1 (AND J1_out, SYMBOL), K6 (AND M1_out, check) -> **PADDLES**. Wired in atari_wcc; PADDLES available for hit circuit and video summing.

**Components:** AND **K6-6**. Inputs: player symbol signal (from mux) and check pattern. Output: **PADDLES** to hit circuit and video summing.

---

## Implementation Order (Suggested)

1. **Vertical Window Generator** – **DONE.** `PlayersVerticalWindow.vhd`: M6 (LS93 on 8H, H RESET), D6 (LS74), F6 (LS00), H6 (LS10), J6 (LS27), L6 (LS86); LS08 for 8H = (H1 and H2 and H4); LS04 for D6 clock invert and window NAND. Produces TEAM, GOALIE, DEFENSEMEN, Q and PLAYER_WINDOWn. Wired in `atari_wcc.vhd`; H_ENABLE/V_ENABLE from PlayfieldCircuit.
2. **Ramp Generator** – Digital ramp (counter/phase) driven by V timing, reset by 256V; output “ramp” value for comparators.
3. **Control Switch** – Logic only (ATRC → controls_enabled).
4. **Solid Forwards** – M9 (9602), K8 (NOR), K7 (counter – verify 9316 on schematic), J8 (inverter). Produces E2 and B2,C2,D2.
5. **Solid Defense/Goalie** – N8 (555), M7 (9316), H8 (LS107), J8, L8, E6, K6, J6. Produces E1 and B1,C1,D1, GOALIE.
6. **Striped Forwards** – Same as (4) with J9 and E3.
7. **Striped Defense** – Same as (5) with E4.
8. **Multiplexer** – L7, H7 (LS153); select = f(TEAM, Q); data = B1–C4 and D1–D4, E1–E4.
9. **Check Pattern** – E6-6, F6-6.
10. **One Player Defeat** – J2, J1, M1.
11. **Player Summing** – K6-6 → PADDLES.

---

## Schematic Checks Needed

- **M6:** Exact part (counter type) and pinout (8H, H RESET, A/B/C/D outputs).
- **K7:** 9316 vs 153 on schematic (manual says counter K7).
- **L7/H7:** Exact select mapping (which bit = TEAM, which = Q) and data pin order (B1–B4, C1–C4, D1–D4, E1–E4).
- **N9, N8:** N9 is UA747 op-amp (not implemented); N8 is 555. Comparators N9-12 and N9-10 must be replaced by digital threshold (ramp > threshold) in FPGA.
- Pot inputs: For simulation, use fixed or register-driven “position” values instead of real potentiometers.

---

## File Naming

- Single top-level: `PlayersCircuit.vhd` (entity `PlayersCircuit`) that instantiates sub-blocks.
- Optionally one file per sub-circuit (e.g. `PlayersVerticalWindow.vhd`, `PlayersRampGenerator.vhd`, …) and instantiate all in `PlayersCircuit.vhd`.

Once the schematic is fully traced for one chain (e.g. Solid Forwards), the same pattern applies to Striped Forwards and to Defense/Goalie pairs.
