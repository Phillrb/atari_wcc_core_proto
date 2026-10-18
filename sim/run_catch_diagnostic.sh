#!/usr/bin/env bash
# Diagnose STOP against the real raster. Preset 9 is a testbench experiment only.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd"
for ic in LS00 LS02 LS04 LS08 LS10 LS20 LS30 LS74 LS93 LS107; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
ghdl -a --std=93 "$ROOT/IC/IC9316.vhd" "$ROOT/IC/IC9602.vhd" \
    "$ROOT/HorizontalSync.vhd" "$ROOT/VerticalSync.vhd" \
    "$ROOT/BallMotionCircuit.vhd" "$ROOT/ServeTimingCircuit.vhd" \
    "$ROOT/testbench/tb_ServeControl.vhd" "$ROOT/testbench/tb_HorizontalStop.vhd"
ghdl -r --std=93 tb_ServeControl --assert-level=error
for code in 10 9; do
    ghdl -r --std=93 tb_HorizontalStop -gSTOP_CODE="$code" --assert-level=error
    cp horizontal_stop.csv "$ROOT/sim/horizontal_stop${code}.csv"
done
python3 "$ROOT/sim/visualize_horizontal_stop.py"
