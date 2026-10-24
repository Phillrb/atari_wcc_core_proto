#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
# Reject a disconnected integration even if the circuit fixture still passes.
python3 - "$ROOT/atari_wcc.vhd" <<'PYCODE'
import re, sys
from pathlib import Path
assert re.search(r"GOALIE_FWD_HIT\s*=>\s*catch_trigger_i", Path(sys.argv[1]).read_text()), "D8 catch output is not connected to Figure 15"
PYCODE
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd" "$ROOT/IC/IC9316.vhd"
for ic in LS00 LS02 LS04 LS08 LS74 LS83 LS86; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
for name in CollisionSampleBank CatchKickHorizontalDirection HorizontalDirectionAndSpeed testbench/tb_HitAcceleration; do
    ghdl -a --std=93 "$ROOT/$name.vhd"
done
ghdl -r --std=93 tb_HitAcceleration --assert-level=error
