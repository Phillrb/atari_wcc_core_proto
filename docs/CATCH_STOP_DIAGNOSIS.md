# Catch and horizontal STOP investigation

> Historical STOP investigation. The approved preset is retained, and subsequent collision/catch repairs are documented in [collision timing](COLLISION_TIMING_HANDOFF.md), [vertical timing](VERTICAL_BALL_TIMING.md), [catch timeout](CATCH_TIMEOUT.md) and [rear catch timeout](REAR_CATCH_TIMEOUT.md). Statements below about deferred tests or unresolved BLIP describe that earlier stage. Horizontal acceleration remains open in the [current queue](IMPLEMENTATION_PLAN.md).

## Approved correction — 18 October 2026

The project owner approved adapting B5 to the measured raster. In
`HorizontalDirectionAndSpeed.vhd`, B5 pin 10 (A1) is now high and pin 8 (A2)
is low, changing the fixed adder input from 10 to 9. All logic remains in the
existing LS83 instance. The raster, counter wiring and catch logic are unchanged.
This is an explicit schematic adaptation, analogous to the vertical adaptation.

The isolated fixed-preset diagnostic was rerun before this change and again
measured drifting positions with 10 and stable positions with 9. That experiment
establishes the period correction, but does not validate complete catching.
At the owner's request, the production change is now awaiting their manual
build; further simulation and catch regressions are deferred until needed.
The remaining BLIP/collision concerns below have not been changed or resolved.

The following sections record the investigation **before this correction**.

TM-035 says goalies and forwards catch in both paid play and attract mode.
Defensemen only bounce. A catch ends on the appropriate kick button, when the
player leaves the ball, or after the nominal three-second timeout. See the
manual's attract description (line 350), play description (lines 359–361),
and Figure 13 catch description (lines 1041–1056).

## Reproduced failure

The horizontal STOP preset does not hold the ball still against the current
raster. This is independent of catch-trigger generation: holding both motion
presets continuously at their STOP values reproduces it.

`bash sim/run_catch_diagnostic.sh` connects the actual HorizontalSync,
VerticalSync and BallMotionCircuit entities, holds vertical STOP at 7, and
measures horizontal preset 10 and an experimental preset 9. It also runs the
existing Figure 12 serve/catch timer assertions. No production logic changes.

| Measurement | Current preset 10 | Experimental preset 9 |
| --- | --- | --- |
| Raster clocks per line | 455 | 455 |
| CLOCK_7 rising edges with HBLANKn high per line | 375 | 375 |
| Horizontal counter period in enabled clocks | 374 | 375 |
| BALL leading edge H on successive lines of the first captured field | 441, 440, …, 434 | 314 on all eight lines |
| BALL leading edge H at V=248 in three successive fields | 441, 128, 189 | 314, 314, 314 |

The period is 384 minus the horizontal preset. Preset 10 therefore moves one
pixel left each scanline, wrapping within the counter cycle, even with STOP
continuously asserted. Vertical position is stable at V=248–255 in both runs.
The different initial H coordinates result from running the different fixed
presets from release; the decisive measurement is stability across fields.

Generated evidence: `sim/horizontal_stop10.csv`, `sim/horizontal_stop9.csv`,
`sim/horizontal_stop.png`, and `sim/horizontal_stop.gif`. The visualization
shows measured leading edges with an eight-pixel ball width and enlarged Y.

A separate temporary closed-loop diagnostic retained the actual raster,
player horizontal windows, multiplexer, summing, catch circuit, serve timer,
speed circuits and ball counters. Its vertical player symbols were held high
and wall contacts supplied by the testbench. A checked goalie contact asserted
STOP at 134.908130 ms. The ball then left that column despite STOP=1,
HSPEED=10 and VSPEED=7. D5's no-contact detector cleared STOP at 159.504730 ms,
only 24.5966 ms later, against a 140 ms test timeout. This establishes a
simulation mechanism for a catch too short to appear to stick; it is not a
measurement of the FPGA hardware or a claim that every contact has this cause.

The normal 650 ms `sim/run_sim.sh` regression passed and generated the inspected
`frame_output.png` and `gameplay.gif`. Its default trajectory did not exercise
a sustained goalie/forward catch, so that passing run alone cannot validate
catching. The temporary full-core trace observed a sampled defender contact
and no STOP assertion.

## Correction requires a timing decision

Figures 15 and 16 explicitly specify horizontal STOP=10. Their implementation
currently retains that value. The experimental preset 9 demonstrates that
matching the counter period to the measured raster removes the drift, but
changing B5's fixed straps would be a schematic departure, like the separately
approved vertical adaptation. Alternatively, the clock/blanking boundary can
be investigated to determine how to retain the specified STOP=10.

No production VHDL was changed. Do not treat the older documentation's
374-active-clock claim or its claim that diagonal ball skew is necessarily
hardware-accurate as established: the actual counter-enable measurement here
is 375, and the skew occurs under a command that must hold the ball stationary.
This finding does not by itself settle the original board's edge timing.

There are also separate concerns in the current player-window BLIP timing and
zero-delay collision hazards (see `DEFENDER_HIT_HAZARD.md`), and the horizontal
speed increment input was tied high at the time of this diagnosis (now implemented;
see [hit acceleration](HIT_ACCELERATION.md)). Those issues were not fixed
by changing a STOP preset and should not be conflated with this isolated result.
