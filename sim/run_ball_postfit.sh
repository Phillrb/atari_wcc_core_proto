#!/usr/bin/env bash
# Existing Quartus fit/EDA export and working ModelSim-Altera are required.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
NETLIST_DIR=$(cd "${1:-"$ROOT/simulation/modelsim"}" && pwd)
RESULT_DIR=${2:-"$ROOT/output_files/ball_postfit"}
mkdir -p "$RESULT_DIR"
RESULT_DIR=$(cd "$RESULT_DIR" && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
if [[ -n ${MODELSIM_BIN:-} ]]; then
    export PATH="$MODELSIM_BIN:$PATH"
fi
vlib work
vcom -93 -work work "$NETLIST_DIR/atari_wcc.vho"
failed=0
for corner in slow fast; do
    sdf="$NETLIST_DIR/atari_wcc_vhd.sdo"
    if [[ $corner == fast ]]; then sdf="$NETLIST_DIR/atari_wcc_vhd_fast.sdo"; fi
    vsim -c -t ps -sdfmax "/atari_wcc_board=$sdf" work.atari_wcc_board \
        -do "do {$ROOT/sim/vertical_ball_postfit.do}" \
        -l "$RESULT_DIR/$corner.log" || failed=1
    cp vertical_ball_postfit.csv "$RESULT_DIR/$corner.csv"
    for motion in up down; do
        if [[ -f vertical_ball_$motion.csv ]]; then
            cp "vertical_ball_$motion.csv" "$RESULT_DIR/${corner}_$motion.csv"
        fi
    done
    vsim -c -t ps -sdfmax "/atari_wcc_board=$sdf" work.atari_wcc_board \
        -do "do {$ROOT/sim/ball_carry_postfit.do}" \
        -l "$RESULT_DIR/horizontal_$corner.log" || failed=1
    cp ball_carry.vcd "$RESULT_DIR/horizontal_$corner.vcd"
    python3 "$ROOT/sim/check_ball_carry.py" "$RESULT_DIR/horizontal_$corner.vcd" || failed=1
done
exit "$failed"
