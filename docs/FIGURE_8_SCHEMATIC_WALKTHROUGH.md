# Figure 8 – Schematic walkthrough (pin-level)

This doc records exact pin connections for Phase 2 Figure 8 so we can implement schematic-accurate logic. References: **Goal_IV_TM-035.md** (§ Electronic Latch, Credit, Start, Time Line), **diagrams/8_Electronic_Latch_etc.png**, and the 74LS pinouts in this project.

---

## 1. Coin debounce – “flip-flop A8-4/2”

**Manual:** “pin 1 of flip-flop A8-4/2” is set by the coin microswitch (negative-going pulse via CR1); “pin 2” is Q and enables B8-5/6 and B8-9/8 and inhibits C9-13. When the switch returns before count of three, “resets flip-flop A8-4/2”.

**Issue:** A8 is **LS04** (hex inverter) – no flip-flops. So “A8-4/2” is either a misprint or a gate designation.

**Interpretation from schematic:** The coin debounce is likely a **two-inverter SR latch** using two gates of A8:
- **Gate 1:** P1_A1 (input), P2_Y1 (output) – “A8-1/2”.
- **Gate 2:** P3_A2 (input), P4_Y2 (output) – “A8-3/4”.
- Cross-couple: P2_Y1 → P3_A2, P4_Y2 → P1_A1 (or via resistor/diode).
- Coin pulse (low) into P1_A1 → P2_Y1 goes high (set). That high enables B8 and inhibits C9-13.
- Reset when coin releases: something pulls P2_Y1 low (e.g. via B8 clear or the same switch node).

**A8-12 (latch preset output):** Drives **B9-10** (SET2n) and **A9-10** (SET2n). Low = preset active (both ATRC and A9-9/8 preset high for attract).

**Please confirm on schematic:**
- [ ] Which A8 pins connect to the COIN SWITCH node (1, 2, 3, or 4)?
- [ ] Is there a second inverter in the latch and which pins (3–4 or another pair)?
- [ ] What drives the reset of this latch (e.g. B8 clear, or switch return)?

**For VHDL:** Once confirmed, we implement an explicit **A8** (LS04) with two gates wired as an SR latch; coin switch (or its conditioned pulse) drives the set input.

---

## 2. Credit LED – A8-8

**Manual:** “Clearing flip-flop A9-9/8 causes … a high level to inverter A8-8. The low output of this inverter is used to forward bias the LED of the credit indicator.”

So: **A9_9_8_Qn** (or the node that is high when credit is established) → **A8-9** (input) → **A8-8** (output) → LED (low = LED on).

**LS04:** P9_A4 = input, P8_Y4 = output. So **A8-8** = P8_Y4, **A8-9** = P9_A4.  
Input to A8-9 = “high when credit established” = output of C9-13 (CREDIT). So **CREDIT** → A8-9 → A8-8 → LED drive (inverted). Our CREDIT output is already the C9-13 output; we can add a single LS04 gate for A8-8 if we want to drive an “LED” net explicitly.

**Please confirm on schematic:**
- [ ] A8 pin 9 is driven by C9-13 (CREDIT) and pin 8 goes to the credit LED (or resistor to LED).

---

## 3. Start debounce – “flip-flop A8-10/C9-10”

**Manual:** Start circuit has “flip-flops A8-10/C9-10, B9-5/6 and B9-9/8”. “Pressing and releasing the pushbutton sets and resets flip-flop A8-10/C9-10, causing a **positive-going pulse** to be applied to the **D input of flip-flop B9-5**.”

So the “A8-10/C9-10” block produces **one positive pulse** per press-release, and that pulse goes to **B9-5** (D of the first FF of B9).

**Pin meanings:**
- **A8-10:** LS04 P10_Y5 (output of gate 5); input is P11_A5.
- **C9-10:** LS02 P10_Y3 (output of NOR gate 3); inputs are P8_A3, P9_B3.

**Schematic (confirmed):** Start switch **N/C** connects **A8-11**, **B9-2**, and **C9-10** (one net; when not pressed, shorted to ground). Start switch **N/O** connects **C9-9** and **A8-10**. **ATRCn** to **C9-8**. When pressed, N/C opens so B9-2 and C9-10 are driven by NOR output (high when ATRCn and A8-10 both low); next 256V clocks START.

