# Historical moving-hole investigation — 22 October 2026

These files are obsolete experiments retained only to reproduce historical
evidence. **They are not required by any current build or test runner. Do not
apply them to current sources.** The combined fix has already been incorporated.

| File | Historical purpose |
| --- | --- |
| `moving_hole_6_8_candidate.patch` | Presets-only experiment; still reversed early at the upper boundary. |
| `moving_hole_fix_candidate.patch` | Combined presets and boundary-sampling fix, subsequently adopted. |
| `moving_hole_video_diagnostic.patch` | Simulation-only long-game instrumentation. |
| `check_moving_hole_candidate_trace.py` | Analyzer for that instrumented eight-second trace. |

Patch contents are preserved unchanged, including old source comments and paths.
The current implementation and normal test commands are documented in the
[correction record](../../MOVING_HOLE_FIX_PROPOSAL.md) and
[Figure 18 notes](../../MOVING_HOLE_FIG18.md).

## Historical reproduction only

Use patch files from this archive, not from the top-level docs directory.
`/path/to/archive` below means the absolute path to this archive in the current
repository, outside the isolated old checkout.

For reproducing that earlier diagnostic only, start with an isolated checkout
of `7c3e8a4` (not the updated production source), then apply
`moving_hole_6_8_candidate.patch` instead of the combined patch, run the standard
simulation, then apply `moving_hole_video_diagnostic.patch` in the isolated copy:

```sh
cd sim
# Compile the instrumented source and long-game testbench after applying patches.
ghdl -a --std=93 ../atari_wcc.vhd ../testbench/tb_atari_wcc.vhd
ghdl -r --std=93 tb_moving_hole_video "-gONE_PLAYER_MODE='1'" --stop-time=8000ms --assert-level=error
python3 /path/to/archive/check_moving_hole_candidate_trace.py moving_hole_full_trace.csv
python3 visualize.py --frame=20
```

That instrumentation is simulation-only and must not enter the board build.
It captures video one frame in four and logs the vertical counter and HOLE on
every HSYNCn edge, using 10 ns timestamp units to avoid integer overflow.

