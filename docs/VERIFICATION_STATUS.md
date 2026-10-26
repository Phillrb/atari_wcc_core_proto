# Verification status — updated 26 October 2026

This record separates fresh review results from existing build artifacts and
owner observations. The [work queue](IMPLEMENTATION_PLAN.md) lists the next steps.

## Current build and hardware evidence

- Acceleration is connected and the Figure 15 decoder is corrected. The 24 October
  run `output_files/build_runs/20261024T205243Z-l_3p021s/` passed all 15 stages,
  including ball/score/speed routing and local timing, focused regressions and
  full video capture. PNG and GIF keyframes were inspected.
- Fitter: 3,113/4,608 logic elements (68%), 619 registers. Whole-design timing
  remains incomplete. See [acceleration evidence](HIT_ACCELERATION.md).
- Exact programmed POF SHA-256:
  `7c276209a4eca2c7c1171acf090d7932f13696cfcac2b06ed407da264a5e19e6`.
  Active Serial backup/program/verify succeeded; this proves stored flash
  contents, not gameplay correctness. Latest-image physical checks remain pending.
- Pin 7 credit lamp is implemented and simulation-tested. LED0 retains the
  catch diagnostic and sound is enabled. Physical lamp confirmation remains pending.
- The owner confirmed working catches/kicks on the audible diagnostic POF
  `54b6387520f11dfeeb0e04fde3f077bfbe623515081f8c56e2bb408d962fe2fd`,
  as well as the earlier silent diagnostic. The normal restored image failed
  catching. The underlying fitting-sensitive cause is unresolved; confirmation
  of those diagnostic images does not transfer to later fits.
- Build/test and programming automation are implemented. Source snapshots and
  SHA-256 manifests are retained with each run; see [workflow](BUILD_AND_TEST.md).

## Historical review baseline — 22 October 2026

The remaining sections preserve that review's measurements. Resource counts,
unconstrained-clock counts and image provenance below apply to that baseline,
not the current image.

## RTL review baseline

Source HEAD at review: `6ccf701cfc8d49318bff9a49f95bcc6c0fd69dcd`.
The only pre-existing tracked edit was QSF whitespace/newline formatting.

All eight focused runners passed during review:

```bash
bash sim/run_control_tests.sh
bash sim/run_player_mode_tests.sh
bash sim/run_catch_timeout_tests.sh
bash sim/run_score_tests.sh
bash sim/run_vertical_ball_tests.sh
bash sim/run_spi_tests.sh
bash sim/run_sound_tests.sh
bash sim/run_moving_hole_tests.sh
```

The full `cd sim && bash run_sim.sh` capture also passed at 650 ms, including
coin/start/serve/expiry assertions. The paid-play PNG and six gameplay GIF
keyframes were inspected. The focused moving-hole fixture measured 998 complete
fields with sampled opening starts at 83..224, constant 16-line width and repeated
reversals without wrap. The short full-core capture does not prove full sweeps.

Review baseline output SHA-256 values:

```text
frame_output.png  f025e6b202db7e755316bdd83f29b3dfb7e90c82b44572430ba45a250f5e3a84
gameplay.gif      ed50c19935bea3b3e5e962dcaf24fec0820f703c239d74b6881a92a262ee1d82
```

## Existing local Quartus artifacts

Reviewed reports, not a new compilation during this review:

- `output_files/atari_wcc.fit.summary`: successful, dated 22 October 2026;
  Quartus 13.0.1 SP1, EP2C5T144C8, 3,108/4,608 logic elements (67%), 619 registers.
- `output_files/atari_wcc.sta.summary`: positive slack for every listed check;
  minimum listed hold slack +0.215 ns at the fast corner.
- `output_files/atari_wcc.sta.rpt`: 32 unconstrained clocks, seven unconstrained
  input ports and seven unconstrained output ports. This is incomplete timing
  coverage, not whole-design timing closure.
- `python3 sim/check_ball_routing.py` and `python3 sim/check_score_routing.py`
  passed against the existing fit during review.

Existing `output_files/atari_wcc.sof` SHA-256:

```text
974f039f6dd8302637e5db0ddf1111097287cd1b5f8d17576608ab5b6faf75cc
```

The exact source commit used to build that SOF is not recorded. Do not infer it
from the review HEAD or equate this file with the owner's currently programmed
image. A cleanup simulation does not regenerate or validate the bitstream.
Older documents' utilization and negative slack values describe earlier builds.

## Hardware observations and remaining evidence

The owner confirmed hardware video on 24 September, goal counting on 18 October,
and reports on 22 October that the project is working well and playable. These
are useful hardware observations; no new physical test was performed by this
review. A commit/hash-linked checklist for the latest image remains to be recorded,
including sound, controls, catch release and complete one-player hole sweeps.

For each future hardware validation, record:

| Field | Required detail |
| --- | --- |
| Source | Commit plus any uncommitted functional changes |
| Build | Quartus version, device, SOF hash and retained artifact location |
| Timing | Constraint coverage, routing guards, setup/hold and fitted test results |
| Board | Date, tested modes/scenarios, observations and remaining issues |

Temporary `/tmp` investigation paths in historical notes are not durable release
artifacts. Preserve needed evidence before relying on it for future comparisons.
