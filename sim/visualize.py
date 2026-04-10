#!/usr/bin/env python3
"""
CRT Simulator - Visualizes frame_data.txt from GHDL simulation.

Reads HSYNC/VSYNC/HBLANK/VIDEO samples captured at 7.159 MHz and
reconstructs the frame like a real CRT: HSYNC trailing edge starts
a new scanline, VSYNC trailing edge starts a new frame.

Usage:
    python3 visualize.py              # pygame window (2x scale, green phosphor); always writes frame_output.png
    python3 visualize.py --ppm       # also write frame_output.ppm

PNG (frame_output.png) is always generated. PPM is written only with --ppm or when pygame is missing.
"""

import sys
import os


def load_samples(filename="frame_data.txt"):
    """Load simulation samples from text file."""
    samples = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 4:
                continue
            hsync, vsync, hblank, video = [int(x) for x in parts]
            samples.append((hsync, vsync, hblank, video))
    return samples


def reconstruct_frames(samples):
    """Reconstruct frames from sync signals, like a CRT."""
    frames = []
    current_frame = []
    current_line = []

    prev_hsync = 0
    prev_vsync = 0

    for hsync, vsync, hblank, video in samples:
        # VSYNC trailing edge (1->0) = new frame
        if prev_vsync == 1 and vsync == 0:
            if current_line:
                current_frame.append(current_line)
                current_line = []
            if current_frame:
                frames.append(current_frame)
            current_frame = []

        # HSYNC trailing edge (1->0) = new scanline
        if prev_hsync == 1 and hsync == 0:
            if current_line:
                current_frame.append(current_line)
            current_line = []

        # Record pixel (only during active video)
        current_line.append(video)

        prev_hsync = hsync
        prev_vsync = vsync

    # Don't forget the last partial frame
    if current_line:
        current_frame.append(current_line)
    if current_frame:
        frames.append(current_frame)

    return frames


def frame_to_pixels(frame, width=None, height=None):
    """Convert frame data to a 2D pixel array, normalized to consistent size."""
    if not frame:
        return []

    # Find actual dimensions
    max_line_len = max(len(line) for line in frame) if frame else 0
    if width is None:
        width = max_line_len
    if height is None:
        height = len(frame)

    pixels = []
    for y in range(min(height, len(frame))):
        row = []
        for x in range(width):
            if x < len(frame[y]):
                row.append(frame[y][x])
            else:
                row.append(0)
        pixels.append(row)

    # Pad remaining rows
    while len(pixels) < height:
        pixels.append([0] * width)

    return pixels


def write_ppm(pixels, filename="frame_output.ppm", scale=2):
    """Write pixels as PPM image with green phosphor look."""
    if not pixels:
        print("No pixel data to write!")
        return

    height = len(pixels)
    width = len(pixels[0]) if pixels else 0

    with open(filename, 'w') as f:
        f.write("P3\n")
        f.write(f"{width * scale} {height * scale}\n")
        f.write("255\n")

        for row in pixels:
            for _ in range(scale):
                for pixel in row:
                    for _ in range(scale):
                        if pixel:
                            f.write("0 255 0 ")  # Green phosphor
                        else:
                            f.write("0 0 0 ")
                f.write("\n")

    print(f"Wrote {filename} ({width * scale}x{height * scale})")


def write_png(pixels, filename="frame_output.png", scale=2):
    """Write pixels as PNG (green phosphor). Uses Pillow if available."""
    if not pixels:
        print("No pixel data to write!")
        return
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not available; cannot write PNG. Install with: pip3 install Pillow")
        return

    height = len(pixels)
    width = len(pixels[0]) if pixels else 0
    out_w, out_h = width * scale, height * scale

    img = Image.new("RGB", (out_w, out_h), (0, 0, 0))
    for y in range(height):
        for x in range(width):
            rgb = (0, 255, 0) if pixels[y][x] else (0, 0, 0)
            for sy in range(scale):
                for sx in range(scale):
                    img.putpixel((x * scale + sx, y * scale + sy), rgb)

    img.save(filename)
    print(f"Wrote {filename} ({out_w}x{out_h})")


def frame_to_pil_image(frame, width, height, scale=1):
    """Convert a frame (list-of-lines) to a PIL palette-mode Image.  Fast path: builds
    pixel bytes directly rather than using putpixel.  Returns None on failure."""
    try:
        from PIL import Image
    except ImportError:
        return None

    pixels = frame_to_pixels(frame, width=width, height=height)
    # Build flat byte string: 0=black, 1=green
    if scale == 1:
        data = bytes(1 if px else 0 for row in pixels for px in row)
        img = Image.frombytes("P", (width, height), data)
    else:
        # Scale up by repeating pixels
        rows = []
        for row in pixels:
            out_row = bytes(v for px in row for v in ([1 if px else 0] * scale))
            rows.extend([out_row] * scale)
        img = Image.frombytes("P", (width * scale, height * scale), b"".join(rows))

    # 2-entry palette: index 0 = black, index 1 = phosphor green
    palette = [0, 0, 0,   0, 255, 0] + [0] * (256 * 3 - 6)
    img.putpalette(palette)
    return img


