#!/bin/bash
# Atari WCC GHDL Simulation Script
# Usage: cd sim && bash run_sim.sh
# Top-level: atari_wcc (display stack: clock, sync, playfield, ball off).
#
# Note: GHDL 0.37 mcode does not support default component binding.
# All design files use direct entity instantiation (entity work.X).

set -e

ROOT=..

echo "=== Atari WCC GHDL Simulation ==="
echo ""

# Clean previous artifacts
rm -f *.cf frame_data.txt

echo "[1/3] Compiling VHDL sources..."

# IC primitives
ghdl -a --std=93 "$ROOT/IC/jkff.vhd"
ghdl -a --std=93 "$ROOT/IC/dff.vhd"

# 74LS library - simple gates (no internal component instantiation)
ghdl -a --std=93 "$ROOT/74LS/LS00.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS02.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS04.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS08.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS10.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS20.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS27.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS30.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS86.vhd"

# 74LS library - flip-flop ICs (direct entity instantiation)
ghdl -a --std=93 "$ROOT/74LS/LS74.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS93.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS107.vhd"

# 74LS library - counters (use JK flip-flops)
ghdl -a --std=93 "$ROOT/74LS/LS90.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS92.vhd"

# 74LS library - adder (behavioral, no component instantiation)
ghdl -a --std=93 "$ROOT/74LS/LS83.vhd"

# 74LS library - multiplexer and decoder (behavioral)
ghdl -a --std=93 "$ROOT/74LS/LS153.vhd"
ghdl -a --std=93 "$ROOT/74LS/LS48.vhd"

# IC library - 9316 presettable counter, 9314 latch, 9602 one-shot (Ball / Vertical Direction / Players)
ghdl -a --std=93 "$ROOT/IC/IC9316.vhd"
ghdl -a --std=93 "$ROOT/IC/IC9314.vhd"
ghdl -a --std=93 "$ROOT/IC/IC9602.vhd"

# Design files
ghdl -a --std=93 "$ROOT/ComputerClock.vhd"
ghdl -a --std=93 "$ROOT/HorizontalSync.vhd"
ghdl -a --std=93 "$ROOT/VerticalSync.vhd"
ghdl -a --std=93 "$ROOT/SyncSumming.vhd"
ghdl -a --std=93 "$ROOT/PlayfieldCircuit.vhd"
ghdl -a --std=93 "$ROOT/PlayersVerticalWindow.vhd"
ghdl -a --std=93 "$ROOT/PlayersRampGenerator.vhd"
ghdl -a --std=93 "$ROOT/PlayersSolidForwards.vhd"
ghdl -a --std=93 "$ROOT/PlayersStripedForwards.vhd"
ghdl -a --std=93 "$ROOT/PlayersSolidDefenseGoalie.vhd"
ghdl -a --std=93 "$ROOT/PlayersStripedDefenseGoalie.vhd"
ghdl -a --std=93 "$ROOT/PlayersMultiplexer.vhd"
ghdl -a --std=93 "$ROOT/PlayersSumming.vhd"
ghdl -a --std=93 "$ROOT/VerticalDirectionAndSpeed.vhd"
ghdl -a --std=93 "$ROOT/WindowMissBounce.vhd"
ghdl -a --std=93 "$ROOT/CatchKickHorizontalDirection.vhd"
ghdl -a --std=93 "$ROOT/HorizontalDirectionAndSpeed.vhd"
ghdl -a --std=93 "$ROOT/ServeTimingCircuit.vhd"
ghdl -a --std=93 "$ROOT/BallMotionCircuit.vhd"
ghdl -a --std=93 "$ROOT/TimeLineCircuit.vhd"
ghdl -a --std=93 "$ROOT/ScoreCircuit.vhd"
ghdl -a --std=93 "$ROOT/atari_wcc.vhd"

# Testbench
ghdl -a --std=93 "$ROOT/testbench/tb_atari_wcc.vhd"

# Elaborate
ghdl -e --std=93 tb_atari_wcc

# Default 300 ms covers: pre-serve, post-serve, +5 frames, +10 frames (frame 13 ≈ 250 ms).
STOP_MS=${STOP_MS:-300}
echo "[2/3] Running simulation (${STOP_MS} ms)..."
ghdl -r --std=93 tb_atari_wcc --stop-time=${STOP_MS}ms 2>&1 || true

# Check output
if [ ! -f frame_data.txt ]; then
    echo "ERROR: frame_data.txt not generated!"
    exit 1
fi

LINES=$(wc -l < frame_data.txt)
echo "  Generated $LINES samples in frame_data.txt"

echo "[3/3] Rendering keyframes..."
# Reconstructed frames are ~19.3 ms each in this design's sync timing.
#   1     = first complete frame; SERVE has just gone high, ball not yet visible
#   3     = ball clearly on playfield, scores still 0-0 (post-serve)
#   4..8  = +1..+5 frames after post-serve (each ~19 ms apart)
render_frame() {
    local idx=$1
    local out=$2
    python3 visualize.py --frame=${idx} >/dev/null
    if [ -f frame_output.png ]; then
        mv -f frame_output.png "${out}"
        echo "  Wrote ${out} (frame ${idx})"
    fi
}

render_frame 1 frame_initial.png
render_frame 3 frame_post_serve.png
render_frame 4 frame_plus1.png
render_frame 5 frame_plus2.png
render_frame 6 frame_plus3.png
render_frame 7 frame_plus4.png
render_frame 8 frame_plus5.png

# Leave frame_output.png at the last rendered frame so existing tooling still finds something.
cp -f frame_plus5.png frame_output.png 2>/dev/null || true

echo ""
echo "=== Done ==="
