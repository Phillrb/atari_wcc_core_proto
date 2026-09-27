#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT
cd "$BUILD"
ghdl -a --std=93 "$ROOT/IC/jkff.vhd" "$ROOT/IC/dff.vhd" "$ROOT/74LS/LS74.vhd" "$ROOT/74LS/LS00.vhd" "$ROOT/74LS/LS02.vhd" "$ROOT/74LS/LS04.vhd"
ghdl -a --std=93 "$ROOT/JammaSwitchAdapter.vhd" "$ROOT/CreditCircuit.vhd" "$ROOT/ElectronicLatchCircuit.vhd" "$ROOT/StartCircuit.vhd"
ghdl -a --std=93 "$ROOT/testbench/tb_JammaSwitchAdapter.vhd" "$ROOT/testbench/tb_GameControl.vhd"
ghdl -r --std=93 tb_JammaSwitchAdapter --assert-level=error
ghdl -r --std=93 tb_GameControl --assert-level=error

ghdl -a --std=93 "$ROOT/IC/IC9602.vhd" "$ROOT/ServeTimingCircuit.vhd" "$ROOT/testbench/tb_ServeControl.vhd"
ghdl -r --std=93 tb_ServeControl --assert-level=error
ghdl -a --std=93 "$ROOT/74LS/LS10.vhd" "$ROOT/74LS/LS27.vhd" "$ROOT/TimeLineCircuit.vhd" "$ROOT/testbench/tb_TimeLineControl.vhd"
ghdl -r --std=93 tb_TimeLineControl --assert-level=error
