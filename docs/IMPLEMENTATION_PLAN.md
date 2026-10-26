# Atari WCC — next steps

Updated 26 October 2026 after acceleration, credit-LED and automation work. This is the current work queue;
older diagnosis and handoff documents preserve historical evidence. Follow
[AGENTS.md](../AGENTS.md) for implementation rules and TM-035 for circuit wiring.

The owner reports that the game is working well and playable. All major circuit
groups are integrated. The formerly disconnected speed increment input is now integrated. Remaining
priorities are build-sensitive catch reliability, hardware validation and fidelity. See [verification status](VERIFICATION_STATUS.md)
for the distinction between RTL tests, existing fitted reports and hardware reports.

One-player mode is complete per project-owner confirmation on 26 October 2026.
The verification and fidelity tasks below remain separate from functional completion.

## Ordered work queue

### 1. Repository consolidation

- [x] Replace the obsolete phase plan with this prioritized queue.
- [x] Refresh README and agent-facing status, clock and ball-shape information.
- [x] Archive the unused, invalid `IC/ControlsSPI.vhd` draft outside compiled sources.
- [x] Ignore Quartus workspace state and remove `atari_wcc.qws` from version control,
  retaining the local file.
- [x] Remove unused `video_playfield` and `video_timeline` signals; their source
  signals already feed the visible output through `ScoreCircuit`.
- [x] Label superseded investigation notes and preserve source/diagnostic evidence.
- [ ] Verify the cleanup with the full simulation, compare PNG/GIF to the review
  baseline, and commit locally. Do not include the pre-existing QSF edit.

### 2. Verify hit-driven horizontal acceleration on hardware

Figure 13 D8 pin 9 now feeds Figure 15 F6/B6. The pin-number audit also
corrected crossed counter/XOR inputs in the existing speed decoder. RTL tests
cover ordered levels, saturation, presets, defender exclusion and STOP.
See [the wiring and verification record](HIT_ACCELERATION.md).

- Confirm catch/kick and progressive rally speed on the new FPGA image in
  both game modes, including reset after goals.
- Retain the fitted-event-clock and cross-domain timing limitations recorded
  in the verification document; local B6 checks do not prove whole-design closure.

### 3. Resolve build-sensitive catching and complete timing coverage

The owner confirmed catch/kick on the audible diagnostic image, but removing
its LED connection produced a failing fit. Retaining the LED is not a root-cause
fix. Establish a reproducer and check the collision/catch paths across fits.


The local 22 October reports have positive slack for their reported constrained
checks, but list 32 unconstrained clocks and unconstrained I/O. Successful fitting
and playable hardware do not establish coverage of these paths.

- Inventory ripple/event clocks and clock crossings, starting with moving-hole
  feedback, collision consumers and the restored speed counter.
- Add justified constraints and focused slow/fast fitted tests. Do not silence
  warnings with blanket false paths; document any legitimate exceptions.
- Retain the existing ball, score and speed routing/setup/hold guards.
- Record commit, local changes, tool version, SOF SHA-256 and hardware results
  together. Recent builds preserve source snapshots, manifests and exact image hashes.
  Physical results still need to be linked to each new image.
- Exercise both modes, multiple moving-hole reversals, repeated scoring, catches
  from both sides, kick/timeout, timer expiry, controls and sound on the board.

### 4. Consolidate regression execution

- [x] Provide one documented entry point: `scripts/build_and_test.py` snapshots
  sources and runs suites sequentially with summaries and failure logs.
- [x] Provide Active Serial backup/program/verify via `scripts/program_as.py`.
- Audit older IC tests (`tb_jkff`, `tb_LS83`, `tb_LS92`, `tb_LS93`, and other tests
  absent from current runners). Replace legacy component instantiation with
  direct entities and require actual assertion/completion evidence.
- Keep coverage explicit: automated Quartus timing guards are included; optional
  ModelSim fitted simulations have separate prerequisites.

### 5. Fidelity and calibration

These are documented approximations/adaptations, not newly demonstrated gameplay
failures. Audit them against sources or measurements before changing behavior.

| Area | Follow-up and existing evidence |
| --- | --- |
| Player layout | Audit the uniform-spacing J6/L6 changes and related BLIP guard together; see [one-player history](ONE_PLAYER_HANDOFF.md) and [rear catch correction](REAR_CATCH_TIMEOUT.md). |
| Analog functions | Calibrate player ramp/555 models, timer-line window and [M9 sound estimates](SOUND_CIRCUIT_FIG20.md); retain tested gameplay while documenting model boundaries. |
| Raster and ball | Preserve the approved [clock choice](MASTER_CLOCK_AND_VIDEO_ADOPTION.md), [vertical presets](VERTICAL_BALL_313_LINE_ADAPTATION.md), [horizontal STOP preset](CATCH_STOP_DIAGNOSIS.md) and [carry/routing repairs](VERTICAL_BALL_TIMING.md). |
| Moving hole | Preserve the approved [6/8 presets and boundary sampling](MOVING_HOLE_FIG18.md); Figure 18 drawing/prose reconciliation remains a source question. |
| Video output | The MaSTer/Sprint2 output works; recreating the original Figure 22 resistor network remains fidelity work. |
| FPGA adapters | Keep the [collision sampling](COLLISION_TIMING_HANDOFF.md), registered carries and top-level MISS qualification explicit in documentation. |

## Completed integration

Clock/sync, playfield, coin/start/credit, runtime game selection, timer/serve,
players and controls, ball/catch/bounce, moving hole, score, sound and board video
are all integrated. Figure 12 controls serving; the old custom 13 ms serve
process has been removed. Ball shape and catch drift have received specific
RTL/fitted repairs; the old claim that diagonal skew is unavoidable is obsolete.

Current board and full-core simulation use a 14.285714 MHz master clock and
7.142857 MHz pixel clock, with 455 clocks per line and 313 lines per field.
The original nominal master clock is 14.318180 MHz.
