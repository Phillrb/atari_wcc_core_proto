# One-player correction handoff — 2026-09-30

## Required result

Use `diagrams/A_Playfield_Player_vs_Game.png` as the visual acceptance reference:
one solid goalie on the left, two solid forwards in one column, no solid
defenders and no checked players. The left goal stays fixed. The right-hand
16-line opening must travel upward, reverse at the upper playfield limit,
travel downward, and reverse at the lower limit repeatedly, without wrapping.
A passing compilation or a screenshot containing an opening is not sufficient.

## Work already committed

- `d2d3c7d`: Figure 18 netlist, integration, optional original-74107 mode for H1,
  static one-player generic, circuit tests and diagnostic renderer.
- `1817336`: MovingHoleCircuit formatting matches PlayfieldCircuit: IC_ labels,
  aligned active pins, grouped unused pins and pin-level comments.
- User approved an optional original-74107 master/slave mode for H1. Seven
  other circuit files retain the existing LS107 default. Do not change them
  globally as part of the moving-hole repair.

## Easiest confirmed correction: missing player-window mode connection

`atari_wcc.vhd`, instance `U_PLAYERS_VW`, had `PLAYER => '0'` even when
`ONE_PLAYER_MODE='1'`. Figure 11 already provides the required checked-team
suppression: TEAM and PLAYER feed F6 gate 1, then H6/J6 disable H7's symbol
window for the checked team. The manual describes this immediately after
Figure 11. Connect PLAYER to the same static mode generic already used by
PlayersSumming, WindowMissBounce, CatchKick and HorizontalDirectionAndSpeed.
This adds no gates and changes no schematic pin connections within Figure 11.

PlayersSumming already receives ONE_PLAYER and implements J2/J1/M1 suppression
of solid defenders. Verify the resulting visible players, rather than assuming
DEFENSEMENn identifies the right columns.

Status for this session: connection corrected to ONE_PLAYER_MODE. One-player
video now contains the required three solid player symbols; see results below.

## Remaining work: real game-selection distribution

The static generic is a diagnostic/configuration selection, not a complete
Figure 10 implementation. It remains asserted during attract. Figure 10 gates
ONE_PLAYER with active play so attract uses the two-team display.

Inspect `diagrams/10_Game_Select_Circuit.png` before changing GameSelectCircuit:
its current implementation substitutes an LS74 for the drawn cross-coupled D9
inverters and uses C5 pins 9/10/8 instead of the drawn 12/13/11. It also uses
loose inversions. Correct the switch latch and play-enable path with explicit
IC entities, test both switch positions and attract/play transitions, then
route one effective ONE_PLAYER signal to all five gameplay consumers.
The credit circuit's ONE_PLAYER input is currently the one-game-per-coin
configuration: review Figure 8 separately before treating it as gameplay mode.

## Remaining work: moving-hole reversal (not fixed)

Current implementation loads M4:L4 with C9 or CB. Figure 18 was read as L4
pins 3 and 6 high, pin 5 low, pin 4 from K1 Q; the user agreed that it looks
that way. This is an image interpretation, not proof that the resulting
behavior is correct. Preserve the uncertainty and recheck source evidence.

With current models, first HOLE begins at rising HSYNCn edge 496 after reset,
lasts 16 lines, and repeats every 311 or 309 lines. The core has been measured
as 313 lines per frame. Both periods move the hole upward; K1 changes speed
instead of reversing it. Existing long tests explicitly accept those periods
and wraparound: they document the implementation, NOT correct gameplay.

Required investigation, before inventing new preset connections:

1. Cross-check Figure 18 against App_Full_Schematic_1/2.png and the original
   PDF. Distinguish actual drawing, OCR mistakes and possible board variants.
2. Recheck Figure 5 and VerticalSync reset timing, measuring complete frame
   periods. Do not change frame timing merely to make the hole appear to bounce.
3. Verify original 9316 load/count/enable/carry semantics against the model.
   Count the synchronous reload edge explicitly. Recheck H1's master/slave
   sampling at simultaneous L4/M4 carry changes; absence of delta glitches
   alone does not prove the model matches the original IC.
4. Trace F3 clock, K1 Q, V128, both TC signals, H1 Q, LDn and HOLE through both
   boundary overlaps. Confirm the captured state selects the correct direction.
5. For a 313-line raster, 312/314-line recurrence would give opposite one-line
   drift. This is a diagnostic target only, not authorization to change presets
   without schematic evidence. Reversing K1 polarity alone cannot fix two
   periods that are both shorter than a frame.
