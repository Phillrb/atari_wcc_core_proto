#!/usr/bin/env python3
"""Render/check the fixed four-control SPI sweep from run_sim.sh SPI_TEST=true."""
from itertools import groupby
from shutil import copyfile
from PIL import Image, ImageDraw
import visualize

frames = visualize.reconstruct_frames(visualize.load_samples())
# Raster coordinates; the field interior is y=77..232.
columns = [(104, 'solid goalie', 0), (152, 'solid defense', 0),
           (200, 'checks forwards', 3), (248, 'solid forwards', 1),
           (296, 'checks defense', 2), (344, 'checks goalie', 2)]
images = []
for index, label, offsets in [
    (12, 'All controls: ADC 700 / top', [0, 0, 0, 0]),
    (19, 'All controls: ADC 1023 / bottom', [72, 72, 72, 72]),
    (23, 'Independent: SD bottom, SF top, CD top, CF bottom', [72, 0, 0, 72]),
]:
    pixels = visualize.frame_to_pixels(frames[index])
    for x, name, channel in columns:
        rows = [y for y in range(77, 233) if any(pixels[y][p] for p in range(x, x+4))]
        spans = []
        for _, group in groupby(enumerate(rows), lambda pair: pair[1]-pair[0]):
            ys = [pair[1] for pair in group]
            spans.append((ys[0], ys[-1]))
        if 'goalie' in name:
            base = [(111, 125)]
        elif 'defense' in name:
            base = [(77, 91), (145, 159)]
        else:
            base = [(77, 91), (144, 158)]
        expected = {y+offsets[channel] for lo, hi in base for y in range(lo, hi+1)}
        # Composite video may also contain ball/score pixels in this column.
        # Exact symbol counts and absence of extra symbols are checked by
        # tb_SPIPlayerTravel against the actual Figure 11 circuit outputs.
        assert expected.issubset(rows), (index, name, spans, sorted(expected))
        print(f'Frame {index}: {name}: lit rows {spans}')
    path = f'spi_frame_{index}.png'
    visualize.write_png(pixels, path)
    image = Image.open(path).convert('RGB')
    labelled = Image.new('RGB', (image.width, image.height+28))
    labelled.paste(image, (0,28))
    ImageDraw.Draw(labelled).text((10,8), label, fill='white')
    images.append(labelled)
result = Image.new('RGB', (sum(i.width for i in images), max(i.height for i in images)))
x = 0
for image in images:
    result.paste(image, (x,0)); x += image.width
result.save('spi_limits.png')
copyfile('gameplay.gif', 'spi_controls.gif')
print('SPI full-core frame checks passed; wrote spi_limits.png and spi_controls.gif')
