# Solid attacker rear-hit catch — 20 October 2026

After the checked-attacker repair, the owner reported that a ball hitting a
solid attacker from behind stops, releases after three seconds, then catches
at the front and never automatically releases.

## Reproduction

The earlier regression tested ball offsets -4 through 0 relative to the
four-pixel player column. It omitted offsets +1 through +3. With the original
BLIP adaptation, an eight-pixel ball at those offsets extends into the next
M6 state, where BLIP is high. E8 presets D8 after the HIT has cleared it.
The following scanline clears D8 again, retriggering J5 indefinitely.

This is asymmetric: the solid attacker uses M6 state 0, followed by state 1
where Q1 XOR Q2 is high. The checked attacker uses state 3, followed by state 4
where that decode remains low.

The expanded stationary regression fails on the original RTL at solid
offset +1 with `Held catch repeatedly retriggers instead of auto-kicking`.
A second fixture advances the ball in four-pixel steps, with two raster rows
per position and movement inhibited by STOP. The original RTL catches at
offset -7, times out, then catches indefinitely at offset +1. The corrected
RTL catches once and clears the front edge. This fixture uses real raster,
player decode, checked pattern, collision sampling, D8 and J5; its controlled
position steps do not instantiate the Figure 16 motion counters.

## Correction

`PlayersVerticalWindow.U_BLIP_GUARD` uses an explicit LS08 to qualify the
existing `Q1_xor_Q2` BLIP decode with H8. This extends the low region over every
possible eight-pixel-ball/four-pixel-player overlap, including the three
previously missed front-edge positions. BLIP still becomes high between
columns so the next separate catch can arm.

This is an additional FPGA spacing-adapter gate, not an original Figure 11
PCB gate. J6 and the visible player windows retain their previous wiring.
At every active player window H8 is high, so the existing relationship
between BLIP and the J6 decode is preserved there. Figure 13 and the
retriggerable J5 model are unchanged; the board timeout remains approximately
three seconds.

## Verification

`bash sim/run_catch_timeout_tests.sh` tests offsets -7 through +3 for both
teams and both checked-pattern parities. A one-pixel overlap on a checked
hole must not catch. All actual contacts must expire at exactly 5,460 clocks
(764.4 microseconds, twelve scanlines), stay released at the same position,
and allow a fresh catch after crossing a BLIP region.

The same runner tests the rear-to-front sequence and produces
`sim/catch_traversal.csv`, `sim/catch_traversal.png` and
`sim/catch_traversal.gif`. These images depict measured diagnostic positions
and STOP states, with accelerated timing, rather than full gameplay.

The control tests also pass, including manual kick, defender catch rejection,
and natural J5 expiry. The rebuilt image passes the existing ball/score clock
routing guards and local setup/hold checks at both slow and fast corners.
This does not claim whole-design timing closure or a fitted simulation of
the complete rear-hit interaction.

The full `cd sim && bash run_sim.sh` run passes, including carry equivalence,
vertical speed/STOP periods, the 180-field vertical-bounce regression,
collision sampling, score tests, and the 650 ms attract/coin/start/serve/expiry
capture. `frame_output.png`, six gameplay GIF keyframes and the catch
diagnostic keyframes were visually inspected. The ball remains compact and
the player layout is intact. The full capture checks general video behavior;
the dedicated fixture supplies the rear-hit assertions.

## Replacement FPGA image

`output_files/atari_wcc.sof`

SHA-256:
`ac37cabbc59c66b698509711fcad8ed70a7bc7c79d466cdabb5014cfe009e77d`

Quartus compilation completed with 0 errors and 163 warnings. The previous
image is preserved at `/tmp/wcc-rear-catch-before/atari_wcc.sof`.

Board confirmation remains necessary: approach a solid attacker from behind,
leave the kick button alone, and verify the ball releases after approximately
three seconds and continues through the front edge. Also repeat a normal
front catch, a checked-attacker catch, and early release with the kick button.
