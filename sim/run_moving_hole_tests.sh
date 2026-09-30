#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd"
for ic in LS00 LS02 LS04 LS08 LS74 LS107; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
ghdl -a --std=93 "$ROOT/IC/IC9316.vhd" "$ROOT/MovingHoleCircuit.vhd" "$ROOT/WindowMissBounce.vhd"
for tb in tb_IC9316 tb_LS74 tb_LS107 tb_LS107_master_slave tb_MovingHoleCircuit; do
    ghdl -a --std=93 "$ROOT/testbench/$tb.vhd"
    STOP=1us
    if [ "$tb" = tb_MovingHoleCircuit ]; then STOP=3ms; fi
    ghdl -r --std=93 "$tb" --assert-level=error --stop-time="$STOP"
done
python3 "$ROOT/sim/visualize_moving_hole.py" moving_hole_trace.csv "$ROOT/sim"
