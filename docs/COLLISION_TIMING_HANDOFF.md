# Ball / goal / defender regression handoff — 18 October 2026

**20 October follow-up:** the owner reported rapid vertical rolling immediately
after serve. The fitted vertical counter/phase paths had timing faults outside
the checks below. See [vertical rolling diagnosis and replacement build](VERTICAL_BALL_TIMING.md).
The bitstream hash and verification below describe the earlier build.

## Owner report and authorization

After d60a166 the ball is square without ripple, but open goals bounce the ball
back and defenders sometimes catch. Which defender team is affected is unknown.
The owner explicitly approved an LS74-based FPGA collision timing adapter, then
requested wrapping up for manual testing rather than extended fitted simulations.

## Findings (simulation evidence, not physical waveforms)

- The old fitted goal sampler/score path accepts clean goal pulses. Controlled
  placement at both goal walls scores. These fixtures bypass actual horizontal
  ball-counter behavior and therefore did not reproduce the reported gameplay.
- In the old fitted ball counters, C4 7 -> 8 produces a 182 ps terminal-decode
  pulse. B3 toggles incorrectly at 31.056679 us. The saved trace repeats false
  toggles at 78.096679 and 113.936679 us. A regression rejects these.
- Storing C4's terminal decode removes those false phase changes. An intermediate
  fitted trace has four legitimate phase transitions and two 1119.571 ns ball
  pulses (eight pixels), but also two 0.429 ns raw ball pulses eight pixels early.
  The carry correction alone is therefore insufficient for collision safety.
- These are confirmed model hazards and plausible causes, not proof that all
  reported board symptoms share this cause. Final hardware confirmation is pending.

## Changes

1. IC9316 adds optional REGISTERED_CARRY (default false). Enabled only for C4
   in BallMotionCircuit. It stores next-count terminal status at the counter edge,
   retaining async clear, load priority, enables and asynchronous CET gating.
   It does not delay carry by a clock. Figure 16 connections remain unchanged.
2. CollisionSampleBank uses direct LS74 instances. The top gates CLOCK_14 with
   inverted CLOCK_7 using LS04/LS08, sampling halfway through CLOCK_7 low after
   raster ripple settles. Qualified HIT, wall bounce, MISS and player segments
   feed collision consumers; visible BALL/PADDLES retain their original paths.
3. CatchKickHorizontalDirection optionally samples E8/C8's already-qualified
   outputs before D8. Qualifying BEFORE registering prevents separately sampled
   HIT/DEFENSEMENn skew from creating a false catch. D5 uses sampled HIT.
4. LS153 feedback holds player-segment samples outside a valid hit, keeping
   D7's data stable when the sampled HIT closes its transparent latch.
5. QSF retains the square-ball and score global routes, adds C4 terminal and
   all collision sampling sinks. SDC describes the new sampling clock.

The existing uncommitted horizontal stop-code 9 change and its approval notes
were present before this session and are retained. This build includes them.

## Verification

- IC9316 original test and exhaustive carry equivalence pass: every preset,
  both enables, load priority, rollover, async clear and CET gating.
- tb_CollisionSampling passes: both teams' defender contacts do not catch;
  qualifying contacts catch and kick releases; a 1 ns false wall/catch pulse is
  rejected; a genuine wall event survives. This is a focused RTL fixture,
  not full player motion or fitted glitch rejection proof.
- Quartus full compile passes (0 errors, 162 warnings). All 12 adapter registers
  use the same global sampling clock; ball and score routing checks pass.
- Final ball and score setup/hold checker scripts both pass at both corners.
- Final STA constrained COLLISION_SAMPLE setup/hold slack: slow +31.250/+37.343 ns;
  fast +34.048/+35.673 ns. This excludes unconstrained ripple-source paths.
  Whole-design hold/removal issues remain; this is not whole-design timing closure.
- The carry-only fitted regression passed before adding the collision adapter.
  sim/ball_carry_postfit.do and check_ball_carry.py retain that fixture. It forces
  CLOCK_7 and vertical window state; it DOES NOT exercise the final adapter clock
  or prove final catch/goal behavior. Extended final fitted simulation is deferred
  at the owner's request.

Final bitstream: output_files/atari_wcc.sof
SHA-256: 4516b3802cae0e1f83c406f74c371b3ba15c84e04d3545210d40d1214e8d1486

Temporary investigation evidence is in /tmp/wcc-regression-fit. The pre-change
bitstream/netlist/SDF are preserved in /tmp/wcc-ball-regression-before.

The full run_sim.sh reached the vertical regression successfully, then an
independent analysis command interfered with its shared GHDL library. The final
650 ms core capture was restarted from a fresh compilation without repeating
already-passed unit/vertical regressions. This is a tooling interruption, not a
reported VHDL assertion failure. See /tmp/wcc-final-capture.log for that capture.

## Manual board test / next session

Start a fresh paid two-player game. Check square ball while moving and held;
score through both goal openings (point, goal sound and new serve); ensure both
teams' defenders only bounce; verify both goalies/forwards catch and kick buttons
release. Also check automatic catch release and new-game score reset.

If any symptom remains, record the team, player column, ball direction, game
mode, and whether a goal sound/serve occurs. Next fitted regression must run the
actual CLOCK_14/ComputerClock relationship, assert sampled events reject the
observed raw glitches, and exercise both goal mouths and all six player columns.
