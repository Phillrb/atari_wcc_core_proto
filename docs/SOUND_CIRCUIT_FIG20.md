# Figure 20: sound circuit

Implemented in `SoundCircuit.vhd` using direct IC9602, LS00 and LS20 instances.
The user confirmed Figure 20 wiring, timing components, P2 = +5 V, and E7 =
7420 (the previous LS27 entry in AGENTS.md was incorrect).

## Pin trace

| Device | Connections |
| --- | --- |
| J9 channel 1 | 4 = MISS; 5,3 = +5 V; 6 = GOAL; 7 = GOALn. R49 47k from +5 V to pin 2; C19 5uF between pins 2 and 1. |
| L8 gate 2 | 5 = HIT; 4 = STOPn; 6 drives M9 pin 5. |
| M9 channel 1 | 5 = L8-6; 4 = ground; 3 = +5 V; 6 drives L8-1. R47 12k from SLOW and R44 68k from +5 V meet at pin 2; C28 1uF between pins 2 and 1. |
| L8 gate 1 | 1 = M9-6; 2 = HIT_TONE; 3 drives E7-1. |
| L8 gate 4 | 12 = 32V; 13 = J9-6; 11 = SCORE_SOUNDn, also E7-4. |
| E5 channel 2 | 11 = BOUNCEn; 12 = ground; 13 = +5 V; 9 drives E5-5. R67 22k to pin 14; C31 5nF between 14 and 15. |
| E5 channel 1 | 5 = E5-9; 4 = ground; 3 = +5 V; 7 drives E7-5. R68 33k to pin 2; C32 10nF between 2 and 1. |
| E7 gate 1 | 1 = L8-3; 2 = ATRCn; 4 = SCORE_SOUNDn; 5 = E5-7; 6 = SOUND_OUT. |

E5 channel 1 starts on channel 2 Qn's **falling leading edge**, one sampling
clock later in the FPGA. It does not wait for channel 2's pulse to expire.
E7 is a four-input NAND drawn as a negative-true OR. When ATRCn is low,
SOUND_OUT is constant high (mute). When enabled and idle it is low.
R50 (1k) and monitor audio circuitry are external analogue components.

## Timing and model boundary

The local National Semiconductor `IC/data/9602.PDF`, pages 1 and 3, specifies
A falling with B low, or B rising with A high, with clear high. Pins A/B are
5/4 and 11/12. The old model uses opposite edges without qualification.
`PIN_ACCURATE => true` enables corrected triggers, retriggering, asynchronous
clear, and exact N-clock pulse widths. Existing users retain legacy behaviour
by default, including their historical N+1-clock expiry. Startup and the first
sample after clear establish input history rather than inventing an edge.
Inputs must be observable at a timing-clock edge. Propagation delay, capacitor
discharge dead time and changes of SLOW within an active pulse are not modelled.
M9 samples its width at each trigger/retrigger.

For fixed RC networks, nominal t = 0.34 * (R[kohm] + 1) * C[pF] ns:

| Envelope | Default |
| --- | --- |
| Goal | 81.6 ms |
| Slow hit | 23.460 ms, adjustable estimate |
| Fast hit | 3.808 ms, adjustable estimate |
| E5 channel 2 | 39 us (39.1 us nominal) |
| E5 channel 1 | 116 us (115.6 us nominal) |

**The two M9 defaults are approved estimates, not calibrated timings.** The
slow estimate uses the 68k branch; the fast estimate uses the parallel-resistor
scale. This does not solve the actual TTL output voltage/current behaviour of
the SLOW-controlled RC network. Tune the generics against measured hardware.
All durations are rounded to timing-clock cycles. The core selects 7,142,857 Hz
to match its current board PLL and testbench; the standalone default is the
schematic's 7,159,090 Hz.

## Integration

The core feeds raw MISS, HIT, STOPn, SLOW, HIT_TONE, 32V and BOUNCEn into sound.
GOAL and SCORE_SOUNDn replace tied constants in HorizontalDirectionAndSpeed;
GOALn connects to ServeTimingCircuit. SOUND_OUT reaches board Audio1_O,
**FPGA pin 71**, copied from `MaSTer/Sprint2v1/sprint2/sprint2.qsf`.
Sprint2's second audio output (pin 72) is unused.

The core now receives ATRC/ATRCn from Figure 8's StartCircuit. Sound's ATRCn
is high during play and low during attract; full-core simulation verifies mute
on power-up and after time expiry. ServeTimingCircuit now controls the ball,
with pin-accurate J5 triggers and three-second board defaults. See
[JAMMA/game-control integration](JAMMA_GAME_CONTROL.md).
The existing tied GOALIE_FWD_HIT input also prevents exercising full speed
progression in gameplay; both SLOW states are tested independently here.

## Validation

Run `bash sim/run_sound_tests.sh` for exhaustive LS00/LS20 binary truth tables,
legacy 9602 regression, corrected 9602 tests (edges, qualification, exact
expiry, retrigger, dynamic width, clear), and complete sound-path assertions.
The circuit test covers MISS polarity, 32V gating, STOP inhibition, hit tone
passing, both hit durations, E5 cascade/expiry, simultaneous mixing and mute.
GHDL synthesis of SoundCircuit also succeeds.

`cd sim && bash run_sim.sh` completed 300 ms / 2,142,857 samples with no errors
(the existing time-zero numeric_std metavalue warnings remain). PNG keyframes
and gameplay.gif are generated; frame_output.png was visually inspected.
Quartus 13.0sp1 full compilation and fitting also succeed (0 errors, 154
warnings); the fitted pin report confirms Audio1_O on pin 71. **Timing is not
closed:** TimeQuest reports timing violations, including hold paths into sound,
and incomplete setup/hold constraints. Compilation success is not a timing-clean
hardware sign-off. No hardware listening test was performed.
