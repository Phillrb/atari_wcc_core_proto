#!/usr/bin/env bash
# Requires an existing Quartus fit/EDA export and working ModelSim-Altera.
# MODELSIM_BIN may select the actual platform directory on a modern host.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
NETLIST_DIR=${1:-"$ROOT/simulation/modelsim"}
NETLIST_DIR=$(cd "$NETLIST_DIR" && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
if [[ -n ${MODELSIM_BIN:-} ]]; then
    export PATH="$MODELSIM_BIN:$PATH"
fi
vlib work
vcom -93 -work work "$NETLIST_DIR/atari_wcc.vho"
for corner in slow fast; do
    sdf="$NETLIST_DIR/atari_wcc_vhd.sdo"
    if [[ $corner == fast ]]; then sdf="$NETLIST_DIR/atari_wcc_vhd_fast.sdo"; fi
    vsim -c -t ps -sdfmax "/atari_wcc_board=$sdf" work.atari_wcc_board \
        -do "do {$ROOT/sim/score_postfit.do}" -l "$ROOT/output_files/score_postfit_${corner}.log"
done
