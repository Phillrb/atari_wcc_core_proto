# Figure 21 score rollover on the FPGA

On 17 October 2026 the reported solids score jump from 9 to 12 was reproduced
with the saved 13 October fitted board netlist and its slow-corner SDF delays.
The same stimulus passes with the corrected fit at both timing corners.
No game or IC VHDL was changed. The separate checks-goal detection issue is
outside this change.

## Cause and correction

Figure 21 connects J3-3 to K3 CP0, K3 Q0 to CP1, and K3 Q3 to the N2 tens
flip-flop. `ScoreCircuit.vhd` preserves that wiring. Within the LS90 model,
FF_B/Q1 samples the inverse of FF_D/Q3 at the same falling Q0 edge.

The original fit routed Q0 to FF_B and FF_C through a global clock buffer,
but routed it to FF_D locally. At 9 -> 0, Q3 therefore cleared early enough
for FF_B to read the new zero and set Q1. N2 still toggled when Q3 fell:
the tens digit became 1 and the units became 2. Zero-delay GHDL simulation
cannot represent this clock skew.

With the previously unconstrained score clocks described in TimeQuest, the
original K3 Q3 -> Q1 path has **-0.593 ns slow-corner hold slack**. The saved
post-fit simulation independently failed with:

```text
POSTFIT score 8 0
POSTFIT score 9 0
Error: Score expected 10/0, got 12 0
```

`atari_wcc.qsf` now explicitly assigns all three Q0 clock sinks in each LS90
to global clock routing. It uses source-to-destination assignments because
source-only automatic promotion had already promoted only part of this net.
Both counter instances are covered; this is not a change to goal detection.

`atari_wcc.sdc` adds score event clocks and the Q0/Q3 generated clocks.
The fitted J3 LUT absorbs the LS90 clock inverter, so its output is an
active-high pulse, unlike the schematic NAND output. Q0 toggles on its
rising edges. Q3 rises at count 8 and falls at count 10; the generated-clock
edge list preserves this 20% duty cycle and N2's falling-edge clocking.

The 280 ns event period represents a conservative envelope of a 140 ns pulse
and a 140 ns gap, not periodic goals or a fixed phase relationship with the
raster. These constraints check local counter feedback and clock pulse width.
They do not establish that the upstream MISS/H256 logic is glitch-free or
that asynchronous START recovery/removal meets timing. No score feedback
path is false-pathed.

## Verification

The final fit uses 3,108 / 4,608 logic elements. All six B/C/D clock sinks
use their respective Q0 global routes. The fitted J3 LUT polarity also
matches the constraints. Score setup/hold results in nanoseconds:

| Check | Slow corner | Fast corner |
|---|---:|---:|
| K3 Q3 -> Q1 hold | +0.749 | +0.245 |
| L3 Q3 -> Q1 hold | +0.751 | +0.244 |
| Worst score setup | +279.235 | +279.665 |
| Worst score hold | +0.499 | +0.215 |

The timing checker includes paths launched from generated-clock **pins**, not
just register nodes. A register-only `-from` filter silently omits the
critical Q3 feedback path once a generated clock is defined on that output.

Regression commands, from the repository root:

```bash
bash sim/run_score_tests.sh
quartus_sh --flow compile atari_wcc
python3 sim/check_score_routing.py
quartus_sta -t sim/check_score_timing.tcl
bash sim/run_score_postfit.sh
cd sim && bash run_sim.sh
```

- `tb_LS90`: direct entity instantiation, paired reset/set inputs, independent
  divide-by-two/divide-by-five sections, Q0 feedback, repeated BCD rollover,
  clock inhibition during asynchronous controls and first count after release.
- `tb_ScoreCircuit` and `check_score.py`: 66 observations of the actual circuit
  nets, one J3 clock edge per goal, one tens transition per carry, 19 -> 0,
  independence of the two score counters and START with nonzero tens/units.
  Pixel samples check the displayed digits rather than substituting a counter
  or drawing expected digits. Captures: `sim/score_8.png` through
  `sim/score_12.png`, `sim/score_rollover.png`, `sim/score_rollover.gif`.
- `check_score_timing.tcl`: setup and hold checks at both corners, explicit
  coverage of Q3 -> Q1, reports in `output_files/score_*_*.rpt`.
- Full `sim/run_sim.sh` passed the coin/start/serve/expiry assertions and
  produced the gameplay PNG/GIF. `sim/frame_output.png` and the score contact
  sheet were visually inspected: playfield/players/ball remain present and
  the displayed score advances 8, 9, 10, 11, 12.
- `score_postfit.do`: the complete fitted board netlist with SDF backannotation,
  driving only the goal pulse, H256 and START sources to isolate Figure 21.
  Counter outputs are never forced. Tests both score counters through 21 goals,
  another 1 -> 12 run, reset and first post-reset goal, with 140 ns high/low
  stimulus. Both corners pass. Logs: `output_files/score_postfit_{slow,fast}.log`.

For ModelSim-Altera on a modern Linux host, `MODELSIM_BIN` can select its
actual platform binary directory (on this host,
`/home/phill/altera/13.0sp1/modelsim_ase/linuxaloem`). The host needed the
32-bit `libxft2`, `libncurses5` and `libtinfo5` runtime packages. They were
extracted under `/tmp/wcc-modelsim-libs/runtime`, with both its
`usr/lib/i386-linux-gnu` and `lib/i386-linux-gnu` on `LD_LIBRARY_PATH`;
no system packages or installed tool files were modified. The legacy
simulator must run outside the execution sandbox on this host.

## Remaining board check

Load `output_files/atari_wcc.sof`, start a fresh game and verify consecutive
solids goals display 8, 9, 10, 11, 12. Verify a new game resets the score.
The bitstream was generated but has not been programmed or tested on the
physical board in this session. SHA-256 of the verified build:

```text
03615909332308a6a1b4f832aef503eda70eb12290c810c57a7d9e8c59ac6dda
```

This is score-path timing closure, not whole-design timing closure. The final
build still reports 29 other unconstrained clocks and existing CLOCK_7
hold/removal failures (slow hold -22.484 ns, removal -15.993 ns). Those and
the checks-scoring gameplay issue remain separate work.
