# Vertical ball rolling immediately after serve — 20 October 2026

The owner reported very fast vertical rolling, almost a column, immediately
after serve following the collision timing changes. The existing fitted tests
forced the vertical window and checked only horizontal motion, so they could
not detect vertical counter failures.

## Evidence

The build present at investigation start had SHA-256
`99b26dd831ccd785c4ecd78fffb2dcddb504b0557b2cb09cba67cc702f1d797b`.
It differs from the 18 October handoff's recorded hash. Its netlist, both SDF
corners and bitstream were preserved in `/tmp/wcc-vertical-before`.

Figure 16 connects A4 and D4 to the same HSYNCn clock. The fitted netlist
routed A4 locally and D4 globally. At the slow corner the skew was 2.388 ns
and worst A4-to-D4 hold slack was -0.771 ns; the fast corner also failed,
at -0.570 ns.

The new fitted test drives the registered HSYNC source, serve and STOP while
leaving both counters, their carry/load feedback and B3 untouched. It compares
every settled A4/D4/B3 state with the Figure 16 count sequence.

- Original fit: D4 increments at line 15 instead of 16. The slow model later
  produces unknown D4 bits; the fast model reports 862 state mismatches over
  1200 lines and spurious windows.
- Routing correction alone: counter setup/hold passes, but the carry-derived
  phase still fails. STOP windows recur every 256 lines, with six-line height,
  instead of every 313 lines with eight-line height. This would advance the
  window by 57 raster lines per recurrence. This intermediate build and traces
  are preserved in `/tmp/wcc-vertical-routing-only`.
- Registering A4's terminal decode removes the phase/count mismatches in both
  fitted models. An additional STA check found a remaining -0.128 ns fast-corner
  D4-to-B3 hold violation. Enabling internal hold optimization repairs that path.

These are reproduced fitted faults consistent with the reported symptom.
Physical FPGA confirmation of the replacement build is still required.

## Changes

- Route all A4/D4 bits and A4's terminal register through one global HSYNCn
  route, as already done for the horizontal counters.
- Enable the existing `IC9316.REGISTERED_CARRY` option on A4 as well as C4.
  It stores next-count terminal status, preserving pin truth tables, load,
  clear, enables and the original count at which carry changes. Figure 16
  pin connections and the approved vertical speed presets are unchanged.
- Constrain HSYNC's local counter domain and A4's carry-derived B3 clock.
  The carry clock uses a conservative one-line high/one-line low envelope;
  actual preset-dependent intervals are longer. This covers the same-edge
  D4-to-B3 hold relationship and B3-to-counter load feedback.
- Enable Quartus `OPTIMIZE_HOLD_TIMING = ALL PATHS`. Its previous default
  optimized I/O and minimum-TPD paths, leaving this internal hold violation.
- Extend routing/timing guards to include the vertical counters and B3.
  Add a fitted regression for STOP and both maximum vertical directions.

The earlier collision sampler, C4 carry protection and approved horizontal
STOP=9 adaptation remain part of this build.

## Verification and artifacts

Run from the repository root:

```bash
quartus_sh --flow compile atari_wcc
python3 sim/check_ball_routing.py
python3 sim/check_score_routing.py
quartus_sta -t sim/check_ball_timing.tcl
quartus_sta -t sim/check_score_timing.tcl
bash sim/run_ball_postfit.sh
bash sim/run_score_postfit.sh
cd sim && bash run_sim.sh
```

For this host's ModelSim runtime environment, see
[score verification](SCORE_ROLLOVER_TIMING.md). The fitted ball runner compiles
the exported board netlist in an isolated temporary library and uses both SDF
corners. CSVs, VCDs and logs are under `output_files/ball_postfit/`.

The final Quartus build completes with 0 errors and 161 warnings. Both ball
axes and B3 pass their constrained setup/hold checks at both corners. Minimum
vertical hold slack is +0.499 ns slow and +0.215 ns fast. Existing horizontal
and score routing/timing checks also pass. Other unconstrained ripple clocks
and whole-design timing warnings remain outside this local repair.

The full RTL run passes the exhaustive carry tests, all 25 vertical
speed/STOP/bounce period cases, the 180-field closed-loop bounce test, collision
sampling and score tests, and the 650 ms coin/start/serve/expiry capture.
`sim/frame_output.png` and multiple frames from `sim/gameplay.gif` were inspected:
the ball is compact and remains visible during paid play.

The fitted STOP trace has windows starting at lines 504, 817 and 1130:
exactly 313 lines apart. The maximum upward (serve) and downward cases recur
every 310 and 316 lines respectively, corresponding to -3 and +3 lines per
313-line field. All 3600 counter/phase comparisons pass at each SDF corner.
Both horizontal carry/pulse-width tests and both fitted score runs pass too.
A before/after diagnostic can be rendered with:

```bash
python3 sim/visualize_vertical_postfit.py \
  /tmp/wcc-vertical-before/postfit/fast.csv \
  output_files/ball_postfit/fast.csv sim
```

This produces `sim/vertical_postfit_comparison.png` and
`sim/vertical_postfit_comparison.gif`. They show the isolated vertical window;
horizontal position and full gameplay are intentionally omitted. The PNG and
GIF keyframes were inspected.

The horizontal fitted regression retains its controlled vertical window.
It checks C4/B3 terminal transitions and eight-pixel pulse widths, not the
complete collision adapter or all goal/player interactions. The score fixture
also drives controlled goal events. These are focused timing regressions.

## Replacement FPGA image

`output_files/atari_wcc.sof`

SHA-256:
`76d01e6d840eb318a6a42519e0dc8e90c75f2242a8df3fd054d7219adc2eedd6`

Start a fresh paid game and check the first served ball, then caught/released
ball motion, both wall bounces and goal counting. In particular, confirm that
the immediate vertical rolling has stopped. This document does not claim
physical board verification.
