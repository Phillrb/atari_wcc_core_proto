# Credit indicator on FPGA pin 7

The owner selected FPGA pin 7 for the credit LED. `CreditLEDn` is an
active-low output, matching the existing LED0 convention. Physical LED
polarity and operation must be confirmed on the board.

TM-035 Figure 8 connects A9 pin 8 (the complemented credit-expired state)
to A8 pin 9. A8 pin 8 sinks the red Start-button LED through R31 (220 ohms)
and connector H. `CreditCircuit.vhd` now explicitly instantiates this LS04
gate and exports `CREDIT_LEDn`, routed through the core and board wrapper.
The board's existing LED hardware supplies its own electrical interface.

The lamp is off at power-up, comes on when a valid coin establishes credit,
remains on during play, and turns off when the purchased games are exhausted.
The board selects one game per coin. The credit regression also checks two
games per coin, including the lamp staying on after the first game. The lamp
uses A9's state, not C9's coin-contact-gated start-enable output.

LED0 on pin 3 retains the hardware-confirmed diagnostic connection: either
kick button in one-player mode, STOP in two-player mode. Sound remains enabled.
The owner confirmed the audible diagnostic POF beginning `54b6387520f11dfee`
has working catch/kick. Adding another output changes the FPGA fit, so this
new image needs physical catch/kick confirmation too; the previous known-good
image is preserved at `output_files/atari_wcc_catch_debug.pof`.

## Build validation

Full automated run: `output_files/build_runs/20261024T203931Z-w57j5wnq/`.
All 12 stages passed, including credit, catch timeout and sound tests, targeted
ball/score timing, and full video simulation. The paid-play PNG and six GIF
keyframes were visually inspected: field, players, ball and game-state
transitions are intact. The diagnostic LED truth-table test also passed.
Quartus reported 169 warning lines; whole-design timing remains incomplete.

POF SHA-256:
`e8af230ef82337b107332844325f84ceafef4759c3f7d4a5327f56abd01d9015`.

Active Serial flash programming and verification passed. Backup/logs:
`output_files/as_program/20261024-214506-sfr0q4k1/`.
Physical LED and catch/kick confirmation after power-cycle remain pending.
