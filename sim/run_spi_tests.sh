#!/bin/bash
# Standalone protocol and Figure 11 travel tests; no full-video capture needed.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
WORK="$ROOT/testbench/work/spi"
mkdir -p "$WORK"
analyze() { ghdl -a --std=93 --workdir="$WORK" "$ROOT/$1"; }
analyze SPIAdapter.vhd
analyze testbench/ATtinySPITestModel.vhd
analyze testbench/tb_SPIAdapter.vhd
ghdl -r --std=93 --workdir="$WORK" tb_SPIAdapter --stop-time=2400ms --assert-level=error
analyze IC/jkff.vhd
analyze IC/dff.vhd
for gate in LS00 LS02 LS04 LS08 LS10 LS27 LS86 LS107; do analyze "74LS/$gate.vhd"; done
analyze IC/IC9316.vhd
analyze IC/IC9602.vhd
for circuit in PlayersSolidForwards PlayersStripedForwards PlayersSolidDefenseGoalie PlayersStripedDefenseGoalie; do analyze "$circuit.vhd"; done
analyze testbench/tb_SPIPlayerTravel.vhd
ghdl -r --std=93 --workdir="$WORK" tb_SPIPlayerTravel --stop-time=300ms --assert-level=error
