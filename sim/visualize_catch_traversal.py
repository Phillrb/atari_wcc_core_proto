"""Render the measured catch fixture: controlled motion, real raster/catch logic."""
import csv
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
with (ROOT / "catch_traversal.csv").open() as stream:
    rows = list(csv.DictReader(stream))

frames = []
for row in rows:
    offset = int(row["offset"])
    held = row["stop"] == "'1'"
    image = Image.new("RGB", (640, 240), "#101820")
    draw = ImageDraw.Draw(image)
    draw.text((16, 12), "Solid attacker: rear contact -> timeout -> front clearance", fill="white")
    draw.text((16, 32), "Controlled 4px steps; real raster, collision sampler, D8 and J5", fill="white")
    draw.text((16, 52), "Accelerated timeout: 12 scanlines (764.4 us)", fill="white")
    draw.line((40, 180, 600, 180), fill="#506070")
    draw.rectangle((250, 100, 269, 159), fill="#00ff66")
    left = 250 + offset * 5
    draw.rectangle((left, 110, left + 39, 149), fill="#ffcc55")
    draw.text((16, 200), f"t={int(row['time_ns']) / 1000:.1f} us   offset={offset:+d}px"
              f"   STOP={row['stop']}   {'HELD' if held else 'MOVING'}", fill="white")
    frames.append(image)

frames[0].save(ROOT / "catch_traversal.gif", save_all=True,
               append_images=frames[1:], duration=120, loop=0)
# Select measured stages: approach, hold, release overlap, front clearance.
indices = [0, next(i for i, r in enumerate(rows) if r["stop"] == "'1'")]
indices += [next(i for i, r in enumerate(rows)
                 if int(r["offset"]) == offset) for offset in (1, 5)]
sheet = Image.new("RGB", (1280, 480))
for panel, index in enumerate(indices):
    sheet.paste(frames[index], ((panel % 2) * 640, (panel // 2) * 240))
sheet.save(ROOT / "catch_traversal.png")
print("Rendered catch_traversal.png and catch_traversal.gif from measured fixture states")
