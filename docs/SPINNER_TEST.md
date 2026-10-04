# Temporary Solid Forwards spinner input

`SpinnerAdapter.vhd` adapts a quadrature spinner at the FPGA boundary; it is not
an original TM-035 IC. The downstream Figure 11 comparator, ramp, one-shot,
counter and symbol logic remain unchanged. `JammaSwitchAdapter` still handles
switch debounce only.

## Wiring

| Spinner signal | Board port | FPGA package pin |
| --- | --- | --- |
| Phase A | SpinnerA_I | 42 |
| Phase B | SpinnerB_I | 43 |
| Ground | Board GND | Use the board ground connector |

These are FPGA package numbers, not connector-position numbers. Use the board
pinout to locate their header connections. Both inputs are configured for 3.3 V
LVTTL, with weak pull-ups so disconnected inputs settle to a fixed state.

The spinner supply voltage and output circuit have not been identified. Power
it according to its own specification. A 3.3 V logic output may connect directly.
Do not connect a 5 V push-pull output directly: use a suitable 5 V-to-3.3 V level
translator. A confirmed open-collector output can use a 4.7 kΩ pull-up to board
3.3 V on each phase, provided any existing pull-up to 5 V is removed or isolated.
A 74HC244 powered at 5 V does not provide 3.3 V level conversion. Verify A and B
voltage levels before attaching them to the FPGA. All grounds must be common.

## Operation and adjustment

Insert a coin and start a game. Attract deliberately ignores the position input,
as described by TM-035's Figure 11 control-switch circuit. Turn the spinner to
move only Solid Forwards. The board reset button recentres the spinner counter;
it retains its existing separate core-button function.

The board wrapper exposes these generics (edit defaults and rebuild):

| Generic | Default | Effect |
| --- | --- | --- |
| SPINNER_POSITION_MIN | 82 | Top endpoint, in existing ramp/scanline units |
| SPINNER_POSITION_MAX | 154 | Bottom endpoint |
| SPINNER_STEP_SIZE | 32 | Counter increment per A rising edge |
| SPINNER_REVERSE | false | Set true to reverse movement, or swap A and B |

The raw counter is 0–1023, starts at 512, and saturates at both ends. With step 32,
full travel takes 32 A rising edges (4× the movement of the former step-8 default).
This is not necessarily one shaft revolution.
Both phases pass through three synchronization registers. Startup seeds the
phase history without counting. Only an A rising edge with unchanged B counts;
simultaneous two-bit jumps are rejected. This is x1 decoding, not a mechanical
switch debouncer. It assumes clean optical encoder phases; electrical noise
that resembles a valid transition can still count.

With normal direction, B high on an A rising edge increases the count and moves
the forwards down. The position mapping is:

    POSITION_MIN + round(count * (POSITION_MAX - POSITION_MIN) / 1023)

The adapter runs from the same CLOCK_7 as the game. It publishes the mapped
position at the rising edge of VSYNC, avoiding mid-frame comparator retriggers
and a multibit clock-domain crossing. A count on that same edge takes effect on
the following frame. A 0–1023 value must not be sent directly to the player
comparator: the digital ramp reaches only approximately 256.

The other three core position inputs retain their previous fixed defaults.
The two forwards move together and keep their existing spacing. Adjust the limits
so the upper forward clears the top wall and the lower forward clears the bottom
wall. Physical spinner sensitivity, direction and electrical operation require
hardware testing; simulation cannot verify the actual encoder wiring.

## Verification

Run `cd sim && SPINNER_TEST=true bash run_sim.sh` for the spinner regression and
full-game sweep. The default (without SPINNER_TEST) retains the original static
position capture. The unit test checks startup in all four phase states,
direction/reversal, invalid jumps, saturation, leaving each end stop, frame
latching and reset. The sweep test exercises real A/B pulses through the adapter
and asserts both mapped endpoints during paid play.

`sim/gameplay.gif` contains the sweep when SPINNER_TEST=true. `python3 check_spinner_frames.py` (from `sim`) checks and renders the captured
endpoints as `spinner_limits.png` and saves a separate `spinner_gameplay.gif`.
At the top limit the forwards occupy raster rows 77–91 and 144–158; at the bottom
limit, rows 149–163 and 216–230. The field interior spans rows 77–232. Both
15-line symbols remain inside it. The top symbol touches the inside edge of the
upper wall at the minimum; increase SPINNER_POSITION_MIN for extra clearance.

Quartus 13.0 SP1 synthesis/fitting passed with 1,465/4,608 logic elements. The
fitter confirms spinner A/B on pins 42/43. TimeQuest reports hold/removal violations
(worst slow-model hold slack −29.541 ns) and unconstrained clocks. Timing closure
is not established; this build is for the requested hardware test. During the build the
existing `KickSolid_I` QSF spelling was corrected to `KickSolids_I`, retaining
its intended pin 57 (checked kick remains on pin 58).