def write_animated_gif(frames, filename="gameplay.gif", scale=1, delay_ms=100):
    """Write all complete frames as an animated GIF.

    delay_ms is the inter-frame delay in milliseconds.  At 100 ms/frame
    (10 fps), 100 game frames = 10 seconds of playback time.
    """
    try:
        from PIL import Image
    except ImportError:
        print("Pillow not available; cannot write GIF.  Install: pip3 install Pillow")
        return

    # Keep only frames that look like a complete field (at least 290 scanlines)
    complete = [f for f in frames if len(f) >= 290]
    if not complete:
        print("No complete frames available for GIF.")
        return

    # Canonical dimensions: widest line across all complete frames, modal height
    target_w = max(max((len(l) for l in f), default=0) for f in complete)
    heights   = sorted(len(f) for f in complete)
    target_h  = heights[len(heights) // 2]   # median height

    print(f"  Rendering {len(complete)} frames at {target_w}x{target_h} scale={scale}x …")
    images = []
    for i, frame in enumerate(complete):
        img = frame_to_pil_image(frame, target_w, target_h, scale=scale)
        if img is not None:
            images.append(img)
        if (i + 1) % 10 == 0:
            print(f"    {i + 1}/{len(complete)} frames converted")

    if not images:
        print("No images generated.")
        return

    out_w = target_w * scale
    out_h = target_h * scale
    images[0].save(
        filename,
        save_all=True,
        append_images=images[1:],
        duration=delay_ms,
        loop=0,
        optimize=False,
    )
    print(f"Wrote {filename} ({len(images)} frames, {out_w}x{out_h}, "
          f"{delay_ms} ms/frame = {len(images)*delay_ms/1000:.1f} s)")


def display_pygame(pixels, scale=2):
    """Display frame using pygame with green phosphor effect."""
    try:
        import pygame
    except ImportError:
        print("pygame not available, falling back to file output only")
        print("Install with: pip3 install pygame")
        write_png(pixels)
        write_ppm(pixels)
        return

    if not pixels:
        print("No pixel data to display!")
        return

    height = len(pixels)
    width = len(pixels[0]) if pixels else 0

    pygame.init()
    screen = pygame.display.set_mode((width * scale, height * scale))
    pygame.display.set_caption("Cross Display - CRT Simulation")

    # Create surface
    surface = pygame.Surface((width, height))
    for y, row in enumerate(pixels):
        for x, pixel in enumerate(row):
            if pixel:
                surface.set_at((x, y), (0, 255, 0))  # Green phosphor
            else:
                surface.set_at((x, y), (0, 0, 0))

    # Scale and display
    scaled = pygame.transform.scale(surface, (width * scale, height * scale))
    screen.blit(scaled, (0, 0))
    pygame.display.flip()

    print(f"Displaying {width}x{height} frame (scale {scale}x). Press ESC or close window to quit.")

    # Event loop
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_ESCAPE:
                    running = False

    pygame.quit()


def main():
    use_ppm = "--ppm" in sys.argv

    if not os.path.exists("frame_data.txt"):
        print("ERROR: frame_data.txt not found. Run the GHDL simulation first.")
        sys.exit(1)

    print("Loading simulation data...")
    samples = load_samples()
    print(f"  Loaded {len(samples)} samples")

    print("Reconstructing frames from sync signals...")
    frames = reconstruct_frames(samples)
    print(f"  Found {len(frames)} frame(s)")

    if not frames:
        print("ERROR: No frames reconstructed!")
        sys.exit(1)

    # Always write an animated GIF when there are multiple complete frames
    if len(frames) > 2:
        print("Writing animated GIF...")
        write_animated_gif(frames, filename="gameplay.gif", scale=1, delay_ms=100)

    # Also render a single representative still (second-to-last complete frame)
    frame_idx = max(len(frames) - 2, 0)
    frame = frames[frame_idx]
    print(f"  Using frame {frame_idx}: {len(frame)} scanlines, "
          f"max {max(len(l) for l in frame)} pixels/line")

    pixels = frame_to_pixels(frame)

    # Always write PNG so you can view the result without pygame
    write_png(pixels)

    if use_ppm:
        write_ppm(pixels)
    if not use_ppm:
        display_pygame(pixels)


if __name__ == "__main__":
    main()
