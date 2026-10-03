#!/usr/bin/env python3
"""Verify/render the endpoint frames from SPINNER_TEST=true's fixed sequence."""
from itertools import groupby
from shutil import copyfile
from PIL import Image, ImageDraw
import visualize

frames = visualize.reconstruct_frames(visualize.load_samples())
images = []
for index, label, expected in [
    (12, "Top: POSITION 82", [(77, 91), (144, 158)]),
    (16, "Turning spinner", None),
    (21, "Bottom: POSITION 154", [(149, 163), (216, 230)]),
]:
    pixels = visualize.frame_to_pixels(frames[index])
    # Solid Forwards occupy x=248..251. Exclude horizontal walls at y=73..76,
    # 233..236. These are rendered raster coordinates, not V-counter values.
    rows = [y for y in range(77, 233) if any(pixels[y][x] for x in range(248, 252))]
    spans = []
    for _, group in groupby(enumerate(rows), lambda pair: pair[1] - pair[0]):
        ys = [pair[1] for pair in group]
        spans.append((ys[0], ys[-1]))
    if expected is not None:
        assert spans == expected, (index, spans, expected)
    path = f"spinner_frame_{index}.png"
    visualize.write_png(pixels, path)
    image = Image.open(path).convert("RGB")
    labelled = Image.new("RGB", (image.width, image.height + 28))
    labelled.paste(image, (0, 28))
    ImageDraw.Draw(labelled).text((10, 8), label, fill="white")
    images.append(labelled)
    print(f"Frame {index}: Solid Forwards rows {spans}")
result = Image.new("RGB", (sum(i.width for i in images), max(i.height for i in images)))
x = 0
for image in images:
    result.paste(image, (x, 0))
    x += image.width
result.save("spinner_limits.png")
copyfile("gameplay.gif", "spinner_gameplay.gif")
print("Spinner endpoint frame checks passed; wrote spinner_limits.png and spinner_gameplay.gif")
