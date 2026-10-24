# Figure 15 goalie/forward hit acceleration

The integrated core now connects Figure 13 D8 pin 9 (`catch_trigger_i`) to
Figure 15 F6 pin 10 (`GOALIE_FWD_HIT`). The original constant-high connection
prevented hit-driven counting. This is the existing sampled D8 catch latch,
not raw HIT and not J5 STOP: the collision sampling and catch timer are retained.

## IC path

- E8 (7400) pins 9/10 -> 8 qualify BALL/BLIP and preset D8 pin 10.
- C8 (7400) pins 4/5 -> 6 qualify HIT/DEFENSEMENn and clear D8 pin 13.
- D8 (7474) pin 9 falls on a qualified catch; its clock pin 11 is tied low.
- D8 pin 9 -> F6 (7400) pin 10; SCORE_SOUNDn -> F6 pin 9.
- F6 pin 8 -> B6 (9316) pin 2. A falling input produces a rising count clock.
- B7 (7402) pins 11/12 -> 13 combine GOAL/ATRC into B6 load pin 9.
  Score-sound supplies the clock for synchronous loading after a goal.
- B6 presets zero in two-player mode, four in one-player mode. Pin 15 terminal
  count -> C6 (7404) pin 9 -> pin 8 -> B6 enable pin 7, inhibiting count at 15.
  C6 pin 8 also supplies SLOW to the existing sound envelope selector.
- F5/A6 (7408), A5 (7486) and B5 (7483) gate and decode count/direction.

## Corrected decoder wiring

Follow the actual numbered pins in Figure 15; its C/D lettering and the prose
are misleading relative to the 9316 pinout. The existing VHDL had crossed
counter-bit and XOR connections:

| Source | Destination |
| --- | --- |
| B6 pin 12 (QC, bit 2) | A6 gate 2 -> A5 gate 1 -> B5 pin 11 (B1) |
| B6 pin 11 (QD, bit 3) | C6 pins 3 -> 4 -> A6 gate 3 -> A5 gate 4 -> B5 pin 7 (B2) |
| B6 pin 11 (QD, bit 3) | A6 gate 4 -> A5 gate 3 -> B5 pin 4 (B3) |

These yield motion offsets 2, 3, 4, 5 for count groups 0–3, 4–7, 8–11,
12–15. With the approved stationary preset 9, the two directional codes are
9 + offset and 9 - offset. STOP or inactive VRESET still produces 9. The old
wiring instead decoded offsets 4, 2, 5, 3. No new behavioral game logic was added.

Each distinct catch advances the counter; the visible speed level changes at
counts 4, 8 and 12. Counting saturates at 15, where SLOW goes low. A held
contact without rearming D8 must not advance it again. Defenders do not clear
D8 and therefore do not advance this counter.

## Verification scope

`sim/run_acceleration_tests.sh` checks the core connection and exercises the
sampled Figure 13 circuit with Figure 15: both team polarities, defender
exclusion, repeated HIT without rearming, four ordered speed levels in both
directions, saturation, one/two-player presets, goal reset, attract loading,
STOP and VRESET gating. Existing sound tests cover the SLOW envelope selector.

The build runner includes this regression and B6 routing/setup/hold guards.
The SPEED_HIT constraint is a conservative 280 ns event-clock envelope for
local B6 feedback. It does not prove upstream event-clock glitch immunity or
whole-design timing closure. Hardware confirmation is required for catch/kick
and rally progression on the new fit.

## Validated build

Run: `output_files/build_runs/20261024T205243Z-l_3p021s/`.
All 15 automated stages passed. Full-core PNG and six GIF keyframes were
visually inspected: field, players and ball are intact. Negative-control tests
also confirmed that the old decoder fails the ordered-level regression and
the tied-high input fails the integration check.

B6 worst local slack (ns): slow setup 276.982, slow hold 0.499,
fast setup 279.028, fast hold 0.215. Quartus reported 169 warning lines;
these targeted results are not whole-design timing closure.

POF SHA-256:
`7c276209a4eca2c7c1171acf090d7932f13696cfcac2b06ed407da264a5e19e6`.

Active Serial programming and flash verification succeeded. Logs and previous
flash backup: `output_files/as_program/20261024-215753-kz8l0h22/`.
Power-cycle and physical catch/kick, rally acceleration and goal-reset checks
in both modes remain pending.
