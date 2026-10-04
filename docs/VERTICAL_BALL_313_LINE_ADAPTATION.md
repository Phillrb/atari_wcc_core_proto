# Vertical ball motion on the 313-line raster

The reported failure was upward motion after a forward-player hit, followed by
sticking at the upper wall or escaping above it on another hit.

## Cause and approved adaptation

Figure 14 straps A7's fixed B input to 6: pin 11 low, pins 7 and 4 high,
pin 16 low. The implementation matched those connections. They produce a STOP
code of 10 and moving codes from 7 through 13. However, the Figure 16 ball
counter recurs every `320 - VSPEED` scanlines, measured at BALL itself. Against
this project's 313-line raster, that means:

| Condition | Original code | Period | Vertical movement per frame |
| --- | ---: | ---: | ---: |
| Maximum up | 13 | 307 | -6 lines |
| STOP / central player segment | 10 | 310 | -3 lines |
| Maximum down after top bounce | 7 | 313 | 0 lines |

Thus even a correctly clocked D6 bounce latch cannot select downward motion.
The previous latch test only checked adder codes, so it missed this mismatch.

Figure 16 annotates vertical STOP as Va/Vb/Vc/Vd = 1/1/1/0 (code 7), whereas
Figure 14 annotates 0/1/0/1 (code 10). The appendix full schematic repeats the
conflict. This change is an **explicit adaptation**, not a claim to resolve the
original PCB variant or the conflicting documentation.

On 2026-10-04 the user selected "Adapt A7 for the 313-line raster". Accordingly,
A7 pin 11 (B1) is now high and pin 4 (B3) low, changing fixed B from 6 to 3.
All logic remains in the existing explicit TTL instances. No counter presets,
raster timing, IC models, hit latches or bounce wiring were changed.

| Player segment PP4..PP2 | New VSPEED | Movement per frame |
| --- | ---: | ---: |
| 000 | 10 | -3 |
| 001 | 9 | -2 |
| 010 | 8 | -1 |
| 011 | 7 | 0 |
| 100 | 7 | 0 |
| 101 | 6 | +1 |
| 110 | 5 | +2 |
| 111 | 4 | +3 |

STOP now selects 7, giving exactly 313 lines between ball windows. Top bounces
select nonnegative movement; bottom bounces select nonpositive movement,
preserving speed magnitude. Zero vertical speed remains zero at either wall.

## Verification

`tb_VerticalHitHold.vhd` retains its no-contact, hit capture, hold, bounce,
STOP/release and serve checks with the adapted codes.

`tb_VerticalBallMotion.vhd` connects the actual Figure 14 direction and Figure
16 motion circuits. It measures successive BALL windows for STOP and all eight
segments after hits, top bounces and bottom bounces (25 cases). It then closes
Figure 19's BALL/wall feedback into Figure 14 for 180 fields, checking that the
ball stays within the wall-contact envelope and reaches both walls. The
fixture supplies Figure 9's wall coordinates (80..83 and 240..243) and 128V
polarity; this isolates vertical feedback from other gameplay events.

Run:

```bash
bash sim/run_vertical_ball_tests.sh
cd sim && bash run_sim.sh
```

The focused script generates measured signal diagnostics:

- `sim/vertical_ball_periods.csv`: code, measured recurrence and expected drift.
- `sim/vertical_ball_trajectory.csv`: actual BALL-positive scanlines.
- `sim/vertical_ball_timing.png`: scanline versus frame plot.
- `sim/vertical_ball_bounce.gif`: animation of the measured vertical window,
  with horizontal position intentionally omitted.

`run_sim.sh` also runs the movement regression, existing control/input checks,
and the 650 ms full-core simulation, producing `sim/frame_output.png` and
`sim/gameplay.gif`. The full-core capture is short; repeated wall reversal is
verified by the separate feedback fixture. Board synthesis and physical
hardware testing remain to be done.

The original A7 wiring fails the new STOP assertion (310 lines instead of
313). With the adaptation, all 25 period checks pass. The 180-field feedback
capture shows two top-wall reversals and one bottom-wall reversal; the sampled
ball remains between lines 81 and 241. The timing PNG and animation were
visually inspected, as were the full-core paid-play PNG and gameplay keyframes.
