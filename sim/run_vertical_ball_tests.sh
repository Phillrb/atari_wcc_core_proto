#!/usr/bin/env bash
# Isolated Figure 14/16/19 movement and closed-loop wall-bounce regression.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$ROOT/sim"
ghdl -a --std=93 --workdir="$BUILD" "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd"
for ic in LS00 LS02 LS04 LS08 LS10 LS74 LS83 LS86 LS107; do
    ghdl -a --std=93 --workdir="$BUILD" "$ROOT/74LS/$ic.vhd"
done
ghdl -a --std=93 --workdir="$BUILD" "$ROOT/IC/IC9314.vhd" "$ROOT/IC/IC9316.vhd" \
    "$ROOT/VerticalDirectionAndSpeed.vhd" "$ROOT/BallMotionCircuit.vhd" \
    "$ROOT/WindowMissBounce.vhd" "$ROOT/testbench/tb_VerticalBallMotion.vhd"
ghdl -r --std=93 --workdir="$BUILD" tb_VerticalBallMotion --assert-level=error
python3 visualize_vertical_ball.py