**B9 (LS74) first FF (START) – confirmed:**
- **B9-1** (CLR1n) ← **C9-13** (CREDIT: NOR output from credit circuit; high = credit established, so clear released and FF enabled).
- **B9-2** (D1) ← from N/C net (when not pressed held low; when pressed driven by C9-10).
- **B9-3** (CLK1) ← **V256**.
- **B9-4** (SET1n) ← **logic 1** (inactive).
- **B9-5** (Q1) → **START**.
- **B9-6** (Q1n) → **STARTn**.

**B9 (LS74) second FF (ATRC) – confirmed:**
- **B9-7** (GND), **B9-14** (VCC).
- **B9-8** (Q2n) → **ATRCn**.
- **B9-9** (Q2) → **ATRC**.
- **B9-10** (SET2n) ← **A8-12** (latch preset output; also to **A9-10** SET2n). Low = preset active (attract).
- **B9-11** (CLK2) ← **END_GAME** (from **N4-6**). END_GAME pulse clocks ATRC FF high (game over → attract).
- **B9-12** (D2) ← **logic 1** (so when clocked, Q2 goes high = ATRC).
- **B9-13** (CLR2n) ← **STARTn** (B9-6). When START goes high, STARTn goes low and clears ATRC FF (play mode).

**For VHDL:** Implement with explicit A8 (inverter P11→P10) and C9 (NOR P8=ATRCn, P9=node from A8-10, P10=output tied to B9-2 when N/C open). B9: CLR1n=C9-13 (CREDIT), D1=net from C9-10/N/C, CLK1=V256, SET1n='1', Q1=START, Q1n=STARTn; CLR2n=STARTn, D2='1', CLK2=END_GAME, SET2n=A8-12, Q2=ATRC, Q2n=ATRCn. Model switch: not pressed = A8-11, B9-2, C9-10 shorted low; pressed = A8-11 high, A8-10 low, B9-2 driven by C9-10.

---

## 4. Time line – K1-5 and J2-10 (128H–132H window) – confirmed

**Manual:** “Flip-flop K1-5 and inverter J2-10 combine the **H**, **128H**, and **4H** signals to form a **vertical-window pulse** that begins at **128H** and ends at **132H**. This pulse is applied to **pin 9** of NAND gate A2-8.”

So the **H window** into A2 pin 9 is high for **H = 128..131** (four clocks). In terms of bits: 128 = 128H only; 132 = 128 + 4, so 128H and 4H. So one correct combination is:
- **Window = 128H AND NOT 4H** → high for H = 128, 129, 130, 131 (four counts).

**J2 (LS04) – confirmed:**
- **J2-11** (P11_A5) ← **H4** (4H signal).
- **J2-10** (P10_Y5) → **H4n** (NOT 4H). So H4n = NOT(H4).

**K1 (LS74) first FF – confirmed:**
- **K1-1** (CLR1n) ← **H4n** (from J2-10). When H4 is high, H4n is low → K1 cleared (Q low). When H4 is low, H4n is high → clear released.
- **K1-2** (D1) ← **Hn** (inverted H from playfield).
- **K1-3** (CLK1) ← **128H**.
- **K1-4** (SET1n) ← **logic 1** (inactive).
- **K1-5** (Q1) → **A2-9** (H window input to TIME_LINE NAND).

So when 128H clocks and D (Hn) is high, Q goes high; when 128H and 4H coincide (at H=132), H4 goes high, H4n goes low, K1 clears. Result: 4-clock window 128H–132H into A2-9.

**For VHDL:** Implement J2 as LS04 (H4 → P11, P10 → H4n). Implement K1 as LS74: CLR1n=H4n, D1=Hn, CLK1=128H, SET1n='1', Q1→A2-9. Provide playfield **Hn** (inverted H) and **128H**, **H4** (4H) from H counter.

---

## 5. Time line – A2-8 (TIME LINE NAND)

**Manual:** “NAND gate A2-8 combines the window signals and the time line information (output of inverter D9-8 to form the TIME LINE signal).” “Pin 9” = H window, “pin 10” = V pulse (80V–240V).

**LS10 (A2) gate 3:** P9_A3, P10_B3, P11_C3 in → P8_Y3 out. So:
- **P9_A3** = H window (from K1/J2, 128H–132H). **Schematic:** A2 pin 9 is the TIME_LINE signal (net name at this gate; the gate output is at pin 8).
- **P10_B3** = **V** signal (playfield vertical window 80V–240V; **A2-10** confirmed from schematic).
- **P11_C3** = output of D9-8 (inverted 555 time-line pulse; **D9-8** → **A2-11** confirmed).
- **P8_Y3** = TIME_LINE (NAND output; active low when line is drawn). So TIME_LINE is output at **A2-8**; the net may be labeled TIME_LINE at pin 9 on the schematic.

