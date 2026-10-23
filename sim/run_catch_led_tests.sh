#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/74LS/LS02.vhd" "$ROOT/74LS/LS153.vhd" \
    "$ROOT/sim/CatchStatusLED.vhd" "$ROOT/testbench/tb_CatchStatusLED.vhd"
ghdl -r --std=93 tb_CatchStatusLED --assert-level=error
