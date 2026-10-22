# Moving-hole reversal proposal

Status: **approved and applied on 22 October 2026**. The owner approved both
the 6/8 presets and settled boundary sampling. Production VHDL now contains
the combined correction. The [reviewed patch](moving_hole_fix_candidate.patch)
is retained as an archival diff against commit `7c3e8a4`; do not reapply it to
the updated source. The sections below record the design decision and evidence.

## 1. Select periods on opposite sides of the 313-line frame

Keep the existing raster, counter cascade, K1 direction latch, H1 mode and
16-line HOLE decode. Change L4's preset connections using K1's Q and Qn:

| L4 pin | Current connection | Candidate connection |
| --- | --- | --- |
| 3, A | High | Low |
| 4, B | K1 Q, pin 9 | K1 Qn, pin 8 |
| 5, C | Low | K1 Qn, pin 8 |
| 6, D | High | K1 Q, pin 9 |

With M4 preset to 12, the recurrence is `512 - (192 + L4 preset)`:

| Boundary sampled | V128 / K1 Q | Preset | Recurrence | Movement per frame |
| --- | --- | --- | --- | --- |
| Top | 0 | 6 (`0110`) | 314 lines | Down one line |
| Bottom | 1 | 8 (`1000`) | 312 lines | Up one line |

The current 9/11 presets give 311/309 lines, both upward. Inverting K1 alone
only exchanges the two upward speeds. This is the same class of mismatch as
[the earlier ball-speed adaptation](VERTICAL_BALL_313_LINE_ADAPTATION.md), but
that approval covered A7, not the moving-hole wiring.

## 2. Sample the settled playfield boundary

Testing the preset change in the full core revealed a second issue: the hole
reversed at line 95 instead of reaching the upper boundary. A focused capture
with the actual `VerticalSync` and `PlayfieldCircuit` reproduced a transient
`(C+D)n` assertion during the 95-to-96 ripple transition. That transient clocks
K1 if HOLE is already high. The settled boundary signal is inactive at line 96.

The combined candidate extends the existing `CollisionSampleBank` from eight
to ten channels. Channel 8 captures `(C+D)n` using the existing `collision_clk`;
channel 9 is tied low. Only `U_MOVING_HOLE` consumes the new channel. This adds
one explicit LS74 pair and uses the existing sampling phase after CLOCK_7's
ripple transitions settle. Other collision-channel assignments are preserved.

This is an **FPGA timing adaptation**, not an original PCB gate. The isolated
actual-raster test compares raw and sampled boundary inputs side by side:

| Feedback | Opening start range | Complete fields | Upper/lower reversals |
| --- | --- | --- | --- |
| Raw `(C+D)n`, 6/8 presets | 95..224 | 998 | 4 / 4 |
| Sampled `(C+D)n`, 6/8 presets | 83..224 | 998 | 3 / 4 |

Both paths retain a 16-line width; the sampled path reaches the intended upper
limit. Tests require contiguous openings, one-line movement, no missing fields,
no wraparound and repeated reversals. At the lower limit, `(C+D)n` can overlap
the end of HOLE before HSYNCn, giving sampled start line 224.

[Measured comparison](images/moving_hole_candidate/raster.png) and
[signal animation](images/moving_hole_candidate/raster.gif): red is raw boundary
feedback, green is the sampled candidate. These are measured signal diagnostics,
not full-game video.

## Source evidence and limitation

- Original `Goal_IV_TM-035.pdf`, page 75 / printed PCB-47, describes preset 6 at
  the upper boundary and 8 at the lower boundary, with 314/312-line timing.
  These numbers are visible in the scan, not merely in the Markdown/OCR.
- Figure 18 on PDF page 76 / PCB-48 and `App_Full_Schematic_1.png` instead show
  the current 9/11 wiring. The prose also contains contradictory 262-line and
  preset-9 statements. This is not a consistent specification.
- The full schematic is labelled 60 Hz and its vertical-reset wiring differs
  from extracted Figure 5. The origin of the differences is unknown to the
  project owner; a particular conversion history has not been established.
- The local National Semiconductor `IC/data/9316.PDF`, page 1, agrees with the
  model's counting edge, synchronous load, asynchronous clear and CET-gated
  terminal count. No shared IC model changes are proposed.

The candidate follows the stated gameplay and 6/8 prose, but **deviates from
Figure 18's preset wiring and adds boundary sampling**. It does not establish
which original PCB/manual variant was correct.

## Reproduction and validation

Run the applied correction directly:

```sh
bash sim/run_moving_hole_tests.sh
cd sim
ONE_PLAYER=1 bash run_sim.sh
```

The combined focused suite includes the existing IC tests, both preset periods,
reset and direction retention, boundary gating, Figure 19 mode selection,
1,000 fields with ideal boundaries, and the actual-raster comparison above.
The new timing regression rejects the production 9/11 circuit with
`HOLE recurrence too early`. The patch passes `git apply --check` against the
pre-adoption production source at `7c3e8a4`.

The combined candidate's standard 650 ms full-core run passes paid start,
serve and expiry checks. Its paid game lasts 300 ms, so repeated reversal is
verified by the longer actual-raster fixture, not by that short full-core run.
The [paid-play PNG](images/moving_hole_candidate/paid_play.png) and
[full-core GIF](images/moving_hole_candidate/gameplay.gif) were visually
inspected, including GIF frames 12, 16 and 20. They show the expected three
solid players and the moving opening on the right.

The earlier **presets-only** candidate also completed an eight-second full-core
run. All 390 checked paid-play frames retained a 16-line opening; it reversed
bottom/top/bottom, but its upper reversal was the premature line-95 event.
That run exposed the need for boundary sampling. It must not be described as
an eight-second full-core test of the combined candidate.

For reproducing that earlier diagnostic only, start with an isolated checkout
of `7c3e8a4` (not the updated production source), then apply
`moving_hole_6_8_candidate.patch` instead of the combined patch, run the standard
simulation, then apply `moving_hole_video_diagnostic.patch` in the isolated copy:

```sh
cd sim
# Compile the instrumented source and long-game testbench after applying patches.
ghdl -a --std=93 ../atari_wcc.vhd ../testbench/tb_atari_wcc.vhd
ghdl -r --std=93 tb_moving_hole_video "-gONE_PLAYER_MODE='1'" --stop-time=8000ms --assert-level=error
python3 ../docs/check_moving_hole_candidate_trace.py moving_hole_full_trace.csv
python3 visualize.py --frame=20
```

That instrumentation is simulation-only and must not enter the board build.
It captures video one frame in four and logs the vertical counter and HOLE on
every HSYNCn edge, using 10 ns timestamp units to avoid integer overflow.

No candidate Quartus fit, post-fit timing simulation or physical FPGA check has
been performed. Those remain necessary before claiming board verification.
