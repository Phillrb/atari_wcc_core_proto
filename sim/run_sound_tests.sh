#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/IC9602.vhd" "$ROOT/74LS/LS00.vhd" "$ROOT/74LS/LS20.vhd" "$ROOT/SoundCircuit.vhd"
ghdl -a --std=93 "$ROOT/testbench/tb_IC9602.vhd" "$ROOT/testbench/tb_IC9602_sound.vhd" "$ROOT/testbench/tb_SoundCircuit.vhd" "$ROOT/testbench/tb_sound_gates.vhd"
ghdl -r --std=93 tb_sound_gates --assert-level=error
ghdl -r --std=93 tb_IC9602 --assert-level=error --stop-time=1us
ghdl -r --std=93 tb_IC9602_sound --assert-level=error
ghdl -r --std=93 tb_SoundCircuit --assert-level=error
