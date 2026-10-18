"""Render measured BALL leading edges; no modification to captured game video."""
import csv
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
traces = {}
for code in (10, 9):
    with (ROOT / f"horizontal_stop{code}.csv").open() as stream:
        traces[code] = [tuple(map(int, (r["time_ns"], r["h"], r["v"])))
                        for r in csv.DictReader(stream)]
    assert len(traces[code]) == 24, "Expected eight ball lines in each of three fields"
    assert [v for _, _, v in traces[code]] == list(range(248, 256)) * 3

# This script records the current discrepancy, not a requirement to retain it.
moving = [h for _, h, _ in traces[10]]
stationary = [h for _, h, _ in traces[9]]
assert len(set(stationary)) == 1, "Experimental preset 9 did not hold horizontally"
print("Preset 10, H at V=248:", moving[::8])
print("Preset 9, H at V=248:", stationary[::8])
print("Preset 10 stationary:", len(set(moving)) == 1)

frames = []
for field in range(3):
    img = Image.new("RGB", (630, 360), "#101820")
    draw = ImageDraw.Draw(img)
    draw.text((20, 12), f"STOP held continuously - captured field {field + 1}", fill="white")
    draw.text((20, 30), "Real raster: 455 clocks/line; 375 enabled clocks/line", fill="white")
    for panel, code in enumerate((10, 9)):
        top = 75 + 140 * panel
        label = "Current preset 10" if code == 10 else "Testbench-only preset 9"
        rows = traces[code][8 * field:8 * (field + 1)]
        draw.text((20, top - 20), f"{label}: H={rows[0][1]} at V=248", fill="white")
        draw.rectangle((80, top, 455, top + 85), outline="#556677")
        for _, h, v in rows:
            y = top + 6 + (v - 248) * 9
            draw.rectangle((h, y, h + 7, y + 7), fill="#00ff66")
        draw.text((470, top + 15), "V=248..255", fill="white")
        draw.text((470, top + 32), "Y enlarged", fill="white")
        draw.text((80, top + 90), "H=80", fill="white")
        draw.text((410, top + 90), "H=455", fill="white")
    frames.append(img)
frames[0].save(ROOT / "horizontal_stop.gif", save_all=True,
               append_images=frames[1:], duration=900, loop=0)
sheet = Image.new("RGB", (630 * 3, 360))
for index, frame in enumerate(frames):
    sheet.paste(frame, (630 * index, 0))
sheet.save(ROOT / "horizontal_stop.png")
