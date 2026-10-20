# Checked attacker catch timeout — 20 October 2026

**Follow-up:** the owner confirmed improvement but found a solid-attacker
rear-hit/front-edge trap. The original five alignments missed the far-edge
BLIP overlap. See [rear-hit correction](REAR_CATCH_TIMEOUT.md) for the
expanded regression and replacement image.

The owner confirmed that the previous ball timing repair corrected most issues,
but checked attackers held the ball indefinitely until the kick button was
pressed. TM-035's Catch Circuit description requires an automatic kick after
the nominal three-second J5 STOP pulse.

## Cause and correction

Figure 11 connects M6 pin 9 to both BLIP and J6 pin 3. Figure 13 uses
BALL/BLIP through E8 to preset D8; a goalie/forward HIT clears D8 and triggers
the retriggerable J5 timer.

The existing uniform-spacing adaptation moved the player windows from M6
states 0/4 to states 0/3, using the existing LS86 `Q1_xor_Q2` output as J6's
first input. BLIP still used the original M6 Q2 output, which is high at
state 3. Checked-pixel gaps therefore preset D8 between HIT pixels, restarting
J5 continuously. This was reproduced using the real horizontal raster,
player column decode, checked pattern, collision sampler, and catch/serve
circuits: solid catches expired, but the checked catch exceeded its deadline.

`PlayersVerticalWindow.vhd` now exports `Q1_xor_Q2` as BLIP too. This preserves
the original shared BLIP/J6-input relationship within the existing spacing
adaptation. Both player states have BLIP low, so checked-pixel gaps cannot
re-arm D8. No gates, timer changes, or pulse-retrigger suppression were added.
The board timeout remains 21,428,571 CLOCK_7 cycles, approximately three seconds.

## Regression coverage

`bash sim/run_catch_timeout_tests.sh` tests both teams, five partial/full
eight-pixel ball overlaps per team, and both checked-pattern line parities.
The timeout is accelerated to 5,460 clocks (764.4 microseconds), twelve
scanlines. Every catch must expire exactly that many clocks after STOP rises
and remain released while the same stationary contact continues. Crossing a
BLIP region then permits a fresh catch. The default parity is also included
in `sim/run_sim.sh`.

`tb_ServeControl` additionally checks natural catch expiry after an
asynchronously cleared catch. The control test runner also exposed an obsolete
`tb_TimeLineControl` port map; it now uses the existing H1n/H4/H128 interface.
All control tests pass. These fixtures use accelerated timing and do not
constitute physical board verification.

The complete 650 ms `cd sim && bash run_sim.sh` run passes, including the
existing carry, vertical motion/bounce, score, collision and game-control
regressions. `sim/frame_output.png` and six frames spanning `sim/gameplay.gif`
were visually inspected: player layout is intact and the ball remains compact.
The full capture is a general video regression; the dedicated catch fixture
provides the checked-attacker deadline assertions.

The rebuilt image passes `check_ball_routing.py`, `check_score_routing.py`,
`check_ball_timing.tcl` and `check_score_timing.tcl`, including both slow and fast
setup/hold corners for the constrained ball and score paths. Whole-design
timing closure and a fitted catch-interaction simulation are not claimed.

## FPGA image

`output_files/atari_wcc.sof`

SHA-256:
`8405655dcae977ef724661ca1924db14706f6b6c3cc14e4b7c41ab20acbf0a45`

Quartus compilation completed with 0 errors and 163 warnings.
The previous image is preserved at `/tmp/wcc-catch-before/atari_wcc.sof`.

On the board, catch with a checked attacker and leave both its position and
kick button alone: the ball should release after approximately three seconds.
Repeat with a solid attacker, then check early button release.
