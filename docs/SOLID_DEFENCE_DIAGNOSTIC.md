# Solid defence hardware diagnostic

The board showed moving controls for all groups except solid defence. Swapping
the solid/checks defence inputs in the board wrapper left the failure on solid
defence. This points downstream of the SPI position channel. The normal control
mapping has now been restored.

The fitted Quartus netlist retains the position comparator and the diagnostic
swap, so the input was not simply optimized away. Ideal RTL simulations also
move the solid defenders and goalie across all 73 calibrated positions.

## Candidate correction: N8 pulse output

Figure 11 and the defence description in TM-035 identify N9 as the comparator
enabling N8, with N8 pin 3 driving J8, M7's load input, and the symbol gating.
The existing digital approximation decoded N8 pin 3 combinationally from the
ramp comparator and a modulo expression over the phase counter. Quartus inferred
a combinational divider for this expression. Intermediate ramp values can thus
change the visible symbol between HSYNC edges; ideal simultaneous-bit simulation
does not exercise those transitions.

`PlayersSolidDefenseGoalie.vhd` now registers N8 pin 3 on HSYNC, decoding the
next phase to retain the calibrated scanline geometry. This is a change to the
existing analogue approximation, not a change to the documented TTL wiring.
The comparator is sampled at that edge; between-edge changes take effect at the
next edge. The three pulse intervals and attract/play delay values are unchanged.

`tb_SolidDefensePulse.vhd` injects a 10 ns low ramp transient during the initial
delay. The old version emits an erroneous E1 pulse and fails the assertion;
the registered version passes. The existing player-travel regression verifies
all 73 positions, symbol sizes, and attract layout.

This demonstrates a transient-sensitivity defect, **not proof that it caused the
reported stationary defence**. No board capture of the failing signals is yet
available. Test the rebuilt design on the board with the normal control mapping.
If the group remains stationary, capture POSITION, comparator_out, phase_count,
N8_3, M7 count/RC and H8 Q1/Q2 on hardware before further circuit changes.
The project also has unconstrained generated clocks and existing timing failures;
functional simulation and a successful fit do not establish timing closure.

Validation: the SPI/travel tests pass; the injected transient test fails against
the prior source and passes against this version. The full SPI video simulation
and frame checks pass, and `frame_output.png` and `spi_limits.png` were visually
inspected. `spi_controls.gif` captures the movement. Quartus 13.0 SP1 full
compilation completed with zero errors (158 warnings); slow-model hold slack is
-23.143 ns and removal slack is -15.514 ns, so timing closure remains unresolved.
