#!/usr/bin/env python3
"""Check actual fitted C4/B3 transitions and horizontal ball pulse widths."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
names, values, count_bits = {}, {}, {}
clock = phase = ball = None
last_count = None
phase_edges = 0
ball_start = None
widths = []
narrow = []
errors = []
time = 0
for line in path.read_text().splitlines():
    fields = line.split()
    if line.startswith("$var"):
        key, name = fields[3:5]
        if "U_BALL_MOTION|C4|count" in name:
            count_bits[int(fields[5].strip("[]"))] = key
        if "U_CLOCK|E2|DFF2|JKFF|nxt_state~clkctrl_outclk" in name:
            clock = key
        if "U_BALL_MOTION|B3|edge_slaves:JKFF2|nxt_state~regout" in name:
            phase = key
        if "U_BALL_MOTION|A3|P8_Y3~0_combout" in name:
            ball = key
    elif line.startswith("#"):
        time = int(line[1:])
    elif len(line) == 2 and line[0] in "01xXzZ":
        value, key = line
        old = values.get(key)
        values[key] = value
        if key == clock and old == "1" and value == "0":
            bits = [values.get(count_bits[i], "x") for i in range(4)]
            if all(b in "01" for b in bits):
                last_count = sum(int(b) << i for i, b in enumerate(bits))
        if key == phase and old in ("0", "1") and value != old:
            phase_edges += 1
            if last_count != 15:
                errors.append(f"B3 toggled at {time/1e6:.6f} us after C4={last_count}, expected 15")
        if key == ball and value == "1":
            ball_start = time
        elif key == ball and value == "0" and ball_start is not None:
            width = (time - ball_start) / 1000
            if width < 20:
                narrow.append(width)  # Raw decode; collision adapter must reject these.
            else:
                widths.append(width)
                if not 1100 <= width <= 1140:
                    errors.append(f"Ball pulse width {width:.3f} ns, expected eight 140 ns pixels")
            ball_start = None
assert clock and phase and ball and len(count_bits) == 4, "Missing trace coverage"
if phase_edges < 2:
    errors.append("Missing two complete phase transitions")
if len(widths) < 2:
    errors.append("Missing two ball pulses")
for error in errors:
    print("FAIL:", error)
assert not errors, "Fitted carry/ball regression failed"
print(f"PASS: {phase_edges} genuine terminal-count phase transitions; ball widths {widths} ns")
print(f"Raw subpixel pulses (not collision-filter verification): {narrow} ns")
