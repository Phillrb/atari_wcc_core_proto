# ATtiny84 SPI player controls

`SPIAdapter.vhd` replaces the temporary quadrature-spinner input in the board
wrapper. The ATtiny measures four resistive controls; the FPGA is SPI master.
The existing `SpinnerAdapter.vhd` and its tests remain available for reference.
The untracked `IC/ControlsSPI.vhd` draft is not compiled or modified: it has
syntax/counter-range defects, lacks the firmware's inter-byte pauses, and
suppresses the final SCLK rising pulse when leaving its transfer state.

## Wiring

Disconnect the old encoder from pins 42/43 before using this build: they are now
outputs. These numbers identify FPGA package pins, not header positions.

| Signal | FPGA port | FPGA pin | ATtiny84 PA/PB | ATtiny84 14-pin package |
| --- | --- | --- | --- | --- |
| Chip select, active low | ControlsCSn_O | 42 | PB2 | 5 |
| Clock | ControlsSCLK_O | 43 | PA4 / USCK | 9 |
| Master to slave data | ControlsMOSI_O | 44 | PA6 / DI | 7 |
| Slave to master data | ControlsMISO_I | 45 | PA5 / DO | 8 |
| Ground | Board GND | Board ground connector | GND | 14 |

The user confirmed the ATtiny runs at 3.3 V. Use a common ground and connect
the four signals directly: all FPGA signals are 3.3 V LVTTL. Keep the ATtiny
supply and SPI levels at 3.3 V. Remove the Nano as bus master before connecting the FPGA.
MOSI carries dummy zero bytes but is provided as the fourth SPI connection.

## Channel order and ranges

The firmware packet is eight bytes: channel 0 high/low, channel 1 high/low,
channel 2 high/low, channel 3 high/low. No firmware modification is needed.

| ADC channel | ATtiny84 analog pin | Player control | Calibrated POSITION range |
| --- | --- | --- | --- |
| ADC0 | PA0, pin 13 | Solid defense and goalie | 10–82 |
| ADC1 | PA1, pin 12 | Solid forwards | 82–154 |
| ADC2 | PA2, pin 11 | Checks defense and goalie | 10–82 |
| ADC3 | PA3, pin 10 | Checks forwards | 82–154 |

The board's `CONTROL_ADC_MIN=700` and `CONTROL_ADC_MAX=1023` map to the complete
safe sweep, not to a raw 0–1023 POSITION. Readings below 700 clamp at the top;
readings at 1023 reach the bottom. Thus a measured 670–700 region is a deliberate
endpoint dead zone, about 8.5% of the observed ADC span (not necessarily knob
rotation). Lower CONTROL_ADC_MIN to 670 if that dead zone wastes useful travel.
Using a smaller ADC interval makes motion more sensitive and enlarges the dead
zones; it does not increase safe screen travel. With these defaults roughly
4.5 ADC counts move the group one scanline.

    position = top + round((clamp(raw, min, max) - min)
                           * (bottom - top) / (max - min))

The controls move each group together, preserving its spacing; it is not possible
for every member of a group to individually reach both walls while preserving
that spacing. The upper member reaches the upper boundary at one end and the
lower member reaches the lower boundary at the other.

The wrapper exposes CONTROL_DEF_TOP/BOTTOM and CONTROL_FWD_TOP/BOTTOM plus
SOLID_DEF_REVERSE, SOLID_FWD_REVERSE, CHECKS_DEF_REVERSE and CHECKS_FWD_REVERSE.
Reverse a control in VHDL if its physical direction is wrong. For independently
measured ADC endpoints, change the corresponding SD/SF/CD/CF_ADC_MIN/MAX generic
associations on U_CONTROLS; each channel is independently configurable inside
the adapter. Defaults start at the centre until the first valid packet.

## Figure 11 calibration boundary

The ramp and downstream TTL netlist remain in use. Two existing digital 555/RC
models had fixed initial gaps that prevented defense reaching the upper wall.
Their new PLAY_INITIAL_GAP generics default to the old 85/83 values, preserving
other users. The SPI board maps solid/checks gaps to 57/55 respectively. Attract
continues to use 85/83 and ignores control positions, preserving its layout.
These are calibration parameters of existing analog approximations, not a claim
that the original analog schematic has literal scanline delay constants.

## Protocol and failure behavior

- Mode 0, MSB first, idle-low SCLK. CLOCK_7 is 7.142857 MHz; a half-period of
  29 clocks yields approximately 123.15 kHz (not faster than the Nano's 125 kHz).
- Initial CS-high wait: about 100 ms. CS setup, inter-byte pauses and final hold
  are each at least 100 us, allowing the ATtiny's USI interrupt handlers to run.
- Every byte gets all eight rising AND falling clock edges. CS stays low for
  the complete eight-byte packet; then high for about 5 ms for fresh ADC scans.
  Total polling period is about 6.42 ms (~156 packets/s).
- MISO passes through a two-stage synchronizer. ADC packet data is validated
  before scaling: any nonbinary bit or 16-bit channel value above 1023 rejects
  the whole packet. An absent device with pulled-up MISO reads FFFF and is rejected.
- All four pending positions latch together at rising VSYNC. SPI and player
  logic share CLOCK_7, avoiding a multibit clock-domain crossing. A packet that
  completes on the same clock as VSYNC is applied at the following frame.
- Invalid packets retain the last good positions; reset recentres and restarts
  the boot delay. There is no checksum or connection timeout in the existing
  eight-byte protocol. In-range corrupt data (including a stuck-low wire) cannot
  reliably be distinguished from genuine readings.

Controls are active only after coin/start, as in Figure 11's attract defeat.

## Validation

`bash sim/run_spi_tests.sh` exercises the serial protocol against a delayed
wire-level ATtiny model, all readings 670–1023, channel order, clamping, reverse
mapping, packet rejection, frame-atomic publication, and reset mid-transfer.
It also sweeps all 73 travel positions through the actual four Figure 11 player
circuits, checks symbol sizes/positions and compares attract to the old delays.

`cd sim && SPI_TEST=true bash run_sim.sh` supplies all four ADC channels through
SPI during coin/start/play, sweeps minimum to maximum, and then applies mixed
values to prove independent control. It produces frame_output.png and gameplay.gif.
`check_spi_frames.py` runs automatically and saves `spi_limits.png` (top, bottom,
and independent-channel snapshots) and `spi_controls.gif`. All symbols remain
within raster rows 77–232: forwards reach rows 77–91/144–158 at the top and
149–163/216–230 at the bottom; defense reaches 77–91/145–159 and
149–163/217–231. Goalies span 111–125 through 183–197.

Physical wiring, the actual resistors' endpoint values and knob direction still
require hardware testing. Quartus fitting is checked separately from timing
closure; the project has reported hold/removal violations and unconstrained clocks.

Quartus 13.0 SP1 synthesis/fitting passed: 3,112/4,608 logic elements (68%).
The fitter confirms pins 42/43/44/45. TimeQuest still reports hold/removal
violations (worst slow-model hold slack −30.346 ns) and unconstrained clocks;
this is not a timing-closed release.