6. If sources remain ambiguous, ask the user to clarify the specific pins or
   board timing. Do not replace the TTL netlist with a behavioral animation.

The manual's prose contains mutually inconsistent 261/263, 262, 312/314 and
9/6/8 numbers. `docs/MOVING_HOLE_FIG18.md` records the current implementation;
it must not be treated as evidence that the gameplay is complete.

## Existing player-layout deviations requiring audit

PlayersVerticalWindow deliberately changes J6 decoding and L6 inputs to force
uniform 48-pixel spacing, adding an XOR relative to the schematic. Audit TEAM,
GOALIE, DEFENSEMENn and mux selection together before deciding whether to keep
or undo those changes. Do not assume a visually symmetric arrangement is the
original layout. The manual lists left goalie/defenders/forwards at H152/200/296
and right goalie/defenders/forwards at H392/344/248.

## Verification for completing all corrections

- One-player paid play: exactly three solid symbols in the expected roles;
  no checked symbols and no solid defenders.
- Two-player paid play: both complete teams remain.
- Attract: original two-team behavior regardless of selected play mode.
- HOLE remains 16 lines wide and reverses at both limits, without wraparound,
  for multiple complete up/down cycles; test restart as well.
- Cover player-window suppression and defender suppression in signal tests.
- Inspect actual full-core PNGs and a GIF, not only the signal diagnostic.
- Extend the current 300 ms accelerated game for full-core reversal evidence;
  the default 650 ms capture contains too little paid play for full sweeps.
- Replace/extend tests that currently assert 311/309 recurrence with desired
  movement assertions once the source-backed correction is established.

## Commands and artifacts

```bash
bash sim/run_player_mode_tests.sh
bash sim/run_moving_hole_tests.sh
cd sim
ONE_PLAYER=1 bash run_sim.sh
bash run_sim.sh
```

The full simulation captures 650 ms by default and asserts coin/start/serve/
expiry behavior. ONE_PLAYER=1 retains `moving_hole_core.png` and
`moving_hole_core.gif`; each run overwrites frame_output.png and gameplay.gif.
The focused 400-field diagnostic produces moving_hole_timing.png and
moving_hole.gif. Generated artifacts are ignored by git; reproduce them locally.
Do not edit run_sim.sh while it is executing: a previous in-place edit changed
bash's read offset and interrupted rendering even though simulation passed.

Sandbox commands have failed with `mountinfo path is not absolute`; use explicit
escalation requests when necessary. Image viewing has the same sandbox issue;
loading PNG bytes through an approved command and emitting them worked.
Unrelated pre-existing untracked files include atari_wcc.qws and sim/frame_initial,
frame_plus1..5 and frame_post_serve PNGs. Leave these alone.

## This session's final verification

- `bash sim/run_player_mode_tests.sh` passes. The new test exercises four full
  horizontal lines in both modes with actual HorizontalSync and
  PlayersVerticalWindow instances. It asserts that checked windows are
  suppressed in one-player mode, solid windows are preserved, role decoding is
  unchanged, and both teams have active windows in two-player mode.
- `cd sim && ONE_PLAYER=1 bash run_sim.sh` completed its 650 ms capture and
  coin/start/serve/expiry assertions. Inspected frame_output.png and GIF frames
  12, 16 and 20: one left goalie, two solid forwards, no checked players or
  defenders. The 2x frame 20 contains three filled 8x30 player rectangles at
  x/y bounds (208,274)-(216,304), (496,190)-(504,220) and
  (496,324)-(504,354), using exclusive upper bounds. These are observed image
  coordinates, not new schematic coordinates or permanent gameplay constants.
- The one-player PNG/GIF are retained in sim/moving_hole_core.png and
  sim/moving_hole_core.gif; default-mode runs do not overwrite those copies.
- `cd sim && bash run_sim.sh` also completed the 650 ms capture and all
  control assertions. Inspected the default two-player frame; it is pixel-identical
  to the pre-fix default paid-play PNG saved before the one-player run.
- No IC models, presets, player spacing or game-selection logic were changed.
  Only the missing top-level mode connection was corrected. Attract gating and
  moving-hole reversal remain open; do not describe overall one-player mode as
  complete.

Recommended next step: correct and test Figure 10 game selection, including
attract gating, before replacing the static mode connections with its output.
Then perform the source/timing reconciliation for the moving hole described
above. The player-layout audit remains necessary for full schematic fidelity.
