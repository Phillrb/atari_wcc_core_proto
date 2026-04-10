# Figure 8 – IC Map (Electronic Latch, Credit, Start, Time Line)

TM-035 Figure 8 contains the following ICs. Your list: **A8, C8, B8, C9, A9, E9, A2, D9, K1, C4, N4**. (C4 is the capacitor in the time-line RC, not an IC.)

## PCB grid → type (from README)

| Grid | Type   | Role in Fig 8 |
|------|--------|----------------|
| A8   | LS04  | Hex inverter: latch preset (pin 12), credit LED (pin 8), coin debounce path, start debounce path |
| B8   | LS74  | Dual D FF: 32V delay counter (B8-5/6, B8-9/8) for coin validation |
| C8   | LS00  | Quad NAND: C8-8 = NAND(B8_Q1, B8_Q2) → coin-accepted pulse |
| C9   | LS02  | Quad 2-input NOR: C9-13 = NOR(A9_9_8_Q, debounce) → CREDIT; C9-10 etc. for start debounce |
| A9   | LS74  | Dual D FF: A9-5 (1P/2P), A9-9/8 (credit expired) |
| B9   | LS74  | Dual D FF: B9-5/6 (START), B9-9/8 (ATRC) |
| E9   | 555   | Timer: time-line ramp; output pin 3 → D9-8 |
| A2   | LS10  | Triple 3-input NAND: A2-8 = TIME LINE window NAND(H_window, V_pulse, D9_8) |
| D9   | LS04  | Inverter D9-8: inverts E9-3 for time-line draw window |
| J2   | LS04  | Inverter J2-10: with K1-5 forms H window 128H–132H (manual) |
| K1   | LS74  | Flip-flop K1-5: with J2-10 forms horizontal window for TIME LINE |
| N4   | LS27  | Triple 3-input NOR: N4-6 = negative-true AND for END OF GAME pulse → clocks B9-9/8 |

**Note:** Manual says “flip-flop A8-4/2” for coin debounce; A8 is LS04 (no FFs). Likely typo for another chip or node; schematic check needed. Credit circuit currently uses a level-sensitive debounce (coin switch high).

**C4:** Capacitor C4 (with R7, R10, Q5) in the time-line RC; not an IC.

## Circuit ↔ files

| Circuit           | File                     | ICs used in implementation |
|-------------------|--------------------------|-----------------------------|
| Electronic Latch  | ElectronicLatchCircuit.vhd | A8-12 (LS04) only; Q1/Q2/Q3 modelled as behavioural FF |
| Credit            | CreditCircuit.vhd       | B8(LS74), C8-8(LS00), A9(LS74), C9-13(LS27). No A8-8 or A8-4/2. |
| Start             | StartCircuit.vhd        | B9(LS74). Start debounce behavioural; no A8-10/C9-10 gates. |
| Time Line         | TimeLineCircuit.vhd     | A2(LS10). D9-8, E9, K1, J2, N4-6 modelled behaviourally. |

## Next steps (schematic accuracy)

1. **Credit:** Add A8-8 (inverter for credit LED drive) if needed; confirm coin debounce vs “A8-4/2” on schematic.
2. **Start:** Implement start-button debounce with explicit A8-10 and C9 gates (e.g. C9-10) per schematic.
3. **Time Line:** Add explicit D9-8 (LS04), K1-5 + J2-10 (H window 128H–132H), and N4-6 (LS27) for END_OF_GAME → B9-9/8 clock.
4. **Latch:** Keep transistor latch as behavioural model; only A8-12 is TTL (already instantiated).
