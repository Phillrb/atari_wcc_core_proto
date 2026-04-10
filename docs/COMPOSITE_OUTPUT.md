# Displaying the Video on a Real Composite Monitor

The cross_display design outputs **digital** TTL-level signals. A composite (CVBS) monitor expects **analog** levels on a 75 Ω line. You need to combine sync and video and convert to the right voltage range.

## What You Have (from atari_wcc)

| Signal  | Meaning | Level |
|---------|--------|--------|
| **CSYNC** | Composite sync (H and V combined: HSYNC xor VSYNCn) | 0 / 3.3 V (or 5 V) |
| **VIDEO** | Picture content (playfield + time line, active high) | 0 / 3.3 V (or 5 V) |

Timing is PAL-like 313–314 lines, ~50 Hz field rate; horizontal rate is derived from the 7.159 MHz clock (same as the original game).

## What the Monitor Expects

- **Single composite (CVBS) input:** one wire carrying sync + video.
- **Levels (typical):** sync tip ≈ 0 V, blanking/black ≈ 0.3 V, white ≈ 1 V peak (into 75 Ω).
- **Impedance:** source should drive 75 Ω (series 75 Ω at the output, or a 75 Ω load at the monitor).

So you must:
1. **Combine** CSYNC and VIDEO into one signal so that sync is “blacker than black”.
2. **Scale** the result to about 0 V (sync) and 0.3–1 V (picture).
3. **Drive** a 75 Ω line (or a 75 Ω termination at the monitor).

## Simple Resistor Method

A minimal approach is to build a small resistor network so that:

- When **CSYNC** is active (sync pulse), the output is pulled **low** (toward 0 V).
- When **CSYNC** is inactive, the output follows **VIDEO** (black ≈ 0.3 V, white ≈ 0.7–1 V).

Example idea (conceptual; adjust for your FPGA voltage and desired levels):

- One resistor from **VIDEO** (FPGA pin) to the composite output node (so high VIDEO = higher voltage).
- One resistor from **CSYNC** (or inverted CSYNC) to the composite output node so that when sync is high the node is pulled toward 0 V (stronger than the video pull-up).
- Composite output node through a **75 Ω** series resistor to the coax output (and/or 75 Ω to ground at the monitor).

Values depend on your supply (3.3 V or 5 V) and the exact 0.3 V / 1 V targets; a few hundred ohms for the two “mix” resistors and 75 Ω for the line is the usual ballpark. You can simulate or measure with a scope to set sync at ~0 V and white at ~1 V.

## Using a DAC or Video DAC

For cleaner levels and better picture:

- Feed **CSYNC** and **VIDEO** (or a combined digital stream) into a small **video DAC** or **R‑2R ladder** that outputs 0–1 V composite.
- Many retro and arcade designs use a single **video DAC** (e.g. 2‑bit: sync / black / grey / white) or a simple op‑amp mixer so that sync = 0 V and video = 0.3–1 V.
- The DAC output then goes through a 75 Ω series resistor to the composite (RCA or BNC) connector.

## Connection to the Monitor

- **Composite (yellow RCA):** One coax cable from your “composite out” (after the resistor/DAC and 75 Ω) to the monitor’s composite input. Use 75 Ω coax if possible.
- **Sync on green / separate sync:** If the monitor has separate H/V sync inputs (e.g. VGA-style), you can use **HSYNC** and **VSYNC** instead of CSYNC and drive the monitor’s sync inputs (often through buffers and level shifters). The “video” (picture) would still need to be converted to analog and combined or fed to the correct input depending on the monitor.

## Summary

1. Take **CSYNC** and **VIDEO** from the FPGA.
2. Mix and level-shift them so that sync ≈ 0 V and picture ≈ 0.3–1 V (e.g. resistor network or small DAC).
3. Drive the composite line through 75 Ω into the monitor’s composite input.

After that, the monitor should show the same playfield and time line you see in simulation, at the correct scan rate.
