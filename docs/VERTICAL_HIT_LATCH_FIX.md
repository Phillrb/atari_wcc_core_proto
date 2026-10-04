# Ball steering without player contact: D7 latch correction

Figure 14 connects C6 pin 12 (HITn) to D7 pin 1. D7 should accept
PP2/PP3/PP4 only during a hit, then retain the segment code between hits.
The manual's "Vertical Direction and Speed Circuit" section describes this
explicitly. The wiring in `VerticalDirectionAndSpeed.vhd` already matches
`diagrams/14_Vertical_Direction_Speed_Circuit.png`.

The former `IC9314.vhd` ignored pin 1 in its logic. With the three S inputs
grounded, D7 continuously followed player segment data, allowing player movement
to change the ball's vertical motion even while HIT was low. Its comments also
incorrectly described pin 1 as a tri-state output enable.

The National Semiconductor truth table in `IC/data/9314.PDF`, page 3
([online copy](https://www.teledynedefenseelectronics.com/e2vhrel/Signal%20Chain%20Datasheets/Documents/NSC_9314.pdf)),
defines pin 1 as a common active-low latch enable. The corrected model implements:

- MRn low: clear all outputs, regardless of enable.
- Enable high: hold all stored outputs.
- Enable low: D low resets; D high and Sn low sets; D high and Sn high holds.

The existing `P1_OEn` port name remains for compatibility. Outputs are actively
driven in both enable states. No additional collision gates or motion filtering
are introduced.

## Regression evidence

`tb_VerticalHitHold` connects the Figure 17 hit gate to Figure 14. It failed on
the old model at 100 ns with "player data changed ball speed without contact".
With the corrected model it passes: all eight player codes are held without
contact, both player-only and ball-only pixels leave speed unchanged, and real
overlap loads the segment code. Wall bounce, STOP/release and serve reset are
also checked.

`tb_IC9314` uses direct entity instantiation and checks all 16 previous output
patterns, all four channels and all 16 binary MR/E/D/S combinations. It also
checks transparent data changes, output retention, and reset release with enable
high. This replaces the old component-instantiated test that expected incorrect
tri-state behavior.

Both regressions run automatically in `sim/run_sim.sh`. Run
`cd sim && SPINNER_TEST=true bash run_sim.sh` for the full coin/start/spinner
sweep, endpoint checks, `frame_output.png` and `spinner_gameplay.gif`.
Hardware behavior still needs confirmation after rebuilding and programming the FPGA.
