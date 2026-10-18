#!/usr/bin/env python3
"""Reject split CLOCK_7 routes in the fitted Figure 16 counters/blanking."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv) > 1 else
            "simulation/modelsim/atari_wcc.vho")
netlist = path.read_text()
names = [f"U_CORE|U_BALL_MOTION|{ic}|count[{bit}]"
         for ic in ("B4", "C4") for bit in range(4)]
names.append("U_CORE|U_HSYNC|D2|DFF1|JKFF|nxt_state")
expected = "\\U_CORE|U_CLOCK|E2|DFF2|JKFF|nxt_state~clkctrl_outclk\\"
for name in names:
    pattern = (re.escape("\\" + name + "\\") +
               r"\s*:\s*cycloneii_lcell_ff\s*PORT MAP\s*\((.*?)\);")
    match = re.search(pattern, netlist, re.S)
    assert match, f"Missing fitted register {name}"
    clock = re.search(r"\bclk\s*=>\s*(\\[^\n]+?\\)", match[1])[1]
    assert clock == expected, f"{name}: expected global CLOCK_7, got {clock}"
print("PASS: all eight B4/C4 bits and HRESET D2 share global CLOCK_7")
