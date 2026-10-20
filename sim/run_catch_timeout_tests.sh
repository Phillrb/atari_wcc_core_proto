#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd"
for ic in LS00 LS02 LS04 LS08 LS10 LS27 LS30 LS74 LS86 LS92 LS93 LS107; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
for circuit in IC/IC9602 ComputerClock HorizontalSync PlayersVerticalWindow PlayersSumming CollisionSampleBank CatchKickHorizontalDirection ServeTimingCircuit testbench/tb_CatchTimeout; do
    ghdl -a --std=93 "$ROOT/$circuit.vhd"
done
for parity in 0 1; do
    ghdl -r --std=93 tb_CatchTimeout -gCHECK_PARITY="'$parity'" --assert-level=error
done
ghdl -r --std=93 tb_CatchTimeout -gWALK_THROUGH=true --assert-level=error
cp catch_traversal.csv "$ROOT/sim/catch_traversal.csv"
python3 "$ROOT/sim/visualize_catch_traversal.py"
