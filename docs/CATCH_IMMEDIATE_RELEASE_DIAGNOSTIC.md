# Immediate release on FPGA — 23 October 2026

The owner reports that goalies and forwards kick immediately, with no visible
pause, in both game modes. The cause has **not been reproduced or fixed**.

## Board observation

Load `output_files/atari_wcc_catch_debug.sof` into the FPGA using Quartus
Programmer. Do not rebuild the normal project to obtain this image: the
diagnostic was compiled from a separate source tree.

The existing mode switch selects what the board's LED0 displays:

| Mode | LED lit means | Check |
| --- | --- | --- |
| One player | Either debounced kick input is active | With both buttons released, LED should be off. Press each button separately; each should light it. This check also works before starting a game. |
| Two players | STOP is asserted | In a paid game, hold the controls still and contact a goalie or forward. Report whether LED stays off, flashes, or remains lit while the ball moves. Defenders do not catch. |

The outputs are active low. The one-player button test establishes the physical
LED indication before relying on it for the two-player observation. There is no
pulse stretching: a very brief STOP pulse may be too short to see.

Please also report whether this diagnostic image still exhibits immediate
release. Refitting changes placement/routing, so a change in behavior is useful
evidence even though the diagnostic only adds LED observation logic.

The normal `output_files/atari_wcc.sof` was not replaced with the diagnostic.
Diagnostic SOF SHA-256:

`c4810736b572fa7269e77c72b9d6cefe68d866688a3732a27c08123647d81e6c`

## Implementation and reproduction

`sim/CatchStatusLED.vhd` uses direct LS02 and LS153 instances. It selects
active-low STOP or NOR of the two debounced kick signals. The preparer replaces
only the core's LED assignment in a separate directory; game logic and board
pin assignments remain as supplied by the working tree.

```bash
bash sim/run_catch_led_tests.sh
python3 sim/prepare_catch_led_debug.py /tmp/wcc-catch-led-new
cd /tmp/wcc-catch-led-new
/home/phill/altera/13.0sp1/quartus/bin/quartus_sh --flow compile atari_wcc
```

The destination must not already exist. A new fit need not produce the same SOF
hash. The exact compiled sources, their SHA-256 manifest, build/test logs and
video evidence are retained in `output_files/catch_debug/`, including
`sources.zip`. This snapshot includes the pre-existing repository cleanup
changes; those changes are not part of the diagnostic source commit.

## Evidence and limits

- `bash sim/run_catch_timeout_tests.sh` passes both checked-pattern parities,
  all tested overlaps and rear-to-front traversal.
- The full `cd sim && bash run_sim.sh` passes, including the 650 ms control/video
  capture. These tests have not reproduced the reported hardware behavior.
- Temporary fitted probes in `/tmp/wcc-catch-investigation/` exercised D8/J5
  and D5 contact retention across controlled frame boundaries at slow and fast
  corners. STOP remained asserted. A further fast-corner real horizontal
  raster/column probe also generated catches. These probes force stimulus
  signals and are not full gameplay or ball-motion verification.
- The normal SOF changed during investigation because the owner ran Quartus.
  Its initial hash was
  `974f039f6dd8302637e5db0ddf1111097287cd1b5f8d17576608ab5b6faf75cc`;
  the later image was
  `65e735a1b18a6eb061e0bdf699336c5651e036eac49df4eb35cd124187880bf6`.
  The controlled frame probes preceded that replacement; the raster probe
  followed it. They must not be treated as a single immutable fitted baseline.
- Diagnostic LED truth-table assertions pass for every input combination.
- The diagnostic core's 650 ms simulation produces exactly the same raw video
  samples, PNG and GIF as the normal full run. The PNG and six GIF keyframes
  were visually inspected; players, ball and field remain intact.
- Diagnostic Quartus compilation passes with 0 errors and 163 warnings. Ball
  and score global-routing guards and their slow/fast setup/hold checks pass.
  The design remains incompletely constrained; this is not whole-design timing
  closure or proof that the hardware catch fault is resolved.

Next action depends on the physical LED observations. A kick indication with
buttons released directs investigation to switch inputs. STOP absent on contact
directs it to catch arming/qualification or immediate clear. STOP remaining high
while the ball moves directs it to the motion/preset paths.
