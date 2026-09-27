# Solid/striped defender HIT investigation

The reproduced silent solid-defender contact is a false collision from the
shared horizontal-window decode. Its zero-time HIT changes the asynchronous
direction latch but is not sampled by the clocked sound one-shot. A genuine
solid-defender overlap does produce sound. No game logic was changed during
this investigation.

## Differences in the current implementation

| Path | Solid | Striped |
| --- | --- | --- |
| Vertical generator | N8/M7/H8, E1 output | H9/J7/F7, E4 output |
| Symbol timing | During counter run | After terminal count |
| Model timing constants: initial/gap/length | 85 / 18 / 16 | 83 / 5 / 29 |
| H7 selection | TEAM=0, Qn=0 | TEAM=1, Qn=1 |
| Check-pattern gate | Passes symbol continuously | Masks alternate H1/V1 pixels |
| Collision and sound | Shared K6 HIT and L8/M9 sound path | Same shared path |

The manual's Defensemen/Goalie Circuits section describes the original circuits
as identical. The present generator differences and timing adjustments are
therefore model discrepancies needing a separate schematic audit. They do not
cause the specific glitch demonstrated here: E1 and E4 both remain high through
its entire transition, and the isolated diagnostic reproduces it with both tied
high and neither generator instantiated.

## Full-core trace

A temporary instrumented simulation used the current core, the board clock,
coin at 100–130 ms, Start at 160–190 ms, and a 50 ms serve delay. It did not
modify the working core or the user's Quartus settings.

At 92.011920 ms (attract, V=192), the solid-column horizontal count changes from
207 to 208. The player window is inactive both before and after this edge:

| Stage within the same simulation time | H4 | H8 | PLAYER_WINDOWn | Effect |
| --- | --- | --- | --- | --- |
| Settled H=207 | 1 | 1 | 1 | No player pixel |
| Ripple intermediate | 0 | 1 | Goes low after gate evaluation | False window |
| Settled H=208 | 0 | 0 | Returns high | No player pixel |

HorizontalSync F1 is an LS93 ripple counter. Its intermediate decoded counts
include 200 and 192 before settling to 208; this does not mean physical time
or the settled counter runs backwards. PlayersVerticalWindow H6 gate 2 combines
H4n, H8 and J6_Y2. H4 falls before H8, so the condition for an enabled window
briefly exists during ripple propagation. H7 passes E1, then M1/K6 pass it to
PADDLES and HIT because BALL is already high.

Both E1 and E4 stay high, TEAM=0, DEFENSEMENn=0, and STOPn=1 throughout. HIT rises
and falls within delta cycles at the same timestamp. The asynchronous D8 path
in CatchKickHorizontalDirection changes HORIZ_DIR_Qn from 0 to 1 after this
pulse. The IC9602 sound model samples on CLOCK_7 rising edges and never sees it.
This accounts for the apparent bounce without a hit envelope.

At 131.843600 ms (attract, V=191), the striped contact occurs inside the valid
H=344–347 window. Its checker pixel at H=345 produces a 140 ns HIT, captured
by sound at 131.843670 ms (although attract still mutes the output). During paid
play the same asymmetry was observed at 391.083420 ms (solid, no sampled HIT)
and 430.915100 ms (striped, hit envelope starts at 430.915170 ms with ATRCn=1).
The exact delta trace above is from the attract occurrences; the longer run
separately establishes that the sampled-hit discrepancy persists during play.

## Isolated reproduction and counterexample

Run `bash sim/run_hit_diagnostic.sh`. It uses the real HorizontalSync,
PlayersVerticalWindow, PlayersMultiplexer, PlayersSumming and SoundCircuit.
E1/E4 are constant high and the other player symbols are low. STOPn and ATRCn
are high. Testbench BALL placement selects two cases:

1. **No real solid overlap:** BALL covers H=207–211, outside the solid window
   H=200–203. The decode hazard at H=208 produces a zero-time HIT and no sound.
   BALL also covers the striped window, producing 140 ns hits and sound.
2. **Real solid overlap:** BALL spans H=196–205, including the solid window.
   HIT lasts 560 ns (four pixels), and the sound output asserts normally.

Both diagnostic runs pass. The first intentionally asserts the observed bug,
not desired behavior: after a fix it must be revised to assert that false
collisions are rejected. HIT_TONE is held high here so audio directly exposes
whether the hit envelope was triggered; this is not a listening test.

## Implications for a fix

Stretching the glitch solely for audio would make a false collision audible.
The collision event must first be made consistent for direction/catch, speed
and sound. The next investigation should reconcile ripple/gate timing with the
original schematic and the FPGA implementation boundary. These zero-delay IC
models provide no physical pulse-width prediction; real TTL inertial delays
and FPGA routing delays may treat the hazard differently. This is a reproduced
simulation cause consistent with the hardware symptom, not a measured hardware
waveform or a completed fix.
