#!/usr/bin/env python3
"""Render actual BALL scanline samples from the isolated wall-feedback test."""
import csv
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parent
with (root / 'vertical_ball_trajectory.csv').open() as source:
    samples = list(csv.DictReader(source))
frames = max(int(row['frame']) for row in samples) + 1
trace = Image.new('RGB', (frames, 313), 'black')
for row in samples:
    trace.putpixel((int(row['frame']), int(row['line'])), (0, 255, 0))
chart = Image.new('RGB', (frames * 4 + 90, 690), '#171717')
chart.paste(trace.resize((frames * 4, 626), getattr(Image, "Resampling", Image).NEAREST), (60, 35))
draw = ImageDraw.Draw(chart)
draw.text((12, 10), 'Measured BALL: Figure 19 -> 14 -> 16 feedback, 313 lines/frame', fill='white')
for line in (0, 80, 128, 240, 312):
    y = 35 + line * 2
    draw.text((25, y), str(line), fill='white')
    if line in (80, 240):
        draw.line((60, y, frames * 4 + 59, y), fill='#777777')
for frame in range(0, frames, 20):
    draw.text((60 + frame * 4, 666), str(frame), fill='white')
draw.text((8, 666), 'Frame', fill='white')
chart.save(root / 'vertical_ball_timing.png')
images = []
for frame in range(1, frames-1):
    picture = Image.new('RGB', (420, 370), '#171717')
    pen = ImageDraw.Draw(picture)
    pen.text((12, 8), f'Ball vertical feedback diagnostic - frame {frame}', fill='white')
    pen.text((12, 23), 'Measured BALL lines; horizontal position omitted', fill='white')
    for line in (80, 240):
        pen.line((40, line+45, 380, line+45), fill='#777777')
    for line in range(313):
        if trace.getpixel((frame, line)) != (0, 0, 0):
            pen.line((205, line+45, 213, line+45), fill='#00ff00')
    images.append(picture.quantize(colors=8, dither=Image.NONE))
images[0].save(root / 'vertical_ball_bounce.gif', save_all=True,
               append_images=images[1:], duration=50, loop=0)
print(f'Rendered {frames} measured fields: vertical_ball_timing.png, vertical_ball_bounce.gif')
