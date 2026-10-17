#!/usr/bin/env python3
"""Check fitted Figure 21 clock sinks and the polarity assumed by the SDC."""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1] if len(sys.argv)>1 else 'simulation/modelsim/atari_wcc.vho')
netlist = path.read_text()


def cell(name, kind):
    pattern = re.escape('\\'+name+'\\') + r'\s*:\s*' + kind + r'\b.*?PORT MAP\s*\((.*?)\);'
    match = re.search(pattern,netlist,re.S)
    if not match:
        raise SystemExit(f'Missing fitted cell {name}')
    return match.group(1)


for counter, gate in (('K3','P3_Y1'),('L3','P11_Y4')):
    base = f'U_CORE|U_SCORE|ic_{counter}|'
    clocks = []
    for stage in 'BCD':
        ports = cell(base+f'FF_{stage}|nxt_state','cycloneii_lcell_ff')
        clocks.append(re.search(r'\bclk\s*=>\s*(\\[^\n]+?\\)',ports).group(1))
    expected = '\\'+base+'FF_A|ALT_INV_nxt_state~clkctrl_outclk\\'
    assert clocks == [expected]*3, f'{counter}: mixed or unexpected /5 clock routing: {clocks}'
    ports = cell(base+'FF_A|nxt_state','cycloneii_lcell_ff')
    assert f'\\U_CORE|U_SCORE|ic_J3|{gate}~combout\\' in re.search(r'\bclk\s*=>\s*(\\[^\n]+?\\)',ports).group(1)
    # Quartus folds the LS90 inverter into J3. Evaluate the actual LUT with
    # its fitted port mapping; placement may permute the four LUT inputs.
    gate_label = re.escape('\\U_CORE|U_SCORE|ic_J3|'+gate+'\\')
    match = re.search(gate_label+r'\s*:\s*cycloneii_lcell_comb\b(.*?)PORT MAP',netlist,re.S)
    assert match, 'Missing J3 LUT'
    mask = int(re.search(r'lut_mask => "([01]{16})"',match.group(1)).group(1),2)
    ports = cell('U_CORE|U_SCORE|ic_J3|'+gate,'cycloneii_lcell_comb')
    inputs = dict(re.findall(r'(data[abcd])\s*=>\s*(\\[^\n]+?\\)',ports))
    goal = '\\U_CORE|miss_one_shot~regout\\'
    side = '\\U_CORE|U_HSYNC|B2|edge_slaves:JKFF1|nxt_state~regout\\'
    assert set(inputs.values()) == {goal,side}, 'Unexpected fitted goal gate inputs'
    for address in range(16):
        bits = {name:(address>>'abcd'.index(port[-1]))&1 for port,name in inputs.items()}
        expected = bits[goal] & (bits[side] if counter=='K3' else 1-bits[side])
        assert (mask>>address)&1 == expected, 'Recheck fitted J3 polarity before using SDC'
    print(f'PASS: {counter} B/C/D share one global clock; fitted goal polarity matches SDC')
