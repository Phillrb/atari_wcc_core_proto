# One-command build and verification

From the repository root:

```bash
./scripts/build_and_test.py
```

This is the normal build/test entry point. It does not program the board. It
prints the run directory immediately, followed by short `START`, `RUNNING` and
`PASS` messages. On failure it prints the failing log's last 20 lines, writes a
failure summary and returns a nonzero exit code. A stage has a 30-minute timeout
by default; `--timeout SECONDS` changes it. Interrupting a running stage also
terminates its child processes and records the interruption.

## What it runs

1. Copy the current tracked and untracked, non-ignored source files into a
   fresh snapshot. Preserve local edits; record Git HEAD, dirty status and
   SHA-256 hashes of the actual copied sources.
2. Compile the snapshot with Quartus, requiring fresh SOF, POF and fitted netlist.
3. Check ball, score and acceleration clock routing and slow/fast setup/hold using the existing
   focused guard scripts.
4. Run control, sound, hit acceleration, catch timeout/traversal, moving-hole, player-mode and SPI
   regressions sequentially.
5. Run `sim/run_sim.sh`, including its component/circuit regressions and 650 ms
   two-player attract/coin/start/serve/game-expiry capture. This covers the existing
   score and vertical-ball suites without separately repeating their runners.
6. Verify the PNG/GIF are readable and generate a six-keyframe contact sheet.
   Record hashes of the SOF, POF and visual artifacts.

The scripts run inside the snapshot, so their shared simulation files cannot
collide with another build or with the working tree. The normal project's
`output_files/atari_wcc.pof` is not overwritten. The snapshot is retained with
its build, reports and video; no cached result is silently reused.

Existing standalone diagnostic/post-fit ModelSim runners and every older IC
testbench are **not** all included. The focused timing guards do not establish
whole-design timing closure. Full-core video currently uses two-player mode;
the moving-hole and player-mode suites provide separate one-player coverage.

## Results and efficient agent workflow

Each run lives in `output_files/build_runs/<UTC timestamp>-<unique suffix>/`:

| File | Purpose |
| --- | --- |
| `summary.txt` | Short status, stage results, log locations and artifact hashes |
| `report.json` | Machine-readable status, source revision, coverage and timings; updated atomically after stage transitions |
| `source_sha256.json` | Exact input file hashes, including uncommitted edits |
| `inputs.zip` | Source snapshot preserved before any tool can rewrite project settings |
| `NN_stage.log` | Detailed output for that stage |
| `source/output_files/atari_wcc.{sof,pof}` | Images built from this snapshot |
| `source/sim/frame_output.png` | Paid-play frame to inspect |
| `source/sim/review_keyframes.png` | Six gameplay keyframes to inspect |
| `source/sim/gameplay.gif` | Complete animation |

For future agents:

- Invoke the runner once and retain the printed run directory/session ID.
- Wait for its stage updates; avoid repeatedly reading large logs or issuing
  the underlying compile/test commands again.
- At completion, read `summary.txt`. Open only the failed stage log if needed.
- For `AUTOMATED_PASS`, inspect the PNG and contact sheet/GIF before reporting
  visual verification. The script deliberately leaves visual review pending.
- When programming is requested, pass the **exact POF path from that report**
  to `scripts/program_as.py`. Do not program a potentially older root-level POF.
- Record the owner's hardware observations against that POF hash.

Example after a successful run:

```bash
./scripts/program_as.py output_files/build_runs/<run>/source/output_files/atari_wcc.pof
```

`AUTOMATED_PASS` means the listed automated checks passed. It does not claim
human visual review, hardware testing or complete FPGA timing closure. A failed
run must not be used as a verified release even if it produced a POF before a
later test failed.

Warning-line counts are included in the summary; existing Quartus warnings do
not automatically fail the build. Errors, failed assertions, missing completion
markers, missing outputs and failed timing/routing guards do fail it. Inspect
the relevant log when a warning count changes or the change affects that area.

## Faster intermediate checks

```bash
./scripts/build_and_test.py --quick
```

This still builds, checks targeted timing/routing and runs the focused control,
sound, catch, moving-hole and player-mode tests. It omits SPI and the full video
suite and reports `QUICK_PASS`, with visual review `NOT_RUN`. It is useful during
iteration, but does not replace the full run and visual review for video changes.

Use `--quartus-bin /path/to/quartus/bin` for another installation. Otherwise
Quartus is found on PATH or under `~/altera/13.0sp1/quartus/bin`. GHDL, Bash, Git,
Python 3 and Pillow must be available. `--output-dir` selects another results
directory. Each run keeps potentially large simulation data, so remove old run
directories when their evidence and images are no longer needed.

Automation tests (no FPGA/Quartus access):

```bash
python3 -m unittest discover -s testbench -p 'test_build_and_test.py' -v
```
