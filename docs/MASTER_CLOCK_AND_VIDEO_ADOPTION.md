# WCC board clock and Sprint2 video pinout

Quartus uses `atari_wcc_board` on the EP2C5T144C8. The onboard 50 MHz oscillator enters on pin 17 and feeds `Altera/clk_pll.vhd`. The PLL generates 14.285714 MHz (multiply 2, divide 7); the core's Fig. 3 LS74 divides this to 7.142857 MHz.

The manual specifies 14.318180 MHz. The board clock is intentionally 0.2268% slower, approved for this board configuration. Quartus 13.0 SP1 rejected the exact 756/2640 ratio and its reduced 63/220 form. A two-PLL 50 -> 35 -> 14.318182 MHz experiment also failed routing on this device. The checked-in implementation uses one PLL and passes fitting.

## Board pins

These match the working `../MaSTer/Sprint2v1/sprint2/sprint2.qsf`, rather than the different generic MaSTer README pinout.

| Signal | Pin | Connection |
| --- | --- | --- |
| Clk_50_I | 17 | Onboard 50 MHz oscillator |
| Sync_O | 92 | Core composite sync |
| VideoW_O | 86 | Core active-high video |
| VideoB_O | 74 | Constant low |
| Reset_I | 144 | Active-low board button, pull-up enabled |
| LED0 | 3 | Core LED output |
| Clock_out | 80 | 7.142857 MHz debug clock |

Use the same external composite resistor network as Sprint2. No separate H/V sync pins are exposed by this wrapper. The board button retains the existing core button/LED behavior; it is not a new game reset implementation.

## Simulation and verification

The core `atari_wcc` takes `CLOCK_14` as an input, keeping Altera PLL primitives out of GHDL simulation. `testbench/tb_atari_wcc.vhd` uses a 70 ns period to match the board PLL. Run `cd sim && bash run_sim.sh` for video snapshots.

Run `quartus_sh --flow compile atari_wcc` for the board build. `atari_wcc.sdc` constrains the 50 MHz input, derives the PLL clock, and describes the Fig. 3 divided clock. This is not a complete timing model for the game's many TTL ripple/gated clocks; remaining unconstrained-clock and I/O warnings require a separate timing review. A successful build does not establish full timing closure or CRT hardware validation.
