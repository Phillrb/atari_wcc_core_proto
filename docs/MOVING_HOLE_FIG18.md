# Moving hole — TM-035 Figure 18

`MovingHoleCircuit.vhd` uses explicit IC instances with the owner-approved
313-line adaptation of 22 October 2026: L4 presets 6/8 and settled boundary
sampling in the top level. These are documented deviations from Figure 18.
`HOLE` is active high and feeds Figure 19's existing input; E3's
inverted output feeds F3 internally. `STARTn` asynchronously clears L4, M4 and
H1, but does not reset K1's direction latch.

| Device | Connections used |
| --- | --- |
| F3, 7402 gate 1 | Pins 2/3 = `(C+D)n` / `HOLEn`; pin 1 clocks K1 pin 11 |
| K1, 7474 FF2 | D pin 12 = V128; preset/clear high; Q pin 9 feeds L4 pin 6; Qn pin 8 feeds L4 pins 4/5 |
| L4, 9316 | Clock = HSYNCn; A/B/C/D = 0/K1-Qn/K1-Qn/K1-Q; both enables high |
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

## Source discrepancy and approved adaptation

The user confirmed the visible L4 preset wiring: pins 3 and 6 high, pin 5 low,
pin 4 driven by K1 Q. That gives presets **9 and 11**, not the contradictory
9/6/8 values in the prose. The original implementation preserved those
connections, but both resulting periods moved upward on the 313-line raster.

After reset, the first HOLE starts at HSYNCn rising edge 496 and ends at edge
512. Each subsequent pulse lasts **16 scanlines**. Loading M4:L4 with `C9` or
`CB` gives an interval of `512 - (192 + preset)` between successive HOLE rising
edges: **311 or 309 lines**, respectively. The reload edge is included.

The owner approved the [combined correction](MOVING_HOLE_FIX_PROPOSAL.md) on
22 October 2026. L4 now loads **6 at the upper boundary** (314-line period,
one line downward per frame) and **8 at the lower boundary** (312-line period,
one line upward). This follows PCB-47's stated 6/8 behavior without claiming
that Figure 18's drawing has been reconciled.

The actual vertical ripple counter also produces a false `(C+D)n` pulse during
the 95-to-96 transition. The top level therefore extends the existing explicit
LS74 collision sample bank to ten channels: channel 8 captures `(C+D)n` after
the raster settles; channel 9 is tied low. Only the moving-hole input uses this
new sample. This is an approved FPGA timing adapter, not a PCB gate.

With actual Figure 5/9 feedback, the sampled circuit reverses with opening
starts at lines **83 and 224**, retains a **16-line width**, and does not wrap.
No IC models, raster timing or other collision-channel assignments changed.

## Running verification

```bash
bash sim/run_moving_hole_tests.sh
cd sim
bash run_sim.sh                 # Existing default two-player mode
ONE_PLAYER=1 bash run_sim.sh    # Exercise the moving opening in the full core
```

`ONE_PLAYER_MODE` is now a testbench-only generic driving the active-low
`GameSelect_I` input. The core synchronizes and debounces that input, then
Figure 10 C5 gates the selected mode with ATRCn for all five gameplay inputs.
Credit configuration remains the existing one-game-per-coin selection.

The focused suite checks the 9316, 7474, both 107 variants, asynchronous reset,
16-line width, both presets, direction retention across reset, boundary gating,
Figure 19 polarity/mode selection and 1,000 fields with ideal boundaries.
An additional actual-raster regression checks 998 complete fields, comparing
raw and sampled boundary feedback. It requires repeated reversals, one-line
motion, constant width and no missing openings. The short full-core capture
checks integration/video; repeated reversals are verified by the longer fixture.

Generated artifacts (ignored by git):

- `sim/moving_hole_timing.png`: measured HOLE versus field and scanline.
- `sim/moving_hole.gif`: animated signal diagnostic over 1,000 fields.
- `sim/moving_hole_raster.png` and `sim/moving_hole_raster.gif`: actual-raster
  comparison (red = raw boundary, green = sampled boundary).
- `sim/moving_hole_core.png` and `sim/moving_hole_core.gif`: retained full-core
  one-player video from `ONE_PLAYER=1 bash run_sim.sh`.
- `sim/frame_output.png` and `sim/gameplay.gif`: actual full-core video from the
  most recent `run_sim.sh` invocation.

The signal diagnostic is labelled separately from the full-core video. It
renders actual testbench samples. The correction is included in subsequent successful Quartus builds. The owner
confirmed one-player mode complete on 26 October 2026; see the
[verification record](VERIFICATION_STATUS.md). Specific post-fit moving-hole
timing and image-linked sweep measurements remain separate verification tasks.

For remaining gameplay corrections and source questions, see the
[current work queue](IMPLEMENTATION_PLAN.md). The [one-player handoff](ONE_PLAYER_HANDOFF.md)
is retained as historical context.
