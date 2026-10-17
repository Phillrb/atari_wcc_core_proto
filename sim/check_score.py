#!/usr/bin/env python3
"""Check actual Figure 21 internal nets, then render captured DUT video pixels."""
from pathlib import Path
import argparse
from PIL import Image, ImageDraw


def check_vcd(path):
    scope, names, values = [], {}, {}
    pulses = [0, 0]
    carries = [0, 0]
    samples = 0
    previous_expected = [0, 0]
    root = 'tb_scorecircuit.'
    pulse_names = [root+'dut.j3_y1', root+'dut.j3_y4']
    carry_names = [root+'dut.n2_q1', root+'dut.n2_q2']
    pending = []

    def flush():
        nonlocal samples, previous_expected
        old = values.copy()
        values.update(pending)
        pending.clear()
        reset = values.get(root+'start') == '1'
        for i in range(2):
            if old.get(pulse_names[i]) == '1' and values.get(pulse_names[i]) == '0' and not reset:
                pulses[i] += 1
            if old.get(carry_names[i]) in ('0', '1') and old.get(carry_names[i]) != values.get(carry_names[i]) and not reset:
                carries[i] += 1
        if reset:
            pulses[:] = [0, 0]
            carries[:] = [0, 0]
            previous_expected = [0, 0]
        if old.get(root+'sample_scores') != '1' and values.get(root+'sample_scores') == '1':
            expected = [int(values[root+'expected_solid'],2), int(values[root+'expected_checks'],2)]
            for i, ic in enumerate(('k3', 'l3')):
                units = ''.join(values[root+'dut.'+ic+'_q'+str(bit)] for bit in (3,2,1,0))
                assert set(units) <= {'0','1'}, f'Unknown BCD: {units}'
                actual = 10*int(values[carry_names[i]],2)+int(units,2)
                assert actual == expected[i], (ic, expected[i], actual)
                advance = (expected[i]-previous_expected[i]) % 20
                assert pulses[i] == advance, (ic, 'goal edges', pulses[i], advance)
                carry = int(expected[i]//10 != previous_expected[i]//10)
                assert carries[i] == carry, (ic, 'tens transitions', carries[i], carry)
            pulses[:] = [0, 0]
            carries[:] = [0, 0]
            previous_expected = expected
            samples += 1

    with path.open() as source:
        for line in source:
            fields = line.split()
            if not fields:
                continue
            if fields[0] == '$scope':
                scope.append(fields[2])
            elif fields[0] == '$upscope':
                scope.pop()
            elif fields[0] == '$var':
                names[fields[3]] = '.'.join(scope+[fields[4]])
            elif line.startswith('#'):
                flush()
            elif line[0] in '01xXzZuU':
                pending.append((names[line[1:].strip()],line[0]))
            elif line[0] == 'b':
                pending.append((names[fields[1]],fields[0][1:]))
        flush()
    assert samples == 66, f'Incomplete stimulus: {samples} samples'
    print(f'PASS: {samples} score observations; single goal edges, carries, reset, 19->0 and 8->12')


def render(path, output):
    lines = iter(path.read_text().splitlines())
    images = []
    for expected in range(8,13):
        assert int(next(lines)) == expected
        rows = [next(lines) for _ in range(32)]
        assert all(len(row)==256 for row in rows)
        img = Image.new('RGB',(256,32),(0,12,0))
        img.putdata([(80,255,100) if pixel=='1' else (0,12,0) for row in rows for pixel in row])
        # Actual segment samples, independent of the DUT decoder/mux logic.
        # Digit origin: units at H=176, tens at H=160, both V=96.
        points = [(11,1),(15,3),(15,11),(11,15),(9,11),(9,3),(11,7)]
        patterns = {0:'1111110',1:'0110000',2:'1101101',8:'1111111',9:'1110011'}
        for x0, digit in ((176,expected%10),(160,expected//10)):
            got=''.join(rows[96+y-88][x0+x-144] for x,y in points)
            want = '0000000' if x0==160 and digit==0 else patterns[digit]
            assert got==want, (expected,x0,got,want)
        scaled=img.resize((768,96),Image.NEAREST)
        frame=Image.new('RGB',(768,124),(0,12,0))
        frame.paste(scaled,(0,28))
        ImageDraw.Draw(frame).text((12,8),f'Solid score {expected} - actual Figure 21 VIDEO',fill='white')
        frame.save(output/f'score_{expected}.png')
        images.append(frame)
    assert next(lines,None) is None
    images[0].save(output/'score_rollover.gif',save_all=True,append_images=images[1:],duration=700,loop=0)
    sheet=Image.new('RGB',(768,124*5))
    for i,img in enumerate(images): sheet.paste(img,(0,124*i))
    sheet.save(output/'score_rollover.png')
    print('PASS: decoded captured pixels show 8, 9, 10, 11, 12; PNGs and GIF written')


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('build',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    check_vcd(args.build/'score.vcd')
    render(args.build/'score_pixels.txt',args.output)
