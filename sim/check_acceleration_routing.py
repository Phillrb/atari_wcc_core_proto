#!/usr/bin/env python3
"""Check all four B6 bits use the same fitted F6 event clock."""
import re
import sys
from pathlib import Path
s = Path(sys.argv[1] if len(sys.argv)>1 else 'simulation/modelsim/atari_wcc.vho').read_text()
clocks = []
for i in range(4):
    name = f'\\U_CORE|U_HORIZ_SPEED|B6|count[{i}]\\'
    m = re.search(re.escape(name)+r'\s*:\s*cycloneii_lcell_ff\s*PORT MAP\s*\((.*?)\);', s, re.S)
    assert m, f'Missing B6 bit {i}'
    clocks.append(re.search(r'\bclk\s*=>\s*(\\[^\n]+?\\)', m[1])[1])
assert len(set(clocks)) == 1 and 'U_HORIZ_SPEED|F6|P8_Y3' in clocks[0], clocks
print('PASS: all four B6 speed bits share the fitted F6 event clock')