No confirmation needed; this matches the manual and our A2 usage.

---

## 6. Time line – D9-8 (inverter on 555 output)

**Manual:** “This pulse is inverted (D9-8) and applied to NAND gate A2-8 and negative-true AND gate N4-6.”

**D9 (LS04):** D9-8 = P8_Y4 (output), input P9_A4. **E9-3** (555 output) → **D9-9** (P9_A4). **D9-8** (P8_Y4) → **N4-4** (P4_B2) and **A2-11** (P11_C3).

**Schematic (confirmed):** E9-3 → D9-9; D9-8 → N4-4 and A2-11.

---

## 8. E9 (555) time-line timer – confirmed

**Pin connections from schematic:**
- **E9-1** (GND) – ground.
- **E9-2** (TRIG) ← **VRESETn** (vertical reset, active low). Start of field triggers the 555.
- **E9-3** (OUT) → D9-9 (inverter) for time-line pulse.
- **E9-4** (RST) ← **logic 1** (reset inactive).
- **E9-5** (CTRL) – **variable**: control voltage from GAME_TIME circuit (1 MΩ variable resistor and ATRCn fed through transistors and a diode). Sets comparison threshold so pulse width increases as game time advances.
- **E9-6** (THRES) and **E9-7** (DISCH) – **variable**: tied to RC (50 kΩ variable resistor, R17/R18, C5). Voltage here ramps during each field; when it reaches E9-5 level, output (E9-3) goes low.
- **E9-8** (VCC) ← **logic 1** (+5 V).

**For VHDL:** Keep existing digital model: trigger on VRESETn (or equivalent), with threshold/pulse-width driven by a digital equivalent of the ramp and game-time control (e.g. start_V or similar). E9-4 and E9-8 = '1'.

## 7. END OF GAME – N4-6

**Manual:** “When the negative-going time-line-delay pulse … coincides with the **low portion** of the **C & D** and **128V** signals, a high **END OF GAME** pulse is developed at the output of **negative-true AND gate N4-6**. This pulse **clocks flip-flop B9-9/8**.”

So N4-6 is a 3-input NOR (negative-true AND): all three inputs low → output high. The three inputs are:
1. The time-line delay pulse (D9-8) – we want the “low” part.
2. **C & D** (playfield signal).
3. **128V**.

**LS27 (N4) gate 2:** P3_A2, P4_B2, P5_C2 in → P6_Y2 out. So:
- **P3_A2** = **C.Dn** (C and D negated; confirmed from schematic).
- **P4_B2** = **D9-8** (inverted 555 time-line pulse; confirmed from schematic).
- **P5_C2** = 128V or V128n (low in relevant half of field). **N4-2** = **V128n** (gate 1, P2_B1).
- **P6_Y2** = **END_GAME** (high when all three low). → **B9-11** (CLK2).

**Schematic (confirmed):** N4-3 = C.Dn; N4-2 = V128n. N4-6 = END_GAME; END_GAME → B9-11 (CLK2).

---

## Summary – what to confirm on the schematic

| # | Item | Confirm |
|---|------|--------|
| 1 | Coin debounce: A8 pins used (1–2 and 3–4?), cross-couple, and what resets the latch | [ ] |
| 2 | A8-9 = CREDIT (C9-13), A8-8 = to credit LED | [ ] |
| 3 | Start: N/C → A8-11, B9-2, C9-10; N/O → C9-9, A8-10; ATRCn → C9-8 | [x] |
| 4 | K1: CLR1n=H4n, D1=Hn, CLK1=128H, SET1n=1, Q1→A2-9; J2: H4→11, H4n→10 | [x] |
| 5 | (A2-8 already clear) | – |
| 6 | E9: VRESETn→2, 4=1, 8=1; 5 = GAME_TIME/ATRCn (variable); 6,7 = RC (50k pot) | [x] |
| 7 | N4-6 = END_GAME → B9-11 (CLK2) | [x] |

Once you’ve checked **diagrams/8_Electronic_Latch_etc.png** (or the PDF) and filled the checkboxes / noted any differences, we can update the VHDL to match the schematic exactly.
