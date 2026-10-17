#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd"
for ic in LS00 LS02 LS04 LS08 LS10 LS27 LS30 LS86 LS90 LS107 LS153 LS48; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
ghdl -a --std=93 "$ROOT/testbench/tb_LS90.vhd" "$ROOT/ScoreCircuit.vhd" "$ROOT/testbench/tb_ScoreCircuit.vhd"
ghdl -r --std=93 tb_LS90 --assert-level=error
ghdl -r --std=93 tb_ScoreCircuit --assert-level=error --vcd=score.vcd
python3 "$ROOT/sim/check_score.py" "$BUILD" "$ROOT/sim"
