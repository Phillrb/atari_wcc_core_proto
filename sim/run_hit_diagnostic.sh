#!/usr/bin/env bash
# Reproduce a known zero-delay hazard, then prove real solid overlap is audible.
# This is a diagnostic, not a specification that the hazard should be preserved.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd"
for ic in LS00 LS02 LS04 LS08 LS10 LS20 LS27 LS30 LS74 LS86 LS92 LS93 LS107 LS153; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
ghdl -a --std=93 "$ROOT/IC/IC9602.vhd" "$ROOT/HorizontalSync.vhd" "$ROOT/PlayersVerticalWindow.vhd" "$ROOT/PlayersMultiplexer.vhd" "$ROOT/PlayersSumming.vhd" "$ROOT/SoundCircuit.vhd" "$ROOT/testbench/tb_DefenderHitHazard.vhd"
ghdl -r --std=93 tb_DefenderHitHazard --assert-level=error
ghdl -r --std=93 tb_DefenderHitHazard -gVALID_SOLID_OVERLAP=true --assert-level=error
