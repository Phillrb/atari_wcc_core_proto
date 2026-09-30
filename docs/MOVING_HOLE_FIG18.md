# Moving hole — TM-035 Figure 18

`MovingHoleCircuit.vhd` implements the confirmed Figure 18 wiring using explicit
IC instances. `HOLE` is active high and feeds Figure 19's existing input; E3's
inverted output feeds F3 internally. `STARTn` asynchronously clears L4, M4 and
H1, but does not reset K1's direction latch.

| Device | Connections used |
| --- | --- |
| F3, 7402 gate 1 | Pins 2/3 = `(C+D)n` / `HOLEn`; pin 1 clocks K1 pin 11 |
| K1, 7474 FF2 | D pin 12 = V128; preset/clear high; Q pin 9 feeds L4 pin 4 |
| L4, 9316 | Clock = HSYNCn; A/B/C/D = 1/K1-Q/0/1; both enables high |
| M4, 9316 | Same clock; A/B/C/D = 0/0/1/1; CEP = L4 TC, CET high |
| H1, 74107 FF1 | Clock pin 12 = L4 TC; J/K pins 1/4 = M4 TC; clear = STARTn |
| M1, 7408 gate 4 | Pins 12/13 = H1 Q / M4 TC; pin 11 = HOLE |
| J1, 7400 gate 1 | Pins 1/2 = L4 TC / HOLE; pin 3 loads both counters |
| E3, 7404 gate 2 | Pins 3/4 = HOLE / HOLEn |

Unused pins are explicitly tied off. The existing starter's F5 label, duplicate
K1 instance and top-level `startn_i` typo have been corrected. GHDL and Quartus
source lists both include the new circuit.

## Original 74107 model

H1 selects `LS107(MASTER_SLAVE => true)`. The optional mode holds the J/K data
from the high-clock interval before the inverted slave clock advances. This
prevents simultaneous zero-delay counter carry transitions from making H1
sample the next count's enable. Both halves implement asynchronous clear.

TI distinguishes the original pulse-triggered 74107 from the negative-edge
triggered LS107A: [TI SN54107/SN74107 documentation](https://www.ti.com/product/SN54107).
The user approved this mode for H1. The existing default model is unchanged for
all seven other circuit files using LS107. This is a functional model, not an
analog propagation-delay or metastability simulation; FPGA timing remains a
separate board-validation task.

## Confirmed schematic/prose discrepancy

The user confirmed the visible L4 preset wiring: pins 3 and 6 high, pin 5 low,
pin 4 driven by K1 Q. That gives presets **9 and 11**, not the contradictory
9/6/8 values in the prose. The implementation preserves these connections.

After reset, the first HOLE starts at HSYNCn rising edge 496 and ends at edge
512. Each subsequent pulse lasts **16 scanlines**. Loading M4:L4 with `C9` or
`CB` gives an interval of `512 - (192 + preset)` between successive HOLE rising
edges: **311 or 309 lines**, respectively. The reload edge is already included
in that count. Tests force each K1 state and assert these intervals.

With this project's **313-line raster**, these periods move the opening upward
by two or four lines per frame. Boundary sampling changes the speed; it does
**not** reverse motion. The manual's description of bounded up/down movement is
therefore **not reproduced by the confirmed netlist**. No alternate presets,
counter changes or timing corrections have been invented to conceal this.
Further source clarification is needed before changing the wiring to reproduce
that description. The long diagnostic explicitly includes wraparound.

## Running verification

```bash
bash sim/run_moving_hole_tests.sh
cd sim
bash run_sim.sh                 # Existing default two-player mode
ONE_PLAYER=1 bash run_sim.sh    # Exercise the moving opening in the full core
```

`ONE_PLAYER_MODE` is a static top-level generic (default `'0'`), passed to all
five gameplay mode inputs. It provides a way to exercise Figure 18 without
claiming that the Figure 10 game-select circuit has been integrated. Credit
configuration remains the existing one-game-per-coin selection.

The focused suite checks the 9316, 7474, both 107 variants, asynchronous reset,
16-line width, both presets, direction retention across reset, boundary gating,
Figure 19 polarity/mode selection and 400 PAL fields. The old LS74/LS107 tests
now use direct entity instantiation so GHDL actually connects their DUTs.

Generated artifacts (ignored by git):

- `sim/moving_hole_timing.png`: measured HOLE versus field and scanline.
- `sim/moving_hole.gif`: animated signal diagnostic over 400 fields.
- `sim/moving_hole_core.png` and `sim/moving_hole_core.gif`: retained full-core
  one-player video from `ONE_PLAYER=1 bash run_sim.sh`.
- `sim/frame_output.png` and `sim/gameplay.gif`: actual full-core video from the
  most recent `run_sim.sh` invocation.

The signal diagnostic is labelled separately from the full-core video. It
renders the actual testbench samples, including the unresolved motion behavior.

For remaining gameplay corrections and source questions, see [one-player handoff](ONE_PLAYER_HANDOFF.md).
