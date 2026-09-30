#!/usr/bin/env python3
"""Render measured Figure 18 HOLE samples; this is a signal diagnostic, not video."""
import csv
import sys
from pathlib import Path
from PIL import Image, ImageDraw


def render(trace_path, output_dir):
    with open(trace_path, newline="") as source:
        samples = list(csv.DictReader(source))
    fields = max(int(row["frame"]) for row in samples) + 1
    trace = Image.new("RGB", (fields, 313), "black")
    for row in samples:
        if int(row["hole"]):
            trace.putpixel((int(row["frame"]), int(row["line"])), (0, 255, 0))
    chart = Image.new("RGB", (fields * 2 + 80, 313 * 2 + 65), "#171717")
    chart.paste(trace.resize((fields * 2, 626), getattr(Image, "Resampling", Image).NEAREST), (60, 35))
    draw = ImageDraw.Draw(chart)
    draw.text((12, 10), "Figure 18: actual HOLE samples (9/11 presets, 313 lines/frame)", fill="white")
    for line in (0, 80, 128, 240, 312):
        y = 35 + line * 2
        draw.text((22, y), str(line), fill="white")
        if line in (80, 240):
            draw.line((60, y, 60 + fields * 2, y), fill="#555555")
    draw.text((12, 670), "Frame", fill="white")
    for frame in range(0, fields, 100):
        draw.text((60 + frame * 2, 670), str(frame), fill="white")
    output = Path(output_dir)
    chart.save(output / "moving_hole_timing.png")
    animation = []
    # Every fourth field makes the full measured trajectory easy to inspect.
    for frame in range(0, fields, 4):
        image = Image.new("RGB", (320, 353), "#171717")
        draw = ImageDraw.Draw(image)
        draw.text((12, 8), f"Figure 18 signal diagnostic - frame {frame}", fill="white")
        draw.text((12, 23), "Green = HOLE high; full 313-line raster", fill="white")
        for line in range(313):
            colour = trace.getpixel((frame, line))
            draw.line((200, line + 40, 250, line + 40), fill=colour)
        for line in (80, 240):
            draw.line((190, line + 40, 260, line + 40), fill="#777777")
        animation.append(image)
    animation[0].save(output / "moving_hole.gif", save_all=True,
                      append_images=animation[1:], duration=80, loop=0)
    print(f"Rendered {fields} measured fields: moving_hole_timing.png, moving_hole.gif")


if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2])
