# Ball rendering clock routing — 18 October 2026

The owner reports successful catching/kicking after the horizontal stop-code
adaptation, but a ripple through the ball both held and moving.

The 16:00 fitted build split CLOCK_7 between global and local routes: B4 bits
0–2 used the global buffer, B4 bit 3 and all C4 bits used local routing.
HRESET D2 also used local routing. The timing report shows 20.931 ns skew
from D2 into B4 and worst hold slack of -17.869 ns on that path. This is a
confirmed timing defect and a candidate cause of the reported distortion.

`atari_wcc.qsf` now explicitly routes all eight B4/C4 clock sinks and HRESET
D2 through the existing CLOCK_7 global buffer. No IC/circuit VHDL, stop-code
straps, catch logic, or score clock assignments were changed by this fix.

Validation completed:

- Quartus full compile succeeded, producing `output_files/atari_wcc.sof`.
- `python3 sim/check_ball_routing.py` confirms the nine global clock sinks.
- `quartus_sta -t sim/check_ball_timing.tcl` passes constrained B4/C4 setup
  and hold paths at both corners; minimum hold slack is +0.499 ns slow and
  +0.215 ns fast. Separate unconstrained ripple clocks remain outside this check.
- Existing score routing and two-corner score timing checks pass after refit.
- `cd sim && bash run_sim.sh` passes, including control and score regressions.
  `frame_output.png` was inspected and shows a solid square ball. The run also
  generated `gameplay.gif`. RTL simulation does not verify fitted clock delays.
- The fixed-preset horizontal diagnostic confirms code 9 holds H=314 over
  three fields. The earlier code 10 drifts.

Extended fitted waveform simulations were stopped at the owner's request to
proceed with manual testing. No completed post-fit pixel regression or physical
board confirmation is claimed. Test the ball while caught, immediately after
kicking, and during travel; check goal counting as a regression.

The original build/netlist/timing reports are preserved in `/tmp/wcc-ball-before`
for this session. This routing correction is not whole-design timing closure.
