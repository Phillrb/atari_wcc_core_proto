#!/usr/bin/env python3
"""Compare fitted vertical-window samples on a 313-line raster.

Usage: python3 sim/visualize_vertical_postfit.py BEFORE.csv AFTER.csv OUTPUT_DIR
Horizontal position is deliberately omitted; these are isolated STOP traces.
"""
import csv
import sys
from pathlib import Path

from PIL import Image, ImageDraw


def samples(path):
    with Path(path).open() as source:
        return {int(row["line"]) for row in csv.DictReader(source)
                if row["window"] == "1"}


before, after = map(samples, sys.argv[1:3])
out = Path(sys.argv[3])
out.mkdir(parents=True, exist_ok=True)
images = []
for frame in range(1, 3):
    image = Image.new("RGB", (580, 385), "#171717")
    draw = ImageDraw.Draw(image)
    draw.text((15, 10), f"Fitted vertical STOP window - raster frame {frame}", fill="white")
    draw.text((15, 27), "Measured scanlines; horizontal position omitted", fill="white")
    for x, label, trace in ((45, "Before", before), (335, "Fixed", after)):
        draw.text((x, 47), label, fill="white")
        draw.rectangle((x, 65, x + 200, 377), outline="#777777")
        for y in range(313):
            if frame * 313 + y in trace:
                draw.line((x + 92, 65 + y, x + 108, 65 + y), fill="#00ff00")
    images.append(image)
sheet = Image.new("RGB", (580 * len(images), 385))
for i, image in enumerate(images):
    sheet.paste(image, (580 * i, 0))
sheet.save(out / "vertical_postfit_comparison.png")
images[0].save(out / "vertical_postfit_comparison.gif", save_all=True,
               append_images=images[1:], duration=700, loop=0)
print("Wrote fitted vertical-window comparison PNG and GIF")
