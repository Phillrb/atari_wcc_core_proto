#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd"
for ic in LS00 LS02 LS04 LS08 LS10 LS20 LS27 LS30 LS74 LS86 LS92 LS93 LS107; do
    ghdl -a --std=93 "$ROOT/74LS/$ic.vhd"
done
ghdl -a --std=93 "$ROOT/HorizontalSync.vhd" "$ROOT/PlayersVerticalWindow.vhd" "$ROOT/testbench/tb_PlayerModeWindow.vhd"
ghdl -r --std=93 tb_PlayerModeWindow --assert-level=error --stop-time=400us
