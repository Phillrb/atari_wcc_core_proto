# Solid Forwards – Implementation Notes

## Schematic (TM-035 Figure 11)

- **Comparator N9-12**: ramp from ramp generator vs pot (variable resistor) → threshold crossing.
- **One-shot M9 (IC9602)**: triggered on comparator high; pulse width set by R41 (spacing between top/bottom forward).
- **Differentiators R39–C21, R40–C22**: edge spikes from M9 pulse.
- **NOR K8 (LS02)**: combines spikes → drives **K7 LDn** (load enable).
- **Counter K7 (IC9316)**: clocked by HSYNC; loads 0 on spikes, then counts 0..15 when LDn high; **RC** → inverter **J8** → **E2**; **QB, QC, QD** → **B2, C2, D2**.

## Current Implementation (Restored)

The full chain is implemented in **PlayersSolidForwards.vhd**:

- **M9 (IC9602)** with generic `PULSE_WIDTH_NS => 70 us`, triggered by comparator (A1).
- **Differentiator**: digital model – on rising/falling edge of M9 Q1, one-HSYNC spikes drive K8.
- **K8 (LS02)** gate 1: NOR(spike_leading, spike_trailing) → K7 LDn (low when spike → load 0).
- **K7 (IC9316)** and **J8 (LS04)** as per schematic.

Leading edge of M9 → K8 low → K7 loads 0 → K7 counts. Trailing edge of M9 → K8 low again → K7 loads 0 again (bottom forward). Simulation runs with `--stop-delta=400000000`; IC9602 uses 100 ns polling to limit delta growth.
